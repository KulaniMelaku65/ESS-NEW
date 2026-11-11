page 51135 "Employee Attendance Card"
{
    // Opened by clicking an employee on "Employee Attendance Log List"
    // (drill-down on the Employee No. field) — one employee's full
    // attendance picture: identity + this month's total up top, full daily
    // log below via the "Employee Attendance Subform" part.
    PageType = Card;
    SourceTable = Employee;
    Caption = 'Employee Attendance Card';
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No.";Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(EmployeeName;EmployeeFullName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Editable = false;
                }
                field(CurrentMonthAttendanceDays;CurrentMonthDays)
                {
                    ApplicationArea = All;
                    Caption = 'Attendance Days (This Month)';
                    Editable = false;
                    ToolTip = 'Sum of Day Value from the Employee Attendance Log for the current calendar month (1 = full day, 0.5 = half day).';
                }
            }
            part(AttendanceLog;"Employee Attendance Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Employee No." = field("No.");
            }
        }
    }

    var
        CurrentMonthDays: Decimal;
        EmployeeFullName: Text[100];

    trigger OnAfterGetRecord()
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        EmployeeFullName := Rec.FullName();
        AttendanceLog.SetRange("Employee No.", Rec."No.");
        AttendanceLog.SetRange(Date, CalcDate('<-CM>', Today), CalcDate('<CM>', Today));
        AttendanceLog.CalcSums("Day Value");
        CurrentMonthDays := AttendanceLog."Day Value";
    end;
}
