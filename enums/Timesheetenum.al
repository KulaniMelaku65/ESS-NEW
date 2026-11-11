enum 51100 "Timesheet Status"
{
    Extensible = true;

    value(0;Open)
    {
    Caption = 'Open';
    }
    value(1;"Pending Approval")
    {
    Caption = 'Pending Approval';
    }
    value(2;Approved)
    {
    Caption = 'Approved';
    }
    value(3;Rejected)
    {
    Caption = 'Rejected';
    }
    value(4;Cancelled)
    {
    Caption = 'Cancelled';
    }
    value(5;Reopened)
    {
    Caption = 'Reopened';
    }
    value(6;Created)
    {
    Caption = 'Created';
    }
}
