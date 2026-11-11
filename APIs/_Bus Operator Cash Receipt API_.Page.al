page 51132 "Bus Operator Cash Receipt API"
{
    // Lets the bus-operator cash-transfer system push one daily
    // operator/date row directly into BC over OData v4 — turns
    // automatically into Cash Receipt Journal lines (created, never
    // posted — see codeunit "Bus Operator Cash Receipt Mgmt") for someone
    // to review and post manually. Insert-only; Bus Operator + Report Date
    // is the key, so the same day can only be pushed once — a retry of an
    // already-processed day is rejected rather than double-posting.
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Bus Operator Cash Receipt API';
    DelayedInsert = true;
    EntityName = 'busOperatorCashReceipt';
    EntitySetName = 'busOperatorCashReceipts';
    PageType = API;
    SourceTable = "Bus Operator Cash Receipt";
    ODataKeyFields = "Bus Operator", "Report Date";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(busOperator;Rec."Bus Operator")
                {
                    Caption = 'Bus Operator';
                }
                field(reportDate;Rec."Report Date")
                {
                    Caption = 'Report Date';
                }
                field(totalCollected;Rec."Total Collected")
                {
                    Caption = 'Total Collected';
                }
                field(bankAccountNo;Rec."Bank Account No.")
                {
                    Caption = 'Bank Account No.';
                }
                field(interAssociationAmount;Rec."Inter-Association Amount")
                {
                    Caption = 'Inter-Association Amount';
                }
                field(interAssociationBankAccountNo;Rec."Inter-Association Bank Account No.")
                {
                    Caption = 'Inter-Association Bank Account No.';
                }
                field(documentNo;Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(vendorNo;Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                    Editable = false;
                }
                field(result;Rec.Result)
                {
                    Caption = 'Result';
                    Editable = false;
                }
                field(details;Rec.Details)
                {
                    Caption = 'Details';
                    Editable = false;
                }
                field(journalLineNo;Rec."Journal Line No.")
                {
                    Caption = 'Journal Line No.';
                    Editable = false;
                }
                field(interAssociationLineNo;Rec."Inter-Association Line No.")
                {
                    Caption = 'Inter-Association Line No.';
                    Editable = false;
                }
                field(processed;Rec.Processed)
                {
                    Caption = 'Processed';
                    Editable = false;
                }
            }
        }
    }
}
