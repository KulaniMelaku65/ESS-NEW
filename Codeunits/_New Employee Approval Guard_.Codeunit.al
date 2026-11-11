codeunit 51147 "New Employee Approval Guard"
{
    // Blocks sending an employee's approval request until "Annual Leave
    // Entitlement" (table extension 51101, field 51106) is filled in.
    // Employee approvals go through Business Central's standard
    // Workflow/Approvals engine (Codeunit "Approvals Mgmt." + table
    // "Approval Entry"), same as everything else that flows through
    // approvals in this system, so hooking the standard Approval Entry
    // insert catches it regardless of which exact action/procedure in
    // Fanisi HR triggers the send (New Employee Card, Employee Card, or
    // any onboarding workflow).
    //
    // Deliberately the ONLY place this is enforced — an earlier attempt
    // also blocked it at record Insert/Modify time (codeunit "New Employee
    // Entitlement Req.", since removed), but that fired on the very first
    // blank Insert behind opening a New Employee Card, before the user
    // could fill in anything at all. Other details must be fillable
    // first; only sending for approval requires this to be set.

    [EventSubscriber(ObjectType::Table, Database::"Approval Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeApprovalEntryInsert(var Rec: Record "Approval Entry"; RunTrigger: Boolean)
    var
        Employee: Record Employee;
        EntitlementErr: Label 'Cannot send %1 for approval: Annual Leave Entitlement must be filled in first.';
    begin
        if Rec."Table ID" <> Database::Employee then
            exit;
        if not Employee.Get(Rec."Record ID to Approve") then
            exit;
        // Interns aren't entitled to annual leave at all (Annual Leave Accrual,
        // codeunit 51145, never credits them either, since it only accrues where
        // this is > 0) — 0/blank here is correct for them, not an omission.
        if Employee."Employee Type" = Employee."Employee Type"::Internship then
            exit;
        if Employee."Annual Leave Entitlement" <= 0 then
            Error(EntitlementErr, Employee.FullName());
    end;
}
