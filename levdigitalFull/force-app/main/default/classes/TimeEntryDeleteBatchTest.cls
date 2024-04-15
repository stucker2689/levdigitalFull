@isTest
public class TimeEntryDeleteBatchTest {

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

        Date testEntryDate = Date.newInstance(2022, 1, 10);

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 3.25;
        testBillableTimeEntry1.Deleted_in_Replicon__c = true; 
        testBillableTimeEntry1.EntryDate__c = testEntryDate;

        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4.5;
        testBillableTimeEntry2.Deleted_in_Replicon__c = true; 
        testBillableTimeEntry2.EntryDate__c = testEntryDate;

        testNonBillableTimeEntry.Associated_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.Override_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.TotalHrs__c = 6; 
        testNonBillableTimeEntry.EntryDate__c = testEntryDate;

        testConcessionTimeEntry.Override_Billing_Rate__c = testConcessionRate.Id;
        testConcessionTimeEntry.Associated_Billing_Rate__c = NULL;
        testConcessionTimeEntry.TotalHrs__c = 8; 
        testConcessionTimeEntry.EntryDate__c = testEntryDate;

        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testNonBillableTimeEntry, testConcessionTimeEntry};

        insert timeEntryList;
    }
    
    @isTest
    static void testTimeEntryDeleteBatch(){
        Test.startTest();
        TimeEntryDeleteBatch newDeleteTimeEntriesRun = new TimeEntryDeleteBatch();
        Database.executeBatch(newDeleteTimeEntriesRun, 5); 
        Test.stopTest();
    }

    @isTest
    static void scheduleTimEntryDeleteBatch(){
        String cronExpr = '0 0 0 31 12 ? 2022';
        Test.startTest();
        TimeEntryDeleteBatch newTestScheduler = new TimeEntryDeleteBatch();
        String jobId = System.schedule('Delete Time Entrys Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }


}