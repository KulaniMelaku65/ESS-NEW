pageextension 51148 "Leave Ledger Entries Ext" extends "Leave Ledger Entries"
{
    layout
    {
        addafter("No. of Days")
        {
            field("Leave Entitlement";Rec."Leave Entitlement")
            {
                ApplicationArea = Basic;
                ToolTip = 'The effective annual entitlement (base + seniority bonus) used to compute this entry, for monthly annual leave accrual entries. Blank for other entry types.';
            }
        }
    }
}
