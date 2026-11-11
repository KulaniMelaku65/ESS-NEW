pageextension 51108 "Employee List Ext" extends "Employee List"
{
    layout
    {
        addlast(Control1)
        {
            field("Annual Leave Entitlement";Rec."Annual Leave Entitlement")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Total annual leave days for this employee (base, before any seniority bonus). Once set, and while Employee Status is Active, this accrues automatically every month.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(RunAnnualLeaveAccrualForMonth)
            {
                ApplicationArea = All;
                Caption = 'Run Annual Leave Accrual for Month...';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Manually runs the monthly annual leave accrual for a specific month, for every Active employee with an entitlement filled in. Safe to run more than once — anyone already credited for that month is skipped. Use this to catch up a month that was missed (e.g. before the automated monthly job was set up).';

                trigger OnAction()
                var
                    Accrual: Codeunit "Annual Leave Accrual";
                    SelectMonthDialog: Page "Select Month Dialog";
                    TargetMonth: Date;
                begin
                    if SelectMonthDialog.RunModal() <> Action::OK then
                        exit;
                    TargetMonth := SelectMonthDialog.GetTargetDate();
                    if TargetMonth = 0D then
                        exit;
                    if not Confirm('Run annual leave accrual for %1 %2, for every Active employee with an entitlement filled in? Anyone already credited for that month is skipped automatically. Continue?', false, Format(TargetMonth, 0, '<Month Text>'), Date2DMY(TargetMonth, 3)) then
                        exit;
                    Accrual.AccrueForMonth(TargetMonth);
                    Message('Annual leave accrual complete for %1 %2.', Format(TargetMonth, 0, '<Month Text>'), Date2DMY(TargetMonth, 3));
                end;
            }
            action(UndoAnnualLeaveAccrualForMonth)
            {
                ApplicationArea = All;
                Caption = 'Undo Annual Leave Accrual for Month (Selected Employee)...';
                Image = Cancel;
                ToolTip = 'Removes this system''s own annual leave accrual entry for the selected employee and a chosen month, if one exists — e.g. to fix a month that turned out to already be covered by the old manual process. Never touches manual entries or anything from another source, only entries this system created itself.';

                trigger OnAction()
                var
                    Accrual: Codeunit "Annual Leave Accrual";
                    SelectMonthDialog: Page "Select Month Dialog";
                    TargetMonth: Date;
                begin
                    if SelectMonthDialog.RunModal() <> Action::OK then
                        exit;
                    TargetMonth := SelectMonthDialog.GetTargetDate();
                    if TargetMonth = 0D then
                        exit;
                    if not Confirm('Remove this system''s own annual leave accrual entry for %1 for %2 %3, if one exists? This cannot be undone.', false, Rec.FullName(), Format(TargetMonth, 0, '<Month Text>'), Date2DMY(TargetMonth, 3)) then
                        exit;
                    if Accrual.UndoAccrualForMonth(Rec."No.", TargetMonth) then
                        Message('Removed the accrual entry for %1 for %2 %3.', Rec.FullName(), Format(TargetMonth, 0, '<Month Text>'), Date2DMY(TargetMonth, 3))
                    else
                        Message('No accrual entry from this system was found for %1 for %2 %3 — nothing to remove.', Rec.FullName(), Format(TargetMonth, 0, '<Month Text>'), Date2DMY(TargetMonth, 3));
                end;
            }
            action(GrantOtherLeaveTypesExisting)
            {
                ApplicationArea = All;
                Caption = 'Grant Other Leave Types (Existing Employees)...';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Pick which non-Annual leave types to grant, then grants every Active employee that type''s entitlement for the current leave period — using each type''s own configured entitlement (Fixed No. of Days, or by Employee Level) and Gender restriction. Anyone already granted a given leave type for the current leave period is skipped automatically, so this is safe to run more than once, including in a new leave period to top everyone up again.';

                trigger OnAction()
                var
                    NewHireAllocation: Codeunit "New Hire Leave Allocation";
                    SelectLeaveTypesDialog: Page "Select Leave Types Dialog";
                    SelectedLeaveType: Record "Leave Type";
                begin
                    SelectLeaveTypesDialog.RunModal();
                    if SelectLeaveTypesDialog.WasCancelled() then
                        exit;

                    SelectLeaveTypesDialog.GetSelectedLeaveTypes(SelectedLeaveType);
                    if SelectedLeaveType.IsEmpty() then begin
                        Message('No leave types selected — nothing to do.');
                        exit;
                    end;

                    if not Confirm('Grant every Active employee the selected leave type(s) for the current leave period, based on the Leave Type table setup? Anyone already granted a given type for this period is skipped automatically. Continue?', false) then
                        exit;

                    NewHireAllocation.GrantSelectedLeaveTypesForAllActiveEmployees(SelectedLeaveType);
                    Message('Done. Existing employees have been brought up to date on the selected leave types for the current leave period.');
                end;
            }
            action(GrantLeaveTypeSelectedEmployee)
            {
                ApplicationArea = All;
                Caption = 'Grant Leave Type (Selected Employee)...';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Grants the highlighted employee a specific leave type for the current leave period, in whatever amount you enter — defaults to that type''s configured entitlement, but you can change it. For one-off exceptions; the bulk action above is for granting everyone at the standard amount.';

                trigger OnAction()
                var
                    NewHireAllocation: Codeunit "New Hire Leave Allocation";
                    GrantLeaveTypeDialog: Page "Grant Leave Type Dialog";
                    LeaveType: Record "Leave Type";
                    ExistingEntry: Record "Leave Ledger Entry";
                    HRMgt: Codeunit "HR Management";
                    LeaveTypeCode: Code[20];
                    Days: Decimal;
                begin
                    GrantLeaveTypeDialog.SetEmployee(Rec);
                    if GrantLeaveTypeDialog.RunModal() <> Action::OK then
                        exit;
                    GrantLeaveTypeDialog.GetResult(LeaveTypeCode, Days);

                    if LeaveTypeCode = '' then begin
                        Message('No leave type selected — nothing to do.');
                        exit;
                    end;
                    if not LeaveType.Get(LeaveTypeCode) then begin
                        Message('Leave type %1 was not found.', LeaveTypeCode);
                        exit;
                    end;
                    if Days <= 0 then begin
                        Message('Enter a number of days greater than zero.');
                        exit;
                    end;

                    if (LeaveType.Gender <> LeaveType.Gender::" ") and (LeaveType.Gender <> Rec.Gender) then
                        if not Confirm('%1 is normally restricted to %2, but %3 is %4. Grant it anyway?', false, LeaveType.Code, LeaveType.Gender, Rec.FullName(), Rec.Gender) then
                            exit;

                    ExistingEntry.SetRange("Employee No.", Rec."No.");
                    ExistingEntry.SetRange("Transaction Type", ExistingEntry."Transaction Type"::"Leave Allocation");
                    ExistingEntry.SetRange("Leave Type", LeaveType.Code);
                    ExistingEntry.SetRange("Leave Period", HRMgt.GetCurrentLeavePeriod());
                    if ExistingEntry.FindFirst() then
                        if not Confirm('%1 already has %2 day(s) of %3 allocated for this leave period. Grant %4 additional day(s) anyway?', false, Rec.FullName(), ExistingEntry."No. of Days", LeaveType.Code, Days) then
                            exit;

                    NewHireAllocation.GrantSpecificAmount(Rec, LeaveType.Code, Days);
                    Message('Granted %1 day(s) of %2 to %3.', Days, LeaveType.Code, Rec.FullName());
                end;
            }
        }
    }
}
