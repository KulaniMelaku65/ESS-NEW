table 51126 "Calendar Day Entry"
{
    DataClassification = CustomerContent;
    Caption = 'Calendar Day Entry';

    fields
    {
        field(1;"Calendar Code";Code[10])
        {
            Caption = 'Calendar Code';
            DataClassification = CustomerContent;
            TableRelation = "Base Calendar";
            NotBlank = true;
        }
        field(2;Date;Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3;"Day Name";Text[10])
        {
            Caption = 'Day';
            DataClassification = CustomerContent;
        }
        field(4;"Is Working Day";Boolean)
        {
            Caption = 'Is Working Day';
            DataClassification = CustomerContent;
        }
        field(5;"Is Half Day";Boolean)
        {
            Caption = 'Is Half Day';
            DataClassification = CustomerContent;
        }
        field(6;Description;Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK;"Calendar Code", Date)
        {
            Clustered = true;
        }
    }
}
