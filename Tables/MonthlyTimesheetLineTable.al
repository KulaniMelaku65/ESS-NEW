// --- Table: Timesheet Line ---
table 51101 "Monthly Timesheet Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20]) { TableRelation = "Monthly Timesheet Header"."No."; }
        field(2; "Line No."; Integer) { }
        field(3; "Work Date"; Date) { }
        field(4; "Job No."; Code[20]) { TableRelation = Job; }
        // --- Table Extension/Update: Timesheet Line ---
        field(5; "Hours"; Decimal)
        {
            DecimalPlaces = 0 : 2;
            MinValue = 0; // Prevents negative hours

            trigger OnValidate()
            begin
                if "Hours" > 24 then
                    Error('Hours cannot exceed 24 in a single day.');

                if "Hours" = 0 then
                    Message('Note: You are recording 0 hours for this entry.');
            end;
        }
        field(6; "Description"; Text[100]) { }
        field(7; "Morning Hours"; Decimal)
        {
            MinValue = 0;
            trigger OnValidate()
            begin
                Rec."Daily Total" := Rec."Morning Hours" + Rec."Afternoon Hours";
            end;
        }
        field(8; "Afternoon Hours"; Decimal)
        {
            MinValue = 0;
            trigger OnValidate()
            begin
                Rec."Daily Total" := Rec."Morning Hours" + Rec."Afternoon Hours";
            end;
        }
        field(9; "Daily Total"; Decimal)
        {
            Editable = false;
            Caption = 'Total for Day';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }

    // Inside the Monthly Timesheet Line Table
    trigger OnInsert()
    var
        Header: Record "Monthly Timesheet Header";
    begin
        if Header.Get(Rec."Document No.") then begin
            // Ensure the date matches the header's month
            if Date2DMY(Rec."Work Date", 2) <> Header.Month then
                Error('The Work Date must be within the month of %1.', Header.Month);

            if Date2DMY(Rec."Work Date", 3) <> Header.Year then
                Error('The Work Date must be within the year %1.', Header.Year);
        end;
    end;

}