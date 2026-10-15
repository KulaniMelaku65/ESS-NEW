table 51104 "E-Receipt Setup"
{
    // Singleton setup table (Primary Key = 0, one row only — same pattern as every other
    // BC Setup table) holding the Kifiya e-sign middleware credentials for the MoR
    // e-invoicing integration (codeunit 51105 "Sales E-Receipt API"). Deliberately NOT
    // hardcoded in AL source: this extension is pushed to a git repo, and a real API key
    // committed as a literal would sit in git history in plaintext forever, even after
    // rotation. "API Key" is entered here, in BC, once, by whoever administers this.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Base URL"; Text[250])
        {
            Caption = 'Base URL';
            InitValue = 'https://api.middleware.kifiya.et/api/esign';
        }
        field(11; "API Key"; Text[250])
        {
            Caption = 'API Key';
            ExtendedDatatype = Masked;
        }
        field(12; "System Number"; Text[20])
        {
            Caption = 'System Number';
        }
        field(13; "System Type"; Text[10])
        {
            Caption = 'System Type';
            // MoR-enforced values: POS, MAN, CRM, EFD, SYS.
        }
        field(20; "Next Receipt Counter"; Integer)
        {
            Caption = 'Next Receipt Counter';
            // ONE shared sequence across every receipt-generating call this system
            // makes — the invoice's own payment receipt, credit-sale receipts
            // (POST /v1/receipts/sales), and withholding receipts (POST /v1/receipts/
            // withholding) all draw from this SAME counter, confirmed by the guide's own
            // examples (123, then 124 for a credit-sale receipt, then 125 for a
            // withholding receipt — strictly sequential across different call types, not
            // separate per-type counters). Incremented atomically (see codeunit 51105's
            // GetNextReceiptCounter). Starts at 1 for a brand-new system registration; set
            // this manually if the middleware team registers this system starting from a
            // different number.
            InitValue = 1;
            MinValue = 1;
        }
        field(21; "Paper Size"; Enum "E-Receipt Paper Size")
        {
            Caption = 'Paper Size';
            InitValue = A4;
            // Used on .../v1/invoices/{id}/print?paper=<value> for both the automatic
            // attachment (codeunit 51105's FetchAndAttachPrintPage) and "Open printable
            // receipt". The e-sign doc's actual query values are a4/80/58, not "a4"/
            // "80mm"/"58mm" — see enum 51101.
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetOrInsert(): Record "E-Receipt Setup"
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
        exit(Rec);
    end;

    // Hands back the counter to use on THIS receipt and advances it for the next one.
    // LockTable() before the read means two near-simultaneous sends can't both walk
    // away with the same number — the second call blocks until the first commits.
    procedure GetNextReceiptCounter(): Integer
    var
        Setup: Record "E-Receipt Setup";
        ThisCounter: Integer;
    begin
        Setup.LockTable();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
        ThisCounter := Setup."Next Receipt Counter";
        Setup."Next Receipt Counter" += 1;
        Setup.Modify();
        exit(ThisCounter);
    end;
}
