page 51120 "Base Calendar API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Base Calendar API';
    DelayedInsert = true;
    EntityName = 'calendarEntry';
    EntitySetName = 'calendarEntries';
    PageType = API;
    SourceTable = "Base Calendar Change";
    ODataKeyFields = "Base Calendar Code", "Recurring System", Date, Day;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(baseCalendarCode;Rec."Base Calendar Code")
                {
                    Caption = 'Base Calendar Code';
                }
                field(recurringSystem;Rec."Recurring System")
                {
                    Caption = 'Recurring System';
                }
                field(date;Rec.Date)
                {
                    Caption = 'Date';
                }
                field(day;Rec.Day)
                {
                    Caption = 'Day';
                }
                field(description;Rec.Description)
                {
                    Caption = 'Description';
                }
                field(nonworking;Rec.Nonworking)
                {
                    Caption = 'Nonworking';
                }
                field(isHalfDay;Rec."Is Half Day")
                {
                    Caption = 'Is Half Day';
                }
            }
        }
    }
}
