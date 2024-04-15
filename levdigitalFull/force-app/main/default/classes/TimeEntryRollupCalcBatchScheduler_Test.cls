@isTest
public with sharing class TimeEntryRollupCalcBatchScheduler_Test {
    
    @TestSetup
    static void makeData(){

        Account newClientAccount = new Account();
        newClientAccount.Name = 'Test Client Account';
        newClientAccount.RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId(); //Client Account Record Type Id
        insert newClientAccount;

        Contact testEmployeeContact1 = new Contact();
        testEmployeeContact1.FirstName = 'Test';
        testEmployeeContact1.LastName = 'Employee1';
        testEmployeeContact1.Email = 'testEmployee1@email.com'; 
        testEmployeeContact1.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId(); //Client Account Record Type Id
        testEmployeeContact1.Cognizant_Employee_Id__c = '123456';

        Contact testEmployeeContact2 = new Contact();
        testEmployeeContact2.FirstName = 'Test';
        testEmployeeContact2.LastName = 'Employee2';
        testEmployeeContact2.Email = 'testEmployee2@email.com'; 
        testEmployeeContact2.RecordTypeId = Schema.sObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId(); //Client Account Record Type Id
        testEmployeeContact2.Cognizant_Employee_Id__c = '654321';

        List<Contact> employeeInsertList = new List<Contact>{testEmployeeContact1, testEmployeeContact2};
        insert employeeInsertList;

        Opportunity newTestOpportunity1 = new Opportunity();
        newTestOpportunity1.Name = 'Test Opportunity #1';
        newTestOpportunity1.StageName = '1. Engagement';
        newTestOpportunity1.AccountId = newClientAccount.Id;
        newTestOpportunity1.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
        newTestOpportunity1.CloseDate = System.today().addDays(21);
        newTestOpportunity1.Service__c = 'Program';
        newTestOpportunity1.Program_Type__c = 'Campaign';
        newTestOpportunity1.Peoplesoft_Project_Id__c = '12345678';
        insert newTestOpportunity1;

        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(Name = 'Test Product Developer', ProductCode = 'TPD', isActive = true);
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = newTestOpportunity1.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 500);
        insert oli;

        /*newTestOpportunity1.StageName = '2. Shaping';
        update newTestOpportunity1;
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ After 2. Shaping ^^^^^^^^^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ CPU Time: ' + Limits.getCPUTime() + ' / ' + Limits.getLimitCpuTime());
        
        newTestOpportunity1.StageName = '3. Solutioning';
        update newTestOpportunity1;
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ After 3. Solutioning ^^^^^^^^^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ CPU Time: ' + Limits.getCPUTime() + ' / ' + Limits.getLimitCpuTime());

        newTestOpportunity1.StageName = '4. End-Game';
        update newTestOpportunity1;
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ After 4. End-Game ^^^^^^^^^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ CPU Time: ' + Limits.getCPUTime() + ' / ' + Limits.getLimitCpuTime());

        newTestOpportunity1.StageName = '5. Negotiation';
        update newTestOpportunity1;
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ After 5. Negotiation ^^^^^^^^^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ CPU Time: ' + Limits.getCPUTime() + ' / ' + Limits.getLimitCpuTime());*/

        newTestOpportunity1.StageName = 'Won';
        update newTestOpportunity1;
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ After Won ^^^^^^^^^^^^^^^^^^^^^^^^^');
        System.debug('^^^^^^^^^^^^^^^^^^^^^^^^^^ CPU Time: ' + Limits.getCPUTime() + ' / ' + Limits.getLimitCpuTime());

        
        
        
    }

    @isTest
    static void scheduleProjectRollupBatch_Test(){
        String cronExpr = '0 0 3 1 * ? *';
        Test.startTest();
        insertTestTimeEntries();
        TimeEntryRollupCalcBatchScheduler newProjectRollupScheduler = new TimeEntryRollupCalcBatchScheduler('Project');
        String jobId = System.schedule('TimeEntryRollupCalcBatchScheduler Test Batch Run', cronExpr, newProjectRollupScheduler);
        newProjectRollupScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void scheduleTimesheetRollupBatch_Test(){
        String cronExpr = '0 0 3 1 * ? *';
        Test.startTest();
        insertTestTimeEntries();
        TimeEntryRollupCalcBatchScheduler newTimesheetRollupScheduler = new TimeEntryRollupCalcBatchScheduler('Timesheet');
        String jobId = System.schedule('TimeEntryRollupCalcBatchScheduler Test Batch Run', cronExpr, newTimesheetRollupScheduler);
        newTimesheetRollupScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void scheduleWorkDayRollupBatch_Test(){
        String cronExpr = '0 0 3 1 * ? *';
        Test.startTest();
        insertTestTimeEntries();
        TimeEntryRollupCalcBatchScheduler newWorkDayRollupScheduler = new TimeEntryRollupCalcBatchScheduler('Work Day');
        String jobId = System.schedule('TimeEntryRollupCalcBatchScheduler Test Batch Run', cronExpr, newWorkDayRollupScheduler);
        newWorkDayRollupScheduler.execute(null);
        Test.stopTest();
    }

    private static void insertTestTimeEntries(){
        Replicon_Time_Entry__c testEntry1 = new Replicon_Time_Entry__c();
        testEntry1.EntryDate__c = Date.today().addDays(-7);
        testEntry1.Cognizant_Employee_Id__c = '123456';
        testEntry1.Peoplesoft_Project_Id__c = '12345678';
        testEntry1.TotalHrs__c = 8;
        testEntry1.ActivityName__c = 'Business Support';
        testEntry1.Billing_Action__c = 'B';
        testEntry1.Type__c = 'Project';
        
        Replicon_Time_Entry__c testEntry2 = new Replicon_Time_Entry__c();
        testEntry2.EntryDate__c = Date.today().addDays(-8);
        testEntry2.Cognizant_Employee_Id__c = '123456';
        testEntry2.Peoplesoft_Project_Id__c = '12345678';
        testEntry2.TotalHrs__c = 7;
        testEntry2.ActivityName__c = 'Business Support';
        testEntry2.Billing_Action__c = 'B';
        testEntry2.Type__c = 'Project';

        Replicon_Time_Entry__c testEntry3 = new Replicon_Time_Entry__c();
        testEntry3.EntryDate__c = Date.today().addDays(-10);
        testEntry3.Cognizant_Employee_Id__c = '654321';
        testEntry3.Peoplesoft_Project_Id__c = '12345678';
        testEntry3.TotalHrs__c = 6;
        testEntry3.ActivityName__c = 'Business Support';
        testEntry3.Billing_Action__c = 'B';
        testEntry3.Type__c = 'Project';

        List<Replicon_Time_Entry__c> timeEntryInsertList = new List<Replicon_Time_Entry__c>{testEntry1, testEntry2, testEntry3};
        insert timeEntryInsertList;
    }
}