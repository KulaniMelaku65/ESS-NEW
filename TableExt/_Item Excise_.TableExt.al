tableextension 51107 "Item Excise" extends Item
{
    fields
    {
        field(51100; "Excise Code"; Code[20])
        {
            Caption = 'Excise Code';
            TableRelation = "Excise Setup";
            // Blank = not excisable. Looked up live by codeunit 51105 "Sales E-Receipt
            // API" at send-time (not copied onto Sales Line) so there's nothing to go
            // stale if the rate or the item's code changes after a line was entered.
        }
    }
}
