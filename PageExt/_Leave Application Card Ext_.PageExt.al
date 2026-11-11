pageextension 51124 "Leave Application Card Ext" extends "Leave Application Card"
{
    layout
    {
        addlast(content)
        {
            part(LeaveApplicationDays;"Leave App Day Subform")
            {
                ApplicationArea = All;
                Caption = 'Selected Days';
                SubPageLink = "Leave No."=field("No.");
            }
        }
    }
}
