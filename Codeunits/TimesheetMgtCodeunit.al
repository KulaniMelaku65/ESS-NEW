codeunit 51100 "Timesheet Mgt."
{
    // =========================================================
    //  INTEGRATION EVENTS
    //  Published here; subscribed to in "Timesheet Workflow Code"
    //  (51101) which hands them to the workflow engine.
    //  Keeping them here means the page never needs to reference
    //  the workflow codeunit directly.
    // =========================================================
    /// <summary>
 
///  Raised when the employee submits the timesheet. 
 
/// </summary>
[IntegrationEvent(false, false)]
    procedure OnSendTimesheetForApproval(var MonthlyTimesheetHeader: Record "Monthly Timesheet Header")begin
    end;
    /// <summary>
 
///  Raised when the employee cancels the pending approval 
 
///  request before any approver has acted. 
 
/// </summary>
[IntegrationEvent(false, false)]
    procedure OnCancelTimesheetApprovalRequest(var MonthlyTimesheetHeader: Record "Monthly Timesheet Header")begin
    end;
    // =========================================================
    //  PUBLIC PROCEDURES  (called from page 51100)
    // =========================================================
    /// <summary>
 
///  Called by the "Submit for Approval" action on the page. 
 
///  Validates the document, then raises the integration event. 
 
///  The workflow engine subscriber in Timesheet Workflow Code 
 
///  picks it up and starts the approval chain. 
 
/// </summary>
 procedure SubmitTimesheet(var Header: Record "Monthly Timesheet Header")var WorkflowMgt: Codeunit "Workflow Management";
    begin
        // Must be Open to submit.
        if Header.Status <> Header.Status::Open then Error('Only Open timesheets can be submitted for approval. Current status: %1.', Header.Status);
        // Employee No. is mandatory.
        Header.TestField("Employee No.");
        // At least one line must exist.
        if not LinesExist(Header."No.")then Error('Cannot submit an empty timesheet. Please add at least one line.');
        // A workflow must be configured and active for this document.
        // This catches the case where the admin forgot to enable the workflow.
        // if not WorkflowMgt.CanExecuteWorkflow(Database::"Monthly Timesheet Header")
        //.CanHandleRequest(Header)
        //  then
        //Error('No active workflow is set up for Monthly Timesheet approval. Please contact your system administrator.');
        // All checks passed — raise event for the workflow engine.
        OnSendTimesheetForApproval(Header);
    end;
    /// <summary>
 
///  Called by the "Cancel Approval Request" action on the page. 
 
///  Only allowed while status is Pending Approval AND before 
 
///  the first approver has acted (open approval entries exist). 
 
///  Removes all pending approval entries, then raises the 
 
///  cancel event so the workflow engine resets status to Open. 
 
/// </summary>
 procedure CancelTimesheet(var Header: Record "Monthly Timesheet Header")var ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    ApprovalEntry: Record "Approval Entry";
    begin
        // Must be in Pending Approval to cancel.
        if Header.Status <> Header.Status::"Pending Approval" then Error('The approval request can only be cancelled while the status is Pending Approval.');
        // If no Open approval entries remain, at least one approver
        // has already acted — block the cancel.
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Table ID", Database::"Monthly Timesheet Header");
        ApprovalEntry.SetRange("Record ID to Approve", Header.RecordId());
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if ApprovalEntry.IsEmpty()then Error('This approval request cannot be cancelled because it has already been reviewed by an approver.');
        // Remove all pending approval entries for this record.
        //  ApprovalsMgmt.CancelApprovalRequestsForRecord(Header.RecordId());
        //ApprovalsMgmt.CancelApprovalRequestsForRecord(Header.RecordId());
        // Raise event — workflow engine subscriber resets status to Open.
        OnCancelTimesheetApprovalRequest(Header);
    end;
    // =========================================================
    //  PRIVATE HELPERS
    // =========================================================
    local procedure LinesExist(DocNo: Code[20]): Boolean var Lines: Record "Monthly Timesheet Line";
    begin
        Lines.SetRange("Document No.", DocNo);
        exit(not Lines.IsEmpty());
    end;
}
