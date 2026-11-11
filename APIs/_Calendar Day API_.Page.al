page 51129 "Calendar Day API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Calendar Day API';
    DelayedInsert = false;
    EntityName = 'calendarDay';
    EntitySetName = 'calendarDays';
    PageType = API;
    SourceTable = "Calendar Day Entry";
    ODataKeyFields = "Calendar Code", Date;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(calendarCode;Rec."Calendar Code")
                {
                    Caption = 'Calendar Code';
                }
                field(date;Rec.Date)
                {
                    Caption = 'Date';
                }
                field(dayName;Rec."Day Name")
                {
                    Caption = 'Day';
                }
                field(isWorkingDay;Rec."Is Working Day")
                {
                    Caption = 'Is Working Day';
                }
                field(isHalfDay;Rec."Is Half Day")
                {
                    Caption = 'Is Half Day';
                }
                field(description;Rec.Description)
                {
                    Caption = 'Description';
                }
            }
        }
    }
}
