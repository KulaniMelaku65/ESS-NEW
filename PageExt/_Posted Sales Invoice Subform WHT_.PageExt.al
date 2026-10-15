pageextension 51113 "Posted Sales Inv Subform WHT" extends "Posted Sales Invoice Subform"
{
    layout
    {
        addafter("Line Amount")
        {
            field("Apply Withholding"; Rec."Apply Withholding")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether withholding was applied to this line.';
            }
            field("Withholding Code"; Rec."Withholding Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding code that was applied to this line.';
            }
            field("Withholding %"; Rec."Withholding %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding percentage that was applied.';
            }
            field("Withholding Amount"; Rec."Withholding Amount")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding amount for this line.';
            }
        }
        addafter("Total VAT Amount")
        {
            field("Total Withholding Amount"; Rec."Total Withholding Amount")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the sum of all lines'' Withholding Amount (Item/Resource lines only, not G/L Account).';
            }
        }
    }
}
