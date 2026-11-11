page 51133 "Bus Operator Cash Receipts"
{
    // Read-only audit view of every row pushed in via "Bus Operator Cash
    // Receipt API" (page 51132) and what happened to it — Success and the
    // journal line(s) created, or a reason it couldn't be (customer not
    // found, bad bank account, etc.). "Open Cash Receipt Journal" jumps
    // straight to the batch these lines land in for review and posting.
    ApplicationArea = All;
    Caption = 'Bus Operator Cash Receipts';
    PageType = List;
    SourceTable = "Bus Operator Cash Receipt";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Bus Operator";Rec."Bus Operator")
                {
                    ApplicationArea = All;
                }
                field("Report Date";Rec."Report Date")
                {
                    ApplicationArea = All;
                }
                field("Vendor No.";Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Total Collected";Rec."Total Collected")
                {
                    ApplicationArea = All;
                }
                field("Bank Account No.";Rec."Bank Account No.")
                {
                    ApplicationArea = All;
                }
                field("Inter-Association Amount";Rec."Inter-Association Amount")
                {
                    ApplicationArea = All;
                }
                field("Inter-Association Bank Account No.";Rec."Inter-Association Bank Account No.")
                {
                    ApplicationArea = All;
                }
                field(Result;Rec.Result)
                {
                    ApplicationArea = All;
                    StyleExpr = ResultStyle;
                }
                field(Details;Rec.Details)
                {
                    ApplicationArea = All;
                }
                field("Journal Line No.";Rec."Journal Line No.")
                {
                    ApplicationArea = All;
                }
                field("Inter-Association Line No.";Rec."Inter-Association Line No.")
                {
                    ApplicationArea = All;
                }
                field("Created At";Rec."Created At")
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
            action(OpenJournal)
            {
                ApplicationArea = All;
                Caption = 'Open Cash Receipt Journal';
                Image = OpenJournal;
                ToolTip = 'Opens the Cash Receipt Journal batch these lines were created in, for review and posting.';

                trigger OnAction()
                var
                    Mgmt: Codeunit "Bus Operator Cash Receipt Mgmt";
                    GenJnlLine: Record "Gen. Journal Line";
                begin
                    GenJnlLine.SetRange("Journal Template Name", Mgmt.JournalTemplateName());
                    GenJnlLine.SetRange("Journal Batch Name", Mgmt.JournalBatchName());
                    PAGE.Run(PAGE::"Cash Receipt Journal", GenJnlLine);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Result = Rec.Result::Success then
            ResultStyle := 'Favorable'
        else
            if Rec.Result = Rec.Result::" " then
                ResultStyle := 'Standard'
            else
                ResultStyle := 'Unfavorable';
    end;

    var
        ResultStyle: Text;
}
