page 51134 "Employee Attendance Subform"
{
    // Embedded in "Employee Attendance Card" (page 51135) via SubPageLink on
    // Employee No. — the daily rows for whichever employee the card is open
    // on.
    PageType = ListPart;
    SourceTable = "Employee Attendance Log";
    Caption = 'Attendance Log';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Date;Rec.Date)
                {
                    ApplicationArea = Basic;
                }
                field(DayType;DayType)
                {
                    ApplicationArea = Basic;
                    Caption = 'Day Type';
                    ToolTip = 'Saturday, Sunday, or the holiday name if this date is non-working; "Approved by Manager" if a missing-attendance day was explained and approved. Blank for an ordinary working day.';
                    StyleExpr = DayTypeStyle;
                }
                field("Check-In Time";Rec."Check-In Time")
                {
                    ApplicationArea = Basic;
                }
                field("Check-Out Time";Rec."Check-Out Time")
                {
                    ApplicationArea = Basic;
                }
                field(HoursWorked;HoursWorked)
                {
                    ApplicationArea = Basic;
                    Caption = 'Hours Worked';
                    DecimalPlaces = 1 : 2;
                    ToolTip = 'Check-Out Time minus Check-In Time, in hours. For a day approved by the manager without a full clock-in/out, an estimate: the average of the employee''s other worked days that week (8 hours if the week has no clock-ins at all). 0 if either punch is missing and the day was not approved.';
                }
                field("Day Value";Rec."Day Value")
                {
                    ApplicationArea = Basic;
                    ToolTip = 'Full day (1) if both check-in and check-out are recorded; half day (0.5) if only one is.';
                }
                field("Processing Result";Rec."Processing Result")
                {
                    ApplicationArea = Basic;
                }
                field("Leave No.";Rec."Leave No.")
                {
                    ApplicationArea = Basic;
                    ToolTip = 'Set automatically by the nightly Attendance Leave Processor when it links this day to an auto-created absence leave. Usually blank.';
                }
                field(ApprovedLeaveNo;ApprovedLeaveNo)
                {
                    ApplicationArea = Basic;
                    Caption = 'Approved Leave No.';
                    ToolTip = 'The employee''s own Leave Application covering this date, if they have an approved leave request for it — independent of "Leave No." above.';
                }
                field(LeaveStatusText;LeaveStatusText)
                {
                    ApplicationArea = Basic;
                    Caption = 'Leave Status';
                    ToolTip = 'On Leave, or On Leave - Half Day, if the Approved Leave No. above covers this date.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DayTypeCU: Codeunit "Attendance Day Type";
        LeaveCalc: Codeunit "Leave Half Day Calculator";
        IsHalfDayLeave: Boolean;
    begin
        ApprovedLeaveNo := LeaveCalc.GetLeaveStatus(Rec."Employee No.", Rec.Date, IsHalfDayLeave);
        if ApprovedLeaveNo <> '' then
            if IsHalfDayLeave then
                LeaveStatusText := 'On Leave - Half Day'
            else
                LeaveStatusText := 'On Leave'
        else
            LeaveStatusText := '';

        HoursWorked := Rec.GetHoursWorked();
        DayType := DayTypeCU.GetDayType(Rec.Date);
        if DayType <> '' then
            DayTypeStyle := 'Ambiguous'
        else
            if Rec."Processing Result" = Rec."Processing Result"::"Approved by Manager" then begin
                DayType := 'Approved by Manager';
                DayTypeStyle := 'AttentionAccent';
            end else
                DayTypeStyle := 'Standard';
    end;

    var
        ApprovedLeaveNo: Code[20];
        LeaveStatusText: Text[20];
        HoursWorked: Decimal;
        DayType: Text[30];
        DayTypeStyle: Text;
}
