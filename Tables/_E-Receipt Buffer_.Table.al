table 51103 "E-Receipt Buffer"
{
    // In-memory carrier for one e-receipt, used only as the data source for report 51111
    // "Sales E-Receipt" — never inserted as real, persisted data (always declared
    // `temporary` by its one caller, codeunit 51105 "Sales E-Receipt API"). Flattened to
    // one row per sales line (header/seller/customer/totals/fiscal fields repeated on
    // every row) rather than a header row plus a nested dataitem, so the report's single
    // dataitem can source everything — both the repeated header fields (via RDLC's
    // First()) and the line table — without depending on a live Sales Line/Sales Invoice
    // Line query that would need to switch tables the instant the invoice is posted.
    //
    // Populated in two passes: the header/seller/customer/totals/line fields are filled
    // in once, from the still-unposted invoice, and reused to build BOTH the API payload
    // and this printed receipt — so the two can never drift apart by recomputing the same
    // figures twice. "Document No." starts as the draft number and is overwritten with
    // the real posted number once posting completes. The fiscal fields (IRN, Ack Date,
    // Status, Fiscal Document No., QR Image) are filled in last, from the API's response.
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(10; IRN; Text[250])
        {
            Caption = 'IRN';
        }
        field(11; "Ack Date"; Text[50])
        {
            Caption = 'Acknowledgement Date';
        }
        field(12; Status; Text[10])
        {
            Caption = 'Status';
        }
        field(13; "Fiscal Document No."; Text[20])
        {
            Caption = 'Fiscal Document No.';
        }
        field(20; "QR Image"; Media)
        {
            Caption = 'QR Image';
        }
        field(30; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(31; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(32; "Customer TIN"; Text[40])
        {
            Caption = 'Customer TIN';
        }
        field(33; "Customer VAT Reg. No."; Text[20])
        {
            Caption = 'Customer VAT Reg. No.';
        }
        field(34; "Customer Phone No."; Text[30])
        {
            Caption = 'Customer Phone No.';
        }
        field(40; "Seller Name"; Text[100])
        {
            Caption = 'Seller Name';
        }
        field(41; "Seller TIN"; Text[20])
        {
            Caption = 'Seller TIN';
        }
        field(42; "Seller Address"; Text[100])
        {
            Caption = 'Seller Address';
        }
        field(43; "Seller City"; Text[30])
        {
            Caption = 'Seller City';
        }
        field(44; "Seller Phone No."; Text[30])
        {
            Caption = 'Seller Phone No.';
        }
        field(50; "Total Excl. VAT"; Decimal)
        {
            Caption = 'Total Excl. VAT';
            AutoFormatType = 1;
        }
        field(51; "Total VAT"; Decimal)
        {
            Caption = 'Total VAT';
            AutoFormatType = 1;
        }
        field(52; "Total Incl. VAT"; Decimal)
        {
            Caption = 'Total Incl. VAT';
            AutoFormatType = 1;
        }
        field(53; "Inv. Discount Amt. Incl. VAT"; Decimal)
        {
            Caption = 'Inv. Discount Amount Incl. VAT';
            AutoFormatType = 1;
        }
        field(54; "Invoice Discount %"; Decimal)
        {
            Caption = 'Invoice Discount %';
        }
        field(60; "Line Item No."; Code[20])
        {
            Caption = 'Line Item No.';
        }
        field(61; "Line Description"; Text[100])
        {
            Caption = 'Line Description';
        }
        field(62; "Line Quantity"; Decimal)
        {
            Caption = 'Line Quantity';
        }
        field(63; "Line Unit Price"; Decimal)
        {
            Caption = 'Line Unit Price';
            AutoFormatType = 1;
        }
        field(64; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            AutoFormatType = 1;
        }
        field(65; "Line Unit of Measure"; Code[10])
        {
            Caption = 'Line Unit of Measure';
        }
        field(69; "Line Nature of Supplies"; Text[10])
        {
            Caption = 'Line Nature of Supplies';
            // 'goods' or 'service', from the Item's own Type (Service -> service,
            // Inventory/Non-Inventory -> goods) — MoR rejects the invoice if this
            // doesn't match what EIMS expects for that item.
        }
        field(66; "Line Discount Amount"; Decimal)
        {
            Caption = 'Line Discount Amount';
            AutoFormatType = 1;
        }
        field(67; "Line VAT %"; Decimal)
        {
            Caption = 'Line VAT %';
        }
        field(68; "Line Amount Incl. VAT"; Decimal)
        {
            Caption = 'Line Amount Incl. VAT';
            AutoFormatType = 1;
        }
        field(70; "Receipt Number"; Text[30])
        {
            Caption = 'Receipt Number';
        }
        field(71; "Receipt Counter"; Integer)
        {
            Caption = 'Receipt Counter';
        }
    }

    keys
    {
        key(PK; "Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
