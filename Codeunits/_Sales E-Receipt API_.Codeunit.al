codeunit 51105 "Sales E-Receipt API"
{
    // "Print e-receipt" on the (unposted) Sales Invoice page (43): registers the invoice
    // with the Ministry of Revenue's EIMS e-invoicing system through the Kifiya e-sign
    // middleware (base URL/API key/system number/system type held in "E-Receipt Setup",
    // never hardcoded — this extension is pushed to git, and a real API key committed as
    // a literal would sit in git history forever), then fetches MoR's own print DATA
    // (.../v1/invoices/{id}/print, with the X-API-Key header) and renders it as a plain
    // HTML document built directly in AL (see ShowPrintDataReport) — NOT through BC's
    // Report/RDLC engine. CONFIRMED via a real Postman/curl test: this endpoint returns
    // 200 JSON (seller/buyer/document/fiscal/lines/totals — same shape as the "print"
    // object seen embedded in the registration response), not an HTML or PDF page as
    // earlier versions assumed; the X-API-Key header is required (a plain unauthenticated
    // Hyperlink reliably 401s). No posting happens here; the invoice number sent to the
    // provider (clientReference) is the draft "No." as it stands right now.
    //
    // Every single rendering path tried through BC's Report engine (report 51111 "Sales
    // E-Receipt") failed in this environment: Report.Run as a Record/Variant/RecordRef and
    // Report.RunModal all either errored "the report was empty" despite confirmed data
    // present, or (RunModal/Run with a RecordRef) aren't available at this BC version's
    // runtime; Report.SaveAs returned success while silently writing 0 bytes. Plain HTML
    // sidesteps the whole category of problem: fiscal.qrPngBase64 embeds directly as a
    // `data:image/png;base64,...` <img> src, with no Media field, no ImportStream, no
    // database write at all — the exact mechanism that crashed the session in multiple
    // earlier versions of this codeunit no longer exists in this flow.
    //
    // Also, a real response was checked and has no "links" object anywhere (not on a
    // REGISTERED response, not on a 202 QUEUED one) despite the guide documenting
    // data.links.self/print/printHtml — PollUntilResolved below builds the poll URL
    // itself from data.invoice.id instead of relying on a links.self that never actually
    // showed up.
    //
    // Every invoice is treated as an immediate cash sale (payment.mode = CASH,
    // paymentTerm = IMMIDIATE) with its own receipt sent in the same call. The invoice
    // must be Released first, so the amounts sent are final. "E-Receipt Counter" on the
    // Sales Header is obtained ONCE per invoice (via "E-Receipt Setup".
    // GetNextReceiptCounter, which is the persistent, auto-incrementing source) and then
    // reused on every attempt — a rejected/refused send never files its receipt, so
    // retrying it must not consume another counter value, or MoR's required "+1 per
    // receipt filed" sequence would have gaps. "E-Receipt Attempt No." (-> clientReference)
    // only advances on a genuine refusal (see StartNewAttempt); a plain retry after a
    // timeout/5xx/still-pending result reuses the same reference, which the guide
    // documents as safely idempotent as long as the body doesn't change.
    //
    // buyer.idType is hardcoded to 'KID' (buyer.idNumber = Customer No.) per instruction —
    // 'KID' is in the integration guide's documented MoR idType list (NID, KID, SID, WID,
    // PST, DLS, MRS), so no validation concern there.
    //
    // Response shape (confirmed against real responses, not just the guide): { "status",
    // "message", "data": { "invoice": { "id", "irn", "ackAt"/"ackDate", "signedQr"/
    // "signedQR" (base64 PNG), "status", "documentNumber", "signedInvoice",
    // "errorMessage", "errors" }, "receipt", "receiptError", "print" } }. No "links"
    // object actually shows up. A 202 means MoR hasn't decided yet (invoice.status
    // QUEUED/SUBMITTING/UNKNOWN) — PollUntilResolved below polls .../v1/invoices/{id}
    // briefly before giving up and telling the user it's still pending. "Open printable
    // receipt" (a separate action) builds .../v1/invoices/{id}/print the same way, using
    // "E-Receipt Invoice ID" captured once the invoice registers.
    //
    // Withholding: chosen on a per-line basis on the Sales Line itself ("Apply
    // Withholding" + "Withholding Code", see TableExt "Sales Line Withholding" and table
    // "Withholding Setup"), never automatic by customer. Sent as values.incomeWithholdValue
    // on the issue payload (BuildPayload) — DISPLAY-ONLY on this invoice, never subtracted
    // from the total.
    //
    // This codeunit does NOT, and must NOT, call POST /v1/receipts/withholding. That was
    // tried (type "IWHT", an unconfirmed extrapolation from the guide's "TWHT"-only
    // example) and removed after a real HTTP 400 proved the assumption wrong:
    // "IRN is a sale by <sellerTin>; the buyer (<buyerTin>) files the withholding receipt
    // as withholding agent, not the seller." Filing that receipt is the BUYER's
    // responsibility when they are a registered withholding agent, never the seller's —
    // this ERP is always the seller side of the invoices it issues, so there is no
    // scenario where this codeunit should be making that call. The invoice itself still
    // registers successfully regardless; only the (wrongly-attempted) second call failed.

    // Fetches MoR's own print DATA (confirmed via a real Postman test: GET with X-API-Key,
    // no forced Accept header, returns 200 JSON — not HTML/PDF as earlier assumed) and
    // renders it into report 51111 "Sales E-Receipt" using MoR's own authoritative
    // figures (seller/buyer/document/fiscal/lines/totals), not locally recomputed ones.
    // Requires "E-Receipt Invoice ID" to already be set, which only happens once "Print
    // e-receipt" has successfully registered the invoice at least once.
    procedure OpenPrintableReceipt(var SalesHeader: Record "Sales Header")
    var
        EReceiptSetup: Record "E-Receipt Setup";
        Client: HttpClient;
    begin
        if SalesHeader."E-Receipt Invoice ID" = '' then begin
            Message('Send the e-receipt first — there''s no registered MoR invoice to show a printable page for yet.');
            exit;
        end;
        EReceiptSetup := EReceiptSetup.GetOrInsert();
        // MoR's own real PDF (?format=pdf) first — confirmed via a real curl test to
        // return an actual PDF, not JSON. Falls back to the self-built HTML version (the
        // one guaranteed-working output from earlier testing) if that ever fails.
        if FetchAndDownloadPdf(EReceiptSetup, Client, SalesHeader."E-Receipt Invoice ID", SalesHeader."No.") then
            exit;
        if not FetchAndShowPrintReport(EReceiptSetup, Client, SalesHeader) then
            Message('The printable receipt data could not be fetched.');
    end;

    procedure SendEReceipt(var SalesHeader: Record "Sales Header")
    var
        EReceiptBuffer: Record "E-Receipt Buffer" temporary;
        EReceiptSetup: Record "E-Receipt Setup";
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        Payload: JsonObject;
        PayloadText: Text;
        Url: Text;
        ClientReference: Code[20];
        StatusCode: Integer;
    begin
        if not Confirm('This will send invoice %1 to the e-receipt service. Continue?', false, SalesHeader."No.") then
            exit;

        EReceiptSetup := EReceiptSetup.GetOrInsert();
        if (EReceiptSetup."API Key" = '') or (EReceiptSetup."System Number" = '') then begin
            Message('E-Receipt Setup is missing the API Key and/or System Number. Open the E-Receipt Setup page and fill it in first.');
            exit;
        end;
       // SalesHeader.TestField(Status, SalesHeader.Status::Released);

        // Same attempt number/reference on every retry until MoR actually refuses the
        // invoice (see StartNewAttempt) — reusing the SAME clientReference with an
        // IDENTICAL body is documented as safely idempotent, only a DIFFERENT body under
        // the same reference draws a 409. The receipt counter is obtained once per
        // invoice, ever, and kept even across a refusal/new attempt: a rejected invoice
        // never files its receipt, so retrying it must not consume another counter value.
        if SalesHeader."E-Receipt Attempt No." = 0 then
            SalesHeader."E-Receipt Attempt No." := 1;
        if SalesHeader."E-Receipt Counter" = 0 then
            SalesHeader."E-Receipt Counter" := EReceiptSetup.GetNextReceiptCounter();
        SalesHeader.Modify();
        // Bare document number on the normal/first attempt — only a genuine retry after a
        // rejection (attempt > 1) needs the "-<attempt>" suffix, to avoid colliding with
        // the previous (refused) attempt's own clientReference. Keeps what MoR echoes back
        // (and what shows on its own printed receipt as "Trans. ID") clean in the common
        // case instead of always showing "-1".
        if SalesHeader."E-Receipt Attempt No." <= 1 then
            ClientReference := SalesHeader."No."
        else
            ClientReference := CopyStr(StrSubstNo('%1-%2', SalesHeader."No.", SalesHeader."E-Receipt Attempt No."), 1, MaxStrLen(ClientReference));

        PopulateReceiptData(SalesHeader, ClientReference, EReceiptBuffer);

        Payload := BuildPayload(EReceiptBuffer, EReceiptSetup, SalesHeader."E-Receipt Counter");
        Payload.WriteTo(PayloadText);

        Content.WriteFrom(PayloadText);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        Client.DefaultRequestHeaders().Add('X-API-Key', EReceiptSetup."API Key");
        Client.DefaultRequestHeaders().Add('X-Correlation-Id', Format(CreateGuid()));

        Url := EReceiptSetup."Base URL" + '/v1/invoices/issue';
        if not Client.Post(Url, Content, Response) then begin
            Message('Could not reach the e-receipt service (network/timeout). Nothing was attached. Send again: the retry reuses reference %1, so nothing is filed twice.', ClientReference);
            exit;
        end;
        Response.Content().ReadAs(ResponseText);
        StatusCode := Response.HttpStatusCode();

        if StatusCode = 202 then
            if not PollUntilResolved(EReceiptSetup, Client, ResponseText) then begin
                Message('Invoice %1 was sent, but MoR has not decided yet (still QUEUED/SUBMITTING). Nothing was attached — send again shortly: the same reference is reused, so you get the result without filing twice.', SalesHeader."No.");
                exit;
            end;

        // Refused before MoR ever saw an invoice at all — the next send must use a new
        // clientReference, since whatever gets fixed will change the body.
        if StatusCode in [400, 404, 409] then begin
            StartNewAttempt(SalesHeader);
            Message('E-receipt service refused the request (HTTP %1). Fix the data and send again.', StatusCode);
            exit;
        end;

        // 401/5xx/anything else unexpected: keep the same reference, just retry later.
        if not (StatusCode in [200, 201, 202, 422]) then begin
            Message('E-receipt service returned HTTP %1. Nothing was attached. Send again later (same reference).', StatusCode);
            exit;
        end;

        // A 422 has TWO different shapes per the guide: a genuine MoR REJECTED invoice
        // (has "data.invoice.errors", handled by HandleResponse below) and a validation
        // failure caught before MoR ever saw it — totals-mismatch, date-out-of-range —
        // which uses the generic error shape {traceId, code, title, message, errors} with
        // NO "data" field at all. Caught here first so that second shape shows its real
        // reason instead of HandleResponse's generic "no data field" message.
        if (StatusCode = 422) and not HasDataField(ResponseText) then begin
            StartNewAttempt(SalesHeader);
            Message('E-receipt service rejected the request before it reached MoR (HTTP 422).\n%1', FormatGenericError(ResponseText));
            exit;
        end;

        if not HandleResponse(SalesHeader, EReceiptBuffer, ResponseText) then
            exit;

        if FetchAndDownloadPdf(EReceiptSetup, Client, SalesHeader."E-Receipt Invoice ID", SalesHeader."No.") then
            exit;
        if not FetchAndShowPrintReport(EReceiptSetup, Client, SalesHeader) then
            Message('Invoice %1 was registered with MoR, but the printable receipt data could not be fetched. Use "Open printable receipt" to try again.', SalesHeader."No.");
    end;

    // Re-fetches the record before modifying it — SalesHeader may have come in via a page
    // action's var parameter, and this can run after other work (polling, etc.) touched it.
    local procedure StartNewAttempt(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader."E-Receipt Attempt No." += 1;
        SalesHeader.Modify();
    end;

    // Polls the invoice's own status up to 3 times (3s apart — a bounded, short wait on
    // top of the initial call's own waitSeconds, not a background job) while MoR is still
    // deciding. On success, overwrites ResponseText with the resolved response so the
    // normal success path below reads from it exactly as if the first call had returned
    // it. Builds the poll URL itself from data.invoice.id — a real 202 response was
    // checked and had no "links" object at all (despite the guide documenting
    // data.links.self), so relying on that field meant this always failed instantly
    // without ever actually polling.
    local procedure PollUntilResolved(EReceiptSetup: Record "E-Receipt Setup"; var Client: HttpClient; var ResponseText: Text): Boolean
    var
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        DataJson: JsonObject;
        InvoiceJson: JsonObject;
        JTok: JsonToken;
        SelfUrl: Text;
        InvoiceId: Text;
        StatusText: Text;
        Attempt: Integer;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then exit(false);
        if not ResponseJson.Get('data', JTok) then exit(false);
        DataJson := JTok.AsObject();
        if not DataJson.Get('invoice', JTok) then exit(false);
        InvoiceJson := JTok.AsObject();
        if InvoiceJson.Get('id', JTok) then
            if JTok.IsValue() then
                if not JTok.AsValue().IsNull() then
                    InvoiceId := JTok.AsValue().AsText();
        if InvoiceId = '' then exit(false);
        SelfUrl := EReceiptSetup."Base URL" + '/v1/invoices/' + InvoiceId;

        for Attempt := 1 to 3 do begin
            Sleep(3000);
            if not Client.Get(SelfUrl, Response) then
                exit(false);
            Response.Content().ReadAs(ResponseText);
            if not ResponseJson.ReadFrom(ResponseText) then exit(false);
            if not ResponseJson.Get('data', JTok) then exit(false);
            DataJson := JTok.AsObject();
            StatusText := '';
            if DataJson.Get('invoice', JTok) then begin
                InvoiceJson := JTok.AsObject();
                if InvoiceJson.Get('status', JTok) and JTok.IsValue() then
                    StatusText := JTok.AsValue().AsText();
            end;
            case StatusText of
                'REGISTERED', 'REJECTED', 'MANUAL_REVIEW':
                    exit(true);
            end;
            // QUEUED / SUBMITTING / UNKNOWN — keep polling.
        end;
        exit(false);
    end;

    // Fills in everything derivable straight from the invoice — seller, customer,
    // totals, and one buffer row per line — exactly once, so BuildPayload (what gets
    // sent) and the printed receipt (report 51111) are guaranteed to show the same
    // figures. ClientReference is computed by the caller (SendEReceipt decides whether to
    // reuse the existing attempt or start a new one; PreviewEReceipt never burns either).
    local procedure PopulateReceiptData(var SalesHeader: Record "Sales Header"; ClientReference: Code[20]; var EReceiptBuffer: Record "E-Receipt Buffer" temporary)
    var
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ExciseSetupRec: Record "Excise Setup";
        LineNo: Integer;
        TotalExclVat: Decimal;
        TotalInclVat: Decimal;
        TotalVat: Decimal;
        InvDiscountAmount: Decimal;
        InvDiscAmountInclVat: Decimal;
        InvoiceDiscountPct: Decimal;
        UnitPriceExclVat: Decimal;
        LineDiscount: Decimal;
        TotalWithholding: Decimal;
        LineWithholdingAmount: Decimal;
        LineExcisePct: Decimal;
        LineExciseAmount: Decimal;
        TotalExciseAmount: Decimal;
        CustomerTin: Text[40];
        CustomerVatRegNo: Text[20];
        CustomerPhoneNo: Text[30];
        CustomerName: Text[100];
        SellerName: Text[100];
        SellerTin: Text[20];
        SellerAddress: Text[100];
        SellerCity: Text[30];
        SellerPhoneNo: Text[30];
    begin
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        TotalExclVat := SalesHeader.Amount;
        TotalInclVat := SalesHeader."Amount Including VAT";
        TotalVat := TotalInclVat - TotalExclVat;
        InvDiscountAmount := SalesHeader."Invoice Discount Amount";

        // Invoice Discount Amount (FlowField, Excl. VAT) is the only discount figure BC
        // stores on the header — there's no stored Incl.-VAT figure, so it's derived by
        // applying the invoice's overall VAT ratio. Exact for a single-VAT-rate invoice
        // (the norm here), an approximation if lines mix VAT rates.
        if TotalExclVat <> 0 then begin
            InvDiscAmountInclVat := InvDiscountAmount * (TotalInclVat / TotalExclVat);
            InvoiceDiscountPct := InvDiscountAmount / (TotalExclVat + InvDiscountAmount) * 100;
        end;

        // "Customer TIN No." is already auto-filled on the header by codeunit 51108
        // "Sales Header TIN Sync" when the customer was selected. VAT Registration No.
        // and Phone No. aren't mirrored onto Sales Header, so those two still need a
        // direct Customer lookup.
        CustomerTin := SalesHeader."Customer TIN No.";
        CustomerName := SalesHeader."Sell-to Customer Name";
        if Customer.Get(SalesHeader."Sell-to Customer No.") then begin
            CustomerVatRegNo := Customer."VAT Registration No.";
            CustomerPhoneNo := Customer."Phone No.";
        end;

        if CompanyInfo.Get() then begin
            SellerName := CompanyInfo.Name;
            SellerTin := CompanyInfo."VAT Registration No.";
            SellerAddress := CompanyInfo.Address;
            SellerCity := CompanyInfo.City;
            SellerPhoneNo := CompanyInfo."Phone No.";
        end;

        // Every real line (Item, Resource — not just Item), matching what MoR's gateway
        // actually totals against; a blank-type/zero-quantity line (comment lines, etc.)
        // is never a real sale line. G/L Account lines are EXCLUDED too — in this
        // business's existing flow those are used to manually book withholding, which is
        // now handled properly via "Apply Withholding" on the real item/service lines, so
        // sending them to MoR as if they were sold items would double things up.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1&<>%2', SalesLine.Type::" ", SalesLine.Type::"G/L Account");
        SalesLine.SetFilter(Quantity, '<>%1', 0);
        if SalesLine.FindSet() then
            repeat
                // preTaxValue must equal quantity x unitPrice - discount, with unitPrice
                // excl. VAT — derived from Sales Line's own Amount (always excl. VAT),
                // whether or not the invoice is set up to show prices including VAT.
                UnitPriceExclVat := SalesLine."Unit Price";
                if SalesHeader."Prices Including VAT" then
                    UnitPriceExclVat := Round(SalesLine."Unit Price" / (1 + SalesLine."VAT %" / 100), 0.00001);
                LineDiscount := SalesLine.Quantity * UnitPriceExclVat - SalesLine.Amount;
                if LineDiscount < 0 then begin
                    UnitPriceExclVat := Round(SalesLine.Amount / SalesLine.Quantity, 0.00001, '>');
                    LineDiscount := SalesLine.Quantity * UnitPriceExclVat - SalesLine.Amount;
                end;

                // Excise, per the EIMS tax calc reference: calculated on the FULL
                // pre-discount Line Total (Quantity x Unit Price excl. VAT) — discounts
                // never reduce the excise base. Looked up live from the Item's own
                // "Excise Code" rather than trusted from any stored Sales Line field, so
                // there's nothing here that can go stale the way "Withholding Amount" did.
                LineExcisePct := 0;
                if SalesLine.Type = SalesLine.Type::Item then
                    if Item.Get(SalesLine."No.") and (Item."Excise Code" <> '') then
                        if ExciseSetupRec.Get(Item."Excise Code") then
                            LineExcisePct := ExciseSetupRec."Excise %";
                LineExciseAmount := Round(SalesLine.Quantity * UnitPriceExclVat * LineExcisePct / 100, 0.01);
                TotalExciseAmount += LineExciseAmount;

                LineNo += 1;
                EReceiptBuffer.Init();
                EReceiptBuffer."Line Nature of Supplies" := LineNatureOfSupplies(SalesLine);
                EReceiptBuffer."Entry No." := 1;
                EReceiptBuffer."Line No." := LineNo;
                EReceiptBuffer."Document No." := ClientReference;
                EReceiptBuffer."Document Date" := SalesHeader."Document Date";
                EReceiptBuffer."Customer No." := SalesHeader."Sell-to Customer No.";
                EReceiptBuffer."Customer Name" := CustomerName;
                EReceiptBuffer."Customer TIN" := CustomerTin;
                EReceiptBuffer."Customer VAT Reg. No." := CustomerVatRegNo;
                EReceiptBuffer."Customer Phone No." := CustomerPhoneNo;
                EReceiptBuffer."Seller Name" := SellerName;
                EReceiptBuffer."Seller TIN" := SellerTin;
                EReceiptBuffer."Seller Address" := SellerAddress;
                EReceiptBuffer."Seller City" := SellerCity;
                EReceiptBuffer."Seller Phone No." := SellerPhoneNo;
                EReceiptBuffer."Total Excl. VAT" := TotalExclVat;
                EReceiptBuffer."Total VAT" := TotalVat;
                EReceiptBuffer."Total Incl. VAT" := TotalInclVat;
                EReceiptBuffer."Inv. Discount Amt. Incl. VAT" := InvDiscAmountInclVat;
                EReceiptBuffer."Invoice Discount %" := InvoiceDiscountPct;
                EReceiptBuffer."Line Item No." := SalesLine."No.";
                EReceiptBuffer."Line Description" := SalesLine.Description;
                EReceiptBuffer."Line Quantity" := SalesLine.Quantity;
                EReceiptBuffer."Line Unit Price" := UnitPriceExclVat;
                EReceiptBuffer."Line Amount" := SalesLine.Amount;
                EReceiptBuffer."Line Unit of Measure" := SalesLine."Unit of Measure Code";
                EReceiptBuffer."Line Discount Amount" := LineDiscount;
                EReceiptBuffer."Line VAT %" := SalesLine."VAT %";
                EReceiptBuffer."Line Amount Incl. VAT" := SalesLine."Amount Including VAT";
                // Recomputed here rather than trusted from the stored "Withholding Amount"
                // field: that field only gets refreshed by the OnValidate triggers on this
                // table's own withholding fields and by codeunit 51109's subscriber on
                // UpdateAmounts, so it can still go stale for a line whose withholding was
                // applied before this codeunit existed, or set by anything else that moves
                // Amount without re-raising those events. Recalculating from the CURRENT
                // Amount at send-time guarantees what's sent always matches MoR's own
                // expectation, independent of whatever state the stored field is in.
                if SalesLine."Apply Withholding" then
                    LineWithholdingAmount := Round(SalesLine.Amount * SalesLine."Withholding %" / 100, 0.01)
                else
                    LineWithholdingAmount := 0;
                EReceiptBuffer."Line Withholding %" := SalesLine."Withholding %";
                EReceiptBuffer."Line Withholding Amount" := LineWithholdingAmount;
                EReceiptBuffer."Line Excise %" := LineExcisePct;
                EReceiptBuffer."Line Excise Amount" := LineExciseAmount;
                if SalesLine."Apply Withholding" then
                    TotalWithholding += LineWithholdingAmount;
                EReceiptBuffer.Insert();
            until SalesLine.Next() = 0;

        // No Item lines on the invoice — still carry a single row so the header/totals
        // still have somewhere to live for the report and the payload.
        if LineNo = 0 then begin
            EReceiptBuffer.Init();
            EReceiptBuffer."Entry No." := 1;
            EReceiptBuffer."Line No." := 1;
            EReceiptBuffer."Document No." := ClientReference;
            EReceiptBuffer."Document Date" := SalesHeader."Document Date";
            EReceiptBuffer."Customer No." := SalesHeader."Sell-to Customer No.";
            EReceiptBuffer."Customer Name" := CustomerName;
            EReceiptBuffer."Customer TIN" := CustomerTin;
            EReceiptBuffer."Customer VAT Reg. No." := CustomerVatRegNo;
            EReceiptBuffer."Customer Phone No." := CustomerPhoneNo;
            EReceiptBuffer."Seller Name" := SellerName;
            EReceiptBuffer."Seller TIN" := SellerTin;
            EReceiptBuffer."Seller Address" := SellerAddress;
            EReceiptBuffer."Seller City" := SellerCity;
            EReceiptBuffer."Seller Phone No." := SellerPhoneNo;
            EReceiptBuffer."Total Excl. VAT" := TotalExclVat;
            EReceiptBuffer."Total VAT" := TotalVat;
            EReceiptBuffer."Total Incl. VAT" := TotalInclVat;
            EReceiptBuffer."Inv. Discount Amt. Incl. VAT" := InvDiscAmountInclVat;
            EReceiptBuffer."Invoice Discount %" := InvoiceDiscountPct;
            EReceiptBuffer.Insert();
        end;

        // Both totals are only known once the loop above finishes, so they're stamped on
        // afterward — same reason "Receipt Number"/"Receipt Counter" get a second pass in
        // BuildPayload rather than being known inline. Computed from the SAME filtered
        // line set actually sent as items[] (Item/Resource, not G/L Account) rather than
        // Sales Header's own "Total Withholding Amount" FlowField, which sums ALL Sales
        // Lines regardless of type — keeps "preTaxAmount" and "withholdingAmount" (sent
        // together to MoR) always consistent with each other and with what was sent.
        EReceiptBuffer.Reset();
        if EReceiptBuffer.FindSet(true) then
            repeat
                EReceiptBuffer."Total Withholding Amount" := TotalWithholding;
                EReceiptBuffer."Total Excise Amount" := TotalExciseAmount;
                EReceiptBuffer.Modify();
            until EReceiptBuffer.Next() = 0;
    end;

    // MoR/EIMS rejects an invoice whose natureOfSupplies doesn't match what it expects
    // for that item — confirmed by a real 422 ("must be the constant value 'service'")
    // after assuming every Item-type Sales Line was 'goods'. For an Item line the real
    // signal is the Item's own Type (Service -> service; Inventory/Non-Inventory ->
    // goods), not the Sales Line Type (which only tells you it's an Item, not what kind).
    // Resource lines are never physical goods, so those are 'service' outright. (G/L
    // Account lines never reach here at all — PopulateReceiptData excludes them before
    // this is ever called, since this business uses them for manually booking
    // withholding, not as sold items.)
    local procedure LineNatureOfSupplies(SalesLine: Record "Sales Line"): Text[10]
    var
        Item: Record Item;
    begin
        case SalesLine.Type of
            SalesLine.Type::Item:
                if Item.Get(SalesLine."No.") and (Item.Type = Item.Type::Service) then
                    exit('service');
            SalesLine.Type::Resource:
                exit('service');
        end;
        exit('goods');
    end;

    // MoR/EIMS enforces a strict enum for unit ([LTR, MTR, 101, PCS, ROL, MTS, PKG, SET,
    // KLG] per a real 422) AND a ^([A-Z|a-z]{3,8})$ format (letters only, 3-8 characters —
    // '101' from their own enum fails that regex, so it's effectively unusable). BC's
    // Unit of Measure Code is free text set up per company, so there's no way to map it
    // correctly in general — this covers the common cases and falls back to 'PCS' for
    // anything unrecognized, which is a guess, not a verified mapping.
    local procedure MapUnitOfMeasure(UomCode: Code[10]): Text[10]
    begin
        case UpperCase(UomCode) of
            'PCS', 'PC', 'EA', 'EACH', 'UNIT', 'NOS', 'NO':
                exit('PCS');
            'KG', 'KGS', 'KILO', 'KLG':
                exit('KLG');
            'L', 'LTR', 'LITER', 'LITRE':
                exit('LTR');
            'M', 'MTR', 'METER', 'METRE':
                exit('MTR');
            'BOX', 'PKG', 'PACK', 'CARTON':
                exit('PKG');
            'SET':
                exit('SET');
            'ROLL', 'ROL':
                exit('ROL');
            'MTS':
                exit('MTS');
            else
                exit('PCS');
        end;
    end;

    // The BC user actually logged in and clicking "Print e-receipt" — their Full Name from
    // the User table when set (a real person's name, e.g. "Kulani Melaku"), falling back
    // to the raw login ID (UserId()) if Full Name was never filled in for that user.
    local procedure CurrentUserDisplayName(): Text
    var
        UserRec: Record User;
    begin
        if UserRec.Get(UserSecurityId()) and (UserRec."Full Name" <> '') then
            exit(UserRec."Full Name");
        exit(UserId());
    end;

    local procedure BuildPayload(var EReceiptBuffer: Record "E-Receipt Buffer" temporary; EReceiptSetup: Record "E-Receipt Setup"; ReceiptCounter: Integer): JsonObject
    var
        Root: JsonObject;
        InvoiceObj: JsonObject;
        BuyerObj: JsonObject;
        ItemsArr: JsonArray;
        ItemObj: JsonObject;
        InvPaymentObj: JsonObject;
        ValuesObj: JsonObject;
        TopPaymentObj: JsonObject;
        TxnObj: JsonObject;
        LineNo: Integer;
        TransactionTypeText: Text;
        ReceiptNumberText: Text[30];
        VatPctInt: Integer;
        LineTaxAmount: Decimal;
        ExciseVatAmount: Decimal;
        LineTotalAmount: Decimal;
        SumTotal: Decimal;
        SumTax: Decimal;
        CashierNameText: Text[50];
    begin
        EReceiptBuffer.Reset();
        if not EReceiptBuffer.FindSet() then
            exit(Root);

        CashierNameText := CopyStr(CurrentUserDisplayName(), 1, MaxStrLen(CashierNameText));

        if EReceiptBuffer."Customer TIN" <> '' then
            TransactionTypeText := 'B2B'
        else
            TransactionTypeText := 'B2C';

        BuyerObj.Add('legalName', EReceiptBuffer."Customer Name");
        if EReceiptBuffer."Customer TIN" <> '' then
            BuyerObj.Add('tin', EReceiptBuffer."Customer TIN");
        if EReceiptBuffer."Customer VAT Reg. No." <> '' then
            BuyerObj.Add('vatNumber', EReceiptBuffer."Customer VAT Reg. No.");
        // idType/idNumber per instruction.
        BuyerObj.Add('idType', 'KID');
        BuyerObj.Add('idNumber', EReceiptBuffer."Customer No.");
        if EReceiptBuffer."Customer Phone No." <> '' then
            BuyerObj.Add('phone', EReceiptBuffer."Customer Phone No.");

        LineNo := 0;
        repeat
            LineNo += 1;
            VatPctInt := Round(EReceiptBuffer."Line VAT %", 1);
            // Base VAT-on-net calc is untouched (still BC's own "Amount Including VAT" -
            // "Amount", so a non-excisable line computes byte-for-byte as before); the
            // EIMS tax calc reference additionally taxes the excise amount itself, so that
            // portion is added on top. Both are 0 when "Line Excise Amount" is 0.
            ExciseVatAmount := Round(EReceiptBuffer."Line Excise Amount" * EReceiptBuffer."Line VAT %" / 100, 0.01);
            LineTaxAmount := (EReceiptBuffer."Line Amount Incl. VAT" - EReceiptBuffer."Line Amount") + ExciseVatAmount;
            LineTotalAmount := EReceiptBuffer."Line Amount" + EReceiptBuffer."Line Excise Amount" + LineTaxAmount;

            Clear(ItemObj);
            ItemObj.Add('lineNumber', LineNo);
            ItemObj.Add('itemCode', EReceiptBuffer."Line Item No.");
            ItemObj.Add('productDescription', EReceiptBuffer."Line Description");
            ItemObj.Add('natureOfSupplies', EReceiptBuffer."Line Nature of Supplies");
            ItemObj.Add('quantity', EReceiptBuffer."Line Quantity");
            ItemObj.Add('unit', MapUnitOfMeasure(EReceiptBuffer."Line Unit of Measure"));
            ItemObj.Add('unitPrice', EReceiptBuffer."Line Unit Price");
            ItemObj.Add('discount', EReceiptBuffer."Line Discount Amount");
            ItemObj.Add('preTaxValue', EReceiptBuffer."Line Amount");
            ItemObj.Add('exciseTaxValue', EReceiptBuffer."Line Excise Amount");
            ItemObj.Add('taxCode', StrSubstNo('VAT%1', VatPctInt));
            ItemObj.Add('taxAmount', LineTaxAmount);
            ItemObj.Add('totalLineAmount', LineTotalAmount);
            ItemsArr.Add(ItemObj);

            SumTotal += LineTotalAmount;
            SumTax += LineTaxAmount;
        until EReceiptBuffer.Next() = 0;

        InvPaymentObj.Add('mode', 'CASH');
        InvPaymentObj.Add('paymentTerm', 'IMMIDIATE');

        // Must be the sums of the lines actually sent, not the header's own totals — the
        // two can drift (e.g. a line excluded by the broader-than-Item filter elsewhere,
        // or rounding) and the gateway answers 422 totals-mismatch if they don't match.
        ValuesObj.Add('totalValue', SumTotal);
        ValuesObj.Add('taxValue', SumTax);
        ValuesObj.Add('currency', 'ETB');

        // "When the buyer is a withholding agent, put the withheld amount on the invoice"
        // (guide's Withholding section) — chosen as income withholding (incomeWithholdValue
        // / type "IWHT" on the follow-up receipt call) per instruction. Omitted entirely
        // when nothing on the invoice has withholding applied, rather than sending a 0.
        EReceiptBuffer.FindFirst();
        if EReceiptBuffer."Total Withholding Amount" > 0 then
            ValuesObj.Add('incomeWithholdValue', EReceiptBuffer."Total Withholding Amount");

        InvoiceObj.Add('systemNumber', EReceiptSetup."System Number");
        InvoiceObj.Add('clientReference', EReceiptBuffer."Document No.");
        InvoiceObj.Add('transactionType', TransactionTypeText);
        InvoiceObj.Add('documentType', 'INV');
        InvoiceObj.Add('cashierName', CashierNameText);
        InvoiceObj.Add('buyer', BuyerObj);
        InvoiceObj.Add('items', ItemsArr);
        InvoiceObj.Add('payment', InvPaymentObj);
        InvoiceObj.Add('values', ValuesObj);
        Root.Add('invoice', InvoiceObj);

        ReceiptNumberText := CopyStr(StrSubstNo('%1-R%2', EReceiptBuffer."Document No.", ReceiptCounter), 1, 30);

        TxnObj.Add('modeOfPayment', 'CASH');
        TxnObj.Add('collectorName', CashierNameText);

        TopPaymentObj.Add('receiptNumber', ReceiptNumberText);
        TopPaymentObj.Add('receiptCounter', Format(ReceiptCounter));
        TopPaymentObj.Add('transaction', TxnObj);
        Root.Add('payment', TopPaymentObj);

        Root.Add('waitSeconds', 10);

        // Carried onto every buffer row for the printed receipt / audit trail.
        EReceiptBuffer.Reset();
        if EReceiptBuffer.FindSet(true) then
            repeat
                EReceiptBuffer."Receipt Number" := ReceiptNumberText;
                EReceiptBuffer."Receipt Counter" := ReceiptCounter;
                EReceiptBuffer.Modify();
            until EReceiptBuffer.Next() = 0;

        exit(Root);
    end;

    local procedure HandleResponse(var SalesHeader: Record "Sales Header"; var EReceiptBuffer: Record "E-Receipt Buffer" temporary; ResponseText: Text): Boolean
    var
        ResponseJson: JsonObject;
        DataJson: JsonObject;
        InvoiceJson: JsonObject;
        JTok: JsonToken;
        StatusText: Text;
        ErrorMessageText: Text;
        IRNText: Text[250];
        AckDateText: Text[50];
        FiscalDocNoText: Text[20];
    begin
        if not ResponseJson.ReadFrom(ResponseText) then begin
            Message('The e-receipt service response was not valid JSON. Nothing was attached.');
            exit(false);
        end;
        if not ResponseJson.Get('data', JTok) then begin
            Message('The e-receipt service response had no "data" field. Nothing was attached.');
            exit(false);
        end;
        DataJson := JTok.AsObject();
        if not DataJson.Get('invoice', JTok) then begin
            Message('The e-receipt service response had no "data.invoice" field. Nothing was attached.');
            exit(false);
        end;
        InvoiceJson := JTok.AsObject();

        if InvoiceJson.Get('status', JTok) and JTok.IsValue() then
            StatusText := JTok.AsValue().AsText();
        // "errorMessage" crashed here on a real REJECTED response: it wasn't the plain
        // string/null this was written for, so AsValue() (unguarded) threw "Unable to
        // convert ... NavJsonToken to NavJsonValue." Guarded now, with an object/array
        // shape dumped as raw JSON rather than silently dropped.
        if InvoiceJson.Get('errorMessage', JTok) then
            if JTok.IsValue() then begin
                if not JTok.AsValue().IsNull() then
                    ErrorMessageText := JTok.AsValue().AsText();
            end else
                JTok.WriteTo(ErrorMessageText);
        ErrorMessageText += FormatInvoiceErrors(InvoiceJson);

        // A real REJECTED response seen from this service had "errorMessage" as null
        // AND no usable content in "errors" either — the old code showed a blank error,
        // which read as "Nothing was attached" with no clue why. Falling back to the raw
        // invoice JSON means a genuine rejection always shows SOMETHING to act on.
        if (ErrorMessageText = '') and (StatusText <> 'REGISTERED') and (StatusText <> '') then
            InvoiceJson.WriteTo(ErrorMessageText);

        if (StatusText <> 'REGISTERED') or (ErrorMessageText <> '') then begin
            // A genuine refusal — per the guide, fix the data and send as a new sale with
            // a new clientReference; the rejection itself never files a receipt, so the
            // counter obtained earlier is kept for that next attempt.
            if StatusText = 'REJECTED' then
                StartNewAttempt(SalesHeader);
            Message('The e-receipt was not issued.\nStatus: %1\nError: %2\nNothing was attached.', StatusText, ErrorMessageText);
            exit(false);
        end;

        // Null-safe: a real rejected-invoice response seen from this service had these as
        // explicit JSON null (not absent) — AsValue().AsText() on a JSON null isn't
        // guaranteed to come back as a clean empty string. Also tries both the casing
        // seen in an early sample (ackDate) and the casing seen in an actual
        // rejected-invoice response (ackAt).
        IRNText := CopyStr(GetJsonText(InvoiceJson, 'irn'), 1, MaxStrLen(IRNText));
        AckDateText := CopyStr(GetJsonTextAny(InvoiceJson, 'ackDate', 'ackAt'), 1, MaxStrLen(AckDateText));
        if InvoiceJson.Get('documentNumber', JTok) then
            if JTok.IsValue() then
                if not JTok.AsValue().IsNull() then
                    FiscalDocNoText := CopyStr(Format(JTok.AsValue()), 1, MaxStrLen(FiscalDocNoText));

        // Kept for "Open printable receipt" (a separate action, run independently of this
        // call) to build .../v1/invoices/{id}/print on its own.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader."E-Receipt Invoice ID" := CopyStr(GetJsonText(InvoiceJson, 'id'), 1, MaxStrLen(SalesHeader."E-Receipt Invoice ID"));
        SalesHeader.Modify();

        // No QR decoding here anymore — MoR's own printable page (fetched separately, see
        // FetchAndAttachPrintPage) already has the QR rendered in it, so there's nothing
        // left for this codeunit to decode or import. An earlier version did decode
        // data.invoice.signedQr into this buffer's "QR Image" field for a self-built PDF;
        // that field is unused now but left on the table in case a self-built layout is
        // needed again later.
        EReceiptBuffer.Reset();
        if EReceiptBuffer.FindSet(true) then
            repeat
                EReceiptBuffer.IRN := IRNText;
                EReceiptBuffer."Ack Date" := AckDateText;
                EReceiptBuffer.Status := CopyStr(StatusText, 1, MaxStrLen(EReceiptBuffer.Status));
                EReceiptBuffer."Fiscal Document No." := FiscalDocNoText;
                EReceiptBuffer.Modify();
            until EReceiptBuffer.Next() = 0;

        exit(true);
    end;

    local procedure HasDataField(ResponseText: Text): Boolean
    var
        ResponseJson: JsonObject;
        JTok: JsonToken;
    begin
        exit(ResponseJson.ReadFrom(ResponseText) and ResponseJson.Get('data', JTok));
    end;

    // Formats the guide's generic error shape ({traceId, code, title, message, errors?,
    // status, timestamp}) into something readable, instead of dumping the raw JSON —
    // used for a 422/400/etc. that was refused before MoR ever saw the invoice.
    local procedure FormatGenericError(ResponseText: Text): Text
    var
        ResponseJson: JsonObject;
        ErrorObj: JsonObject;
        JTok: JsonToken;
        ErrorElement: JsonToken;
        ResultText: Text;
        TitleText: Text;
        MessageText: Text;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then
            exit('(response was not valid JSON)');

        TitleText := GetJsonText(ResponseJson, 'title');
        MessageText := GetJsonText(ResponseJson, 'message');
        if (TitleText <> '') and (MessageText <> '') then
            ResultText := StrSubstNo('%1: %2', TitleText, MessageText)
        else
            ResultText := TitleText + MessageText;

        if ResponseJson.Get('errors', JTok) and JTok.IsArray() then
            foreach ErrorElement in JTok.AsArray() do
                if ErrorElement.IsObject() then begin
                    ErrorObj := ErrorElement.AsObject();
                    ResultText += StrSubstNo('\n- %1: %2', GetJsonText(ErrorObj, 'location'), GetJsonText(ErrorObj, 'message'));
                end;

        exit(ResultText);
    end;

    // "data.invoice.errors" (a genuine REJECTED invoice) isn't documented with a fixed
    // shape the way the generic error envelope is, so this is deliberately tolerant:
    // tries the field names the guide's OTHER error shape uses first, and if an element
    // doesn't match any of them, dumps that element's raw JSON rather than silently
    // dropping it — seeing something unparsed beats seeing nothing at all.
    local procedure FormatInvoiceErrors(InvoiceJson: JsonObject): Text
    var
        ErrorObj: JsonObject;
        JTok: JsonToken;
        ErrorElement: JsonToken;
        ResultText: Text;
        PartText: Text;
        LocationText: Text;
        RawText: Text;
    begin
        if not InvoiceJson.Get('errors', JTok) then
            exit('');
        if JTok.IsValue() then
            if JTok.AsValue().IsNull() then
                exit('');

        if JTok.IsArray() then begin
            foreach ErrorElement in JTok.AsArray() do begin
                Clear(PartText);
                if ErrorElement.IsObject() then begin
                    ErrorObj := ErrorElement.AsObject();
                    PartText := GetJsonText(ErrorObj, 'message');
                    if PartText = '' then
                        PartText := GetJsonText(ErrorObj, 'reason');
                    if PartText = '' then
                        PartText := GetJsonText(ErrorObj, 'description');
                    LocationText := GetJsonText(ErrorObj, 'location');
                    if LocationText = '' then
                        LocationText := GetJsonText(ErrorObj, 'field');
                    if PartText = '' then begin
                        Clear(RawText);
                        ErrorElement.WriteTo(RawText);
                        PartText := RawText;
                    end else
                        if LocationText <> '' then
                            PartText := StrSubstNo('%1: %2', LocationText, PartText);
                end else begin
                    Clear(RawText);
                    ErrorElement.WriteTo(RawText);
                    PartText := RawText;
                end;
                ResultText += '\n- ' + PartText;
            end;
            exit(ResultText);
        end;

        JTok.WriteTo(RawText);
        exit(RawText);
    end;

    // Returns '' for an absent key AND for an explicit JSON null — unlike calling
    // JsonValue.AsText() directly on a null token, whose return value for null isn't
    // something this codebase was able to verify is a clean empty string (the
    // signedQR-crash this guards against is consistent with it not being one).
    local procedure GetJsonText(Obj: JsonObject; KeyName: Text): Text
    var
        JTok: JsonToken;
    begin
        // AL does NOT short-circuit "and" — every term in a compound condition is always
        // evaluated, so "X and Y.AsValue()" calls AsValue() even when X is false. Nested
        // ifs are the only way to actually guard a converting call like AsValue()/
        // AsObject()/AsArray(). (Root cause of a real "Unable to convert ... NavJsonToken
        // to NavJsonValue" crash on a REJECTED invoice whose fields weren't plain values.)
        if Obj.Get(KeyName, JTok) then
            if JTok.IsValue() then
                if not JTok.AsValue().IsNull() then
                    exit(JTok.AsValue().AsText());
        exit('');
    end;

    // Tries KeyName1 first, falls back to KeyName2 — covers the field-name casing seen
    // in an early sample response (ackDate/signedQR) vs. the casing seen in an actual
    // rejected-invoice response from this service (ackAt/signedQr); which one a genuine
    // REGISTERED response actually uses isn't confirmed yet.
    local procedure GetJsonTextAny(Obj: JsonObject; KeyName1: Text; KeyName2: Text): Text
    var
        ResultText: Text;
    begin
        ResultText := GetJsonText(Obj, KeyName1);
        if ResultText <> '' then
            exit(ResultText);
        exit(GetJsonText(Obj, KeyName2));
    end;

    // The e-sign doc's actual query values for .../print?paper=<value> are a4/80/58 —
    // not "a4"/"80mm"/"58mm" as a literal reading of the enum captions might suggest.
    local procedure PaperSizeQueryValue(PaperSize: Enum "E-Receipt Paper Size"): Text
    begin
        case PaperSize of
            PaperSize::Mm80:
                exit('80');
            PaperSize::Mm58:
                exit('58');
            else
                exit('a4');
        end;
    end;

    // GET .../print?paper=<size> — confirmed via a real Postman/curl test (X-API-Key
    // header, no Accept header forced) to return 200 JSON print data by default, and the
    // full integration guide's own example (?format=html&paper=a4) confirms "paper" is
    // the real parameter name. An earlier version used an empty parameter name ("?=") per
    // an ambiguous one-off test result; the guide is the more trustworthy source now that
    // it's actually been shared in full.
    local procedure PrintPageUrl(EReceiptSetup: Record "E-Receipt Setup"; InvoiceId: Text): Text
    begin
        exit(EReceiptSetup."Base URL" + '/v1/invoices/' + InvoiceId + '/print?paper=' + PaperSizeQueryValue(EReceiptSetup."Paper Size"));
    end;

    // Fetches MoR's own real, ready-made PDF (?format=pdf&paper=<size>) — confirmed via a
    // real curl test to return an actual PDF, not the JSON the same endpoint returns
    // without that parameter. This is the primary path: no self-built layout, no QR
    // handling, no BC Report engine involved at all — just MoR's own bytes, relayed
    // straight to the browser's download prompt.
    local procedure FetchAndDownloadPdf(EReceiptSetup: Record "E-Receipt Setup"; var Client: HttpClient; InvoiceId: Text; DocumentNo: Text): Boolean
    var
        Response: HttpResponseMessage;
        InStr: InStream;
        Url: Text;
        FileName: Text;
    begin
        if InvoiceId = '' then
            exit(false);

        if not Client.DefaultRequestHeaders().Contains('X-API-Key') then
            Client.DefaultRequestHeaders().Add('X-API-Key', EReceiptSetup."API Key");

        Url := EReceiptSetup."Base URL" + '/v1/invoices/' + InvoiceId + '/print?format=pdf&paper=' + PaperSizeQueryValue(EReceiptSetup."Paper Size");
        if not Client.Get(Url, Response) then
            exit(false);
        if not Response.IsSuccessStatusCode() then
            exit(false);

        Response.Content().ReadAs(InStr);
        FileName := StrSubstNo('E-Receipt - %1.pdf', DocumentNo);
        DownloadFromStream(InStr, '', '', '', FileName);
        exit(true);
    end;

    // Fetches MoR's print data with the same X-API-Key as everything else — confirmed via
    // a real Postman/curl test to return 200 JSON (not HTML/PDF) when this header is sent
    // with no Accept header forced. On success, renders it straight into report 51111.
    local procedure FetchAndShowPrintReport(EReceiptSetup: Record "E-Receipt Setup"; var Client: HttpClient; var SalesHeader: Record "Sales Header"): Boolean
    var
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        ResponseText: Text;
        Url: Text;
    begin
        if SalesHeader."E-Receipt Invoice ID" = '' then
            exit(false);

        if not Client.DefaultRequestHeaders().Contains('X-API-Key') then
            Client.DefaultRequestHeaders().Add('X-API-Key', EReceiptSetup."API Key");

        Url := PrintPageUrl(EReceiptSetup, SalesHeader."E-Receipt Invoice ID");
        if not Client.Get(Url, Response) then
            exit(false);
        Response.Content().ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);

        ShowPrintDataReport(ResponseJson, SalesHeader);
        exit(true);
    end;

    // Builds the "E-Receipt Buffer" temporary records straight from MoR's own print JSON
    // (seller/buyer/document/fiscal/lines/totals) — MoR's authoritative figures, not the
    // locally recomputed ones BuildPayload sends — and runs report 51111 to show them.
    // The QR (fiscal.qrPngBase64) is decoded the same safe way as everywhere else in this
    // codeunit: only the base64 decode (no database write) is inside TryFunction;
    // ImportStream/Insert run as ordinary code outside it.
    // Builds the receipt as a plain HTML document — no Report object, no RDLC, no Media
    // field, no Report.* call at all. Every single rendering path tried through BC's
    // Report engine (Report.Run as a Record, as an explicit Variant, as a RecordRef;
    // Report.RunModal; Report.SaveAs) either crashed the session, errored "the report was
    // empty" despite confirmed data present, or silently produced 0 bytes while reporting
    // success — a real platform issue in this environment, not a data problem. Plain HTML
    // sidesteps all of it: the QR embeds directly as a data: URI from the base64 string
    // MoR already provides, with no decode/ImportStream/Insert needed at all.
    local procedure ShowPrintDataReport(ResponseJson: JsonObject; var SalesHeader: Record "Sales Header")
    var
        DataJson: JsonObject;
        SellerJson: JsonObject;
        BuyerJson: JsonObject;
        DocumentJson: JsonObject;
        FiscalJson: JsonObject;
        TotalsJson: JsonObject;
        PaymentJson: JsonObject;
        LinesArr: JsonArray;
        LineJson: JsonObject;
        JTok: JsonToken;
        LineElement: JsonToken;
        SellerAddressText: Text;
        QrBase64: Text;
        BuyerIdLabel: Text;
        LineDiscountText: Text;
        LineRowsHtml: Text;
        IncomeWithholdingAmt: Decimal;
        SubtotalAmt: Decimal;
        WithholdingPct: Decimal;
        HtmlDoc: TextBuilder;
        HtmlBlob: Codeunit "Temp Blob";
        HtmlOutStr: OutStream;
        HtmlInStr: InStream;
        HtmlFileName: Text;
    begin
        if ResponseJson.Get('data', JTok) and JTok.IsObject() then
            DataJson := JTok.AsObject();

        if DataJson.Get('seller', JTok) and JTok.IsObject() then
            SellerJson := JTok.AsObject();
        if DataJson.Get('buyer', JTok) and JTok.IsObject() then
            BuyerJson := JTok.AsObject();
        if DataJson.Get('document', JTok) and JTok.IsObject() then
            DocumentJson := JTok.AsObject();
        if DataJson.Get('fiscal', JTok) and JTok.IsObject() then
            FiscalJson := JTok.AsObject();
        if DataJson.Get('totals', JTok) and JTok.IsObject() then
            TotalsJson := JTok.AsObject();
        if DataJson.Get('payment', JTok) and JTok.IsObject() then
            PaymentJson := JTok.AsObject();
        if DataJson.Get('lines', JTok) and JTok.IsArray() then
            LinesArr := JTok.AsArray();

        SellerAddressText := JoinAddressArray(SellerJson);
        QrBase64 := GetJsonText(FiscalJson, 'qrPngBase64');
        BuyerIdLabel := GetJsonText(BuyerJson, 'idType');
        if BuyerIdLabel = '' then
            BuyerIdLabel := 'ID';

        foreach LineElement in LinesArr do begin
            LineJson := LineElement.AsObject();
            if GetJsonDecimal(LineJson, 'discount') = 0 then
                LineDiscountText := '–'
            else
                LineDiscountText := Format(GetJsonDecimal(LineJson, 'discount'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>');
            LineRowsHtml += StrSubstNo(
                '<tr><td>%1</td><td class="r">%2</td><td>%3</td><td class="r">%4</td><td class="r">%5</td><td><span class="badge">%6</span></td><td class="r">%7</td><td class="r">%8</td></tr>',
                HtmlEncode(GetJsonText(LineJson, 'description')),
                Format(GetJsonDecimal(LineJson, 'quantity'), 0, '<Precision,0:5><Integer><Decimals>'),
                HtmlEncode(GetJsonText(LineJson, 'unit')),
                Format(GetJsonDecimal(LineJson, 'unitPrice'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>'),
                LineDiscountText,
                HtmlEncode(GetJsonText(LineJson, 'taxCode')),
                Format(GetJsonDecimal(LineJson, 'taxAmount'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>'),
                Format(GetJsonDecimal(LineJson, 'total'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>'));
        end;

        HtmlDoc.Append('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Tax Invoice</title><style>');
        HtmlDoc.Append('@media print{@page{size:A4 portrait;margin:12mm}}');
        HtmlDoc.Append('body{font-family:Segoe UI,Arial,sans-serif;margin:0 auto;padding:24px;color:#1b2434;background:#fff;max-width:820px}');
        HtmlDoc.Append('.hdr{display:flex;justify-content:space-between;align-items:flex-start;border-bottom:2px solid #1b2a4a;padding-bottom:14px}');
        HtmlDoc.Append('.company{font-size:19px;font-weight:700;color:#1b2a4a}');
        HtmlDoc.Append('.muted{color:#667085;font-size:12px}');
        HtmlDoc.Append('.doctitle{font-size:22px;font-weight:700;color:#1b2a4a;text-align:right}');
        HtmlDoc.Append('.badges{margin-top:10px}');
        HtmlDoc.Append('.badge{display:inline-block;border:1px solid #c7d0e0;background:#f3f6fb;border-radius:14px;padding:2px 10px;font-size:11px;font-weight:600;color:#1b2a4a;margin-right:6px}');
        HtmlDoc.Append('.infobar{display:flex;background:#f3f6fb;border:1px solid #e1e7f0;border-radius:8px;margin-top:16px}');
        HtmlDoc.Append('.infobar div{flex:1;padding:10px 14px;border-right:1px solid #e1e7f0}');
        HtmlDoc.Append('.infobar div:last-child{border-right:none}');
        HtmlDoc.Append('.infolbl{font-size:10px;color:#667085;text-transform:uppercase;letter-spacing:.03em}');
        HtmlDoc.Append('.infoval{font-weight:700;font-size:13px;margin-top:2px}');
        HtmlDoc.Append('.main{display:flex;gap:20px;margin-top:20px}');
        HtmlDoc.Append('.billto{flex:1}.billto .name{font-weight:700;font-size:14px;margin-bottom:4px}');
        HtmlDoc.Append('.billto .row{font-size:12px;color:#3a4656;margin-top:2px}');
        HtmlDoc.Append('.qrcard{width:230px;border:1px solid #e1e7f0;border-radius:8px;padding:14px;text-align:center}');
        HtmlDoc.Append('.qrcard .lbl{font-size:10px;color:#667085;text-transform:uppercase;letter-spacing:.04em}');
        HtmlDoc.Append('.qrcard .verify{font-weight:700;color:#1b2a4a;font-size:12px;margin:2px 0 10px}');
        HtmlDoc.Append('.qrcard img{width:150px;height:150px}');
        HtmlDoc.Append('.qrcard .irn{font-size:9px;color:#667085;word-break:break-all;margin-top:10px}');
        HtmlDoc.Append('table.items{border-collapse:collapse;width:100%;margin-top:20px}');
        HtmlDoc.Append('table.items th,table.items td{border:1px solid #c7d0e0;padding:6px 8px;font-size:12px}');
        HtmlDoc.Append('table.items th{background:#E3E9F2;text-align:left;font-size:10px;text-transform:uppercase;color:#1b2a4a}');
        HtmlDoc.Append('.r{text-align:right}');
        HtmlDoc.Append('.totals{width:280px;margin-left:auto;margin-top:10px}');
        HtmlDoc.Append('.totals td{padding:3px 8px;font-size:13px}');
        HtmlDoc.Append('.totals .tot td{border-top:2px solid #1b2a4a;font-weight:700;font-size:16px;padding-top:6px}');
        HtmlDoc.Append('.footer{margin-top:24px;text-align:center;font-size:11px;color:#667085}');
        HtmlDoc.Append('</style></head><body>');

        HtmlDoc.Append('<div class="hdr"><div>');
        HtmlDoc.Append(StrSubstNo('<div class="company">%1</div>', HtmlEncode(TitleCaseCompanyName(GetJsonText(SellerJson, 'legalName')))));
        HtmlDoc.Append(StrSubstNo('<div class="muted">%1</div>', HtmlEncode(SellerAddressText)));
        HtmlDoc.Append(StrSubstNo('<div class="muted">Tel %1 &#183; %2</div>', HtmlEncode(GetJsonText(SellerJson, 'phone')), HtmlEncode(GetJsonText(SellerJson, 'email'))));
        HtmlDoc.Append('<div class="badges">');
        HtmlDoc.Append(StrSubstNo('<span class="badge">TIN %1</span>', HtmlEncode(GetJsonText(SellerJson, 'tin'))));
        if GetJsonText(SellerJson, 'vatNumber') <> '' then
            HtmlDoc.Append(StrSubstNo('<span class="badge">VAT %1</span>', HtmlEncode(GetJsonText(SellerJson, 'vatNumber'))));
        HtmlDoc.Append('</div></div><div>');
        HtmlDoc.Append('<div class="doctitle">TAX INVOICE</div>');
        HtmlDoc.Append(StrSubstNo('<div class="muted r">No. %1</div>', HtmlEncode(SalesHeader."No.")));
        HtmlDoc.Append('</div></div>');

        HtmlDoc.Append('<div class="infobar">');
        HtmlDoc.Append(StrSubstNo('<div><div class="infolbl">Issue Date</div><div class="infoval">%1</div></div>', HtmlEncode(GetJsonText(DocumentJson, 'date'))));
        HtmlDoc.Append(StrSubstNo('<div><div class="infolbl">Reference</div><div class="infoval">%1</div></div>', HtmlEncode(GetJsonText(DocumentJson, 'clientReference'))));
        HtmlDoc.Append(StrSubstNo('<div><div class="infolbl">Transaction</div><div class="infoval">%1</div></div>', HtmlEncode(GetJsonText(DocumentJson, 'transactionType'))));
        HtmlDoc.Append(StrSubstNo('<div><div class="infolbl">Payment</div><div class="infoval">%1 &#183; %2</div></div>',
            HtmlEncode(GetJsonText(PaymentJson, 'mode')), HtmlEncode(GetJsonText(PaymentJson, 'term'))));
        HtmlDoc.Append(StrSubstNo('<div><div class="infolbl">Currency</div><div class="infoval">%1</div></div>', HtmlEncode(GetJsonText(TotalsJson, 'currency'))));
        HtmlDoc.Append('</div>');

        HtmlDoc.Append('<div class="main"><div class="billto">');
        HtmlDoc.Append('<div class="infolbl">Bill To</div>');
        HtmlDoc.Append(StrSubstNo('<div class="name">%1</div>', HtmlEncode(GetJsonText(BuyerJson, 'legalName'))));
        if GetJsonText(BuyerJson, 'tin') <> '' then
            HtmlDoc.Append(StrSubstNo('<div class="row">TIN  %1</div>', HtmlEncode(GetJsonText(BuyerJson, 'tin'))));
        if GetJsonText(BuyerJson, 'idNumber') <> '' then
            HtmlDoc.Append(StrSubstNo('<div class="row">%1  %2</div>', HtmlEncode(BuyerIdLabel), HtmlEncode(GetJsonText(BuyerJson, 'idNumber'))));
        if GetJsonText(BuyerJson, 'phone') <> '' then
            HtmlDoc.Append(StrSubstNo('<div class="row">Tel  %1</div>', HtmlEncode(GetJsonText(BuyerJson, 'phone'))));
        HtmlDoc.Append('</div>');

        HtmlDoc.Append('<div class="qrcard">');
        HtmlDoc.Append('<div class="lbl">Ministry of Revenue &#183; EIMS</div>');
        HtmlDoc.Append('<div class="verify">Scan to verify this invoice</div>');
        if QrBase64 <> '' then
            HtmlDoc.Append(StrSubstNo('<img src="data:image/png;base64,%1">', QrBase64));
        HtmlDoc.Append(StrSubstNo('<div class="irn"><b>IRN</b><br>%1</div>', HtmlEncode(GetJsonText(FiscalJson, 'irn'))));
        HtmlDoc.Append(StrSubstNo('<div class="irn"><b>REGISTERED</b><br>%1</div>', HtmlEncode(GetJsonText(FiscalJson, 'acknowledgedAt'))));
        HtmlDoc.Append('</div></div>');

        HtmlDoc.Append('<table class="items"><tr><th>Description</th><th class="r">Qty</th><th>Unit</th><th class="r">Unit Price</th><th class="r">Discount</th><th>Tax</th><th class="r">Tax Amount</th><th class="r">Amount</th></tr>');
        HtmlDoc.Append(LineRowsHtml);
        HtmlDoc.Append('</table>');

        HtmlDoc.Append('<table class="totals">');
        HtmlDoc.Append(StrSubstNo('<tr><td>Subtotal</td><td class="r">%1</td></tr>',
            Format(GetJsonDecimal(TotalsJson, 'subtotal'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>')));
        HtmlDoc.Append(StrSubstNo('<tr><td>Tax</td><td class="r">%1</td></tr>',
            Format(GetJsonDecimal(TotalsJson, 'tax'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>')));
        IncomeWithholdingAmt := GetJsonDecimal(TotalsJson, 'incomeWithholding');
        if IncomeWithholdingAmt > 0 then begin
            SubtotalAmt := GetJsonDecimal(TotalsJson, 'subtotal');
            if SubtotalAmt <> 0 then
                WithholdingPct := Round(IncomeWithholdingAmt / SubtotalAmt * 100, 0.01);
            HtmlDoc.Append(StrSubstNo('<tr><td>Withholding (%1%%)</td><td class="r">-%2</td></tr>',
                Format(WithholdingPct, 0, '<Precision,2:2><Integer><Decimals>'),
                Format(IncomeWithholdingAmt, 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>')));
        end;
        HtmlDoc.Append(StrSubstNo('<tr class="tot"><td>Total (%1)</td><td class="r">%2</td></tr>',
            HtmlEncode(GetJsonText(TotalsJson, 'currency')),
            Format(GetJsonDecimal(TotalsJson, 'total'), 0, '<Precision,2:2><Sign><Integer Thousand><Decimals>')));
        HtmlDoc.Append('</table>');

        HtmlDoc.Append(StrSubstNo('<div class="footer">%1</div>', HtmlEncode(GetJsonText(DataJson, 'footer'))));
        HtmlDoc.Append('</body></html>');

        // Real PDF rendering (Report.SaveAs with a real, non-temporary row) was tested and
        // confirmed to silently produce 0 bytes in this environment — a server-side
        // limitation (likely a missing PDF-rendering component on the BC service tier),
        // not a data or code problem. Sticking with the HTML version, which is confirmed
        // to work and opens/prints fine from any browser.
        HtmlBlob.CreateOutStream(HtmlOutStr, TextEncoding::UTF8);
        HtmlOutStr.WriteText(HtmlDoc.ToText());
        HtmlBlob.CreateInStream(HtmlInStr, TextEncoding::UTF8);
        HtmlFileName := StrSubstNo('E-Receipt - %1.html', SalesHeader."No.");
        DownloadFromStream(HtmlInStr, '', '', '', HtmlFileName);
    end;

    // Title-cases a company name coming back from the API in whatever casing it happens
    // to use (e.g. "Kifiya financial technology plc") — common legal-entity suffixes are
    // kept fully uppercase (PLC, LLC, LTD, INC, LLP) rather than title-cased.
    local procedure TitleCaseCompanyName(Value: Text): Text
    var
        ResultText: Text;
        Word: Text;
        Remaining: Text;
        SpacePos: Integer;
    begin
        Remaining := Value;
        while Remaining <> '' do begin
            SpacePos := StrPos(Remaining, ' ');
            if SpacePos = 0 then begin
                Word := Remaining;
                Remaining := '';
            end else begin
                Word := CopyStr(Remaining, 1, SpacePos - 1);
                Remaining := CopyStr(Remaining, SpacePos + 1);
            end;
            if Word <> '' then begin
                if ResultText <> '' then
                    ResultText += ' ';
                case UpperCase(Word) of
                    'PLC', 'LLC', 'LTD', 'INC', 'LLP':
                        ResultText += UpperCase(Word);
                    else
                        ResultText += UpperCase(CopyStr(Word, 1, 1)) + LowerCase(CopyStr(Word, 2));
                end;
            end;
        end;
        exit(ResultText);
    end;

    // Minimal HTML-escaping for text embedded into attribute-free text nodes — guards
    // against a customer/seller name containing '<', '>', or '&' breaking the markup.
    local procedure HtmlEncode(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        exit(Value);
    end;

    local procedure JoinAddressArray(Obj: JsonObject): Text
    var
        JTok: JsonToken;
        AddrArr: JsonArray;
        Element: JsonToken;
        ResultText: Text;
    begin
        if not (Obj.Get('address', JTok) and JTok.IsArray()) then
            exit('');
        AddrArr := JTok.AsArray();
        foreach Element in AddrArr do begin
            if Element.IsValue() then
                if not Element.AsValue().IsNull() then begin
                    if ResultText <> '' then
                        ResultText += ', ';
                    ResultText += Element.AsValue().AsText();
                end;
        end;
        exit(ResultText);
    end;

    local procedure GetJsonDecimal(Obj: JsonObject; KeyName: Text): Decimal
    var
        JTok: JsonToken;
    begin
        if Obj.Get(KeyName, JTok) then
            if JTok.IsValue() then
                if not JTok.AsValue().IsNull() then
                    exit(JTok.AsValue().AsDecimal());
        exit(0);
    end;

}
