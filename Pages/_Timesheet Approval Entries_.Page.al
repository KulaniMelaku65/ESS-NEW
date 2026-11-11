page 51105 "Timesheet Approval Entries"
{
    ApplicationArea = Suite;
    Caption = 'Approval Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Timesheet Approval Entry";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Timesheet No.";Rec."Timesheet No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Timesheet No. field.', Comment='%';
                }
                field("Sequence No.";Rec."Sequence No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Sequence No. field.', Comment='%';
                }
                field("Approver ID";Rec."Approver ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Approver ID field.', Comment='%';
                }
                field(ApproverName;ApproverName)
                {
                    ApplicationArea = All;
                    Caption = 'Approver Name';
                    ToolTip = 'The approver''s full name, resolved from Approver ID (which holds an Employee No. for the dynamic supervisor step, or a BC User ID for the static configured step).';
                }
                field(Status;Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.', Comment='%';
                }
                field("Date-Time Sent";Rec."Date-Time Sent")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Date-Time Sent field.', Comment='%';
                }
                field("Last Modified";Rec."Last Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Last Modified field.', Comment='%';
                }
                field("Approved By";Rec."Approved By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Approved By field.', Comment='%';
                }
                field("Rejected By";Rec."Rejected By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Rejected By field.', Comment='%';
                }
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Employee No. field.', Comment='%';
                }
                field("Employee Name";Rec."Employee Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Employee Name field.', Comment='%';
                }
                field(Description;Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.', Comment='%';
                }
            }
        }
    }

    // "Approver ID" holds a BC User ID for the static, ERP-configured
    // approval step, but an Employee No. for the dynamic supervisor step
    // (same mixed identity the "Timesheet Approval Lines API" page already
    // resolves) — try Employee No. first since that's the common case,
    // then fall back to matching Employee."User ID".
    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(ApproverName);
        if Employee.Get(Rec."Approver ID") then
            ApproverName := Employee.FullName()
        else begin
            Employee.Reset();
            Employee.SetRange("User ID", Rec."Approver ID");
            if Employee.FindFirst() then
                ApproverName := Employee.FullName();
        end;
    end;

    var
        ApproverName: Text[100];
}
