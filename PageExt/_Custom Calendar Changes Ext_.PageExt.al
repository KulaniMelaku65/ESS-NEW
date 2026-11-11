pageextension 51131 "Custom Calendar Changes Ext" extends "Customized Calendar Changes"
{
    layout
    {
        addafter(Nonworking)
        {
            field("Is Half Day";Rec."Is Half Day")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether this day is a half working day. Employees taking leave on this day will be charged 0.5 days instead of 1.';
            }
        }
    }
}
