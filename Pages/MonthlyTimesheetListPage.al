page 51103 "Monthly Timesheet List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists; // Makes it searchable in the Tell Me (Alt+Q) menu
    SourceTable = "Monthly Timesheet Header";
    CardPageId = "Monthly Timesheet Card"; // Links the List to the Card for double-click opening
    Editable = false; // Usually, lists are read-only; editing happens in the Card
    Caption = 'Monthly Timesheets';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Month"; Rec."Month") { ApplicationArea = All; }
                field("Year"; Rec."Year") { ApplicationArea = All; }
                field("Status"; Rec."Status") { ApplicationArea = All; }

                // This will show the total calculated from the subform lines
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                }
            }
        }
    }

    // Filter the list so users only see their own timesheets
    trigger OnOpenPage()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then begin
            // Assuming Employee No. is linked to User ID or you want to restrict access
            // Rec.SetRange("Employee No.", UserSetup."Employee No."); 
        end;
    end;


}