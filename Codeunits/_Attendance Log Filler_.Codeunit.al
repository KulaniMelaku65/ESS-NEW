codeunit 51143 "Attendance Log Filler"
{
    // Quiet alternative to codeunit 51126 "Attendance Leave Processor" —
    // same processing over the last 7 days (fills in Processing Result: Attended, Holiday,
    // Weekend, Absence Flagged, etc.), but never sends the
    // per-gap supervisor "Attendance Alert" email. Point a Job Queue Entry
    // at THIS codeunit instead of 51126 if all you want is the Employee
    // Attendance Log kept up to date, without the daily supervisor emails
    // (the weekly Attendance Review Mailer, codeunit 51140, still covers
    // notifying people).
    //
    // SETUP: Create a Job Queue Entry pointing at this codeunit (51143),
    // recurring daily — do NOT also schedule codeunit 51126, since both
    // would process the same day (harmless, just redundant) and 51126
    // would additionally send the supervisor alert email you're trying to
    // avoid here.

    trigger OnRun()
    var
        Processor: Codeunit "Attendance Leave Processor";
    begin
        Processor.ProcessRecentAttendance(false);
    end;
}
