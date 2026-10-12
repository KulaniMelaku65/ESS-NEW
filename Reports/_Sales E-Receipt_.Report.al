report 51111 "Sales E-Receipt"
{
    Caption = 'Sales E-Receipt';
    UsageCategory = None;
    DefaultLayout = RDLC;
    RDLCLayout = './Reports/SalesEReceipt.rdlc';

    dataset
    {
        dataitem(EReceiptBuffer; "E-Receipt Buffer")
        {
            DataItemTableView = sorting("Entry No.", "Line No.");

            column(SellerName_; "Seller Name") { }
            column(SellerTIN_; "Seller TIN") { }
            column(SellerAddress_; "Seller Address") { }
            column(SellerCity_; "Seller City") { }
            column(SellerPhoneNo_; "Seller Phone No.") { }

            column(CustomerNo_; "Customer No.") { }
            column(CustomerName_; "Customer Name") { }
            column(CustomerTIN_; "Customer TIN") { }

            column(DocumentNo_; "Document No.") { }
            column(DocumentDate_; Format("Document Date")) { }

            column(IRN_; IRN) { }
            column(AckDate_; "Ack Date") { }
            column(Status_; Status) { }
            column(FiscalDocumentNo_; "Fiscal Document No.") { }
            column(QRImage_; "QR Image") { }

            column(TotalExclVAT_; "Total Excl. VAT") { }
            column(TotalVAT_; "Total VAT") { }
            column(TotalInclVAT_; "Total Incl. VAT") { }
            column(InvDiscAmtInclVAT_; "Inv. Discount Amt. Incl. VAT") { }
            column(InvDiscPct_; "Invoice Discount %") { }

            column(LineItemNo_; "Line Item No.") { }
            column(LineDescription_; "Line Description") { }
            column(LineQuantity_; "Line Quantity") { }
            column(LineUnitPrice_; "Line Unit Price") { }
            column(LineAmount_; "Line Amount") { }
        }
    }
}
