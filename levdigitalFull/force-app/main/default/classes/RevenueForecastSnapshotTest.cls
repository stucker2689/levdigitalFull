/**
 * Created by Sam Tucker 3/4/2022
 * Purpose: To Test RevenueForecastSnapshot, MonthlyTargetRevenueBacklogSnapScheduler, WeeklyTargetRevenueBacklogSnapScheduler
 */

@isTest
private class RevenueForecastSnapshotTest {
    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    @testSetup
    static void testSetupData(){
        //Create Acc
        List<Account> testAccountList = new List<Account>();
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        testAccountList.add(levementumLLCAcct);

        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        testAccountList.add(acct);

        insert testAccountList;

        //Create Opp
        Opportunity oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'Revenue Forecast Snapshot Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Revenue Forecast Snapshot Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123


        //Build and insert the Timesheet First, then build the Time Entries
        /*Replicon_Timesheet__c timesheetForFirstWeekOfJune = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForFirstWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220529';
        timesheetForFirstWeekOfJune.Start_Date__c = Date.newInstance(2022, 5, 29); //Start of the Full Week of the First Week of June 2022 (Week Starts in May)

        Replicon_Timesheet__c timesheetForSecondWeekOfJune = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForSecondWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220605';
        timesheetForSecondWeekOfJune.Start_Date__c = Date.newInstance(2022, 6, 5); //First Full Week Entirely in June 2022

        Replicon_Timesheet__c timesheetForFirstWeekOfJuly = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForFirstWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220626';
        timesheetForFirstWeekOfJuly.Start_Date__c = Date.newInstance(2022, 6, 26); //Start of the Full Week of the First Week of July 2022 (Week Starts in June)

        Replicon_Timesheet__c timesheetForSecondWeekOfJuly = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForSecondWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForSecondWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 3); //First Full Week Entirely in July 2022

        Replicon_Timesheet__c timesheetForLastWeekOfJuly = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForLastWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForLastWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 31); //First Full Week Entirely in July 2022

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstWeekOfJune, timesheetForSecondWeekOfJune, timesheetForFirstWeekOfJuly, timesheetForSecondWeekOfJuly, timesheetForLastWeekOfJuly};
        insert testTimesheetList;

        Replicon_Time_Entry__c lastWeekOfMayEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        lastWeekOfMayEntry.EntryDate__c = Date.newInstance(2022, 5, 31);
        lastWeekOfMayEntry.TotalHrs__c = 5;
        lastWeekOfMayEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfMayEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220531';        

        Replicon_Time_Entry__c firstWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        firstWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 1);
        firstWeekOfJuneEntry.TotalHrs__c = 6;
        firstWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220601';

        Replicon_Time_Entry__c secondWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 6);
        secondWeekOfJuneEntry.TotalHrs__c = 7;
        secondWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220606';

        Replicon_Time_Entry__c secondWeekOfJuneEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntryTwo.EntryDate__c = Date.newInstance(2022, 6, 8);
        secondWeekOfJuneEntryTwo.TotalHrs__c = 1.5;
        secondWeekOfJuneEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220608';

        Replicon_Time_Entry__c lastWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, con.Id, testProj);
        lastWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 30);
        lastWeekOfJuneEntry.TotalHrs__c = 8;
        lastWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220631';

        Replicon_Time_Entry__c firstWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, con.Id, testProj);
        firstWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntry.TotalHrs__c = 9;
        firstWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220701';

        Replicon_Time_Entry__c firstWeekOfJulyEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, con.Id, testProj);
        firstWeekOfJulyEntryTwo.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntryTwo.TotalHrs__c = 0.5;
        firstWeekOfJulyEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202207012';

        Replicon_Time_Entry__c secondWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJuly.Id, con.Id, testProj);
        secondWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 3);
        secondWeekOfJulyEntry.TotalHrs__c = 10;
        secondWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220705';

        Replicon_Time_Entry__c lastWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, con.Id, testProj);
        lastWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 31);
        lastWeekOfJulyEntry.TotalHrs__c = 11;
        lastWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220731';

        Replicon_Time_Entry__c firstWeekOfAugustEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, con.Id, testProj);
        firstWeekOfAugustEntry.EntryDate__c = Date.newInstance(2022, 8, 1);
        firstWeekOfAugustEntry.TotalHrs__c = 12;
        firstWeekOfAugustEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfAugustEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220801';*/


        Integer currentMonth = Date.today().month();
        Integer nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
        Integer previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;

        //Insert Monthly Targets for the Current Date
        Revenue_Forecast__c testCurrentMonthMonthlyRevForecast = new Revenue_Forecast__c();
        testCurrentMonthMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testCurrentMonthMonthlyRevForecast.MonthStartDate__c = Date.newInstance(Date.today().year(), currentMonth, 1);
        testCurrentMonthMonthlyRevForecast.MonthlyTarget__c = 2000000;

        Revenue_Forecast__c testNextMonthMonthlyRevForecast = new Revenue_Forecast__c();
        testNextMonthMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testNextMonthMonthlyRevForecast.MonthStartDate__c = Date.newInstance(Date.today().year(), nextMonth, 1);
        testNextMonthMonthlyRevForecast.MonthlyTarget__c = 2000000;

        Revenue_Forecast__c testPreviousMonthMonthlyRevForecast = new Revenue_Forecast__c();
        testPreviousMonthMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testPreviousMonthMonthlyRevForecast.MonthStartDate__c = Date.newInstance(Date.today().year(), previousMonth, 1);
        testPreviousMonthMonthlyRevForecast.MonthlyTarget__c = 2000000;

        List<Revenue_Forecast__c> monthlyRevenueForecastList = new List<Revenue_Forecast__c>{testCurrentMonthMonthlyRevForecast, testNextMonthMonthlyRevForecast, testPreviousMonthMonthlyRevForecast};
        insert monthlyRevenueForecastList;
    }

    @isTest 
	static void testMonthlySnapshot() {   
        /**
         * Testing Purpose: Take the snapshot of the current Revenue Backlog and populate the Start of Month Revenue Backlog on the Revenue Forecast Monthly Target for the current Month
         *                  Also populate the End Of Month Revenue Backlog for the Revenue Forecast Monthly Target for the previous Month
         */
	}

    @isTest 
	static void testWeeklySnapshot() {   
        /**
         * Testing Purpose: Take the snapshot of the current Revenue Backlog and populate the Start of Week Revenue Backlog on the Revenue Forecast Weekly Target for the current Week
         *                  Also populate the End Of Week Revenue Backlog for the Revenue Forecast Weekly Target for the previous Week 
         */
	}

    @isTest
    static void testWeeklyForecastSnapshot(){
        /**
         * Testing Purpose: Take the snapshot of the current Forecast $ for the current Weekly Target record and paste a static copy of that value into the Week Forecast Snapshot field on the same record.
         */
    }

    @isTest
    static void testScheduleMonthlySnapshot(){
        /**
         * Testing Purpose: Test the Scheduler Class for Monthly Revenue Backlog Snapshot
         */
        
        String cronExpr = '0 0 6 1 * ?';
        Test.startTest();
        MonthlyTargetRevenueBacklogSnapScheduler monthlyTargetRevBacklogSnapScheduler = new MonthlyTargetRevenueBacklogSnapScheduler();
        String jobId = System.schedule('Monthly Start and End Revenue Backlog Snapshot TEST' , cronExpr, monthlyTargetRevBacklogSnapScheduler);
        monthlyTargetRevBacklogSnapScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testScheduleWeeklySnapshot(){
        /**
         * Testing Purpose: Test the Scheduler Class for Weekly Revenue Backlog Snapshot
         */ 
        String cronExpr = '0 5 6 ? * 1';
        Test.startTest();
        WeeklyTargetRevenueBacklogSnapScheduler weeklyTargetRevBacklogSnapSchedulerTest = new WeeklyTargetRevenueBacklogSnapScheduler();
        String jobId = System.schedule('Weekly Start and End Revenue Backlog Snapshot TEST', cronExpr, weeklyTargetRevBacklogSnapSchedulerTest);
        weeklyTargetRevBacklogSnapSchedulerTest.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testScheduleWeeklyForecastSnapshot(){
        /**
         * Testing Purpose: Test the Scheduler Class for Weekly Forecast Snapshot
         */ 
        String cronExpr = '0 0 6 ? * FRI';
        Test.startTest();
        WeeklyForecastSnapshotScheduler weeklyForecastSnapshot = new WeeklyForecastSnapshotScheduler();
        String jobId = System.schedule('Weekly Forecast Amount Snapshot TEST', cronExpr, weeklyForecastSnapshot);
        weeklyForecastSnapshot.execute(null);
        Test.stopTest();
    }

}