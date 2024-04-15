@isTest(seeAllData=true)
public with sharing class CreateBillRatesOnExistingProjBatch_Test {
    @isTest
    static void createBillRates_Test(){
        CreateBillRatesOnExistingProjectsBatch createBillRatesBatch= new CreateBillRatesOnExistingProjectsBatch();
        Database.executeBatch(createBillRatesBatch, 300); 
    }

    @isTest
    static void createBillRatesForSpecificProjectList_Test(){

        List<Project__c> projList = [SELECT Id, Name FROM Project__c WHERE Project_Status__c = 'Active' LIMIT 3];

        CreateBillRatesOnExistingProjectsBatch createBillRatesBatch= new CreateBillRatesOnExistingProjectsBatch(projList);
        Database.executeBatch(createBillRatesBatch, 300); 
    }
}