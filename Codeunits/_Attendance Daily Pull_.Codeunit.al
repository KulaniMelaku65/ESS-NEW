codeunit 51136 "Attendance Daily Pull"
{
    // BC-native alternative to the Python-side push (sync/erp_attendance_push.py
    // in the attendance dashboard repo): instead of an external process
    // pushing into BC, this codeunit PULLS today's attendance from the
    // dashboard's own API and upserts it into Employee Attendance Log —
    // so the only thing keeping this current is BC's own Job Queue, nothing
    // external needs to stay running.
    //
    // SETUP REQUIRED before scheduling:
    //   1. Update AttendanceApiBaseUrl() below to the real, network-reachable
    //      address of the attendance dashboard API (NOT a local dev machine —
    //      it must be a server this BC instance can reach). The endpoint used
    //      is GET {base}/attendance/today, which needs no authentication today.
    //   2. Create a Job Queue Entry (search "Job Queue Entries") pointing at
    //      this codeunit (51136), same as documented on codeunit 51126
    //      "Attendance Leave Processor" — set it to recur daily, ideally late
    //      in the evening so that day's check-outs are already recorded.
    //
    // NOTE: if the Python-side scheduler (sync/erp_attendance_push.py) is
    // also running, both paths write to the same table using the same
    // get-or-insert-then-modify shape, so running both is redundant but
    // harmless — not something you need.

    trigger OnRun()
    begin
        PullTodayAttendance();
    end;

    local procedure AttendanceApiBaseUrl(): Text
    begin
        exit('http://REPLACE-WITH-REAL-SERVER:8000');
    end;

    local procedure TrackedLocation(): Code[20]
    begin
        // Mirrors codeunit 51138 "Attendance Punch Machine Pull".
        exit('ADDIS ABABA - HQ');
    end;

    local procedure TrackedCountry(): Code[10]
    begin
        // Blank or anything other than Ethiopia is excluded.
        exit('ET');
    end;

    procedure PullTodayAttendance()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        JArray: JsonArray;
        JToken: JsonToken;
        Url: Text;
    begin
        Url := AttendanceApiBaseUrl() + '/attendance/today';
        if not Client.Get(Url, Response) then
            Error('Attendance Daily Pull: HTTP request to %1 failed (network/DNS/timeout).', Url);
        if not Response.IsSuccessStatusCode() then
            Error('Attendance Daily Pull: %1 returned HTTP %2.', Url, Response.HttpStatusCode());

        Response.Content().ReadAs(ResponseText);
        if not JArray.ReadFrom(ResponseText) then
            Error('Attendance Daily Pull: could not parse JSON response from %1.', Url);

        foreach JToken in JArray do
            UpsertOneRecord(JToken.AsObject());
    end;

    local procedure UpsertOneRecord(JObj: JsonObject)
    var
        AttendanceLog: Record "Employee Attendance Log";
        Employee: Record Employee;
        EmployeeNo: Code[20];
        CheckInTimeText: Text;
        CheckOutTimeText: Text;
        WorkDate: Date;
        JTok: JsonToken;
    begin
        if not JObj.Get('id', JTok) then
            exit;
        EmployeeNo := CopyStr(JTok.AsValue().AsText(), 1, 20);

        // Same population as codeunit 51138 "Attendance Punch Machine Pull"
        // — HQ, Active, Ethiopia only.
        if not Employee.Get(EmployeeNo) then
            exit;
        if Employee."Employee Location" <> TrackedLocation() then
            exit;
        if Employee."Employee Status" <> Employee."Employee Status"::Active then
            exit;
        if Employee."Country/Region Code" <> TrackedCountry() then
            exit;

        // first_check_in_date is the real work date; if it's null the
        // employee has no punch data at all today, so there's nothing to log.
        if not (JObj.Get('first_check_in_date', JTok) and not JTok.AsValue().IsNull()) then
            exit;
        if not Evaluate(WorkDate, JTok.AsValue().AsText()) then
            exit;

        if JObj.Get('first_check_in_time', JTok) and not JTok.AsValue().IsNull() then
            CheckInTimeText := ExtractTime(JTok.AsValue().AsText());
        if JObj.Get('last_check_out_time', JTok) and not JTok.AsValue().IsNull() then
            CheckOutTimeText := ExtractTime(JTok.AsValue().AsText());

        if not AttendanceLog.Get(EmployeeNo, WorkDate) then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No." := EmployeeNo;
            AttendanceLog.Date := WorkDate;
            ApplyTimes(AttendanceLog, CheckInTimeText, CheckOutTimeText);
            AttendanceLog.Insert(true);
        end else begin
            ApplyTimes(AttendanceLog, CheckInTimeText, CheckOutTimeText);
            AttendanceLog.Modify(true);
        end;
    end;

    local procedure ApplyTimes(var AttendanceLog: Record "Employee Attendance Log"; CheckInTimeText: Text; CheckOutTimeText: Text)
    var
        Noon: Time;
        ParsedTime: Time;
    begin
        // Reclassify by time-of-day instead of trusting the dashboard's own
        // first_check_in/last_check_out labels — a single tap late in the
        // day (e.g. 4:16pm) can arrive here labelled "first_check_in" just
        // because it was the only punch, and should count as a Check-Out.
        Noon := 120000T;
        if (CheckInTimeText <> '') and Evaluate(ParsedTime, CheckInTimeText) then
            if ParsedTime < Noon then
                AttendanceLog."Check-In Time" := ParsedTime
            else
                if (AttendanceLog."Check-Out Time" = 0T) or (ParsedTime > AttendanceLog."Check-Out Time") then
                    AttendanceLog."Check-Out Time" := ParsedTime;
        if (CheckOutTimeText <> '') and Evaluate(ParsedTime, CheckOutTimeText) then
            if ParsedTime >= Noon then begin
                if (AttendanceLog."Check-Out Time" = 0T) or (ParsedTime > AttendanceLog."Check-Out Time") then
                    AttendanceLog."Check-Out Time" := ParsedTime;
            end else
                if (AttendanceLog."Check-In Time" = 0T) or (ParsedTime < AttendanceLog."Check-In Time") then
                    AttendanceLog."Check-In Time" := ParsedTime;
    end;

    local procedure ExtractTime(IsoTime: Text): Text
    begin
        // 'T08:54:25+03:00' -> '08:54:25'
        if IsoTime = '' then
            exit('');
        if CopyStr(IsoTime, 1, 1) = 'T' then
            IsoTime := CopyStr(IsoTime, 2);
        exit(CopyStr(IsoTime, 1, 8));
    end;
}
