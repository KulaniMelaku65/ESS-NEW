page 51125 "Leave Application Day API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Leave Application Day API';
    DelayedInsert = true;
    EntityName = 'leaveApplicationDay';
    EntitySetName = 'leaveApplicationDays';
    PageType = API;
    SourceTable = "Leave Application Day";
    ODataKeyFields = "Leave No.", "Line No.";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(leaveNo;Rec."Leave No.")
                {
                    Caption = 'Leave No.';
                }
                field(lineNo;Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(date;Rec.Date)
                {
                    Caption = 'Date';
                }
                field(dayName;Rec."Day Name")
                {
                    Caption = 'Day Name';
                }
                field(isHalfDay;Rec."Is Half Day")
                {
                    Caption = 'Is Half Day';
                }
                field(halfDayRequested;Rec."Half Day Requested")
                {
                    Caption = 'Half Day Requested';
                }
                field(noOfDays;Rec."No. of Days")
                {
                    Caption = 'No. of Days';
                }
            }
        }
    }
}
