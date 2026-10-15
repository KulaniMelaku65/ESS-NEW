page 51122 "Excise Setup"
{
    ApplicationArea = All;
    Caption = 'Excise Setup';
    PageType = List;
    SourceTable = "Excise Setup";
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
                    ToolTip = 'Specifies the excise code, selected on an Item to apply this rate.';
                }
                field("Excise %"; Rec."Excise %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage charged, applied to the line''s pre-discount, pre-VAT amount.';
                }
            }
        }
    }
}
