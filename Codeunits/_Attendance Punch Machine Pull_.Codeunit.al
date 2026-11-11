codeunit 51138 "Attendance Punch Machine Pull"
{
    // Fully independent alternative to codeunit 51136 "Attendance Daily
    // Pull" — this one talks to the punch machine directly instead of the
    // attendance dashboard API, so it has zero dependency on the dashboard
    // service or its Postgres database being up. The only thing it needs
    // reachable is the punch machine itself — same host/port the
    // dashboard's own sync/punch_client.py calls.
    //
    // Scoped the same way as the dashboard: only employees whose Employee
    // Location is "ADDIS ABABA - HQ" are pulled (mirrors TRACKED_LOCATION
    // in sync/erp_roster.py on the dashboard side).
    //
    // SETUP REQUIRED before scheduling:
    //   1. Confirm this BC server can reach PunchApiBaseUrl() below over
    //      the network.
    //   2. Create a Job Queue Entry pointing at this codeunit (51138),
    //      recurring daily — same pattern as codeunit 51126/51136. You can
    //      run this alongside 51136 (both upsert the same way, so it's
    //      redundant-safe) or use only one — your call.

    trigger OnRun()
    begin
        PullTodayAttendance();
    end;

    local procedure PunchApiBaseUrl(): Text
    begin
        exit('http://172.16.11.241:5000');
    end;

    local procedure TrackedLocation(): Text
    begin
        exit('ADDIS ABABA - HQ');
    end;

    local procedure TrackedCountry(): Code[10]
    begin
        // Blank or anything other than Ethiopia is excluded — SetRange to
        // an exact value naturally excludes blank too.
        exit('ET');
    end;

    // Bulk version of PullHistoricalForEmployee — runs it for every
    // employee in the tracked population (HQ, Active, Ethiopia), one
    // machine call per employee. Meant for a one-off "get everything
    // right, one last time" full-history re-pull, not routine use — the
    // daily job (OnRun/PullTodayAttendance) is what keeps things current
    // afterward. Returns total days filled across everyone.
    procedure PullHistoricalForAllTracked(FromDate: Date; ToDate: Date) TotalDaysFilled: Integer
    var
        Employee: Record Employee;
    begin
        TotalDaysFilled := 0;
        Employee.SetRange("Employee Location", TrackedLocation());
        Employee.SetRange("Employee Status", Employee."Employee Status"::Active);
        Employee.SetRange("Country/Region Code", TrackedCountry());
        if Employee.FindSet() then
            repeat
                TotalDaysFilled += PullHistoricalForEmployee(Employee."No.", FromDate, ToDate);
            until Employee.Next() = 0;
    end;

    // Pulls a rolling 7-day window every run, not just today, so a day that
    // was missed (job skipped, machine unreachable, run before that day's
    // punches existed) gets filled on the next successful run.
    procedure PullTodayAttendance()
    var
        Employee: Record Employee;
        RunDate: Date;
    begin
        RunDate := Today();
        Employee.SetRange("Employee Location", TrackedLocation());
        Employee.SetRange("Employee Status", Employee."Employee Status"::Active);
        Employee.SetRange("Country/Region Code", TrackedCountry());
        if Employee.FindSet() then
            repeat
                PullRecentForEmployee(Employee."No.", CalcDate('<-6D>', RunDate), RunDate);
            until Employee.Next() = 0;
    end;

    // Re-fetches a date range directly from the punch machine for one
    // employee and fills in any Employee Attendance Log rows that are
    // missing Check-In/Check-Out — unlike "Backfill Processing Since
    // Start" (Attendance Leave Processor), which only re-derives the
    // Processing Result label from whatever's already stored and can
    // never fill in a genuinely blank Check-In/Check-Out. Returns how many
    // days actually got a punch. Same noon-boundary classification as the
    // daily pull, applied per calendar date across the whole range.
    procedure PullHistoricalForEmployee(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date) DaysFilled: Integer
    var
        PullLog: Record "Attendance Pull Log";
        FirstCheckInByDate: Dictionary of [Date, Time];
        LastCheckOutByDate: Dictionary of [Date, Time];
        RunDate: Date;
    begin
        DaysFilled := 0;
        if not FetchPunchTimes(EmployeeNo, FromDate, ToDate, FirstCheckInByDate, LastCheckOutByDate) then
            exit;

        RunDate := FromDate;
        while RunDate <= ToDate do begin
            if FirstCheckInByDate.ContainsKey(RunDate) or LastCheckOutByDate.ContainsKey(RunDate) then begin
                UpsertLog(EmployeeNo, RunDate, GetTimeOrZero(FirstCheckInByDate, RunDate), GetTimeOrZero(LastCheckOutByDate, RunDate));
                LogPullResult(EmployeeNo, RunDate, PullLog.Result::Success, StrSubstNo('Check-In=%1 Check-Out=%2', Format(GetTimeOrZero(FirstCheckInByDate, RunDate)), Format(GetTimeOrZero(LastCheckOutByDate, RunDate))));
                DaysFilled += 1;
            end else
                LogPullResult(EmployeeNo, RunDate, PullLog.Result::"No Data", 'Machine returned no punches for this date.');
            RunDate := CalcDate('<1D>', RunDate);
        end;
    end;

    local procedure PullRecentForEmployee(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date)
    var
        PullLog: Record "Attendance Pull Log";
        FirstCheckInByDate: Dictionary of [Date, Time];
        LastCheckOutByDate: Dictionary of [Date, Time];
        RunDate: Date;
    begin
        if not FetchPunchTimes(EmployeeNo, FromDate, ToDate, FirstCheckInByDate, LastCheckOutByDate) then
            exit;

        RunDate := FromDate;
        while RunDate <= ToDate do begin
            if FirstCheckInByDate.ContainsKey(RunDate) or LastCheckOutByDate.ContainsKey(RunDate) then begin
                FillBlankLog(EmployeeNo, RunDate, GetTimeOrZero(FirstCheckInByDate, RunDate), GetTimeOrZero(LastCheckOutByDate, RunDate));
                LogPullResult(EmployeeNo, RunDate, PullLog.Result::Success, StrSubstNo('Check-In=%1 Check-Out=%2', Format(GetTimeOrZero(FirstCheckInByDate, RunDate)), Format(GetTimeOrZero(LastCheckOutByDate, RunDate))));
            end else
                LogPullResult(EmployeeNo, RunDate, PullLog.Result::"No Data", 'Machine returned no punches for this date.');
            RunDate := CalcDate('<1D>', RunDate);
        end;
    end;

    local procedure FetchPunchTimes(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date; var FirstCheckInByDate: Dictionary of [Date, Time]; var LastCheckOutByDate: Dictionary of [Date, Time]): Boolean
    var
        PullLog: Record "Attendance Pull Log";
        PunchCode: Integer;
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        JObj: JsonObject;
        JTok: JsonToken;
        Url: Text;
    begin
        if (FromDate = 0D) or (ToDate = 0D) or (FromDate > ToDate) then
            exit(false);
        if not TryKftToPunchCode(EmployeeNo, PunchCode) then begin
            LogRangeResult(EmployeeNo, FromDate, ToDate, PullLog.Result::"Invalid Employee No. Format", 'Could not derive a punch code from this Employee No.');
            exit(false);
        end;

        Url := PunchApiBaseUrl() + '/api/attendance/' + Format(PunchCode) +
               '?start=' + Format(FromDate, 0, '<Year4>-<Month,2>-<Day,2>') +
               '&end=' + Format(ToDate, 0, '<Year4>-<Month,2>-<Day,2>');

        if not Client.Get(Url, Response) then begin
            LogRangeResult(EmployeeNo, FromDate, ToDate, PullLog.Result::"HTTP Error", 'Could not reach the punch machine (network/timeout).');
            exit(false);
        end;
        if not Response.IsSuccessStatusCode() then begin
            LogRangeResult(EmployeeNo, FromDate, ToDate, PullLog.Result::"HTTP Error", StrSubstNo('Punch machine returned HTTP %1.', Response.HttpStatusCode()));
            exit(false);
        end;
        Response.Content().ReadAs(ResponseText);
        if not JObj.ReadFrom(ResponseText) then begin
            LogRangeResult(EmployeeNo, FromDate, ToDate, PullLog.Result::"Parse Error", 'Response was not valid JSON.');
            exit(false);
        end;
        if not JObj.Get('data', JTok) then begin
            LogRangeResult(EmployeeNo, FromDate, ToDate, PullLog.Result::"Parse Error", 'Response had no "data" field.');
            exit(false);
        end;

        CollectDayTimesGrouped(JTok.AsArray(), FirstCheckInByDate, LastCheckOutByDate);
        exit(true);
    end;

    local procedure LogRangeResult(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date; PullResult: Option; Details: Text[250])
    var
        RunDate: Date;
    begin
        RunDate := FromDate;
        while RunDate <= ToDate do begin
            LogPullResult(EmployeeNo, RunDate, PullResult, Details);
            RunDate := CalcDate('<1D>', RunDate);
        end;
    end;

    local procedure LogPullResult(EmployeeNo: Code[20]; WorkDate: Date; PullResult: Option; Details: Text[250])
    var
        PullLog: Record "Attendance Pull Log";
    begin
        if not PullLog.Get(EmployeeNo, WorkDate) then begin
            PullLog.Init();
            PullLog."Employee No." := EmployeeNo;
            PullLog.Date := WorkDate;
            PullLog.Insert();
        end;
        PullLog.Result := PullResult;
        PullLog.Details := Details;
        PullLog."Pulled At" := CurrentDateTime;
        PullLog.Modify();
    end;

    local procedure GetTimeOrZero(var Dict: Dictionary of [Date, Time]; ForDate: Date): Time
    begin
        if Dict.ContainsKey(ForDate) then
            exit(Dict.Get(ForDate));
        exit(0T);
    end;

    // Same noon-boundary classification as CollectDayTimes, but grouped by
    // calendar date instead of assuming every punch in the array belongs
    // to a single day — needed for a multi-day historical range.
    local procedure CollectDayTimesGrouped(JArr: JsonArray; var FirstCheckInByDate: Dictionary of [Date, Time]; var LastCheckOutByDate: Dictionary of [Date, Time])
    var
        JTok: JsonToken;
        JPunch: JsonObject;
        TimeTok: JsonToken;
        PunchTimeFullText: Text;
        DatePart: Text;
        TimePart: Text;
        ThisDate: Date;
        ThisTime: Time;
        Existing: Time;
        Noon: Time;
    begin
        Noon := 120000T;
        foreach JTok in JArr do begin
            JPunch := JTok.AsObject();
            if JPunch.Get('punch_time', TimeTok) then begin
                PunchTimeFullText := TimeTok.AsValue().AsText();
                if SplitIsoDateTime(PunchTimeFullText, DatePart, TimePart) then begin
                    ThisDate := ParseIsoDate(DatePart);
                    if (ThisDate <> 0D) and Evaluate(ThisTime, TimePart) then begin
                        if ThisTime < Noon then begin
                            if FirstCheckInByDate.ContainsKey(ThisDate) then begin
                                Existing := FirstCheckInByDate.Get(ThisDate);
                                if ThisTime < Existing then
                                    FirstCheckInByDate.Set(ThisDate, ThisTime);
                            end else
                                FirstCheckInByDate.Add(ThisDate, ThisTime);
                        end else begin
                            if LastCheckOutByDate.ContainsKey(ThisDate) then begin
                                Existing := LastCheckOutByDate.Get(ThisDate);
                                if ThisTime > Existing then
                                    LastCheckOutByDate.Set(ThisDate, ThisTime);
                            end else
                                LastCheckOutByDate.Add(ThisDate, ThisTime);
                        end;
                    end;
                end;
            end;
        end;
    end;

    // '2026-08-27T08:54:25+03:00' -> DatePart='2026-08-27', TimePart='08:54:25'
    local procedure SplitIsoDateTime(FullText: Text; var DatePart: Text; var TimePart: Text): Boolean
    var
        TPos: Integer;
    begin
        TPos := StrPos(FullText, 'T');
        if TPos = 0 then
            exit(false);
        DatePart := CopyStr(FullText, 1, TPos - 1);
        TimePart := CopyStr(FullText, TPos + 1, 8);
        exit(true);
    end;

    // Deliberately not using Evaluate(Date,...) — its behaviour depends on
    // regional format, and this text is always fixed 'YYYY-MM-DD'. Parsing
    // the three numeric parts and building the date with DMY2Date avoids
    // any locale ambiguity.
    local procedure ParseIsoDate(DateText: Text): Date
    var
        Y: Integer;
        M: Integer;
        D: Integer;
    begin
        if StrLen(DateText) < 10 then
            exit(0D);
        if not Evaluate(Y, CopyStr(DateText, 1, 4)) then
            exit(0D);
        if not Evaluate(M, CopyStr(DateText, 6, 2)) then
            exit(0D);
        if not Evaluate(D, CopyStr(DateText, 9, 2)) then
            exit(0D);
        exit(DMY2Date(D, M, Y));
    end;

    local procedure TryKftToPunchCode(EmployeeNo: Code[20]; var PunchCode: Integer): Boolean
    var
        Digits: Text;
    begin
        // 'KFT1459' -> 1459, 'KFT0001' -> 1 -- same rule as
        // crud.kft_to_punch_code on the dashboard side.
        Digits := UpperCase(EmployeeNo);
        if CopyStr(Digits, 1, 3) = 'KFT' then
            Digits := CopyStr(Digits, 4);
        while (StrLen(Digits) > 1) and (CopyStr(Digits, 1, 1) = '0') do
            Digits := CopyStr(Digits, 2);
        exit(Evaluate(PunchCode, Digits));
    end;

    // Only fills Check-In/Check-Out that are still blank — a value already
    // stored (including a manual correction) is never overwritten.
    local procedure FillBlankLog(EmployeeNo: Code[20]; WorkDate: Date; FirstCheckIn: Time; LastCheckOut: Time)
    var
        AttendanceLog: Record "Employee Attendance Log";
        Changed: Boolean;
    begin
        if not AttendanceLog.Get(EmployeeNo, WorkDate) then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No." := EmployeeNo;
            AttendanceLog.Date := WorkDate;
            AttendanceLog."Check-In Time" := FirstCheckIn;
            AttendanceLog."Check-Out Time" := LastCheckOut;
            AttendanceLog.Insert(true);
            exit;
        end;

        if (AttendanceLog."Check-In Time" = 0T) and (FirstCheckIn <> 0T) then begin
            AttendanceLog."Check-In Time" := FirstCheckIn;
            Changed := true;
        end;
        if (AttendanceLog."Check-Out Time" = 0T) and (LastCheckOut <> 0T) then begin
            AttendanceLog."Check-Out Time" := LastCheckOut;
            Changed := true;
        end;
        if Changed then
            AttendanceLog.Modify(true);
    end;

    local procedure UpsertLog(EmployeeNo: Code[20]; WorkDate: Date; FirstCheckIn: Time; LastCheckOut: Time)
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        if not AttendanceLog.Get(EmployeeNo, WorkDate) then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No." := EmployeeNo;
            AttendanceLog.Date := WorkDate;
            if FirstCheckIn <> 0T then
                AttendanceLog."Check-In Time" := FirstCheckIn;
            if LastCheckOut <> 0T then
                AttendanceLog."Check-Out Time" := LastCheckOut;
            AttendanceLog.Insert(true);
        end else begin
            if FirstCheckIn <> 0T then
                AttendanceLog."Check-In Time" := FirstCheckIn;
            if LastCheckOut <> 0T then
                AttendanceLog."Check-Out Time" := LastCheckOut;
            AttendanceLog.Modify(true);
        end;
    end;
}
