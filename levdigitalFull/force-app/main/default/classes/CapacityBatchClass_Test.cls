/**
 * Created 10.6.22 ST
 * Used to test multiple batch classes that are used in Capacity Work
 * 
 * 
 */


@isTest
private class CapacityBatchClass_Test {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    @TestSetup
    static void makeData(){
        List<Account> testAccountList = new List<Account>();
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        testAccountList.add(levementumLLCAcct);

        //Create Test Client Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        testAccountList.add(acct);

        //Insert Both Accounts
        insert testAccountList;

        //Create Test Oppty associated with the Client Account
        Opportunity oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'Timesheet Trigger Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Department = 'Consulting';
        con.Division_New__c = 'Next Lev';
        con.Division__c = 'Not Ops Management';
        con.Quarterly_Target__c=414;
        con.RampTime__c = 10;
        con.Hire_Date__c = Date.today();
        insert con;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220925';
        testTimesheet.Name = 'Test Lev Employee: 09/25/2022';
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Start_Date__c = Date.newInstance(2022, 9, 25);
        testTimesheet.Target__c = 36;

        Replicon_Timesheet__c testTimesheet2 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet2.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221002';
        testTimesheet2.Name = 'Test Lev Employee: 10/02/2022';
        testTimesheet2.EmployeeDepartment__c = 'Consulting';
        testTimesheet2.Start_Date__c = Date.newInstance(2022, 10, 2);

        Replicon_Timesheet__c testTimesheet3 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet3.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet3.Name = 'Test Lev Employee: 10/09/2022';
        testTimesheet3.EmployeeDepartment__c = 'Consulting';
        testTimesheet3.Start_Date__c = Date.newInstance(2022, 10, 9);

        Replicon_Timesheet__c testTimesheet4 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet4.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221016';
        testTimesheet4.Name = 'Test Lev Employee: 10/16/2022';
        testTimesheet4.EmployeeDepartment__c = 'Consulting';
        testTimesheet4.Start_Date__c = Date.newInstance(2022, 10, 16);

        Replicon_Timesheet__c testTimesheet5 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet5.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221023';
        testTimesheet5.Name = 'Test Lev Employee: 10/23/2022';
        testTimesheet5.EmployeeDepartment__c = 'Consulting';
        testTimesheet5.Start_Date__c = Date.newInstance(2022, 10, 23);

        Replicon_Timesheet__c testTimesheet6 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet6.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221030';
        testTimesheet6.Name = 'Test Lev Employee: 10/30/2022';
        testTimesheet6.Start_Date__c = Date.newInstance(2022, 10, 30);

        List<Replicon_Timesheet__c> timesheetInsertList = new List<Replicon_Timesheet__c>{testTimesheet, testTimesheet2, testTimesheet3, testTimesheet4, testTimesheet5, testTimesheet6};
        insert timesheetInsertList;

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        Replicon_Time_Entry__c testEntry = TestDataFactory.createTimeEntry(false, testTimesheet3.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        testEntry.EntryDate__c = Date.newInstance(2022, 10, 11);
        testEntry.TotalHrs__c = 5;
        testEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        testEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220531';        

        Replicon_Time_Entry__c testEntry2 = TestDataFactory.createTimeEntry(false, testTimesheet5.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        testEntry2.EntryDate__c = Date.newInstance(2022, 10, 28);
        testEntry2.TotalHrs__c = 6;
        testEntry2.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        testEntry2.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220601';

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{testEntry, testEntry2};
        insert entryInsertList;

        Revenue_Forecast__c testMarchMonthlyRevForecast = new Revenue_Forecast__c();
        testMarchMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testMarchMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 10, 1);
        testMarchMonthlyRevForecast.MonthlyTarget__c = 2100000;

        Integer currentMonthInteger;
        if(Date.today().month() == 10){
            currentMonthInteger = 11;
        }else{
            currentMonthInteger = Date.today().month();
        }
        Revenue_Forecast__c testeCurrentMonthRevForecast = new Revenue_Forecast__c();
        testeCurrentMonthRevForecast.RecordTypeId = monthlyTargetRT;
        testeCurrentMonthRevForecast.MonthStartDate__c = Date.newInstance(Date.today().year(), currentMonthInteger, 1);
        testeCurrentMonthRevForecast.MonthlyTarget__c = 40000000;
        
        List<Revenue_Forecast__c> monthlyTargetList = new List<Revenue_Forecast__c>{testMarchMonthlyRevForecast, testeCurrentMonthRevForecast};
        insert monthlyTargetList;
    }

    @isTest
    static void linkTimesheetsToCapacityBatch_Test(){

        Date startDateOne = Date.newInstance(2022, 10, 2);
        Date startDateTwo = Date.newInstance(2022, 10, 9);
        Date startDateThree = Date.newInstance(2022, 10, 16);
        Date startDateFour = Date.newInstance(2022, 10, 23);
        Date startDateFive = Date.newInstance(2022, 10, 30);
        List<Date> startDateList = new List<Date>{startDateOne, startDateTwo, startDateThree, startDateFour, startDateFive};


        //Test Linking Existing Timesheet Records to Capacity Records
        Test.startTest();
        LinkTimesheetsToCapacityBatch newTimesheetToCapacityMatchBatch = new LinkTimesheetsToCapacityBatch(startDateList);
        Database.executeBatch(newTimesheetToCapacityMatchBatch, 100);
        Test.stopTest();
    }

    @isTest
    static void setTimesheetsWeekTargetBatch_Test(){

        //Test set to set the Target field on existing Timesheets
        Test.startTest();
        SetTimesheetWeekTargetBatch setTimesheetTargetBatch = new SetTimesheetWeekTargetBatch();
        Database.executeBatch(setTimesheetTargetBatch, 100);
        Test.stopTest();
    }

    @isTest
    static void getCapacityAverageBillRate_Test(){

        //Get the Org Wide Average Rate
        Test.startTest();
        CapacityAverageBillRateSnapshot newAvgBilLRateBatch = new CapacityAverageBillRateSnapshot();
        Database.executeBatch(newAvgBilLRateBatch, 100);
        Test.stopTest();
    }

    @isTest
    static void scheduleCapacityAverageBillRate_Test(){

        Test.startTest();
        CapacityAverageBillRateSnapshot newAvgBilLRateBatch = new CapacityAverageBillRateSnapshot();
        System.schedule('Monthly Start Capacity Average Bill Rate Snapshot Test', '0 0 6 1 * ?', newAvgBilLRateBatch);
        Test.stopTest();
    }

    @isTest
    static void populateTimesheetContactDetailsBatch_Test(){

        List<Date> weekStartDateList = new List<Date>();
        Date firstStartDate = Date.newInstance(2021, 12, 26);
       
        weekStartDateList.add(firstStartDate);
        Date iterationWeekStartDate = firstStartDate;
        for(Integer i = 0; i < 52; i++){
           iterationWeekStartDate = iterationWeekStartDate.addDays(7);
           weekStartDateList.add(iterationWeekStartDate);
        }

        Test.startTest();
        PopulateTimesheetContactDetailsBatch newBatch = new PopulateTimesheetContactDetailsBatch(weekStartDateList);
        Database.executeBatch(newBatch, 100);
        Test.stopTest();
    }

    @isTest
    static void testBatchResource(){
        Test.startTest();
        Project__c proj = [SELECT Id, Name FROM Project__c LIMIT 1];
        Set<Id> newProjectIdList = new Set<Id>{proj.Id};
        Set<Id> returnedProjectIdList = new Set<Id>();

        BatchResource.addToProjectIdUpdateSet(newProjectIdList);
        returnedProjectIdList = BatchResource.getProjectUpdateSet();
        BatchResource.setRepliconTimeEntryBatchAsRunning();
        Boolean returnedBoolean = BatchResource.isRepliconTimeEntryBatchRunning();
        Test.stopTest();
    }

    @isTest
    static void testScheduleFlipShowActuals(){
        Test.startTest();
        CapacityShowActualsScheduled capacityActualsFlip = new CapacityShowActualsScheduled();
        System.schedule('Capacity Show Actuals Flip', '0 0 6 ? * MON', capacityActualsFlip);
        Test.stopTest();
    }

    /*@isTest
    static void testFlipShowActuals(){
        Test.startTest();
        CapacityShowActualsScheduled capacityActualsFlip = new CapacityShowActualsScheduled();
        capacityActualsFlip.FlipCapacityToShowActualsInsteadOfForecast();
        Test.stopTest();
    }*/

}