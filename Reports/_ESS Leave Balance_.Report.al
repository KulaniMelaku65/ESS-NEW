report 51149 "ESS Leave Balance"
{
    // Standalone replacement for Fanisi HR's "Leave Balance" report
    // (52179082) — same layout and structure, reusing its RDLC verbatim
    // (Reports/ESSLeaveBalance.rdlc), but the Annual Leave row's
    // "Entitlement" column shows OUR value (Employee."Annual Leave
    // Entitlement" + seniority bonus, via codeunit "Annual Leave Accrual")
    // instead of the base report's "Allocated Leave Days" flowfield, which
    // is a running sum of what's actually been credited so far this
    // period — a different, smaller number early in the year that
    // confused people expecting to see the same figure as the Employee
    // card.
    //
    // "Available Balance" is NOT changed to use that same value — it still
    // adds up what's actually been credited (via "Allocated Leave Days"),
    // so the balance math stays correct. Only the displayed Entitlement
    // number changes for the Annual Leave row; every other leave type
    // behaves exactly as it did on the original report.
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Leave Balance (ESS)';
    DefaultLayout = RDLC;
    RDLCLayout = './Reports/ESSLeaveBalance.rdlc';

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";
            column(ReportForNavId_1; 1)
            {
            }
            column(No; Employee."No.")
            {
            }
            column(Fullname; Employee.FullName())
            {
            }
            column(JobTitle; Employee."Job Title")
            {
            }
            column(Gender; Gender)
            {
            }
            column(LeavePeriod; LeavePeriod)
            {
            }
            column(LeaveFilter; LeaveFilter)
            {
            }
            column(CompInfoName; CompInfo.Name)
            {
            }
            column(CompInfoAddress; CompInfo.Address)
            {
            }
            column(CompInfoAddress2; CompInfo."Address 2")
            {
            }
            column(CompInfoPicture; CompInfo.Picture)
            {
            }
            dataitem(Leave; Integer)
            {
                column(LeaveType; LeaveType[Number])
                {
                }
                column(BalBefore; BalBefore[Number])
                {
                }
                column(Forfeiture; Forfeiture[Number])
                {
                }
                column(DaysTaken; DaysTaken[Number])
                {
                }
                column(AvailableBal; AvailableBal[Number])
                {
                }
                column(Liablility; Liablility[Number])
                {
                }
                column(YearEntitlement; YearEntitlement[Number])
                {
                }
                column(Adjustment; Adjustment[Number])
                {
                }

                trigger OnPreDataItem()
                begin
                    Leave.SetRange(Number, 1, i);
                end;
            }

            trigger OnAfterGetRecord()
            var
                EmployeeRec: Record Employee;
                LeaveTypeRec: Record "Leave Type";
                LeaveLedgerEntry: Record "Leave Ledger Entry";
                AccrualCU: Codeunit "Annual Leave Accrual";
                AnnualLeaveCode: Code[20];
                AllocatedSoFar: Decimal;
                DisplayedEntitlement: Decimal;
            begin
                i := 0;
                Clear(LeaveType);
                Clear(BalBefore);
                Clear(Forfeiture);
                Clear(DaysTaken);
                Clear(Adjustment);
                Clear(AvailableBal);
                Clear(Liablility);
                Clear(YearEntitlement);

                AnnualLeaveCode := LeaveTypeRec.GetAnnualLeave();

                LeaveTypeRec.Reset();
                if LeaveFilter <> '' then
                    LeaveTypeRec.SetFilter(Code, LeaveFilter);
                if LeaveTypeRec.FindSet() then
                    repeat
                        EmployeeRec.Copy(Employee);
                        EmployeeRec.SetRange("Leave Period Filter", LeavePeriod);
                        EmployeeRec.SetRange("Leave Type Filter", LeaveTypeRec.Code);
                        EmployeeRec.CalcFields("Allocated Leave Days", "Total Leave Taken", "Leave Balance", "Brought Forward Leave Days", "Adjustment Leave Days", "Recall Leave Days", "Forfeiture Leave Days");

                        // "Allocated Leave Days" is what's actually been
                        // credited so far this period — used for the real
                        // balance math. For Annual Leave, once the employee
                        // has been migrated to the new system (an entitlement
                        // is filled in), the old Fanisi "Allocation on Hire"
                        // lump sum is excluded entirely here — it's legacy
                        // noise from before this employee was on the new
                        // system, and mixing it with the new monthly figures
                        // was confusing the report. Recomputed directly from
                        // Leave Ledger Entry rather than the blanket
                        // "Allocated Leave Days" flowfield, which has no way
                        // to exclude just that one entry.
                        if (LeaveTypeRec.Code = AnnualLeaveCode) and (Employee."Annual Leave Entitlement" > 0) then begin
                            LeaveLedgerEntry.Reset();
                            LeaveLedgerEntry.SetRange("Employee No.", Employee."No.");
                            LeaveLedgerEntry.SetRange("Leave Period", LeavePeriod);
                            LeaveLedgerEntry.SetRange("Leave Type", AnnualLeaveCode);
                            LeaveLedgerEntry.SetRange("Transaction Type", LeaveLedgerEntry."Transaction Type"::"Leave Allocation");
                            LeaveLedgerEntry.SetFilter(Description, '<>%1', 'Allocation on Hire');
                            LeaveLedgerEntry.CalcSums("No. of Days");
                            AllocatedSoFar := LeaveLedgerEntry."No. of Days";
                        end else
                            AllocatedSoFar := EmployeeRec."Allocated Leave Days";

                        if LeaveTypeRec.Code = AnnualLeaveCode then
                            // Our flat/effective entitlement (base + seniority
                            // bonus, as of today) — matches the Employee card,
                            // not a partial running total.
                            DisplayedEntitlement := Employee."Annual Leave Entitlement" + AccrualCU.SeniorityBonusDays(Employee."Employment Date", Today)
                        else
                            DisplayedEntitlement := AllocatedSoFar;

                        if (AllocatedSoFar + EmployeeRec."Leave Balance") <> 0 then begin
                            i += 1;
                            LeaveType[i] := LeaveTypeRec.Code;
                            BalBefore[i] := EmployeeRec."Brought Forward Leave Days";
                            Forfeiture[i] := EmployeeRec."Forfeiture Leave Days";
                            DaysTaken[i] := EmployeeRec."Total Leave Taken" - EmployeeRec."Recall Leave Days";
                            YearEntitlement[i] := DisplayedEntitlement;
                            Adjustment[i] := EmployeeRec."Adjustment Leave Days";
                            AvailableBal[i] := (BalBefore[i] + AllocatedSoFar + Adjustment[i]) - (DaysTaken[i] + Forfeiture[i]);
                        end;
                    until LeaveTypeRec.Next() = 0;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                field(LeavePeriod; LeavePeriod)
                {
                    Caption = 'Leave Period';
                    ApplicationArea = All;
                    TableRelation = "Leave Period";
                }
                field(LeaveFilter; LeaveFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Leave Type';
                    TableRelation = "Leave Type";
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        CompInfo.Get();
        CompInfo.CalcFields(Picture);

        if LeavePeriod = '' then
            LeavePeriod := HRMgt.GetCurrentLeavePeriod();
    end;

    var
        CompInfo: Record "Company Information";
        HRMgt: Codeunit "HR Management";
        LeavePeriod, LeaveFilter : Code[20];
        i: Integer;
        LeaveType: array[50] of Code[20];
        BalBefore, DaysTaken, AvailableBal, Liablility, YearEntitlement, Forfeiture, Adjustment : array[50] of Decimal;
}
