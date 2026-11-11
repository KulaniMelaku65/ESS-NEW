table 51122 "Leave Application Day"
{
    DataClassification = CustomerContent;
    Caption = 'Leave Application Day';
    LookupPageId = "Leave App Day Subform";
    DrillDownPageId = "Leave App Day Subform";

    fields
    {
        field(1;"Leave No.";Code[20])
        {
            Caption = 'Leave No.';
            DataClassification = CustomerContent;
            TableRelation = "Leave Application";
            NotBlank = true;
        }
        field(2;"Line No.";Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3;Date;Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()var OtherLine: Record "Leave Application Day";
            DupLabel: Label 'Date %1 is already added to this leave application.';
            begin
                if Date = 0D then begin
                    "Is Half Day":=false;
                    "No. of Days":=0;
                    "Day Name":='';
                    exit;
                end;
                // Prevent duplicates
                OtherLine.SetRange("Leave No.", "Leave No.");
                OtherLine.SetRange(Date, Date);
                OtherLine.SetFilter("Line No.", '<>%1', "Line No.");
                if OtherLine.FindFirst()then Error(DupLabel, Format(Date));
                // Compute day name
                case Date2DWY(Date, 1)of 1: "Day Name":='Monday';
                2: "Day Name":='Tuesday';
                3: "Day Name":='Wednesday';
                4: "Day Name":='Thursday';
                5: "Day Name":='Friday';
                6: "Day Name":='Saturday';
                7: "Day Name":='Sunday';
                end;
                RecalcHalfDay();
            end;
        }
        field(4;"Day Name";Text[10])
        {
            Caption = 'Day';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5;"Is Half Day";Boolean)
        {
            Caption = 'Half Day';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6;"No. of Days";Decimal)
        {
            Caption = 'No. of Days';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0: 1;
        }
        field(7;"Half Day Requested";Boolean)
        {
            Caption = 'Half Day Requested';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Date <> 0D then RecalcHalfDay();
            end;
        }
    }
    keys
    {
        key(PK;"Leave No.", "Line No.")
        {
            Clustered = true;
        }
        key(DateKey;"Leave No.", Date)
        {
        }
    }
    trigger OnInsert()var LastLine: Record "Leave Application Day";
    begin
        if "Line No." = 0 then begin
            LastLine.SetRange("Leave No.", "Leave No.");
            if LastLine.FindLast()then "Line No.":=LastLine."Line No." + 10000
            else
                "Line No.":=10000;
        end;
    end;
    // Combines the company-wide calendar half-day (e.g. every Friday afternoon)
    // with the employee's own elective half-day choice for this specific date.
    // Runs from both the Date and Half Day Requested triggers so either can be
    // set first without losing the other's contribution.
    local procedure RecalcHalfDay()var BaseCalChange: Record "Base Calendar Change";
    CalCode: Code[10];
    WeekDay: Integer;
    FoundNonWorking: Boolean;
    FoundHalfDay: Boolean;
    NWLabel: Label 'Cannot add a non-working day (%1) to the leave application.';
    begin
        // Get company calendar code
        CalCode:=GetCompanyCalendarCode();
        WeekDay:=Date2DWY(Date, 1);
        // Check Base Calendar Change entries
        if CalCode <> '' then begin
            BaseCalChange.Reset();
            BaseCalChange.SetRange("Base Calendar Code", CalCode);
            if BaseCalChange.FindSet()then repeat case BaseCalChange."Recurring System" of BaseCalChange."Recurring System"::"Weekly Recurring": if BaseCalChange.Day = WeekDay then begin
                            if BaseCalChange.Nonworking then FoundNonWorking:=true;
                            if BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking then FoundHalfDay:=true;
                        end;
                    BaseCalChange."Recurring System"::"Annual Recurring": if(BaseCalChange.Date <> 0D) and(Date2DMY(Date, 1) = Date2DMY(BaseCalChange.Date, 1)) and (Date2DMY(Date, 2) = Date2DMY(BaseCalChange.Date, 2))then begin
                            if BaseCalChange.Nonworking then FoundNonWorking:=true
                            else
                                FoundNonWorking:=false;
                            if BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking then FoundHalfDay:=true;
                        end;
                    else if BaseCalChange.Date = Date then begin
                            if BaseCalChange.Nonworking then FoundNonWorking:=true
                            else
                                FoundNonWorking:=false;
                            if BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking then FoundHalfDay:=true;
                        end;
                    end;
                until BaseCalChange.Next() = 0;
        end;
        if FoundNonWorking then Error(NWLabel, Format(Date));
        "Is Half Day":=FoundHalfDay or "Half Day Requested";
        if "Is Half Day" then "No. of Days":=0.5
        else
            "No. of Days":=1.0;
    end;

    // Company Information."Base Calendar Code" is the normal place this
    // should come from, but it can be left blank while calendar data still
    // exists in Base Calendar Change. Falls back to whichever code is
    // actually in use, as long as there's exactly one.
    local procedure GetCompanyCalendarCode(): Code[10]var CompanyInfo: Record "Company Information";
    BaseCalChange: Record "Base Calendar Change";
    FirstCode: Code[10];
    begin
        if CompanyInfo.Get()and(CompanyInfo."Base Calendar Code" <> '')then exit(CompanyInfo."Base Calendar Code");
        if BaseCalChange.FindFirst()then begin
            FirstCode:=BaseCalChange."Base Calendar Code";
            BaseCalChange.SetFilter("Base Calendar Code", '<>%1', FirstCode);
            if BaseCalChange.IsEmpty()then exit(FirstCode);
        end;
        exit('');
    end;
}
