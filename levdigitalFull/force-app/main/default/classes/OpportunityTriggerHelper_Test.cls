/**
 * Created 6/10/2022 ST
 * 
 * Purpose: To test the functionality of OpportunityTriggerHelper
 */

@isTest
public with sharing class OpportunityTriggerHelper_Test {


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
        testOppty1.PeopleSoft_Project_ID__c = '12345678';

        Opportunity testOppty2 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        testOppty2.Name = 'Test Project Role Oppty 2';
        testOppty2.Do_Not_Create_Project__c = false;

        List<Opportunity> testOpportunitiesList = new List<Opportunity>{testOppty1};
        insert testOpportunitiesList;

        //Create Products, Price Book Entries, Opportunity Line Items
        Product2 developerProduct = new Product2(Name = 'Developer');
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

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'ATG');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - UK'); 
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Move Opportunities to Closed Won to have Projects and Project Roles created
        testOppty1.StageName = 'Closed Won';
        //testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1};
        //update testUpdateOpptiesToClosedWonList; 
    }

    @isTest
    static void testKickOffPlaceHolderForecastsCreated(){
        //test that the Placeholder Forecasts are created (and for the right hours/amounts)
        Test.startTest();

        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;

        List<RepliconForecast__c> kickoffForecastList = new List<RepliconForecast__c>();
        kickoffForecastList = [SELECT Id, Name, Project__c, Project__r.Name, Week_Start_Date__c, Week_End_Date__c, EstimatedHours__c, EstimatedRevenue__c, Kickoff_Placeholder_Forecast__c,
                                    ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c
                                FROM RepliconForecast__c
                                WHERE Project__r.Name = 'Test Project Role Oppty 1'
                                ORDER BY Week_End_Date__c ASC];
                                

        for(RepliconForecast__c forecast : kickoffForecastList){
            System.debug('Forecast: ' + forecast);
            System.assertEquals(true, forecast.Kickoff_Placeholder_Forecast__c, 'Placeholder Forecasts were not properly created');
        }
        Test.stopTest();

        System.assertEquals(8, kickoffForecastList.size(), 'The incorrect number of KickOff Placeholder Forecasts were created when a Opportunity goes closed won.');

    }

    @isTest
    static void testKickOffPlaceholderForecastsDeletion(){
        //Test that the Kickoff Placeholders are deleted once a real (non-kickoff) placeholder gets inserted for the related Project
        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;

        Project__c testProj = [SELECT Id, Name, Opportunity__c FROM Project__c WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        Id testProjId = testProj.Id;
        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 150, Project__c = testProj.Id);
        insert devBillRate;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c testForecast = new RepliconForecast__c(Name = 'Test Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(14), Week_End_Date__c = currentWeekStartDate.addDays(20), ProjectTeamMemberBillingRate__c = devBillRate.Id, EstimatedHours__c = 10, Project__c = testProj.Id);
        
        
        insert testForecast;
        Test.stopTest();

        List<RepliconForecast__c> kickoffForecastList = new List<RepliconForecast__c>();
        kickoffForecastList = [SELECT Id, Name, Project__c, Project__r.Name, EstimatedHours__c, EstimatedRevenue__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c
                                FROM RepliconForecast__c
                                WHERE Project__c =: testProjId AND Kickoff_Placeholder_Forecast__c = true
                                ORDER BY EstimatedHours__c ASC];

        System.assertEquals(0, kickoffForecastList.size(), 'The Kickoff Placeholders were not properly deleted when the project gets an actual forecast created');


    }

    @isTest
    static void testCWOpptyCloseDateChange(){
        //Test that the Kickoff Placeholders change Dates when the related Opportunity Close Date changes, but the Oppty stays CW
        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, CloseDate, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;

        //Opportunity testOppty = [SELECT Id, Name, CloseDate, StageName FROM Opportunity WHERE Name =  'Test Project Role Oppty 1' LIMIT 1];
        testOppty.CloseDate = Date.today().addDays(7);

        
        update testOppty;
        Test.stopTest();

        List<RepliconForecast__c> kickoffForecastList = new List<RepliconForecast__c>();
        kickoffForecastList = [SELECT Id, Name, Project__c, Project__r.Name, Week_Start_Date__c, Week_End_Date__c, EstimatedHours__c, EstimatedRevenue__c, 
                                    ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c
                                FROM RepliconForecast__c
                                WHERE Project__r.Name = 'Test Project Role Oppty 1'
                                ORDER BY Week_End_Date__c ASC];

        Date thirtySevenDaysAfterTodayWeekStartDate = Date.today().addDays(37).toStartOfWeek();
        Date firstKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate;
        Date secondKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(7);
        Date thirdKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(14);
        Date fourthKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(21);
        Date fifthKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(28);
        Date sixthKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(35);
        Date seventhKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(42);
        Date eigthKickoffExpectedWeekStartDate = thirtySevenDaysAfterTodayWeekStartDate.addDays(49);

        System.assertEquals(firstKickoffExpectedWeekStartDate, kickoffForecastList[0].Week_Start_Date__c, 'The First Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(secondKickoffExpectedWeekStartDate, kickoffForecastList[1].Week_Start_Date__c, 'The Second Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(thirdKickoffExpectedWeekStartDate, kickoffForecastList[2].Week_Start_Date__c, 'The Third Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(fourthKickoffExpectedWeekStartDate, kickoffForecastList[3].Week_Start_Date__c, 'The Fourth Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(fifthKickoffExpectedWeekStartDate, kickoffForecastList[4].Week_Start_Date__c, 'The Fifth Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(sixthKickoffExpectedWeekStartDate, kickoffForecastList[5].Week_Start_Date__c, 'The Sixth Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(seventhKickoffExpectedWeekStartDate, kickoffForecastList[6].Week_Start_Date__c, 'The Seventh Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        System.assertEquals(eigthKickoffExpectedWeekStartDate, kickoffForecastList[7].Week_Start_Date__c, 'The Eighth Kickoff Placeholder Forecast did not adjust properly after Close Date of Opportunity was changed.');
        
    }

    @isTest
    static void testChangeESAProjectId(){
        System.debug('test Change ESA Project Id');
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        //Test when changing ESA Project Id that is cascades and updates all related Time Entries
        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName, Peoplesoft_Project_Id__c FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c(EntryDate__c = Date.today(), TotalHrs__c = 8, Peoplesoft_Project_Id__c = '12345678');
        insert newEntry;
        System.debug('2.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());

        testOppty.Peoplesoft_Project_Id__c = '87654321';
        update testOppty;
        System.debug('3.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        Test.stopTest();

        List<Replicon_Time_Entry__c> assertEntryList = new List<Replicon_Time_Entry__c>();
        assertEntryList = [SELECT Id, Name, Peoplesoft_Project_Id__c, Opportunity__c FROM Replicon_Time_Entry__c];

        for(Replicon_Time_Entry__c entry : assertEntryList){
            System.assertEquals('87654321', entry.Peoplesoft_Project_Id__c, 'Time Entries did not properly have their ESA Project Id updated after it was updated on the related Opportunity');
        }


    }

    @isTest
    static void testInvoiceTotalsUpdate(){
        //Create Products, Price Book Entries, Opportunity Line Items
        Opportunity testOppty = [SELECT Id, Name, CloseDate, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, StageName, CSP_Email__c, Managing_Director_SC_Email__c, Anticipated_Project_Start_Date__c FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        testOppty.Total_Hours_Invoiced_to_Date__c = 10;
        testOppty.Total_Amount_Invoiced_to_Date__c = 1000;
        testOppty.CSP_Email__c = 'testemail@gmail.com';
        testOppty.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        Test.startTest();
        update testOppty;
        Test.stopTest();

        Project__c testProj = [SELECT Id, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, Opportunity__c FROM Project__c WHERE Opportunity__c = :testOppty.Id LIMIT 1];

        System.assertEquals(10, testProj.Total_Hours_Invoiced_to_Date__c, 'Total Invoiced Hours on Project did not rollup correctly after it was updated on the related Opportunity.');
        System.assertEquals(1000, testProj.Total_Amount_Invoiced_to_Date__c, 'Total Invoiced Amount on Project did not rollup correctly after it was updated on the related Opportunity.');
    }

    @isTest
    static void lowRateOpptyProductEmailAlert_Test(){

        Opportunity testOppty = [SELECT Id, Name, CloseDate, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, StageName, CSP_Email__c, Managing_Director_SC_Email__c, Anticipated_Project_Start_Date__c 
                                FROM Opportunity 
                                WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];

        //Create Products, Price Book Entries, Opportunity Line Items
        Product2 platformArchitectProduct = new Product2(Name = 'Platform Architect');
        Product2 marConProduct = new Product2(Name = 'Marketing Consultant');
        List<Product2> testProductsList = new List<Product2>{platformArchitectProduct, marConProduct};
        insert testProductsList;

        PricebookEntry platformArchitectBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = platformArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry marConPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = marConProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        List<PricebookEntry> testPriceBookEntryList = new List<PricebookEntry>{platformArchitectBookEntry, marConPriceBookEntry};
        insert testPriceBookEntryList;

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = platformArchitectBookEntry.Id, Quantity = 10, UnitPrice = 75, Resource_Delivery_Group__c = 'Lev - NA');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = marConPriceBookEntry.Id, Quantity = 15, UnitPrice = 60, Resource_Delivery_Group__c = 'Lev - NA');
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;


        Test.startTest();
        testOppty.StageName = 'Closed Won';
        update testOppty;
        Test.stopTest();

    }

    @isTest
    static void populateSOWNumberOnOppty_Test(){
        List<Opportunity> testOpptyList = [SELECT Id, Name, StageName, SOW_Number__c, Unique_SOW_Number__c, CO_Number__c, AccountId FROM Opportunity];
        Test.startTest();
        OpportunityTriggerHelper.populateSOWorCONumberOnOppty(testOpptyList, null);
        Test.stopTest();
    }
    
}