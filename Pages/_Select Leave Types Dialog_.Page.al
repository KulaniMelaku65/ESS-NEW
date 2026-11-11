page 51137 "Select Leave Types Dialog"
{
    // Small picker used by "Employee List Ext" (page extension 51108) to
    // ask which non-Annual leave types to grant when running "Grant Other
    // Leave Types (Existing Employees)". Check the rows you want (Ctrl+A
    // for all), then OK — Cancel or closing the page abandons the run.
    PageType = List;
    Caption = 'Select Leave Types to Grant';
    SourceTable = "Leave Type";
    SourceTableView = sorting(Code);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("No. of Days"; Rec."No. of Days")
                {
                    ApplicationArea = All;
                }
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = All;
                }
                field("Allocation Type"; Rec."Allocation Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OK)
            {
                ApplicationArea = All;
                Caption = 'OK';
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    UserCancelled := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Status, Rec.Status::Active);
        Rec.SetFilter("Is Annual", '%1', false);
    end;

    procedure WasCancelled(): Boolean
    begin
        exit(UserCancelled);
    end;

    // Sets filters on the caller's own Leave Type record so FindSet()/
    // IsEmpty() there reflect exactly the checked rows — same technique
    // as the "Delete Selected" action on the Leave Ledger Cleanup page.
    procedure GetSelectedLeaveTypes(var SelectedLeaveType: Record "Leave Type")
    begin
        CurrPage.SetSelectionFilter(SelectedLeaveType);
    end;

    var
        UserCancelled: Boolean;
}
