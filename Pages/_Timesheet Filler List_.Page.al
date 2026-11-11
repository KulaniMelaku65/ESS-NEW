page 51116 "Timesheet Filler List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Timesheet Filler";
    Caption = 'Timesheet Fillers';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Employee ID";Rec."Employee ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee ID.';
                }
                field("First Name";Rec."First Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the first name of the employee.';
                }
                field("Middle Name";Rec."Middle Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the middle name of the employee.';
                }
                field("Last Name";Rec."Last Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the last name of the employee.';
                }
                field("Employment Type";Rec."Employment Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the employment type of the employee.';
                }
            }
        }
    }
}
