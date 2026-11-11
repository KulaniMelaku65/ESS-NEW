table 51147 "Attendance Review Send Log"
{
    // One row per attendance review email actually sent by "Attendance
    // Review Mailer" (codeunit 51140) — bulk weekly run or the single-
    // employee test send both log here. Answers "who got this email and
    // who was CC'd" without having to open individual entries in BC's
    // generic Sent Emails log. Append-only: a deliberate single-employee
    // test resend for a period already sent adds another row rather than
    // overwriting, so the history stays intact. The BULK run, however,
    // checks this table first and skips anyone already logged for the
    // exact period, so a Job Queue Entry run twice for the same period
    // doesn't double-email everyone (see AlreadySentForPeriod).
    DataClassification = CustomerContent;
    Caption = 'Attendance Review Send Log';
    LookupPageId = "Attendance Review Send Log";
    DrillDownPageId = "Attendance Review Send Log";

    fields
    {
        field(1;"Entry No.";Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
        }
        field(3;"Employee Name";Text[100])
        {
            Caption = 'Employee Name';
            DataClassification = CustomerContent;
        }
        field(4;"Period Start";Date)
        {
            Caption = 'Period Start';
            DataClassification = CustomerContent;
        }
        field(5;"Period End";Date)
        {
            Caption = 'Period End';
            DataClassification = CustomerContent;
        }
        field(6;"Sent To";Text[80])
        {
            Caption = 'Sent To';
            DataClassification = CustomerContent;
        }
        field(7;"Supervisor No.";Code[20])
        {
            Caption = 'Supervisor No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
        }
        field(8;"Supervisor CC";Text[80])
        {
            Caption = 'Supervisor CC';
            DataClassification = CustomerContent;
        }
        field(9;"HRBP No.";Code[20])
        {
            Caption = 'HRBP No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
        }
        field(10;"HRBP CC";Text[80])
        {
            Caption = 'HRBP CC';
            DataClassification = CustomerContent;
        }
        field(11;"Sent At";DateTime)
        {
            Caption = 'Sent At';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK;"Entry No.")
        {
            Clustered = true;
        }
        key(ByEmployeePeriod;"Employee No.", "Period Start")
        {
        }
    }
}
