page 51109 "Timesheet Approval Lines API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet Approval Lines API';
    DelayedInsert = false;
    EntityName = 'TimesheetLineForApproval';
    EntitySetName = 'TimesheetLinesForApproval';
    PageType = API;
    SourceTable = "Monthly Timesheet Line";
    ODataKeyFields = "Document No.", "Line No.";
    Editable = false; // Read-only
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(documentNo;Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(lineNo;Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(workDate;Rec."Work Date")
                {
                    Caption = 'Work Date';
                }
                field(morningHours;Rec."Morning Hours")
                {
                    Caption = 'Morning Hours';
                }
                field(afternoonHours;Rec."Afternoon Hours")
                {
                    Caption = 'Afternoon Hours';
                }
                field(activity;Rec.Activity)
                {
                    Caption = 'Activity';
                }
                field(notes;Rec.Notes)
                {
                    Caption = 'Notes';
                }
                field(dailyTotal;Rec."Daily Total")
                {
                    Caption = 'Daily Total';
                }
                field(hours;Rec.Hours)
                {
                    Caption = 'Total Hours';
                }
            }
        }
    }
}
