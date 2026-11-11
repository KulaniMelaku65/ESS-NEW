table 51142 "Attendance Absence Explanation"
{
    // One row per full-day absence that's been referred into the
    // explain-and-confirm workflow: employee gives a free-text reason,
    // their manager confirms Yes/No, and a Yes writes the reason back onto
    // the matching Employee Attendance Log row. Created and driven by
    // codeunit "Attendance Absence Notifier".
    DataClassification = CustomerContent;
    Caption = 'Attendance Absence Explanation';
    LookupPageId = "Absence Explanation List";
    DrillDownPageId = "Absence Explanation List";

    fields
    {
        field(1;"Entry No.";Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
            Editable = false;
        }
        field(2;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
            NotBlank = true;
        }
        field(3;Date;Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(4;Status;Option)
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = "Pending Employee Response","Pending Manager Confirmation",Confirmed,Rejected;
            OptionCaption = 'Pending Employee Response,Pending Manager Confirmation,Confirmed,Rejected';
        }
        field(5;Reason;Text[250])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }
        field(6;"Manager No.";Code[20])
        {
            // Snapshot of the employee's Supervisor No. at the time this
            // row was created, so a later Supervisor No. change on the
            // employee doesn't retarget an in-flight confirmation.
            Caption = 'Manager No.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
            Editable = false;
        }
        field(7;"Manager Decision";Option)
        {
            Caption = 'Manager Decision';
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = " ",Yes,No;
            OptionCaption = ' ,Yes,No';
        }
        field(8;"Employee Notified On";DateTime)
        {
            Caption = 'Employee Notified On';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9;"Reason Submitted On";DateTime)
        {
            Caption = 'Reason Submitted On';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10;"Manager Notified On";DateTime)
        {
            Caption = 'Manager Notified On';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11;"Decided On";DateTime)
        {
            Caption = 'Decided On';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(PK;"Entry No.")
        {
            Clustered = true;
        }
        key(EmployeeDateKey;"Employee No.", Date)
        {
        }
    }
}
