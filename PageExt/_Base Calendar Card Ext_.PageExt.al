pageextension 51128 "Base Calendar Card Ext" extends "Base Calendar Card"
{
    actions
    {
        addlast(processing)
        {
            action(GenerateCalendarDays)
            {
                Caption = 'Generate Calendar Days';
                ToolTip = 'Pre-generates day-by-day calendar entries for today through the next 2 years, used by the Calendar Day API.';
                ApplicationArea = All;
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()var Generator: Codeunit "Calendar Day Generator";
                MsgLbl: Label 'Calendar days generated from %1 to %2.';
                FromDate: Date;
                ToDate: Date;
                begin
                    FromDate:=Today();
                    ToDate:=CalcDate('<+2Y>', Today());
                    Generator.GenerateCalendarDays(Rec.Code, FromDate, ToDate);
                    Message(MsgLbl, Format(FromDate, 0, '<Day,2>/<Month,2>/<Year4>'), Format(ToDate, 0, '<Day,2>/<Month,2>/<Year4>'));
                end;
            }
        }
    }
}
