pageextension 51109 "Sales Invoice Page Ext" extends "Sales Invoice"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Customer TIN No."; Rec."Customer TIN No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer''s Tax Identification Number (TIN), filled in automatically from the customer card when the customer is selected.';
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            action(PrintEReceipt)
            {
                ApplicationArea = All;
                Caption = 'Print e-receipt';
                Image = PrintCover;
                ToolTip = 'Sends this invoice to the e-receipt service and, once MoR registers it, opens MoR''s own printable receipt page in the browser.';

                trigger OnAction()
                var
                    EReceiptApi: Codeunit "Sales E-Receipt API";
                begin
                    EReceiptApi.SendEReceipt(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenPrintableReceipt)
            {
                ApplicationArea = All;
                Caption = 'Open printable receipt';
                Image = Print;
                ToolTip = 'Opens MoR''s own rendered receipt page in the browser, for viewing or printing directly from MoR. Requires "Print e-receipt" to have already registered this invoice at least once.';

                trigger OnAction()
                var
                    EReceiptApi: Codeunit "Sales E-Receipt API";
                begin
                    EReceiptApi.OpenPrintableReceipt(Rec);
                end;
            }
        }
    }
}
