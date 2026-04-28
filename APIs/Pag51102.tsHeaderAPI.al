page 51102 tsHeaderAPI
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet API';
    DelayedInsert = true;
    EntityName = 'Timesheet';
    EntitySetName = 'Timesheets';
    PageType = API;
    SourceTable = "Monthly Timesheet Header";
    ODataKeyFields = "No.";
    //AutoSplitKey = true;


    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(employeeNo; Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(month; Rec.Month)
                {
                    Caption = 'Month';
                }
                field(year; Rec.Year)
                {
                    Caption = 'Year';
                }
                field(totalHours; Rec."Total Hours")
                {
                    Caption = 'Total Hours';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(approverID; Rec."Approver ID")
                {
                    Caption = 'Approver ID';
                }

            }
            // This is the magic part that nests the lines

            part(Lines; tsLineAPI)
            {
                Caption = 'Lines';
                EntityName = 'TimesheetsLine';
                EntitySetName = 'TimesheetsLines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

}
