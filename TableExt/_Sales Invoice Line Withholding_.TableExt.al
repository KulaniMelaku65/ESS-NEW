tableextension 51106 "Sales Invoice Line Withholding" extends "Sales Invoice Line"
{
    // Named identically to TableExt "Sales Line Withholding" (same field names, same
    // field numbers) so BC's own posting routine (TransferFields, codeunit 80
    // "Sales-Post") carries "Apply Withholding"/"Withholding Code"/"Withholding %"/
    // "Withholding Amount" onto the posted line automatically — without this, posting
    // would silently drop that data. No OnValidate triggers here: a posted line is
    // historical record, never recalculated.
    fields
    {
        field(51100; "Apply Withholding"; Boolean)
        {
            Caption = 'Apply Withholding';
            DataClassification = CustomerContent;
        }
        field(51101; "Withholding Code"; Code[20])
        {
            Caption = 'Withholding Code';
            DataClassification = CustomerContent;
        }
        field(51102; "Withholding %"; Decimal)
        {
            Caption = 'Withholding %';
            DataClassification = CustomerContent;
        }
        field(51103; "Withholding Amount"; Decimal)
        {
            Caption = 'Withholding Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(51104; "Total Withholding Amount"; Decimal)
        {
            Caption = 'Total Withholding Amount';
            Editable = false;
            FieldClass = FlowField;
            // Same self-referential-sum pattern as the unposted version — "Sales Invoice
            // Line" has no "Document Type" field (a posted sales invoice is always type
            // Invoice), so the filter is just "Document No.".
            CalcFormula = sum("Sales Invoice Line"."Withholding Amount" where("Document No." = field("Document No."), Type = filter(<> "G/L Account")));
            AutoFormatType = 1;
        }
    }
}
