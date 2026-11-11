page 51107 "Timesheet Approvers API"
{
    // Second (final sign-off) step only — a single ERP-configured person,
    // "Timesheet Final Approver No." on Sales & Receivables Setup, resolved
    // via Approvals Timesheet Mgmt.'s own helpers so this can never drift
    // out of sync with the actual approval logic. The dynamic first-step
    // approver (each employee's own supervisor) isn't a fixed roster entry
    // — the portal already gets that per-employee via GetEmployees
    // (supervisorCode / supervisorName).
    PageType = API;
    APIPublisher = 'kifiya';
    APIGroup = 'timesheet';
    APIVersion = 'v1.0';
    EntityName = 'timesheetApprover';
    EntitySetName = 'timesheetApprovers';
    SourceTable = "Sales & Receivables Setup";
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(employeeNo;FinalApproverNo)
                {
                    Caption = 'Employee No';
                }
                field(employeeName;FinalApproverName)
                {
                    Caption = 'Employee Name';
                }
                field(email;FinalApproverEmail)
                {
                    Caption = 'Email';
                }
            }
        }
    }
    trigger OnAfterGetRecord()var ApprovalsMgt: Codeunit "Approvals Timesheet Mgmt.";
    Employee: Record Employee;
    begin
        Clear(FinalApproverNo);
        Clear(FinalApproverName);
        Clear(FinalApproverEmail);
        FinalApproverNo:=ApprovalsMgt.GetFinalApproverNo();
        FinalApproverEmail:=ApprovalsMgt.GetFinalApproverEmail();
        if Employee.Get(FinalApproverNo)then FinalApproverName:=Employee."First Name" + ' ' + Employee."Last Name";
    end;
    var FinalApproverNo: Code[20];
    FinalApproverName: Text[100];
    FinalApproverEmail: Text[80];
}
