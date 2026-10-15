pageextension 51114 "Item Card Excise" extends "Item Card"
{
    layout
    {
        addafter("Item Category Code")
        {
            field("Excise Code"; Rec."Excise Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the excise rate applied when this item is sold, per Excise Setup. Blank means not excisable.';
            }
        }
    }
}
