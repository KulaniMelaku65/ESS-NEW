page 51146 "Attendance Pull Log"
{
    // View of what "Attendance Punch Machine Pull" (codeunit 51138) found
    // — or didn't — for each employee/date. Filter by Result to see, e.g.,
    // every "HTTP Error" or "No Data" outcome for a specific day.
    ApplicationArea = Basic;
    Caption = 'Attendance Pull Log';
    PageType = List;
    SourceTable = "Attendance Pull Log";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Employee No.";Rec."Employee No.")
                {
                    ApplicationArea = Basic;
                }
                field(EmployeeName;EmployeeName)
                {
                    ApplicationArea = Basic;
                    Caption = 'Employee Name';
                }
                field(Date;Rec.Date)
                {
                    ApplicationArea = Basic;
                }
                field(Result;Rec.Result)
                {
                    ApplicationArea = Basic;
                    StyleExpr = ResultStyle;
                }
                field(Details;Rec.Details)
                {
                    ApplicationArea = Basic;
                }
                field("Pulled At";Rec."Pulled At")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Employee: Record Employee;
    begin
        Clear(EmployeeName);
        if Employee.Get(Rec."Employee No.") then
            EmployeeName := Employee.FullName();

        if Rec.Result = Rec.Result::Success then
            ResultStyle := 'Favorable'
        else
            if Rec.Result = Rec.Result::"No Data" then
                ResultStyle := 'Subordinate'
            else
                ResultStyle := 'Unfavorable';
    end;

    var
        EmployeeName: Text[100];
        ResultStyle: Text;
}
