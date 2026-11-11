page 51123 "Leave App Day Subform"
{
    PageType = ListPart;
    SourceTable = "Leave Application Day";
    Caption = 'Selected Days';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Date;Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the specific date for the leave day.';
                }
                field("Day Name";Rec."Day Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the day of the week.';
                }
                field("Is Half Day";Rec."Is Half Day")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Automatically checked if this day is marked as a half working day in the company calendar.';
                }
                field("No. of Days";Rec."No. of Days")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows 0.5 for a half day or 1.0 for a full day.';
                }
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)begin
        Rec."Leave No.":=Rec.GetFilter("Leave No.");
    end;
}
