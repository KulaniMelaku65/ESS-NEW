page 51104 tsLineAPI
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet Lines API';
    DelayedInsert = true;
    EntityName = 'TimesheetsLine';
    EntitySetName = 'TimesheetsLines';
    PageType = API;
    SourceTable = "Monthly Timesheet Line";
    ODataKeyFields = "Document No.", "Line No.";
    AutoSplitKey = true;



    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }

                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(workDate; Rec."Work Date")
                {
                    Caption = 'Work Date';
                }
                field(morningHours; Rec."Morning Hours")
                {
                    Caption = 'Morning Hours';
                }
                field(afternoonHours; Rec."Afternoon Hours")
                {
                    Caption = 'Afternoon Hours';
                }
                field(activity; Rec.Activity)
                {
                    Caption = 'Activity';
                }
                field(Notes; Rec.Notes)
                {
                    Caption = 'Notes';
                }
                field(dailyTotal; Rec."Daily Total")
                {
                    Caption = 'Total for Day';
                }
                field(hours; Rec.Hours)
                {
                    Caption = 'Hours';
                }
            }
        }
    }

    // Add this trigger
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Auto-calculate daily total and hours
        Rec."Daily Total" := Rec."Morning Hours" + Rec."Afternoon Hours";
        Rec.Hours := Rec."Daily Total";
        exit(false);
    end;


}
