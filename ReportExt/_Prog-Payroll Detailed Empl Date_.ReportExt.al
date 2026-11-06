reportextension 51102 "Prog-Payroll Detail Empl Date" extends "Prog-Payroll Detailed"
{
    // Same change as "Payroll Detailed Empl. Date" (51101) — this is the
    // "progressive" payroll counterpart, a separate report object that
    // happens to duplicate the exact same dataset/layout structure. Swaps
    // the "Department" column (Employee's "Global Dimension 2 Code") for
    // "Employment Date" on a custom layout; the base report's own
    // GlobalDimension2Code column is left untouched.
    dataset
    {
        add(Employee)
        {
            column(EmploymentDate; "Employment Date")
            {
            }
        }
    }

    rendering
    {
        layout(ProgPayrollDetailedEmploymentDate)
        {
            Type = RDLC;
            LayoutFile = './Reports/ProgPayrollDetailedEmploymentDate.rdlc';
            Caption = 'Prog-Payroll Detailed (Employment Date)';
            Summary = 'Shows Employment Date instead of Department.';
        }
    }
}
