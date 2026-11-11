page 51138 "Grant Leave Type Dialog"
{
    // Small prompt used by "Employee List Ext" (page extension 51108) for
    // "Grant Leave Type (Selected Employee)..." — pick one leave type and
    // how many days to grant a single employee. Days defaults to that
    // type's configured entitlement (Fixed, or by Employee Level) the
    // moment a leave type is chosen, but is editable — this is the
    // manual-override path, for a specific employee needing a different
    // amount than the standard setup.
    PageType = StandardDialog;
    Caption = 'Grant Leave Type';

    layout
    {
        area(Content)
        {
            field(LeaveTypeCode; LeaveTypeCode)
            {
                ApplicationArea = All;
                Caption = 'Leave Type';
                TableRelation = "Leave Type".Code where(Status = const(Active));
                ToolTip = 'The leave type to grant.';

                trigger OnValidate()
                var
                    LeaveType: Record "Leave Type";
                begin
                    if LeaveType.Get(LeaveTypeCode) then begin
                        Employee.CalcFields("Employee Level");
                        DaysToGrant := LeaveType.GetNoOfDays(LeaveType, Employee."Employee Level");
                    end;
                end;
            }
            field(DaysToGrant; DaysToGrant)
            {
                ApplicationArea = All;
                Caption = 'Days to Grant';
                ToolTip = 'Defaults to this leave type''s configured entitlement for this employee — change it if this employee should get a different amount.';
            }
        }
    }

    procedure SetEmployee(NewEmployee: Record Employee)
    begin
        Employee := NewEmployee;
    end;

    procedure GetResult(var OutLeaveTypeCode: Code[20]; var OutDays: Decimal)
    begin
        OutLeaveTypeCode := LeaveTypeCode;
        OutDays := DaysToGrant;
    end;

    var
        Employee: Record Employee;
        LeaveTypeCode: Code[20];
        DaysToGrant: Decimal;
}
