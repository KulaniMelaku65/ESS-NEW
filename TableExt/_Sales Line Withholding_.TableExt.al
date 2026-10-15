tableextension 51105 "Sales Line Withholding" extends "Sales Line"
{
    // "Apply Withholding" and "Withholding Code" can be set in either order — whichever is
    // validated second triggers the actual Amount calc, since the other one's OnValidate
    // only recalculates when both are already present. "Withholding %"/"Withholding
    // Amount" are auto-calculated only (Editable = false), not manually overridable.
    fields
    {
        field(51100; "Apply Withholding"; Boolean)
        {
            Caption = 'Apply Withholding';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not "Apply Withholding" then begin
                    "Withholding Code" := '';
                    "Withholding %" := 0;
                    "Withholding Amount" := 0;
                end else
                    RecalcWithholdingAmount();
            end;
        }
        field(51101; "Withholding Code"; Code[20])
        {
            Caption = 'Withholding Code';
            DataClassification = CustomerContent;
            TableRelation = "Withholding Setup".Code where("Sales Invoice" = const(true));

            trigger OnValidate()
            var
                WithholdingSetup: Record "Withholding Setup";
            begin
                if "Withholding Code" = '' then begin
                    "Withholding %" := 0;
                    "Withholding Amount" := 0;
                    exit;
                end;
                if WithholdingSetup.Get("Withholding Code") then
                    "Withholding %" := WithholdingSetup."Withholding %";
                if "Apply Withholding" then
                    RecalcWithholdingAmount();
            end;
        }
        field(51102; "Withholding %"; Decimal)
        {
            Caption = 'Withholding %';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51103; "Withholding Amount"; Decimal)
        {
            Caption = 'Withholding Amount';
            DataClassification = CustomerContent;
            Editable = false;
            AutoFormatType = 1;
        }
        field(51104; "Total Withholding Amount"; Decimal)
        {
            Caption = 'Total Withholding Amount';
            Editable = false;
            FieldClass = FlowField;
            // Self-referential: sums THIS SAME field across every sibling line on the
            // document, excluding G/L Account lines (consistent with codeunit 51105's own
            // total — see TableExt "Sales Header TIN"). Defined here, on Sales Line itself
            // rather than only on Sales Header, specifically so it can be bound directly
            // as Rec.<field> inside the Sales Invoice Subform (whose SourceTable is Sales
            // Line, not Sales Header) — shown next to "Total VAT Amount" there.
            CalcFormula = sum("Sales Line"."Withholding Amount" where("Document Type" = field("Document Type"), "Document No." = field("Document No."), Type = filter(<> "G/L Account")));
            AutoFormatType = 1;
        }
    }

    // Withheld against the line's own pre-tax Amount (matches the integration guide's
    // /v1/receipts/withholding payload, which names that base "preTaxAmount").
    local procedure RecalcWithholdingAmount()
    begin
        "Withholding Amount" := Round(Amount * "Withholding %" / 100, 0.01);
    end;
}
