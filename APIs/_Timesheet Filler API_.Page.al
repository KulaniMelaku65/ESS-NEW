page 51117 "Timesheet Filler API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet Filler API';
    DelayedInsert = true;
    EntityName = 'TimesheetFiller';
    EntitySetName = 'TimesheetFillers';
    PageType = API;
    SourceTable = "Timesheet Filler";
    ODataKeyFields = "Employee ID";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(employeeID;Rec."Employee ID")
                {
                    Caption = 'Employee ID';
                }
                field(firstName;Rec."First Name")
                {
                    Caption = 'First Name';
                }
                field(middleName;Rec."Middle Name")
                {
                    Caption = 'Middle Name';
                }
                field(lastName;Rec."Last Name")
                {
                    Caption = 'Last Name';
                }
                field(employmentType;Rec."Employment Type")
                {
                    Caption = 'Employment Type';
                }
            }
        }
    }
}
