codeunit 51146 "New Hire Leave Allocation"
{
    // When an employee becomes Active (a new hire, or a later status
    // change into Active), automatically grants their entitlement for
    // every OTHER active Leave Type — i.e. every Leave Type except the one
    // flagged "Is Annual". Annual Leave is deliberately excluded here: it's
    // handled separately, monthly, by codeunit "Annual Leave Accrual"
    // using the employee's own Annual Leave Entitlement field (table
    // extension 51101, field 51106), since annual entitlement varies per
    // employee. Every other leave type's entitlement already comes from
    // the Leave Type table itself (Fixed "No. of Days", or "Based on
    // Table" by Employee Level via LeaveType.GetNoOfDays), so no new
    // per-employee field is needed for those.
    //
    // One Leave Ledger Entry per employee+leave type+leave period
    // (current year). Idempotent on that combination (Employee No. +
    // Transaction Type = Leave Allocation + Leave Type + Leave Period),
    // checked directly on those fields rather than on Document No. — so
    // it also catches an allocation that came from somewhere else, not
    // just this codeunit's own past runs. Safe to fire more than once per
    // year (both an insert straight into Active, and a later modify into
    // Active, subscribe below) without double-granting, and safe to run
    // again in a new leave period — that's a genuine fresh grant, not a
    // duplicate.
    //
    // Document No. ("INIT-<Entry No.>") only exists to satisfy the
    // table's own Employee No. + Document No. unique key; it's not what
    // decides "already granted" any more, so it doesn't need to encode
    // the leave type or year and can't collide via Code[20] truncation
    // the way "INIT-<LeaveType>" could.

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnEmployeeInserted(var Rec: Record Employee; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;
        if Rec."Employee Status" = Rec."Employee Status"::Active then
            AllocateInitialLeaveTypes(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnEmployeeModified(var Rec: Record Employee; var xRec: Record Employee; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;
        if (Rec."Employee Status" = Rec."Employee Status"::Active) and (xRec."Employee Status" <> xRec."Employee Status"::Active) then
            AllocateInitialLeaveTypes(Rec);
    end;

    // Automatic path: every non-Annual active leave type, for one employee.
    local procedure AllocateInitialLeaveTypes(Employee: Record Employee)
    var
        AllLeaveTypes: Record "Leave Type";
    begin
        AllLeaveTypes.SetRange(Status, AllLeaveTypes.Status::Active);
        GrantSelectedLeaveTypes(Employee, AllLeaveTypes);
    end;

    // Manual bulk catch-up, every non-Annual active leave type — kept for
    // any caller that wants the old "grant everything" behavior in one
    // call. The "Grant Other Leave Types (Existing Employees)" action now
    // calls GrantSelectedLeaveTypesForAllActiveEmployees below instead, so
    // the HR admin can pick a subset.
    procedure AllocateForAllActiveEmployees()
    var
        AllLeaveTypes: Record "Leave Type";
    begin
        AllLeaveTypes.SetRange(Status, AllLeaveTypes.Status::Active);
        GrantSelectedLeaveTypesForAllActiveEmployees(AllLeaveTypes);
    end;

    // Bulk catch-up restricted to whichever leave types the caller has
    // already filtered LeaveTypeFilter down to (e.g. the HR admin's
    // selection from "Select Leave Types Dialog"). Runs the exact same
    // per-leave-type logic as the automatic path, so it's safe to run
    // against everyone: already-granted employee+leave type+leave period
    // combinations are skipped, only genuine gaps get a new entry.
    procedure GrantSelectedLeaveTypesForAllActiveEmployees(var LeaveTypeFilter: Record "Leave Type")
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Employee Status", Employee."Employee Status"::Active);
        if Employee.FindSet() then
            repeat
                GrantSelectedLeaveTypes(Employee, LeaveTypeFilter);
            until Employee.Next() = 0;
    end;

    local procedure GrantSelectedLeaveTypes(Employee: Record Employee; var LeaveTypeFilter: Record "Leave Type")
    var
        LeaveType: Record "Leave Type";
        HRMgt: Codeunit "HR Management";
        CurrentLeavePeriod: Code[20];
        AnnualLeaveCode: Code[20];
    begin
        CurrentLeavePeriod := HRMgt.GetCurrentLeavePeriod();
        AnnualLeaveCode := LeaveType.GetAnnualLeave();

        LeaveType.CopyFilters(LeaveTypeFilter);
        if LeaveType.FindSet() then
            repeat
                if LeaveType.Code <> AnnualLeaveCode then
                    GrantLeaveType(Employee, LeaveType, CurrentLeavePeriod);
            until LeaveType.Next() = 0;
    end;

    local procedure GrantLeaveType(Employee: Record Employee; LeaveType: Record "Leave Type"; LeavePeriod: Code[20])
    var
        LeaveLedgerEntry: Record "Leave Ledger Entry";
        Days: Decimal;
        NewEntryNo: Integer;
    begin
        if (LeaveType.Gender <> LeaveType.Gender::" ") and (LeaveType.Gender <> Employee.Gender) then
            exit;

        Employee.CalcFields("Employee Level");
        Days := LeaveType.GetNoOfDays(LeaveType, Employee."Employee Level");
        if Days = 0 then
            exit;

        LeaveLedgerEntry.SetRange("Employee No.", Employee."No.");
        LeaveLedgerEntry.SetRange("Transaction Type", LeaveLedgerEntry."Transaction Type"::"Leave Allocation");
        LeaveLedgerEntry.SetRange("Leave Type", LeaveType.Code);
        LeaveLedgerEntry.SetRange("Leave Period", LeavePeriod);
        if not LeaveLedgerEntry.IsEmpty() then
            exit; // already granted for this leave period

        NewEntryNo := NextEntryNo();

        LeaveLedgerEntry.Init();
        LeaveLedgerEntry."Entry No." := NewEntryNo;
        LeaveLedgerEntry."Employee No." := Employee."No.";
        LeaveLedgerEntry."Employee Name" := Employee.FullName();
        LeaveLedgerEntry."Posting Date" := Today;
        LeaveLedgerEntry."Transaction Type" := LeaveLedgerEntry."Transaction Type"::"Leave Allocation";
        LeaveLedgerEntry."Document No." := CopyStr('INIT-' + Format(NewEntryNo), 1, 20);
        LeaveLedgerEntry.Description := 'Initial allocation - ' + LeaveType.Description;
        LeaveLedgerEntry."Leave Period" := LeavePeriod;
        LeaveLedgerEntry."Leave Type" := LeaveType.Code;
        LeaveLedgerEntry."No. of Days" := Days;
        LeaveLedgerEntry."Posted Date" := CurrentDateTime;
        LeaveLedgerEntry.Insert(true);
    end;

    // Manual, single-employee grant with an admin-specified amount,
    // bypassing the automatic Leave Type entitlement calculation. Used by
    // "Grant Leave Type (Selected Employee)..." on the Employee List.
    // Deliberately does NOT check Gender restriction or an existing
    // allocation for the period itself — the calling action already
    // queries those and asks the admin to confirm, since this is a
    // deliberate, human-supervised exception grant (a specific person,
    // watching it happen), not the unattended bulk path above.
    procedure GrantSpecificAmount(Employee: Record Employee; LeaveTypeCode: Code[20]; Days: Decimal)
    var
        LeaveType: Record "Leave Type";
        LeaveLedgerEntry: Record "Leave Ledger Entry";
        HRMgt: Codeunit "HR Management";
        NewEntryNo: Integer;
    begin
        LeaveType.Get(LeaveTypeCode);
        NewEntryNo := NextEntryNo();

        LeaveLedgerEntry.Init();
        LeaveLedgerEntry."Entry No." := NewEntryNo;
        LeaveLedgerEntry."Employee No." := Employee."No.";
        LeaveLedgerEntry."Employee Name" := Employee.FullName();
        LeaveLedgerEntry."Posting Date" := Today;
        LeaveLedgerEntry."Transaction Type" := LeaveLedgerEntry."Transaction Type"::"Leave Allocation";
        LeaveLedgerEntry."Document No." := CopyStr('MANUAL-' + Format(NewEntryNo), 1, 20);
        LeaveLedgerEntry.Description := 'Manual grant - ' + LeaveType.Description;
        LeaveLedgerEntry."Leave Period" := HRMgt.GetCurrentLeavePeriod();
        LeaveLedgerEntry."Leave Type" := LeaveType.Code;
        LeaveLedgerEntry."No. of Days" := Days;
        LeaveLedgerEntry."Posted Date" := CurrentDateTime;
        LeaveLedgerEntry.Insert(true);
    end;

    local procedure NextEntryNo(): Integer
    var
        LeaveLedgerEntry: Record "Leave Ledger Entry";
    begin
        if LeaveLedgerEntry.FindLast() then
            exit(LeaveLedgerEntry."Entry No." + 1);
        exit(1);
    end;
}
