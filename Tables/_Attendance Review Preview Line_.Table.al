table 51144 "Attendance Review Preview Line"
{
    // Temporary display buffer for page "Attendance Review Preview" — never
    // written to the database. One row per Monday-Friday date in the chosen
    // range, built from the exact same Attendance Day Type / Leave Half Day
    // Calculator checks the weekly review email (codeunit 51140) uses, so
    // what you see here matches what would actually get emailed.
    DataClassification = SystemMetadata;
    Caption = 'Attendance Review Preview Line';

    fields
    {
        field(1;"Line No.";Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2;Date;Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(3;Weekday;Text[10])
        {
            Caption = 'Weekday';
            DataClassification = SystemMetadata;
        }
        field(4;"Clock In";Text[40])
        {
            Caption = 'Clock In';
            DataClassification = SystemMetadata;
        }
        field(5;"Clock Out";Text[40])
        {
            Caption = 'Clock Out';
            DataClassification = SystemMetadata;
        }
        field(6;"Total Time";Text[20])
        {
            Caption = 'Total Time';
            DataClassification = SystemMetadata;
        }
        field(7;"Row Style";Text[20])
        {
            Caption = 'Row Style';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK;"Line No.")
        {
            Clustered = true;
        }
    }
}
