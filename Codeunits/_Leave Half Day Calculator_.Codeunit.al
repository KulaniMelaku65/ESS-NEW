codeunit 51121 "Leave Half Day Calculator"
{
    SingleInstance = true;

    var IsAdjusting: Boolean;
    [EventSubscriber(ObjectType::Table, Database::"Leave Application", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnLeaveApplicationInserted(var Rec: Record "Leave Application";
    RunTrigger: Boolean)begin
        if IsAdjusting then exit;
        if HasDayLines(Rec."No.")then exit;
        AdjustDatesForHalfDays(Rec);
    end;
    [EventSubscriber(ObjectType::Table, Database::"Leave Application", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnLeaveApplicationModified(var Rec: Record "Leave Application";
    var xRec: Record "Leave Application";
    RunTrigger: Boolean)begin
        if IsAdjusting then exit;
        if HasDayLines(Rec."No.")then exit;
        AdjustDatesForHalfDays(Rec);
    end;
    [EventSubscriber(ObjectType::Table, Database::"Leave Application Day", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnLeaveDayInserted(var Rec: Record "Leave Application Day";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        RecalcLeaveFromLines(Rec."Leave No.");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Leave Application Day", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnLeaveDayModified(var Rec: Record "Leave Application Day";
    var xRec: Record "Leave Application Day";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        if Rec.Date = xRec.Date then exit;
        RecalcLeaveFromLines(Rec."Leave No.");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Leave Application Day", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnLeaveDayDeleted(var Rec: Record "Leave Application Day";
    RunTrigger: Boolean)begin
        if not RunTrigger then exit;
        RecalcLeaveFromLines(Rec."Leave No.");
    end;
    local procedure HasDayLines(LeaveNo: Code[20]): Boolean var LeaveDay: Record "Leave Application Day";
    begin
        LeaveDay.SetRange("Leave No.", LeaveNo);
        exit(not LeaveDay.IsEmpty());
    end;
    local procedure RecalcLeaveFromLines(LeaveNo: Code[20])var LeaveApp: Record "Leave Application";
    LeaveDay: Record "Leave Application Day";
    MinDate: Date;
    MaxDate: Date;
    TotalDays: Decimal;
    begin
        if not LeaveApp.Get(LeaveNo)then exit;
        LeaveDay.SetRange("Leave No.", LeaveNo);
        if not LeaveDay.FindFirst()then begin
            LeaveApp."No. of Days":=0;
            LeaveApp.Modify(false);
            exit;
        end;
        MinDate:=LeaveDay.Date;
        MaxDate:=LeaveDay.Date;
        repeat TotalDays+=LeaveDay."No. of Days";
            if LeaveDay.Date < MinDate then MinDate:=LeaveDay.Date;
            if LeaveDay.Date > MaxDate then MaxDate:=LeaveDay.Date;
        until LeaveDay.Next() = 0;
        LeaveApp."No. of Days":=TotalDays;
        LeaveApp."Start Date":=MinDate;
        LeaveApp."End Date":=MaxDate;
        LeaveApp.Modify(false);
    end;
    // New behaviour: keep No. of Days at whatever the user entered; instead extend
    // End Date / Return Date so the employee is absent long enough to consume exactly
    // that many days from their balance, counting half-day calendar entries as 0.5.
    local procedure AdjustDatesForHalfDays(var LeaveApp: Record "Leave Application")var CompanyInfo: Record "Company Information";
    CalCode: Code[10];
    HalfDayCount: Decimal;
    NewEndDate: Date;
    NewReturnDate: Date;
    begin
        // Leave Fanisi's own half-day-leave feature untouched
        if LeaveApp."Is Half Day Leave?" then exit;
        if(LeaveApp."Start Date" = 0D) or (LeaveApp."End Date" = 0D) or (LeaveApp."No. of Days" = 0)then exit;
        CalCode:='';
        if CompanyInfo.Get()then CalCode:=CompanyInfo."Base Calendar Code";
        // Fast path: no half-days in Fanisi's range → nothing to adjust
        HalfDayCount:=CountHalfDaysInRange(CalCode, LeaveApp."Start Date", LeaveApp."End Date");
        if HalfDayCount = 0 then exit;
        CalcEndAndReturnDate(CalCode, LeaveApp."Start Date", LeaveApp."No. of Days", NewEndDate, NewReturnDate);
        if NewEndDate = 0D then exit;
        // Idempotent: skip if already correct (handles Fanisi's second Modify after re-read)
        if(NewEndDate = LeaveApp."End Date") and (NewReturnDate = LeaveApp."Return Date")then exit;
        LeaveApp."End Date":=NewEndDate;
        LeaveApp."Return Date":=NewReturnDate;
        IsAdjusting:=true;
        LeaveApp.Modify(false);
        IsAdjusting:=false;
    end;
    // Walk forward from StartDate one working day at a time, consuming NoOfDays at
    // 0.5 cost for half-day calendar entries and 1.0 for full days.
    // Overshoot (partial final day) → ReturnDate = that day (employee back that afternoon).
    // Exact consumption → ReturnDate = next working day.
    local procedure CalcEndAndReturnDate(CalCode: Code[10];
    StartDate: Date;
    NoOfDays: Decimal;
    var EndDate: Date;
    var ReturnDate: Date)var CheckDate: Date;
    Remaining: Decimal;
    DayCost: Decimal;
    IsWorking: Boolean;
    IsHalfDay: Boolean;
    Safety: Integer;
    begin
        EndDate:=0D;
        ReturnDate:=0D;
        if(StartDate = 0D) or (NoOfDays <= 0)then exit;
        CheckDate:=StartDate;
        Remaining:=NoOfDays;
        Safety:=1000;
        while(Remaining > 0) and (Safety > 0)do begin
            Safety-=1;
            GetDayStatus(CalCode, CheckDate, IsWorking, IsHalfDay);
            if IsWorking then begin
                DayCost:=1.0;
                if IsHalfDay then DayCost:=0.5;
                if Remaining <= DayCost then begin
                    EndDate:=CheckDate;
                    if Remaining = DayCost then ReturnDate:=NextWorkingDay(CalCode, CheckDate + 1)
                    else
                        ReturnDate:=CheckDate; // Partial day: back that afternoon
                    exit;
                end;
                Remaining-=DayCost;
            end;
            CheckDate:=CheckDate + 1;
        end;
    end;
    // Returns working/half-day status for a date by checking calendar entries in
    // priority order: Customized Cal Change (specific > annual > weekly) then
    // Base Cal Change (same order). Default when no entry found: working, not half-day.
    local procedure GetDayStatus(CalCode: Code[10];
    CheckDate: Date;
    var IsWorking: Boolean;
    var IsHalfDay: Boolean)var CustomCalChange: Record "Customized Calendar Change";
    BaseCalChange: Record "Base Calendar Change";
    DayOfWeek: Integer;
    begin
        IsWorking:=true;
        IsHalfDay:=false;
        DayOfWeek:=Date2DWY(CheckDate, 1);
        // 1a. Customized — specific date
        CustomCalChange.Reset();
        CustomCalChange.SetRange("Source Type", 0);
        CustomCalChange.SetRange("Source Code", '');
        if CalCode <> '' then CustomCalChange.SetRange("Base Calendar Code", CalCode);
        CustomCalChange.SetRange("Recurring System", 0);
        CustomCalChange.SetRange(Date, CheckDate);
        if CustomCalChange.FindFirst()then begin
            IsWorking:=not CustomCalChange.Nonworking;
            IsHalfDay:=CustomCalChange."Is Half Day" and IsWorking;
            exit;
        end;
        // 1b. Customized — annual recurring
        CustomCalChange.Reset();
        CustomCalChange.SetRange("Source Type", 0);
        CustomCalChange.SetRange("Source Code", '');
        if CalCode <> '' then CustomCalChange.SetRange("Base Calendar Code", CalCode);
        CustomCalChange.SetRange("Recurring System", CustomCalChange."Recurring System"::"Annual Recurring");
        if CustomCalChange.FindSet()then repeat if(Date2DMY(CheckDate, 1) = Date2DMY(CustomCalChange.Date, 1)) and (Date2DMY(CheckDate, 2) = Date2DMY(CustomCalChange.Date, 2))then begin
                    IsWorking:=not CustomCalChange.Nonworking;
                    IsHalfDay:=CustomCalChange."Is Half Day" and IsWorking;
                    exit;
                end;
            until CustomCalChange.Next() = 0;
        // 1c. Customized — weekly recurring
        CustomCalChange.Reset();
        CustomCalChange.SetRange("Source Type", 0);
        CustomCalChange.SetRange("Source Code", '');
        if CalCode <> '' then CustomCalChange.SetRange("Base Calendar Code", CalCode);
        CustomCalChange.SetRange("Recurring System", CustomCalChange."Recurring System"::"Weekly Recurring");
        CustomCalChange.SetRange(Day, DayOfWeek);
        if CustomCalChange.FindFirst()then begin
            IsWorking:=not CustomCalChange.Nonworking;
            IsHalfDay:=CustomCalChange."Is Half Day" and IsWorking;
            exit;
        end;
        // 2a. Base Calendar — specific date
        BaseCalChange.Reset();
        if CalCode <> '' then BaseCalChange.SetRange("Base Calendar Code", CalCode);
        BaseCalChange.SetRange("Recurring System", 0);
        BaseCalChange.SetRange(Date, CheckDate);
        if BaseCalChange.FindFirst()then begin
            IsWorking:=not BaseCalChange.Nonworking;
            IsHalfDay:=BaseCalChange."Is Half Day" and IsWorking;
            exit;
        end;
        // 2b. Base Calendar — annual recurring
        BaseCalChange.Reset();
        if CalCode <> '' then BaseCalChange.SetRange("Base Calendar Code", CalCode);
        BaseCalChange.SetRange("Recurring System", BaseCalChange."Recurring System"::"Annual Recurring");
        if BaseCalChange.FindSet()then repeat if(Date2DMY(CheckDate, 1) = Date2DMY(BaseCalChange.Date, 1)) and (Date2DMY(CheckDate, 2) = Date2DMY(BaseCalChange.Date, 2))then begin
                    IsWorking:=not BaseCalChange.Nonworking;
                    IsHalfDay:=BaseCalChange."Is Half Day" and IsWorking;
                    exit;
                end;
            until BaseCalChange.Next() = 0;
        // 2c. Base Calendar — weekly recurring
        BaseCalChange.Reset();
        if CalCode <> '' then BaseCalChange.SetRange("Base Calendar Code", CalCode);
        BaseCalChange.SetRange("Recurring System", BaseCalChange."Recurring System"::"Weekly Recurring");
        BaseCalChange.SetRange(Day, DayOfWeek);
        if BaseCalChange.FindFirst()then begin
            IsWorking:=not BaseCalChange.Nonworking;
            IsHalfDay:=BaseCalChange."Is Half Day" and IsWorking;
        end;
    // Default: working=true, halfDay=false
    end;
    local procedure NextWorkingDay(CalCode: Code[10];
    FromDate: Date): Date var CheckDate: Date;
    IsWorking: Boolean;
    IsHalfDay: Boolean;
    Safety: Integer;
    begin
        CheckDate:=FromDate;
        Safety:=30;
        while Safety > 0 do begin
            Safety-=1;
            GetDayStatus(CalCode, CheckDate, IsWorking, IsHalfDay);
            if IsWorking then exit(CheckDate);
            CheckDate:=CheckDate + 1;
        end;
        exit(FromDate);
    end;
    local procedure CountHalfDaysInRange(CalendarCode: Code[10];
    StartDate: Date;
    EndDate: Date): Decimal var BaseCalChange: Record "Base Calendar Change";
    CustomCalChange: Record "Customized Calendar Change";
    CheckDate: Date;
    HalfDayDates: array[1000]of Date;
    HalfDayCount2: Integer;
    i: Integer;
    AlreadyCounted: Boolean;
    begin
        // Customized Calendar Change (company level, highest priority)
        CustomCalChange.Reset();
        CustomCalChange.SetRange("Source Type", 0);
        CustomCalChange.SetRange("Source Code", '');
        if CalendarCode <> '' then CustomCalChange.SetRange("Base Calendar Code", CalendarCode);
        CustomCalChange.SetRange("Is Half Day", true);
        CustomCalChange.SetRange(Nonworking, false);
        if CustomCalChange.FindSet()then repeat case CustomCalChange."Recurring System" of CustomCalChange."Recurring System"::"Weekly Recurring": begin
                    CheckDate:=StartDate;
                    while CheckDate <= EndDate do begin
                        if Date2DWY(CheckDate, 1) = CustomCalChange.Day then if HalfDayCount2 < 1000 then begin
                                HalfDayCount2+=1;
                                HalfDayDates[HalfDayCount2]:=CheckDate;
                            end;
                        CheckDate:=CheckDate + 1;
                    end;
                end;
                CustomCalChange."Recurring System"::"Annual Recurring": begin
                    CheckDate:=StartDate;
                    while CheckDate <= EndDate do begin
                        if(Date2DMY(CheckDate, 1) = Date2DMY(CustomCalChange.Date, 1)) and (Date2DMY(CheckDate, 2) = Date2DMY(CustomCalChange.Date, 2))then if HalfDayCount2 < 1000 then begin
                                HalfDayCount2+=1;
                                HalfDayDates[HalfDayCount2]:=CheckDate;
                            end;
                        CheckDate:=CheckDate + 1;
                    end;
                end;
                else if(CustomCalChange.Date >= StartDate) and (CustomCalChange.Date <= EndDate)then if HalfDayCount2 < 1000 then begin
                            HalfDayCount2+=1;
                            HalfDayDates[HalfDayCount2]:=CustomCalChange.Date;
                        end;
                end;
            until CustomCalChange.Next() = 0;
        // Base Calendar Change — skip dates already found in Customized
        BaseCalChange.Reset();
        if CalendarCode <> '' then BaseCalChange.SetRange("Base Calendar Code", CalendarCode);
        BaseCalChange.SetRange("Is Half Day", true);
        BaseCalChange.SetRange(Nonworking, false);
        if BaseCalChange.FindSet()then repeat case BaseCalChange."Recurring System" of BaseCalChange."Recurring System"::"Weekly Recurring": begin
                    CheckDate:=StartDate;
                    while CheckDate <= EndDate do begin
                        if Date2DWY(CheckDate, 1) = BaseCalChange.Day then begin
                            AlreadyCounted:=false;
                            for i:=1 to HalfDayCount2 do if HalfDayDates[i] = CheckDate then AlreadyCounted:=true;
                            if not AlreadyCounted then if HalfDayCount2 < 1000 then begin
                                    HalfDayCount2+=1;
                                    HalfDayDates[HalfDayCount2]:=CheckDate;
                                end;
                        end;
                        CheckDate:=CheckDate + 1;
                    end;
                end;
                BaseCalChange."Recurring System"::"Annual Recurring": begin
                    CheckDate:=StartDate;
                    while CheckDate <= EndDate do begin
                        if(Date2DMY(CheckDate, 1) = Date2DMY(BaseCalChange.Date, 1)) and (Date2DMY(CheckDate, 2) = Date2DMY(BaseCalChange.Date, 2))then begin
                            AlreadyCounted:=false;
                            for i:=1 to HalfDayCount2 do if HalfDayDates[i] = CheckDate then AlreadyCounted:=true;
                            if not AlreadyCounted then if HalfDayCount2 < 1000 then begin
                                    HalfDayCount2+=1;
                                    HalfDayDates[HalfDayCount2]:=BaseCalChange.Date;
                                end;
                        end;
                        CheckDate:=CheckDate + 1;
                    end;
                end;
                else if(BaseCalChange.Date >= StartDate) and (BaseCalChange.Date <= EndDate)then begin
                        AlreadyCounted:=false;
                        for i:=1 to HalfDayCount2 do if HalfDayDates[i] = BaseCalChange.Date then AlreadyCounted:=true;
                        if not AlreadyCounted then if HalfDayCount2 < 1000 then begin
                                HalfDayCount2+=1;
                                HalfDayDates[HalfDayCount2]:=BaseCalChange.Date;
                            end;
                    end;
                end;
            until BaseCalChange.Next() = 0;
        exit(HalfDayCount2);
    end;

    // Single source of truth for "is this employee on approved leave on this
    // date" — used by both the Attendance Review Mailer and the Employee
    // Attendance Subform, so the two views can't disagree. Checks two
    // places because approved leave doesn't always leave the same trail:
    //   1. Leave Application Day lines — populated for multi-day leave
    //      submitted through the ESS portal (SubmitMultiDayLeave).
    //   2. Leave Ledger Entry — Fanisi's own half-day-leave flow
    //      (AdjustDatesForHalfDays above deliberately leaves it untouched)
    //      and any leave application created/posted directly in BC never
    //      get Leave Application Day rows at all, so without this fallback
    //      those days showed as an unexplained gap instead of leave. This
    //      is the same table Leave Application."Leave Balance" itself sums
    //      from, so it's already this system's source of truth for leave.
    procedure GetLeaveStatus(EmployeeNo: Code[20]; CheckDate: Date; var IsHalfDay: Boolean): Code[20]
    var
        LeaveApplication: Record "Leave Application";
        LeaveDay: Record "Leave Application Day";
        LeaveLedgerEntry: Record "Leave Ledger Entry";
    begin
        IsHalfDay := false;

        LeaveApplication.SetRange("Employee No.", EmployeeNo);
        LeaveApplication.SetRange(Status, LeaveApplication.Status::Approved);
        if LeaveApplication.FindSet() then
            repeat
                LeaveDay.SetRange("Leave No.", LeaveApplication."No.");
                LeaveDay.SetRange(Date, CheckDate);
                if not LeaveDay.IsEmpty() then begin
                    IsHalfDay := LeaveApplication."Is Half Day Leave?";
                    exit(LeaveApplication."No.");
                end;
            until LeaveApplication.Next() = 0;

        LeaveLedgerEntry.SetRange("Employee No.", EmployeeNo);
        LeaveLedgerEntry.SetRange("Transaction Type", LeaveLedgerEntry."Transaction Type"::"Leave Application");
        LeaveLedgerEntry.SetFilter("Start Date", '<=%1', CheckDate);
        LeaveLedgerEntry.SetFilter("End Date", '>=%1', CheckDate);
        if LeaveLedgerEntry.FindFirst() then begin
            if LeaveApplication.Get(LeaveLedgerEntry."Document No.") then
                IsHalfDay := LeaveApplication."Is Half Day Leave?";
            exit(LeaveLedgerEntry."Document No.");
        end;

        exit('');
    end;
}
