pageextension 51103 HRSetupPageExt extends "Human Resources Setup"
{
    layout
    {
        addafter("Last pay")
        {
            field("Timesheet Nos";Rec."Timesheet No. Series")
            {
                ApplicationArea = All;
            }
            field("Weekly Contractual Hours";Rec."Weekly Contractual Hours")
            {
                ApplicationArea = All;
                ToolTip = 'Weekly hours benchmark shown on the automated attendance review email. Leave blank to use the default (48).';
            }
        }
    }
}
