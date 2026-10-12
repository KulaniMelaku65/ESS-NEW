tableextension 51112 "Sales Invoice Header TIN" extends "Sales Invoice Header"
{
    // Same field, same name, as TableExt\_Sales Header TIN_.TableExt.al on "Sales
    // Header" — BC's posting routine (SalesInvHeader.TransferFields(SalesHeader), inside
    // codeunit 80 "Sales-Post") copies any same-named custom field across automatically,
    // so this one needs no posting-event code of its own; it just has to exist.
    fields
    {
        field(51100; "Customer TIN No."; Text[40])
        {
            Caption = 'TIN No.';
            DataClassification = CustomerContent;
        }
    }
}
