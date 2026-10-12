tableextension 51109 "Customer TIN Rename" extends Customer
{
    // Relabels the standard "EORI Number" field (Customer, field 93) as "TIN No." — this
    // org has no use for the EU customs EORI concept, and reuses that field to hold the
    // customer's Ethiopian Tax Identification Number instead. Only the Caption changes;
    // the underlying field name/number/data are untouched, so existing data and any
    // standard code referencing "EORI Number" keep working. The Customer Card page's own
    // field control has no Caption override of its own, so it picks this up automatically
    // (see PageExt\_Customer Card TIN_.PageExt.al for the matching ToolTip fix).
    fields
    {
        modify("EORI Number")
        {
            Caption = 'TIN No.';
        }
    }
}
