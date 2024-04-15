@isTest
public with sharing class MilestoneTriggerTest {

    private static String campaignMilestoneRT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
    
    @TestSetup
    static void testSetup(){

        Account testAccount = TestDataFactory.createAccount(false, 'Client');
        testAccount.Name = 'Test Account';
        insert testAccount;

        Opportunity testOppty = TestDataFactory.createOpportunity(true, testAccount.Id, 'Salesforce');
        
        Project__c testProj = TestDataFactory.createProject(false, testAccount.Id, testOppty.Id);
        testProj.Name = 'Test Project';
        insert testProj;
        
        Milestone__c testMilestone = TestDataFactory.createMilestone(false, testProj.Id);
        testMilestone.Name = 'Test Milestone';
        insert testMilestone; 

        Work__c testWork1 = TestDataFactory.createWork(false, testMilestone.Id, 'Test Milestone Test Work Assignment #1');
        Work__c testWork2 = TestDataFactory.createWork(false, testMilestone.Id, 'Test Milestone Test Work Assignment #2');
        Work__c testWork3 = TestDataFactory.createWork(false, null, 'Test Milestone Test Work Assignment #3');
        List<Work__c> workInsertList = new List<Work__c>{testWork1, testWork2, testWork3};
        insert workInsertList;

    }


    @isTest
    static void testRelatedWorkDeletion(){

        Milestone__c milestoneToDelete = [SELECT Id, Name FROM Milestone__c WHERE Name = 'Test Milestone' LIMIT 1];

        List<Work__c> workBeforeDeleteList = new List<Work__c>();
        workBeforeDeleteList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c =: milestoneToDelete.Id];

        System.assertEquals(2, workBeforeDeleteList.size(), 'Wrong amount of Work Records associated with Test Milestone.');

        Test.startTest();
        delete milestoneToDelete;
        Test.stopTest();

        List<Work__c> workAfterDeleteList = new List<Work__c>();
        workAfterDeleteList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c =: milestoneToDelete.Id];

        System.assertEquals(0, workAfterDeleteList.size(), 'Related Work Records were not properly deleted.');

    }

    @isTest
    static void testMilestoneNameChangeReflectedOnRelatedWork(){
    /** 
     * Functionality: Test the functionality that when a Milestone Name is changed, it cascades to replace the old name with the new name on any related Work Records.
     */
        Milestone__c milestoneBeforeNameChange = [SELECT Id, Name FROM Milestone__c WHERE Name = 'Test Milestone' LIMIT 1];

        List<Work__c> workBeforeNameChangeList = new List<Work__c>();
        workBeforeNameChangeList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c =: milestoneBeforeNameChange.Id];

        for(Work__c w : workBeforeNameChangeList){
            System.assertEquals(true, w.Name.contains('Test Milestone'));
            System.assertEquals(false, w.Name.contains('New Name For Milestone'));
            if(w.Name.contains('#1')){
                System.assertEquals('Test Milestone Test Work Assignment #1', w.Name, 'Work Name #1 does not match what it was inserted as.');
            }else if(w.Name.contains('#2')){
                System.assertEquals('Test Milestone Test Work Assignment #2', w.Name, 'Work Name #2 does not match what it was inserted as.');
            }else{
                //Shouldn't get here since there are only 2 Work records created for the Milestone and 
            }
        }

        Test.startTest();
        milestoneBeforeNameChange.Name = 'New Name For Milestone';
        update milestoneBeforeNameChange;
        Test.stopTest();

        List<Work__c> workAfterNameChangeList = new List<Work__c>();
        workAfterNameChangeList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c =: milestoneBeforeNameChange.Id];

        for(Work__c w : workAfterNameChangeList){
            System.assertEquals(true, w.Name.contains('New Name For Milestone'));
            System.assertEquals(false, w.Name.contains('Test Milestone'));
            if(w.Name.contains('#1')){
                System.assertEquals('New Name For Milestone Test Work Assignment #1', w.Name, 'Work Name #1 was not properly updated with the new Milestone Name.');
            }else if(w.Name.contains('#2')){
                System.assertEquals('New Name For Milestone Test Work Assignment #2', w.Name, 'Work Name #2 was not properly updated with the new Milestone Name.');
            }else{
                //Shouldn't get here since there are only 2 Work records created for the Milestone and 
            }
        }
    }

}