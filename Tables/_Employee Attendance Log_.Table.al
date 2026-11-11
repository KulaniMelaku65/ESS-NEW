table 51128 "Employee Attendance Log"
{
    DataClassification = CustomerContent;
    Caption = 'Employee Attendance Log';

    fields
    {
        field(1;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
            NotBlank = true;
        }
        field(2;Date;Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3;"Check-In Time";Time)
        {
            Caption = 'Check-In Time';
            DataClassification = CustomerContent;
        }
        field(4;"Check-Out Time";Time)
        {
            Caption = 'Check-Out Time';
            DataClassification = CustomerContent;
        }
        field(5;Processed;Boolean)
        {
            Caption = 'Processed';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6;"Leave No.";Code[20])
        {
            Caption = 'Leave No.';
            DataClassification = CustomerContent;
            TableRelation = "Leave Application";
            Editable = false;
        }
        field(7;"Processing Result";Option)
        {
            Caption = 'Processing Result';
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = " ",Attended,"Half Day Created","Absence Created","Half Day Flagged","Absence Flagged","Already On Leave","Insufficient Balance",Failed,Holiday,Weekend,"Approved by Manager";
            OptionCaption = ' ,Attended,Half Day Created,Absence Created,Half Day Flagged,Absence Flagged,Already On Leave,Insufficient Balance,Failed,Holiday,Weekend,Approved by Manager';
        }
        field(8;"Day Value";Decimal)
        {
            // Full day (1) if both check-in and check-out are recorded; half
            // day (0.5) if only one is; 0 if neither.
            Caption = 'Day Value';
            DataClassification = CustomerContent;
            DecimalPlaces = 1 : 1;
            Editable = false;
        }
        field(9;"Absence Reason";Text[250])
        {
            // Filled in once an absence explanation is confirmed — either
            // internally (Attendance Absence Explanation reaching Confirmed,
            // see codeunit "Attendance Absence Notifier") or from the ESS
            // portal's own explain-and-approve flow via "Employee
            // Attendance Log Update API" (page 51136), which also sets
            // Processing Result to "Approved by Manager".
            Caption = 'Absence Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(PK;"Employee No.", Date)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        UpdateDayValue();
    end;

    trigger OnModify()
    begin
        UpdateDayValue();
    end;

    // Half-day rule: any single punch (check-in xor check-out, with the
    // other missing) counts as half a day rather than zero — a partial
    // record is still evidence the employee was in that day, not an
    // unexplained absence. Runs on every Insert/Modify (including the
    // "Attendance Web API" codeunit and the "Employee Attendance Log API"
    // page, since both call the standard Insert(true)/Modify(true)), so it
    // never falls out of sync with however the row got written.
    //
    // A manager-approved explanation overrides the punch-based calculation
    // entirely — once approved, the day counts as a full day regardless of
    // whether a check-in/check-out is actually on file. Existing rows that
    // were approved before this rule existed can be corrected with
    // "Recalculate Day Values" on the Employee Attendance Log List page.
    local procedure UpdateDayValue()
    begin
        if "Processing Result" = "Processing Result"::"Approved by Manager" then
            "Day Value" := 1
        else
            if("Check-In Time" <> 0T) and("Check-Out Time" <> 0T)then "Day Value":=1
            else
                if("Check-In Time" <> 0T) or("Check-Out Time" <> 0T)then "Day Value":=0.5
                else
                    "Day Value":=0;
    end;

    // Real hours if both punches exist; otherwise, for a manager-approved
    // day only, an estimate — the average of this employee's other
    // actually-worked days (real check-in AND check-out) in the same
    // Monday-Sunday week. If the week has no real worked day at all (e.g.
    // the employee worked from home the whole week, so every day is an
    // approved explanation with no punches), each approved day counts as a
    // standard WorkFromHomeHours() instead. Any other day (not approved,
    // no real punches) is 0. Used by the Attendance Card subform, both
    // preview surfaces and the weekly review email, so the estimate is
    // consistent everywhere it shows up instead of drifting between them.
    procedure GetHoursWorked(): Decimal
    var
        OtherLog: Record "Employee Attendance Log";
        WeekMonday: Date;
        WeekSunday: Date;
        TotalHours: Decimal;
        DayCount: Integer;
    begin
        if ("Check-In Time" <> 0T) and ("Check-Out Time" <> 0T) and ("Check-Out Time" > "Check-In Time") then
            exit((CreateDateTime(Today, "Check-Out Time") - CreateDateTime(Today, "Check-In Time")) / 3600000);

        if "Processing Result" <> "Processing Result"::"Approved by Manager" then
            exit(0);

        WeekMonday := Date - (Date2DWY(Date, 1) - 1);
        WeekSunday := WeekMonday + 6;
        OtherLog.SetRange("Employee No.", "Employee No.");
        OtherLog.SetFilter(Date, '%1..%2&<>%3', WeekMonday, WeekSunday, Date);
        if OtherLog.FindSet() then
            repeat
                if (OtherLog."Check-In Time" <> 0T) and (OtherLog."Check-Out Time" <> 0T) and (OtherLog."Check-Out Time" > OtherLog."Check-In Time") then begin
                    TotalHours += (CreateDateTime(Today, OtherLog."Check-Out Time") - CreateDateTime(Today, OtherLog."Check-In Time")) / 3600000;
                    DayCount += 1;
                end;
            until OtherLog.Next() = 0;
        if DayCount > 0 then
            exit(TotalHours / DayCount);

        exit(WorkFromHomeHours());
    end;

    // Standard credit for an approved day in a week with no real punches at
    // all — nothing to average from, so a flat working day.
    procedure WorkFromHomeHours(): Decimal
    begin
        exit(8);
    end;
}
