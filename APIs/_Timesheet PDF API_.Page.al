page 51115 "Timesheet PDF API"
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    Caption = 'Timesheet PDF API';
    EntityName = 'TimesheetPdf';
    EntitySetName = 'TimesheetPdfs';
    PageType = API;
    SourceTable = "Monthly Timesheet Header";
    ODataKeyFields = "No.";
    Editable = false;
    DelayedInsert = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no;Rec."No.")
                {
                    Caption = 'No.';
                }
                field(employeeNo;Rec."Employee No.")
                {
                    Caption = 'Employee No.';
                }
                field(month;Rec.Month)
                {
                    Caption = 'Month';
                }
                field(year;Rec.Year)
                {
                    Caption = 'Year';
                }
                field(status;Rec.Status)
                {
                    Caption = 'Status';
                }
                field(pdfContent;PdfContent)
                {
                    Caption = 'PDF Content';
                }
            }
        }
    }
    trigger OnAfterGetRecord()begin
        PdfContent:=GenerateTimesheetPdf(Rec."No.");
    end;
    var PdfContent: Text;
    local procedure GenerateTimesheetPdf(DocNo: Code[20]): Text var Header: Record "Monthly Timesheet Header";
    TempBlob: Codeunit "Temp Blob";
    Base64Conv: Codeunit "Base64 Convert";
    OutStr: OutStream;
    InStr: InStream;
    RecRef: RecordRef;
    begin
        Header.SetRange("No.", DocNo);
        if not Header.FindFirst()then exit('');
        TempBlob.CreateOutStream(OutStr);
        RecRef.GetTable(Header);
        if not Report.SaveAs(Report::Timesheet, '', ReportFormat::Pdf, OutStr, RecRef)then exit('');
        TempBlob.CreateInStream(InStr);
        exit(Base64Conv.ToBase64(InStr));
    end;
}
