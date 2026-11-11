table 51116 "Timesheet Filler"
{
    DataClassification = CustomerContent;
    Caption = 'Timesheet Filler';
    LookupPageId = "Timesheet Filler List";
    DrillDownPageId = "Timesheet Filler List";

    fields
    {
        field(1;"Employee ID";Code[20])
        {
            Caption = 'Employee ID';
            TableRelation = Employee;
            NotBlank = true;
            DataClassification = CustomerContent;

            trigger OnValidate()var Employee: Record Employee;
            begin
                if Employee.Get("Employee ID")then begin
                    "First Name":=Employee."First Name";
                    "Middle Name":=Employee."Middle Name";
                    "Last Name":=Employee."Last Name";
                    "Employment Type":=CopyStr(Format(Employee."Employee Type"), 1, 50);
                end
                else
                begin
                    "First Name":='';
                    "Middle Name":='';
                    "Last Name":='';
                    "Employment Type":='';
                end;
            end;
        }
        field(2;"First Name";Text[100])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
        }
        field(3;"Middle Name";Text[100])
        {
            Caption = 'Middle Name';
            DataClassification = CustomerContent;
        }
        field(4;"Last Name";Text[100])
        {
            Caption = 'Last Name';
            DataClassification = CustomerContent;
        }
        field(5;"Employment Type";Text[50])
        {
            Caption = 'Employment Type';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK;"Employee ID")
        {
            Clustered = true;
        }
    }
}
