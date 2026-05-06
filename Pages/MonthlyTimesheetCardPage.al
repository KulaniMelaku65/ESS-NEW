// --- Page: Card (The Main UI) ---
page 51100 "Monthly Timesheet Card"
{
    PageType = Document;
    SourceTable = "Monthly Timesheet Header";
    Caption = 'Monthly Timesheet';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = PageEditable;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Month"; Rec."Month") { ApplicationArea = All; }
                field("Year"; Rec."Year") { ApplicationArea = All; }
                field("Status"; Rec."Status") { ApplicationArea = All; }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total hours recorded for this month.';
                    Style = Strong; // Makes the number bold
                }
            }
            part(Lines; "Monthly Timesheet Subform")
            {
                Editable = PageEditable;
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
                Enabled = PageEditable;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Submit)
            {
                Caption = 'Submit for Approval';
                Image = SendApprovalRequest;
                ApplicationArea = All;

                trigger OnAction()
                var
                    TSMgt: Codeunit "Timesheet Mgt.";
                begin
                    TSMgt.SubmitTimesheet(Rec);
                end;
            }
            /*action(CancelApproval)
            {
                Caption = 'Cancel Approval Request';
                Image = CancelApprovalRequest;
                ApplicationArea = All;
                Enabled = Rec.Status = Rec.Status::"Pending Approval"; // Only shows if pending

                trigger OnAction()
                var
                    TSMgt: Codeunit "Timesheet Workflow";
                begin
                    TSMgt.CancelTimesheet(Rec);
                end;
            }*/
        }
    }

    var
        PageEditable: Boolean;

    trigger OnAfterGetRecord()
    begin
        // The page is only editable if the status is Open
        PageEditable := Rec.Status = Rec.Status::Open;
    end;

}