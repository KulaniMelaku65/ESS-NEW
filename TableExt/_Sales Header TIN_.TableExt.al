tableextension 51111 "Sales Header TIN" extends "Sales Header"
{
    // Filled in automatically from Customer."EORI Number" (captioned "TIN No." — see
    // TableExt\_Customer TIN Rename_.TableExt.al) when "Sell-to Customer No." is selected;
    // see codeunit 51108 "Sales Header TIN Sync". Named identically on Sales Invoice
    // Header (TableExt\_Sales Invoice Header TIN_.TableExt.al) so BC's own posting
    // routine (TransferFields, codeunit 80 "Sales-Post") carries it onto the posted
    // invoice automatically — no extra posting code needed.
    fields
    {
        field(51100; "Customer TIN No."; Text[40])
        {
            Caption = 'TIN No.';
            DataClassification = CustomerContent;
        }
        field(51101; "E-Receipt Attempt No."; Integer)
        {
            Caption = 'E-Receipt Attempt No.';
            // Only incremented when MoR actually REFUSES a send (400/404/409/422/
            // REJECTED — see codeunit 51105's StartNewAttempt), baked into clientReference
            // as "<No.>-<attempt>". A plain retry after a timeout/5xx/still-pending result
            // reuses the SAME attempt number and reference: the middleware treats a retry
            // with an identical body under the same clientReference as safely idempotent,
            // and only rejects a clientReference reused with a DIFFERENT body (409) — which
            // only happens after a genuine refusal changes what gets sent.
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51102; "E-Receipt Counter"; Integer)
        {
            Caption = 'E-Receipt Counter';
            // The MoR receiptCounter value for this invoice, obtained ONCE (via "E-Receipt
            // Setup".GetNextReceiptCounter) and then reused on every attempt, even after a
            // refusal starts a new "E-Receipt Attempt No."/clientReference. MoR requires
            // this to increase by exactly one per receipt actually FILED — a rejected
            // invoice never files its receipt, so retrying it must not consume another
            // counter value, or the sequence MoR expects would have gaps.
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51103; "E-Receipt Invoice ID"; Text[50])
        {
            Caption = 'E-Receipt Invoice ID';
            // MoR's own invoice GUID (data.invoice.id), captured once the invoice is
            // REGISTERED (codeunit 51105's HandleResponse) so the "Open printable
            // receipt" action can build .../v1/invoices/{id}/print on its own, in a
            // separate click, without needing to re-run SendEReceipt's local variables.
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(51104; "Total Withholding Amount"; Decimal)
        {
            Caption = 'Total Withholding Amount';
            Editable = false;
            FieldClass = FlowField;
            // Excludes G/L Account lines — this business uses those to manually book
            // withholding in its existing flow, which "Apply Withholding" on the real
            // item/service lines now replaces; including them would double-count and,
            // more importantly, would disagree with codeunit 51105's own total (computed
            // from the exact same Item/Resource line set actually sent to MoR).
            CalcFormula = sum("Sales Line"."Withholding Amount" where("Document Type" = field("Document Type"), "Document No." = field("No."), Type = filter(<> "G/L Account")));
            AutoFormatType = 1;
        }
    }
}
