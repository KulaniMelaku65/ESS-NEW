pageextension 51133 "FIN Payment Header Ext" extends "FIN-Payment Header"
{
    // "Reference No." is Editable = false on the base "FINPaymentsHeader"
    // table (Fanisi_Finance), so every page showing it is read-only unless
    // it explicitly overrides that — this page didn't (the override was
    // present but commented out). Overriding here, not on the table, since
    // a table extension can't change an existing field's properties.
    layout
    {
        modify("Reference No.")
        {
            Editable = true;
        }
    }

    actions
    {
        // The "Source Document" action (View) calls the base table's
        // OpenSource(), which — for a Last Payment-originated voucher —
        // looks up "Last Payment Employee" by "No." = Rec."Reference No.".
        // At least one of the voucher-creation code paths in "Last Payment
        // Employee" never sets "Reference No." on the voucher (it's
        // commented out there), so that lookup silently finds nothing for
        // vouchers created that way, and the button does nothing.
        //
        // Can't edit Fanisi's own OpenSource() (separate installed app),
        // so this runs first: if the forward lookup the base code is about
        // to do would already succeed, do nothing (let the base logic
        // handle it, avoiding opening the page twice). Otherwise, fall
        // back to the reverse lookup "View Voucher" already uses
        // successfully — Last Payment Employee."Payment Voucher No." =
        // this voucher's own "No." — which doesn't depend on "Reference
        // No." having been set at all.
        modify(View)
        {
            trigger OnBeforeAction()
            var
                LastPaymentEmployee: Record "Last Payment Employee";
            begin
                LastPaymentEmployee.SetRange("No.", Rec."Reference No.");
                if not LastPaymentEmployee.IsEmpty() then
                    exit; // base OpenSource will already find and open this correctly

                LastPaymentEmployee.Reset();
                LastPaymentEmployee.SetRange("Payment Voucher No.", Rec."No.");
                if LastPaymentEmployee.FindFirst() then
                    Page.Run(Page::"Last Payment Header", LastPaymentEmployee);
            end;
        }
    }
}
