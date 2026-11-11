codeunit 51111 "Timesheet Approval Web API"
{
    Subtype = Normal;

    /// <summary>
 
/// Get Timesheets Pending Approval for a specific approver 
 
/// </summary>
[ServiceEnabled]
    procedure GetPendingTimesheets(ApproverUserID: Code[50])Result: Text var Header: Record "Monthly Timesheet Header";
    ApprovalEntry: Record "Timesheet Approval Entry";
    Employee: Record Employee;
    JsonArray: Text;
    JsonObject: Text;
    FirstRecord: Boolean;
    begin
        JsonArray:='[';
        FirstRecord:=true;
        // Find all approval entries pending for this approver
        ApprovalEntry.SetRange("Approver ID", ApproverUserID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if ApprovalEntry.FindSet()then begin
            repeat if Header.Get(ApprovalEntry."Timesheet No.")then begin
                    if not FirstRecord then JsonArray+=',';
                    JsonObject:='{';
                    JsonObject+='"timesheetNo":"' + Format(Header."No.") + '",';
                    JsonObject+='"employeeNo":"' + Format(Header."Employee No.") + '",';
                    // Get employee name
                    if Employee.Get(Header."Employee No.")then JsonObject+='"employeeName":"' + Employee."First Name" + ' ' + Employee."Last Name" + '",'
                    else
                        JsonObject+='"employeeName":"",';
                    JsonObject+='"month":"' + Format(Header.Month) + '",';
                    JsonObject+='"year":' + Format(Header.Year) + ',';
                    JsonObject+='"totalHours":' + Format(Header."Total Hours") + ',';
                    JsonObject+='"status":"' + Format(Header.Status) + '",';
                    JsonObject+='"submittedDate":"' + Format(ApprovalEntry."Date-Time Sent", 0, 9) + '",';
                    JsonObject+='"sequenceNo":' + Format(ApprovalEntry."Sequence No.") + ',';
                    JsonObject+='"description":"' + ApprovalEntry.Description + '"';
                    JsonObject+='}';
                    JsonArray+=JsonObject;
                    FirstRecord:=false;
                end;
            until ApprovalEntry.Next() = 0;
        end;
        JsonArray+=']';
        Result:=JsonArray;
    end;
    /// <summary>
 
/// Get Full Timesheet Details for Approval (with lines) 
 
/// </summary>
[ServiceEnabled]
    procedure GetTimesheetForApproval(TimesheetNo: Code[20];
    ApproverUserID: Code[50])Result: Text var Header: Record "Monthly Timesheet Header";
    Line: Record "Monthly Timesheet Line";
    Employee: Record Employee;
    ApprovalEntry: Record "Timesheet Approval Entry";
    JsonResult: Text;
    JsonLines: Text;
    JsonLine: Text;
    FirstLine: Boolean;
    begin
        // Verify the timesheet exists
        if not Header.Get(TimesheetNo)then exit('{"error": "Timesheet not found"}');
        // Verify this approver has permission to view/approve
        ApprovalEntry.SetRange("Timesheet No.", TimesheetNo);
        ApprovalEntry.SetRange("Approver ID", ApproverUserID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if not ApprovalEntry.FindFirst()then exit('{"error": "You are not authorized to approve this timesheet"}');
        // Build header JSON
        JsonResult:='{';
        JsonResult+='"timesheetNo":"' + Format(Header."No.") + '",';
        JsonResult+='"employeeNo":"' + Format(Header."Employee No.") + '",';
        if Employee.Get(Header."Employee No.")then begin
            JsonResult+='"employeeName":"' + Employee."First Name" + ' ' + Employee."Last Name" + '",';
            JsonResult+='"employeeEmail":"' + Employee."Company E-Mail" + '",';
        end
        else
        begin
            JsonResult+='"employeeName":"",';
            JsonResult+='"employeeEmail":"",';
        end;
        JsonResult+='"month":"' + Format(Header.Month) + '",';
        JsonResult+='"year":' + Format(Header.Year) + ',';
        JsonResult+='"totalHours":' + Format(Header."Total Hours") + ',';
        JsonResult+='"status":"' + Format(Header.Status) + '",';
        JsonResult+='"approverID":"' + Format(Header."Approver ID") + '",';
        JsonResult+='"submittedDate":"' + Format(ApprovalEntry."Date-Time Sent", 0, 9) + '",';
        // Build lines array
        JsonLines:='[';
        FirstLine:=true;
        Line.SetRange("Document No.", TimesheetNo);
        if Line.FindSet()then begin
            repeat if not FirstLine then JsonLines+=',';
                JsonLine:='{';
                JsonLine+='"lineNo":' + Format(Line."Line No.") + ',';
                JsonLine+='"workDate":"' + Format(Line."Work Date", 0, 9) + '",';
                JsonLine+='"morningHours":' + Format(Line."Morning Hours") + ',';
                JsonLine+='"afternoonHours":' + Format(Line."Afternoon Hours") + ',';
                JsonLine+='"activity":"' + Format(Line.Activity) + '",';
                JsonLine+='"notes":"' + Format(Line.Notes) + '",';
                JsonLine+='"dailyTotal":' + Format(Line."Daily Total") + ',';
                JsonLine+='"hours":' + Format(Line.Hours);
                JsonLine+='}';
                JsonLines+=JsonLine;
                FirstLine:=false;
            until Line.Next() = 0;
        end;
        JsonLines+=']';
        JsonResult+='"lines":' + JsonLines;
        JsonResult+='}';
        Result:=JsonResult;
    end;
    /// <summary>
 
/// Approve Timesheet with Validation 
 
/// </summary>
[ServiceEnabled]
    procedure ApproveTimesheetByApprover(TimesheetNo: Code[20];
    ApproverUserID: Code[50];
    Comments: Text[250])Result: Text var Header: Record "Monthly Timesheet Header";
    ApprovalEntry: Record "Timesheet Approval Entry";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        // Verify timesheet exists
        if not Header.Get(TimesheetNo)then exit('{"status":"error","message":"Timesheet not found"}');
        // Verify approver has permission
        ApprovalEntry.SetRange("Timesheet No.", TimesheetNo);
        ApprovalEntry.SetRange("Approver ID", ApproverUserID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if not ApprovalEntry.FindFirst()then exit('{"status":"error","message":"You are not authorized to approve this timesheet or it is not pending"}');
        // Perform approval
        TSApprovals.ApproveTimesheet(Header, ApproverUserID);
        Result:='{"status":"success","message":"Timesheet ' + TimesheetNo + ' approved by ' + ApproverUserID + '","timesheetNo":"' + TimesheetNo + '"}';
    end;
    /// <summary>
 
/// Reject Timesheet with Validation 
 
/// </summary>
[ServiceEnabled]
    procedure RejectTimesheetByApprover(TimesheetNo: Code[20];
    ApproverUserID: Code[50];
    Reason: Text[250])Result: Text var Header: Record "Monthly Timesheet Header";
    ApprovalEntry: Record "Timesheet Approval Entry";
    TSApprovals: Codeunit "Approvals Timesheet Mgmt.";
    begin
        // Verify timesheet exists
        if not Header.Get(TimesheetNo)then exit('{"status":"error","message":"Timesheet not found"}');
        // Verify approver has permission
        ApprovalEntry.SetRange("Timesheet No.", TimesheetNo);
        ApprovalEntry.SetRange("Approver ID", ApproverUserID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if not ApprovalEntry.FindFirst()then exit('{"status":"error","message":"You are not authorized to reject this timesheet or it is not pending"}');
        // Validate reason is provided
        if Reason = '' then exit('{"status":"error","message":"Rejection reason is required"}');
        // Perform rejection
        TSApprovals.RejectTimesheet(Header, ApproverUserID, Reason);
        Result:='{"status":"success","message":"Timesheet ' + TimesheetNo + ' rejected by ' + ApproverUserID + '","timesheetNo":"' + TimesheetNo + '","reason":"' + Reason + '"}';
    end;
    /// <summary>
 
/// Get Approval History for a Timesheet 
 
/// </summary>
[ServiceEnabled]
    procedure GetApprovalHistory(TimesheetNo: Code[20])Result: Text var ApprovalEntry: Record "Timesheet Approval Entry";
    JsonArray: Text;
    JsonObject: Text;
    FirstRecord: Boolean;
    begin
        JsonArray:='[';
        FirstRecord:=true;
        ApprovalEntry.SetRange("Timesheet No.", TimesheetNo);
        if ApprovalEntry.FindSet()then begin
            repeat if not FirstRecord then JsonArray+=',';
                JsonObject:='{';
                JsonObject+='"sequenceNo":' + Format(ApprovalEntry."Sequence No.") + ',';
                JsonObject+='"approverID":"' + Format(ApprovalEntry."Approver ID") + '",';
                JsonObject+='"status":"' + Format(ApprovalEntry.Status) + '",';
                JsonObject+='"dateSent":"' + Format(ApprovalEntry."Date-Time Sent", 0, 9) + '",';
                JsonObject+='"lastModified":"' + Format(ApprovalEntry."Last Modified", 0, 9) + '",';
                JsonObject+='"approvedBy":"' + Format(ApprovalEntry."Approved By") + '",';
                JsonObject+='"rejectedBy":"' + Format(ApprovalEntry."Rejected By") + '",';
                JsonObject+='"description":"' + ApprovalEntry.Description + '"';
                JsonObject+='}';
                JsonArray+=JsonObject;
                FirstRecord:=false;
            until ApprovalEntry.Next() = 0;
        end;
        JsonArray+=']';
        Result:=JsonArray;
    end;
}
