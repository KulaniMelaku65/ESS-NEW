codeunit 51139 "Attendance Day Type"
{
    // Read-only calendar classification for display — reads the exact same
    // "Base Calendar Change" data codeunit 51126 "Attendance Leave
    // Processor" already uses to decide non-working days (see its
    // IsNonWorkingDay), but exposed here so the attendance log can show WHY
    // a date is non-working (Saturday / Sunday / a named holiday) instead
    // of just silently skipping it.
    //
    // Weekend detection doesn't depend on the Base Calendar having a
    // "Weekly Recurring" entry configured — Date2DWY is checked directly,
    // so Saturday/Sunday are always labeled correctly regardless of
    // calendar setup completeness. Only holiday-specific entries (Annual
    // Recurring or a one-off date) are read from Base Calendar Change.

    // Single source of truth for "is this date non-working" — Attendance
    // Leave Processor calls this instead of keeping its own duplicate
    // holiday/weekend logic, so a date can't be Holiday in Processing
    // Result but something else in the Day Type column, or vice versa.
    procedure IsNonWorkingDay(CheckDate: Date): Boolean
    begin
        exit(GetDayType(CheckDate) <> '');
    end;

    procedure GetDayType(CheckDate: Date): Text[30]
    var
        BaseCalChange: Record "Base Calendar Change";
        CalCode: Code[10];
        WeekDayNo: Integer;
    begin
        // Date2DWY throws "The date is not valid" on a blank (0D) date —
        // same pitfall as BaseCalChange.Date in DateMatches below, just on
        // the caller's own input this time (e.g. a bad/blank Date somehow
        // sitting in Employee Attendance Log throwing off a StartDate calc).
        if CheckDate = 0D then
            exit('');
        WeekDayNo := Date2DWY(CheckDate, 1); // 1=Monday .. 7=Sunday
        if WeekDayNo = 6 then
            exit('Saturday');
        if WeekDayNo = 7 then
            exit('Sunday');

        CalCode := GetCompanyCalendarCode();
        if CalCode = '' then
            exit('');

        BaseCalChange.Reset();
        BaseCalChange.SetRange("Base Calendar Code", CalCode);
        BaseCalChange.SetFilter("Recurring System", '<>%1', BaseCalChange."Recurring System"::"Weekly Recurring");
        if BaseCalChange.FindSet() then
            repeat
                if DateMatches(BaseCalChange, CheckDate) then begin
                    if BaseCalChange.Nonworking then
                        exit(HolidayLabel(BaseCalChange.Description));
                    if BaseCalChange."Is Half Day" then
                        exit(HalfDayLabel(BaseCalChange.Description));
                end;
            until BaseCalChange.Next() = 0;
        exit('');
    end;

    // True only for a genuine Half Day calendar entry (Is Half Day, and NOT
    // also marked Nonworking) — lets a caller tell "office closes at noon"
    // apart from "fully closed", since GetDayType returns a non-blank label
    // for both and can't be used alone to make that distinction.
    procedure IsHalfWorkingDay(CheckDate: Date): Boolean
    var
        BaseCalChange: Record "Base Calendar Change";
        CalCode: Code[10];
    begin
        if CheckDate = 0D then
            exit(false);
        CalCode := GetCompanyCalendarCode();
        if CalCode = '' then
            exit(false);

        BaseCalChange.Reset();
        BaseCalChange.SetRange("Base Calendar Code", CalCode);
        BaseCalChange.SetFilter("Recurring System", '<>%1', BaseCalChange."Recurring System"::"Weekly Recurring");
        if BaseCalChange.FindSet() then
            repeat
                if DateMatches(BaseCalChange, CheckDate) and BaseCalChange."Is Half Day" and not BaseCalChange.Nonworking then
                    exit(true);
            until BaseCalChange.Next() = 0;
        exit(false);
    end;

    local procedure DateMatches(var BaseCalChange: Record "Base Calendar Change"; CheckDate: Date): Boolean
    begin
        // Date2DMY throws "The date is not valid" on a blank (0D) date —
        // guard against any Annual Recurring / one-off row that's missing
        // its Date instead of letting that crash the whole loop.
        if BaseCalChange.Date = 0D then
            exit(false);
        case BaseCalChange."Recurring System" of
            BaseCalChange."Recurring System"::"Annual Recurring":
                exit((Date2DMY(CheckDate, 1) = Date2DMY(BaseCalChange.Date, 1)) and
                     (Date2DMY(CheckDate, 2) = Date2DMY(BaseCalChange.Date, 2)));
            else
                exit(BaseCalChange.Date = CheckDate);
        end;
    end;

    local procedure HolidayLabel(Description: Text[30]): Text[30]
    begin
        if Description <> '' then
            exit(Description);
        exit('Holiday');
    end;

    local procedure HalfDayLabel(Description: Text[30]): Text[30]
    begin
        if Description <> '' then
            exit(Description + ' (Half Day)');
        exit('Half Day');
    end;

    // Company Information."Base Calendar Code" is the normal place this
    // should come from, but it can be left blank while calendar data still
    // exists in Base Calendar Change. Falls back to whichever code is
    // actually in use, as long as there's exactly one.
    local procedure GetCompanyCalendarCode(): Code[10]
    var
        CompanyInfo: Record "Company Information";
        BaseCalChange: Record "Base Calendar Change";
        FirstCode: Code[10];
    begin
        if CompanyInfo.Get() and (CompanyInfo."Base Calendar Code" <> '') then
            exit(CompanyInfo."Base Calendar Code");
        if BaseCalChange.FindFirst() then begin
            FirstCode := BaseCalChange."Base Calendar Code";
            BaseCalChange.SetFilter("Base Calendar Code", '<>%1', FirstCode);
            if BaseCalChange.IsEmpty() then
                exit(FirstCode);
        end;
        exit('');
    end;
}
