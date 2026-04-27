// --- Table: Timesheet Header ---
table 51100 "Monthly Timesheet Header"
{
    DataClassification = CustomerContent;
    Caption = 'Timesheet Header';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            // In a production environment, you would use No. Series here
        }
        field(2; "Employee No."; Code[20])
        {
            TableRelation = Employee;
            Caption = 'Employee No.';
        }
        field(3; "Month"; Option)
        {
            OptionMembers = " ","January","February","March","April","May","June","July","August","September","October","November","December";
            Caption = 'Month';
        }
        field(4; "Year"; Integer)
        {
            Caption = 'Year';
            InitValue = 2026;
        }
        field(5; "Status"; Enum "Timesheet Status")
        {
            Editable = false;
            Caption = 'Status';
            InitValue = Open;  // Add this line
        }
        field(6; "Approver ID"; Code[50])
        {
            TableRelation = "User Setup";
            Caption = 'Approver ID';
        }
        field(7; "Total Hours"; Decimal)
        {
            // This field automatically sums up all lines linked to this header
            FieldClass = FlowField;
            CalcFormula = sum("Monthly Timesheet Line".Hours where("Document No." = field("No.")));
            Editable = false;
        }
        // --- Modified Header Table ---
        field(8; "No. Series"; Code[20])
        {
            TableRelation = "No. Series";
            Editable = false;
        }

    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
    trigger OnInsert()
    var
        HRSetup: Record "Human Resources Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if "No." = '' then begin
            HRSetup.Get();
            HRSetup.TestField("Timesheet No. Series");
            NoSeriesMgt.InitSeries(HRSetup."Timesheet No. Series", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

}