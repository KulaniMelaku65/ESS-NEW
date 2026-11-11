codeunit 51114 EmployeeSupervisorMgt
{
    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyEmployee(var Rec: Record Employee;
    var xRec: Record Employee;
    RunTrigger: Boolean)var EmployeeRec: Record Employee;
    begin
        // Check if status changed to Inactive
        if(Rec."Employee Status" <> xRec."Employee Status") and (Rec."Employee Status" = Rec."Employee Status"::Inactive)then begin
            // Find employees supervised by this employee
            EmployeeRec.Reset();
            EmployeeRec.SetRange("Supervisor No.", Rec."No.");
            if EmployeeRec.FindSet()then begin
                repeat EmployeeRec.Validate("Supervisor No.", '');
                    EmployeeRec.Validate("Supervisor Name", '');
                    EmployeeRec.Modify(true);
                until EmployeeRec.Next() = 0;
            end;
        end;
    end;
}
