codeunit 51109 "Sales Line Withholding Sync"
{
    // Keeps "Withholding Amount" correct after Quantity/Unit Price/Line Discount %/etc.
    // change on a line AFTER withholding was already applied. TableExt "Sales Line
    // Withholding"'s own OnValidate triggers only recalculate when "Apply Withholding" or
    // "Withholding Code" themselves are touched — a real test caught the gap: a line was
    // marked for withholding before a 2% line discount was added, leaving "Withholding
    // Amount" stale (calculated against the pre-discount Amount) until MoR's own 422
    // totals-mismatch caught the drift. Sales Line's UpdateAmounts() (which Quantity/Unit
    // Price/Line Discount %'s OnValidate triggers all call) assigns "Line Amount"/Amount
    // directly rather than through Validate(), so a subscriber on Amount's own
    // OnAfterValidateEvent would never fire for this — OnAfterUpdateAmounts is the
    // dedicated integration event Sales Line itself raises for exactly this situation,
    // regardless of which field triggered the recalculation.
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterUpdateAmounts', '', false, false)]
    local procedure OnAfterUpdateAmounts(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
        if SalesLine."Apply Withholding" then
            SalesLine."Withholding Amount" := Round(SalesLine.Amount * SalesLine."Withholding %" / 100, 0.01);
    end;
}
