permissionset 51100 "ESS Integration"
{
    Assignable = true;
    Caption = 'ESS Integration';
    Permissions = tabledata "Employee Location" = R,
        tabledata "ESS Work Experience" = RIMD,
        tabledata "Leave Application Day" = RIMD,
        tabledata "Employee Attendance Log" = RIMD;
    

}
