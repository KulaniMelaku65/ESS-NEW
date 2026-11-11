page 51113 "ESS Work Experience"
{
    Caption = 'Work Experience';
    PageType = List;
    SourceTable = "ESS Work Experience";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee number.';
                }
                field("Company Name";Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company where the employee worked.';
                }
                field("Position";Rec."Position")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the position or job title held at the company.';
                }
                field("From Date";Rec."From Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start date of the employment.';
                }
                field("To Date";Rec."To Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end date of the employment.';
                }
                field("Description";Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies additional notes about the work experience.';
                }
            }
        }
    }
}
