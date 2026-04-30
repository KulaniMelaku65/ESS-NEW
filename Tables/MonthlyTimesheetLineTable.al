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
        tsLine: Record "Monthly Timesheet Line";
        monthStart: Date;
        monthEnd: Date;
        lastDay: Integer;
        lineCount: Integer;
        headerMonthInt: Integer;
    begin
        if Header.Get(Rec."Document No.") then begin
            // --- Map Option Month to Integer ---
            case Header.Month of
                Header.Month::January:
                    headerMonthInt := 1;
                Header.Month::February:
                    headerMonthInt := 2;
                Header.Month::March:
                    headerMonthInt := 3;
                Header.Month::April:
                    headerMonthInt := 4;
                Header.Month::May:
                    headerMonthInt := 5;
                Header.Month::June:
                    headerMonthInt := 6;
                Header.Month::July:
                    headerMonthInt := 7;
                Header.Month::August:
                    headerMonthInt := 8;
                Header.Month::September:
                    headerMonthInt := 9;
                Header.Month::October:
                    headerMonthInt := 10;
                Header.Month::November:
                    headerMonthInt := 11;
                Header.Month::December:
                    headerMonthInt := 12;
            end;

            // --- Validate Work Date belongs to header month/year ---
            if Date2DMY(Rec."Work Date", 2) <> headerMonthInt then
                Error('The Work Date must be within the month of %1.', Header.Month);

            if Date2DMY(Rec."Work Date", 3) <> Header.Year then
                Error('The Work Date must be within the year %1.', Header.Year);

            // --- Calculate last valid day of the month ---
            monthStart := DMY2Date(1, headerMonthInt, Header.Year);
            monthEnd := CalcDate('<CM>', monthStart); // end of current month
            lastDay := Date2DMY(monthEnd, 1);         // day component (28–31)

            // --- Count existing lines ---
            tsLine.Reset();
            tsLine.SetRange("Document No.", Rec."Document No.");
            lineCount := tsLine.Count;

            if lineCount >= lastDay then
                Error(
                  'Employee %1 already has %2 days entered for %3 %4. No more lines can be added.',
                  Header."Employee No.", lastDay, Header.Month, Header.Year);

            // --- Prevent duplicate Work Date ---
            tsLine.Reset();
            tsLine.SetRange("Document No.", Rec."Document No.");
            tsLine.SetRange("Work Date", Rec."Work Date");
            if tsLine.FindFirst() then
                Error('Work Date %1 is already entered for this timesheet.', Rec."Work Date");
        end;
    end;




}