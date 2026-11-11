page 51142 "Absence Explanation List"
{
    // Working queue for the absence explain-and-confirm workflow (see
    // codeunit "Attendance Absence Notifier"). Enter what the employee
    // replied with, click "Submit Employee Reason" to email their manager,
    // then use "Confirm (Yes)" / "Reject (No)" once the manager responds.
    ApplicationArea = Basic;
    Caption = 'Attendance Absence Explanations';
    PageType = List;
    SourceTable = "Attendance Absence Explanation";
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field(EmployeeName;EmployeeName)
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee Name';
                }
                field(Date;Rec.Date)
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field(Status;Rec.Status)
                {
                    ApplicationArea = Basic;
                }
                field(Reason;Rec.Reason)
                {
                    ApplicationArea = Basic;
                    ToolTip = 'What the employee gave as the reason for their absence — enter this once they''ve replied, then use "Submit Employee Reason".';
                    Editable = Rec.Status = Rec.Status::"Pending Employee Response";
                }
                field("Manager No.";Rec."Manager No.")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field(ManagerName;ManagerName)
                {
                    ApplicationArea = Basic;
                    Caption = 'Manager Name';
                }
                field("Manager Decision";Rec."Manager Decision")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field("Employee Notified On";Rec."Employee Notified On")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field("Manager Notified On";Rec."Manager Notified On")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
                field("Decided On";Rec."Decided On")
                {
                    ApplicationArea = Basic;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SubmitEmployeeReason)
            {
                ApplicationArea = Basic;
                Caption = 'Submit Employee Reason';
                Image = SendTo;
                ToolTip = 'Marks the Reason entered above as the employee''s response and emails their manager to confirm it.';

                trigger OnAction()
                var
                    Notifier: Codeunit "Attendance Absence Notifier";
                begin
                    Notifier.SubmitEmployeeReason(Rec, Rec.Reason);
                    CurrPage.Update(false);
                end;
            }
            action(ConfirmYes)
            {
                ApplicationArea = Basic;
                Caption = 'Confirm (Manager: Yes)';
                Image = Approve;
                ToolTip = 'Records the manager''s Yes and writes the reason onto the employee''s attendance log for this date.';

                trigger OnAction()
                var
                    Notifier: Codeunit "Attendance Absence Notifier";
                begin
                    if not Confirm('Confirm that %1''s manager approved this reason for %2?', false, Rec."Employee No.", Rec.Date) then
                        exit;
                    Notifier.ManagerDecide(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(ConfirmNo)
            {
                ApplicationArea = Basic;
                Caption = 'Reject (Manager: No)';
                Image = Reject;
                ToolTip = 'Records that the manager did not confirm this reason. Nothing is written to the attendance log — handle the day manually from here.';

                trigger OnAction()
                var
                    Notifier: Codeunit "Attendance Absence Notifier";
                begin
                    if not Confirm('Record that %1''s manager rejected this reason for %2?', false, Rec."Employee No.", Rec.Date) then
                        exit;
                    Notifier.ManagerDecide(Rec, false);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(EmployeeName);
        Clear(ManagerName);
        if Employee.Get(Rec."Employee No.") then
            EmployeeName := Employee.FullName();
        if (Rec."Manager No." <> '') and Employee.Get(Rec."Manager No.") then
            ManagerName := Employee.FullName();
    end;

    var
        EmployeeName: Text[100];
        ManagerName: Text[100];
}
