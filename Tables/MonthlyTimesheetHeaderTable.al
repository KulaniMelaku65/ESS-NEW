table 51100 "Monthly Timesheet Header"
{
    DataClassification = CustomerContent;
    Caption = 'Timesheet Header';

    fields
    {
        field(1;"No.";Code[20])
        {
            Caption = 'No.';
        // In a production environment, you would use No. Series here
        }
        field(2;"Employee No.";Code[20])
        {
            TableRelation = Employee;
            Caption = 'Employee No.';
        }
        field(3;"Month";Option)
        {
            OptionMembers = " ", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December";
            Caption = 'Month';
        }
        field(4;"Year";Integer)
        {
            Caption = 'Year';
            InitValue = 2026;
        }
        field(5;"Status";Enum "Timesheet Status")
        {
            Editable = false;
            Caption = 'Status';
            InitValue = Open; // Add this line
        }
        field(6;"Approver ID";Code[50])
        {
            TableRelation = "User Setup";
            Caption = 'Approver ID';
        }
        field(7;"Total Hours";Decimal)
        {
            // Sums "Daily Total", not "Hours" — the ERP Card/Subform (page
            // 51100/51101) only ever populates Morning/Afternoon Hours and
            // Daily Total; it never touches "Hours" at all, so a line
            // entered directly in BC always contributed 0 to this sum
            // regardless of real hours entered. The ESS portal API
            // (tsLineAPI, page 51104) sets Daily Total and Hours to the
            // same value on insert, so this sums identically for
            // portal-created lines while fixing ERP-created ones — and
            // fixes it retroactively for existing timesheets too, since a
            // FlowField recalculates fresh every time it's displayed.
            FieldClass = FlowField;
            CalcFormula = sum("Monthly Timesheet Line"."Daily Total" where("Document No."=field("No.")));
            Editable = false;
        }
        // --- Modified Header Table ---
        field(8;"No. Series";Code[20])
        {
            TableRelation = "No. Series";
            Editable = false;
        }
        field(9;"Reason for Rejection";Text[250])
        {
            Caption = 'Reason for Rejection';
            Editable = false;
        }
        field(10;"Employee Name";Text[100])
        {
            // Deliberately a real stored field, not a FlowField — a
            // Lookup-formula FlowField isn't picked up by the list page's
            // quick search box, unlike a plain field. Kept in sync
            // automatically in OnInsert/OnModify below, same pattern as
            // Employee's own "Full Name" field.
            Caption = 'Employee Name';
            Editable = false;
        }
    }
    keys
    {
        key(PK;"No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()var HRSetup: Record "Human Resources Setup";
    NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if "No." = '' then begin
            HRSetup.Get();
            HRSetup.TestField("Timesheet No. Series");
            NoSeriesMgt.InitSeries(HRSetup."Timesheet No. Series", xRec."No. Series", 0D, "No.", "No. Series");
        end;
        UpdateEmployeeName();
    end;

    trigger OnModify()
    begin
        UpdateEmployeeName();
    end;

    local procedure UpdateEmployeeName()
    var
        Employee: Record Employee;
    begin
        if Employee.Get("Employee No.") then
            "Employee Name" := Employee.FullName()
        else
            "Employee Name" := '';
    end;
}
