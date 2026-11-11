codeunit 51106 "Timesheet Web API"
{
    Subtype = Normal;

    // Submit
    /// <summary>
 
/// SubmitForMonthlyApproval. 
 
/// </summary>
 
/// <param name="TimesheetNo">Code[20].</param>
 
/// <returns>Return variable Result of type Text.</returns>
[ServiceEnabled]
    procedure SubmitForMonthlyApproval(TimesheetNo: Code[20])Result: Text var Header: Record "Monthly Timesheet Header";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(TimesheetNo)then exit('FAILED::Timesheet not found');
        TSApprovals.SubmitTimesheet(Header);
        Result:='SUCCESS::' + TimesheetNo;
    end;
    // Cancel
    [ServiceEnabled]
    procedure CancelMonthlyApprovalRequest(TimesheetNo: Code[20])Result: Text var Header: Record "Monthly Timesheet Header";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(TimesheetNo)then exit('FAILED::Timesheet not found');
        TSApprovals.CancelTimesheet(Header);
        Result:='SUCCESS::Cancelled ' + TimesheetNo;
    end;
    // Approve
    [ServiceEnabled]
    procedure ApproveMonthlyTimesheet(TimesheetNo: Code[20];
    ApproverUser: Code[50])Result: Text var Header: Record "Monthly Timesheet Header";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(TimesheetNo)then exit('FAILED::Timesheet not found');
        TSApprovals.ApproveTimesheet(Header, ApproverUser);
        Result:='SUCCESS::Approved by ' + ApproverUser;
    end;
    // Reject
    [ServiceEnabled]
    procedure RejectMonthlyTimesheet(TimesheetNo: Code[20];
    ApproverUser: Code[50];
    Reason: Text[250])Result: Text var Header: Record "Monthly Timesheet Header";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(TimesheetNo)then exit('FAILED::Timesheet not found');
        TSApprovals.RejectTimesheet(Header, ApproverUser, Reason);
        Result:='SUCCESS::Rejected by ' + ApproverUser;
    end;
    /// <summary>

/// Get Timesheet Approvers.
/// Returns the full 2-step chain for this specific timesheet: the owner's
/// own supervisor (step 1) and the ERP-configured final approver (step 2).
/// Both are identified by Employee No. — same identity scheme used
/// everywhere else in this integration, resolved via Approvals Timesheet
/// Mgmt. itself so this can't drift out of sync with the real logic.

/// </summary>
[ServiceEnabled]
    procedure GetTimesheetApprovers(TimesheetNo: Code[20])Result: Text var Header: Record "Monthly Timesheet Header";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    SupervisorNo: Code[20];
    FinalApproverNo: Code[20];
    ApproversList: Text;
    begin
        if not Header.Get(TimesheetNo)then exit('{"error": "Timesheet not found"}');
        SupervisorNo:=TSApprovals.GetSupervisorEmployeeNo(Header."Employee No.");
        FinalApproverNo:=TSApprovals.GetFinalApproverNo();
        ApproversList:='[';
        if SupervisorNo <> '' then ApproversList+='{"sequenceNo":1,"employeeNo":"' + SupervisorNo + '","employeeName":"' + GetApproverName(SupervisorNo) + '"}';
        if FinalApproverNo <> '' then begin
            if ApproversList <> '[' then ApproversList+=',';
            ApproversList+='{"sequenceNo":2,"employeeNo":"' + FinalApproverNo + '","employeeName":"' + GetApproverName(FinalApproverNo) + '"}';
        end;
        ApproversList+=']';
        Result:=ApproversList;
    end;
    /// <summary>

/// Get Next Approver for a Timesheet.
/// Returns whoever is currently required to act next — read straight off
/// the header's own "Approver ID" (an Employee No.), which Approvals
/// Timesheet Mgmt. already keeps correct at every step.

/// </summary>
[ServiceEnabled]
    procedure GetNextApprover(TimesheetNo: Code[20])Result: Text var Header: Record "Monthly Timesheet Header";
    begin
        if not Header.Get(TimesheetNo)then exit('{"error": "Timesheet not found"}');
        if Header."Approver ID" = '' then exit('{"error": "No more approvers in sequence"}');
        Result:='{"employeeNo":"' + Header."Approver ID" + '","employeeName":"' + GetApproverName(Header."Approver ID") + '"}';
    end;
    local procedure GetApproverName(EmployeeNo: Code[20]): Text var Employee: Record Employee;
    begin
        if EmployeeNo = '' then exit('');
        if not Employee.Get(EmployeeNo)then exit('');
        exit(Employee."First Name" + ' ' + Employee."Last Name");
    end;
}
