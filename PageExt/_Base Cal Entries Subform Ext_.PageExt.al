pageextension 51132 "Base Cal Entries Subform Ext" extends "Base Calendar Entries Subform"
{
    layout
    {
        addafter(Holiday)
        {
            field(IsHalfDayIndicator;IsHalfDay)
            {
                ApplicationArea = All;
                Visible = true;
                Caption = 'Is Half Day';
                Editable = true;
                ToolTip = 'Indicates whether this day is marked as a half working day in the calendar setup.';
            }
        }
    }
    trigger OnAfterGetRecord()var CustomCalChange: Record "Customized Calendar Change";
    BaseCalChange: Record "Base Calendar Change";
    WeekDay: Integer;
    begin
        IsHalfDay:=false;
        if Rec.Date = 0D then exit;
        WeekDay:=Date2DWY(Rec.Date, 1);
        // Check Customized Calendar Change first (company-specific, takes precedence)
        CustomCalChange.SetRange("Source Type", 0); // 0 = Company
        CustomCalChange.SetRange("Source Code", '');
        CustomCalChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        CustomCalChange.SetRange("Is Half Day", true);
        CustomCalChange.SetRange(Nonworking, false);
        if CustomCalChange.FindSet()then repeat case CustomCalChange."Recurring System" of CustomCalChange."Recurring System"::"Weekly Recurring": if CustomCalChange.Day = WeekDay then IsHalfDay:=true;
                CustomCalChange."Recurring System"::"Annual Recurring": if(Date2DMY(Rec.Date, 1) = Date2DMY(CustomCalChange.Date, 1)) and (Date2DMY(Rec.Date, 2) = Date2DMY(CustomCalChange.Date, 2))then IsHalfDay:=true;
                else if CustomCalChange.Date = Rec.Date then IsHalfDay:=true;
                end;
            until CustomCalChange.Next() = 0;
        if IsHalfDay then exit;
        // Fall back to Base Calendar Change
        BaseCalChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        BaseCalChange.SetRange("Is Half Day", true);
        BaseCalChange.SetRange(Nonworking, false);
        if BaseCalChange.FindSet()then repeat case BaseCalChange."Recurring System" of BaseCalChange."Recurring System"::"Weekly Recurring": if BaseCalChange.Day = WeekDay then IsHalfDay:=true;
                BaseCalChange."Recurring System"::"Annual Recurring": if(Date2DMY(Rec.Date, 1) = Date2DMY(BaseCalChange.Date, 1)) and (Date2DMY(Rec.Date, 2) = Date2DMY(BaseCalChange.Date, 2))then IsHalfDay:=true;
                else if BaseCalChange.Date = Rec.Date then IsHalfDay:=true;
                end;
            until BaseCalChange.Next() = 0;
    end;
    var IsHalfDay: Boolean;
}
