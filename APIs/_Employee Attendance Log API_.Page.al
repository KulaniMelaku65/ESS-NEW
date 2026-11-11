page 51131 "Employee Attendance Log API"
{
    // Lets the attendance-sync service push punch-machine check-in/check-out
    // events directly into BC, one row per Employee No. + Date — the same
    // shape "Attendance Web API" (codeunit 51125) already writes via SOAP,
    // but reachable over OData v4 like every other Kifiya-published API
    // page in this extension, so the caller needs no separate web-service
    // publishing step or SOAP calling convention.
    //
    // "Processed" / "Processing Result" / "Leave No." are owned by the
    // nightly "Attendance Leave Processor" (codeunit 51126) — exposed here
    // read-only so a caller can see the outcome, never set it directly.
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Employee Attendance Log API';
    DelayedInsert = true;
    EntityName = 'employeeAttendanceLog';
    EntitySetName = 'employeeAttendanceLogs';
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
                }
                field(date;Rec.Date)
                {
                    Caption = 'Date';
                }
                field(checkInTime;Rec."Check-In Time")
                {
                    Caption = 'Check-In Time';
                }
                field(checkOutTime;Rec."Check-Out Time")
                {
                    Caption = 'Check-Out Time';
                }
                field(dayValue;Rec."Day Value")
                {
                    Caption = 'Day Value';
                    Editable = false;
                }
                field(processed;Rec.Processed)
                {
                    Caption = 'Processed';
                    Editable = false;
                }
                field(processingResult;Rec."Processing Result")
                {
                    Caption = 'Processing Result';
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
