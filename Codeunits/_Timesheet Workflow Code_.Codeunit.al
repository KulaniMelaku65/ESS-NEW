codeunit 51101 "Timesheet Workflow Code"
{
    // =========================================================
    //  WHAT WAS WRONG — CODE KEY STRINGS DID NOT MATCH XML
    // =========================================================
    //  The workflow XML (FunctionName attributes) is the source
    //  of truth. Every Code key function must return exactly the
    //  same uppercase string that is stored in the database.
    //
    //  BEFORE (wrong)                          XML HAS
    //  ─────────────────────────────────────   ────────────────────────────────────
    //  RunWorkflowOnSendMonthlyTimesheet...  ≠ RUNWORKFLOWONSENDTIMESHEETFORAPPROVAL
    //  RunWorkflowOnApproveMonthlyTimesheet≠ RUNWORKFLOWONAPPROVEAPPROVALREQUEST
    //  RunWorkflowOnRejectMonthlyTimesheet ≠ RUNWORKFLOWONREJECTAPPROVALREQUEST
    //  RunWorkflowOnDelegateMonthlytimesheet≠ RUNWORKFLOWONDELEGATEAPPROVALREQUEST
    //
    //  AFTER (fixed — matches XML exactly)
    //  ────────────────────────────────────────────────────────
    //  Send     → RUNWORKFLOWONSENDTIMESHEETFORAPPROVAL
    //  Approve  → RUNWORKFLOWONAPPROVEAPPROVALREQUEST   (standard BC code)
    //  Reject   → RUNWORKFLOWONREJECTAPPROVALREQUEST    (standard BC code)
    //  Delegate → RUNWORKFLOWONDELEGATEAPPROVALREQUEST  (standard BC code)
    //  Cancel   → RUNWORKFLOWONCANCELMONTHLYTIMESHEETAPPROVAL (custom, already matched)
    //
    //  NOTE: Approve/Reject/Delegate reuse the STANDARD BC approval
    //  event codes — exactly as the travel advance workflow does.
    //  This is correct. Those events are fired by Approvals Mgmt.
    //  using those fixed codes regardless of which document type
    //  triggered them. Your custom code only needs to handle
    //  the Send and Cancel events, which are document-specific.
    // =========================================================
    var WFMngt: Codeunit "Workflow Management";
    WorkflowEventHandling: Codeunit "Workflow Event Handling";
    WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    SendTimesheetReq: TextConst ENU='An approval of a monthly timesheet is requested', ENG='An approval of a monthly timesheet is requested';
    AppReqTimesheet: TextConst ENU='Approval Request for Monthly Timesheet is approved', ENG='Approval Request for Monthly Timesheet is approved';
    RejReqTimesheet: TextConst ENU='Approval Request for Monthly Timesheet is rejected', ENG='Approval Request for Monthly Timesheet is rejected';
    CanReqTimesheet: TextConst ENU='Approval Request for Monthly Timesheet is cancelled', ENG='Approval Request for Monthly Timesheet is cancelled';
    UserCanReqTimesheet: TextConst ENU='Approval Request for Monthly Timesheet is cancelled by User', ENG='Approval Request for Monthly Timesheet is cancelled by User';
    DelReqTimesheet: TextConst ENU='Approval Request for Monthly Timesheet is delegated', ENG='Approval Request for Monthly Timesheet is delegated';
    TimesheetPendAppTxt: TextConst ENU='Status of Monthly Timesheet changed to Pending Approval', ENG='Status of Monthly Timesheet changed to Pending Approval';
    ReleaseTimesheetTxt: TextConst ENU='Release Monthly Timesheet', ENG='Release Monthly Timesheet';
    ReOpenTimesheetTxt: TextConst ENU='ReOpen Monthly Timesheet', ENG='ReOpen Monthly Timesheet';
    // =========================================================
    //  SECTION 1 — EVENT CODE KEY FUNCTIONS
    //  Each string matches the FunctionName in the workflow XML.
    // =========================================================
    // Matches XML: FunctionName="RUNWORKFLOWONSENDTIMESHEETFORAPPROVAL"
    procedure RunWorkflowOnSendTimesheetForApprovalCode(): Code[128]begin
        exit(UpperCase('RunWorkflowOnSendTimesheetForApproval'));
    end;
    // Matches XML: FunctionName="RUNWORKFLOWONAPPROVEAPPROVALREQUEST"
    // (standard BC code — same as travel advance, purchase orders, etc.)
    procedure RunWorkflowOnApproveTimesheetApprovalCode(): Code[128]begin
        exit(UpperCase('RunWorkflowOnApproveApprovalRequest'));
    end;
    // Matches XML: FunctionName="RUNWORKFLOWONREJECTAPPROVALREQUEST"
    procedure RunWorkflowOnRejectTimesheetApprovalCode(): Code[128]begin
        exit(UpperCase('RunWorkflowOnRejectApprovalRequest'));
    end;
    // Matches XML: FunctionName="RUNWORKFLOWONDELEGATEAPPROVALREQUEST"
    procedure RunWorkflowOnDelegateTimesheetApprovalCode(): Code[128]begin
        exit(UpperCase('RunWorkflowOnDelegateApprovalRequest'));
    end;
    // Matches XML: FunctionName="RUNWORKFLOWONCANCELMONTHLYTIMESHEETAPPROVAL"
    procedure RunWorkflowOnCancelTimesheetApprovalCode(): Code[128]begin
        exit(UpperCase('RunWorkflowOnCancelMonthlyTimesheetApproval'));
    end;
    // =========================================================
    //  SECTION 2 — RESPONSE CODE KEY FUNCTIONS
    //  Match the FunctionName / ResponseFunctionName in the XML.
    // =========================================================
    // Matches XML: FunctionName="SETSTATUSTOPENDINGAPPROVALMONTHLYTIMESHEET"
    procedure SetStatusToPendingApprovalCodeTimesheet(): Code[128]begin
        exit(UpperCase('SetStatusToPendingApprovalMonthlyTimesheet'));
    end;
    // Matches XML: FunctionName="RELEASEMONTHLYTIMESHEET"
    procedure ReleaseMonthlyTimesheetCode(): Code[128]begin
        exit(UpperCase('ReleaseMonthlyTimesheet'));
    end;
    // Matches XML: FunctionName="REOPENMONTHLYTIMESHEET"
    procedure ReOpenMonthlyTimesheetCode(): Code[128]begin
        exit(UpperCase('ReOpenMonthlyTimesheet'));
    end;
    // =========================================================
    //  SECTION 3 — EVENT SUBSCRIBERS
    // =========================================================
    // Employee submits — fired by Timesheet Mgt.OnSendTimesheetForApproval
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Timesheet Mgt.", 'OnSendTimesheetForApproval', '', false, false)]
    local procedure RunWorkflowOnSendTimesheetForApproval(var MonthlyTimesheetHeader: Record "Monthly Timesheet Header")begin
        WFMngt.HandleEvent(RunWorkflowOnSendTimesheetForApprovalCode(), MonthlyTimesheetHeader);
    end;
    // Approver approves — fired by standard Approvals Mgmt.
    // Must use HandleEventOnKnownWorkflowInstance so the engine
    // advances the EXISTING instance, not starts a new one.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnApproveTimesheetApproval(var ApprovalEntry: Record "Approval Entry")begin
        if ApprovalEntry."Table ID" <> Database::"Monthly Timesheet Header" then exit;
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnApproveTimesheetApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;
    // Approver rejects
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnRejectTimesheetApproval(var ApprovalEntry: Record "Approval Entry")begin
        if ApprovalEntry."Table ID" <> Database::"Monthly Timesheet Header" then exit;
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnRejectTimesheetApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;
    // Approver delegates
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDelegateApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnDelegateTimesheetApproval(var ApprovalEntry: Record "Approval Entry")begin
        if ApprovalEntry."Table ID" <> Database::"Monthly Timesheet Header" then exit;
        WFMngt.HandleEventOnKnownWorkflowInstance(RunWorkflowOnDelegateTimesheetApprovalCode(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;
    // Employee cancels — fired by Timesheet Mgt.OnCancelTimesheetApprovalRequest
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Timesheet Mgt.", 'OnCancelTimesheetApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnCancelTimesheetApproval(var MonthlyTimesheetHeader: Record "Monthly Timesheet Header")begin
        WFMngt.HandleEvent(RunWorkflowOnCancelTimesheetApprovalCode(), MonthlyTimesheetHeader);
    end;
    // =========================================================
    //  SECTION 4 — RESPONSE IMPLEMENTATIONS
    // =========================================================
    procedure SetStatusToPendingApprovalTimesheet(var Variant: Variant)var RecRef: RecordRef;
    TSHeader: Record "Monthly Timesheet Header";
    begin
        RecRef.GetTable(Variant);
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        RecRef.SetTable(TSHeader);
        TSHeader.Validate(Status, TSHeader.Status::"Pending Approval");
        TSHeader.Modify();
        Variant:=TSHeader;
    end;
    procedure ReleaseMonthlyTimesheet(var Variant: Variant)var RecRef: RecordRef;
    TargetRecRef: RecordRef;
    ApprovalEntry: Record "Approval Entry";
    TSHeader: Record "Monthly Timesheet Header";
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number()of DATABASE::"Approval Entry": begin
            ApprovalEntry:=Variant;
            TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
            Variant:=TargetRecRef;
            ReleaseMonthlyTimesheet(Variant);
        end;
        DATABASE::"Monthly Timesheet Header": begin
            RecRef.SetTable(TSHeader);
            TSHeader.Validate(Status, TSHeader.Status::Approved);
            TSHeader.Modify();
            Variant:=TSHeader;
        end;
        end;
    end;
    procedure ReOpenMonthlyTimesheet(var Variant: Variant)var RecRef: RecordRef;
    TargetRecRef: RecordRef;
    ApprovalEntry: Record "Approval Entry";
    TSHeader: Record "Monthly Timesheet Header";
    TimesheetNotify: Codeunit "Timesheet Workflow Notify";
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number()of DATABASE::"Approval Entry": begin
            TimesheetNotify.SendRejectionEmail(ApprovalEntry);
            ApprovalEntry:=Variant;
            TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
            Variant:=TargetRecRef;
            ReOpenMonthlyTimesheet(Variant);
        end;
        DATABASE::"Monthly Timesheet Header": begin
            RecRef.SetTable(TSHeader);
            TSHeader.Validate(Status, TSHeader.Status::Open);
            TSHeader.Modify();
            Variant:=TSHeader;
        end;
        end;
    end;
    // =========================================================
    //  SECTION 5 — LIBRARY REGISTRATION
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    procedure AddTimesheetEventsToLibrary()begin
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendTimesheetForApprovalCode(), Database::"Monthly Timesheet Header", SendTimesheetReq, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnApproveTimesheetApprovalCode(), Database::"Approval Entry", AppReqTimesheet, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnRejectTimesheetApprovalCode(), Database::"Approval Entry", RejReqTimesheet, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnDelegateTimesheetApprovalCode(), Database::"Approval Entry", DelReqTimesheet, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelTimesheetApprovalCode(), Database::"Monthly Timesheet Header", UserCanReqTimesheet, 0, false);
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    procedure AddTimesheetResponsesToLibrary()begin
        WorkflowResponseHandling.AddResponseToLibrary(SetStatusToPendingApprovalCodeTimesheet(), 0, TimesheetPendAppTxt, 'GROUP 0');
        WorkflowResponseHandling.AddResponseToLibrary(ReleaseMonthlyTimesheetCode(), 0, ReleaseTimesheetTxt, 'GROUP 0');
        WorkflowResponseHandling.AddResponseToLibrary(ReOpenMonthlyTimesheetCode(), 0, ReOpenTimesheetTxt, 'GROUP 0');
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    procedure ExecuteTimesheetWorkflowResponse(var ResponseExecuted: Boolean;
    Variant: Variant;
    xVariant: Variant;
    ResponseWorkflowStepInstance: Record "Workflow Step Instance")var WorkflowResponse: Record "Workflow Response";
    begin
        if not WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name")then exit;
        case WorkflowResponse."Function Name" of SetStatusToPendingApprovalCodeTimesheet(): begin
            SetStatusToPendingApprovalTimesheet(Variant);
            ResponseExecuted:=true;
        end;
        ReleaseMonthlyTimesheetCode(): begin
            ReleaseMonthlyTimesheet(Variant);
            ResponseExecuted:=true;
        end;
        ReOpenMonthlyTimesheetCode(): begin
            ReOpenMonthlyTimesheet(Variant);
            ResponseExecuted:=true;
        end;
        end;
    end;
    // =========================================================
    //  SECTION 6 — TABLE RELATION + PREDECESSOR WIRING
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    local procedure AddTimesheetTableRelations()var ApprovalEntry: Record "Approval Entry";
    WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(Database::"Monthly Timesheet Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkFlowResponsePredecessorsToLibrary', '', true, true)]
    local procedure AddTimesheetResponsePredecessors(ResponseFunctionName: Code[128])var WorkFlowResponse: Codeunit "Workflow Response Handling";
    begin
        case ResponseFunctionName of WorkFlowResponse.SetStatusToPendingApprovalCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.SetStatusToPendingApprovalCode(), RunWorkflowOnSendTimesheetForApprovalCode());
        WorkFlowResponse.CreateApprovalRequestsCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.CreateApprovalRequestsCode(), RunWorkflowOnSendTimesheetForApprovalCode());
        WorkFlowResponse.SendApprovalRequestForApprovalCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.SendApprovalRequestForApprovalCode(), RunWorkflowOnSendTimesheetForApprovalCode());
        WorkFlowResponse.OpenDocumentCode(): WorkFlowResponse.AddResponsePredecessor(WorkFlowResponse.OpenDocumentCode(), RunWorkflowOnCancelTimesheetApprovalCode());
        end;
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef;
    var ApprovalEntryArgument: Record "Approval Entry";
    WorkflowStepInstance: Record "Workflow Step Instance")var TSHeader: Record "Monthly Timesheet Header";
    begin
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        RecRef.SetTable(TSHeader);
        ApprovalEntryArgument."Table ID":=Database::"Monthly Timesheet Header";
        ApprovalEntryArgument."Document No.":=TSHeader."No.";
    end;
    // =========================================================
    //  SECTION 7 — OPEN / RELEASE DOCUMENT HOOKS
    // =========================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef;
    var Handled: Boolean)var TSHeader: Record "Monthly Timesheet Header";
    begin
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        Handled:=true;
        RecRef.SetTable(TSHeader);
        TSHeader.Validate(Status, TSHeader.Status::Open);
        TSHeader.Modify();
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure OnReleaseDocument(RecRef: RecordRef;
    var Handled: Boolean)var VarVariant: Variant;
    begin
        if RecRef.Number <> Database::"Monthly Timesheet Header" then exit;
        Handled:=true;
        VarVariant:=RecRef;
        ReleaseMonthlyTimesheet(VarVariant);
    end;
}
