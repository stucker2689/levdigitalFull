@isTest
public with sharing class RepliconTimeEntryDeleteBatchTest {

    @testSetup
    static void setupData() {
        List<Account> testAccountList = new List<Account>();
        Account newAccount = new Account();
        newAccount.Name = 'Test Account123';
        newAccount.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        newAccount.MSA_Number__c = 'MSA_Test01';
        testAccountList.add(newAccount);

        Account newCompanyAccount = new Account();
        newCompanyAccount.Name = 'Levementum LLC';
        testAccountList.add(newCompanyAccount);

        insert testAccountList;

        Contact employee1 = new Contact();
        employee1.FirstName = 'Test2';
        employee1.LastName = 'Employee100';
        employee1.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee1.Email = 'temployee100@levdigital.com';
        employee1.Replicon_User_Number__c = 1;
        employee1.RepliconLoginName__c = 'temployee1';
        insert employee1;

        Opportunity opportunity1 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        opportunity1.AccountId = newAccount.Id;
        opportunity1.Name = 'Test Project';
        opportunity1.CloseDate = system.today()+60;
        opportunity1.Amount = 55000.00;
        opportunity1.StageName='Closed Won';
        opportunity1.ExpectedPro_DurationinWeeks__c = 3;
        opportunity1.Project_Terms__c = 'Time and Materials';
        opportunity1.Payment_Terms__c = 'Invoice Net 15';
        opportunity1.Number_of_Contact_Rolls_Added__c = 1;
        insert opportunity1;

        Project__c project1 = new Project__c();
        project1.Account__c = newAccount.Id;
        project1.Opportunity__c = opportunity1.Id;
        project1.Name = 'Test Project';
        project1.Project_Status__c = 'In Progress';
        project1.RepliconUri__c='urn:replicon-tenant:levementum:project:1154';
        insert project1;

        List<Contact> testContacts = new List<Contact>();
        testContacts = [SELECT Id, Name, Replicon_User_Number__c FROM Contact WHERE LastName = 'Employee100' LIMIT 1];
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee100@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(true, employeeID);

        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testNonBillableTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testConcessionTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        //Create Project_Team_Member_Billing_Rate__c
        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 250;
        billingRateList.add(testBillingRate);
        Project_Team_Member_Billing_Rate__c testConcessionRate = new Project_Team_Member_Billing_Rate__c();
        testConcessionRate.Hourly_Rate__c = 0;
        billingRateList.add(testConcessionRate);

        insert billingRateList;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 3.25;
        testBillableTimeEntry1.Deleted_in_Replicon__c = true; 
        timeEntryList.add(testBillableTimeEntry1);
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4.5;
        testBillableTimeEntry2.Deleted_in_Replicon__c = true; 
        timeEntryList.add(testBillableTimeEntry2); 
        testNonBillableTimeEntry.Associated_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.Override_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.TotalHrs__c = 6; 
        timeEntryList.add(testNonBillableTimeEntry);
        testConcessionTimeEntry.Override_Billing_Rate__c = testConcessionRate.Id;
        testConcessionTimeEntry.Associated_Billing_Rate__c = NULL;
        testConcessionTimeEntry.TotalHrs__c = 8; 
        timeEntryList.add(testConcessionTimeEntry);

        insert timeEntryList;
    }
    
    @isTest
    static void getTimeEntryDeleteContinuedBatch(){
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee100@levdigital.com'].Id;
        List<Replicon_Time_Entry__c> testTimeEntries = new List<Replicon_Time_Entry__c>();
        testTimeEntries = [SELECT Id FROM Replicon_Time_Entry__c WHERE Employee__c =: employeeID];

        String cronExpr1 = '0 0 0 15 3 ? 2022';
        Test.startTest();
        RepliconTimeEntryDeleteScheduler newContinuedTestScheduler = new RepliconTimeEntryDeleteScheduler(testTimeEntries, 5, 1);
        String jobId = System.schedule('RepliconTimeEntryBatchScheduler', cronExpr1, newContinuedTestScheduler);
        newContinuedTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getTimeEntryDeleteBatchTest() {
        String cronExpr2 = '0 0 0 15 3 ? 2022';
        Test.startTest();
        RepliconTimeEntryDeleteScheduler newTestScheduler = new RepliconTimeEntryDeleteScheduler(1);
        String jobId = System.schedule('RepliconTimeEntryBatchScheduler', cronExpr2, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getDeleteBatchTest(){
        Date testDate = Date.valueOf('2021-05-05');
        Test.startTest();
        RepliconTimeEntryDeleteBatch newTimeEntryTestBatch = new RepliconTimeEntryDeleteBatch(System.Today(), 5, 1);
        Database.executeBatch(newTimeEntryTestBatch, 200);
        Test.stopTest();


    }

    @isTest
    static void getDeleteEntries(){

        Id testAccountId = [SELECT Id, Name FROM Account WHERE Name = 'Test Account123'].Id;
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee100@levdigital.com'].Id;

        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(false, employeeID);
        testTimeSheet.Start_Date__c = System.today().addMonths(-1);
        insert testTimeSheet;
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        List<Id> timeEntryIds = new List<Id>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        testBillableTimeEntry1.Deleted_in_Replicon__c = true;
        insert testBillableTimeEntry1;

        timeEntryIds.add(testBillableTimeEntry1.Id);
        Date lastMonth = System.today().addMonths(-1);

        Test.startTest();
        DeleteRepliconTimeEntries.getTimeEntriesToDelete(lastMonth, timeEntryIds);
        Test.stopTest();

    }

}