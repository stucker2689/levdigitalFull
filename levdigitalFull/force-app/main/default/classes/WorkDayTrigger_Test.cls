@isTest
public with sharing class WorkDayTrigger_Test {

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
        oppo.Name = 'Work Day Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Work Day Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Department = 'Consulting';
        con.Division_New__c = 'Next Lev';
        con.Division__c = 'Not Ops Management';
        con.Replicon_User_Number__c = 44;
        con.Quarterly_Target__c = 414;
        con.RampTime__c = 10;
        con.Hire_Date__c = Date.newInstance(2022, 1, 1);
        insert con;

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        Revenue_Forecast__c testOctoberMonthlyRevForecast = new Revenue_Forecast__c();
        testOctoberMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testOctoberMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 10, 1);
        testOctoberMonthlyRevForecast.MonthlyTarget__c = 2100000;
        insert testOctoberMonthlyRevForecast;

        Date timesheetWeekStartDate = Date.newInstance(2022, 10, 9); 
        Date newTimesheetWeekStartDate = Date.newInstance(2022, 10, 9); 
        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Start_Date__c = timesheetWeekStartDate;
        testTimesheet.Target__c = 36;
        insert testTimesheet;

    }

    @isTest
    static void updateWorkingHoursFromLOATimeInsert(){

        Date octoberEleventhDate = Date.newInstance(2022, 10, 11);

        WorkDay__c beforeLOAInsertWorkDay = [SELECT Id, Name, TotalLOAHours__c, WorkingHours__c, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c =: octoberEleventhDate LIMIT 1];
        Replicon_Timesheet__c testTimesheet = [SELECT Id, Name, Employee__c, TotalLOAHours__c FROM Replicon_Timesheet__c LIMIT 1];

        System.assertEquals(8, beforeLOAInsertWorkDay.WorkingHours__c, 'Working Hours were not properly set on Work Day creation');

        Replicon_Time_Entry__c loaEntry = new Replicon_Time_Entry__c();
        loaEntry.Replicon_Timesheet__c = testTimesheet.Id;
        loaEntry.Employee__c = testTimesheet.Employee__c;
        loaEntry.Time_Off__c = true;
        loaEntry.Time_Off_Description__c = 'LOA';
        loaEntry.TotalHrs__c = 8;
        loaEntry.EntryDate__c = octoberEleventhDate;

        Test.startTest();
        insert loaEntry;
        Test.stopTest();


        WorkDay__c afterLOAInsertWorkDay = [SELECT Id, Name, TotalLOAHours__c, WorkingHours__c, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c =: octoberEleventhDate LIMIT 1];

        System.assertEquals(0, afterLOAInsertWorkDay.WorkingHours__c, 'Working Hours were not properly set to 0 on Work Day after LOA time was added.');
        System.assertEquals(8, afterLOAInsertWorkDay.TotalLOAHours__c, 'Total LOA Hours were not correctly rolled up onto the Work Day record.');
        
    }

    @isTest
    static void updateWorkingHoursFromLOATimeDeletion(){

        System.debug('*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/ Update Working Hours FROM LOA TIME Deletion START */*/*/*/*/*/*/*/*/*/*/*/*/*/*/');

        Date octoberEleventhDate = Date.newInstance(2022, 10, 11);

        WorkDay__c beforeLOAInsertWorkDay = [SELECT Id, Name, TotalLOAHours__c, WorkingHours__c, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c =: octoberEleventhDate LIMIT 1];
        Replicon_Timesheet__c testTimesheet = [SELECT Id, Name, Employee__c, TotalLOAHours__c FROM Replicon_Timesheet__c LIMIT 1];

        Replicon_Time_Entry__c loaEntry = new Replicon_Time_Entry__c();
        loaEntry.Replicon_Timesheet__c = testTimesheet.Id;
        loaEntry.Employee__c = testTimesheet.Employee__c;
        loaEntry.Time_Off__c = true;
        loaEntry.Time_Off_Description__c = 'LOA';
        loaEntry.TotalHrs__c = 8;
        loaEntry.EntryDate__c = octoberEleventhDate;
        insert loaEntry;

        WorkDay__c afterLOAInsertWorkDay = [SELECT Id, Name, TotalLOAHours__c, WorkingHours__c, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c =: octoberEleventhDate LIMIT 1];

        System.assertEquals(0, afterLOAInsertWorkDay.WorkingHours__c, 'Working Hours were not properly set to 0 on Work Day after LOA time was added.');
        System.assertEquals(8, afterLOAInsertWorkDay.TotalLOAHours__c, 'Total LOA Hours were not correctly rolled up onto the Work Day record.');

        System.debug('*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/ BEFORE LOA TIME DELETION */*/*/*/*/*/*/*/*/*/*/*/*/*/*/');

        Test.startTest();
        loaEntry.Deleted_in_Replicon__c = true;
        update loaEntry;
        Test.stopTest();

        System.debug('*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/ AFTER LOA TIME DELETION */*/*/*/*/*/*/*/*/*/*/*/*/*/*/');

        WorkDay__c afterLOADeletionWorkDay = [SELECT Id, Name, TotalLOAHours__c, WorkingHours__c, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c =: octoberEleventhDate LIMIT 1];

        System.assertEquals(0, afterLOADeletionWorkDay.TotalLOAHours__c, 'Total LOA Hours were not correctly rolled up onto the Work Day record.');
        System.assertEquals(8, afterLOADeletionWorkDay.WorkingHours__c, 'Working Hours were not properly set to 8 on Work Day after LOA time was deleted.');
        
    }
}