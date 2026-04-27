codeunit 51100 "Timesheet Mgt."
{
    // --- 1. REGISTRATION: Make the events appear in the ERP UI ---
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // Main Event
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendTimesheetForApprovalCode(), Database::"Monthly Timesheet Header", 'An approval of a monthly timesheet is requested.', 0, false);

        // Status Events (To match your system's pattern)
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnTimeSheetApprovedCode(), Database::"Monthly Timesheet Header", 'Approval Request for TimeSheet is approved', 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnTimeSheetRejectedCode(), Database::"Monthly Timesheet Header", 'Approval Request for TimeSheet is rejected', 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnTimeSheetCancelledCode(), Database::"Monthly Timesheet Header", 'Approval Request for TimeSheet is cancelled by User', 0, false);
    end;

    // --- 2. UNIQUE CODES (Used by Workflow Engine) ---
    procedure RunWorkflowOnSendTimesheetForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendTimesheetForApproval'));
    end;

    procedure RunWorkflowOnTimeSheetApprovedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnTimeSheetApproved'));
    end;

    procedure RunWorkflowOnTimeSheetRejectedCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnTimeSheetRejected'));
    end;

    procedure RunWorkflowOnTimeSheetCancelledCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnTimeSheetCancelled'));
    end;

    // --- 3. MAPPING: Link Custom Table to the Approval Entry System ---
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        TSHeader: Record "Monthly Timesheet Header";
    begin
        if RecRef.Number = Database::"Monthly Timesheet Header" then begin
            RecRef.SetTable(TSHeader);
            ApprovalEntryArgument."Table ID" := Database::"Monthly Timesheet Header";
            ApprovalEntryArgument."Document No." := TSHeader."No.";
        end;
    end;

    // --- 4. EXECUTION: Logic for "Release Time_Sheet" and "ReOpen" Responses ---
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowResponse: Record "Workflow Response";
        TSHeader: Record "Monthly Timesheet Header";
        RecRef: RecordRef;
    begin
        if WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name") then begin
            RecRef.GetTable(Variant);
            if RecRef.Number = Database::"Monthly Timesheet Header" then begin
                RecRef.SetTable(TSHeader);
                case WorkflowResponse."Function Name" of
                    'SetStatusToPendingApproval': // Standard BC code
                        begin
                            TSHeader.Status := TSHeader.Status::"Pending Approval";
                            TSHeader.Modify();
                            ResponseExecuted := true;
                        end;
                    'Release TimeSheet': // Matches your UI list
                        begin
                            TSHeader.Status := TSHeader.Status::Released;
                            TSHeader.Modify();
                            ResponseExecuted := true;
                        end;
                    'ReOpen TimeSheet': // Matches your UI list
                        begin
                            TSHeader.Status := TSHeader.Status::Open;
                            TSHeader.Modify();
                            ResponseExecuted := true;
                        end;
                end;
            end;
        end;
    end;

    // --- 5. HANDLING APPROVAL ACTIONS ---
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', false, false)]
    local procedure RunOnApprove(var ApprovalEntry: Record "Approval Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if ApprovalEntry."Table ID" = Database::"Monthly Timesheet Header" then
            WorkflowManagement.HandleEvent(RunWorkflowOnTimeSheetApprovedCode(), ApprovalEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure RunOnReject(var ApprovalEntry: Record "Approval Entry")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if ApprovalEntry."Table ID" = Database::"Monthly Timesheet Header" then
            WorkflowManagement.HandleEvent(RunWorkflowOnTimeSheetRejectedCode(), ApprovalEntry);
    end;

    // --- 6. CORE BUSINESS LOGIC ---
    procedure SubmitTimesheet(var Header: Record "Monthly Timesheet Header")
    begin
        if Header.Status <> Header.Status::Open then
            Error('Only Open timesheets can be submitted.');

        Header.TestField("Employee No.");
        if not LinesExist(Header."No.") then
            Error('You cannot submit an empty timesheet.');

        OnSendTimesheetForApproval(Header);
    end;

    local procedure LinesExist(DocNo: Code[20]): Boolean
    var
        Lines: Record "Monthly Timesheet Line";
    begin
        Lines.SetRange("Document No.", DocNo);
        exit(not Lines.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendTimesheetForApproval(var Timesheet: Record "Monthly Timesheet Header")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Timesheet Mgt.", 'OnSendTimesheetForApproval', '', false, false)]
    local procedure RunWorkflowOnSendTimesheetForApproval(var Timesheet: Record "Monthly Timesheet Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendTimesheetForApprovalCode(), Timesheet);
    end;
}
//An event with description Approval Request for Time_Sheet is approved already exists.