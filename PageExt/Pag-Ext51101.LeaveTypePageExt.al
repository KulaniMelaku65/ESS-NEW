pageextension 51101 LeaveTypePageExt extends "Leave Types"
{
    actions
    {
        addlast(Processing)
        {
            action(DeleteRecord)
            {
                Caption = 'Delete';
                Image = Delete;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ConfirmLbl: Label 'Are you sure you want to delete %1?';
                begin
                    // Optional: Add your own validation
                    if Rec.Status = Rec.Status::Active then
                        Error('You cannot delete an active leave type.');

                    if Confirm(ConfirmLbl, false, Rec.Code) then begin
                        Rec.Delete(true);
                        Message('Deleted successfully.');
                    end;
                end;
            }
        }
    }
}
