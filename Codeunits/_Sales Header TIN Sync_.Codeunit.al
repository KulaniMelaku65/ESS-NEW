codeunit 51108 "Sales Header TIN Sync"
{
    // Pulls Customer."EORI Number" (captioned "TIN No." — see TableExt\_Customer TIN
    // Rename_.TableExt.al) onto Sales Header."Customer TIN No." the instant a customer is
    // selected on the Sales Invoice, same as how Name/Address auto-fill. Field-level
    // OnAfterValidateEvent subscriptions fire regardless of which page or channel (API,
    // import) validated the field, so this covers all of them, not just the Sales Invoice
    // page's own OnValidate.

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure OnAfterValidateSellToCustomerNo(var Rec: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(Rec."Sell-to Customer No.") then
            Rec."Customer TIN No." := Customer."EORI Number"
        else
            Rec."Customer TIN No." := '';
    end;
}
