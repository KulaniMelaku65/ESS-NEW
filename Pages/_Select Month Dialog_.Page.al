page 51110 "Select Month Dialog"
{
    // Small prompt used by "Employee List Ext" (page extension 51108) to
    // ask which month to run "Annual Leave Accrual" for, when catching up
    // a month that was missed.
    PageType = StandardDialog;
    Caption = 'Select Month to Accrue';

    layout
    {
        area(Content)
        {
            field(TargetDate;TargetDate)
            {
                ApplicationArea = All;
                Caption = 'Any Date in the Month';
                ToolTip = 'Enter any date within the month you want to accrue — e.g. the 1st of that month. Only the month and year matter.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        TargetDate := Today;
    end;

    procedure GetTargetDate(): Date
    begin
        exit(TargetDate);
    end;

    var
        TargetDate: Date;
}
