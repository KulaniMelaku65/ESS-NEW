page 51121 "Withholding Setup"
{
    ApplicationArea = All;
    Caption = 'Withholding Setup';
    PageType = List;
    SourceTable = "Withholding Setup";
    UsageCategory = Administration;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the withholding code, selected on a Sales Line to apply this rate.';
                }
                field("Withholding %"; Rec."Withholding %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage withheld, applied to the line''s pre-tax amount.';
                }
                field("Sales Invoice"; Rec."Sales Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this code can be selected on a Sales Invoice line.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L account withholding is posted against for this code.';
                }
            }
        }
    }
}
