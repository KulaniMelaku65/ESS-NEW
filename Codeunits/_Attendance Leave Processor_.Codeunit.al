codeunit 51126 "Attendance Leave Processor"
{
    // Nightly job (schedule via a Job Queue Entry pointing at this codeunit).
    // OnRun re-evaluates the last 7 days ending yesterday. For each active employee on a working day:
    //   - no check-in AND no check-out  -> full-day gap
    //   - check-in xor check-out only   -> half-day gap
    //   - both present                  -> Attended, no action
    // Skips employees already covered by an existing leave application that date.
    //
    // PAUSED: automatic leave deduction for attendance gaps is switched off —
    // see DeductLeaveForAttendanceGaps() below. While paused, a gap only emails
    // the employee's supervisor (Attendance Alert) and is logged as "Flagged";
    // no Leave Application is created and no balance is touched. Flip that one
    // function back to true to resume deducting leave automatically.
    // Every outcome is written back to Employee Attendance Log so a re-run for
    // the same date is a no-op.

    trigger OnRun()
    begin
        ProcessRecentAttendance(true);
    end;

    // Re-evaluates the last 7 days ending yesterday, so a day whose punches
    // were filled in after its first evaluation gets its Processing Result
    // corrected automatically. Alerts only fire on the transition into a
    // flagged state (see ProcessEmployeeAttendance), so a day that stays
    // flagged across runs never emails again.
    procedure ProcessRecentAttendance(SendAlerts: Boolean)
    var
        ToDate: Date;
        RunDate: Date;
    begin
        ToDate := CalcDate('<-1D>', Today());
        RunDate := CalcDate('<-6D>', ToDate);
        while RunDate <= ToDate do begin
            ProcessAttendanceForDate(RunDate, true, SendAlerts);
            RunDate := CalcDate('<1D>', RunDate);
        end;
    end;

    // Reprocess = true forces re-evaluation even for rows already marked
    // Processed — used by the "Backfill" action to correct rows that were
    // processed under old/buggy logic (e.g. a holiday that got logged as
    // Absence Flagged before holiday detection worked). Never re-runs on a
    // row that already has a real auto-created Leave Application attached
    // (Absence Created / Half Day Created), so it can't orphan that
    // reference or create a duplicate leave application.
    //
    // SendAlerts = false skips the per-gap supervisor email entirely (see
    // "Attendance Log Filler", codeunit 51143, which schedules this with
    // SendAlerts:=false for sites that only want the log filled in without
    // per-day emails). The Backfill action on the log list also always
    // passes false — re-running months of history shouldn't re-email
    // supervisors about long-past gaps every time it's clicked.
    procedure ProcessAttendanceForDate(ProcessDate: Date; Reprocess: Boolean; SendAlerts: Boolean)var Employee: Record Employee;
    begin
        Employee.SetRange("Employee Status", Employee."Employee Status"::Active);
        Employee.SetRange("Employee Location", TrackedLocation());
        Employee.SetRange("Country/Region Code", TrackedCountry());
        if Employee.FindSet()then repeat ProcessEmployeeAttendance(Employee."No.", ProcessDate, Reprocess, SendAlerts);
            until Employee.Next() = 0;
    end;

    // Mirrors codeunit 51138 "Attendance Punch Machine Pull" and codeunit
    // 51140 "Attendance Review Mailer" — the same population this whole
    // attendance pipeline covers. Also applies to the "Backfill Processing
    // Since Start" action (page 51130), since it calls straight into
    // ProcessAttendanceForDate above.
    local procedure TrackedLocation(): Code[20]
    begin
        exit('ADDIS ABABA - HQ');
    end;

    local procedure TrackedCountry(): Code[10]
    begin
        // Blank or anything other than Ethiopia is excluded.
        exit('ET');
    end;

    local procedure ProcessEmployeeAttendance(EmployeeNo: Code[20]; ProcessDate: Date; Reprocess: Boolean; SendAlerts: Boolean)var AttendanceLog: Record "Employee Attendance Log";
    RequiredDays: Decimal;
    HalfDay: Boolean;
    AppNo: Code[20];
    DayType: Text[30];
    PreviousResult: Option;
    begin
        if not AttendanceLog.Get(EmployeeNo, ProcessDate)then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No.":=EmployeeNo;
            AttendanceLog.Date:=ProcessDate;
            AttendanceLog.Insert(true);
        end;
        PreviousResult:=AttendanceLog."Processing Result";
        if PreviousResult = AttendanceLog."Processing Result"::"Approved by Manager" then exit;
        if AttendanceLog.Processed then begin
            if not Reprocess then exit;
            if AttendanceLog."Processing Result" in [AttendanceLog."Processing Result"::"Absence Created", AttendanceLog."Processing Result"::"Half Day Created"]then exit;
        end;

        // Log holidays/weekends too (rather than skipping the date
        // entirely) so every calendar day has a row explaining it, not just
        // days someone actually punched or was flagged absent. A Half Day
        // (office open part of the day, not a real holiday) is NOT treated
        // as a holiday here — it falls through to normal attendance
        // evaluation below, based on whatever punches actually exist.
        DayType:=GetDayType(ProcessDate);
        if DayType <> '' then begin
            if(DayType = 'Saturday') or(DayType = 'Sunday')then begin
                FinishLog(AttendanceLog, AttendanceLog."Processing Result"::Weekend, '');
                exit;
            end;
            if not IsHalfWorkingDay(ProcessDate)then begin
                FinishLog(AttendanceLog, AttendanceLog."Processing Result"::Holiday, '');
                exit;
            end;
        end;

        if(AttendanceLog."Check-In Time" <> 0T) and(AttendanceLog."Check-Out Time" <> 0T)then begin
            FinishLog(AttendanceLog, AttendanceLog."Processing Result"::Attended, '');
            exit;
        end;

        HalfDay:=(AttendanceLog."Check-In Time" <> 0T) or(AttendanceLog."Check-Out Time" <> 0T);

        if EmployeeHasLeaveOnDate(EmployeeNo, ProcessDate)then begin
            FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Already On Leave", '');
            exit;
        end;

        if not DeductLeaveForAttendanceGaps()then begin
            if SendAlerts and not IsFlaggedResult(PreviousResult)then
                SendAttendanceAlertEmail(EmployeeNo, ProcessDate, HalfDay);
            if HalfDay then FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Half Day Flagged", '')
            else
                FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Absence Flagged", '');
            exit;
        end;

        RequiredDays:=1.0;
        if HalfDay then RequiredDays:=0.5;

        if not HasSufficientBalance(EmployeeNo, AbsenceLeaveType(), RequiredDays)then begin
            FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Insufficient Balance", '');
            exit;
        end;

        if TryCreateAbsenceLeave(EmployeeNo, ProcessDate, HalfDay, AppNo)then begin
            if HalfDay then FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Half Day Created", AppNo)
            else
                FinishLog(AttendanceLog, AttendanceLog."Processing Result"::"Absence Created", AppNo);
        end
        else
            FinishLog(AttendanceLog, AttendanceLog."Processing Result"::Failed, '');
    end;

    // Single switch for the "pause". False = flag gaps by email only, no leave
    // application, no balance impact. Flip to true to resume auto-deducting
    // ANNUAL LEAVE for missing check-in/out, as it worked before this pause.
    local procedure DeductLeaveForAttendanceGaps(): Boolean
    begin
        exit(false);
    end;

    local procedure SendAttendanceAlertEmail(EmployeeNo: Code[20]; AlertDate: Date; HalfDay: Boolean)var Employee: Record Employee;
    Supervisor: Record Employee;
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    Email: Codeunit Email;
    EmailMessage: Codeunit "Email Message";
    Instr: InStream;
    SNotes: BigText;
    SNotesText: Text;
    Subject: Text;
    Recipient: List of[Text];
    Issue: Text[100];
    Text001: Label '%1';
    begin
        if not Employee.Get(EmployeeNo)then exit;
        if Employee."Supervisor No." = '' then exit;
        if not Supervisor.Get(Employee."Supervisor No.")then exit;
        if Supervisor."Company E-Mail" = '' then exit;
        if not NotificationSetup.Get(NotificationType::"Attendance Alert")then exit;
        if not NotificationSetup."Send Notification" then exit;
        NotificationSetup.CalcFields("Notification Notes");
        NotificationSetup."Notification Notes".CreateInStream(Instr);
        SNotes.Read(Instr);
        if HalfDay then Issue:='Check-in or check-out is missing for part of the day'
        else
            Issue:='No check-in or check-out was recorded';
        Clear(Recipient);
        Recipient.Add(Supervisor."Company E-Mail");
        // %1: Employee No,  %2: Employee Name,  %3: Date,  %4: Issue
        SNotesText:=Format(SNotes);
        SNotesText:=StrSubstNo(SNotesText, Employee."No.", Employee.FullName(), Format(AlertDate), Issue);
        Subject:=StrSubstNo(Text001, Format(NotificationType::"Attendance Alert"));
        EmailMessage.Create(Recipient, Subject, SNotesText, false);
        Email.Send(EmailMessage);
    end;

    local procedure IsFlaggedResult(Result: Option): Boolean
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        exit(Result in [AttendanceLog."Processing Result"::"Absence Flagged", AttendanceLog."Processing Result"::"Half Day Flagged"]);
    end;

    local procedure FinishLog(var AttendanceLog: Record "Employee Attendance Log"; Result: Option; LeaveNo: Code[20])
    begin
        AttendanceLog."Processing Result":=Result;
        AttendanceLog."Leave No.":=LeaveNo;
        AttendanceLog.Processed:=true;
        AttendanceLog.Modify(true);
    end;

    [TryFunction]
    local procedure TryCreateAbsenceLeave(EmployeeNo: Code[20]; LeaveDate: Date; HalfDay: Boolean; var AppNo: Code[20])var WebPortalHRExt: Codeunit "Web Portal HR Ext";
    LeaveDates: array[60] of Date;
    HalfDayFlags: array[60] of Boolean;
    Description: Text[100];
    begin
        Description:='System-generated: missing check-in/out on ' + Format(LeaveDate);
        LeaveDates[1]:=LeaveDate;
        HalfDayFlags[1]:=HalfDay;
        AppNo:=WebPortalHRExt.SubmitMultiDayLeave(EmployeeNo, AbsenceLeaveType(), Description, '', LeaveDates, HalfDayFlags, 1);
    end;

    local procedure AbsenceLeaveType(): Code[10]
    begin
        exit('ANNUAL LEAVE');
    end;

    local procedure EmployeeHasLeaveOnDate(EmployeeNo: Code[20]; CheckDate: Date): Boolean var LeaveApp: Record "Leave Application";
    begin
        LeaveApp.SetRange("Employee No.", EmployeeNo);
        LeaveApp.SetFilter(Status, '<>%1', LeaveApp.Status::Rejected);
        LeaveApp.SetFilter("Start Date", '<=%1', CheckDate);
        LeaveApp.SetFilter("End Date", '>=%1', CheckDate);
        exit(not LeaveApp.IsEmpty());
    end;

    local procedure HasSufficientBalance(EmployeeNo: Code[20]; LeaveTypeCode: Code[20]; RequiredDays: Decimal): Boolean var LeaveLedgerEntry: Record "Leave Ledger Entry";
    HRMgt: Codeunit "HR Management";
    begin
        LeaveLedgerEntry.SetRange("Employee No.", EmployeeNo);
        LeaveLedgerEntry.SetRange("Leave Period", HRMgt.GetCurrentLeavePeriod());
        LeaveLedgerEntry.SetRange("Leave Type", LeaveTypeCode);
        LeaveLedgerEntry.CalcSums("No. of Days");
        exit(LeaveLedgerEntry."No. of Days" >= RequiredDays);
    end;

    // Delegates to "Attendance Day Type" (codeunit 51139) — the same
    // codeunit the attendance log's Day Type column uses — so a date can't
    // be Holiday/Weekend here but something else on screen, or vice versa.
    local procedure GetDayType(CheckDate: Date): Text[30]var DayTypeCU: Codeunit "Attendance Day Type";
    begin
        exit(DayTypeCU.GetDayType(CheckDate));
    end;

    local procedure IsHalfWorkingDay(CheckDate: Date): Boolean var DayTypeCU: Codeunit "Attendance Day Type";
    begin
        exit(DayTypeCU.IsHalfWorkingDay(CheckDate));
    end;
}
