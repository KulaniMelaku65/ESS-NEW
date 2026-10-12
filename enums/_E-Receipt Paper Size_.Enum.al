enum 51101 "E-Receipt Paper Size"
{
    Extensible = false;
    // Query values the e-sign doc documents for .../v1/invoices/{id}/print?paper=<value>:
    // a4, 80 (80mm thermal), 58 (58mm thermal) — not "80mm"/"58mm" as literal values.

    value(0; A4)
    {
        Caption = 'A4';
    }
    value(1; Mm80)
    {
        Caption = '80mm (thermal)';
    }
    value(2; Mm58)
    {
        Caption = '58mm (thermal)';
    }
}
