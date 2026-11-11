codeunit 51123 "Bus Operator Cash Receipt Mgmt"
{
    // Turns one "Bus Operator Cash Receipt" row (table 51124) into Cash
    // Receipt Journal lines — created only, never posted. A person reviews
    // and posts the batch manually in BC (see page "Bus Operator Cash
    // Receipts", which has an action to jump straight to the journal).
    //
    // SETUP REQUIRED before use:
    //   1. Create a Gen. Journal Batch named JournalBatchName() below under
    //      the JournalTemplateName() template (a Cash Receipts-type
    //      template), same as any manually-run Cash Receipt Journal.
    //   2. Bus operators must already exist as Vendors, with Vendor.Name
    //      matching the "Bus Operator" text in the incoming report exactly
    //      (case-insensitive) — see MatchVendor below. If names won't line
    //      up cleanly in practice, this is the one place that needs to
    //      change to add an explicit mapping table instead.
    //
    // CONFIRMED SIGN CONVENTION — matched against a real example already
    // in this ERP (Posting Date 8/13/2026: Account Type = Bank-side
    // account, Amount = 100,000 positive, Bal. Account Type = Vendor):
    // Account Type = Bank Account (primary, positive Amount = Debit,
    // i.e. cash increases), Bal. Account Type = Vendor (automatically
    // credited, i.e. the payable owed back to the operator increases).
    // Bus operators are Vendors, not Customers — Kifiya collects cash on
    // their behalf and owes it back to them.
    //
    // "Inter-Association Amount" (only when non-zero) gets its own second
    // line, same Account/Bal. Account structure as the main line but
    // against the separate Inter-Association Bank Account No. — i.e. this
    // models "part of the total collected cash landed in a different bank
    // account," crediting the SAME vendor's payable a second time from
    // that other bank. This is my best-effort reading of "customer to
    // bank on one line, then bank to customer on the next" once translated
    // to Vendor/Bank Account — PLEASE VERIFY the resulting Vendor payable
    // total (Total Collected + Inter-Association Amount) against what you
    // actually expect before trusting it; flag me if it should instead be
    // a deduction, or a pure bank-to-bank transfer with no Vendor line.

    procedure ProcessReceipt(var Receipt: Record "Bus Operator Cash Receipt")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
    begin
        Receipt.Processed := true;
        Receipt."Created At" := CurrentDateTime;

        if not MatchVendor(Receipt."Bus Operator", Vendor) then begin
            SetResult(Receipt, Receipt.Result::"Vendor Not Found", StrSubstNo('No Vendor found with Name = %1.', Receipt."Bus Operator"));
            exit;
        end;
        Receipt."Vendor No." := Vendor."No.";

        if Receipt."Bank Account No." = '' then begin
            SetResult(Receipt, Receipt.Result::"Bank Account Invalid", 'Bank Account No. was not provided.');
            exit;
        end;
        if not BankAccount.Get(Receipt."Bank Account No.") then begin
            SetResult(Receipt, Receipt.Result::"Bank Account Invalid", StrSubstNo('Bank Account %1 does not exist.', Receipt."Bank Account No."));
            exit;
        end;

        if Receipt."Inter-Association Amount" <> 0 then begin
            if Receipt."Inter-Association Bank Account No." = '' then begin
                SetResult(Receipt, Receipt.Result::"Bank Account Invalid", 'Inter-Association Amount was given but Inter-Association Bank Account No. was not provided.');
                exit;
            end;
            if not BankAccount.Get(Receipt."Inter-Association Bank Account No.") then begin
                SetResult(Receipt, Receipt.Result::"Bank Account Invalid", StrSubstNo('Inter-Association Bank Account %1 does not exist.', Receipt."Inter-Association Bank Account No."));
                exit;
            end;
        end;

        if not TryCreateLines(Receipt) then begin
            SetResult(Receipt, Receipt.Result::Failed, CopyStr(GetLastErrorText(), 1, 250));
            exit;
        end;

        SetResult(Receipt, Receipt.Result::Success, '');
    end;

    [TryFunction]
    local procedure TryCreateLines(var Receipt: Record "Bus Operator Cash Receipt")
    var
        GenJnlLine: Record "Gen. Journal Line";
        NextLineNo: Integer;
    begin
        NextLineNo := GetNextLineNo();

        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := JournalTemplateName();
        GenJnlLine."Journal Batch Name" := JournalBatchName();
        GenJnlLine."Line No." := NextLineNo;
        GenJnlLine.Validate("Posting Date", Receipt."Report Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := Receipt."Document No.";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
        GenJnlLine.Validate("Account No.", Receipt."Bank Account No.");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::Vendor);
        GenJnlLine.Validate("Bal. Account No.", Receipt."Vendor No.");
        GenJnlLine.Validate(Amount, Receipt."Total Collected");
        GenJnlLine.Description := CopyStr(StrSubstNo('Bus cash receipt - %1 - %2', Receipt."Bus Operator", Format(Receipt."Report Date")), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Insert(true);
        Receipt."Journal Line No." := NextLineNo;

        if Receipt."Inter-Association Amount" <> 0 then begin
            NextLineNo += 10000;
            GenJnlLine.Init();
            GenJnlLine."Journal Template Name" := JournalTemplateName();
            GenJnlLine."Journal Batch Name" := JournalBatchName();
            GenJnlLine."Line No." := NextLineNo;
            GenJnlLine.Validate("Posting Date", Receipt."Report Date");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
            GenJnlLine."Document No." := Receipt."Document No.";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"Bank Account");
            GenJnlLine.Validate("Account No.", Receipt."Inter-Association Bank Account No.");
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::Vendor);
            GenJnlLine.Validate("Bal. Account No.", Receipt."Vendor No.");
            GenJnlLine.Validate(Amount, Receipt."Inter-Association Amount");
            GenJnlLine.Description := CopyStr(StrSubstNo('Bus cash inter-association - %1 - %2', Receipt."Bus Operator", Format(Receipt."Report Date")), 1, MaxStrLen(GenJnlLine.Description));
            GenJnlLine.Insert(true);
            Receipt."Inter-Association Line No." := NextLineNo;
        end;
    end;

    local procedure GetNextLineNo(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName());
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName());
        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure MatchVendor(BusOperatorName: Text[100]; var Vendor: Record Vendor): Boolean
    begin
        Vendor.Reset();
        Vendor.SetFilter(Name, '@%1', BusOperatorName);
        exit(Vendor.FindFirst());
    end;

    local procedure SetResult(var Receipt: Record "Bus Operator Cash Receipt"; ResultOption: Option; Details: Text[250])
    begin
        Receipt.Result := ResultOption;
        Receipt.Details := Details;
    end;

    // SETUP: point these at the actual Cash Receipts journal template and
    // batch created for this in BC. Public so the review list page (Bus
    // Operator Cash Receipts) can jump straight to the same batch.
    procedure JournalTemplateName(): Code[10]
    begin
        exit('CASH');
    end;

    procedure JournalBatchName(): Code[10]
    begin
        exit('BUSCASH');
    end;
}
