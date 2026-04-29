// --- Table: Timesheet Line ---
table 51101 "Monthly Timesheet Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20]) { TableRelation = "Monthly Timesheet Header"."No."; }
        field(2; "Line No."; Integer) { }
        //field(3; "Work Date"; Date) { }
        field(3; "Work Date"; Date)
        {
            trigger OnValidate()
            var
                Header: Record "Monthly Timesheet Header";
                workMonth: Integer;
                workYear: Integer;
                headerMonth: Integer;
            begin
                if Header.Get("Document No.") then begin
                    workMonth := Date2DMY("Work Date", 2); // numeric month (1–12)
                    workYear := Date2DMY("Work Date", 3);

                    // Map option to integer month
                    case Header.Month of
                        Header.Month::January:
                            headerMonth := 1;
                        Header.Month::February:
                            headerMonth := 2;
                        Header.Month::March:
                            headerMonth := 3;
                        Header.Month::April:
                            headerMonth := 4;
                        Header.Month::May:
                            headerMonth := 5;
                        Header.Month::June:
                            headerMonth := 6;
                        Header.Month::July:
                            headerMonth := 7;
                        Header.Month::August:
                            headerMonth := 8;
                        Header.Month::September:
                            headerMonth := 9;
                        Header.Month::October:
                            headerMonth := 10;
                        Header.Month::November:
                            headerMonth := 11;
                        Header.Month::December:
                            headerMonth := 12;
                    end;

                    if (workMonth <> headerMonth) or (workYear <> Header.Year) then
                        Error(
                          'Work Date %1 must be within %2 %3.',
                          "Work Date", Format(Header.Month), Header.Year);
                end;
            end;
        }

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
        field(6; "Activity"; Text[100]) { }
        field(10; "Notes"; Text[100]) { }
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