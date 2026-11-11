pageextension 51105 HREmployeePageExt extends "HR Employee Card"
{
    layout
    {
        addafter("Gender")
        {
            field("Fayda Number";Rec."Fayda No.")
            {
                ApplicationArea = All;
                visible = true;
            }
        }
        addafter("Shortcut Dimension 8 Code")
        {
            field("Agent";Rec."Agent")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Indicates whether the employee is an agent.';
            }
            field("Employee Location";Rec."Employee Location")
            {
                ApplicationArea = All;
                visible = true;
                ToolTip = 'Specifies the location of the employee.';
            }
            field("HRBP No.";Rec."HRBP No.")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'The HR Business Partner responsible for this employee — CC''d on automated attendance review emails.';
            }
            field("Excl. Attendance Review";Rec."Excl. Attendance Review")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Set for SLT members and anyone else who should never receive the automated monthly attendance review email.';
            }
            field("Annual Leave Entitlement";Rec."Annual Leave Entitlement")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Total annual leave days for this employee. Once set, and while Employee Status is Active, 1/12th of this is credited to their leave balance automatically every month.';
            }
            field(CurrentMonthAttendanceDays;CurrentMonthDays)
            {
                ApplicationArea = All;
                Caption = 'Attendance Days (This Month)';
                Editable = false;
                ToolTip = 'Sum of Day Value from the Employee Attendance Log for the current calendar month (1 = full day, 0.5 = half day).';
            }
        }
    }
    actions
    {
        addafter("Q&ualifications")
        {
            action("WorkExpereince")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Work Experience';
                Image = Certificate;
                Promoted = true;
                PromotedCategory = Category5;
                RunObject = Page "ESS Work Experience";
                RunPageLink = "Employee No."=FIELD("No.");
                ToolTip = 'Open the list of work experience records for the employee.';
            }
            action("AttendanceLog")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attendance Log';
                Image = Timesheet;
                Promoted = true;
                PromotedCategory = Category5;
                RunObject = Page "Employee Attendance Card";
                RunPageLink = "No."=FIELD("No.");
                ToolTip = 'Open the daily check-in/check-out log for this employee.';
            }
        }
    }

    var
        CurrentMonthDays: Decimal;

    trigger OnAfterGetRecord()
    var
        AttendanceLog: Record "Employee Attendance Log";
    begin
        AttendanceLog.SetRange("Employee No.", Rec."No.");
        AttendanceLog.SetRange(Date, CalcDate('<-CM>', Today), CalcDate('<CM>', Today));
        AttendanceLog.CalcSums("Day Value");
        CurrentMonthDays := AttendanceLog."Day Value";
    end;
}
