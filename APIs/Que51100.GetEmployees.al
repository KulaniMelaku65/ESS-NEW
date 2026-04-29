query 51100 GetEmployees
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getEmployee';
    EntitySetName = 'getEmployees';
    QueryType = API;


    elements
    {
        dataitem(employee; Employee)
        {
            column(no; "No.")
            {
                Caption = 'No';
            }
            column(fullName; "Full Name")
            {
                Caption = 'FullName';
            }
            column(employeeStatus; "Employee Status")
            {
                Caption = 'EmployeeStatus';
            }
            column(status; Status)
            {
                Caption = 'Status';
            }
            column(leaveBalance; "Leave Balance")
            {
                Caption = 'LeaveBalance';
            }
            column(employeeType; "Employee Type")
            {
                Caption = 'EmployeeType';
            }
        }
    }


}
