pageextension 51107 NewEmployeePageExt extends "New Employee Card"
{
    layout
    {
        addafter("Gender")
        {
            field("Fayda Number";Rec."Fayda No.")
            {
                ApplicationArea = All;
                Visible = true;
            }
        }
        addafter("Shortcut Dimension 8 Code")
        {
            field("Agent";Rec."Agent")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Indicates whether the employee is an agent.';
            }
            field("Employee Location";Rec."Employee Location")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Specifies the location of the employee.';
            }
            field("Annual Leave Entitlement";Rec."Annual Leave Entitlement")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Total annual leave days for this employee. Must be filled in before this employee can be sent for approval.';
            }
        }
    }
    actions
    {
        addafter("Q&ualifications")
        {
            action("WorkExpereince")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Work Experience';
                Image = Certificate;
                Promoted = true;
                PromotedCategory = Category5;
                RunObject = Page "ESS Work Experience";
                RunPageLink = "Employee No."=FIELD("No.");
                ToolTip = 'Open the list of work experience records for the employee.';
            }
        }
    }
}
