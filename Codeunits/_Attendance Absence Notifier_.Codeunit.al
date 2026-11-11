codeunit 51142 "Attendance Absence Notifier"
{
    // Drives the full-day-absence explain-and-confirm workflow Hayat asked
    // for: employee gets emailed to explain a full-day absence, HR/manager
    // record the reason and a Yes/No confirmation on the "Attendance
    // Absence Explanations" page (page 51142), and a Yes writes the reason
    // back onto the Employee Attendance Log row.
    //
    // Half-day absences are intentionally out of scope for now (Hayat asked
    // to start with full-day only) — only "Absence Flagged" rows create an
    // explanation, not "Half Day Flagged".
    //
    // No inbound-email handling exists in this system, so the employee's
    // reply doesn't get parsed automatically: the notification email just
    // asks them to reply, and whoever reads that reply (HR today, an ESS
    // portal later if one gets wired up) types the reason into the Reason
    // field on page 51142 and runs "Submit Employee Reason". The manager
    // step works the same way via the "Confirm Yes"/"Confirm No" actions.
    //
    // SETUP REQUIRED: Create a Job Queue Entry (search "Job Queue Entries")
    // pointing at this codeunit (51142), recurring daily, ideally early
    // morning (Hayat's example was 8:30am) — same pattern as codeunit
    // 51126/51138. Looks back over the last 7 days rather than just
    // yesterday, so a missed run (weekend, holiday, job queue paused)
    // doesn't silently skip anyone.

    trigger OnRun()
    begin
        CreateExplanationsForRecentAbsences();
    end;

    procedure CreateExplanationsForRecentAbsences()
    var
        AttendanceLog: Record "Employee Attendance Log";
        Explanation: Record "Attendance Absence Explanation";
    begin
        AttendanceLog.SetRange("Processing Result", AttendanceLog."Processing Result"::"Absence Flagged");
        AttendanceLog.SetRange(Date, CalcDate('<-7D>', Today), CalcDate('<-1D>', Today));
        if AttendanceLog.FindSet() then
            repeat
                Explanation.SetRange("Employee No.", AttendanceLog."Employee No.");
                Explanation.SetRange(Date, AttendanceLog.Date);
                if Explanation.IsEmpty() then
                    CreateAndNotifyEmployee(AttendanceLog."Employee No.", AttendanceLog.Date);
            until AttendanceLog.Next() = 0;
    end;

    procedure CreateAndNotifyEmployee(EmployeeNo: Code[20]; AbsenceDate: Date)
    var
        Employee: Record Employee;
        Explanation: Record "Attendance Absence Explanation";
    begin
        if not Employee.Get(EmployeeNo) then
            exit;

        Explanation.Init();
        Explanation."Employee No." := EmployeeNo;
        Explanation.Date := AbsenceDate;
        Explanation.Status := Explanation.Status::"Pending Employee Response";
        Explanation."Manager No." := Employee."Supervisor No.";
        Explanation.Insert(true);

        if Employee."Company E-Mail" = '' then
            exit; // nothing to send, but the record still exists for HR to fill in manually

        SendEmployeeRequestEmail(Employee, AbsenceDate);
        Explanation."Employee Notified On" := CurrentDateTime;
        Explanation.Modify(true);
    end;

    procedure SubmitEmployeeReason(var Explanation: Record "Attendance Absence Explanation"; ReasonText: Text[250])
    var
        Manager: Record Employee;
        Employee: Record Employee;
    begin
        if Explanation.Status <> Explanation.Status::"Pending Employee Response" then
            Error('This entry is not awaiting an employee reason.');
        if ReasonText = '' then
            Error('Enter the reason given before submitting.');

        Explanation.Reason := ReasonText;
        Explanation."Reason Submitted On" := CurrentDateTime;
        Explanation.Status := Explanation.Status::"Pending Manager Confirmation";
        Explanation.Modify(true);

        if (Explanation."Manager No." <> '') and Manager.Get(Explanation."Manager No.") and (Manager."Company E-Mail" <> '') then
            if Employee.Get(Explanation."Employee No.") then begin
                SendManagerConfirmEmail(Manager, Employee, Explanation);
                Explanation."Manager Notified On" := CurrentDateTime;
                Explanation.Modify(true);
            end;
    end;

    procedure ManagerDecide(var Explanation: Record "Attendance Absence Explanation"; Approved: Boolean)
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        if Explanation.Status <> Explanation.Status::"Pending Manager Confirmation" then
            Error('This entry is not awaiting a manager decision.');

        Explanation."Decided On" := CurrentDateTime;
        if Approved then begin
            Explanation."Manager Decision" := Explanation."Manager Decision"::Yes;
            Explanation.Status := Explanation.Status::Confirmed;
            if AttendanceLog.Get(Explanation."Employee No.", Explanation.Date) then begin
                AttendanceLog."Absence Reason" := Explanation.Reason;
                AttendanceLog.Modify(true);
            end;
        end else begin
            Explanation."Manager Decision" := Explanation."Manager Decision"::No;
            Explanation.Status := Explanation.Status::Rejected;
        end;
        Explanation.Modify(true);
    end;

    local procedure SendEmployeeRequestEmail(Employee: Record Employee; AbsenceDate: Date)
    var
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        Recipient: List of [Text];
        Body: Text;
    begin
        Body := '<p>Hi ' + Employee."First Name" + ',</p>' +
                '<p>Our records show you did not check in or out on <b>' + Format(AbsenceDate, 0, '<Day,2>/<Month,2>/<Year4>') + '</b>.</p>' +
                '<p>Please reply to this email with the reason for your absence on that day.</p>' +
                '<p>Thank you.</p>';
        Clear(Recipient);
        Recipient.Add(Employee."Company E-Mail");
        EmailMessage.Create(Recipient, 'Attendance - Please explain your absence on ' + Format(AbsenceDate, 0, '<Day,2>/<Month,2>/<Year4>'), Body, true);
        Email.Send(EmailMessage);
    end;

    local procedure SendManagerConfirmEmail(Manager: Record Employee; Employee: Record Employee; Explanation: Record "Attendance Absence Explanation")
    var
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        Recipient: List of [Text];
        Body: Text;
    begin
        Body := '<p>Hi ' + Manager."First Name" + ',</p>' +
                '<p>' + Employee.FullName() + ' (' + Employee."No." + ') was absent on <b>' + Format(Explanation.Date, 0, '<Day,2>/<Month,2>/<Year4>') + '</b> and gave this reason:</p>' +
                '<p><i>' + Explanation.Reason + '</i></p>' +
                '<p>Please confirm this is accurate by opening the "Attendance Absence Explanations" page in Business Central and choosing Confirm or Reject.</p>' +
                '<p>Thank you.</p>';
        Clear(Recipient);
        Recipient.Add(Manager."Company E-Mail");
        EmailMessage.Create(Recipient, 'Please confirm absence reason for ' + Employee.FullName(), Body, true);
        Email.Send(EmailMessage);
    end;
}
