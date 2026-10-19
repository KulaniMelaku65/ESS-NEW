query 51100 GetEmployees
{
    APIGroup = 'KifiyaGroup';
    APIPublisher = 'Kifiya';
    APIVersion = 'v1.0';
    EntityName = 'getEmployee';
    EntitySetName = 'getEmployees';
    QueryType = API;

    elements
    {
        dataitem(employee;
        Employee)
        {
            //DataItemTableFilter = "Employee Status" = const(Active);
            column(no;
            "No.")
            {
                Caption = 'No';
            }
            column(fullName;
            "Full Name")
            {
                Caption = 'FullName';
            }
            column(employeeStatus;
            "Employee Status")
            {
                Caption = 'EmployeeStatus';
            }
            column(status;
            Status)
            {
                Caption = 'Status';
            }
            column(gender;
            "Gender")
            {
                Caption = 'Gender';
            }
            column(leaveBalance;
            "Leave Balance")
            {
                Caption = 'LeaveBalance';
            }

            column(virtualCompany; "Global Dimension 1 Code") { }
            column(department; "Global Dimension 2 Code") { }
            column(employeeType;
            "Employee Type")
            {
                Caption = 'EmployeeType';
            }
            column(Curr_Address_Country; "Curr Address Country") { }
            column(Region; "Region") { }
            column(Subcity; "Sub-county") { }
            column(Birth_Date; "Birth Date")
            {
                Caption = 'BirthDate';
            }
            column(Phone_No_; "Phone No.")
            {
                Caption = 'PhoneNo';
            }
            column(employmentDate;
            "Employment Date")
            {
                Caption = 'EmploymentDate';
            }
            column(supervisorCode;
            "Supervisor No.")
            {
                Caption = 'SupervisorNo';
            }
            column(supervisorName;
            "Supervisor Name")
            {
                Caption = 'SupervisorName';
            }
            column(contractStartDate;
            "Contract Start Date")
            {
                Caption = 'ContractStartDate';
            }
            column(contractEndDate;
            "Contract End Date")
            {
                Caption = 'ContractEndDate';
            }
            dataitem(emergencyContact;
            "Employee Emergency Contact")
            {
                DataItemLink = "Employee No." = employee."No.";
                SqlJoinType = LeftOuterJoin;
                column(emergencyContactFirstName;
                "First Name")
                {
                    Caption = 'EmergencyContactFirstName';
                }
                column(emergencyContactMiddleName;
                "Middle Name")
                {
                    Caption = 'EmergencyContactMiddleName';
                }
                column(emergencyContactLastName;
                "Last Name")
                {
                    Caption = 'EmergencyContactLastName';
                }
                column(emergencyContactPhoneNo;
                "Phone No.")
                {
                    Caption = 'EmergencyContactPhoneNo';
                }
                column(emergencyContactEmail;
                "E-Mail")
                {
                    Caption = 'EmergencyContactEmail';
                }
                column(emergencyContactLocation;
                "Location")
                {
                    Caption = 'EmergencyContactLocation';
                }
                dataitem(relative;
                Relative)
                {
                    DataItemLink = "Code" = emergencyContact."Relative Code";
                    SqlJoinType = LeftOuterJoin;
                    column(emergencyContactAssociation;
                    Description)
                    {
                        Caption = 'EmergencyContactAssociation';
                    }

                    // "Employment History" — chained here (not a sibling of
                    // emergencyContact) because a query dataitem can only have ONE
                    // nested child; AL doesn't support sibling dataitems ("unions are
                    // not supported"). NOTE: since this and "Employee Relative" below
                    // are both genuinely one-to-many from the employee and unrelated
                    // to each other or to the emergency contact, chaining them
                    // produces a cartesian product — an employee with e.g. 3 movements
                    // and 2 beneficiaries gets 3x2=6 rows, each an arbitrary pairing.
                    // Accepted trade-off per instruction, in exchange for everything
                    // living in this one query instead of separate endpoints.
                    dataitem(employeeMovement;
                    "Employee Movement")
                    {
                        DataItemLink = "Employee No." = employee."No.";
                        SqlJoinType = LeftOuterJoin;
                        column(movementPreviousJobTitle;
                        "Previous Job Title")
                        {
                            Caption = 'PreviousJobTitle';
                        }
                        column(movementPreviousJobTitleDescription;
                        "Previous Job Description")
                        {
                            Caption = 'PreviousJobTitleDescription';
                        }
                        column(movementCurrentJobTitle;
                        "Job Title")
                        {
                            Caption = 'CurrentJobTitle';
                        }
                        column(movementCurrentJobTitleDescription;
                        "Job Description")
                        {
                            Caption = 'CurrentJobTitleDescription';
                        }
                        column(movementPreviousDepartment;
                        "Previous Dimension 2 Code")
                        {
                            Caption = 'PreviousDepartment';
                        }
                        column(movementCurrentDepartment;
                        "Global Dimension 2 Code")
                        {
                            Caption = 'CurrentDepartment';
                        }
                        column(changeEffectiveDate;
                        "Payroll Period")
                        {
                            // Renamed on the way out — the underlying table (base app
                            // "Fanisi_HR", not ours) still calls this "Payroll Period".
                            Caption = 'ChangeEffectiveDate';
                        }

                        // "Beneficiaries" — table "Employee Relative" (standard BC
                        // relative/next-of-kin table, extended by Fanisi_HR with the
                        // beneficiary-specific fields). Chained here for the same
                        // one-nested-child-per-level reason as above.
                        dataitem(employeeRelative;
                        "Employee Relative")
                        {
                            DataItemLink = "Employee No." = employee."No.";
                            SqlJoinType = LeftOuterJoin;
                            column(beneficiaryFirstName;
                            "First Name")
                            {
                                Caption = 'BeneficiaryFirstName';
                            }
                            column(beneficiaryMiddleName;
                            "Middle Name")
                            {
                                Caption = 'BeneficiaryMiddleName';
                            }
                            column(beneficiaryLastName;
                            "Last Name")
                            {
                                Caption = 'BeneficiaryLastName';
                            }
                            column(beneficiaryBirthDate;
                            "Birth Date")
                            {
                                Caption = 'BeneficiaryBirthDate';
                            }
                            column(beneficiaryPhoneNo;
                            "Phone No.")
                            {
                                Caption = 'BeneficiaryPhoneNo';
                            }
                            column(beneficiaryIdNo;
                            "ID No.")
                            {
                                Caption = 'BeneficiaryIdNo';
                            }
                            column(beneficiaryEmail;
                            "E-Mail")
                            {
                                Caption = 'BeneficiaryEmail';
                            }
                            column(beneficiaryPostalAddress;
                            "Postal Address")
                            {
                                Caption = 'BeneficiaryPostalAddress';
                            }
                            column(beneficiaryRelativeType;
                            "Relative Type")
                            {
                                Caption = 'BeneficiaryRelativeType';
                            }
                            column(beneficiaryPercentage;
                            "Beneficiary Percentage")
                            {
                                Caption = 'BeneficiaryPercentage';
                            }
                            column(beneficiaryComment;
                            Comment)
                            {
                                Caption = 'BeneficiaryComment';
                            }
                            dataitem(beneficiaryRelativeLookup;
                            Relative)
                            {
                                DataItemLink = "Code" = employeeRelative."Relative Code";
                                SqlJoinType = LeftOuterJoin;
                                column(beneficiaryAssociation;
                                Description)
                                {
                                    Caption = 'BeneficiaryAssociation';
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
