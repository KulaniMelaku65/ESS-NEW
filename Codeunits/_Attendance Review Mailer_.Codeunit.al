codeunit 51140 "Attendance Review Mailer"
{
    // Sends the monthly attendance review email (weekly hours summary + a
    // day-by-day Monday-Friday breakdown) to every tracked employee, CC'ing
    // their supervisor and HRBP. Reuses the same Employee Attendance Log /
    // Attendance Day Type / Leave Application data everything else in this
    // extension already relies on, so it can't disagree with what those
    // show.
    //
    // SETUP REQUIRED before scheduling:
    //   1. Fill in Employee."HRBP No." for anyone whose HRBP should be
    //      CC'd (blank = no HRBP CC, not an error).
    //   2. Check "Excl. Attendance Review" on the Employee card for SLT /
    //      anyone who should never get this email.
    //   3. Optionally set Human Resources Setup."Weekly Contractual Hours"
    //      (defaults to 43 if left blank).
    //   4. Create a Job Queue Entry pointing at this codeunit (51140),
    //      recurring weekly — same pattern as codeunit 51126/51136/51138.
    //
    // Period cadence: OnRun now defaults to WEEKLY — the most recently
    // completed Monday-Sunday week (never the current, still-in-progress
    // week, so every day being reported on has already fully happened).
    // GetDefaultMonthlyPeriod() (20th-to-20th, matching the original
    // example email) is kept below and still callable directly if a
    // monthly digest is ever wanted instead/as well — just not what
    // OnRun or the manual action use by default any more.

    trigger OnRun()
    var
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        GetDefaultWeeklyPeriod(PeriodStart, PeriodEnd);
        SendAttendanceReviewEmails(PeriodStart, PeriodEnd);
    end;

    procedure GetDefaultWeeklyPeriod(var PeriodStart: Date; var PeriodEnd: Date)
    var
        ThisWeekMonday: Date;
    begin
        ThisWeekMonday := Today - (Date2DWY(Today, 1) - 1);
        PeriodStart := ThisWeekMonday - 7; // last week's Monday
        PeriodEnd := ThisWeekMonday - 1; // last week's Sunday
    end;

    procedure GetDefaultMonthlyPeriod(var PeriodStart: Date; var PeriodEnd: Date)
    var
        AnchorThisMonth: Date;
    begin
        AnchorThisMonth := DMY2Date(20, Date2DMY(Today, 2), Date2DMY(Today, 3));
        if Today >= AnchorThisMonth then
            PeriodEnd := AnchorThisMonth
        else
            PeriodEnd := CalcDate('<-1M>', AnchorThisMonth);
        PeriodStart := CalcDate('<-1M>', PeriodEnd);
    end;

    local procedure TrackedLocation(): Code[20]
    begin
        // Mirrors codeunit 51138 "Attendance Punch Machine Pull" — the
        // same population this whole attendance pipeline actually covers.
        exit('ADDIS ABABA - HQ');
    end;

    local procedure TrackedCountry(): Code[10]
    begin
        // Blank or anything other than Ethiopia is excluded.
        exit('ET');
    end;

    // Guarded against double-sending: if the Job Queue Entry gets run twice
    // for the same period (e.g. set to Ready and then separately restarted
    // — exactly what happened on 9/21/2026, sending every employee,
    // supervisor, and HRBP two copies), an employee already logged as sent
    // for this exact period is skipped rather than emailed again.
    procedure SendAttendanceReviewEmails(PeriodStart: Date; PeriodEnd: Date)
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Employee Location", TrackedLocation());
        Employee.SetRange("Excl. Attendance Review", false);
        Employee.SetFilter("Employee Status", '<>%1', Employee."Employee Status"::Inactive);
        Employee.SetRange("Country/Region Code", TrackedCountry());
        if Employee.FindSet() then
            repeat
                if not AlreadySentForPeriod(Employee."No.", PeriodStart, PeriodEnd) then
                    SendOneReview(Employee, PeriodStart, PeriodEnd);
            until Employee.Next() = 0;
    end;

    local procedure AlreadySentForPeriod(EmployeeNo: Code[20]; PeriodStart: Date; PeriodEnd: Date): Boolean
    var
        SendLog: Record "Attendance Review Send Log";
    begin
        SendLog.SetRange("Employee No.", EmployeeNo);
        SendLog.SetRange("Period Start", PeriodStart);
        SendLog.SetRange("Period End", PeriodEnd);
        exit(not SendLog.IsEmpty());
    end;

    // Sends to exactly this one employee — deliberately ignores the
    // Employee Location / "Excl. Attendance Review" filters (testing a
    // single person regardless of the bulk-run filters) AND the duplicate
    // guard above (so you can intentionally resend to one person to
    // re-test, even if they already got the real one for this period).
    procedure SendReviewForOneEmployee(Employee: Record Employee; PeriodStart: Date; PeriodEnd: Date)
    begin
        SendOneReview(Employee, PeriodStart, PeriodEnd);
    end;

    local procedure SendOneReview(Employee: Record Employee; PeriodStart: Date; PeriodEnd: Date)
    var
        Supervisor: Record Employee;
        HRBP: Record Employee;
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        SendLogger: Codeunit "Attendance Review Send Logger";
        Recipient: List of [Text];
        Body: Text;
        Subject: Text;
        MissingDatesList: Text;
    begin
        if Employee."Company E-Mail" = '' then
            exit;

        Body := BuildBody(Employee, PeriodStart, PeriodEnd, MissingDatesList);
        Subject := 'Attendance Review - ' + FormatPeriodLabel(PeriodStart, PeriodEnd);

        Clear(Recipient);
        Recipient.Add(Employee."Company E-Mail");
        EmailMessage.Create(Recipient, Subject, Body, true);

        if (Employee."Supervisor No." <> '') and Supervisor.Get(Employee."Supervisor No.") then
            if Supervisor."Company E-Mail" <> '' then
                EmailMessage.AddRecipient(Enum::"Email Recipient Type"::Cc, Supervisor."Company E-Mail");

        if (Employee."HRBP No." <> '') and HRBP.Get(Employee."HRBP No.") then
            if HRBP."Company E-Mail" <> '' then
                EmailMessage.AddRecipient(Enum::"Email Recipient Type"::Cc, HRBP."Company E-Mail");

        Email.Send(EmailMessage);
        // The email above has already gone out at this point. Sending an
        // email forces an implicit commit-like boundary, and BC does not
        // allow a [TryFunction] to write to the database after that when
        // running under a Job Queue Entry ("Call to the function 'INSERT'
        // is not allowed inside the call to 'X' when it is used as a
        // TryFunction" — seen in production on 9/21/2026, though it never
        // showed up testing via the manual "Send Review" action, since
        // interactive sends don't hit this restriction). A failure writing
        // the log entry must still never be allowed to abort the rest of
        // the batch, so it's isolated in a separate SingleInstance codeunit
        // invoked via Codeunit.Run(), which BC does allow post-commit —
        // see "Attendance Review Send Logger" (codeunit 51148).
        SendLogger.SetParameters(Employee, Supervisor, HRBP, PeriodStart, PeriodEnd);
        if not Codeunit.Run(Codeunit::"Attendance Review Send Logger") then;
    end;

    local procedure FormatPeriodLabel(PeriodStart: Date; PeriodEnd: Date): Text
    begin
        exit(Format(PeriodStart, 0, '<Month Text> <Day,2>') + ' to ' + Format(PeriodEnd, 0, '<Month Text> <Day,2>, <Year4>'));
    end;

    local procedure BuildBody(Employee: Record Employee; PeriodStart: Date; PeriodEnd: Date; var MissingDatesList: Text): Text
    var
        Body: Text;
        WeeklyTable: Text;
        DailyTable: Text;
    begin
        WeeklyTable := BuildWeeklySummary(Employee."No.", PeriodStart, PeriodEnd);
        DailyTable := BuildDailyDetail(Employee."No.", PeriodStart, PeriodEnd, MissingDatesList);

        Body += '<p>Dear ' + Employee.FullName() + ',</p>';
        Body += '<p>This email relates to your attendance record for the period from ' + FormatPeriodLabel(PeriodStart, PeriodEnd) + '.</p>';
        Body += '<p>As part of HR''s attendance review, please take the following actions:</p>';
        Body += '<ol>';
        Body += '<li>';
        if MissingDatesList <> '' then begin
            Body += 'Update ESS/attendance records for the following dates where no clock-in or clock-out is recorded: ' + MissingDatesList + '. ';
            Body += 'Where a date reflects approved leave, travel, field/off-site work, or another authorized arrangement, please ensure this is correctly recorded in ESS.';
        end else
            Body += 'No missing clock-in/clock-out dates were found for this period — thank you for keeping your attendance up to date.';
        Body += '</li>';
        Body += '<li>Ensure that you consistently tap in and out each working day so that attendance is accurately tracked and does not create issues during monthly attendance and payroll processing.</li>';
        Body += '<li>Review the weekly summary and detailed record below and flag any discrepancy to HR promptly.</li>';
        Body += '</ol>';

        Body += '<h3>Attendance Summary</h3>';
        Body += WeeklyTable;
        Body += '<p style="font-size:11px;color:#666;">* An incomplete week is shown for consistency; its Difference is not a complete weekly variance. * Contractual hours benchmark: ' + Format(GetContractualHours()) + ' hours per week, reduced for each working day that is a company holiday or approved leave (half a day for a half-day holiday or half-day leave). * A day absent from the clock but explained and approved by your manager is credited with your average worked day that week (8 hours if you had no clock-ins that week).</p>';

        Body += '<p>Please complete any required ESS/attendance corrections promptly. Going forward, please ensure your attendance is consistently and accurately captured through both clock-in and clock-out records.</p>';
        Body += '<p>The detailed attendance report for this period is included below for your reference.</p>';
        Body += '<p>Regards,<br>HR</p>';

        Body += '<h3>Detailed Attendance Report - ' + Employee.FullName() + '</h3>';
        Body += '<p>Attendance period: ' + FormatPeriodLabel(PeriodStart, PeriodEnd) + '<br>';
        Body += 'Employee: ' + Employee.FullName() + ' | ID: ' + Employee."No." + '<br>';
        Body += 'Attendance key: <span style="background-color:#f4cccc;">RED</span> = no clock-in/out recorded; <span style="background-color:#fff2cc;">YELLOW</span> = one tap is missing; <span style="background-color:#d9ead3;">GREEN</span> = on approved leave; <span style="background-color:#cfe2f3;">BLUE</span> = holiday; <span style="background-color:#d9d2e9;">PURPLE</span> = absence explained and approved by manager.</p>';
        Body += DailyTable;

        exit(Body);
    end;

    local procedure GetContractualHours(): Decimal
    var
        HRSetup: Record "Human Resources Setup";
    begin
        if HRSetup.Get() and (HRSetup."Weekly Contractual Hours" > 0) then
            exit(HRSetup."Weekly Contractual Hours");
        exit(43);
    end;

    // ── Weekly summary table ──────────────────────────────────────────
    local procedure BuildWeeklySummary(EmployeeNo: Code[20]; PeriodStart: Date; PeriodEnd: Date): Text
    var
        Html: Text;
        WeekStart: Date;
        WeekEnd: Date;
        WeekIndex: Integer;
        ContractualHours: Decimal;
        WeekContractual: Decimal;
        LeaveDays: Decimal;
        WorkedHours: Decimal;
        Difference: Decimal;
    begin
        ContractualHours := GetContractualHours();
        Html := '<table border="1" cellpadding="4" cellspacing="0" style="border-collapse:collapse;">';
        Html += '<tr><th>Week / dates</th><th>Total hours worked</th><th>Contractual hours</th><th>Difference</th></tr>';

        WeekStart := PeriodStart - (Date2DWY(PeriodStart, 1) - 1); // normalize back to that week's Monday
        WeekIndex := 0;
        while WeekStart <= PeriodEnd do begin
            WeekIndex += 1;
            WeekEnd := WeekStart + 5; // Saturday
            if WeekEnd > PeriodEnd then
                WeekEnd := PeriodEnd;

            WorkedHours := SumWorkedHours(EmployeeNo, WeekStart, WeekEnd);
            // Nobody is expected to work on a company holiday or a day of
            // approved leave, so each such day comes off the week's
            // contractual hours (a fifth of the weekly figure per day; a
            // half-day holiday or half-day leave, half of that).
            LeaveDays := DaysOffInRange(EmployeeNo, WeekStart, WeekEnd);
            WeekContractual := ContractualHours - LeaveDays * (ContractualHours / 5);
            Difference := WorkedHours - WeekContractual;

            Html += '<tr><td>Week ' + Format(WeekIndex) + ': ' + FormatDateRange(WeekStart, WeekEnd) + '</td>';
            Html += '<td>' + FormatHours(WorkedHours) + '</td>';
            Html += '<td>' + FormatHours(WeekContractual);
            if LeaveDays > 0 then
                Html += ' <span style="font-size:11px;color:#666;">(' + FormatHours(ContractualHours) + ' less ' + Format(LeaveDays) + ' day(s) leave/holiday)</span>';
            Html += '</td>';
            Html += '<td>' + FormatHours(Difference) + '</td></tr>';

            WeekStart := WeekStart + 7;
        end;
        Html += '</table>';
        exit(Html);
    end;

    // Working days (Mon-Fri) the employee isn't expected to work in the
    // range: company holidays (a half-day holiday counts 0.5) and approved
    // leave (a half-day leave counts 0.5). Same holiday/leave lookups the
    // daily detail table uses, so the two can't disagree about which days
    // those are.
    local procedure DaysOffInRange(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        RunDate: Date;
        TotalDays: Decimal;
    begin
        RunDate := FromDate;
        while RunDate <= ToDate do begin
            if Date2DWY(RunDate, 1) <= 5 then
                TotalDays += DayOffFraction(EmployeeNo, RunDate);
            RunDate := CalcDate('<1D>', RunDate);
        end;
        exit(TotalDays);
    end;

    // How much of one working day is not expected: 1 for a full company
    // holiday; 0.5 for a half-day holiday plus whatever of the remaining half
    // approved leave covers; otherwise the leave itself (1 full, 0.5 half).
    // Leave never takes more than the day still has left, so a leave on top
    // of a holiday can't be deducted twice.
    local procedure DayOffFraction(EmployeeNo: Code[20]; CheckDate: Date): Decimal
    var
        DayTypeCU: Codeunit "Attendance Day Type";
        LeaveCalc: Codeunit "Leave Half Day Calculator";
        IsHalfDayLeave: Boolean;
        HolidayFraction: Decimal;
        LeaveFraction: Decimal;
        Remaining: Decimal;
    begin
        if DayTypeCU.GetDayType(CheckDate) <> '' then begin
            if not DayTypeCU.IsHalfWorkingDay(CheckDate) then
                exit(1);
            HolidayFraction := 0.5;
        end;
        Remaining := 1 - HolidayFraction;

        if LeaveCalc.GetLeaveStatus(EmployeeNo, CheckDate, IsHalfDayLeave) <> '' then begin
            if IsHalfDayLeave then
                LeaveFraction := 0.5
            else
                LeaveFraction := 1;
            if LeaveFraction > Remaining then
                LeaveFraction := Remaining;
        end;
        exit(HolidayFraction + LeaveFraction);
    end;

    local procedure FormatDateRange(FromDate: Date; ToDate: Date): Text
    begin
        if Date2DMY(FromDate, 2) = Date2DMY(ToDate, 2) then
            exit(Format(FromDate, 0, '<Month Text> <Day,2>') + ' to ' + Format(ToDate, 0, '<Day,2>'))
        else
            exit(Format(FromDate, 0, '<Month Text> <Day,2>') + ' to ' + Format(ToDate, 0, '<Month Text> <Day,2>'));
    end;

    local procedure SumWorkedHours(EmployeeNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        AttendanceLog: Record "Employee Attendance Log";
        TotalHours: Decimal;
        RunDate: Date;
    begin
        RunDate := FromDate;
        while RunDate <= ToDate do begin
            if AttendanceLog.Get(EmployeeNo, RunDate) then
                TotalHours += AttendanceLog.GetHoursWorked();
            RunDate := CalcDate('<1D>', RunDate);
        end;
        exit(TotalHours);
    end;

    // ── Daily detail table (Monday-Friday only) ───────────────────────
    local procedure BuildDailyDetail(EmployeeNo: Code[20]; PeriodStart: Date; PeriodEnd: Date; var MissingDatesList: Text): Text
    var
        AttendanceLog: Record "Employee Attendance Log";
        DayTypeCU: Codeunit "Attendance Day Type";
        LeaveCalc: Codeunit "Leave Half Day Calculator";
        Html: Text;
        RunDate: Date;
        DayType: Text[30];
        ApprovedLeaveNo: Code[20];
        IsHalfDayLeave: Boolean;
        LeaveNote: Text;
        ApprovalNote: Text;
        EstimatedHours: Decimal;
        RowColor: Text;
        ClockInText: Text;
        ClockOutText: Text;
        TotalText: Text;
        HasLog: Boolean;
    begin
        Html := '<table border="1" cellpadding="4" cellspacing="0" style="border-collapse:collapse;">';
        Html += '<tr><th>Date</th><th>Weekday</th><th>Clock In</th><th>Clock Out</th><th>Total Time</th></tr>';

        RunDate := PeriodStart;
        while RunDate <= PeriodEnd do begin
            if Date2DWY(RunDate, 1) <= 5 then begin // Monday..Friday only
                RowColor := '';
                ClockInText := '-';
                ClockOutText := '-';
                TotalText := '-';

                DayType := DayTypeCU.GetDayType(RunDate);
                if DayType <> '' then begin
                    RowColor := 'background-color:#cfe2f3;'; // holiday (blue) — weekends never reach here
                    ClockInText := DayType;
                    ClockOutText := '';
                    TotalText := '';
                    // A half-day company holiday is still worked in the
                    // morning, and those hours count in the weekly total —
                    // so show that day's total time (not the clock times,
                    // which stay hidden on a holiday row).
                    if DayTypeCU.IsHalfWorkingDay(RunDate) and AttendanceLog.Get(EmployeeNo, RunDate) then
                        if (AttendanceLog."Check-In Time" <> 0T) and (AttendanceLog."Check-Out Time" > AttendanceLog."Check-In Time") then
                            TotalText := FormatDurationHHMM(DurationBetween(AttendanceLog."Check-In Time", AttendanceLog."Check-Out Time"))
                        else begin
                            EstimatedHours := AttendanceLog.GetHoursWorked();
                            if EstimatedHours > 0 then
                                TotalText := FormatHours(EstimatedHours) + ' (est.)';
                        end;
                end else begin
                    ApprovedLeaveNo := LeaveCalc.GetLeaveStatus(EmployeeNo, RunDate, IsHalfDayLeave);

                    // Show real punch data whenever it exists, on-leave or
                    // not — someone can be on approved leave and still have
                    // come in. Leave just adds a note; it never hides an
                    // actual clock-in/clock-out.
                    HasLog := AttendanceLog.Get(EmployeeNo, RunDate);
                    if HasLog and (AttendanceLog."Check-In Time" <> 0T) then
                        ClockInText := FormatHHMM(AttendanceLog."Check-In Time");
                    if HasLog and (AttendanceLog."Check-Out Time" <> 0T) then
                        ClockOutText := FormatHHMM(AttendanceLog."Check-Out Time");

                    if ApprovedLeaveNo <> '' then begin
                        RowColor := 'background-color:#d9ead3;'; // on leave (green)
                        if IsHalfDayLeave then
                            LeaveNote := 'On Leave - Half Day (' + ApprovedLeaveNo + ')'
                        else
                            LeaveNote := 'On Leave (' + ApprovedLeaveNo + ')';
                        if (ClockInText <> '-') and (ClockOutText <> '-') then
                            TotalText := FormatDurationHHMM(DurationBetween(AttendanceLog."Check-In Time", AttendanceLog."Check-Out Time")) + ' - ' + LeaveNote
                        else
                            if (ClockInText = '-') and (ClockOutText = '-') then begin
                                ClockInText := LeaveNote;
                                ClockOutText := '';
                            end else
                                TotalText := LeaveNote;
                    end else
                        if HasLog and (AttendanceLog."Processing Result" = AttendanceLog."Processing Result"::"Approved by Manager") then begin
                            RowColor := 'background-color:#d9d2e9;'; // absence explained & approved (purple)
                            if AttendanceLog."Absence Reason" <> '' then
                                ApprovalNote := 'Approved by Manager: ' + AttendanceLog."Absence Reason"
                            else
                                ApprovalNote := 'Approved by Manager';
                            EstimatedHours := AttendanceLog.GetHoursWorked();
                            if (ClockInText = '-') and (ClockOutText = '-') then begin
                                // No punch at all — nothing real to show, so
                                // the note becomes the display text, same as
                                // the Leave case above.
                                ClockInText := ApprovalNote;
                                ClockOutText := '';
                                if EstimatedHours > 0 then
                                    TotalText := FormatHours(EstimatedHours) + ' (est.)';
                            end else
                                // A real punch exists (e.g. checked in, never
                                // checked out) — keep it visible rather than
                                // hiding what actually happened; the note and
                                // estimate go in Total Time instead.
                                if EstimatedHours > 0 then
                                    TotalText := FormatHours(EstimatedHours) + ' (est.) - ' + ApprovalNote
                                else
                                    TotalText := ApprovalNote;
                        end else begin
                            if (ClockInText <> '-') and (ClockOutText <> '-') then
                                TotalText := FormatDurationHHMM(DurationBetween(AttendanceLog."Check-In Time", AttendanceLog."Check-Out Time"))
                            else
                                if (ClockInText = '-') and (ClockOutText = '-') then begin
                                    RowColor := 'background-color:#f4cccc;'; // full gap (red)
                                    if MissingDatesList <> '' then
                                        MissingDatesList += '; ';
                                    MissingDatesList += Format(RunDate, 0, '<Month Text> <Day,2>');
                                end else
                                    RowColor := 'background-color:#fff2cc;'; // half gap (yellow)
                        end;
                end;

                Html += '<tr style="' + RowColor + '">';
                Html += '<td>' + Format(RunDate, 0, '<Year4>-<Month,2>-<Day,2>') + '</td>';
                Html += '<td>' + WeekdayName(RunDate) + '</td>';
                Html += '<td>' + ClockInText + '</td>';
                Html += '<td>' + ClockOutText + '</td>';
                Html += '<td>' + TotalText + '</td></tr>';
            end;
            RunDate := CalcDate('<1D>', RunDate);
        end;

        Html += '</table>';
        exit(Html);
    end;

    // ── Safe formatting helpers ────────────────────────────────────────
    // Custom Format() strings are only validated at runtime, not compile
    // time, and this codebase never relies on them for Time/weekday text
    // elsewhere (see Calendar Day Generator / Leave Application Day, which
    // both compute weekday names manually) — so these avoid custom format
    // strings entirely rather than risk another bad tag.
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

    local procedure FormatHHMM(T: Time): Text
    begin
        if T = 0T then
            exit('');
        exit(FormatDurationHHMM(DurationBetween(0T, T)));
    end;

    // Bare Time - Time subtraction is what actually threw "The date is not
    // valid" (confirmed via debugger) — going through CreateDateTime with a
    // real, valid Date on both sides avoids whatever the platform does
    // internally with Time-only arithmetic.
    local procedure DurationBetween(StartTime: Time; EndTime: Time): Duration
    begin
        exit(CreateDateTime(Today, EndTime) - CreateDateTime(Today, StartTime));
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

    local procedure PadZero(N: Integer): Text
    begin
        if N < 10 then
            exit('0' + Format(N));
        exit(Format(N));
    end;

    local procedure FormatHours(V: Decimal): Text
    var
        Rounded: Decimal;
        IsNegative: Boolean;
        WholePart: Integer;
        FracPart: Integer;
    begin
        IsNegative := V < 0;
        Rounded := Round(V, 0.01);
        if IsNegative then
            Rounded := -Rounded;
        WholePart := Round(Rounded, 1, '<');
        FracPart := Round((Rounded - WholePart) * 100, 1);
        if IsNegative and ((WholePart <> 0) or (FracPart <> 0)) then
            exit('-' + Format(WholePart) + '.' + PadZero(FracPart));
        exit(Format(WholePart) + '.' + PadZero(FracPart));
    end;

}
