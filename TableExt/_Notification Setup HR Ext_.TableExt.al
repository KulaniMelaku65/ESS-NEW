tableextension 51103 "Notification Setup HR Ext" extends "Notification Setup HR"
{
    fields
    {
    }
    trigger OnAfterInsert()begin
        if Rec."Notification Type" = Rec."Notification Type"::"Leave Rejection" then Rec.Tooltip:='E-Mail sent to the employee. Placeholders: %1: Leave No, %2: Employee No, %3: Employee Name, %4: Leave Type, %5: No. of Days, %6: Start Date, %7: End Date, %8: Return Date, %9: Rejection Reason';
        if Rec."Notification Type" = Rec."Notification Type"::"Leave Approval" then Rec.Tooltip:='E-Mail sent to the employee once the leave is fully approved. Placeholders: %1: Leave No, %2: Employee No, %3: Employee Name, %4: Leave Type, %5: No. of Days, %6: Start Date, %7: End Date';
        if Rec."Notification Type" = Rec."Notification Type"::"Leave Submission" then Rec.Tooltip:='E-Mail sent to the employee confirming their leave request was submitted for approval. Placeholders: %1: Leave No, %2: Employee No, %3: Employee Name, %4: Leave Type, %5: No. of Days, %6: Start Date, %7: End Date';
        if Rec."Notification Type" = Rec."Notification Type"::"Attendance Alert" then Rec.Tooltip:='E-Mail sent to the employee''s supervisor when a check-in or check-out is missing for a working day. Placeholders: %1: Employee No, %2: Employee Name, %3: Date, %4: Issue';
    end;
}
