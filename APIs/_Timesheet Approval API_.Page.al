page 51108 "Timesheet Approval API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet Approval API';
    DelayedInsert = false;
    EntityName = 'TimesheetForApproval';
    EntitySetName = 'TimesheetsForApproval';
    PageType = API;
    SourceTable = "Monthly Timesheet Header";
    ODataKeyFields = "No.";
    Editable = false; // Read-only for approvers
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no;Rec."No.")
                {
                    Caption = 'Timesheet No.';
                }
                field(employeeNo;Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(employeeName;EmployeeName)
                {
                    Caption = 'Employee Name';
                }
                field(employeeEmail;EmployeeEmail)
                {
                    Caption = 'Employee Email';
                }
                field(month;Rec.Month)
                {
                    Caption = 'Month';
                }
                field(year;Rec.Year)
                {
                    Caption = 'Year';
                }
                field(totalHours;Rec."Total Hours")
                {
                    Caption = 'Total Hours';
                }
                field(status;Rec.Status)
                {
                    Caption = 'Status';
                }
                field(approverID;Rec."Approver ID")
                {
                    Caption = 'Current Approver ID';
                }
                field(submittedDate;SubmittedDateTime)
                {
                    Caption = 'Submitted Date';
                }
                field(currentApprovalSequence;CurrentSequence)
                {
                    Caption = 'Approval Sequence';
                }
                field(pendingWith;PendingWithApprover)
                {
                    Caption = 'Pending With';
                }
                // Nested lines so approver can see the full timesheet
                part(TimesheetLines;"Timesheet Approval Lines API")
                {
                    Caption = 'Timesheet Lines';
                    EntityName = 'TimesheetLineForApproval';
                    EntitySetName = 'TimesheetLinesForApproval';
                    SubPageLink = "Document No."=field("No.");
                }
            }
        }
    }
    trigger OnOpenPage()var UserSetup: Record "User Setup";
    ApproverFilter: Text;
    begin
        // Filter to show only timesheets pending approval by current user
        // You can pass the user ID as a filter parameter from your web app
        // Example: Filter by Approver ID
        // Rec.SetRange("Approver ID", UserId);
        // Or filter by status to show all pending timesheets
        Rec.SetFilter(Status, '%1|%2', Rec.Status::"Pending Approval", Rec.Status::Approved);
    end;
    trigger OnAfterGetRecord()var Employee: Record Employee;
    ApprovalEntry: Record "Timesheet Approval Entry";
    UserSetup: Record "User Setup";
    begin
        // Clear variables
        Clear(EmployeeName);
        Clear(EmployeeEmail);
        Clear(SubmittedDateTime);
        Clear(CurrentSequence);
        Clear(PendingWithApprover);
        // Get Employee details
        if Employee.Get(Rec."Employee No.")then begin
            EmployeeName:=Employee."First Name" + ' ' +Employee."Middle Name" + ' ' +Employee."Last Name";
            EmployeeEmail:=Employee."Company E-Mail";
        end;
        // Get approval entry details
        ApprovalEntry.SetRange("Timesheet No.", Rec."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if ApprovalEntry.FindLast()then begin
            SubmittedDateTime:=ApprovalEntry."Date-Time Sent";
            CurrentSequence:=ApprovalEntry."Sequence No.";
            // Get approver name
            if UserSetup.Get(ApprovalEntry."Approver ID")then PendingWithApprover:=ApprovalEntry."Approver ID"
            else
                PendingWithApprover:=ApprovalEntry."Approver ID";
        end;
    end;
    var EmployeeName: Text[100];
    EmployeeEmail: Text[80];
    SubmittedDateTime: DateTime;
    CurrentSequence: Integer;
    PendingWithApprover: Text[50];
}
