page 51147 "Attendance Review Send Log"
{
    ApplicationArea = Basic;
    Caption = 'Attendance Review Send Log';
    PageType = List;
    SourceTable = "Attendance Review Send Log";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No.";Rec."Entry No.")
                {
                    ApplicationArea = Basic;
                }
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = Basic;
                }
                field("Employee Name";Rec."Employee Name")
                {
                    ApplicationArea = Basic;
                }
                field("Period Start";Rec."Period Start")
                {
                    ApplicationArea = Basic;
                }
                field("Period End";Rec."Period End")
                {
                    ApplicationArea = Basic;
                }
                field("Sent To";Rec."Sent To")
                {
                    ApplicationArea = Basic;
                }
                field("Supervisor CC";Rec."Supervisor CC")
                {
                    ApplicationArea = Basic;
                }
                field("HRBP CC";Rec."HRBP CC")
                {
                    ApplicationArea = Basic;
                }
                field("Sent At";Rec."Sent At")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}
