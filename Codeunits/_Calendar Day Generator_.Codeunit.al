codeunit 51127 "Calendar Day Generator"
{
    // Generates day-by-day Calendar Day Entry records for a given Base Calendar.
    // Auto-triggered when Base Calendar Change records are saved, so the API always
    // reflects the current calendar setup without a manual refresh step.
    // Range: today through end of next year, regenerated for the affected calendar code.
    procedure GenerateCalendarDays(CalendarCode: Code[10];
    FromDate: Date;
    ToDate: Date)var CalEntry: Record "Calendar Day Entry";
    BaseCalChange: Record "Base Calendar Change";
    CheckDate: Date;
    IsWorking: Boolean;
    IsHalfDay: Boolean;
    Descr: Text[100];
    begin
        if CalendarCode = '' then exit;
        if FromDate > ToDate then exit;
        // Clear existing entries for this calendar in the range
        CalEntry.SetRange("Calendar Code", CalendarCode);
        CalEntry.SetRange(Date, FromDate, ToDate);
        CalEntry.DeleteAll(false);
        // Load all calendar change entries once for performance
        BaseCalChange.Reset();
        BaseCalChange.SetRange("Base Calendar Code", CalendarCode);
        BaseCalChange.FindSet(false); // May return false — handled below per-day
        // Generate one record per day
        CheckDate:=FromDate;
        while CheckDate <= ToDate do begin
            IsWorking:=true;
            IsHalfDay:=false;
            Descr:='';
            // Pass 1 — Weekly Recurring
            BaseCalChange.Reset();
            BaseCalChange.SetRange("Base Calendar Code", CalendarCode);
            BaseCalChange.SetRange("Recurring System", BaseCalChange."Recurring System"::"Weekly Recurring");
            if BaseCalChange.FindSet()then repeat if BaseCalChange.Day = Date2DWY(CheckDate, 1)then begin
                        IsWorking:=not BaseCalChange.Nonworking;
                        if BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking then IsHalfDay:=true;
                        if BaseCalChange.Description <> '' then Descr:=BaseCalChange.Description;
                    end;
                until BaseCalChange.Next() = 0;
            // Pass 2 — Annual Recurring (overrides weekly)
            BaseCalChange.Reset();
            BaseCalChange.SetRange("Base Calendar Code", CalendarCode);
            BaseCalChange.SetRange("Recurring System", BaseCalChange."Recurring System"::"Annual Recurring");
            if BaseCalChange.FindSet()then repeat if(BaseCalChange.Date <> 0D) and(Date2DMY(CheckDate, 1) = Date2DMY(BaseCalChange.Date, 1)) and (Date2DMY(CheckDate, 2) = Date2DMY(BaseCalChange.Date, 2))then begin
                        IsWorking:=not BaseCalChange.Nonworking;
                        IsHalfDay:=BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking;
                        Descr:=BaseCalChange.Description;
                    end;
                until BaseCalChange.Next() = 0;
            // Pass 3 — Specific Date (highest precedence)
            BaseCalChange.Reset();
            BaseCalChange.SetRange("Base Calendar Code", CalendarCode);
            BaseCalChange.SetRange("Recurring System", 0); // Blank = specific date
            BaseCalChange.SetRange(Date, CheckDate);
            if BaseCalChange.FindFirst()then begin
                IsWorking:=not BaseCalChange.Nonworking;
                IsHalfDay:=BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking;
                Descr:=BaseCalChange.Description;
            end;
            // Build description if empty
            if Descr = '' then if IsHalfDay then Descr:='Half Working Day'
                else if IsWorking then Descr:='Working Day'
                    else
                        Descr:='Non-Working Day';
            CalEntry.Init();
            CalEntry."Calendar Code":=CalendarCode;
            CalEntry.Date:=CheckDate;
            CalEntry."Is Working Day":=IsWorking;
            CalEntry."Is Half Day":=IsHalfDay and IsWorking;
            CalEntry.Description:=CopyStr(Descr, 1, 100);
            SetDayName(CalEntry, CheckDate);
            CalEntry.Insert(false);
            CheckDate:=CheckDate + 1;
        end;
    end;
    // When BC's standard Customize logic recreates Customized Calendar Change records it
    // copies standard fields only — our Is Half Day is lost. This subscriber restores it
    // by looking up the matching Base Calendar Change rule.
    [EventSubscriber(ObjectType::Table, Database::"Customized Calendar Change", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnCustomizedCalChangeInserted(var Rec: Record "Customized Calendar Change";
    RunTrigger: Boolean)var BaseCalChange: Record "Base Calendar Change";
    begin
        if not RunTrigger then exit;
        if Rec."Source Type" <> 0 then exit; // 0 = Company; skip customer/vendor entries
        if Rec."Is Half Day" then exit; // Already populated — nothing to do
        BaseCalChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        BaseCalChange.SetRange("Recurring System", Rec."Recurring System");
        BaseCalChange.SetRange(Nonworking, false);
        BaseCalChange.SetRange("Is Half Day", true);
        case Rec."Recurring System" of Rec."Recurring System"::"Weekly Recurring": BaseCalChange.SetRange(Day, Rec.Day);
        else
            BaseCalChange.SetRange(Date, Rec.Date);
        end;
        if not BaseCalChange.FindFirst()then exit;
        Rec."Is Half Day":=true;
        Rec.Modify(false);
    end;
    // Auto-regenerate when any Base Calendar Change entry is saved or deleted
    [EventSubscriber(ObjectType::Table, Database::"Base Calendar Change", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnCalChangeInserted(var Rec: Record "Base Calendar Change";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        RegenerateForCode(Rec."Base Calendar Code");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Base Calendar Change", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnCalChangeModified(var Rec: Record "Base Calendar Change";
    var xRec: Record "Base Calendar Change";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        RegenerateForCode(Rec."Base Calendar Code");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Base Calendar Change", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnCalChangeDeleted(var Rec: Record "Base Calendar Change";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        RegenerateForCode(Rec."Base Calendar Code");
    end;
    local procedure RegenerateForCode(CalendarCode: Code[10])begin
        GenerateCalendarDays(CalendarCode, Today(), CalcDate('<+2Y>', Today()));
    end;
    local procedure SetDayName(var CalEntry: Record "Calendar Day Entry";
    EntryDate: Date)begin
        case Date2DWY(EntryDate, 1)of 1: CalEntry."Day Name":='Monday';
        2: CalEntry."Day Name":='Tuesday';
        3: CalEntry."Day Name":='Wednesday';
        4: CalEntry."Day Name":='Thursday';
        5: CalEntry."Day Name":='Friday';
        6: CalEntry."Day Name":='Saturday';
        7: CalEntry."Day Name":='Sunday';
        end;
    end;
}
