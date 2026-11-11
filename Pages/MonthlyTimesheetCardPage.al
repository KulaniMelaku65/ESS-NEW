page 51100 "Monthly Timesheet Card"
{
    PageType = Document;
    SourceTable = "Monthly Timesheet Header";
    Caption = 'Monthly Timesheet';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = PageEditable;

                field("No.";Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = All;
                }
                field(Month;Rec.Month)
                {
                    ApplicationArea = All;
                }
                field(Year;Rec.Year)
                {
                    ApplicationArea = All;
                }
                field(Status;Rec.Status)
                {
                    ApplicationArea = All;
                    // Status is always read-only — driven by the workflow.
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field("Total Hours";Rec."Total Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total hours recorded for this month.';
                    Style = Strong;
                }
                field("Reason for Rejection";Rec."Reason for Rejection")
                {
                    ApplicationArea = All;
                    ToolTip = 'If this timesheet was rejected, the reason will be shown here.';
                }
            }
            part(Lines;"Monthly Timesheet Subform")
            {
                Editable = PageEditable or LinesCorrectionMode;
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No."=field("No.");
                Enabled = PageEditable or LinesCorrectionMode;
                UpdatePropagation = Both;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            // ── Submit for Approval ───────────────────────────────
            action(Submit)
            {
                Caption = 'Submit for Approval';
                Image = SendApprovalRequest;
                ApplicationArea = All;
                Enabled = CanSubmit; // Only active when Status = Open
                ToolTip = 'Send this timesheet for approval. The status will change to Pending Approval and the timesheet will become read-only.';

                trigger OnAction()var TSMgt: Codeunit "Timesheet Mgt.";
                begin
                    TSMgt.SubmitTimesheet(Rec);
                    CurrPage.Update(false); // Refresh status display
                end;
            }
            // ── Cancel Approval Request ───────────────────────────
            action(CancelApproval)
            {
                Caption = 'Cancel Approval Request';
                Image = CancelApprovalRequest;
                ApplicationArea = All;
                Enabled = CanCancel; // Only active when Status = Pending Approval
                ToolTip = 'Cancel the pending approval request. This is only possible before the first approver has acted. The timesheet will return to Open status.';

                trigger OnAction()var TSMgt: Codeunit "Timesheet Mgt.";
                begin
                    TSMgt.CancelTimesheet(Rec);
                    CurrPage.Update(false); // Refresh status display
                end;
            }
            // ── Manual correction for a locked timesheet whose Lines
            // ended up empty (data gap, not a workflow state) — unlocks
            // ONLY the Lines subform for this one document, this one
            // session; header fields (Employee No./Month/Year/Status)
            // stay locked, and nothing here is persisted, so it can't be
            // left accidentally unlocked. Special-case repair tool, not a
            // replacement for the normal Open -> Submit -> Approve flow.
            action(UnlockLinesForCorrection)
            {
                Caption = 'Unlock Lines for Correction (Admin)';
                Image = Edit;
                ApplicationArea = All;
                Enabled = not PageEditable;
                ToolTip = 'For a timesheet that is Pending Approval, Approved, or Rejected but whose Lines are missing/incomplete (a data gap) — temporarily unlocks just the Lines below so you can enter them manually. Does not change Status or reopen the workflow, and only applies to this document for this session.';

                trigger OnAction()
                begin
                    if not Confirm('This timesheet''s Status is %1, so it is normally locked. Temporarily unlock the Lines below to manually enter missing entries? This does not change Status or reopen approval — use it only to correct a data gap, not to alter an already-decided timesheet.', false, Rec.Status) then
                        exit;
                    LinesCorrectionMode := true;
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            // ── View Approval Entries ─────────────────────────────
            action(Approvals)
            {
                Caption = 'Approvals';
                Image = Approvals;
                ApplicationArea = All;
                ToolTip = 'View the approval entries for this timesheet, including who has approved or rejected it.';

                trigger OnAction()var TsApproval: Record "Timesheet Approval Entry";
                begin
                    TsApproval.SetRange("Timesheet No.", Rec."No.");
                    PAGE.RunModal(PAGE::"Timesheet Approval Entries", TsApproval);
                end;
            }
        }
    }
    var PageEditable: Boolean;
    CanSubmit: Boolean;
    CanCancel: Boolean;
    StatusStyle: Text;
    LinesCorrectionMode: Boolean;
    LinesCorrectionModeForNo: Code[20];
    trigger OnAfterGetRecord()begin
        // OnAfterGetRecord also fires from CurrPage.Update() on the SAME
        // record (e.g. right after the unlock action below sets
        // LinesCorrectionMode), not just from moving to a different one —
        // so resetting it unconditionally here was wiping out the unlock
        // the instant it was granted. Only reset when the record actually
        // changed (Next/Previous navigation, or opening a different
        // document), tracked via LinesCorrectionModeForNo.
        if LinesCorrectionModeForNo <> Rec."No." then begin
            LinesCorrectionMode:=false;
            LinesCorrectionModeForNo:=Rec."No.";
        end;
        // Edit lock: header and lines are only editable when Open.
        PageEditable:=Rec.Status = Rec.Status::Open;
        // Action visibility guards.
        CanSubmit:=Rec.Status = Rec.Status::Open;
        CanCancel:=Rec.Status = Rec.Status::"Pending Approval";
        // Status badge colour for visual feedback.
        case Rec.Status of Rec.Status::Open: StatusStyle:='Favorable';
        Rec.Status::"Pending Approval": StatusStyle:='Ambiguous';
        Rec.Status::Approved: StatusStyle:='Strong';
        else
            StatusStyle:='Standard';
        end;
    end;
}
