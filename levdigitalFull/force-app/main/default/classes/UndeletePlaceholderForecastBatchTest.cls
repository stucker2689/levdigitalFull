/**
 * Created by Sam Tucker 2/25/2022
 * Test Class for UndeletePlaceholderForecastBatch and UndeletePlaceholderForecastScheduler
 */

@isTest
public with sharing class UndeletePlaceholderForecastBatchTest {

    @testSetup
    static void setupData() {
        Account placeholderAcct = TestDataFactory.createAccount(true, 'Client');

        Opportunity placeholderOppty = TestDataFactory.createOpportunity(false, placeholderAcct.Id, 'Salesforce');
        placeholderOppty.Name = 'Test Lev - Internal Placeholder';
        insert placeholderOppty;

        Project__c placeholderProj = new Project__c();
        placeholderProj.Account__c = placeholderAcct.Id;
        placeholderProj.Opportunity__c = placeholderOppty.Id;
        placeholderProj.Name = 'Test Lev - Internal Placeholder';
        placeholderProj.RepliconUri__c= 'urn:replicon-tenant:levementum:project:26030';
        insert placeholderProj;

        Project__c nonPlaceholderProj = new Project__c();
        nonPlaceholderProj.Account__c = placeholderAcct.Id;
        nonPlaceholderProj.Opportunity__c = placeholderOppty.Id;
        nonPlaceholderProj.Name = 'Test Lev - Non-Internal Placeholder';
        nonPlaceholderProj.RepliconUri__c= 'urn:replicon-tenant:levementum:project:98765';
        insert nonPlaceholderProj;

        List<RepliconForecast__c> allForecastsList = new List<RepliconForecast__c>();
        Date pastWeekEndDate = Date.today().toStartOfWeek().addDays(-1);
        List<RepliconForecast__c> pastPlaceholderForecastList = TestDataFactory.createMultipleForecasts(false, 50, placeholderProj.Id, null, pastWeekEndDate, true);
        List<RepliconForecast__c> futurePlaceholderForecastsList = TestDataFactory.createMultipleForecasts(false, 50, placeholderProj.Id, null, null, true);
        List<RepliconForecast__c> futureNonPlaceholderForecastsList = TestDataFactory.createMultipleForecasts(false, 50, placeholderProj.Id, null, null, true);
        List<RepliconForecast__c> nonDeletedForecastsList = TestDataFactory.createMultipleForecasts(false, 50, nonPlaceholderProj.Id, null, null, false);
        allForecastsList.addAll(pastPlaceholderForecastList);
        allForecastsList.addAll(futurePlaceholderForecastsList);
        allForecastsList.addAll(futureNonPlaceholderForecastsList);
        allForecastsList.addAll(nonDeletedForecastsList);
        insert allForecastsList;

    }

    @isTest
    static void getUndeletePlaceholderForecastBatchTest() {
        String cronExpr = '0 0 0 15 3 ? 2022';
        Test.startTest();
        UndeletePlaceholderForecastsScheduler newTestScheduler = new UndeletePlaceholderForecastsScheduler();
        String jobId = System.schedule('UndeletePlaceholderForecastsScheduler Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getDeleteBatchTest(){
        Integer sizeOfPlaceholdersMarkedAsDeletedInitially;
        Integer sizeOfPlaceholdersMarkedAsDeletedAfterRun;
        List<RepliconForecast__c> allDeletedPlaceholderForecasts = new List<RepliconForecast__c>();
        allDeletedPlaceholderForecasts = [SELECT Id, Project__c, Project__r.Name, Week_End_Date__c, Deleted_in_Replicon__c
                                            FROM RepliconForecast__c
                                            WHERE Project__r.Name = 'Test Lev - Internal Placeholder' AND Deleted_in_Replicon__c = true AND Week_End_Date__c >= TODAY];
        sizeOfPlaceholdersMarkedAsDeletedInitially = allDeletedPlaceholderForecasts.size();
        Date testDate = Date.valueOf('2021-05-05');
        Test.startTest();
        UndeletePlaceholderForecastsBatch newUndeleteBatch = new UndeletePlaceholderForecastsBatch();
        Database.executeBatch(newUndeleteBatch, 200);
        Test.stopTest();

        List<RepliconForecast__c> allDeletedPlaceholderForecastsAfter = new List<RepliconForecast__c>();
        allDeletedPlaceholderForecastsAfter = [SELECT Id, Project__c, Project__r.Name, Week_End_Date__c, Deleted_in_Replicon__c
                                                FROM RepliconForecast__c
                                                WHERE Project__r.Name = 'Test Lev - Internal Placeholder' AND Deleted_in_Replicon__c = true AND Week_End_Date__c >= TODAY];
        sizeOfPlaceholdersMarkedAsDeletedAfterRun = allDeletedPlaceholderForecastsAfter.size();

        System.assertNotEquals(sizeOfPlaceholdersMarkedAsDeletedAfterRun, sizeOfPlaceholdersMarkedAsDeletedInitially, 'No Placeholder Forecasts have been marked as deleted after the Undelete Batch Run');


    }

}