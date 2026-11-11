page 51106 timesheetapprovalentries
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'timesheetapprovalentries';
    DelayedInsert = true;
    EntityName = 'tsApprovalEntries';
    EntitySetName = 'tsApprovalEntries';
    PageType = API;
    SourceTable = "Timesheet Approval Entry";
    ODataKeyFields = "Timesheet No.", "Sequence No.";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(timesheetNo;Rec."Timesheet No.")
                {
                    Caption = 'Timesheet No.';
                }
                field(approverID;Rec."Approver ID")
                {
                    Caption = 'Approver ID';
                }
                field(approverEmployeeNo;ApproverEmployeeNo)
                {
                    Caption = 'Approver Employee No.';
                }
                field(approverName;ApproverName)
                {
                    Caption = 'Approver Name';
                }
                field(approvedBy;Rec."Approved By")
                {
                    Caption = 'Approved By';
                }
                field(rejectedBy;Rec."Rejected By")
                {
                    Caption = 'Rejected By';
                }
                field(approverSequenceNo;ApproverSequenceNo)
                {
                    Caption = 'Approver Sequence No.';
                }
                field(status;Rec.Status)
                {
                    Caption = 'Status';
                }
                field(employeeNo;Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(employeeName;Rec."Employee Name")
                {
                    Caption = 'Employee Name';
                }
                field(timesheetPeriod;TimesheetPeriod)
                {
                    Caption = 'Timesheet Period';
                }
                field(description;Rec.Description)
                {
                    Caption = 'Description';
                }
                field(dateTimeSent;Rec."Date-Time Sent")
                {
                    Caption = 'Date-Time Sent';
                }
            }
        }
    }
    trigger OnAfterGetRecord()var Employee: Record Employee;
    SalesSetup: Record "Sales & Receivables Setup";
    WorkflowUserGroupMember: Record "Workflow User Group Member";
    TimesheetHeader: Record "Monthly Timesheet Header";
    begin
        // Clear the calculated fields
        Clear(ApproverEmployeeNo);
        Clear(ApproverName);
        Clear(ApproverSequenceNo);
        Clear(WorkflowUserGroupCode);
        Clear(TimesheetPeriod);
        // STEP 0: Get Month and Year from Timesheet Header
        // ═══════════════════════════════════════════════════════
        if TimesheetHeader.Get(Rec."Timesheet No.")then begin
            TimesheetMonth:=Format(TimesheetHeader.Month);
            TimesheetYear:=TimesheetHeader.Year;
            // Combined period: "April, 2026"
            TimesheetPeriod:=TimesheetMonth + ', ' + Format(TimesheetYear);
        end;
        // ═══════════════════════════════════════════════════════
        // STEP 1: Get Workflow User Group Code from Sales Setup
        // (Same method as TimesheetApproversAPI)
        // ═══════════════════════════════════════════════════════
        if SalesSetup.Get()then begin
            WorkflowUserGroupCode:=SalesSetup."Timesheet Workflow Group Code";
            // ═══════════════════════════════════════════════════
            // STEP 2: Get Approver's Sequence No. from Workflow User Group
            // ═══════════════════════════════════════════════════
            WorkflowUserGroupMember.Reset();
            WorkflowUserGroupMember.SetRange("Workflow User Group Code", SalesSetup."Timesheet Workflow Group Code");
            WorkflowUserGroupMember.SetRange("User Name", Rec."Approver ID");
            if WorkflowUserGroupMember.FindFirst()then ApproverSequenceNo:=WorkflowUserGroupMember."Sequence No.";
        end;
        // Falls back to the entry's own stored sequence (covers the dynamic
        // supervisor step, who is never a member of the static workflow group).
        if ApproverSequenceNo = 0 then ApproverSequenceNo:=Rec."Sequence No.";
        // ═══════════════════════════════════════════════════════
        // STEP 3: Resolve the approver's Employee record. "Approver ID" holds
        // a BC User ID for the static step-1 approver, but an Employee No. for
        // the dynamic supervisor step (same identity the Leave module uses —
        // no "User Setup" dependency). Try Employee No. first since that's the
        // common case going forward, then fall back to User ID for step 1.
        // ═══════════════════════════════════════════════════════
        if Employee.Get(Rec."Approver ID")then begin
            ApproverEmployeeNo:=Employee."No.";
            ApproverName:=Employee."First Name" + ' ' + Employee."Last Name";
        end
        else
        begin
            Employee.Reset();
            Employee.SetRange("User ID", Rec."Approver ID");
            if Employee.FindFirst()then begin
                ApproverEmployeeNo:=Employee."No.";
                ApproverName:=Employee."First Name" + ' ' + Employee."Last Name";
            end;
        end;
    end;
    trigger OnOpenPage()begin
        Rec.SetFilter(Status, '%1|%2', Rec.Status::Open, Rec.Status::Created);
    end;
    var ApproverEmployeeNo: Code[20];
    ApproverName: Text[100];
    ApproverSequenceNo: Integer;
    WorkflowUserGroupCode: Code[20];
    TimesheetPeriod: Text[50];
    TimesheetMonth: Text[20];
    TimesheetYear: Integer;
}
