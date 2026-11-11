table 51102 "Timesheet Approval Entry"
{
    Caption = 'Timesheet Approval Entry';
    DataClassification = ToBeClassified;

    fields
    {
        field(1;"Timesheet No.";Code[20])
        {
            Caption = 'Timesheet No.';
        }
        field(2;"Sequence No.";Integer)
        {
            Caption = 'Sequence No.';
        }
        field(3;"Approver ID";Code[50])
        {
            Caption = 'Approver ID';
        }
        field(4;Status;Enum "Timesheet Status")
        {
            Caption = 'Status';
        }
        field(5;"Date-Time Sent";DateTime)
        {
            Caption = 'Date-Time Sent';
        }
        field(6;"Last Modified";DateTime)
        {
            Caption = 'Last Modified';
        }
        field(7;"Approved By";Code[50])
        {
            Caption = 'Approved By';
        }
        field(8;"Rejected By";Code[50])
        {
            Caption = 'Rejected By';
        }
        field(9;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
        }
        field(10;"Employee Name";Text[100])
        {
            Caption = 'Employee Name';
        }
        field(11;Description;Text[250])
        {
            Caption = 'Description';
        }
    }
    keys
    {
        key(PK;"Timesheet No.", "Sequence No.")
        {
            Clustered = true;
        }
    }
}
