codeunit 51107 "Approvals Timesheet Mgmt."
{
    Subtype = Normal;

    var
        NotificationSetup: Record "Notification Setup HR";
        NotificationType: Enum "Notification Type HR";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Employee: Record Employee;
        SalesSetup: Record "Sales & Receivables Setup";
        Instr: InStream;
        SNotes: BigText;
        SNotesText: Text;
        Recipient: List of [Text];
        Subject: Text;
        Text001: Label '%1';
    // === Submit ===
    /// <summary>

    /// SubmitTimesheet. 

    /// </summary>

    /// <param name="Header">VAR Record "Monthly Timesheet Header".</param>
    procedure SubmitTimesheet(var Header: Record "Monthly Timesheet Header")
    var
        SupervisorNo: Code[20];
        FinalApproverNo: Code[20];
        SupervisorEmail: Text;
    begin
        Header.Status := Header.Status::"Pending Approval";
        Header.Modify();
        // Step 1 is always the timesheet owner's own supervisor — dynamic,
        // identified by Employee No., same as leave application approval.
        SupervisorNo := GetSupervisorEmployeeNo(Header."Employee No.");
        if SupervisorNo <> '' then begin
            Header."Approver ID" := SupervisorNo;
            Header.Modify();
            CreateApprovalEntry(Header, SupervisorNo, "Timesheet Status"::Open);
            SupervisorEmail := GetSupervisorEmail(Header."Employee No.");
            if SupervisorEmail <> '' then SendApprovalEmail(Header, SupervisorEmail);
        end;
        // Also create a placeholder for step 2 (the final approver) right
        // away, in "Created" status, so the full chain is visible up front —
        // it only becomes active (Open) once the supervisor approves.
        FinalApproverNo := GetFinalApproverNo();
        if (FinalApproverNo <> '') and (FinalApproverNo <> SupervisorNo) then CreateApprovalEntry(Header, FinalApproverNo, "Timesheet Status"::Created);
    end;
    // === Approve ===
    /// <summary>

    /// ApproveTimesheet. 

    /// </summary>

    /// <param name="Header">VAR Record "Monthly Timesheet Header".</param>

    /// <param name="ApproverUser">Code[50].</param>
    procedure ApproveTimesheet(var Header: Record "Monthly Timesheet Header";
       ApproverUser: Code[50])
    var
        NextPlaceholder: Record "Timesheet Approval Entry";
        NextApproverUser: Code[50];
        NextApproverEmail: Text;
    begin
        // Guard: prevent approval if timesheet is cancelled
        if Header.Status = Header.Status::Open then Error('This timesheet has been cancelled or reopened. Approval is not allowed until it is resubmitted.');
        // Whoever is currently assigned gets to approve — covers both the
        // dynamic supervisor first step and the static ERP-configured second
        // step below.
        if Header."Approver ID" <> ApproverUser then Error('User %1 is not the current approver for this timesheet.', ApproverUser);

        // Mark the current open entry for this approver as approved
        MarkApprovalEntry(Header, ApproverUser, "Timesheet Status"::Approved);

        // Whether there's a next step is decided by whether a "Created"
        // placeholder is still waiting for this timesheet — NOT by checking
        // "was the just-approved entry's Sequence No. = 1". Sequence No. is
        // assigned by CreateApprovalEntry as (highest existing + 1) across
        // the timesheet's ENTIRE history, so it keeps climbing every time the
        // timesheet is rejected/cancelled and resubmitted (e.g. 3 and 4 on a
        // timesheet's second cycle, not 1 and 2). Keying off "= 1" only ever
        // worked on a timesheet's very first submission cycle; on any later
        // cycle the supervisor's entry lands on a higher Sequence No., the
        // check silently fails, and the code fell straight to marking the
        // whole timesheet Approved without ever activating the final
        // approver's placeholder.
        NextPlaceholder.SetRange("Timesheet No.", Header."No.");
        NextPlaceholder.SetRange(Status, NextPlaceholder.Status::Created);
        if NextPlaceholder.FindFirst() then
            NextApproverUser := NextPlaceholder."Approver ID";

        if (NextApproverUser <> '') and (NextApproverUser <> ApproverUser) then begin
            NextApproverEmail := GetApproverEmail(NextApproverUser);
            Header."Approver ID" := NextApproverUser;
            Header.Modify();
            ActivateApprovalEntry(Header, NextApproverUser);
            if NextApproverEmail <> '' then SendApprovalEmail(Header, NextApproverEmail);
        end
        else begin
            // Final approver — mark header approved, no extra email
            Header.Status := Header.Status::Approved;
            Header.Modify();
        end;
    end;
    // === Reject ===
    /// <summary>

    /// RejectTimesheet. 

    /// </summary>

    /// <param name="Header">VAR Record "Monthly Timesheet Header".</param>

    /// <param name="ApproverUser">Code[50].</param>

    /// <param name="Reason">Text[250].</param>
    procedure RejectTimesheet(var Header: Record "Monthly Timesheet Header";
       ApproverUser: Code[50];
       Reason: Text[250])
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        // Guard: prevent rejection if timesheet is already cancelled or approved
        if Header.Status = Header.Status::Open then Error('This timesheet has been cancelled or reopened. Rejection is not allowed.');
        // Mark the latest open entry for this approver as Rejected
        TsApproval.SetRange("Timesheet No.", Header."No.");
        TsApproval.SetRange("Approver ID", ApproverUser);
        TsApproval.SetRange(Status, TsApproval.Status::Open);
        if TsApproval.FindLast() then begin
            TsApproval.Status := TsApproval.Status::Rejected;
            TsApproval."Last Modified" := CurrentDateTime;
            TsApproval."Rejected By" := ApproverUser;
            TsApproval.Modify();
        end
        else
            Error('No open approval entry found for this approver.');
        // Close out the step-2 placeholder too, if it exists and hasn't
        // activated yet — the chain is aborted, so it shouldn't keep
        // showing up as pending.
        ClosePendingPlaceholders(Header."No.", TsApproval.Status::Rejected);
        // Update header back to Open (so employee can fix and resubmit)
        Header.Status := Header.Status::Open;
        Header.Modify();
        // Notify employee
        if Employee.Get(Header."Employee No.") then if Employee."Company E-Mail" <> '' then SendRejectionEmail(Header, Employee."Company E-Mail", Reason);
    end;
    // === Cancel ===
    /// <summary>

    /// CancelTimesheet.

    /// </summary>

    /// <param name="Header">VAR Record "Monthly Timesheet Header".</param>
    procedure CancelTimesheet(var Header: Record "Monthly Timesheet Header")
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        // Mark the latest open entry as cancelled
        TsApproval.SetRange("Timesheet No.", Header."No.");
        TsApproval.SetRange(Status, TsApproval.Status::Open);
        if TsApproval.FindLast() then begin
            TsApproval.Status := TsApproval.Status::Cancelled;
            TsApproval."Last Modified" := CurrentDateTime;
            TsApproval.Modify();
        end;
        // Close out the step-2 placeholder too, if it exists and hasn't
        // activated yet.
        ClosePendingPlaceholders(Header."No.", TsApproval.Status::Cancelled);
        Header.Status := Header.Status::Open;
        Header.Modify();
        if Employee.Get(Header."Employee No.") then if Employee."Company E-Mail" <> '' then SendCancellationEmail(Header, Employee."Company E-Mail");
    end;
    // === One-time repair ===
    /// <summary>

    /// One-time repair for the Sequence-No.-based bug in ApproveTimesheet
    /// (fixed above): on a timesheet's later approval cycles, that bug could
    /// mark the header Approved while the final approver's "Created"
    /// placeholder was left behind, never activated — so that approver never
    /// actually saw or approved it. Finds every timesheet in that exact
    /// broken shape (Status = Approved, but a "Created" entry still exists
    /// for it) and puts it back into the state it should have reached:
    /// header back to Pending Approval, that approver's entry activated to
    /// Open, Header."Approver ID" pointed at them, and their approval e-mail
    /// (re)sent. Returns how many timesheets it fixed.

    /// </summary>
    procedure FixOrphanedApprovals(): Integer
    var
        Header: Record "Monthly Timesheet Header";
        OrphanedEntry: Record "Timesheet Approval Entry";
        ApproverEmail: Text;
        FixedCount: Integer;
    begin
        Header.SetRange(Status, Header.Status::Approved);
        if Header.FindSet(true) then
            repeat
                OrphanedEntry.SetRange("Timesheet No.", Header."No.");
                OrphanedEntry.SetRange(Status, OrphanedEntry.Status::Created);
                if OrphanedEntry.FindFirst() then begin
                    OrphanedEntry.Status := OrphanedEntry.Status::Open;
                    OrphanedEntry."Date-Time Sent" := CurrentDateTime;
                    OrphanedEntry.Modify();

                    Header."Approver ID" := OrphanedEntry."Approver ID";
                    Header.Status := Header.Status::"Pending Approval";
                    Header.Modify();

                    ApproverEmail := GetApproverEmail(OrphanedEntry."Approver ID");
                    if ApproverEmail <> '' then SendApprovalEmail(Header, ApproverEmail);

                    FixedCount += 1;
                end;
            until Header.Next() = 0;
        exit(FixedCount);
    end;
    // === Approval Entry Helpers ===
    /// <summary>

    /// CreateApprovalEntry. 

    /// </summary>

    /// <param name="Header">Record "Monthly Timesheet Header".</param>

    /// <param name="ApproverUser">Code[50].</param>
    procedure CreateApprovalEntry(Header: Record "Monthly Timesheet Header";
       ApproverUser: Code[50];
       EntryStatus: Enum "Timesheet Status")
    var
        Emp: Record Employee;
        TsApproval: Record "Timesheet Approval Entry";
        NextSeq: Integer;
    begin
        // Only skip if an entry for this approver is still active (Open or a
        // Created placeholder) — on resubmission after a reject/cancel, prior
        // entries are already in a terminal status (Rejected/Cancelled), so a
        // fresh entry for the new cycle should still be created.
        if ActiveApprovalEntryExists(Header."No.", ApproverUser) then exit;
        TsApproval.SetRange("Timesheet No.", Header."No.");
        // Find the highest sequence number for this timesheet
        if TsApproval.FindLast() then
            NextSeq := TsApproval."Sequence No." + 1
        else
            NextSeq := 1;
        TsApproval.Init();
        TsApproval."Timesheet No." := Header."No.";
        TsApproval."Sequence No." := NextSeq;
        TsApproval."Approver ID" := ApproverUser;
        TsApproval.Status := EntryStatus;
        TsApproval."Date-Time Sent" := CurrentDateTime;
        TsApproval.Description := 'Timesheet Header: ' + Header."No.";
        if Emp.Get(Header."Employee No.") then begin
            TsApproval."Employee No." := Emp."No.";
            TsApproval."Employee Name" := Emp."First Name" + ' ' + Emp."Middle Name" + ' ' + Emp."Last Name";
        end;
        TsApproval.Insert();
    end;
    // Flips a step-2 "Created" placeholder entry to Open once the
    // supervisor has approved — reuses the same row instead of inserting
    // a new one, so the placeholder created at submission time is what
    // actually goes live.
    local procedure ActivateApprovalEntry(Header: Record "Monthly Timesheet Header";
       ApproverUser: Code[50])
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        TsApproval.SetRange("Timesheet No.", Header."No.");
        TsApproval.SetRange("Approver ID", ApproverUser);
        TsApproval.SetRange(Status, TsApproval.Status::Created);
        if TsApproval.FindFirst() then begin
            TsApproval.Status := TsApproval.Status::Open;
            TsApproval."Date-Time Sent" := CurrentDateTime;
            TsApproval.Modify();
        end else
            CreateApprovalEntry(Header, ApproverUser, "Timesheet Status"::Open);
    end;

    /// <summary>

    /// MarkApprovalEntry. 

    /// </summary>

    /// <param name="Header">Record "Monthly Timesheet Header".</param>

    /// <param name="ApproverUser">Code[50].</param>

    /// <param name="NewStatus">Enum "Approval Status".</param>
    procedure MarkApprovalEntry(Header: Record "Monthly Timesheet Header";
       ApproverUser: Code[50];
       NewStatus: Enum "Timesheet Status")
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        TsApproval.SetRange("Timesheet No.", Header."No.");
        TsApproval.SetRange("Approver ID", ApproverUser);
        TsApproval.SetRange(Status, TsApproval.Status::Open);
        if TsApproval.FindSet() then
            repeat
                TsApproval.Status := NewStatus;
                TsApproval."Last Modified" := CurrentDateTime;
                case NewStatus of
                    TsApproval.Status::Approved:
                        TsApproval."Approved By" := ApproverUser;
                    TsApproval.Status::Rejected:
                        TsApproval."Rejected By" := ApproverUser;
                end;
                TsApproval.Modify();
            until TsApproval.Next() = 0;
    end;

    /// <summary>

    /// The final sign-off approver, after the dynamic supervisor step. Almost
    /// nobody in this org has a BC login/"User Setup" row — they only ever act
    /// through the third-party portal — so, exactly like the supervisor step,
    /// this is a plain Employee No. set directly on Sales & Receivables Setup
    /// ("Timesheet Final Approver No."), no BC user account required at all.

    /// </summary>
    procedure GetFinalApproverNo(): Code[20]
    begin
        if not SalesSetup.Get() then exit('');
        if not Employee.Get(SalesSetup."Timesheet Final Approver No.") then exit('');
        exit(Employee."No.");
    end;

    /// <summary>

    /// E-mail for the final approver, resolved straight off their Employee
    /// record — same pattern as the supervisor's e-mail.

    /// </summary>
    procedure GetFinalApproverEmail(): Text
    begin
        if not SalesSetup.Get() then exit('');
        if not Employee.Get(SalesSetup."Timesheet Final Approver No.") then exit('');
        exit(Employee."Company E-Mail");
    end;

    /// <summary>

    /// E-mail for whichever Employee No. is being activated as the next
    /// approver — looked up generically off the Employee table rather than
    /// assuming the next step is always the final approver, so this stays
    /// correct if the chain is ever extended beyond two steps.

    /// </summary>
    local procedure GetApproverEmail(ApproverEmployeeNo: Code[20]): Text
    var
        Emp: Record Employee;
    begin
        if not Emp.Get(ApproverEmployeeNo) then exit('');
        exit(Emp."Company E-Mail");
    end;

    /// <summary>

    /// The timesheet owner's own supervisor — the dynamic second approval step.
    /// Identified the same way the rest of the HR module identifies a
    /// supervisor: by Employee No. (Employee."Supervisor No."), not a BC login.
    /// Blank if the employee has no supervisor set, or the supervisor No.
    /// doesn't resolve to an Employee record.

    /// </summary>
    procedure GetSupervisorEmployeeNo(EmployeeNo: Code[20]): Code[20]
    var
        Emp: Record Employee;
        Supervisor: Record Employee;
    begin
        if not Emp.Get(EmployeeNo) then exit('');
        if Emp."Supervisor No." = '' then exit('');
        if not Supervisor.Get(Emp."Supervisor No.") then exit('');
        exit(Supervisor."No.");
    end;

    /// <summary>

    /// The timesheet owner's supervisor's e-mail, resolved straight off the
    /// Employee table so the dynamic approval step doesn't depend on the
    /// supervisor having a "User Setup" row.

    /// </summary>
    procedure GetSupervisorEmail(EmployeeNo: Code[20]): Text
    var
        Emp: Record Employee;
        Supervisor: Record Employee;
    begin
        if not Emp.Get(EmployeeNo) then exit('');
        if Emp."Supervisor No." = '' then exit('');
        if not Supervisor.Get(Emp."Supervisor No.") then exit('');
        exit(Supervisor."Company E-Mail");
    end;

    /// <summary>

    /// GetCurrentSequence — sequence on the open approval entry for this approver (legacy). 

    /// </summary>
    procedure GetCurrentSequence(TimesheetNo: Code[20];
       ApproverUser: Code[50]): Integer
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        TsApproval.SetRange("Timesheet No.", TimesheetNo);
        TsApproval.SetRange("Approver ID", ApproverUser);
        TsApproval.SetRange(Status, TsApproval.Status::Open);
        if TsApproval.FindLast() then exit(TsApproval."Sequence No.");
        TsApproval.SetRange(Status);
        if TsApproval.FindLast() then exit(TsApproval."Sequence No.");
        exit(0);
    end;

    local procedure ClosePendingPlaceholders(TimesheetNo: Code[20];
       NewStatus: Enum "Timesheet Status")
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        TsApproval.SetRange("Timesheet No.", TimesheetNo);
        TsApproval.SetRange(Status, TsApproval.Status::Created);
        if TsApproval.FindSet() then
            repeat
                TsApproval.Status := NewStatus;
                TsApproval."Last Modified" := CurrentDateTime;
                TsApproval.Modify();
            until TsApproval.Next() = 0;
    end;

    local procedure ActiveApprovalEntryExists(TimesheetNo: Code[20];
       ApproverUser: Code[50]): Boolean
    var
        TsApproval: Record "Timesheet Approval Entry";
    begin
        TsApproval.SetRange("Timesheet No.", TimesheetNo);
        TsApproval.SetRange("Approver ID", ApproverUser);
        TsApproval.SetFilter(Status, '%1|%2', TsApproval.Status::Open, TsApproval.Status::Created);
        exit(not TsApproval.IsEmpty());
    end;
    // === Email Helpers (ERP-managed pattern) ===
    local procedure SendApprovalEmail(Header: Record "Monthly Timesheet Header";
    RecipientEmail: Text)
    var
        EmployeeName: Text;
    begin
        if not NotificationSetup.Get(NotificationType::"Timesheet Approval") then exit;
        if not NotificationSetup."Send Notification" then exit;
        NotificationSetup.CalcFields("Notification Notes");
        NotificationSetup."Notification Notes".CreateInStream(Instr);
        SNotes.Read(Instr);
        Clear(Recipient);
        Recipient.Add(RecipientEmail);
        if Employee.Get(Header."Employee No.") then EmployeeName := Employee."First Name" + ' ' + Employee."Last Name";
        SNotesText := Format(SNotes);
        SNotesText := StrSubstNo(SNotesText, Header."No.", Header."Employee No.", EmployeeName);
        Subject := StrSubstNo(Text001, Format(NotificationType::"Timesheet Approval"));
        EmailMessage.Create(Recipient, Subject, SNotesText, false);
        Email.Send(EmailMessage);
    end;

    local procedure SendRejectionEmail(Header: Record "Monthly Timesheet Header";
    RecipientEmail: Text;
    Reason: Text[250])
    begin
        if not NotificationSetup.Get(NotificationType::"Timesheet Rejection") then exit;
        if not NotificationSetup."Send Notification" then exit;
        NotificationSetup.CalcFields("Notification Notes");
        NotificationSetup."Notification Notes".CreateInStream(Instr);
        SNotes.Read(Instr);
        Clear(Recipient);
        Recipient.Add(RecipientEmail);
        SNotesText := Format(SNotes);
        SNotesText := StrSubstNo(SNotesText, Header."No.", Header."Employee No.", Reason);
        Subject := StrSubstNo(Text001, Format(NotificationType::"Timesheet Rejection"));
        EmailMessage.Create(Recipient, Subject, SNotesText, false);
        Email.Send(EmailMessage);
    end;

    local procedure SendCancellationEmail(Header: Record "Monthly Timesheet Header";
    RecipientEmail: Text)
    begin
        if not NotificationSetup.Get(NotificationType::"Timesheet Cancelled") then exit;
        if not NotificationSetup."Send Notification" then exit;
        NotificationSetup.CalcFields("Notification Notes");
        NotificationSetup."Notification Notes".CreateInStream(Instr);
        SNotes.Read(Instr);
        Clear(Recipient);
        Recipient.Add(RecipientEmail);
        SNotesText := Format(SNotes);
        SNotesText := StrSubstNo(SNotesText, Header."No.", Header."Employee No.");
        Subject := StrSubstNo(Text001, Format(NotificationType::"Timesheet Cancelled"));
        EmailMessage.Create(Recipient, Subject, SNotesText, false);
        Email.Send(EmailMessage);
    end;
}
