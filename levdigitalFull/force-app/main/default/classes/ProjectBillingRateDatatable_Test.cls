@isTest(seeAllData=true)
public with sharing class ProjectBillingRateDatatable_Test {
    

    /*@TestSetup
    static void makeData(){
        
    }*/

    @isTest
    static void testing_Test(){

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Project_Status__c = 'Active' AND Rollup_Billable__c > 100 ORDER BY Rollup_Billable__c DESC LIMIT 1];
        String projId = (String)testProj.Id;

        List<ProjectBillingRateDatatableController.BillingRateWrapper> wrapperList = new List<ProjectBillingRateDatatableController.BillingRateWrapper>();
        wrapperList = ProjectBillingRateDatatableController.getBillingRateTableData(projId);
    }

    @isTest
    static void getNewBillingRateOptions_Test(){

        List<Product2> productList = ProjectBillingRateDatatableController.getNewBillingRateOptions();
    }

    @isTest
    static void createNewBillingRate_Test(){

        List<Product2> productsList = new List<Product2>();
            productsList = [SELECT Id, Name, IsActive
                            FROM Product2
                            WHERE IsActive = true AND (NOT Name LIKE '%Margin User%') 
                            ORDER BY Name];
        String productId = productsList[0].Id;

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Project_Status__c = 'Active' AND Rollup_Billable__c > 100 ORDER BY Rollup_Billable__c DESC LIMIT 1];
        String projId = (String)testProj.Id;
        ProjectBillingRateDatatableController.getBillingRateTableData(projId);

        Project_Team_Member_Billing_Rate__c newBillRate = ProjectBillingRateDatatableController.createNewBillingRate(projId, projId, 'Developer', 195.00);

    }
}