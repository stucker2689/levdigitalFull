/**
 * Created by Sam Tucker 4/1/2022
 * Purpose: To Test WeeklyTargetTimeEntryMatchBatch
 */
@isTest
private class WeeklyTargetTimeEntryMatchBatchTest {
    
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
        oppo.Name = 'Weekly Target Match Batch Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Weekly Target Match Batch Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        //Build and insert the Timesheet First, then build the Time Entries
        /*Replicon_Timesheet__c timesheetForFirstWeekOfJanuary = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForFirstWeekOfJanuary.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220102';
        timesheetForFirstWeekOfJanuary.Start_Date__c = Date.newInstance(2022, 1, 2); //Start of the Full Week of the First Week of January 2022
        
        Replicon_Timesheet__c timesheetForSecondWeekOfJanuary = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForSecondWeekOfJanuary.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220109';
        timesheetForSecondWeekOfJanuary.Start_Date__c = Date.newInstance(2022, 1, 9); //Second Full Week Entirely in January 2022

        Replicon_Timesheet__c timesheetForFebruary = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForFebruary.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220213';
        timesheetForFebruary.Start_Date__c = Date.newInstance(2022, 2, 13); //Third Full Week of the First Week of January 2022

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstWeekOfJanuary, timesheetForSecondWeekOfJanuary, timesheetForFebruary};
        insert testTimesheetList;

        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJanuary.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.newInstance(2022, 1, 5);
        entryOne.TotalHrs__c = 5;
        entryOne.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220105';        

        Replicon_Time_Entry__c entryTwo = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJanuary.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        entryTwo.EntryDate__c = Date.newInstance(2022, 1, 6);
        entryTwo.TotalHrs__c = 6;
        entryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220106';

        Replicon_Time_Entry__c entryThree = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJanuary.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        entryThree.EntryDate__c = Date.newInstance(2022, 1, 7);
        entryThree.TotalHrs__c = 7;
        entryThree.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryThree.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220107';

        Replicon_Time_Entry__c entryFour = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJanuary.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        entryFour.EntryDate__c = Date.newInstance(2022, 1, 10);
        entryFour.TotalHrs__c = 1.5;
        entryFour.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryFour.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220110';

        Replicon_Time_Entry__c entryFive = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJanuary.Id, con.Id, testProj);
        entryFive.EntryDate__c = Date.newInstance(2022, 1, 11);
        entryFive.TotalHrs__c = 8;
        entryFive.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryFive.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220111';

        Replicon_Time_Entry__c entrySix = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJanuary.Id, con.Id, testProj);
        entrySix.EntryDate__c = Date.newInstance(2022, 1, 12);
        entrySix.TotalHrs__c = 9;
        entrySix.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entrySix.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202201121';

        Replicon_Time_Entry__c entrySeven = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJanuary.Id, con.Id, testProj);
        entrySeven.EntryDate__c = Date.newInstance(2022, 1, 12);
        entrySeven.TotalHrs__c = 0.5;
        entrySeven.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entrySeven.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202201122';

        Replicon_Time_Entry__c entryEight = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJanuary.Id, con.Id, testProj);
        entryEight.EntryDate__c = Date.newInstance(2022, 1, 13);
        entryEight.TotalHrs__c = 10;
        entryEight.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryEight.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220113';

        Replicon_Time_Entry__c entryNine = TestDataFactory.createTimeEntry(false, timesheetForFebruary.Id, con.Id, testProj);
        entryNine.EntryDate__c = Date.newInstance(2022, 2, 15);
        entryNine.TotalHrs__c = 11;
        entryNine.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryNine.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220215';

        Replicon_Time_Entry__c entryTen = TestDataFactory.createTimeEntry(false, timesheetForFebruary.Id, con.Id, testProj);
        entryTen.EntryDate__c = Date.newInstance(2022, 2, 16);
        entryTen.TotalHrs__c = 12;
        entryTen.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryTen.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220216';

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo, entryThree, entryFour, entryFive, entrySix, entrySeven, entryEight, entryNine, entryTen};
        insert timeEntriesList;*/

        Replicon_Timesheet__c timesheetForFirstWeekOfJanuary = TestDataFactory.createTimesheet(false, con.Id);
        timesheetForFirstWeekOfJanuary.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220102';
        timesheetForFirstWeekOfJanuary.Start_Date__c = Date.newInstance(2022, 1, 2); //Start of the Full Week of the First Week of January 2022

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstWeekOfJanuary};
        insert testTimesheetList;

        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJanuary.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.newInstance(2022, 1, 5);
        entryOne.TotalHrs__c = 5;
        entryOne.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220105';        

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne};
        insert timeEntriesList;
    }

    /*@isTest 
	static void testWeeklyTargetTimeEntryMatchBatch() {   
        /**
         * Testing Purpose: Populate Replicon Time Entries with their respective Weekly Target lookup.       
         */

        /*Revenue_Forecast__c testJanuaryMonthlyRevForecast = new Revenue_Forecast__c();
        testJanuaryMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJanuaryMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 1, 1);
        testJanuaryMonthlyRevForecast.MonthlyTarget__c = 1900000; //19 Million for clean distribution of target to weeks because of 19 Business days in January 2022 (There are 2 holidays in January, New Years (1/3/2022) & MLK Day (1/17/2022))

        List<Revenue_Forecast__c> revForecastsListBefore = new List<Revenue_Forecast__c>();
        revForecastsListBefore = [SELECT Id, MonthlyActuals__c, WeeklyActuals__c, RecordTypeId
                                    FROM Revenue_Forecast__c];

        for(Revenue_Forecast__c revForecast : revForecastsListBefore){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                System.debug('Weekly Target BEFORE: ' + revForecast.WeeklyActuals__c);
                System.assertEquals(revForecast.WeeklyActuals__c, null, 'Weekly Targets Actual $ not properly rolled up before batch run');

            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                System.debug('Monthly Target BEFORE: ' + revForecast.MonthlyActuals__c);
                System.assertEquals(revForecast.MonthlyActuals__c, null, 'Monthly Targets Actual $ not properly rolled up before batch run');

            }
        }

        List<Replicon_Time_Entry__c> timeEntriesListBefore = new List<Replicon_Time_Entry__c>();
        timeEntriesListBefore = [SELECT Id, EntryDate__c, WeekEndDate__c, WeeklyTarget__c, Replicon_URI__c, TotalHrs__c, Project__c
                                    FROM Replicon_Time_Entry__c];

        for(Replicon_Time_Entry__c entry : timeEntriesListBefore){
            System.assertEquals(entry.WeeklyTarget__c, null, 'Replicon Time Entries incorrectly populated with Weekly Targets before batch run');
        }

        Test.startTest();
        WeeklyTargetTimeEntryMatchBatch newTimeEntryMatchBatch = new WeeklyTargetTimeEntryMatchBatch(1, 2022);
        Database.executeBatch(newTimeEntryMatchBatch, 10); //Batch size determines how many Time Entries to update at a time
        Test.stopTest();

        List<Replicon_Time_Entry__c> timeEntriesListAfter = new List<Replicon_Time_Entry__c>();
        timeEntriesListAfter = [SELECT Id, EntryDate__c, WeekEndDate__c, WeeklyTarget__c, Replicon_URI__c, TotalHrs__c, Project__c
                            FROM Replicon_Time_Entry__c];

        for(Replicon_Time_Entry__c entry : timeEntriesListAfter){
            if(entry.EntryDate__c.month() == 1 && entry.EntryDate__c.year() == 2022){
                System.assertNotEquals(entry.WeeklyTarget__c, null, 'January 2022 Replicon Time Entries not correctly populated with Weekly Targets after January 2022 Time Entry Match Batch run');
            }else{
                System.assertEquals(entry.WeeklyTarget__c, null, 'Non-January 2022 Replicon Time Entries incorrectly populated with Weekly Targets after January 2022 Time Entry Match Batch run');
            }
        }

        List<Revenue_Forecast__c> revForecastsListAfter = new List<Revenue_Forecast__c>();
        revForecastsListAfter = [SELECT Id, MonthlyActuals__c, WeeklyActuals__c, RecordTypeId
                                    FROM Revenue_Forecast__c];

        for(Revenue_Forecast__c revForecast : revForecastsListAfter){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                System.debug('Weekly Target AFTER: ' + revForecast.WeeklyActuals__c);
                System.assertNotEquals(revForecast.WeeklyActuals__c, null, 'Weekly Targets Actual $ not properly rolled up after batch run');

            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                System.debug('Monthly Target AFTER: ' + revForecast.MonthlyActuals__c);
                System.assertNotEquals(revForecast.MonthlyActuals__c, null, 'Monthly Targets Actual $ not properly rolled up after batch run');

            }
        }
    }*/

    @isTest
    static void testRunMatchBatch(){

        Revenue_Forecast__c testJanuaryMonthlyRevForecast = new Revenue_Forecast__c();
        testJanuaryMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJanuaryMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 1, 1);
        testJanuaryMonthlyRevForecast.MonthlyTarget__c = 1900000; //19 Million for clean distribution of target to weeks because of 19 Business days in January 2022 (There are 2 holidays in January, New Years (1/3/2022) & MLK Day (1/17/2022))
        insert testJanuaryMonthlyRevForecast;

        List<Revenue_Forecast__c> revForecastsListBefore = new List<Revenue_Forecast__c>();
        revForecastsListBefore = [SELECT Id, MonthlyActuals__c, WeeklyActuals__c, RecordTypeId
                                    FROM Revenue_Forecast__c];

        for(Revenue_Forecast__c revForecast : revForecastsListBefore){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                System.debug('Weekly Target BEFORE: ' + revForecast.WeeklyActuals__c);
                System.assertEquals(revForecast.WeeklyActuals__c, null, 'Weekly Targets Actual $ not properly rolled up before batch run');

            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                System.debug('Monthly Target BEFORE: ' + revForecast.MonthlyActuals__c);
                System.assertEquals(revForecast.MonthlyActuals__c, null, 'Monthly Targets Actual $ not properly rolled up before batch run');

            }
        }

        Test.startTest();
        WeeklyTargetTimeEntryMatchBatch newTimeEntryMatchBatch = new WeeklyTargetTimeEntryMatchBatch(1, 2022);
        Database.executeBatch(newTimeEntryMatchBatch, 10); //Batch size determines how many Time Entries to update at a time
        Test.stopTest();
    }

    @isTest
    static void testRunMatchBatchTwo(){

        Revenue_Forecast__c testJanuaryMonthlyRevForecast = new Revenue_Forecast__c();
        testJanuaryMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJanuaryMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 1, 1);
        testJanuaryMonthlyRevForecast.MonthlyTarget__c = 1900000; //19 Million for clean distribution of target to weeks because of 19 Business days in January 2022 (There are 2 holidays in January, New Years (1/3/2022) & MLK Day (1/17/2022))
        insert testJanuaryMonthlyRevForecast;

        List<Revenue_Forecast__c> revForecastsListBefore = new List<Revenue_Forecast__c>();
        revForecastsListBefore = [SELECT Id, MonthlyActuals__c, WeeklyActuals__c, RecordTypeId
                                    FROM Revenue_Forecast__c];

        for(Revenue_Forecast__c revForecast : revForecastsListBefore){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                System.debug('Weekly Target BEFORE: ' + revForecast.WeeklyActuals__c);
                System.assertEquals(revForecast.WeeklyActuals__c, null, 'Weekly Targets Actual $ not properly rolled up before batch run');

            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                System.debug('Monthly Target BEFORE: ' + revForecast.MonthlyActuals__c);
                System.assertEquals(revForecast.MonthlyActuals__c, null, 'Monthly Targets Actual $ not properly rolled up before batch run');

            }
        }

        Test.startTest();
        List<Integer> monthList = new List<Integer>{1, 2, 3};
        List<Integer> yearList = new List<Integer>{2022};
        WeeklyTargetTimeEntryMatchBatchTwo newTimeEntryMatchBatch = new WeeklyTargetTimeEntryMatchBatchTwo(monthList, yearList);
        Database.executeBatch(newTimeEntryMatchBatch, 10); //Batch size determines how many Time Entries to update at a time
        Test.stopTest();
    }
}