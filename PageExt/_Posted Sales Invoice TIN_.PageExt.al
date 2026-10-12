pageextension 51111 "Posted Sales Invoice TIN" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Customer TIN No."; Rec."Customer TIN No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer''s Tax Identification Number (TIN) at the time this invoice was posted.';
            }
        }
    }
}
