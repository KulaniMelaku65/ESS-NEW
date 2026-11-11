tableextension 51101 "EmployeeTableExt.al" extends Employee
{
    fields
    {
        field(51100;"Fayda No.";Code[20])
        {
            Caption = 'Fayda No.';
        }
        field(51102;"Employee Location";Code[20])
        {
            Caption = 'Employee Location';
            TableRelation = "Employee Location"."Code";
        }
        field(51103;"Agent";Boolean)
        {
            Caption = 'Agent';
        }
        field(51104;"HRBP No.";Code[20])
        {
            Caption = 'HRBP No.';
            TableRelation = Employee."No.";
        }
        field(51105;"Excl. Attendance Review";Boolean)
        {
            Caption = 'Excl. Attendance Review';
        }
        field(51106;"Annual Leave Entitlement";Decimal)
        {
            // Total annual leave days for this employee. Once filled in and
            // the employee is Active, codeunit "Annual Leave Accrual"
            // credits Entitlement / 12 to their leave balance every month
            // (see that codeunit for how it avoids double-crediting).
            Caption = 'Annual Leave Entitlement';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
    }
}
