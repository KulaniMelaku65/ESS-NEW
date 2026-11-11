page 51114 "Timesheet Report Data API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet Report Data API';
    DelayedInsert = false;
    EntityName = 'TimesheetReport';
    EntitySetName = 'TimesheetReports';
    PageType = API;
    SourceTable = "Monthly Timesheet Header";
    ODataKeyFields = "No.";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no;Rec."No.")
                {
                    Caption = 'No.';
                }
                field(employeeNo;Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(employeeName;EmployeeName)
                {
                    Caption = 'Employee Name';
                }
                field(month;Rec.Month)
                {
                    Caption = 'Month';
                }
                field(monthName;MonthName)
                {
                    Caption = 'Month Name';
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
                    Caption = 'Approver ID';
                }
                field(approvedByName;ApprovedByName)
                {
                    Caption = 'Approved By';
                }
                field(reasonForRejection;Rec."Reason for Rejection")
                {
                    Caption = 'Reason for Rejection';
                }
            }
            part(Lines;tsLineAPI)
            {
                Caption = 'Lines';
                EntityName = 'TimesheetsLine';
                EntitySetName = 'TimesheetsLines';
                SubPageLink = "Document No."=field("No.");
            }
        }
    }
    trigger OnAfterGetRecord()begin
        Rec.CalcFields("Total Hours");
        EmployeeName:=GetEmployeeFullName(Rec."Employee No.");
        ApprovedByName:=GetApprovedByName(Rec."No.");
        MonthName:=Format(Rec.Month);
    end;
    var EmployeeName: Text[250];
    ApprovedByName: Text[250];
    MonthName: Text[20];
    local procedure GetEmployeeFullName(EmployeeNo: Code[20]): Text[250]var Emp: Record Employee;
    FullName: Text;
    begin
        if EmployeeNo = '' then exit('');
        if not Emp.Get(EmployeeNo)then exit('');
        FullName:=Emp."First Name";
        if Emp."Middle Name" <> '' then FullName+=' ' + Emp."Middle Name";
        if Emp."Last Name" <> '' then FullName+=' ' + Emp."Last Name";
        exit(CopyStr(DelChr(FullName, '<>', ' '), 1, 250));
    end;
    local procedure GetApprovedByName(TimesheetNo: Code[20]): Text[250]var ApprEntry: Record "Timesheet Approval Entry";
    UserSetup: Record "User Setup";
    Emp: Record Employee;
    ApproverEmail: Text[80];
    FullName: Text;
    begin
        ApprEntry.Reset();
        ApprEntry.SetRange("Timesheet No.", TimesheetNo);
        ApprEntry.SetCurrentKey("Sequence No.");
        if not ApprEntry.FindLast()then exit('');
        if ApprEntry.Status <> ApprEntry.Status::Approved then exit('');
        if not UserSetup.Get(ApprEntry."Approver ID")then exit('');
        ApproverEmail:=UserSetup."E-Mail";
        if ApproverEmail = '' then exit('');
        Emp.Reset();
        Emp.SetRange("Company E-Mail", ApproverEmail);
        if not Emp.FindFirst()then exit('');
        FullName:=Emp."First Name";
        if Emp."Middle Name" <> '' then FullName+=' ' + Emp."Middle Name";
        if Emp."Last Name" <> '' then FullName+=' ' + Emp."Last Name";
        exit(CopyStr(DelChr(FullName, '<>', ' '), 1, 250));
    end;
}
