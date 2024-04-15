/**
 * Created 6/24/2022 ST
 * 
 * To test the NonLevProjectRollupBatch class
 */
@isTest
public with sharing class LevNonLevProjectRollupBatch_Test {

    @testSetup
    static void setupData() {

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';

        Account testAcct = TestDataFactory.createAccount(false, 'Client');

        List<Account> testAccountList = new List<Account>{levementumLLCAcct, testAcct};
        insert testAccountList;

        Opportunity testOppty = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        testOppty.Name = 'Test Oppty';
        testOppty.StageName = 'Closed Won';
        testOppty.Amount = 10000;
        testOppty.Do_Not_Create_Project__c = false;
        insert testOppty;

        Project__c testProj1 = new Project__c();
        testProj1.Account__c = testAcct.Id;
        testProj1.Opportunity__c = testOppty.Id;
        testProj1.Name = 'Test Project 1';
        testProj1.Project_Status__c = 'Active';
        testProj1.Planned_Close_Date__c = Date.today().addDays(14);
        testProj1.RepliconURI__c = 'urn:replicon-tenant:levementum:project:54325432';
        testProj1.Remaining_Forecasted_Hrs__c = 120;

        Project__c testProj2 = new Project__c();
        testProj2.Account__c = testAcct.Id;
        testProj2.Opportunity__c = testOppty.Id;
        testProj2.Name = 'Test Project 2';
        testProj2.Project_Status__c = 'Not Started';
        testProj2.Planned_Close_Date__c = Date.today().addDays(14);
        testProj2.RepliconURI__c = 'urn:replicon-tenant:levementum:project:12341234';
        testProj2.Remaining_Forecasted_Hrs__c = 120;

        List<Project__c> insertProjList = new List<Project__c>{testProj1, testProj2};
        insert insertProjList;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        Contact testATGConsultant = TestDataFactory.createEmployee(false, levementumLLCAcct.Id);
        testATGConsultant.Replicon_User_Number__c = 8888;
        testATGConsultant.FirstName = 'ATG';
        testATGConsultant.LastName = 'Consultant';

        Contact testNonLev = TestDataFactory.createEmployee(false, testAcct.Id);
        testNonLev.Replicon_User_Number__c = 7777;
        testNonLev.FirstName = 'Non Lev';
        testNonLev.LastName = 'Test Contact';

        List<Contact> contactInsertList = new List<Contact>{con, testATGConsultant, testNonLev};
        insert contactInsertList;

        Project__c testProj3 = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c, RepliconURI__c FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        testProj3.RepliconURI__c = 'urn:replicon-tenant:levementum:project:43214321';
        update testProj3;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj3.Id);
        Project_Team_Member_Billing_Rate__c concessionBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Concession', Hourly_Rate__c = 0, Project__c = testProj3.Id);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{devBillRate, concessionBillRate};
        insert billRateInsertList;

        //Create Time Entries for current, previous, and next Quarter
        Date afterATGSwitchDate = Date.today();
        Date beforeATGSwitchDate = Date.newInstance(2022, 5, 1);
        //Lev Employee Entries
        Replicon_Time_Entry__c levEmployeeBillableEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, 
                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc111');
        Replicon_Time_Entry__c levEmployeeNonBillableEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = null, TotalHrs__c = 2, 
                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc222');
        Replicon_Time_Entry__c levEmployeeConcessionEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = concessionBillRate.Id, TotalHrs__c = 2, 
                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc333');
        //ATG Consultant Contact Entries
        Replicon_Time_Entry__c atgConsultantBillableEntry = new Replicon_Time_Entry__c(Employee__c = testATGConsultant.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, 
                                                                                    Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = beforeATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc444');
        Replicon_Time_Entry__c atgConsultantNonBillableEntry = new Replicon_Time_Entry__c(Employee__c = testATGConsultant.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = null, TotalHrs__c = 2, 
                                                                                    Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc555');
        Replicon_Time_Entry__c atgConsultantConcessionEntry = new Replicon_Time_Entry__c(Employee__c = testATGConsultant.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = concessionBillRate.Id, TotalHrs__c = 2, 
                                                                                    Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc666');

        //Non Lev Employee Entries
        Replicon_Time_Entry__c nonLevEmployeeBeforeATGSwitchBillableEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = BeforeATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc777');
        Replicon_Time_Entry__c nonLevEmployeeBeforeATGSwitchNonBillableEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = null, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = BeforeATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc888');
        Replicon_Time_Entry__c nonLevEmployeeBeforeATGSwitchConcessionEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = concessionBillRate.Id, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = BeforeATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc999');
        Replicon_Time_Entry__c nonLevEmployeeAfterATGSwitchBillableEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc000');
        Replicon_Time_Entry__c nonLevEmployeeAfterATGSwitchNonBillableEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = null, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc123');
        Replicon_Time_Entry__c nonLevEmployeeAfterATGSwitchConcessionEntry = new Replicon_Time_Entry__c(Employee__c = testNonLev.Id, Project__c = testProj3.Id, Associated_Billing_Rate__c = concessionBillRate.Id, TotalHrs__c = 2, 
                                                                                                Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:43214321', EntryDate__c = afterATGSwitchDate, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:abc321');

        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{levEmployeeBillableEntry, levEmployeeNonBillableEntry, levEmployeeConcessionEntry, 
                                                                                    atgConsultantBillableEntry, atgConsultantNonBillableEntry, atgConsultantConcessionEntry,
                                                                                    nonLevEmployeeBeforeATGSwitchBillableEntry, nonLevEmployeeBeforeATGSwitchNonBillableEntry, nonLevEmployeeBeforeATGSwitchConcessionEntry,
                                                                                     nonLevEmployeeAfterATGSwitchBillableEntry, nonLevEmployeeAfterATGSwitchNonBillableEntry, nonLevEmployeeAfterATGSwitchConcessionEntry};
        insert entryList;

    }

    @isTest
    static void runProjectRollupBatchForAllProjects(){
        System.debug('*************************************************** runProjectRollupBatchForAllProjects ******************************************');

        //Opportunity_Billable_Hours_Booked__c = Lev Billable Hours Booked (Rollup_Billable__c)
        //Opp_Concession_Non_Billable_Hours_Booked__c = Lev Concession Non-Billable Hours (Rollup_Concession__c)
        //Rollup_Nonbillable__c = Lev Non-Billable Hours (Rollup_Nonbillable__c)
        //OpportunityTotal_Amount_Invoiced_To_Date__c = Lev Revenue Amount Booked (Rollup_Revenue__c)
        //Total_Non_Bill_hours__c = Lev Total Non-Billable Hours (Lev Non Bill + Lev Concession)
        //NonLevBillableHoursBooked__c = Non-Lev Billable Hours Booked 
        //NonLevNonBillHours__c = Non-Lev Non-Billable Hours
        //NonLevRevenueAmountBooked__c = Non-Lev Revenue Amount Booked
        //NonLevTotalNonBillableHours__c = Non-Lev Total Non-Billable Hours (Non-Lev Non Bill + Non Lev Concession)

        Project__c testRollupProjBefore = [SELECT Id, Name, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, OpportunityTotal_Amount_Invoiced_To_Date__c, Total_Non_Bill_hours__c,
                                            NonLevBillableHoursBooked__c, NonLevNonBillHours__c, NonLevRevenueAmountBooked__c, Rollup_Billable__c, Rollup_Revenue__c, Rollup_Concession__c, Rollup_Nonbillable__c
                                        FROM Project__c
                                        WHERE Name = 'Test Oppty' LIMIT 1];

        //Assert that thew Rollups were properly calculated from the Replicon Time Entry Logic before we intentially change the values
        System.assertEquals(4, testRollupProjBefore.Rollup_Billable__c, 'Lev Billable Hours Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Billable Hours Booked correctly calculated
        System.assertEquals(800, testRollupProjBefore.Rollup_Revenue__c, 'Lev Revenue Amount Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Revenue Amount Booked correctly calculated
        System.assertEquals(4, testRollupProjBefore.Rollup_Concession__c, 'Lev Concession Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Concession Non-Billable Hours Booked correctly calculated
        System.assertEquals(4, testRollupProjBefore.Rollup_Nonbillable__c, 'Lev Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Non-Billable Hours correctly calculated
        System.assertEquals(4, testRollupProjBefore.NonLevBillableHoursBooked__c, 'Non-Lev Billable Hours Booked  was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Billable Hours Booked  correctly calculated
        System.assertEquals(4, testRollupProjBefore.NonLevNonBillHours__c, 'Non-Lev Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Non-Billable Hours correctly calculated
        System.assertEquals(800, testRollupProjBefore.NonLevRevenueAmountBooked__c, 'Non-Lev Revenue Amount Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Revenue Amount Booked correctly calculated

        //Update Project to the wrong Rollup Values so the Batch run can correct it
        testRollupProjBefore.Rollup_Billable__c = 0;
        testRollupProjBefore.Rollup_Revenue__c = 0;
        testRollupProjBefore.Rollup_Concession__c = 0;
        testRollupProjBefore.Rollup_Nonbillable__c = 0;
        testRollupProjBefore.NonLevBillableHoursBooked__c = 0;
        testRollupProjBefore.NonLevNonBillHours__c = 0;
        testRollupProjBefore.NonLevRevenueAmountBooked__c = 0;

        update testRollupProjBefore;


        Test.startTest();
        LevNonLevProjectRollupBatch newBatch = new LevNonLevProjectRollupBatch(true, null);
        Database.executeBatch(newBatch, 10);
        Test.stopTest();

        Project__c testRollupProjAfter = [SELECT Id, Name, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, OpportunityTotal_Amount_Invoiced_To_Date__c, Total_Non_Bill_hours__c,
                                            NonLevBillableHoursBooked__c, NonLevNonBillHours__c, NonLevRevenueAmountBooked__c, Rollup_Billable__c, Rollup_Revenue__c, Rollup_Concession__c, Rollup_Nonbillable__c
                                        FROM Project__c
                                        WHERE Name = 'Test Oppty' LIMIT 1];

        //Assert that the Batch Job correctly Re-calculated the Project Rollups
        System.assertEquals(4, testRollupProjAfter.Rollup_Billable__c, 'Lev Billable Hours Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Billable Hours Booked correctly calculated
        System.assertEquals(800, testRollupProjAfter.Rollup_Revenue__c, 'Lev Revenue Amount Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Revenue Amount Booked correctly calculated
        System.assertEquals(4, testRollupProjAfter.Rollup_Concession__c, 'Lev Concession Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Concession Non-Billable Hours Booked correctly calculated
        System.assertEquals(4, testRollupProjAfter.Rollup_Nonbillable__c, 'Lev Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Non-Billable Hours correctly calculated
        System.assertEquals(4, testRollupProjAfter.NonLevBillableHoursBooked__c, 'Non-Lev Billable Hours Booked  was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Billable Hours Booked  correctly calculated
        System.assertEquals(4, testRollupProjAfter.NonLevNonBillHours__c, 'Non-Lev Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Non-Billable Hours correctly calculated
        System.assertEquals(800, testRollupProjAfter.NonLevRevenueAmountBooked__c, 'Non-Lev Revenue Amount Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Revenue Amount Booked correctly calculated
    }

    @isTest
    static void runProjectRollupBatchForSpecificProjectList(){
        System.debug('*************************************************** runProjectRollupBatchForSpecificProjectList ******************************************');

        Project__c testRollupProjBefore = [SELECT Id, Name, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, OpportunityTotal_Amount_Invoiced_To_Date__c, Total_Non_Bill_hours__c,
                                            NonLevBillableHoursBooked__c, NonLevNonBillHours__c, NonLevRevenueAmountBooked__c, Rollup_Billable__c, Rollup_Revenue__c, Rollup_Concession__c, Rollup_Nonbillable__c
                                        FROM Project__c
                                        WHERE Name = 'Test Oppty' LIMIT 1];

        //Assert that thew Rollups were properly calculated from the Replicon Time Entry Logic before we intentially change the values
        System.assertEquals(4, testRollupProjBefore.Rollup_Billable__c, 'Lev Billable Hours Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Billable Hours Booked correctly calculated
        System.assertEquals(800, testRollupProjBefore.Rollup_Revenue__c, 'Lev Revenue Amount Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Revenue Amount Booked correctly calculated
        System.assertEquals(4, testRollupProjBefore.Rollup_Concession__c, 'Lev Concession Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Concession Non-Billable Hours Booked correctly calculated
        System.assertEquals(4, testRollupProjBefore.Rollup_Nonbillable__c, 'Lev Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Lev Non-Billable Hours correctly calculated
        System.assertEquals(4, testRollupProjBefore.NonLevBillableHoursBooked__c, 'Non-Lev Billable Hours Booked  was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Billable Hours Booked  correctly calculated
        System.assertEquals(4, testRollupProjBefore.NonLevNonBillHours__c, 'Non-Lev Non-Billable Hours was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Non-Billable Hours correctly calculated
        System.assertEquals(800, testRollupProjBefore.NonLevRevenueAmountBooked__c, 'Non-Lev Revenue Amount Booked was not correctly calculated for this Project BEFORE the Batch run'); //Assert that the Project has Non-Lev Revenue Amount Booked correctly calculated

        //Update Project to the wrong Rollup Values so the Batch run can correct it
        testRollupProjBefore.Rollup_Billable__c = 0;
        testRollupProjBefore.Rollup_Revenue__c = 0;
        testRollupProjBefore.Rollup_Concession__c = 0;
        testRollupProjBefore.Rollup_Nonbillable__c = 0;
        testRollupProjBefore.NonLevBillableHoursBooked__c = 0;
        testRollupProjBefore.NonLevNonBillHours__c = 0;
        testRollupProjBefore.NonLevRevenueAmountBooked__c = 0;
        update testRollupProjBefore;

        Test.startTest();
        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Oppty'];
        LevNonLevProjectRollupBatch newBatch = new LevNonLevProjectRollupBatch(false, projList);
        Database.executeBatch(newBatch, 10);
        Test.stopTest();

        Project__c testRollupProjAfter = [SELECT Id, Name, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, OpportunityTotal_Amount_Invoiced_To_Date__c, Total_Non_Bill_hours__c,
                                            NonLevBillableHoursBooked__c, NonLevNonBillHours__c, NonLevRevenueAmountBooked__c, Rollup_Billable__c, Rollup_Revenue__c, Rollup_Concession__c, Rollup_Nonbillable__c
                                        FROM Project__c
                                        WHERE Name = 'Test Oppty' LIMIT 1];

        //Assert that the Batch Job correctly Re-calculated the Project Rollups
        System.assertEquals(4, testRollupProjAfter.Rollup_Billable__c, 'Lev Billable Hours Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Billable Hours Booked correctly calculated
        System.assertEquals(800, testRollupProjAfter.Rollup_Revenue__c, 'Lev Revenue Amount Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Revenue Amount Booked correctly calculated
        System.assertEquals(4, testRollupProjAfter.Rollup_Concession__c, 'Lev Concession Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Concession Non-Billable Hours Booked correctly calculated
        System.assertEquals(4, testRollupProjAfter.Rollup_Nonbillable__c, 'Lev Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Lev Non-Billable Hours correctly calculated
        System.assertEquals(4, testRollupProjAfter.NonLevBillableHoursBooked__c, 'Non-Lev Billable Hours Booked  was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Billable Hours Booked  correctly calculated
        System.assertEquals(4, testRollupProjAfter.NonLevNonBillHours__c, 'Non-Lev Non-Billable Hours was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Non-Billable Hours correctly calculated
        System.assertEquals(800, testRollupProjAfter.NonLevRevenueAmountBooked__c, 'Non-Lev Revenue Amount Booked was not correctly calculated for this Project AFTER the Batch run'); //Assert that the Project has Non-Lev Revenue Amount Booked correctly calculated
    }
}