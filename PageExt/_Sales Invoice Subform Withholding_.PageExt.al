pageextension 51112 "Sales Invoice Subform WHT" extends "Sales Invoice Subform"
{
    layout
    {
        addafter("Line Amount")
        {
            field("Apply Withholding"; Rec."Apply Withholding")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether withholding applies to this line. Tick after choosing a Withholding Code (or before — either order recalculates the amount once both are set).';
            }
            field("Withholding Code"; Rec."Withholding Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding code to apply to this line.';
            }
            field("Withholding %"; Rec."Withholding %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding percentage, copied from the selected Withholding Code.';
            }
            field("Withholding Amount"; Rec."Withholding Amount")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the withholding amount, calculated as this line''s pre-tax Amount times Withholding %.';
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
