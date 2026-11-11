table 51108 "Employee Location"
{
    DataClassification = CustomerContent;
    Caption = 'Employee Location';
    LookupPageId = "Employee Location List";
    DrillDownPageId = "Employee Location List";
    Permissions = tabledata "Employee Location"=R,
        tabledata "ESS Work Experience"=RIMD;

    fields
    {
        field(1;"Code";Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2;"Description";Text[100])
        {
            Caption = 'Description';
        }
    }
    keys
    {
        key(PK;"Code")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown;"Code", "Description")
        {
        }
    }
}
