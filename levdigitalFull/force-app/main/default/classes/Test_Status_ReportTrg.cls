/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_Status_ReportTrg {

    static testMethod void myUnitTest() {
        
        Account acc = new Account();
        acc.Name = 'testAccount';
        acc.PrimaryPractice__c = 'Salesforce';
        insert acc;
        
        Opportunity oppo = new Opportunity();
        oppo.Name = 'Test';
        oppo.AccountId = acc.Id;
        oppo.StageName = 'Closed Won';
        oppo.CloseDate = date.today();
        oppo.Interested_In__c = 'Salesforce';
        oppo.Lead_Source__c = 'Levementum';
        oppo.Project_Health__c = 'Green';
        oppo.Payment_Terms__c ='Special';
        insert oppo;
        
        Status_Report__c statusReport = new Status_Report__c();
        //RecordType rt = [select id,Name from RecordType where SobjectType='Status_Report__c' and Name='Old_Do_Not_Use' Limit 1];
        statusReport.Account__c = acc.Id;
        statusReport.Opportunity__c = oppo.Id;
        statusReport.Name = 'TestStatusReport';
        statusReport.Period_Ending__c = date.today();
        statusReport.Go_Live_Date__c = date.today();
        statusReport.A_R_Status__c = 'Current';
        statusReport.Budget_Risk__c = 'High';
        statusReport.Timeline_Risk__c = 'High';
        statusReport.Scope_Risk__c = 'High';
        //statusReport.RecordTypeId = rt.id; 
        statusReport.Budget_Comments__c = 'Test';
        statusReport.Overall_Health_Comments__c = 'Test';
        statusReport.Risk_Comments__c = 'Test';
        statusReport.Schedule_Comments__c = 'Test';
        statusReport.Scope_Comments__c= 'Test';
        statusReport.Reporting_Period_Ending__c= date.today();
        insert statusReport;
        
        //When statusReport.A_R_Status__c, statusReport.Budget_Risk__c, or statusReport.Scope_Risk__c are High, then the opportunity Project_Health__c should be Red
        //Opportunity op = [SELECT Id,Project_Health__c FROM Opportunity WHERE Id = :oppo.Id];
        //system.assertEquals('Red',op.Project_Health__c);
        
        statusReport.Budget_Risk__c = 'Medium';
        statusReport.Timeline_Risk__c = 'Medium';
        statusReport.Scope_Risk__c = 'Medium';
        statusReport.Budget_Comments__c = 'Test';
        statusReport.Overall_Health_Comments__c = 'Test';
        statusReport.Risk_Comments__c = 'Test';
        statusReport.Schedule_Comments__c = 'Test';
        statusReport.Scope_Comments__c= 'Test';
        statusReport.Reporting_Period_Ending__c= date.today();
        update statusReport;
        
        //When statusReport.A_R_Status__c, statusReport.Budget_Risk__c, or statusReport.Scope_Risk__c are Medium, then the opportunity Project_Health__c should be Yellow
        //Opportunity op2 = [SELECT Id,Project_Health__c FROM Opportunity WHERE Id = :oppo.Id];
        //system.assertEquals('Yellow',op2.Project_Health__c);
        
        statusReport.Budget_Risk__c = 'Low';
        statusReport.Timeline_Risk__c = 'Low';
        statusReport.Scope_Risk__c = 'Low';
        statusReport.Budget_Comments__c = 'Test';
        statusReport.Overall_Health_Comments__c = 'Test';
        statusReport.Risk_Comments__c = 'Test';
        statusReport.Schedule_Comments__c = 'Test';
        statusReport.Scope_Comments__c= 'Test';
        statusReport.Reporting_Period_Ending__c= date.today();
        update statusReport;
        
        //When statusReport.A_R_Status__c, statusReport.Budget_Risk__c, or statusReport.Scope_Risk__c are Low, then the opportunity Project_Health__c should be Green
        //Opportunity op3 = [SELECT Id,Project_Health__c FROM Opportunity WHERE Id = :oppo.Id];
        //system.assertEquals('Green',op3.Project_Health__c);
    }
}