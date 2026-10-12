page 51119 "E-Receipt Setup"
{
    ApplicationArea = All;
    Caption = 'E-Receipt Setup';
    PageType = Card;
    SourceTable = "E-Receipt Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL of the Kifiya e-sign middleware.';
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the X-API-Key issued by the middleware team. Kept only here, in the database — never in AL source.';
                }
                field("System Number"; Rec."System Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies this system''s MoR-assigned system number (registered under Kifiya''s TIN).';
                }
                field("System Type"; Rec."System Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies this system''s MoR system type: POS, MAN, CRM, EFD or SYS.';
                }
                field("Next Receipt Counter"; Rec."Next Receipt Counter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the receipt counter to use on the next e-receipt sent — advances by one automatically after each send. Only change this if the middleware team tells you to start from a different number.';
                }
                field("Paper Size"; Rec."Paper Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the paper size used when fetching or opening the printable receipt page from MoR.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInsert();
    end;
}
