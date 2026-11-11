tableextension 51104 "sales&ReceivableTimehseetTable" extends "Sales & Receivables Setup"
{
    fields
    {
        field(51100;"Timesheet workflow group code";Code[50])
        {
            Caption = 'Timesheet workflow group';
            TableRelation = "Workflow User Group"."Code";
        }
        field(51101;"Timesheet Final Approver No.";Code[20])
        {
            Caption = 'Timesheet Final Approver No.';
            TableRelation = Employee."No.";
        }
    }
}
