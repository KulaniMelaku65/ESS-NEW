pageextension 51106 "sales&ReceivableTSPageExt" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(Content)
        {
            group(TimesheetWorkflowGroup)
            {
                Caption = 'Timesheet Workflow';

                field("Timesheet workflow group";Rec."Timesheet workflow group code")
                {
                    ApplicationArea = All;
                }
                field("Timesheet Final Approver No.";Rec."Timesheet Final Approver No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The employee who gives final sign-off on timesheets, after the employee''s own supervisor has approved. Enter their Employee No. directly — no BC user account is required.';
                }
            }
        }
    }
}
