codeunit 51148 "Attendance Review Send Logger"
{
    // Exists solely to work around a real BC platform restriction hit when
    // "Attendance Review Mailer" (codeunit 51140) ran under a Job Queue
    // Entry: "Call to the function 'INSERT' is not allowed inside the call
    // to 'TryLogSend' when it is used as a TryFunction." Sending an email
    // (Email.Send) forces an implicit commit-like boundary, and BC does not
    // allow a [TryFunction] to write to the database after that boundary
    // when running under a Job Queue Entry — interactive/manual sends never
    // hit this, which is why it looked fine when tested by hand.
    //
    // The fix: isolate the write in a genuinely separate codeunit invoked
    // via Codeunit.Run(), which BC does allow post-commit, instead of a
    // [TryFunction] on the calling codeunit. SingleInstance = true so the
    // parameters set via SetParameters() are visible to the same instance
    // Codeunit.Run() invokes.
    SingleInstance = true;

    procedure SetParameters(Employee: Record Employee; Supervisor: Record Employee; HRBP: Record Employee; PeriodStart: Date; PeriodEnd: Date)
    begin
        EmployeeRec := Employee;
        SupervisorRec := Supervisor;
        HRBPRec := HRBP;
        PeriodStartDate := PeriodStart;
        PeriodEndDate := PeriodEnd;
    end;

    trigger OnRun()
    begin
        LogSend();
    end;

    local procedure LogSend()
    var
        SendLog: Record "Attendance Review Send Log";
    begin
        SendLog.Init();
        SendLog."Employee No." := EmployeeRec."No.";
        SendLog."Employee Name" := EmployeeRec.FullName();
        SendLog."Period Start" := PeriodStartDate;
        SendLog."Period End" := PeriodEndDate;
        SendLog."Sent To" := EmployeeRec."Company E-Mail";
        if (EmployeeRec."Supervisor No." <> '') and (SupervisorRec."No." = EmployeeRec."Supervisor No.") then begin
            SendLog."Supervisor No." := SupervisorRec."No.";
            if SupervisorRec."Company E-Mail" <> '' then
                SendLog."Supervisor CC" := SupervisorRec."Company E-Mail";
        end;
        if (EmployeeRec."HRBP No." <> '') and (HRBPRec."No." = EmployeeRec."HRBP No.") then begin
            SendLog."HRBP No." := HRBPRec."No.";
            if HRBPRec."Company E-Mail" <> '' then
                SendLog."HRBP CC" := HRBPRec."Company E-Mail";
        end;
        SendLog."Sent At" := CurrentDateTime;
        SendLog.Insert();
    end;

    var
        EmployeeRec: Record Employee;
        SupervisorRec: Record Employee;
        HRBPRec: Record Employee;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
}
