codeunit 51102 "Web Portal HR Ext"
{
    // Extension codeunit - do not modify Web Portal HR (52179060)
    // do not modify Notifications Management HR (52179058)
    // do not modify Approvals Mgmt. HR (52179056)
    // Purpose: employee email notifications on leave submission/approval/rejection,
    // plus multi-day/half-day leave submission (PATH 4) and cancellation (PATH 5).
    // Covers, for the notification outcomes:
    //   1. Web app calling SupervisorLeaveRejectionWithNotification (reject only)
    //   2. Direct status change on Leave Application table (ERP manual, or the
    //      ESS web portal calling WebPortalHR.ApproveDocument/RejectDocument —
    //      both go through the base Approvals Mgmt. engine and end up modifying
    //      the Leave Application record, so this single subscriber catches
    //      every entry point, portal included)
    //   3. Approver rejecting from Requests to Approve page (Approval Engine)
    //
    // Rejection (by the supervisor/approver) and cancellation (by the employee,
    // PATH 5) both land as the exact same Pending Approval -> Open transition
    // on the header, so PATH 2 can't tell them apart from the change alone.
    // IsCancelling is how PATH 5 tells PATH 2 "this Open transition is mine,
    // it's a cancellation, don't send the rejection email for it."
    // ---------------------------------------------------------------
    SingleInstance = true;

    var IsCancelling: Boolean;
    IsRejectingWithReason: Boolean;
    // ---------------------------------------------------------------
    // PATH 3 — Approver rejects from "Requests to Approve" page
    // ---------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure OnApprovalRejected(var ApprovalEntry: Record "Approval Entry")begin
        if ApprovalEntry."Table ID" <> Database::"Leave Application" then exit;
        SendLeaveRejectionEmail(ApprovalEntry."Document No.", '');
    end;
    // ---------------------------------------------------------------
    // PATH 2 — Direct status change on Leave Application (covers the ESS
    // portal's ApproveDocument/RejectDocument calls, since both route through
    // the base approval engine and land here as a Modify on the header)
    // ---------------------------------------------------------------
    [EventSubscriber(ObjectType::Table, Database::"Leave Application", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnLeaveApplicationModified(var Rec: Record "Leave Application";
    var xRec: Record "Leave Application";
    RunTrigger: Boolean)begin
        // Submission — Open -> Pending Approval. HRLeaveApplication does this as
        // Insert(Open) immediately followed by Modify(Pending Approval), and
        // SubmitMultiDayLeave (PATH 4 below) does the same inside its one call.
        if(xRec.Status = xRec.Status::Open) and(Rec.Status = Rec.Status::"Pending Approval")then begin
            SendLeaveSubmissionEmail(Rec."No.");
            exit;
        end;
        if not(xRec.Status = xRec.Status::"Pending Approval")then exit;
        if Rec.Status = Rec.Status::Open then begin
            if not IsCancelling and not IsRejectingWithReason then SendLeaveRejectionEmail(Rec."No.", '');
            exit;
        end;
        // Only fire once, when the chain reaches its final Approved state —
        // not on every intermediate step of a multi-approver workflow.
        if Rec.Status = Rec.Status::Approved then SendLeaveApprovalEmail(Rec."No.");
    end;
    // ---------------------------------------------------------------
    // PATH 1 — Web App calls this procedure directly
    // ---------------------------------------------------------------
    procedure SupervisorLeaveRejectionWithNotification(DocumentNo: Code[50];
    RejectionReason: Text[250])ReturnMsg: Text var WebPortalHR: Codeunit "Web Portal HR";
    begin
        IsRejectingWithReason:=true;
        ReturnMsg:=WebPortalHR.SupervisorLeaveRejection(DocumentNo);
        IsRejectingWithReason:=false;
        if ReturnMsg <> 'SUCCESS' then exit;
        SendLeaveRejectionEmail(DocumentNo, RejectionReason);
        ReturnMsg:='SUCCESS';
    end;
    // ---------------------------------------------------------------
    // PATH 1B — Web App calls this to approve. Pure pass-through to
    // WebPortalHR.SupervisorLeaveApproval (Status -> Approved, then posts the
    // leave via HR Management) — same return values it already gives
    // ('SUCCESS', 'Failed! Leave Already Posted', or blank if not found).
    // No explicit email call needed here: PATH 2's OnLeaveApplicationModified
    // subscriber already fires SendLeaveApprovalEmail automatically the
    // moment Status flips to Approved, same as it does for any other caller
    // of SupervisorLeaveApproval. Adding an explicit send here would double
    // the email, the same bug PATH 1's IsRejectingWithReason guard exists to
    // avoid — approval doesn't need that guard because there's no second,
    // richer email competing with PATH 2's for this transition.
    // ---------------------------------------------------------------
    procedure SupervisorLeaveApprovalWithNotification(DocumentNo: Code[50]) ReturnMsg: Text var WebPortalHR: Codeunit "Web Portal HR";
    begin
        ReturnMsg:=WebPortalHR.SupervisorLeaveApproval(DocumentNo);
    end;
    // ---------------------------------------------------------------
    // PATH 4 — Multi-day / half-day leave submission. Lets the portal build a
    // leave application out of individual dates (each optionally a half day)
    // instead of the single contiguous Start Date + No. of Days that
    // WebPortalHR.HRLeaveApplication expects.
    //
    // One atomic call. The portal accumulates the employee's date picks on its
    // own side and only calls this once they actually submit — the header
    // Insert (and the No. Series number that comes with it) happens inside
    // this same call, right before it goes to Pending Approval. Nothing is
    // written to BC, and no number is consumed, while the employee is still
    // picking dates or if they change their mind before submitting.
    //
    // LeaveDates/HalfDayFlags are fixed-size arrays (SOAP has no native
    // variable-length list) — only the first NoOfDates entries are read.
    // Reuses Fanisi's own approval hand-off (Team Lead check, workflow
    // enablement, Pending Approval status, notification) the same way
    // HRLeaveApplication's update branch does it — but WITHOUT validating
    // Leave Type/Start Date the way that branch does, because that would
    // re-run GetLeaveDates and compute an End Date assuming one contiguous
    // block, which non-sequential dates are not.
    // ---------------------------------------------------------------
    procedure SubmitMultiDayLeave(EmployeeNo: Code[20]; LeaveTypeCode: Code[20]; Description: Text[100]; RelieverNo: Code[20];
    LeaveDates: array[60] of Date; HalfDayFlags: array[60] of Boolean; NoOfDates: Integer) AppNo: Code[20]var LeaveApplication: Record "Leave Application";
    LeaveDay: Record "Leave Application Day";
    ApprovalsMgmt: Codeunit "Approvals Mgmt. HR";
    NotificationMgt: Codeunit "Notifications Management HR";
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    i: Integer;
    NoDatesErr: Label 'At least one leave date is required.';
    begin
        if(NoOfDates < 1) or(NoOfDates > ArrayLen(LeaveDates))then Error(NoDatesErr);

        LeaveApplication.Init();
        LeaveApplication.Validate("Employee No.", EmployeeNo);
        LeaveApplication.Validate("Leave Type", LeaveTypeCode);
        LeaveApplication.Description:=Description;
        if RelieverNo <> '' then LeaveApplication.Validate("Reliever No.", RelieverNo);
        LeaveApplication.Insert(true);
        AppNo:=LeaveApplication."No.";

        for i:=1 to NoOfDates do begin
            LeaveDay.Init();
            LeaveDay."Leave No.":=AppNo;
            // Assigned directly rather than left for the table's own OnInsert
            // trigger to work out via FindLast() — that lookup-then-insert
            // pattern races if this same request ever fires twice in close
            // succession (double-submit, client retry): two calls can both
            // see "no lines yet" and both land on Line No. 10000. Since we
            // already know we're inserting NoOfDates fresh lines in order
            // under a header we just created ourselves, there's nothing to
            // look up — just number them 10000, 20000, 30000...
            LeaveDay."Line No.":=i * 10000;
            LeaveDay."Half Day Requested":=HalfDayFlags[i];
            LeaveDay.Validate(Date, LeaveDates[i]);
            LeaveDay.Insert(true);
        end;

        // Each LeaveDay.Insert() above triggers Leave Half Day Calculator's
        // OnAfterInsertEvent subscriber, which recalculates and writes the
        // header's No. of Days/Start Date/End Date from the day lines — but
        // it does that through its OWN LeaveApp variable. Our LeaveApplication
        // here is still holding what it looked like right after the empty
        // Insert() above (No. of Days = 0, dates blank). Re-fetch before we
        // touch it again, or the Modify() below overwrites the correct
        // calculator-derived totals with those stale zeros — which is
        // exactly what was landing in the header and the Leave Reminder email.
        LeaveApplication.Get(AppNo);

        if LeaveApplication."Team Lead" then begin
            if ApprovalsMgmt.CheckLeaveApplicationApprovalsWorkflowEnabled(LeaveApplication)then ApprovalsMgmt.OnSendLeaveApplicationForApproval(LeaveApplication);
        end
        else begin
            LeaveApplication.Status:=LeaveApplication.Status::"Pending Approval";
            LeaveApplication.Modify();
            if NotificationSetup.Get(NotificationType::"Leave Reminder")then if NotificationSetup."Send Notification" then begin
                    NotificationMgt.GetLeaveApp(LeaveApplication);
                    NotificationMgt.SendNotification(NotificationSetup);
                end;
        end;
    end;
    // ---------------------------------------------------------------
    // PATH 5 — Employee cancels their own leave request. Modify-and-resubmit
    // pattern: there's no in-place edit of an already-submitted request —
    // cancel it here, then call SubmitMultiDayLeave again for the new dates.
    // Reuses Fanisi's own cancellation (workflow cancel + Status back to Open)
    // unchanged; only adds the guard so PATH 2 doesn't also fire the rejection
    // email for this same Open transition.
    // ---------------------------------------------------------------
    procedure CancelMultiDayLeave(AppNo: Code[20]) ReturnMsg: Text var WebPortalHR: Codeunit "Web Portal HR";
    begin
        IsCancelling:=true;
        ReturnMsg:=WebPortalHR.HRCancelLeaveApplication(AppNo);
        IsCancelling:=false;
    end;
    // ---------------------------------------------------------------
    // PATH 6 — ESS self-service profile updates. Deliberately a hardcoded
    // whitelist of fields (phone, current address, emergency contact) — never
    // a generic "update any field" entry point. Everything else on the
    // Employee card (salary, job title, department, employment dates, etc.)
    // stays HR/admin-only.
    //
    // Gated the same way the base app already gates Employee Emergency
    // Contact inserts/deletes: via the "Edit Employee" FlowField (true only
    // while Employee Status is New or Active) — blank ReturnMsg means
    // "not found or not allowed to self-edit", same convention as
    // UpdateStaffPass/ChangeStaffPassword above (no exception, just blank).
    // ---------------------------------------------------------------
    procedure UpdateStaffPhoneNo(EmployeeNo: Code[20]; PhoneNo: Text[30]) ReturnMsg: Text
    var
        Employee: Record Employee;
    begin
        if not CanSelfEdit(EmployeeNo, Employee) then exit;
        Employee.Validate("Phone No.", PhoneNo);
        Employee.Modify(true);
        ReturnMsg := 'SUCCESS';
    end;

    // CountryCode blank is allowed (clears the field) — TableRelation
    // integrity for a non-blank value is still enforced by Validate().
    procedure UpdateStaffAddress(EmployeeNo: Code[20]; CountryCode: Code[20]; Region: Text[50]; SubCounty: Text[50]; Wereda: Text[50]; HouseNo: Text[50]) ReturnMsg: Text
    var
        Employee: Record Employee;
    begin
        if not CanSelfEdit(EmployeeNo, Employee) then exit;
        Employee.Validate("Curr Address Country", CountryCode);
        Employee.Validate(Region, Region);
        Employee.Validate("Sub-County", SubCounty);
        Employee.Validate(Wereda, Wereda);
        Employee.Validate("House No.", HouseNo);
        Employee.Modify(true);
        ReturnMsg := 'SUCCESS';
    end;

    // Upsert: LineNo = 0 (or a Line No. that doesn't exist yet for this
    // employee) inserts a new emergency contact; an existing Line No.
    // modifies it in place. Mirrors the 10000-step Line No. convention
    // SubmitMultiDayLeave (PATH 4) uses elsewhere in this codeunit.
    procedure UpdateStaffEmergencyContact(EmployeeNo: Code[20]; LineNo: Integer; FirstName: Text[30]; MiddleName: Text[30]; LastName: Text[30]; PhoneNo: Text[30]; Email: Text[80]; ContactLocation: Text[30]; RelativeCode: Code[10]) ReturnMsg: Text
    var
        Employee: Record Employee;
        EmergencyContact: Record "Employee Emergency Contact";
    begin
        if not CanSelfEdit(EmployeeNo, Employee) then exit;

        if (LineNo = 0) or not EmergencyContact.Get(EmployeeNo, LineNo) then begin
            EmergencyContact.Reset();
            EmergencyContact.SetRange("Employee No.", EmployeeNo);
            if EmergencyContact.FindLast() then
                LineNo := EmergencyContact."Line No." + 10000
            else
                LineNo := 10000;
            EmergencyContact.Init();
            EmergencyContact."Employee No." := EmployeeNo;
            EmergencyContact."Line No." := LineNo;
            EmergencyContact.Validate("First Name", FirstName);
            EmergencyContact.Validate("Middle Name", MiddleName);
            EmergencyContact.Validate("Last Name", LastName);
            EmergencyContact.Validate("Phone No.", PhoneNo);
            EmergencyContact.Validate("E-Mail", Email);
            EmergencyContact.Validate(Location, ContactLocation);
            EmergencyContact.Validate("Relative Code", RelativeCode);
            EmergencyContact.Insert(true); // table's own OnInsert re-checks "Edit Employee" too
        end else begin
            EmergencyContact.Validate("First Name", FirstName);
            EmergencyContact.Validate("Middle Name", MiddleName);
            EmergencyContact.Validate("Last Name", LastName);
            EmergencyContact.Validate("Phone No.", PhoneNo);
            EmergencyContact.Validate("E-Mail", Email);
            EmergencyContact.Validate(Location, ContactLocation);
            EmergencyContact.Validate("Relative Code", RelativeCode);
            EmergencyContact.Modify(true);
        end;
        ReturnMsg := 'SUCCESS';
    end;

    local procedure CanSelfEdit(EmployeeNo: Code[20]; var Employee: Record Employee): Boolean
    begin
        if not Employee.Get(EmployeeNo) then exit(false);
        Employee.CalcFields("Edit Employee");
        exit(Employee."Edit Employee");
    end;

    // ---------------------------------------------------------------
    // SHARED EMAIL LOGIC
    // Mirrors Leave Reminder pattern exactly — only difference is
    // recipient is the EMPLOYEE not the supervisor
    // ---------------------------------------------------------------
    local procedure SendLeaveRejectionEmail(DocumentNo: Code[50];
    RejectionReason: Text[250])var LeaveApp: Record "Leave Application"; // same var name as Leave Reminder
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    Employee: Record Employee; // same var name as Leave Reminder
    Email: Codeunit Email; // same
    EmailMessage: Codeunit "Email Message"; // same
    Instr: InStream; // same
    SNotes: BigText; // same
    SNotesText: Text; // same
    Subject: Text; // same
    Recipient: List of[Text]; // same
    Text001: Label '%1'; // same
    begin
        // Same pattern: SetRange on "No." then FindFirst
        LeaveApp.Reset();
        LeaveApp.SetRange("No.", DocumentNo);
        if LeaveApp.FindFirst()then begin
            if not NotificationSetup.Get(NotificationType::"Leave Rejection")then exit;
            if not NotificationSetup."Send Notification" then exit;
            // Same Blob read pattern as Leave Reminder
            NotificationSetup.CalcFields("Notification Notes");
            NotificationSetup."Notification Notes".CreateInStream(Instr);
            SNotes.Read(Instr);
            // Same pattern — but Employee.Get uses Employee No. (not Supervisor No.)
            if Employee.Get(LeaveApp."Employee No.")then if Employee."Company E-Mail" <> '' then begin
                    Clear(Recipient);
                    Recipient.Add(Employee."Company E-Mail");
                    // Same StrSubstNo pattern as Leave Reminder
                    // %1: Leave No,       %2: Employee No,   %3: Employee Name
                    // %4: Leave Type,     %5: No. of Days,   %6: Start Date
                    // %7: End Date,       %8: Return Date,   %9: Rejection Reason
                    SNotesText:=Format(SNotes);
                    SNotesText:=StrSubstNo(SNotesText, LeaveApp."No.", LeaveApp."Employee No.", LeaveApp."Employee Name", LeaveApp."Leave Type", Format(LeaveApp."No. of Days"), Format(LeaveApp."Start Date"), Format(LeaveApp."End Date"), Format(LeaveApp."Return Date"), RejectionReason); // %9 — new, not in Leave Reminder
                    Subject:=StrSubstNo(Text001, Format(NotificationType::"Leave Rejection"));
                    // Same send pattern as Leave Reminder
                    EmailMessage.Create(Recipient, Subject, SNotesText, false);
                    Email.Send(EmailMessage);
                end;
        end;
    end;
    // ---------------------------------------------------------------
    // SHARED EMAIL LOGIC — submission confirmation to the employee.
    // Same pattern as SendLeaveRejectionEmail/SendLeaveApprovalEmail; recipient
    // is the employee, sent once when the request first enters Pending Approval.
    // ---------------------------------------------------------------
    local procedure SendLeaveSubmissionEmail(DocumentNo: Code[50])var LeaveApp: Record "Leave Application";
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    Employee: Record Employee;
    Email: Codeunit Email;
    EmailMessage: Codeunit "Email Message";
    Instr: InStream;
    SNotes: BigText;
    SNotesText: Text;
    Subject: Text;
    Recipient: List of[Text];
    Text001: Label '%1';
    begin
        LeaveApp.Reset();
        LeaveApp.SetRange("No.", DocumentNo);
        if LeaveApp.FindFirst()then begin
            if not NotificationSetup.Get(NotificationType::"Leave Submission")then exit;
            if not NotificationSetup."Send Notification" then exit;
            NotificationSetup.CalcFields("Notification Notes");
            NotificationSetup."Notification Notes".CreateInStream(Instr);
            SNotes.Read(Instr);
            if Employee.Get(LeaveApp."Employee No.")then if Employee."Company E-Mail" <> '' then begin
                    Clear(Recipient);
                    Recipient.Add(Employee."Company E-Mail");
                    // %1: Leave No,       %2: Employee No,   %3: Employee Name
                    // %4: Leave Type,     %5: No. of Days,   %6: Start Date
                    // %7: End Date
                    SNotesText:=Format(SNotes);
                    SNotesText:=StrSubstNo(SNotesText, LeaveApp."No.", LeaveApp."Employee No.", LeaveApp."Employee Name", LeaveApp."Leave Type", Format(LeaveApp."No. of Days"), Format(LeaveApp."Start Date"), Format(LeaveApp."End Date"));
                    Subject:=StrSubstNo(Text001, Format(NotificationType::"Leave Submission"));
                    EmailMessage.Create(Recipient, Subject, SNotesText, false);
                    Email.Send(EmailMessage);
                end;
        end;
    end;
    // ---------------------------------------------------------------
    // SHARED EMAIL LOGIC — approval counterpart to SendLeaveRejectionEmail.
    // Same pattern; recipient is the employee, sent once the header reaches
    // Status::Approved (see PATH 2 above).
    // ---------------------------------------------------------------
    local procedure SendLeaveApprovalEmail(DocumentNo: Code[50])var LeaveApp: Record "Leave Application";
    NotificationSetup: Record "Notification Setup HR";
    NotificationType: Enum "Notification Type HR";
    Employee: Record Employee;
    Email: Codeunit Email;
    EmailMessage: Codeunit "Email Message";
    Instr: InStream;
    SNotes: BigText;
    SNotesText: Text;
    Subject: Text;
    Recipient: List of[Text];
    Text001: Label '%1';
    begin
        LeaveApp.Reset();
        LeaveApp.SetRange("No.", DocumentNo);
        if LeaveApp.FindFirst()then begin
            if not NotificationSetup.Get(NotificationType::"Leave Approval")then exit;
            if not NotificationSetup."Send Notification" then exit;
            NotificationSetup.CalcFields("Notification Notes");
            NotificationSetup."Notification Notes".CreateInStream(Instr);
            SNotes.Read(Instr);
            if Employee.Get(LeaveApp."Employee No.")then if Employee."Company E-Mail" <> '' then begin
                    Clear(Recipient);
                    Recipient.Add(Employee."Company E-Mail");
                    // %1: Leave No,       %2: Employee No,   %3: Employee Name
                    // %4: Leave Type,     %5: No. of Days,   %6: Start Date
                    // %7: End Date
                    SNotesText:=Format(SNotes);
                    SNotesText:=StrSubstNo(SNotesText, LeaveApp."No.", LeaveApp."Employee No.", LeaveApp."Employee Name", LeaveApp."Leave Type", Format(LeaveApp."No. of Days"), Format(LeaveApp."Start Date"), Format(LeaveApp."End Date"));
                    Subject:=StrSubstNo(Text001, Format(NotificationType::"Leave Approval"));
                    EmailMessage.Create(Recipient, Subject, SNotesText, false);
                    Email.Send(EmailMessage);
                end;
        end;
    end;
}
