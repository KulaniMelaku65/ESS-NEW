codeunit 51103 "Timesheet Workflow Notify"
{
    procedure SendRejectionEmail(ApprovalEntry: Record "Approval Entry")var MonthlyTimesheetHeader: Record "Monthly Timesheet Header";
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    Employee: Record Employee;
    User: Record User;
    ApprovalCommentLine: Record "Approval Comment Line";
    Email: Codeunit Email;
    EmailMessage: Codeunit "Email Message";
    TargetRecRef: RecordRef;
    Instr: InStream;
    SNotes: BigText;
    SNotesText: Text;
    Subject: Text;
    Recipient: List of[Text];
    RejectionReason: Text;
    ApproverName: Text[100];
    Text001: Label '%1';
    begin
        // ── Step 1: Resolve the Monthly Timesheet Header ──────────────
        if not TargetRecRef.Get(ApprovalEntry."Record ID to Approve")then exit;
        if TargetRecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        TargetRecRef.SetTable(MonthlyTimesheetHeader);
        // ── Step 2: Check Notification Setup ─────────────────────────
        // Same guard as Web Portal HR Ext — exit silently if the
        // notification type is not configured or is switched off.
        if not NotificationSetup.Get(NotificationType::"Timesheet Rejection")then exit;
        if not NotificationSetup."Send Notification" then exit;
        // ── Step 3: Read email body template from Notification Notes ──
        // Same Blob read pattern as Web Portal HR Ext / Leave Reminder.
        NotificationSetup.CalcFields("Notification Notes");
        NotificationSetup."Notification Notes".CreateInStream(Instr);
        SNotes.Read(Instr);
        // ── Step 4: Get rejection reason from Approval Comment Line ───
        // Approver types this in the Comments FactBox on the
        // Requests to Approve page before clicking Reject.
        /* ApprovalCommentLine.Reset();
        ApprovalCommentLine.SetRange("Table ID", Database::"Monthly Timesheet Header");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("User ID", ApprovalEntry."Approver ID");
        if ApprovalCommentLine.FindLast() then
            RejectionReason := ApprovalCommentLine.Comment
        else
            RejectionReason := 'No reason was provided. Please contact your approver directly.'; */
        // ── Update Step 4 in Codeunit 51103 ─────────────────────
        // This change ensures the system finds the comment linked to the CURRENT rejection
        ApprovalCommentLine.Reset();
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        // CRITICAL: Filter by the Step Instance ID so it doesn't get confused by old comments
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        if ApprovalCommentLine.FindLast()then RejectionReason:=ApprovalCommentLine.Comment
        else
            RejectionReason:='No reason provided.';
        // ── Step 5: Resolve approver display name ─────────────────────
        if User.Get(ApprovalEntry."Approver ID")then ApproverName:=User."Full Name"
        else
            ApproverName:=ApprovalEntry."Approver ID";
        // ── Step 6: Resolve employee email ────────────────────────────
        // Same pattern as Web Portal HR Ext — Employee."Company E-Mail"
        if not Employee.Get(MonthlyTimesheetHeader."Employee No.")then exit;
        if Employee."Company E-Mail" = '' then exit;
        // ── Step 7: Substitute placeholders into the template ─────────
        // Same StrSubstNo pattern as Web Portal HR Ext / Leave Reminder.
        SNotesText:=Format(SNotes);
        SNotesText:=StrSubstNo(SNotesText, MonthlyTimesheetHeader."No.", // %1 Timesheet No.
 MonthlyTimesheetHeader."Employee No.", // %2 Employee No.
 Employee."First Name" + ' ' + Employee."Last Name", // %3 Employee Name
 Format(MonthlyTimesheetHeader.Month), // %4 Month
 Format(MonthlyTimesheetHeader.Year), // %5 Year
 Format(MonthlyTimesheetHeader."Total Hours"), // %6 Total Hours
 ApproverName, // %7 Approver Name
 RejectionReason); // %8 Rejection Reason
        // ── Step 8: Build subject from notification type label ────────
        // Same pattern as Web Portal HR Ext.
        Subject:=StrSubstNo(Text001, Format(NotificationType::"Timesheet Rejection"));
        // ── Step 9: Send via Email + Email Message ────────────────────
        // Same send pattern as Web Portal HR Ext — NOT SMTP Mail.
        Clear(Recipient);
        Recipient.Add(Employee."Company E-Mail");
        EmailMessage.Create(Recipient, Subject, SNotesText, false);
        Email.Send(EmailMessage);
    end;
}
