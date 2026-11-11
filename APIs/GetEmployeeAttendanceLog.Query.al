query 51101 GetEmployeeAttendanceLog
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getEmployeeAttendanceLog';
    EntitySetName = 'getEmployeeAttendanceLogs';
    QueryType = API;

    elements
    {
        dataitem(employeeAttendanceLog; "Employee Attendance Log")
        {
            column(employeeNo; "Employee No.")
            {
                Caption = 'EmployeeNo';
            }
            column(attendanceDate; Date)
            {
                Caption = 'Date';
            }
            column(checkInTime; "Check-In Time")
            {
                Caption = 'CheckInTime';
            }
            column(checkOutTime; "Check-Out Time")
            {
                Caption = 'CheckOutTime';
            }
            column(processed; Processed)
            {
                Caption = 'Processed';
            }
            column(leaveNo; "Leave No.")
            {
                Caption = 'LeaveNo';
            }
            column(processingResult; "Processing Result")
            {
                Caption = 'ProcessingResult';
            }
            column(dayValue; "Day Value")
            {
                Caption = 'DayValue';
            }
            column(absenceReason; "Absence Reason")
            {
                Caption = 'AbsenceReason';
            }
        }
    }
}
