@IsTest
public with sharing class RepliconTimeEntryBatchTest {

    @testSetup
    static void setupData() {
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        newAccount.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        newAccount.MSA_Number__c = 'MSA_Test01';
        insert newAccount;
		
        Account newCompanyAccount = new Account();
        newCompanyAccount.Name = 'Levementum LLC';
        insert newCompanyAccount;
        
        Contact employee1 = new Contact();
        employee1.FirstName = 'Test2';
        employee1.LastName = 'Employee100';
        employee1.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee1.Email = 'temployee100@levdigital.com';
        employee1.Replicon_User_Number__c = 1;
        employee1.RepliconLoginName__c = 'temployee1';
        insert employee1;

    }
    @isTest
    static void getTimeEntryContinuedBatch(){

    List<Contact> testContacts = new List<Contact>();
    testContacts = [SELECT Id, Name, Replicon_User_Number__c FROM Contact WHERE LastName = 'Employee100' LIMIT 1];


    String cronExpr1 = '0 0 0 15 5 ? 2024';
    Test.startTest();
    RepliconTimeEntryBatchScheduler newContinuedTestScheduler = new RepliconTimeEntryBatchScheduler(testContacts, 5, 1);
    String jobId = System.schedule('RepliconTimeEntryBatchScheduler', cronExpr1, newContinuedTestScheduler);
    newContinuedTestScheduler.execute(null);
    Test.stopTest();
    }

    @isTest
    static void getTimeEntryBatchTest() {
        String cronExpr2 = '0 0 0 15 5 ? 2024';
        Test.startTest();
        RepliconTimeEntryBatchScheduler newTestScheduler = new RepliconTimeEntryBatchScheduler(1);
        String jobId = System.schedule('RepliconTimeEntryBatchScheduler', cronExpr2, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getBatchTest(){
        Date testDate = Date.valueOf('2022-12-31');
        Test.startTest();
        RepliconTimeEntryBatch newTimeEntryTestBatch = new RepliconTimeEntryBatch(System.Today(), 5, 1);
        Database.executeBatch(newTimeEntryTestBatch, 10);
        Test.stopTest();


    }

    //Added 5/4/2022 to test PTO Batch
    @isTest
    static void getPTOContinuedBatch(){

    List<Contact> testContacts = new List<Contact>();
    testContacts = [SELECT Id, Name, Replicon_User_Number__c FROM Contact WHERE LastName = 'Employee100' LIMIT 1];


    String cronExpr1 = '0 0 0 31 12 ? 2024';
    Test.startTest();
    RepliconPTOBatchScheduler newContinuedTestPTOScheduler = new RepliconPTOBatchScheduler(testContacts, -5, -1);
    String jobId = System.schedule('RepliconPTOBatchScheduler', cronExpr1, newContinuedTestPTOScheduler);
    newContinuedTestPTOScheduler.execute(null);
    Test.stopTest();
    }

    @isTest
    static void getPTOBatchSchedulerTest() {
        String cronExpr2 = '0 0 0 31 12 ? 2024';
        Test.startTest();
        RepliconPTOBatchScheduler newTestPTOScheduler = new RepliconPTOBatchScheduler(-1);
        String jobId = System.schedule('RepliconPTOBatchScheduler', cronExpr2, newTestPTOScheduler);
        newTestPTOScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getPTOBatchTest(){
        Date testDate = Date.valueOf('2022-12-31');
        Test.startTest();
        RepliconPTOBatch newPTOBatch = new RepliconPTOBatch(System.Today(), -5, -1);
        Database.executeBatch(newPTOBatch, 10);
        Test.stopTest();


    }
}