codeunit 51104 "TS Workflow Event Handling"
{
    // =========================================================
    //  1. Table relation library registration
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddMonthlyTimesheetTableRelations()var ApprovalEntry: Record "Approval Entry";
    WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // Allows the workflow engine to navigate between
        // "Monthly Timesheet Header" and "Approval Entry" when
        // evaluating conditions and running responses.
        WorkflowSetup.InsertTableRelation(Database::"Monthly Timesheet Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
    end;
    // =========================================================
    //  2. Predecessor wiring
    //  Tells the designer which responses are valid after which
    //  events, keeping the drop-down lists clean.
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkFlowResponsePredecessorsToLibrary', '', true, true)]
    local procedure OnAddWorkFlowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])var WorkFlowResponse: Codeunit "Workflow Response Handling";
    TimesheetWFCode: Codeunit "Timesheet Workflow Code";
    begin
        case ResponseFunctionName of // After "Send for Approval": allow the three standard
        // approval setup responses and our custom Pending status.
        WorkFlowResponse.SetStatusToPendingApprovalCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.SetStatusToPendingApprovalCode(), //TimesheetWFCode.RunWorkflowOnSendMonthlyTimesheetApprovalCode()
            TimesheetWFCode.RunWorkflowOnSendTimesheetForApprovalCode());
        WorkFlowResponse.CreateApprovalRequestsCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.CreateApprovalRequestsCode(), TimesheetWFCode.RunWorkflowOnSendTimesheetForApprovalCode());
        WorkFlowResponse.SendApprovalRequestForApprovalCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.SendApprovalRequestForApprovalCode(), TimesheetWFCode.RunWorkflowOnSendTimesheetForApprovalCode());
        // After "User cancels": allow Open Document (unlocks editing).
        WorkFlowResponse.OpenDocumentCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.OpenDocumentCode(), //TimesheetWFCode.RunWorkflowOnCancelMonthlyTimesheetApprovalCode()
            TimesheetWFCode.RunWorkflowOnCancelTimesheetApprovalCode());
        // Our custom response predecessors are registered by
        // OnExecuteWorkflowResponse in Timesheet Workflow Code,
        // so nothing extra is needed here for those.
        end;
    end;
    // =========================================================
    //  3. OnOpenDocument hook
    //  Called by the standard workflow "Open Document" response.
    //  Resets status to Open so the employee can edit again.
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef;
    var Handled: Boolean)var MonthlyTimesheetHeader: Record "Monthly Timesheet Header";
    begin
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        Handled:=true;
        RecRef.SetTable(MonthlyTimesheetHeader);
        MonthlyTimesheetHeader.Validate(Status, MonthlyTimesheetHeader.Status::Open);
        MonthlyTimesheetHeader.Modify();
    end;
    // =========================================================
    //  4. OnReleaseDocument hook
    //  Called by the standard workflow "Release Document" response
    //  when the last approver in the chain approves.
    //  Sets status to Approved.
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure OnReleaseDocument(RecRef: RecordRef;
    var Handled: Boolean)var TimesheetWFCode: Codeunit "Timesheet Workflow Code";
    VarVariant: Variant;
    begin
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        Handled:=true;
        VarVariant:=RecRef;
        TimesheetWFCode.ReleaseMonthlyTimesheet(VarVariant);
    end;
}
