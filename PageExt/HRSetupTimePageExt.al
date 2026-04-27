pageextension 51103 HRSetupPageExt extends "Human Resources Setup"
{
    layout
    {
        addafter("Last pay")
        {
            field("Timesheet Nos"; Rec."Timesheet No. Series")
            {
                ApplicationArea = All;
            }
        }
    }
}
