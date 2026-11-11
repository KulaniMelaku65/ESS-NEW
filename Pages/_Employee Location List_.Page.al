page 51112 "Employee Location List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Employee Location";
    Caption = 'Employee Locations';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code";Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee location code.';
                }
                field("Description";Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee location description.';
                }
            }
        }
    }
}
