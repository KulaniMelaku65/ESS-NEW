tableextension 51102 HRSetupTableExt extends "Human Resources Setup"
{
    fields
    {
        field(50141; "Timesheet No. Series"; Code[20])
        {
            Caption = 'Timesheet No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series".Code;
        }
    }
}
