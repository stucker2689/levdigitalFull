@isTest
public with sharing class WorkTrigger_Test {

    @TestVisible private static String campaignMilestoneRT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
    @TestVisible private static String assignmentWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Assignment').getRecordTypeId();
    @TestVisible private static String emailDevEmailQAWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Email Dev/Email QA').getRecordTypeId();
    @TestVisible private static String emergingServicesWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Emerging Services').getRecordTypeId();
    @TestVisible private static String projectTaskWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Project Task').getRecordTypeId();
    
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
        oppo.Name = 'Work Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Work Test Oppty' LIMIT 1];
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

        Milestone__c testMilestone = TestDataFactory.createMilestone(false, testProj.Id);
        testMilestone.Name = 'Test Milestone';
        insert testMilestone; 

        Work__c testWork1 = new Work__c(RecordTypeId = assignmentWorkRT, Name = 'Test Work Assignment #1', dat_DueDate__c = date.today().addDays(14), pkl_Status__c = 'New', Milestone__c = testMilestone.Id, Order__c = 1);
        Work__c testWork2 = new Work__c(RecordTypeId = assignmentWorkRT, Name = 'Test Work Assignment #2', dat_DueDate__c = date.today().addDays(14), pkl_Status__c = 'New', Milestone__c = testMilestone.Id, Order__c = 2);
        Work__c testWork3 = new Work__c(RecordTypeId = assignmentWorkRT, Name = 'Test Work Assignment #3', dat_DueDate__c = date.today().addDays(14), pkl_Status__c = 'New', Milestone__c = testMilestone.Id, Order__c = 3);
        Work__c testWork4 = new Work__c(RecordTypeId = assignmentWorkRT, Name = 'Test Work Assignment #4', dat_DueDate__c = date.today().addDays(14), pkl_Status__c = 'New', Milestone__c = testMilestone.Id, Order__c = 4);
        List<Work__c> workInsertList = new List<Work__c>{testWork1, testWork2, testWork3, testWork4};
        insert workInsertList;

    }

    @isTest
    static void validateUniqueOrderOnWorkAssignment_onWorkInsert_Test(){

        Milestone__c testMilestone = [SELECT Id, Name FROM Milestone__c WHERE Name = 'Test Milestone' LIMIT 1];

        Work__c testWork5 = new Work__c(RecordTypeId = assignmentWorkRT, Name = 'Test Work Assignment #5', dat_DueDate__c = date.today().addDays(14), pkl_Status__c = 'New', Milestone__c = testMilestone.Id, Order__c = 5);

        Test.startTest();
        insert testWork5;
        Test.stopTest();

    }

    @isTest
    static void validateUniqueOrderOnWorkAssignment_onWorkUpdate_Test(){

        Work__c testWork = [SELECT Id, Name, Order__c FROM Work__c WHERE Name = 'Test Work Assignment #2' LIMIT 1];

        Test.startTest();
        testWork.Order__c = 5;
        update testWork;
        Test.stopTest();

    }

    @isTest
    static void reOrderWorkAssignmentOrdersAfterWorkDeletion_Test1(){
        //Test with Work records of Orders 1 - 10, then delete Work Assignment record #4

        Work__c testWork = [SELECT Id, Name, Order__c FROM Work__c WHERE Name = 'Test Work Assignment #2' LIMIT 1];

        Test.startTest();
        delete testWork;
        Test.stopTest();

    }

    /*@isTest
    static void reOrderWorkAssignmentOrdersAfterWorkDeletion_Test2(){
        //Test with Work records of Orders 1 - 10, with an extra 2 work records that have blank order, then delete Work Assignment record #4
        
    }

    @isTest
    static void reOrderWorkAssignmentOrdersAfterWorkDeletion_Test3(){
        //Test with Work records of Orders 1, 2, 4, 5, 7, 8, 12, 16 then delete Work Assignment record #4
        
    }*/
}