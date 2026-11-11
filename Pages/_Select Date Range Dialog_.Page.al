page 51118 "Select Date Range Dialog"
{
    // Small prompt used by "Employee Attendance Log List" (page 51130) to
    // ask for a Start/End date range — e.g. when re-pulling historical
    // punch data for one employee.
    PageType = StandardDialog;
    Caption = 'Select Date Range';

    layout
    {
        area(Content)
        {
            field(StartDate;StartDate)
            {
                ApplicationArea = All;
                Caption = 'Start Date';
            }
            field(EndDate;EndDate)
            {
                ApplicationArea = All;
                Caption = 'End Date';
            }
        }
    }

    trigger OnOpenPage()
    begin
        EndDate := Today;
        StartDate := CalcDate('<-CM>', Today);
    end;

    procedure GetStartDate(): Date
    begin
        exit(StartDate);
    end;

    procedure GetEndDate(): Date
    begin
        exit(EndDate);
    end;

    var
        StartDate: Date;
        EndDate: Date;
}
