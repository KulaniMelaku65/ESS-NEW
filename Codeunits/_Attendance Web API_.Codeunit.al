codeunit 51125 "Attendance Web API"
{
    // Lets the third-party ESS portal push daily check-in / check-out events into
    // BC, one row per Employee No. + Date. Nightly job "Attendance Leave
    // Processor" (51126) reads this table the next day and turns missing
    // check-in/out into an automatic leave application.

    [ServiceEnabled]
    procedure LogCheckIn(EmployeeNo: Code[20]; CheckInDateTime: DateTime) ReturnMsg: Text var AttendanceLog: Record "Employee Attendance Log";
    begin
        if not AttendanceLog.Get(EmployeeNo, DT2Date(CheckInDateTime))then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No.":=EmployeeNo;
            AttendanceLog.Date:=DT2Date(CheckInDateTime);
            AttendanceLog."Check-In Time":=DT2Time(CheckInDateTime);
            AttendanceLog.Insert(true);
        end
        else begin
            AttendanceLog."Check-In Time":=DT2Time(CheckInDateTime);
            AttendanceLog.Modify(true);
        end;
        ReturnMsg:='SUCCESS';
    end;

    [ServiceEnabled]
    procedure LogCheckOut(EmployeeNo: Code[20]; CheckOutDateTime: DateTime) ReturnMsg: Text var AttendanceLog: Record "Employee Attendance Log";
    begin
        if not AttendanceLog.Get(EmployeeNo, DT2Date(CheckOutDateTime))then begin
            AttendanceLog.Init();
            AttendanceLog."Employee No.":=EmployeeNo;
            AttendanceLog.Date:=DT2Date(CheckOutDateTime);
            AttendanceLog."Check-Out Time":=DT2Time(CheckOutDateTime);
            AttendanceLog.Insert(true);
        end
        else begin
            AttendanceLog."Check-Out Time":=DT2Time(CheckOutDateTime);
            AttendanceLog.Modify(true);
        end;
        ReturnMsg:='SUCCESS';
    end;
}
