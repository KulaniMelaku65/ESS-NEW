codeunit 51149 "Suppress Fanisi Leave Alloc."
{
    // Fanisi HR's own Employee.ActivateEmployee() -> "HR Management".
    // AllocateLeaveNewEmployees() automatically grants a full year's
    // Annual Leave (Leave Type's company-wide "No. of Days") as a lump sum
    // the instant an employee is activated through Fanisi's own flow —
    // entirely separate from, and unaware of, our own per-employee
    // "Annual Leave Entitlement" field and monthly "Annual Leave Accrual"
    // codeunit (51145). Left alone, both would credit annual leave,
    // double-counting it.
    //
    // Fanisi's own code can't be edited (separate installed app), so this
    // deletes that specific entry the instant it's inserted, matched on
    // the exact shape only that one procedure produces: Transaction Type
    // = Leave Allocation, Description = 'Allocation on Hire' (its
    // hardcoded literal), Document No. = Employee No. (also hardcoded
    // there), and Leave Type = whichever type is flagged Is Annual.
    // Nothing this extension writes matches all four, so this can't catch
    // anything of ours (our accrual entries use Document No. "ACCR-YYYYMM"
    // and our new-hire grants use "INIT-<LeaveType>", neither ever equal
    // to the Employee No.).

    [EventSubscriber(ObjectType::Table, Database::"Leave Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnLeaveLedgerEntryInserted(var Rec: Record "Leave Ledger Entry"; RunTrigger: Boolean)
    var
        LeaveType: Record "Leave Type";
    begin
        if not RunTrigger then
            exit;
        if Rec."Transaction Type" <> Rec."Transaction Type"::"Leave Allocation" then
            exit;
        if Rec.Description <> 'Allocation on Hire' then
            exit;
        if Rec."Document No." <> Rec."Employee No." then
            exit;
        if Rec."Leave Type" <> LeaveType.GetAnnualLeave() then
            exit;

        Rec.Delete(false);
    end;
}
