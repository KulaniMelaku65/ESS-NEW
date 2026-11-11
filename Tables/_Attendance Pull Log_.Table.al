table 51146 "Attendance Pull Log"
{
    // Records the outcome of the LAST punch-machine pull attempt for each
    // employee + date, so a day with no Check-In/Check-Out can actually be
    // diagnosed afterward — every failure point in "Attendance Punch
    // Machine Pull" (codeunit 51138) used to fail silently, with no way to
    // tell whether an employee was skipped because they had no data, the
    // machine call failed, or their Employee No. couldn't be mapped to a
    // punch code. One row per Employee No. + Date; re-pulling the same day
    // overwrites the row with the latest attempt's outcome.
    DataClassification = SystemMetadata;
    Caption = 'Attendance Pull Log';
    LookupPageId = "Attendance Pull Log";
    DrillDownPageId = "Attendance Pull Log";

    fields
    {
        field(1;"Employee No.";Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = SystemMetadata;
            TableRelation = Employee;
        }
        field(2;Date;Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(3;Result;Option)
        {
            Caption = 'Result';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionMembers = Success,"No Data","Invalid Employee No. Format","HTTP Error","Parse Error";
        }
        field(4;Details;Text[250])
        {
            Caption = 'Details';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5;"Pulled At";DateTime)
        {
            Caption = 'Pulled At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(PK;"Employee No.", Date)
        {
            Clustered = true;
        }
    }
}
