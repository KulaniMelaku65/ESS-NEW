table 51106 "Withholding Setup"
{
    // List of withholding codes/rates a Sales Line can apply — not a singleton, a real list
    // (unlike "E-Receipt Setup"). "Sales Invoice" marks which codes are usable there (the
    // same table could later carry codes for other document types without those also
    // showing up on Sales Invoice lines).
    DataClassification = CustomerContent;
    Caption = 'Withholding Setup';

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Withholding %"; Decimal)
        {
            Caption = 'Withholding %';
            MinValue = 0;
            MaxValue = 100;
        }
        field(3; "Sales Invoice"; Boolean)
        {
            Caption = 'Sales Invoice';
            // Whether this code can be selected on a Sales Line — the TableRelation on
            // "Sales Line Withholding".TableExt."Withholding Code" filters on this.
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
            // Not yet wired into posting — codeunit 51105 doesn't create any G/L entries
            // from this. Column only, for now.
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
