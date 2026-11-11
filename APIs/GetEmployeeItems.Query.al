query 51104 GetEmployeeItems
{
    // Items / fixed assets issued to employees — table "Employee Items"
    // (Fanisi_HR, maintained from the HR Employee Card). One row per line.
    //
    // Portal usage — one employee's items:
    //   .../getEmployeeItems?$filter=employeeNo eq 'EMP001'
    // Only items still with the employee: add "and returned eq false".
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getEmployeeItem';
    EntitySetName = 'getEmployeeItems';
    QueryType = API;

    elements
    {
        dataitem(employeeItem; "Employee Items")
        {
            column(employeeNo; "Employee No.")
            {
                Caption = 'EmployeeNo';
            }
            column(lineNo; "Line No.")
            {
                Caption = 'LineNo';
            }
            column(itemType; "Item Type")
            {
                Caption = 'ItemType';
            }
            column(itemNo; "Item No.")
            {
                Caption = 'ItemNo';
            }
            column(description; Description)
            {
                Caption = 'Description';
            }
            column(startDate; "Start Date")
            {
                Caption = 'StartDate';
            }
            column(endDate; "End Date")
            {
                Caption = 'EndDate';
            }
            column(allocated; Allocated)
            {
                Caption = 'Allocated';
            }
            column(dateAllocated; "Date Allocated")
            {
                Caption = 'DateAllocated';
            }
            column(allocatedBy; "Allocated By")
            {
                Caption = 'AllocatedBy';
            }
            column(returned; Returned)
            {
                Caption = 'Returned';
            }
            column(dateReturned; "Date Returned")
            {
                Caption = 'DateReturned';
            }
            column(returnCapturedBy; "Return Captured By")
            {
                Caption = 'ReturnCapturedBy';
            }
            dataitem(employee; Employee)
            {
                DataItemLink = "No." = employeeItem."Employee No.";
                SqlJoinType = LeftOuterJoin;
                column(employeeFullName; "Full Name")
                {
                    Caption = 'EmployeeFullName';
                }
                column(department; "Global Dimension 2 Code")
                {
                    Caption = 'Department';
                }
            }
        }
    }
}
