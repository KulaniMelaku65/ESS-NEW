table 51124 "Bus Operator Cash Receipt"
{
    // One row per Bus Operator + Report Date, pushed in via "Bus Operator
    // Cash Receipt API" (page 51132) from the third-party daily cash
    // transfer report. Turns into Cash Receipt Journal lines automatically
    // on insert (see codeunit "Bus Operator Cash Receipt Mgmt") — created
    // only, never posted, so someone reviews and posts the batch manually
    // in BC. Primary key means the same Bus Operator + Report Date can
    // only ever be pushed once; a retry of the same day is rejected rather
    // than double-posting.
    //
    // Modeled on a real confirmed example: Account Type = Bank Account,
    // Bal. Account Type = Vendor, Amount = the receipt amount (positive =
    // Debit to Bank / Credit to Vendor's payable). Bus operators are
    // Vendors here, not Customers — Kifiya collects cash on their behalf
    // and owes it back to them.
    DataClassification = CustomerContent;
    Caption = 'Bus Operator Cash Receipt';

    fields
    {
        field(1;"Bus Operator";Text[100])
        {
            Caption = 'Bus Operator';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2;"Report Date";Date)
        {
            Caption = 'Report Date';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3;"Vendor No.";Code[20])
        {
            // Bus operators are Vendors, not Customers, in this ERP —
            // Kifiya collects cash on their behalf, so a receipt into the
            // company bank increases what's owed BACK to the operator
            // (a payable), matching the confirmed real Cash Receipt
            // Journal example (Account Type = Bank Account, Bal. Account
            // Type = Vendor).
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
            Editable = false;
        }
        field(4;"Total Collected";Decimal)
        {
            Caption = 'Total Collected';
            DataClassification = CustomerContent;
        }
        field(5;"Bank Account No.";Code[20])
        {
            // Supplied by the caller, not looked up here — which bank
            // account a given operator's cash lands in varies and isn't a
            // fixed rule this table can derive on its own.
            Caption = 'Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account";
        }
        field(6;"Inter-Association Amount";Decimal)
        {
            Caption = 'Inter-Association Amount';
            DataClassification = CustomerContent;
        }
        field(7;"Inter-Association Bank Account No.";Code[20])
        {
            Caption = 'Inter-Association Bank Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account";
        }
        field(8;"Document No.";Code[20])
        {
            // Optional external reference from the third-party report, for
            // traceability only — not used as a key.
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(9;Result;Option)
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
            Editable = false;
            OptionMembers = " ",Success,"Vendor Not Found","Bank Account Invalid",Failed;
        }
        field(10;Details;Text[250])
        {
            Caption = 'Details';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11;"Journal Line No.";Integer)
        {
            Caption = 'Journal Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12;"Inter-Association Line No.";Integer)
        {
            Caption = 'Inter-Association Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13;Processed;Boolean)
        {
            Caption = 'Processed';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14;"Created At";DateTime)
        {
            Caption = 'Created At';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(PK;"Bus Operator", "Report Date")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        Mgmt: Codeunit "Bus Operator Cash Receipt Mgmt";
    begin
        Mgmt.ProcessReceipt(Rec);
    end;
}
