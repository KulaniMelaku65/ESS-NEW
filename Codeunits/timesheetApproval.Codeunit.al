codeunit 51112 timesheetApproval
{
    procedure SubmitForMonthlyApproval(timesheetNo: Code[20]): Text var Header: Record "Monthly Timesheet Header";
    ApprovalsMgt: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(timesheetNo)then Error('Timesheet %1 not found.', timesheetNo);
        ApprovalsMgt.SubmitTimesheet(Header);
        exit(StrSubstNo('SUCCESS::%1 submitted for approval', timesheetNo));
    end;
    procedure ApproveMonthlyTimesheet(timesheetNo: Code[20];
    approverUser: Code[50]): Text var Header: Record "Monthly Timesheet Header";
    ApprovalsMgt: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(timesheetNo)then Error('Timesheet %1 not found.', timesheetNo);
        if approverUser = '' then Error('approverUser is required.');
        ApprovalsMgt.ApproveTimesheet(Header, approverUser);
        exit(StrSubstNo('SUCCESS::Approved by %1', approverUser));
    end;
    procedure RejectMonthlyTimesheet(timesheetNo: Code[20];
    approverUser: Code[50];
    reason: Text[250]): Text var Header: Record "Monthly Timesheet Header";
    ApprovalsMgt: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(timesheetNo)then Error('Timesheet %1 not found.', timesheetNo);
        if approverUser = '' then Error('approverUser is required.');
        if reason = '' then Error('reason is required.');
        ApprovalsMgt.RejectTimesheet(Header, approverUser, reason);
        exit(StrSubstNo('SUCCESS::Rejected by %1', approverUser));
    end;
    procedure CancelMonthlyApprovalRequest(timesheetNo: Code[20]): Text var Header: Record "Monthly Timesheet Header";
    ApprovalsMgt: Codeunit "Approvals Timesheet Mgmt.";
    begin
        if not Header.Get(timesheetNo)then Error('Timesheet %1 not found.', timesheetNo);
        ApprovalsMgt.CancelTimesheet(Header);
        exit(StrSubstNo('SUCCESS::%1 approval request cancelled', timesheetNo));
    end;
}
