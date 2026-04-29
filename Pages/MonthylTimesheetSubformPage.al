// --- Page: Subform (The Grid) ---
page 51101 "Monthly Timesheet Subform"
{
    PageType = ListPart;
    SourceTable = "Monthly Timesheet Line";
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Work Date"; Rec."Work Date") { ApplicationArea = All; }
                //field("Job No."; Rec."Job No.") { ApplicationArea = All; }
                field("Description"; Rec."Activity") { ApplicationArea = All; }


                // Shift Breakdown
                field("Morning Hours"; Rec."Morning Hours") { ApplicationArea = All; }
                field("Afternoon Hours"; Rec."Afternoon Hours") { ApplicationArea = All; }
                field(Notes; Rec.Notes) { ApplicationArea = All; }

                // Final calculation for that specific row
                field("Daily Total"; Rec."Daily Total")
                {
                    ApplicationArea = All;
                    Style = Strong; // Makes it stand out
                }
            }
        }
    }

}