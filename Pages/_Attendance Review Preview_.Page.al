page 51144 "Attendance Review Preview"
{
    // On-screen preview of the same Monday-Friday, colour-coded attendance
    // table the weekly review email (codeunit 51140) sends — for one
    // employee, over any date range you choose. Nothing gets sent; this is
    // purely for checking what the table would look like.
    ApplicationArea = Basic;
    Caption = 'Attendance Review Preview';
    PageType = Card;
    SourceTable = "Attendance Review Preview Line";
    SourceTableTemporary = true;
    UsageCategory = Tasks;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Selection';
                field(EmployeeNo;EmployeeNo)
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee No.';
                    TableRelation = Employee;
                    ToolTip = 'The employee to preview. Enter and click Generate Preview.';

                    trigger OnValidate()
                    var
                        Employee: Record Employee;
                    begin
                        Clear(EmployeeName);
                        if Employee.Get(EmployeeNo) then
                            EmployeeName := Employee.FullName();
                    end;
                }
                field(EmployeeName;EmployeeName)
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee Name';
                    Editable = false;
                }
                field(PeriodStart;PeriodStart)
                {
                    ApplicationArea = Basic;
                    Caption = 'Start Date';
                }
                field(PeriodEnd;PeriodEnd)
                {
                    ApplicationArea = Basic;
                    Caption = 'End Date';
                }
            }
            repeater(Lines)
            {
                field(Date;Rec.Date)
                {
                    ApplicationArea = Basic;
                    StyleExpr = Rec."Row Style";
                }
                field(Weekday;Rec.Weekday)
                {
                    ApplicationArea = Basic;
                    StyleExpr = Rec."Row Style";
                }
                field("Clock In";Rec."Clock In")
                {
                    ApplicationArea = Basic;
                    StyleExpr = Rec."Row Style";
                }
                field("Clock Out";Rec."Clock Out")
                {
                    ApplicationArea = Basic;
                    StyleExpr = Rec."Row Style";
                }
                field("Total Time";Rec."Total Time")
                {
                    ApplicationArea = Basic;
                    StyleExpr = Rec."Row Style";
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GeneratePreview)
            {
                ApplicationArea = Basic;
                Caption = 'Generate Preview';
                Image = Refresh;
                ToolTip = 'Builds the table below for the chosen employee and date range — Monday to Friday only, same as the email. Green = on leave, red = full gap, yellow = half gap, blue = holiday/weekend.';

                trigger OnAction()
                begin
                    BuildPreview();
                end;
            }
        }
    }

    var
        EmployeeNo: Code[20];
        EmployeeName: Text[100];
        PeriodStart: Date;
        PeriodEnd: Date;

    local procedure BuildPreview()
    var
        Employee: Record Employee;
        AttendanceLog: Record "Employee Attendance Log";
        DayTypeCU: Codeunit "Attendance Day Type";
        LeaveCalc: Codeunit "Leave Half Day Calculator";
        RunDate: Date;
        LineNo: Integer;
        DayType: Text[30];
        ApprovedLeaveNo: Code[20];
        IsHalfDayLeave: Boolean;
        LeaveNote: Text;
        ApprovalNote: Text;
        EstimatedHours: Decimal;
        HasLog: Boolean;
        ClockInText: Text;
        ClockOutText: Text;
        TotalText: Text;
        RowStyle: Text;
    begin
        if EmployeeNo = '' then
            Error('Enter an Employee No. first.');
        if not Employee.Get(EmployeeNo) then
            Error('Employee %1 does not exist.', EmployeeNo);
        if (PeriodStart = 0D) or (PeriodEnd = 0D) then
            Error('Enter both a Start Date and an End Date.');
        if PeriodStart > PeriodEnd then
            Error('Start Date must be on or before End Date.');

        Rec.Reset();
        Rec.DeleteAll();
        LineNo := 0;

        RunDate := PeriodStart;
        while RunDate <= PeriodEnd do begin
            if Date2DWY(RunDate, 1) <= 5 then begin // Monday..Friday only, same as the email
                ClockInText := '-';
                ClockOutText := '-';
                TotalText := '-';
                RowStyle := 'Standard';

                DayType := DayTypeCU.GetDayType(RunDate);
                if DayType <> '' then begin
                    ClockInText := DayType;
                    ClockOutText := '';
                    TotalText := '';
                    RowStyle := 'Subordinate'; // holiday/weekend
                    // Same as the email: a half-day company holiday is still
                    // worked in the morning, so show that day's total time
                    // (clock times stay hidden on a holiday row).
                    if DayTypeCU.IsHalfWorkingDay(RunDate) and AttendanceLog.Get(EmployeeNo, RunDate) then
                        if (AttendanceLog."Check-In Time" <> 0T) and (AttendanceLog."Check-Out Time" > AttendanceLog."Check-In Time") then
                            TotalText := FormatDurationHHMM(CreateDateTime(Today, AttendanceLog."Check-Out Time") - CreateDateTime(Today, AttendanceLog."Check-In Time"))
                        else begin
                            EstimatedHours := AttendanceLog.GetHoursWorked();
                            if EstimatedHours > 0 then
                                TotalText := FormatHoursDecimal(EstimatedHours) + ' (est.)';
                        end;
                end else begin
                    ApprovedLeaveNo := LeaveCalc.GetLeaveStatus(EmployeeNo, RunDate, IsHalfDayLeave);

                    // Show real punch data whenever it exists, on-leave or
                    // not — someone can be on approved leave and still have
                    // come in. Leave just adds a note; it never hides an
                    // actual clock-in/clock-out.
                    HasLog := AttendanceLog.Get(EmployeeNo, RunDate);
                    if HasLog and (AttendanceLog."Check-In Time" <> 0T) then
                        ClockInText := FormatClockTime(AttendanceLog."Check-In Time");
                    if HasLog and (AttendanceLog."Check-Out Time" <> 0T) then
                        ClockOutText := FormatClockTime(AttendanceLog."Check-Out Time");

                    if ApprovedLeaveNo <> '' then begin
                        RowStyle := 'Favorable'; // on leave
                        if IsHalfDayLeave then
                            LeaveNote := 'On Leave - Half Day (' + ApprovedLeaveNo + ')'
                        else
                            LeaveNote := 'On Leave (' + ApprovedLeaveNo + ')';
                        if (ClockInText <> '-') and (ClockOutText <> '-') then
                            TotalText := FormatDurationHHMM(CreateDateTime(Today, AttendanceLog."Check-Out Time") - CreateDateTime(Today, AttendanceLog."Check-In Time")) + ' - ' + LeaveNote
                        else
                            if (ClockInText = '-') and (ClockOutText = '-') then begin
                                ClockInText := LeaveNote;
                                ClockOutText := '';
                            end else
                                TotalText := LeaveNote;
                    end else
                        if HasLog and (AttendanceLog."Processing Result" = AttendanceLog."Processing Result"::"Approved by Manager") then begin
                            RowStyle := 'AttentionAccent'; // absence explained & approved
                            if AttendanceLog."Absence Reason" <> '' then
                                ApprovalNote := 'Approved by Manager: ' + AttendanceLog."Absence Reason"
                            else
                                ApprovalNote := 'Approved by Manager';
                            EstimatedHours := AttendanceLog.GetHoursWorked();
                            if (ClockInText = '-') and (ClockOutText = '-') then begin
                                ClockInText := ApprovalNote;
                                ClockOutText := '';
                                if EstimatedHours > 0 then
                                    TotalText := FormatHoursDecimal(EstimatedHours) + ' (est.)';
                            end else
                                if EstimatedHours > 0 then
                                    TotalText := FormatHoursDecimal(EstimatedHours) + ' (est.) - ' + ApprovalNote
                                else
                                    TotalText := ApprovalNote;
                        end else begin
                            if (ClockInText <> '-') and (ClockOutText <> '-') then begin
                                TotalText := FormatDurationHHMM(CreateDateTime(Today, AttendanceLog."Check-Out Time") - CreateDateTime(Today, AttendanceLog."Check-In Time"));
                                RowStyle := 'Standard';
                            end else
                                if (ClockInText = '-') and (ClockOutText = '-') then
                                    RowStyle := 'Unfavorable' // full gap
                                else
                                    RowStyle := 'Ambiguous'; // half gap
                        end;
                end;

                LineNo += 1;
                Rec.Init();
                Rec."Line No." := LineNo;
                Rec.Date := RunDate;
                Rec.Weekday := WeekdayName(RunDate);
                Rec."Clock In" := CopyStr(ClockInText, 1, 40);
                Rec."Clock Out" := CopyStr(ClockOutText, 1, 40);
                Rec."Total Time" := CopyStr(TotalText, 1, 20);
                Rec."Row Style" := RowStyle;
                Rec.Insert();
            end;
            RunDate := CalcDate('<1D>', RunDate);
        end;

        CurrPage.Update(false);
    end;

    // Same no-custom-format-string approach as codeunit 51140 "Attendance
    // Review Mailer" — bare Time-Time subtraction and custom Format()
    // strings on Time/decimals have both caused real runtime crashes in
    // this codebase before, so avoid them entirely here too.
    local procedure FormatClockTime(T: Time): Text
    begin
        if T = 0T then
            exit('');
        exit(FormatDurationHHMM(CreateDateTime(Today, T) - CreateDateTime(Today, 0T)));
    end;

    local procedure FormatDurationHHMM(MillisecondsDuration: Duration): Text
    var
        TotalSeconds: Integer;
        Hours: Integer;
        Minutes: Integer;
    begin
        TotalSeconds := MillisecondsDuration div 1000;
        Hours := TotalSeconds div 3600;
        Minutes := (TotalSeconds mod 3600) div 60;
        exit(PadZero(Hours) + ':' + PadZero(Minutes));
    end;

    // Decimal-hours estimate (from GetHoursWorked) formatted for display —
    // distinct from FormatDurationHHMM above, which formats a real
    // millisecond Duration between two punches.
    local procedure FormatHoursDecimal(Hours: Decimal): Text
    var
        WholeHours: Integer;
        Minutes: Integer;
    begin
        WholeHours := Round(Hours, 1, '<') * 1; // truncate toward zero
        Minutes := Round((Hours - WholeHours) * 60, 1, '=');
        exit(PadZero(WholeHours) + ':' + PadZero(Minutes));
    end;

    local procedure PadZero(N: Integer): Text
    begin
        if N < 10 then
            exit('0' + Format(N));
        exit(Format(N));
    end;

    local procedure WeekdayName(D: Date): Text[10]
    begin
        case Date2DWY(D, 1) of
            1:
                exit('Monday');
            2:
                exit('Tuesday');
            3:
                exit('Wednesday');
            4:
                exit('Thursday');
            5:
                exit('Friday');
            6:
                exit('Saturday');
            7:
                exit('Sunday');
        end;
    end;
}
