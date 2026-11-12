query 51103 GetHRBPEmployees
{
    // One row per (HRBP, employee they cover), driven by Employee."HRBP No.".
    // The outer dataitem is the HRBP's own Employee record; the inner one is
    // every employee whose "HRBP No." points at it. InnerJoin means an HRBP
    // with nobody assigned simply doesn't appear, and employees with a blank
    // "HRBP No." are left out.
    //
    // Portal usage — all employees under one HRBP:
    //   .../getHRBPEmployees?$filter=hrbpNo eq 'EMP001'
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getHRBPEmployee';
    EntitySetName = 'getHRBPEmployees';
    QueryType = API;

    elements
    {
        dataitem(hrbp; Employee)
        {
            column(hrbpNo; "No.")
            {
                Caption = 'HRBPNo';
            }
            column(hrbpFullName; "Full Name")
            {
                Caption = 'HRBPFullName';
            }
            column(hrbpCompanyEmail; "Company E-Mail")
            {
                Caption = 'HRBPCompanyEmail';
            }
            dataitem(employee; Employee)
            {
                DataItemLink = "HRBP No." = hrbp."No.";
                SqlJoinType = InnerJoin;
                // Only active employees, at the head office, are linked to their
                // HRBP here. If an HRBP's employees are all inactive or outside
                // "Addis Ababa - HQ", the HRBP drops out (InnerJoin).
                DataItemTableFilter = "Employee Status" = const(Active), "Employee Location" = const('Addis Ababa - HQ');
                column(employeeNo; "No.")
                {
                    Caption = 'EmployeeNo';
                }
                column(employeeFullName; "Full Name")
                {
                    Caption = 'EmployeeFullName';
                }
                column(employeeStatus; "Employee Status")
                {
                    Caption = 'EmployeeStatus';
                }
                column(jobTitle; "Job Title")
                {
                    Caption = 'JobTitle';
                }
                column(virtualCompany; "Global Dimension 1 Code")
                {
                    Caption = 'VirtualCompany';
                }
                column(department; "Global Dimension 2 Code")
                {
                    Caption = 'Department';
                }
                column(employeeCompanyEmail; "Company E-Mail")
                {
                    Caption = 'EmployeeCompanyEmail';
                }
                column(employeePhoneNo; "Phone No.")
                {
                    Caption = 'EmployeePhoneNo';
                }
                column(supervisorNo; "Supervisor No.")
                {
                    Caption = 'SupervisorNo';
                }
                column(supervisorName; "Supervisor Name")
                {
                    Caption = 'SupervisorName';
                }
            }
        }
    }
}
