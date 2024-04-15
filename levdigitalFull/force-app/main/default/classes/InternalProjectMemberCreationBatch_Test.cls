@isTest
public with sharing class InternalProjectMemberCreationBatch_Test {
    
    @TestSetup
    static void makeData(){
        //Create Accounts
        Account levAcct = TestDataFactory.createAccount(false, 'Partner');
        levAcct.Name = 'Levementum LLC';

        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        
        List<Account> setupAccountInsertList = new List<Account>{acct};
        insert setupAccountInsertList;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        //testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.StageName = 'Identifying an Opportunity';
        testOppty1.Name = 'Test Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;
        testOppty1.Peoplesoft_Project_Id__c = '12345678';
        testOppty1.Expedited_Staffing__c = true;
        insert testOppty1;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Email = 'testEmployeeEmail@gmail.com';
        testEmployee1.Cognizant_Employee_Id__c = '1234';

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.FirstName = 'Place';
        testEmployee2.LastName = 'Holder';

        Contact testEmployee3 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee3.FirstName = 'Test Employee';
        testEmployee3.LastName = 'Number Three';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1, testEmployee2};
        insert setupEmployeeInsertList;

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
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{projectManagerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.CSP_Email__c = 'testemail@gmail.com';
        testOppty1.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        update testOppty1;

    }



    @isTest
    static void testStaffingAssignmentBatchRun(){

        Test.startTest();
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];

        List<Staffing_Assignment__c> staffAssignmentList = new List<Staffing_Assignment__c>();
        staffAssignmentList = [SELECT Id, Name, Status__c, Resource_Assigned__c
                                FROM Staffing_Assignment__c];

        List<Staffing_Assignment__c> staffAssignmentUpdateList = new List<Staffing_Assignment__c>();
        for(Staffing_Assignment__c sa : staffAssignmentList){
            sa.Status__c = 'Completed';
            sa.Resource_Assigned__c= testCon.Id;
            staffAssignmentUpdateList.add(sa);
        }

        update staffAssignmentUpdateList;

        Opportunity oppty = [SELECT Id, Name, StageName FROM Opportunity LIMIT 1];
        oppty.StageName = 'Closed Won';
        Test.stopTest();

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Staffing Assignment', null);
        Database.executeBatch(newProjTeamMemberCreationBatch, 500);

    }

    @isTest
    static void testForecastBatchRun(){

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;

        Project__c testProj = [SELECT Id, Name, RepliconURI__c, Project_Status__c FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        Contact testPlaceholder = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project_Team_Member_Billing_Rate__c billRateOne = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c billRateTwo = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 195, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c billRateThree = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Techincal Architect', Hourly_Rate__c = 190, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC Solution Architect 2', Hourly_Rate__c = 160, Project__c = testProj.Id, Created_in_Salesforce__c = true);

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testCon.Id, Date.today().addDays(-7), billRateOne.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testCon.Id, Date.today(), billRateTwo.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testCon.Id, Date.today(), billRateThree.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c currentWeekForecastTwo2 = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testCon.Id, Date.today(), newRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo2.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testPlaceholder.Id, Date.today().addDays(7), billRateOne.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testPlaceholder.Id, Date.today().addDays(7), billRateTwo.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;
        RepliconForecast__c currentWeekForecastTwo3 = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testPlaceholder.Id, Date.today(), newRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo3.EstimatedHours__c = 3;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};
        insert forecastsToInsertList;
        Test.stopTest();

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Forecast', null);
        Database.executeBatch(newProjTeamMemberCreationBatch, 500);

    }

    @isTest
    static void testTimeEntryBatchRun(){

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        testOppty.StageName = 'Closed Won';
        update testOppty;

        Project__c testProj = [SELECT Id, Name, RepliconURI__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        Contact testPlaceholder = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project_Team_Member_Billing_Rate__c billRateOne = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c billRateTwo = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 195, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c billRateThree = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Techincal Architect', Hourly_Rate__c = 190, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC Solution Architect 2', Hourly_Rate__c = 160, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Replicon_Time_Entry__c entryOne = new Replicon_Time_Entry__c();
        entryOne.Cognizant_Employee_Id__c = testCon.Cognizant_Employee_Id__c;
        entryOne.Peoplesoft_Project_Id__c = testProj.Peoplesoft_Project_Id__c;
        entryOne.Associated_Billing_Rate__c = billRateOne.Id;
        entryOne.EntryDate__c = Date.today();
        entryOne.TotalHrs__c = 1;

        Replicon_Time_Entry__c entryTwo = new Replicon_Time_Entry__c();
        entryTwo.Cognizant_Employee_Id__c = testCon.Cognizant_Employee_Id__c;
        entryTwo.Peoplesoft_Project_Id__c = testProj.Peoplesoft_Project_Id__c;
        entryTwo.Associated_Billing_Rate__c = billRateTwo.Id;
        entryTwo.EntryDate__c = Date.today().addDays(7);
        entryTwo.TotalHrs__c = 3;

        Replicon_Time_Entry__c entryFive = new Replicon_Time_Entry__c();
        entryFive.Cognizant_Employee_Id__c = testCon.Cognizant_Employee_Id__c;
        entryFive.Peoplesoft_Project_Id__c = testProj.Peoplesoft_Project_Id__c;
        entryFive.Associated_Billing_Rate__c = newRate.Id;
        entryFive.EntryDate__c = Date.today().addDays(14);
        entryFive.TotalHrs__c = 4;

        Replicon_Time_Entry__c entryThree = new Replicon_Time_Entry__c();
        entryThree.Employee__c = testPlaceholder.Id;
        entryThree.Peoplesoft_Project_Id__c = testProj.Peoplesoft_Project_Id__c;
        entryThree.Associated_Billing_Rate__c = billRateThree.Id;
        entryThree.EntryDate__c = Date.today();
        entryThree.TotalHrs__c = 5;

        Replicon_Time_Entry__c entryFour = new Replicon_Time_Entry__c();
        entryFour.Employee__c = testPlaceholder.Id;
        entryFour.Peoplesoft_Project_Id__c = testProj.Peoplesoft_Project_Id__c;
        entryFour.Associated_Billing_Rate__c = testProjMemberBillRate.Id;
        entryFour.EntryDate__c = Date.today().addDays(7);
        entryFour.TotalHrs__c = 3;

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo, entryFive, entryThree, entryFour};
        insert entryInsertList;

        Test.stopTest();

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Time Entry', null);
        Database.executeBatch(newProjTeamMemberCreationBatch, 500);

    }

    @isTest
    static void placeholderRetrieve_Test(){
        InternalProjectMemberCreationBatch.retrievePlaceholderTime();
    }
}