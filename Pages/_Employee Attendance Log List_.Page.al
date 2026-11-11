page 51130 "Employee Attendance Log List"
{
    // One row per employee (not per day) — the daily check-in/check-out
    // detail lives on "Employee Attendance Card" via its embedded subform.
    // Click an Employee No. here to drill into that employee's full log.
    ApplicationArea = Basic;
    Caption = 'Employee Attendance Log';
    PageType = List;
    SourceTable = Employee;
    SourceTableView = where("Excl. Attendance Review" = const(false));
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No.";Rec."No.")
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee No.';
                    ToolTip = 'Click to open this employee''s attendance card.';

                    trigger OnDrillDown()
                    begin
                        PAGE.Run(PAGE::"Employee Attendance Card", Rec);
                    end;
                }
                field("Full Name";Rec."Full Name")
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee Name';
                }
                field(CurrentMonthAttendanceDays;CurrentMonthDays)
                {
                    ApplicationArea = Basic;
                    Caption = 'Attendance Days (This Month)';
                    ToolTip = 'Sum of Day Value from the Employee Attendance Log for the current calendar month (1 = full day, 0.5 = half day).';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RecalculateDayValues)
            {
                ApplicationArea = Basic;
                Caption = 'Recalculate Day Values';
                Image = Refresh;
                ToolTip = 'One-time repair: recomputes Day Value for every existing attendance log row. Needed because rows written before the Day Value field existed never had it computed — new check-ins/check-outs compute it automatically going forward.';

                trigger OnAction()
                var
                    AttendanceLog: Record "Employee Attendance Log";
                begin
                    if AttendanceLog.FindSet(true) then
                        repeat
                            AttendanceLog.Modify(true);
                        until AttendanceLog.Next() = 0;
                    CurrPage.Update(false);
                    Message('Day Value recalculated for all attendance log entries.');
                end;
            }
            action(BackfillAttendanceProcessing)
            {
                ApplicationArea = Basic;
                Caption = 'Backfill Processing Since Start';
                Image = ReconcileTransaction;
                ToolTip = 'Runs the same nightly Attendance Leave Processor logic for every day from the earliest existing attendance log entry through yesterday, for every active employee. Fills in Holiday / Already On Leave / Absence Flagged outcomes for days that were never processed, AND corrects days already processed under older logic (e.g. a holiday wrongly logged as Absence Flagged) — except days with a real auto-created leave application attached, which are left alone. Can take a while for a long history.';

                trigger OnAction()
                var
                    AttendanceLog: Record "Employee Attendance Log";
                    Processor: Codeunit "Attendance Leave Processor";
                    StartDate: Date;
                    RunDate: Date;
                begin
                    AttendanceLog.SetCurrentKey(Date);
                    AttendanceLog.SetFilter(Date, '<>%1', 0D);
                    if AttendanceLog.FindFirst() then
                        StartDate := AttendanceLog.Date
                    else
                        StartDate := CalcDate('<-CM>', Today);
                    if not Confirm('This will process every day from %1 through %2 for every active employee, correcting any already-processed days too. This may take a while for a long history. Continue?', false, StartDate, CalcDate('<-1D>', Today)) then
                        exit;
                    RunDate := StartDate;
                    while RunDate < Today do begin
                        Processor.ProcessAttendanceForDate(RunDate, true, false);
                        RunDate := CalcDate('<1D>', RunDate);
                    end;
                    CurrPage.Update(false);
                    Message('Backfill complete from %1 through %2.', StartDate, CalcDate('<-1D>', Today));
                end;
            }
            action(SendAttendanceReviewEmails)
            {
                ApplicationArea = Basic;
                Caption = 'Send Attendance Review Emails';
                Image = SendTo;
                ToolTip = 'Sends the weekly attendance review email (weekly summary + daily detail, CC''ing supervisor and HRBP) for the most recently completed Monday-Sunday week to every tracked employee not marked "Excl. Attendance Review". Uses the same period a scheduled Job Queue Entry for codeunit 51140 would use.';

                trigger OnAction()
                var
                    Mailer: Codeunit "Attendance Review Mailer";
                    PeriodStart: Date;
                    PeriodEnd: Date;
                begin
                    Mailer.GetDefaultWeeklyPeriod(PeriodStart, PeriodEnd);
                    if not Confirm('This will email every tracked, non-excluded employee an attendance review for %1 through %2, CC''ing their supervisor and HRBP. This cannot be undone. Continue?', false, PeriodStart, PeriodEnd) then
                        exit;
                    Mailer.SendAttendanceReviewEmails(PeriodStart, PeriodEnd);
                    Message('Attendance review emails sent for %1 through %2.', PeriodStart, PeriodEnd);
                end;
            }
            action(SendReviewForSelectedEmployee)
            {
                ApplicationArea = Basic;
                Caption = 'Send Review (Selected Employee Only)';
                Image = SendToLetter;
                ToolTip = 'Sends the attendance review email to only the employee currently selected in the list — ignores Employee Location and "Excl. Attendance Review", so you can test against anyone regardless of the bulk-run filters.';

                trigger OnAction()
                var
                    Mailer: Codeunit "Attendance Review Mailer";
                    PeriodStart: Date;
                    PeriodEnd: Date;
                begin
                    if Rec."Company E-Mail" = '' then begin
                        Message('%1 (%2) has no Company E-Mail — cannot send.', Rec.FullName(), Rec."No.");
                        exit;
                    end;
                    Mailer.GetDefaultWeeklyPeriod(PeriodStart, PeriodEnd);
                    if not Confirm('Send the attendance review for %1 through %2 to %3 (%4) only, CC''ing their supervisor and HRBP? This cannot be undone.', false, PeriodStart, PeriodEnd, Rec.FullName(), Rec."No.") then
                        exit;
                    Mailer.SendReviewForOneEmployee(Rec, PeriodStart, PeriodEnd);
                    Message('Attendance review sent to %1 for %2 through %3.', Rec.FullName(), PeriodStart, PeriodEnd);
                end;
            }
            action(RePullPunchDataForEmployee)
            {
                ApplicationArea = Basic;
                Caption = 'Re-Pull Punch Data (Selected Employee)...';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Re-fetches a date range directly from the punch machine for the selected employee and writes Check-In/Check-Out for any day the machine has data for, replacing what''s currently stored for that day. Unlike Backfill Processing Since Start, this actually goes back to the machine for new data rather than only re-classifying what''s already stored — use this when Check-In/Check-Out are genuinely blank, not just when the Processing Result label looks wrong.';

                trigger OnAction()
                var
                    PunchPull: Codeunit "Attendance Punch Machine Pull";
                    SelectRange: Page "Select Date Range Dialog";
                    FromDate: Date;
                    ToDate: Date;
                    DaysFilled: Integer;
                begin
                    if SelectRange.RunModal() <> Action::OK then
                        exit;
                    FromDate := SelectRange.GetStartDate();
                    ToDate := SelectRange.GetEndDate();
                    if (FromDate = 0D) or (ToDate = 0D) then
                        exit;
                    if FromDate > ToDate then begin
                        Message('Start Date must be on or before End Date.');
                        exit;
                    end;
                    if not Confirm('Re-fetch punch data from the machine for %1 (%2), from %3 through %4? Any day in this range that the machine has data for will be written with that data, replacing whatever''s currently stored for it. Continue?', false, Rec.FullName(), Rec."No.", FromDate, ToDate) then
                        exit;
                    DaysFilled := PunchPull.PullHistoricalForEmployee(Rec."No.", FromDate, ToDate);
                    Message('Done. %1 day(s) were filled in for %2 from %3 through %4.', DaysFilled, Rec.FullName(), FromDate, ToDate);
                end;
            }
            action(RePullPunchDataAllEmployees)
            {
                ApplicationArea = Basic;
                Caption = 'Re-Pull Punch Data (All Employees)...';
                Image = RefreshLines;
                ToolTip = 'Re-fetches a date range directly from the punch machine for every tracked employee (HQ, Active, Ethiopia) and writes Check-In/Check-Out for any day the machine has data for, replacing what''s currently stored. One machine call per employee, so this can take a while for a long range — meant as a one-off final history pull, not routine use.';

                trigger OnAction()
                var
                    PunchPull: Codeunit "Attendance Punch Machine Pull";
                    SelectRange: Page "Select Date Range Dialog";
                    FromDate: Date;
                    ToDate: Date;
                    TotalDaysFilled: Integer;
                begin
                    if SelectRange.RunModal() <> Action::OK then
                        exit;
                    FromDate := SelectRange.GetStartDate();
                    ToDate := SelectRange.GetEndDate();
                    if (FromDate = 0D) or (ToDate = 0D) then
                        exit;
                    if FromDate > ToDate then begin
                        Message('Start Date must be on or before End Date.');
                        exit;
                    end;
                    if not Confirm('Re-fetch punch data from the machine for EVERY tracked employee, from %1 through %2? This calls the machine once per employee and can take a while. Any day it has data for will be written, replacing whatever''s currently stored. Continue?', false, FromDate, ToDate) then
                        exit;
                    TotalDaysFilled := PunchPull.PullHistoricalForAllTracked(FromDate, ToDate);
                    Message('Done. %1 day(s) were filled in across all tracked employees, from %2 through %3.', TotalDaysFilled, FromDate, ToDate);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        AttendanceLog.SetRange("Employee No.", Rec."No.");
        AttendanceLog.SetRange(Date, CalcDate('<-CM>', Today), CalcDate('<CM>', Today));
        AttendanceLog.CalcSums("Day Value");
        CurrentMonthDays := AttendanceLog."Day Value";
    end;

    var
        CurrentMonthDays: Decimal;
}
