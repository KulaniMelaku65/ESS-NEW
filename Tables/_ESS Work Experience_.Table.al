table 51105 "ESS Work Experience"
{
    Caption = 'Work Experience';
    DataClassification = CustomerContent;

    fields
    {
        field(1;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(2;"Line No.";Integer)
        {
            Caption = 'Line No.';
        }
        field(3;"Company Name";Text[100])
        {
            Caption = 'Company Name';
        }
        field(4;"Position";Text[100])
        {
            Caption = 'Position';
        }
        field(5;"From Date";Date)
        {
            Caption = 'From Date';
        }
        field(6;"To Date";Date)
        {
            Caption = 'To Date';
        }
        field(7;"Description";Text[250])
        {
            Caption = 'Description';
        }
    }
    keys
    {
        key(PK;"Employee No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
