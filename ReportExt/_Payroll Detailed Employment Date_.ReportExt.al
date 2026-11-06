reportextension 51101 "Payroll Detailed Empl. Date" extends "Payroll Detailed"
{
    // Replaces the "Department" column (bound to the Employee's own
    // "Global Dimension 2 Code") with "Employment Date" on the printed
    // report. The base report's dataset still carries GlobalDimension2Code
    // untouched — only this extension's own custom layout (below) actually
    // stops rendering it and shows the new EmploymentDate column instead.
    dataset
    {
        add(Employee)
        {
            column(EmploymentDate; "Employment Date")
            {
            }
        }
    }

    // A report extension can only ADD dataset columns via AL — it can't
    // patch individual cells of the base report's own RDLC. Swapping what's
    // actually shown requires a full replacement layout: a copy of the base
    // app's Rep60401.PayrollDetailed.rdl with the "Department" header/data
    // textbox changed to use the new EmploymentDate field instead. Added
    // here as a selectable layout rather than forced via AL — set it as the
    // default from Report Layout Selection (Administration) once published,
    // so this can be switched without another deployment.
    rendering
    {
        layout(PayrollDetailedEmploymentDate)
        {
            Type = RDLC;
            LayoutFile = './Reports/PayrollDetailedEmploymentDate.rdlc';
            Caption = 'Payroll Detailed (Employment Date)';
            Summary = 'Shows Employment Date instead of Department.';
        }
    }
}
