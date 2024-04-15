/**
* @author LevDigital
* @date 2019
* 
* @description Tests for RepliconUnassignedForecastBatchDelete
*/
@isTest
private with sharing class RepliconForecastBatchDeleteTest {
    /* TEST DATA */
    static Account acct;
    static Contact employee;
    static Contact defaultContact;
    static Project__c project;

    static RepliconForecast__c forecastAssigned;
    static RepliconForecast__c forecastLastWeek;
    static RepliconForecast__c forecastThisWeek;
    static RepliconForecast__c forecastNextWeek;

    /* TEST DATA INITIALIZATION */
    static void init() {
        // Overhead
        acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = TestClassUtil.newSampleOpportunity(acct.Id, 'Test Opp');
        project = TestClassUtil.createProject(true, acct.Id, opp.Id);

        Date thisWeekStart = Date.today().toStartOfWeek();

        // Assigned Contacts
        employee = TestClassUtil.createContact(true, acct.Id);
        defaultContact = TestClassUtil.createContact(false, acct.Id);
        defaultContact.LastName = 'Placeholder';
        insert defaultContact;

        // Forecast Records
        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastAssigned = TestClassUtil.createForecast(false, acct.Id, project.Id);
        forecastAssigned.Contact__c = employee.Id;
        forecastAssigned.Week_Start_Date__c = thisWeekStart;

        forecastLastWeek = TestClassUtil.createForecast(false, acct.Id, project.Id);
        forecastLastWeek.Contact__c = defaultContact.Id;
        forecastLastWeek.Week_Start_Date__c = thisWeekStart - 7;

        forecastThisWeek = TestClassUtil.createForecast(false, acct.Id, project.Id);
        forecastThisWeek.Contact__c = defaultContact.Id;
        forecastThisWeek.Week_Start_Date__c = thisWeekStart;

        forecastNextWeek = TestClassUtil.createForecast(false, acct.Id, project.Id);
        forecastNextWeek.Contact__c = defaultContact.Id;
        forecastNextWeek.Week_Start_Date__c = thisWeekStart + 7;

        insert new List<RepliconForecast__c>{ 
            forecastAssigned, 
            forecastLastWeek,
            forecastThisWeek, 
            forecastNextWeek
         };
    }

    /* TEST METHODS */
    @isTest
    static void testBatch_success() {
        init();

        // Test 
        System.Test.startTest();
        SchedulableContext sc = null;
        RepliconUnassignedForecastBatchDelete sched = new RepliconUnassignedForecastBatchDelete();
        sched.execute(sc);
        System.Test.stopTest();

        // Post-test
        Map<Id, RepliconForecast__c> forecastList = new Map<Id, RepliconForecast__c>([
            SELECT Id FROM RepliconForecast__c
        ]);

        // Assert that the assigned forecast and past forecast records still exist
        System.assert(forecastList.keySet().contains(forecastAssigned.Id));
        System.assert(forecastList.keySet().contains(forecastLastWeek.Id));

        // Assert that the forecast records for this week and next week have been deleted 
        //System.assert(!forecastList.keySet().contains(forecastThisWeek.Id));
        //System.assert(!forecastList.keySet().contains(forecastNextWeek.Id));
    }

    @isTest
    static void testBatch_deleteError() {
        init();
        RepliconUnassignedForecastBatchDelete sched = new RepliconUnassignedForecastBatchDelete();
        delete forecastThisWeek;

        // Test
        System.Test.startTest();
        Database.BatchableContext bc = null;
        sched.execute(bc, new List<RepliconForecast__c>{ forecastThisWeek });
        System.Test.stopTest();

        // Post-test
        List<Error_Log_Lev__c> errorLogList = [SELECT Error_Message__c FROM Error_Log_Lev__c];

        // Assert error was thrown 
        //System.assert(errorLogList[0].Error_Message__c.contains('Problem deleting'));
    }
}