report 51110 "Timesheet"
{
    Caption = 'Timesheet Report';
    DefaultLayout = RDLC;
    RDLCLayout = './Reports/Timesheet.rdlc';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    WordMergeDataItem = Header;

    dataset
    {
        dataitem(Header;"Monthly Timesheet Header")
        {
            RequestFilterFields = "No.", "Employee No.", Month, Year;

            column(No_;"No.")
            {
            }
            column(EmployeeNo_;"Employee No.")
            {
            }
            column(Month_;Month)
            {
            }
            column(Year_;Year)
            {
            }
            column(MonthYearCaption;MonthYearCaption)
            {
            }
            column(EmployeeName;EmployeeName)
            {
            }
            column(SubmittedByName;EmployeeName)
            {
            }
            column(ApprovedByName;ApprovedByName)
            {
            }
            column(ApprovedDate;ApprovedDate)
            {
            }
            column(CompanyName;CompanyDisplayName)
            {
            }
            column(GeneratedOnCaption;GeneratedOnCaption)
            {
            }
            column(CompanyLogo;CompanyLogo)
            {
            }
            column(TotalHours_;"Total Hours")
            {
            }
            // Morning hours per day (1..31)
            column(M01;MorningDisplay[1])
            {
            }
            column(M02;MorningDisplay[2])
            {
            }
            column(M03;MorningDisplay[3])
            {
            }
            column(M04;MorningDisplay[4])
            {
            }
            column(M05;MorningDisplay[5])
            {
            }
            column(M06;MorningDisplay[6])
            {
            }
            column(M07;MorningDisplay[7])
            {
            }
            column(M08;MorningDisplay[8])
            {
            }
            column(M09;MorningDisplay[9])
            {
            }
            column(M10;MorningDisplay[10])
            {
            }
            column(M11;MorningDisplay[11])
            {
            }
            column(M12;MorningDisplay[12])
            {
            }
            column(M13;MorningDisplay[13])
            {
            }
            column(M14;MorningDisplay[14])
            {
            }
            column(M15;MorningDisplay[15])
            {
            }
            column(M16;MorningDisplay[16])
            {
            }
            column(M17;MorningDisplay[17])
            {
            }
            column(M18;MorningDisplay[18])
            {
            }
            column(M19;MorningDisplay[19])
            {
            }
            column(M20;MorningDisplay[20])
            {
            }
            column(M21;MorningDisplay[21])
            {
            }
            column(M22;MorningDisplay[22])
            {
            }
            column(M23;MorningDisplay[23])
            {
            }
            column(M24;MorningDisplay[24])
            {
            }
            column(M25;MorningDisplay[25])
            {
            }
            column(M26;MorningDisplay[26])
            {
            }
            column(M27;MorningDisplay[27])
            {
            }
            column(M28;MorningDisplay[28])
            {
            }
            column(M29;MorningDisplay[29])
            {
            }
            column(M30;MorningDisplay[30])
            {
            }
            column(M31;MorningDisplay[31])
            {
            }
            // Noon / Afternoon hours per day (1..31)
            column(N01;NoonDisplay[1])
            {
            }
            column(N02;NoonDisplay[2])
            {
            }
            column(N03;NoonDisplay[3])
            {
            }
            column(N04;NoonDisplay[4])
            {
            }
            column(N05;NoonDisplay[5])
            {
            }
            column(N06;NoonDisplay[6])
            {
            }
            column(N07;NoonDisplay[7])
            {
            }
            column(N08;NoonDisplay[8])
            {
            }
            column(N09;NoonDisplay[9])
            {
            }
            column(N10;NoonDisplay[10])
            {
            }
            column(N11;NoonDisplay[11])
            {
            }
            column(N12;NoonDisplay[12])
            {
            }
            column(N13;NoonDisplay[13])
            {
            }
            column(N14;NoonDisplay[14])
            {
            }
            column(N15;NoonDisplay[15])
            {
            }
            column(N16;NoonDisplay[16])
            {
            }
            column(N17;NoonDisplay[17])
            {
            }
            column(N18;NoonDisplay[18])
            {
            }
            column(N19;NoonDisplay[19])
            {
            }
            column(N20;NoonDisplay[20])
            {
            }
            column(N21;NoonDisplay[21])
            {
            }
            column(N22;NoonDisplay[22])
            {
            }
            column(N23;NoonDisplay[23])
            {
            }
            column(N24;NoonDisplay[24])
            {
            }
            column(N25;NoonDisplay[25])
            {
            }
            column(N26;NoonDisplay[26])
            {
            }
            column(N27;NoonDisplay[27])
            {
            }
            column(N28;NoonDisplay[28])
            {
            }
            column(N29;NoonDisplay[29])
            {
            }
            column(N30;NoonDisplay[30])
            {
            }
            column(N31;NoonDisplay[31])
            {
            }
            // Cell background color per day (1..31) — Morning
            column(M01Color;MorningColor[1])
            {
            }
            column(M02Color;MorningColor[2])
            {
            }
            column(M03Color;MorningColor[3])
            {
            }
            column(M04Color;MorningColor[4])
            {
            }
            column(M05Color;MorningColor[5])
            {
            }
            column(M06Color;MorningColor[6])
            {
            }
            column(M07Color;MorningColor[7])
            {
            }
            column(M08Color;MorningColor[8])
            {
            }
            column(M09Color;MorningColor[9])
            {
            }
            column(M10Color;MorningColor[10])
            {
            }
            column(M11Color;MorningColor[11])
            {
            }
            column(M12Color;MorningColor[12])
            {
            }
            column(M13Color;MorningColor[13])
            {
            }
            column(M14Color;MorningColor[14])
            {
            }
            column(M15Color;MorningColor[15])
            {
            }
            column(M16Color;MorningColor[16])
            {
            }
            column(M17Color;MorningColor[17])
            {
            }
            column(M18Color;MorningColor[18])
            {
            }
            column(M19Color;MorningColor[19])
            {
            }
            column(M20Color;MorningColor[20])
            {
            }
            column(M21Color;MorningColor[21])
            {
            }
            column(M22Color;MorningColor[22])
            {
            }
            column(M23Color;MorningColor[23])
            {
            }
            column(M24Color;MorningColor[24])
            {
            }
            column(M25Color;MorningColor[25])
            {
            }
            column(M26Color;MorningColor[26])
            {
            }
            column(M27Color;MorningColor[27])
            {
            }
            column(M28Color;MorningColor[28])
            {
            }
            column(M29Color;MorningColor[29])
            {
            }
            column(M30Color;MorningColor[30])
            {
            }
            column(M31Color;MorningColor[31])
            {
            }
            // Cell background color per day (1..31) — Noon/Afternoon
            column(N01Color;NoonColor[1])
            {
            }
            column(N02Color;NoonColor[2])
            {
            }
            column(N03Color;NoonColor[3])
            {
            }
            column(N04Color;NoonColor[4])
            {
            }
            column(N05Color;NoonColor[5])
            {
            }
            column(N06Color;NoonColor[6])
            {
            }
            column(N07Color;NoonColor[7])
            {
            }
            column(N08Color;NoonColor[8])
            {
            }
            column(N09Color;NoonColor[9])
            {
            }
            column(N10Color;NoonColor[10])
            {
            }
            column(N11Color;NoonColor[11])
            {
            }
            column(N12Color;NoonColor[12])
            {
            }
            column(N13Color;NoonColor[13])
            {
            }
            column(N14Color;NoonColor[14])
            {
            }
            column(N15Color;NoonColor[15])
            {
            }
            column(N16Color;NoonColor[16])
            {
            }
            column(N17Color;NoonColor[17])
            {
            }
            column(N18Color;NoonColor[18])
            {
            }
            column(N19Color;NoonColor[19])
            {
            }
            column(N20Color;NoonColor[20])
            {
            }
            column(N21Color;NoonColor[21])
            {
            }
            column(N22Color;NoonColor[22])
            {
            }
            column(N23Color;NoonColor[23])
            {
            }
            column(N24Color;NoonColor[24])
            {
            }
            column(N25Color;NoonColor[25])
            {
            }
            column(N26Color;NoonColor[26])
            {
            }
            column(N27Color;NoonColor[27])
            {
            }
            column(N28Color;NoonColor[28])
            {
            }
            column(N29Color;NoonColor[29])
            {
            }
            column(N30Color;NoonColor[30])
            {
            }
            column(N31Color;NoonColor[31])
            {
            }
            // Daily total per day (1..31)
            column(T01;DayTotal[1])
            {
            }
            column(T02;DayTotal[2])
            {
            }
            column(T03;DayTotal[3])
            {
            }
            column(T04;DayTotal[4])
            {
            }
            column(T05;DayTotal[5])
            {
            }
            column(T06;DayTotal[6])
            {
            }
            column(T07;DayTotal[7])
            {
            }
            column(T08;DayTotal[8])
            {
            }
            column(T09;DayTotal[9])
            {
            }
            column(T10;DayTotal[10])
            {
            }
            column(T11;DayTotal[11])
            {
            }
            column(T12;DayTotal[12])
            {
            }
            column(T13;DayTotal[13])
            {
            }
            column(T14;DayTotal[14])
            {
            }
            column(T15;DayTotal[15])
            {
            }
            column(T16;DayTotal[16])
            {
            }
            column(T17;DayTotal[17])
            {
            }
            column(T18;DayTotal[18])
            {
            }
            column(T19;DayTotal[19])
            {
            }
            column(T20;DayTotal[20])
            {
            }
            column(T21;DayTotal[21])
            {
            }
            column(T22;DayTotal[22])
            {
            }
            column(T23;DayTotal[23])
            {
            }
            column(T24;DayTotal[24])
            {
            }
            column(T25;DayTotal[25])
            {
            }
            column(T26;DayTotal[26])
            {
            }
            column(T27;DayTotal[27])
            {
            }
            column(T28;DayTotal[28])
            {
            }
            column(T29;DayTotal[29])
            {
            }
            column(T30;DayTotal[30])
            {
            }
            column(T31;DayTotal[31])
            {
            }
            // Row totals (sum across all days)
            column(MorningTotal;RowMorningTotal)
            {
            }
            column(NoonTotal;RowNoonTotal)
            {
            }
            column(GrandTotal;RowGrandTotal)
            {
            }
            trigger OnAfterGetRecord()var TSLine: Record "Monthly Timesheet Line";
            ApprEntry: Record "Timesheet Approval Entry";
            SenderEmployeeNo: Code[20];
            DayIdx: Integer;
            begin
                Clear(MorningHours);
                Clear(NoonHours);
                Clear(DayTotal);
                RowMorningTotal:=0;
                RowNoonTotal:=0;
                RowGrandTotal:=0;
                // ── Flatten lines into day buckets ──────────────────
                TSLine.SetRange("Document No.", "No.");
                if TSLine.FindSet()then repeat DayIdx:=Date2DMY(TSLine."Work Date", 1); // day of month
                        if(DayIdx >= 1) and (DayIdx <= 31)then begin
                            MorningHours[DayIdx]+=TSLine."Morning Hours";
                            NoonHours[DayIdx]+=TSLine."Afternoon Hours";
                            DayTotal[DayIdx]:=MorningHours[DayIdx] + NoonHours[DayIdx];
                        end;
                    until TSLine.Next() = 0;
                for DayIdx:=1 to 31 do begin
                    RowMorningTotal+=MorningHours[DayIdx];
                    RowNoonTotal+=NoonHours[DayIdx];
                    MorningDisplay[DayIdx]:=Format(MorningHours[DayIdx]);
                    NoonDisplay[DayIdx]:=Format(NoonHours[DayIdx]);
                    MorningColor[DayIdx]:='White';
                    NoonColor[DayIdx]:='White';
                end;
                RowGrandTotal:=RowMorningTotal + RowNoonTotal;
                ApplyLeaveAndHolidayLabels("Employee No.", Month, Year);
                // ── Resolve sender & completion status from chain ──
                //   Sender: Employee No. carried on the approval entry.
                //   Fully approved only if the highest-sequence entry's
                //   Status = Approved (i.e. both steps done).
                SenderEmployeeNo:='';
                ApproverIsApproved:=false;
                ApprEntry.Reset();
                ApprEntry.SetRange("Timesheet No.", "No.");
                ApprEntry.SetCurrentKey("Sequence No.");
                if ApprEntry.FindLast()then begin // last = highest Sequence No.
                    SenderEmployeeNo:=ApprEntry."Employee No.";
                    ApproverIsApproved:=ApprEntry.Status = ApprEntry.Status::Approved;
                end;
                // Fall back to header employee if no approval entry yet.
                if SenderEmployeeNo = '' then SenderEmployeeNo:="Employee No.";
                // ── Submitter name: Employee No. → First+Middle+Last ─
                EmployeeName:=GetEmployeeFullName(SenderEmployeeNo);
                if EmployeeName = '' then EmployeeName:=SenderEmployeeNo;
                // ── Approver name: only once fully approved (both steps
                //    done). Always the timesheet owner's supervisor — the
                //    meaningful sign-off — regardless of which entry
                //    technically finalized the chain (the static ERP step).
                if ApproverIsApproved then begin
                    ApprovedByName:=GetSupervisorFullName(SenderEmployeeNo);
                    ApprovedDate:=Format(DT2Date(ApprEntry."Last Modified"), 0, '<Day,2> <Month Text> <Year4>');
                end
                else begin
                    ApprovedByName:=''; // not yet fully approved → blank
                    ApprovedDate:='';
                end;
                // ── Caption like "May 2026" ─────────────────────────
                MonthYearCaption:=Format(Month) + ' ' + Format(Year);
                // Company name for the header (logo + name cached in OnPreReport).
                CompanyDisplayName:=CachedCompanyName;
            end;
        }
    }
    trigger OnPreReport()begin
        LoadCompanyInfo();
        GeneratedOnCaption:=Format(Today(), 0, '<Day,2> <Month Text> <Year4>');
    end;
    var MorningHours: array[31]of Decimal;
    NoonHours: array[31]of Decimal;
    DayTotal: array[31]of Decimal;
    // Display versions of Morning/Noon hours per day — same value as the
    // Decimal arrays above, formatted as text, EXCEPT on a day that's a
    // company holiday or approved leave and would otherwise show a plain
    // 0: those show "H" (holiday) or "L" (leave) instead, so the reader
    // can tell "day off" apart from "day worked but nothing logged".
    // Real hours actually entered are never overridden, even on a
    // holiday/leave day.
    MorningDisplay: array[31]of Text[10];
    NoonDisplay: array[31]of Text[10];
    // Cell background per day/half — "White" normally, "LightGreen" on
    // approved leave, "Yellow" on a company holiday. Weekends are neither
    // (see ApplyLeaveAndHolidayLabels), so they stay White.
    MorningColor: array[31]of Text[20];
    NoonColor: array[31]of Text[20];
    RowMorningTotal: Decimal;
    RowNoonTotal: Decimal;
    RowGrandTotal: Decimal;
    EmployeeName: Text[250];
    ApprovedByName: Text[250];
    ApprovedDate: Text[50];
    MonthYearCaption: Text[100];
    CompanyLogo: Text;
    CompanyDisplayName: Text[250];
    CachedCompanyName: Text[250];
    GeneratedOnCaption: Text[100];
    ApproverIsApproved: Boolean;
    // ────────────────────────────────────────────────────────────
    //  Load company name + logo once (logo as Base64 for RDLC).
    //  The logo comes from the Company Information "Picture" field.
    // ────────────────────────────────────────────────────────────
    local procedure LoadCompanyInfo()var CompanyInfo: Record "Company Information";
    InStr: InStream;
    Base64Conv: Codeunit "Base64 Convert";
    begin
        Clear(CompanyLogo);
        CachedCompanyName:=CompanyName();
        if not CompanyInfo.Get()then exit;
        if CompanyInfo.Name <> '' then CachedCompanyName:=CompanyInfo.Name;
        // "Picture" here is a BLOB field, so load it with CalcFields and
        // read it through an InStream created directly off the field.
        CompanyInfo.CalcFields(Picture);
        if not CompanyInfo.Picture.HasValue()then exit;
        CompanyInfo.Picture.CreateInStream(InStr);
        CompanyLogo:=Base64Conv.ToBase64(InStr);
    end;
    // ────────────────────────────────────────────────────────────
    //  Sender:  Employee No.  →  First + Middle + Last name
    // ────────────────────────────────────────────────────────────
    local procedure GetEmployeeFullName(EmployeeNo: Code[20]): Text[250]var Emp: Record Employee;
    begin
        if EmployeeNo = '' then exit('');
        if not Emp.Get(EmployeeNo)then exit('');
        exit(MergeNames(Emp."First Name", Emp."Middle Name", Emp."Last Name"));
    end;
    // ────────────────────────────────────────────────────────────
    //  Approved By: always the timesheet owner's own supervisor —
    //  Employee."Supervisor No." → First+Middle+Last — regardless of which
    //  entry technically finalized the 2-step chain.
    // ────────────────────────────────────────────────────────────
    local procedure GetSupervisorFullName(EmployeeNo: Code[20]): Text[250]var Emp: Record Employee;
    Supervisor: Record Employee;
    begin
        if EmployeeNo = '' then exit('');
        if not Emp.Get(EmployeeNo)then exit('');
        if Emp."Supervisor No." = '' then exit('');
        if not Supervisor.Get(Emp."Supervisor No.")then exit('');
        exit(MergeNames(Supervisor."First Name", Supervisor."Middle Name", Supervisor."Last Name"));
    end;
    // ────────────────────────────────────────────────────────────
    //  Overrides MorningDisplay/NoonDisplay from a plain "0" to "H"
    //  (company holiday) or "L" (approved leave) for a day that would
    //  otherwise show 0 — never touches a day with real hours actually
    //  entered. Reuses "Attendance Day Type" and "Leave Half Day
    //  Calculator", the same holiday/leave lookups the attendance review
    //  email and preview already use, so this can't disagree with those.
    //  A half-day COMPANY HOLIDAY only covers the afternoon, matching the
    //  "office open in the morning" convention used elsewhere in this
    //  extension. A half-day LEAVE can be taken in either half (an
    //  employee's own choice, not a fixed company setting), so which half
    //  is inferred from the timesheet itself instead — see below.
    // ────────────────────────────────────────────────────────────
    local procedure ApplyLeaveAndHolidayLabels(EmployeeNo: Code[20];
    HeaderMonth: Option;
    HeaderYear: Integer)var DayTypeCU: Codeunit "Attendance Day Type";
    LeaveCalc: Codeunit "Leave Half Day Calculator";
    MonthNo: Integer;
    LastDay: Integer;
    MonthStart: Date;
    ThisDate: Date;
    DayIdx: Integer;
    DayType: Text[30];
    IsHalfDayLeave: Boolean;
    begin
        MonthNo:=HeaderMonth; // ordinal 1=January..12=December (0 = blank), matches OptionMembers order exactly
        if(MonthNo < 1) or(MonthNo > 12) or(HeaderYear = 0)then exit;
        MonthStart:=DMY2Date(1, MonthNo, HeaderYear);
        LastDay:=Date2DMY(CalcDate('<CM>', MonthStart), 1);
        for DayIdx:=1 to LastDay do begin
            ThisDate:=DMY2Date(DayIdx, MonthNo, HeaderYear);
            DayType:=DayTypeCU.GetDayType(ThisDate);
            // A plain weekend (Saturday/Sunday) is a non-working day, not a
            // holiday — leave it showing its real value/0, not "H"/Yellow.
            if(DayType <> '') and(DayType <> 'Saturday') and(DayType <> 'Sunday')then begin
                if DayTypeCU.IsHalfWorkingDay(ThisDate)then begin
                    if NoonHours[DayIdx] = 0 then begin
                        NoonDisplay[DayIdx]:='H';
                        NoonColor[DayIdx]:='Yellow';
                    end;
                end else begin
                    if MorningHours[DayIdx] = 0 then begin
                        MorningDisplay[DayIdx]:='H';
                        MorningColor[DayIdx]:='Yellow';
                    end;
                    if NoonHours[DayIdx] = 0 then begin
                        NoonDisplay[DayIdx]:='H';
                        NoonColor[DayIdx]:='Yellow';
                    end;
                end;
            end else
                if LeaveCalc.GetLeaveStatus(EmployeeNo, ThisDate, IsHalfDayLeave) <> '' then begin
                    if IsHalfDayLeave then begin
                        // Which half was actually leave isn't stored anywhere
                        // (Leave Application/Leave Application Day only ever
                        // record a plain "is this half day" flag, no AM/PM) —
                        // half-day leave can be taken in either half. Infer it
                        // from the timesheet itself instead: whichever half
                        // has no real hours logged is presumably the leave
                        // half, since the employee would have worked the
                        // other one. If neither half has hours, there's
                        // nothing to infer from, so flag both.
                        if(MorningHours[DayIdx] = 0) and (NoonHours[DayIdx] <> 0)then begin
                            MorningDisplay[DayIdx]:='L';
                            MorningColor[DayIdx]:='LightGreen';
                        end else
                            if(NoonHours[DayIdx] = 0) and (MorningHours[DayIdx] <> 0)then begin
                                NoonDisplay[DayIdx]:='L';
                                NoonColor[DayIdx]:='LightGreen';
                            end else
                                if(MorningHours[DayIdx] = 0) and (NoonHours[DayIdx] = 0)then begin
                                    MorningDisplay[DayIdx]:='L';
                                    MorningColor[DayIdx]:='LightGreen';
                                    NoonDisplay[DayIdx]:='L';
                                    NoonColor[DayIdx]:='LightGreen';
                                end;
                    end else begin
                        if MorningHours[DayIdx] = 0 then begin
                            MorningDisplay[DayIdx]:='L';
                            MorningColor[DayIdx]:='LightGreen';
                        end;
                        if NoonHours[DayIdx] = 0 then begin
                            NoonDisplay[DayIdx]:='L';
                            NoonColor[DayIdx]:='LightGreen';
                        end;
                    end;
                end;
        end;
    end;
    // ── Merge first / middle / last, collapsing empty parts ──────
    local procedure MergeNames(FirstName: Text;
    MiddleName: Text;
    LastName: Text): Text[250]var FullName: Text;
    begin
        FullName:=FirstName;
        if MiddleName <> '' then FullName:=FullName + ' ' + MiddleName;
        if LastName <> '' then FullName:=FullName + ' ' + LastName;
        exit(CopyStr(DelChr(FullName, '<>', ' '), 1, 250));
    end;
}
