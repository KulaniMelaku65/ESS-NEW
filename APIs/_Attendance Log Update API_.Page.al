page 51136 "Attendance Log Update API"
{
    // Lets the ESS portal write back the outcome of ITS OWN explain-and-
    // approve flow (employee explains a missing-attendance day, supervisor
    // approves it in the portal) directly onto the matching Employee
    // Attendance Log row — sibling to "Employee Attendance Log API" (page
    // 51131), which is read/insert-oriented for punch data. This one is
    // update-only: the row must already exist (created by the punch
    // pull/leave processor pipeline), so Insert and Delete are blocked —
    // only "Processing Result" and "Absence Reason" are writable, every
    // other field stays read-only.
    //
    // Expected caller flow: PATCH this entity (keyed by Employee No. +
    // Date) with Processing Result = "Approved by Manager" and Absence
    // Reason = the employee's explanation, once the supervisor approves it
    // in the ESS portal. The "Attendance Review Mailer" (codeunit 51140)
    // picks this up automatically and shows it as a distinct color on the
    // weekly report instead of a plain unexplained absence.
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Employee Attendance Log Update API';
    DeleteAllowed = false;
    InsertAllowed = false;
    EntityName = 'employeeAttendanceLogUpdate';
    EntitySetName = 'employeeAttendanceLogUpdates';
    PageType = API;
    SourceTable = "Employee Attendance Log";
    ODataKeyFields = "Employee No.", Date;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(employeeNo;Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                    Editable = false;
                }
                field(date;Rec.Date)
                {
                    Caption = 'Date';
                    Editable = false;
                }
                field(checkInTime;Rec."Check-In Time")
                {
                    Caption = 'Check-In Time';
                    Editable = false;
                }
                field(checkOutTime;Rec."Check-Out Time")
                {
                    Caption = 'Check-Out Time';
                    Editable = false;
                }
                field(processingResult;Rec."Processing Result")
                {
                    Caption = 'Processing Result';
                    Editable = true;
                }
                field(absenceReason;Rec."Absence Reason")
                {
                    Caption = 'Absence Reason';
                    Editable = true;
                }
                field(processed;Rec.Processed)
                {
                    Caption = 'Processed';
                    Editable = false;
                }
                field(leaveNo;Rec."Leave No.")
                {
                    Caption = 'Leave No.';
                    Editable = false;
                }
            }
        }
    }
}
