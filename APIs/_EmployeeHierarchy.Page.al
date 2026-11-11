page 51139 "Employee Hierarchy API"
{
    PageType = API;
    APIPublisher = 'Kifiya';
    APIGroup = 'hr';
    APIVersion = 'v1.0';
    EntityName = 'employeeHierarchy';
    EntitySetName = 'employeeHierarchies';
    SourceTable = Employee;
    SourceTableView = where(Status = const(Active));
    ODataKeyFields = SystemId;
    Editable = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { }
                field(employeeNo; Rec."No.") { }
                field(employeeFirstName; Rec."First Name") { }
                field(employeeMiddleName; Rec."Middle Name") { }
                field(employeeLastName; Rec."Last Name") { }
                field(fullName; EmployeeFullName) { }
                field(jobTitle; Rec."Job Title") { }
                field("jobDescription";Rec."Job Description") { }
                field(departmentCode; Rec."Global Dimension 2 Code") { }
                field(companyEmail; Rec."Company E-Mail") { }
                field(supervisorNo; Rec."Supervisor No.") { }   // custom field
                field(supervisorFullName; SupervisorFullName) { }
                field(supervisorStatus; SupervisorStatus) { }
            }
        }
    }

    var
        EmployeeFullName: Text[250];
        SupervisorFullName: Text[250];
        SupervisorStatus: Text[20];

    trigger OnAfterGetRecord()
    var
        Supervisor: Record Employee;
    begin
        EmployeeFullName := BuildFullName(Rec);

        SupervisorFullName := '';
        SupervisorStatus := '';
        if Rec."Supervisor No." <> '' then
            if Supervisor.Get(Rec."Supervisor No.") then begin
                SupervisorFullName := BuildFullName(Supervisor);
                SupervisorStatus := Format(Supervisor.Status);
            end else
                SupervisorStatus := 'Not found';
    end;

    local procedure BuildFullName(Emp: Record Employee): Text[250]
    var
        Result: Text;
    begin
        Result := DelChr(Emp."First Name", '<>', ' ');
        if DelChr(Emp."Middle Name", '<>', ' ') <> '' then
            Result += ' ' + DelChr(Emp."Middle Name", '<>', ' ');
        if DelChr(Emp."Last Name", '<>', ' ') <> '' then
            Result += ' ' + DelChr(Emp."Last Name", '<>', ' ');
        exit(CopyStr(Result, 1, 250));
    end;
}