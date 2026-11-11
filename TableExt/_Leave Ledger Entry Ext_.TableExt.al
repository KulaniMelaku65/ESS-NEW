tableextension 51147 "Leave Ledger Entry Ext" extends "Leave Ledger Entry"
{
    fields
    {
        field(51100;"Leave Entitlement";Decimal)
        {
            // The effective annual entitlement (base + seniority bonus)
            // used to compute this entry's "No. of Days", for Leave
            // Allocation entries created by codeunit "Annual Leave
            // Accrual". Blank for entries from any other source (Leave
            // Application, Leave Recall, manually created, etc.) — it's
            // not meaningful for those.
            Caption = 'Leave Entitlement';
            DecimalPlaces = 0 : 2;
        }
    }
}
