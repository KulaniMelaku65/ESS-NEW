table 51107 "Excise Setup"
{
    // Excise rates by product category, per the EIMS tax calc reference. Deliberately a
    // flat Code+% list rather than keyed by BC's own "Item Category Code" — mirrors
    // "Withholding Setup" (table 51106)'s pattern so the two setups work the same way,
    // and avoids depending on existing Item Category data being populated/accurate.
    // Items opt in via their own "Excise Code" (see TableExt 51107 "Item Excise"); blank
    // means not excisable.
    DataClassification = CustomerContent;
    Caption = 'Excise Setup';

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Excise %"; Decimal)
        {
            Caption = 'Excise %';
            MinValue = 0;
            MaxValue = 100;
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
