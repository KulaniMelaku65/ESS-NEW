query 51102 GetEmployeeEmergencyContacts
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getEmployeeEmergencyContact';
    EntitySetName = 'getEmployeeEmergencyContacts';
    QueryType = API;

    elements
    {
        dataitem(emergencyContact;
        "Employee Emergency Contact")
        {
            column(employeeNo;
            "Employee No.")
            {
                Caption = 'EmployeeNo';
            }
            column(lineNo;
            "Line No.")
            {
                Caption = 'LineNo';
            }
            column(firstName;
            "First Name")
            {
                Caption = 'FirstName';
            }
            column(middleName;
            "Middle Name")
            {
                Caption = 'MiddleName';
            }
            column(lastName;
            "Last Name")
            {
                Caption = 'LastName';
            }
            column(phoneNo;
            "Phone No.")
            {
                Caption = 'PhoneNo';
            }
            column(email;
            "E-Mail")
            {
                Caption = 'Email';
            }
            column(location;
            "Location")
            {
                Caption = 'Location';
            }
            column(relativeCode;
            "Relative Code")
            {
                Caption = 'RelativeCode';
            }
            dataitem(relative;
            Relative)
            {
                DataItemLink = "Code" = emergencyContact."Relative Code";
                column(association;
                Description)
                {
                    Caption = 'Association';
                }
            }
        }
    }
}
