codeunit 51145 "Annual Leave Accrual"
{
    // Monthly accrual for Employee."Annual Leave Entitlement" (table
    // extension 51101, field 51106): for every Active employee with an
    // entitlement filled in, credits Entitlement / 12 to their leave
    // balance for the current month by inserting a "Leave Allocation"
    // transaction-type Leave Ledger Entry — the same table
    // Leave Application."Leave Balance" sums from, so it shows up exactly
    // like any other leave credit everywhere in the system.
    //
    // Idempotent: Document No. encodes the calendar month ("ACCR-YYYYMM"),
    // and Leave Ledger Entry has a unique key on ("Employee No.",
    // "Document No.") — so running this more than once in the same month
    // is a safe no-op for anyone already credited that month rather than
    // double-crediting.
    //
    // Scope, deliberately: starts accruing prospectively from whenever
    // this is first run — it does NOT backfill catch-up entries for months
    // already elapsed since an employee's hire date. Existing employees'
    // balances are left exactly as they are; only new, going-forward
    // months get credited. A brand-new employee marked Active naturally
    // starts getting credited the first time this runs after they're
    // entered, with an entitlement filled in.
    //
    // SETUP REQUIRED: Create a Job Queue Entry pointing at this codeunit
    // (51145), recurring monthly (e.g. 1st of each month).

    trigger OnRun()
    begin
        AccrueForCurrentMonth();
    end;

    procedure AccrueForCurrentMonth()
    begin
        AccrueForMonth(Today);
    end;

    // AccrualDate: any date within the target month — only its month/year
    // matter (for the Document No. and for how much seniority bonus had
    // accrued by then). Used both for the normal current-month run and for
    // manually catching up a specific month that was missed (e.g. run once
    // with a date in July, once with a date in August).
    procedure AccrueForMonth(AccrualDate: Date)
    var
        Employee: Record Employee;
    begin
        Employee.SetRange("Employee Status", Employee."Employee Status"::Active);
        Employee.SetFilter("Annual Leave Entitlement", '>%1', 0);
        if Employee.FindSet() then
            repeat
                AccrueForEmployee(Employee, AccrualDate);
            until Employee.Next() = 0;
    end;

    local procedure AccrueForEmployee(Employee: Record Employee; AccrualDate: Date)
    var
        LeaveLedgerEntry: Record "Leave Ledger Entry";
        HRMgt: Codeunit "HR Management";
        DocNo: Code[20];
        EffectiveEntitlement: Decimal;
        MonthlyDays: Decimal;
    begin
        // If this employee already got Fanisi's old "Allocation on Hire"
        // lump sum — a full year's entitlement granted all at once instead
        // of monthly — and they're still within that same first year of
        // service, monthly accrual on top of it would over-credit them for
        // year 1. Hold off until their first anniversary, when year 2
        // genuinely needs its own crediting (nothing else covers it).
        // Doesn't apply to anyone who never got that lump sum (any new
        // hire since "Suppress Fanisi Leave Alloc." went in) — they start
        // accruing normally from month one.
        if HasHireLumpSum(Employee."No.") and (CompletedYearsOfService(Employee."Employment Date", AccrualDate) < 1) then
            exit;

        DocNo := AccrualDocNo(AccrualDate);

        // Guard against ANY Annual Leave allocation already posted for this
        // employee this calendar month — not just one matching our own
        // "ACCR-YYYYMM" Document No. A month can already be covered by the
        // old manual process (a different Document No./Description
        // entirely), and this still needs to catch that to avoid
        // double-crediting.
        LeaveLedgerEntry.SetRange("Employee No.", Employee."No.");
        LeaveLedgerEntry.SetRange("Transaction Type", LeaveLedgerEntry."Transaction Type"::"Leave Allocation");
        LeaveLedgerEntry.SetRange("Leave Type", AnnualLeaveType());
        LeaveLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', AccrualDate), CalcDate('<CM>', AccrualDate));
        if not LeaveLedgerEntry.IsEmpty() then
            exit; // already credited this employee for this calendar month — ours or the old manual method
        LeaveLedgerEntry.Reset();

        EffectiveEntitlement := Employee."Annual Leave Entitlement" + SeniorityBonusDays(Employee."Employment Date", AccrualDate);
        MonthlyDays := Round(EffectiveEntitlement / 12, 0.01);
        if MonthlyDays = 0 then
            exit;

        LeaveLedgerEntry.Init();
        LeaveLedgerEntry."Entry No." := NextEntryNo();
        LeaveLedgerEntry."Employee No." := Employee."No.";
        LeaveLedgerEntry."Employee Name" := Employee.FullName();
        LeaveLedgerEntry."Posting Date" := AccrualDate;
        LeaveLedgerEntry."Transaction Type" := LeaveLedgerEntry."Transaction Type"::"Leave Allocation";
        LeaveLedgerEntry."Document No." := DocNo;
        LeaveLedgerEntry.Description := 'Monthly annual leave accrual - ' + Format(AccrualDate, 0, '<Month Text> <Year4>');
        LeaveLedgerEntry."Leave Period" := HRMgt.GetCurrentLeavePeriod();
        LeaveLedgerEntry."Leave Type" := AnnualLeaveType();
        LeaveLedgerEntry."No. of Days" := MonthlyDays;
        LeaveLedgerEntry."Leave Entitlement" := EffectiveEntitlement;
        LeaveLedgerEntry."Posted Date" := CurrentDateTime;
        LeaveLedgerEntry.Insert(true);
    end;

    // +1 day for every 2 completed years of service since hire date. E.g.
    // hired 2026-04-01, base 16 days: still 16 through the 2027-04-01
    // anniversary (1 year completed, < 2); becomes 17 exactly at the
    // 2028-04-01 anniversary (2 years completed) and stays 17 until the
    // 2030-04-01 anniversary (4 years completed) bumps it to 18, and so on.
    // Public so other places that need to show "what would this employee's
    // effective entitlement be" (e.g. a leave balance report) can reuse
    // this exact formula instead of re-deriving it.
    procedure SeniorityBonusDays(EmploymentDate: Date; AsOfDate: Date): Integer
    begin
        exit(CompletedYearsOfService(EmploymentDate, AsOfDate) div 2);
    end;

    local procedure CompletedYearsOfService(EmploymentDate: Date; AsOfDate: Date): Integer
    var
        YearsOfService: Integer;
    begin
        if EmploymentDate = 0D then
            exit(0);
        if AsOfDate < EmploymentDate then
            exit(0);

        YearsOfService := Date2DMY(AsOfDate, 3) - Date2DMY(EmploymentDate, 3);
        // Anniversary for this year hasn't happened yet — don't count it.
        if (Date2DMY(AsOfDate, 2) < Date2DMY(EmploymentDate, 2)) or
           ((Date2DMY(AsOfDate, 2) = Date2DMY(EmploymentDate, 2)) and (Date2DMY(AsOfDate, 1) < Date2DMY(EmploymentDate, 1)))
        then
            YearsOfService -= 1;

        if YearsOfService < 0 then
            exit(0);
        exit(YearsOfService);
    end;

    // Detects Fanisi's old lump-sum grant by the exact, hardcoded shape
    // only that one procedure produces (see codeunit "Suppress Fanisi
    // Leave Alloc." for the same signature). Existence-only check — not
    // date-scoped, since it should only ever exist once per employee (it
    // fires once, at activation).
    local procedure HasHireLumpSum(EmployeeNo: Code[20]): Boolean
    var
        LeaveLedgerEntry: Record "Leave Ledger Entry";
    begin
        LeaveLedgerEntry.SetRange("Employee No.", EmployeeNo);
        LeaveLedgerEntry.SetRange("Transaction Type", LeaveLedgerEntry."Transaction Type"::"Leave Allocation");
        LeaveLedgerEntry.SetRange(Description, 'Allocation on Hire');
        exit(not LeaveLedgerEntry.IsEmpty());
    end;

    // Deletes THIS codeunit's own accrual entry for one employee/month, if
    // one exists — matched strictly on our own "ACCR-YYYYMM" Document No.,
    // so it can only ever remove an entry this codeunit created. Never
    // touches an old manual entry or anything from any other source. For
    // fixing a case like: this codeunit didn't realize a month was already
    // covered by the old manual process and created a duplicate on top —
    // use this to remove the duplicate it created, leaving the original
    // manual entry untouched.
    procedure UndoAccrualForMonth(EmployeeNo: Code[20]; AccrualDate: Date): Boolean
    var
        LeaveLedgerEntry: Record "Leave Ledger Entry";
    begin
        LeaveLedgerEntry.SetRange("Employee No.", EmployeeNo);
        LeaveLedgerEntry.SetRange("Document No.", AccrualDocNo(AccrualDate));
        if LeaveLedgerEntry.FindFirst() then begin
            LeaveLedgerEntry.Delete(false);
            exit(true);
        end;
        exit(false);
    end;

    local procedure AccrualDocNo(AccrualDate: Date): Code[20]
    begin
        exit(CopyStr('ACCR-' + Format(Date2DMY(AccrualDate, 3)) + PadZero(Date2DMY(AccrualDate, 2)), 1, 20));
    end;

    local procedure PadZero(N: Integer): Text
    begin
        if N < 10 then
            exit('0' + Format(N));
        exit(Format(N));
    end;

    local procedure AnnualLeaveType(): Code[20]
    var
        LeaveType: Record "Leave Type";
    begin
        // The one Leave Type flagged "Is Annual" — Leave Type itself
        // enforces there can only be one (see CheckUnique in Fanisi HR).
        exit(LeaveType.GetAnnualLeave());
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
