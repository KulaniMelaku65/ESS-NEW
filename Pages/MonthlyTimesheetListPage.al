page 51103 "Monthly Timesheet List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists; // Makes it searchable in the Tell Me (Alt+Q) menu
    SourceTable = "Monthly Timesheet Header";
    CardPageId = "Monthly Timesheet Card"; // Links the List to the Card for double-click opening
    Editable = false; // Usually, lists are read-only; editing happens in the Card
    Caption = 'Monthly Timesheets';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No.";Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = All;
                }
                field("Employee Name";Rec."Employee Name")
                {
                    ApplicationArea = All;
                }
                field("Month";Rec."Month")
                {
                    ApplicationArea = All;
                }
                field("Year";Rec."Year")
                {
                    ApplicationArea = All;
                }
                field("Status";Rec."Status")
                {
                    ApplicationArea = All;
                }
                // This will show the total calculated from the subform lines
                field("Total Hours";Rec."Total Hours")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RecalculateEmployeeNames)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Employee Names';
                Image = Refresh;
                ToolTip = 'One-time repair: fills in Employee Name for every existing timesheet header. Needed because rows written before this field existed never had it computed — new/edited timesheets fill it in automatically going forward.';

                trigger OnAction()
                var
                    TimesheetHeader: Record "Monthly Timesheet Header";
                begin
                    if TimesheetHeader.FindSet(true) then
                        repeat
                            TimesheetHeader.Modify(true);
                        until TimesheetHeader.Next() = 0;
                    CurrPage.Update(false);
                    Message('Employee Name recalculated for all timesheet headers.');
                end;
            }
            action(FixOrphanedApprovals)
            {
                ApplicationArea = All;
                Caption = 'Fix Stuck Timesheet Approvals';
                Image = Approve;
                ToolTip = 'One-time repair: finds timesheets that a since-fixed bug marked Approved while the final approver''s entry was left behind un-activated, and puts each one back into Pending Approval with that approver''s entry reopened. Safe to run more than once — only touches timesheets still in that exact broken shape.';

                trigger OnAction()
                var
                    Approvals: Codeunit "Approvals Timesheet Mgmt.";
                    FixedCount: Integer;
                begin
                    if not Confirm('Scan every Approved timesheet for one still stuck waiting on an un-activated approver, and fix each one found (back to Pending Approval, that approver notified)? Continue?', false) then
                        exit;
                    FixedCount := Approvals.FixOrphanedApprovals();
                    CurrPage.Update(false);
                    if FixedCount > 0 then
                        Message('Fixed %1 stuck timesheet(s) — each is back in Pending Approval and the missing approver has been notified.', FixedCount)
                    else
                        Message('No stuck timesheets found.');
                end;
            }
        }
    }

    // Filter the list so users only see their own timesheets
    trigger OnOpenPage()var UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId)then begin
        // Assuming Employee No. is linked to User ID or you want to restrict access
        // Rec.SetRange("Employee No.", UserSetup."Employee No.");
        end;
    end;
}
