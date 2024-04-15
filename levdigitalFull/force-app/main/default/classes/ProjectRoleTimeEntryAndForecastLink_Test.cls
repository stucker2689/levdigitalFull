/**
 * Created 5/18/2022 ST
 * 
 * Purpose: Test ProjectRoleTimeEntryLinkBatch and ProjectRoleForecastLinkBatch
 *          These batch classes also call the functions:
 *              RepliconTimeEntryTriggerHelper.linkTimeEntryToProjectRoleRecord(List<Replicon_Time_Entry__c, Boolean needsUpdate);
 *              RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(List<RepliconForecsat__c>, Boolean needsUpdate);
 *          These functions do the linking of Time Entries or Forecasts to their respective Project Role records
 *
 */

@isTest
public with sharing class ProjectRoleTimeEntryAndForecastLink_Test {
    
    @TestSetup
    static void makeData(){
        //Create Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        insert acct;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        testOppty1.Name = 'Test Project Role Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;

        Opportunity testOppty2 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        testOppty2.Name = 'Test Project Role Oppty 2';
        testOppty2.Do_Not_Create_Project__c = false;

        List<Opportunity> testOpportunitiesList = new List<Opportunity>{testOppty1, testOppty2};
        insert testOpportunitiesList;

        //Move Opportunities to Closed Won to have Projects and Project Roles created
        testOppty1.StageName = 'Closed Won';
        testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1, testOppty2};
        update testUpdateOpptiesToClosedWonList; 

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        Project__c testProj2 = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project Role Oppty 2' LIMIT 1];

        //Create Time Entries
        Project_Team_Member_Billing_Rate__c devBillRate1 = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 150, Project__c = testProj1.Id);
        Project_Team_Member_Billing_Rate__c devBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 150, Project__c = testProj2.Id);
        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>{devBillRate1, devBillRate2};
        insert billRateList;

        Replicon_Time_Entry__c timeEntry1 = new Replicon_Time_Entry__c(Project__c = testProj1.Id, Associated_Billing_Rate__c = devBillRate1.Id, TotalHrs__c = 4 );
        Replicon_Time_Entry__c timeEntry2 = new Replicon_Time_Entry__c(Project__c = testProj2.Id, Associated_Billing_Rate__c = devBillRate2.Id, TotalHrs__c = 4 );
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{timeEntry1, timeEntry2};
        insert entryList;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c pastDevForecast = new RepliconForecast__c(Name = 'Past Dev Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-14), Week_End_Date__c = currentWeekStartDate.addDays(-8), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c pastPMForecast = new RepliconForecast__c(Name = 'Past PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-7), Week_End_Date__c = currentWeekStartDate.addDays(-1), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c futureDevForecast = new RepliconForecast__c(Name = 'Future Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        RepliconForecast__c futurePMForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>{pastDevForecast, pastPMForecast, futureDevForecast, futurePMForecast};
        insert forecastInsertList;

        ProjectRole__c devProjRole1 = new ProjectRole__c(Name = 'Developer', Project__c = testProj1.Id, Rate__c = 150);
        ProjectRole__c devProjRole2 = new ProjectRole__c(Name = 'Developer', Project__c = testProj2.Id, Rate__c = 150);
        List<ProjectRole__c> projRoleList = new List<ProjectRole__c>{devProjRole1, devProjRole2};
        insert projRoleList;

        //Create Products, Price Book Entries, Opportunity Line Items
        /*Product2 developerProduct = new Product2(Name = 'Developer');
        Product2 mcSolutionArchitectProduct = new Product2(Name = 'MC - Solution Architect');
        Product2 projectManagerProduct = new Product2(Name = 'Project Manager');
        Product2 coreTechnicalArchitectProduct = new Product2(Name = 'CORE - Techincal Architect');
        List<Product2> testProductsList = new List<Product2>{developerProduct, mcSolutionArchitectProduct, projectManagerProduct, coreTechnicalArchitectProduct};
        insert testProductsList;

        PricebookEntry developerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = developerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry mcSolutionArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = mcSolutionArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry projectManagerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = projectManagerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry coreTechnicalArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = coreTechnicalArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        List<PricebookEntry> testPriceBookEntryList = new List<PricebookEntry>{developerPriceBookEntry, mcSolutionArchitectPriceBookEntry, projectManagerPriceBookEntry, coreTechnicalArchitectPriceBookEntry};
        insert testPriceBookEntryList;

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100);
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty2.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty2.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250); 
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;*/
        

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' SETUP END');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' SETUP END');   
    }

    @isTest
    static void ProjectRoleLinkFTimeEntriesAll_Test(){
        //Purpose: Test the functionality of ProjectRoleTimeEntryLinkBatch to test that it is properly matching Time Entries to the Project Roles when it is ran for all Time Entries
        ProjectRoleTimeEntryLinkBatch newProjectRoleTimeEntryLinkBatch = new ProjectRoleTimeEntryLinkBatch(true, null);
        Database.executeBatch(newProjectRoleTimeEntryLinkBatch, 100); //Batch size (100) determines how many Time Entries to update at a time
    }

    @isTest
    static void ProjectRoleLinkFTimeEntriesForProjects_Test(){
        //Purpose: Test the functionality of ProjectRoleTimeEntryLinkBatch to test that it is properly matching Time Entries to the Project Roles when it is ran for a specific list of projects
        List<Project__c> projList = [SELECT Id FROM Project__c WHERE Name = 'Test Project Role Oppty 1'];
        List<Id> projIdList = new List<Id>();
        for(Project__c proj : projList){
            projIdList.add(proj.Id);
        }
        ProjectRoleTimeEntryLinkBatch forecastLinkBatch = new ProjectRoleTimeEntryLinkBatch(false, projIdList);
        Database.executeBatch(forecastLinkBatch, 100);
    }


    @isTest
    static void ProjectRoleLinkForecastAll_Test(){
        //Purpose: Test the functionality of ProjectRoleForecastLinkBatch to test that it is properly matching Forecasts to the Project Roles when it is ran for all Forecasts
        ProjectRoleForecastLinkBatch forecastLinkBatch = new ProjectRoleForecastLinkBatch(true, null);
        Database.executeBatch(forecastLinkBatch, 250);
    }

    @isTest
    static void ProjectRoleLinkForecastForProjects_Test(){
        //Purpose: Test the functionality of ProjectRoleForecastLinkBatch to test that it is properly matching Forecasts to the Project Roles when it is ran for a specific list of projects
        List<Project__c> projList = [SELECT Id FROM Project__c WHERE Name = 'Test Project Role Oppty 2'];
        List<Id> projIdList = new List<Id>();
        for(Project__c proj : projList){
            projIdList.add(proj.Id);
        }
        ProjectRoleForecastLinkBatch forecastLinkBatch = new ProjectRoleForecastLinkBatch(false, projIdList);
        Database.executeBatch(forecastLinkBatch, 250);
    }
    
}