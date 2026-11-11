codeunit 51141 "HRBP Cleanup"
{
    // When an employee designated as someone's HRBP (Employee."HRBP No.")
    // is marked Inactive, clear "HRBP No." on every employee that points
    // at them. Otherwise an inactive HRBP would keep getting CC'd on
    // attendance review emails (and any other future use of that field)
    // just because nobody remembered to reassign their reports when they
    // left.

    [EventSubscriber(ObjectType::Table, Database::Employee, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnEmployeeModified(var Rec: Record Employee; var xRec: Record Employee; RunTrigger: Boolean)
    var
        DependentEmployee: Record Employee;
    begin
        if not RunTrigger then
            exit;
        if Rec."Employee Status" <> Rec."Employee Status"::Inactive then
            exit;
        if xRec."Employee Status" = xRec."Employee Status"::Inactive then
            exit; // was already Inactive — already cleaned up, nothing new to do

        DependentEmployee.SetRange("HRBP No.", Rec."No.");
        if DependentEmployee.FindSet(true) then
            repeat
                DependentEmployee."HRBP No." := '';
                DependentEmployee.Modify(true);
            until DependentEmployee.Next() = 0;
    end;
}
