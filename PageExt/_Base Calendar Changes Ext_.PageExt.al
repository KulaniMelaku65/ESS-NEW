pageextension 51119 "Base Calendar Changes Ext" extends "Base Calendar Changes"
{
    layout
    {
        addafter(Nonworking)
        {
            field("Is Half Day";Rec."Is Half Day")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this day is a half working day.';
            }
        }
    }
}
