/**
 * Created 7/7/2022 ST
 * 
 * Purpose: To test the functionality of Risk Report Trigger and Handler Logic
 */

@isTest
public with sharing class RiskReportTrigger_Test {
    
    @TestSetup
    static void makeData(){       

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';

        Account testAccount = TestDataFactory.createAccount(false, 'Client');
        testAccount.Name = 'Test Risk Report Account';

        List<Account> accountInsertList = new List<Account>{levementumLLCAcct, testAccount};
        insert accountInsertList;

        //Create Contact
        Contact testLevEmployee = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee'
    }

    @isTest
    static void testNextStepsLogLogicOnInsert(){

        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Risk Report Account' LIMIT 1];
        
        //Create Risk Report Record
        Risk_Report__c testRiskReport = new Risk_Report__c(Account__c = testAccount.Id, At_Risk_Headline__c = 'Test', Products__c = 'Audience Builder', Primary_Risk_Reason__c = 'Deliverable Quality',
                                                             At_Risk_Details__c = 'Test', Risk_Status__c = 'Yellow', Next_Steps__c = 'Test Next Steps');
        insert testRiskReport;

        Risk_Report__c assertRiskReport = [SELECT Id, Name, Next_Steps__c, Next_Steps_Log__c, DateNextStepsLastUpdated__c FROM Risk_Report__c WHERE Account__c =: testAccount.Id];
        System.assertNotEquals(null, assertRiskReport.Next_Steps_Log__c, 'Risk Report Next Steps Log was not properly Updated after insert of Risk Report with Next Steps field populated');
        System.assertNotEquals(null, assertRiskReport.DateNextStepsLastUpdated__c, 'Date Next Steps Last Updated was not properly populated after Next Steps field was created with the Next Steps populated');

    }

    @isTest
    static void testNextStepsLogLogicOnUpdate(){
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Risk Report Account' LIMIT 1];
        
        //Create Risk Report Record
        Risk_Report__c testRiskReport = new Risk_Report__c(Account__c = testAccount.Id, At_Risk_Headline__c = 'Test', Products__c = 'Audience Builder', Primary_Risk_Reason__c = 'Deliverable Quality',
                                                             At_Risk_Details__c = 'Test', Risk_Status__c = 'Yellow');
        insert testRiskReport;

        Risk_Report__c updateRiskReport = [SELECT Id, Name, Next_Steps__c, Next_Steps_Log__c FROM Risk_Report__c WHERE Account__c =: testAccount.Id];
        updateRiskReport.Next_Steps__c = 'Test Next Steps Update';
        update updateRiskReport;

        Risk_Report__c assertRiskReport = [SELECT Id, Name, Next_Steps__c, Next_Steps_Log__c, DateNextStepsLastUpdated__c FROM Risk_Report__c WHERE Account__c =: testAccount.Id];
        System.assertNotEquals(null, assertRiskReport.Next_Steps_Log__c, 'Risk Report Next Steps Log was not properly Updated after update of Risk Report with Next Steps field populated');
        System.assertNotEquals(null, assertRiskReport.DateNextStepsLastUpdated__c, 'Date Next Steps Last Updated was not properly populated after Next Steps field was updated');

    }
}