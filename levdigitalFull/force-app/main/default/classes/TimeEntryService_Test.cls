@isTest
public with sharing class TimeEntryService_Test {
    
    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    @TestSetup
    static void makeData(){
        System.debug('RepliconService setupData');
        Account newAccount = new Account();
        newAccount.Name = 'Testing Account';
        newAccount.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        newAccount.MSA_Number__c = 'MSA_Test01';
		
        Account newCompanyAccount = new Account();
        newCompanyAccount.Name = 'Levementum LLC';

        List<Account> acctList = new List<Account>{newAccount, newCompanyAccount};
        insert acctList;

        System.debug('RepliconService after Account Insert');
        
        Contact employee1 = new Contact();
        employee1.FirstName = 'Test';
        employee1.LastName = 'Employee1';
        employee1.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee1.Email = 'temployee1@levdigital.com';
        employee1.Replicon_User_Number__c = 1;
        employee1.RepliconLoginName__c = 'temployee1';
        employee1.AccountId = newCompanyAccount.Id;
        employee1.Cognizant_Employee_Id__c = '1234';
        insert employee1;

        System.debug('RepliconService after Account Contact Insert');
        
        /*Contact employee2 = new Contact();
        employee2.FirstName = 'Test';
        employee2.LastName = 'Employee200';
        employee2.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee2.Email = 'temp2loyee200@levdigital.com';
        employee2.Replicon_User_Number__c = 200;
        employee2.RepliconLoginName__c = 'temployee200';
        insert employee2;*/
        
        Opportunity opportunity1 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        opportunity1.AccountId = newAccount.Id;
        opportunity1.Name = 'Test Project';
        opportunity1.CloseDate = system.today()+60;
        opportunity1.Start_Date__c = system.today()+10;
        opportunity1.End_Date__c = system.today()+40;
        opportunity1.Amount = 55000.00;
        opportunity1.StageName='Closed Won';
        opportunity1.ExpectedPro_DurationinWeeks__c = 3;
        opportunity1.Service__c = 'Program';
        opportunity1.Program_Type__c = 'Strategic';
        opportunity1.LeadSource = 'Salesforce.com';
        opportunity1.Lead_Source__c = 'Salesforce AE';
        opportunity1.Number_of_Contact_Rolls_Added__c = 2;
        opportunity1.Project_Terms__c = 'Time and Materials';
        opportunity1.LevementumVertical__c = 'Manufacturing';
        opportunity1.Payment_Terms__c = 'Invoice Net 15';
        opportunity1.Payment_Schedule__c = 'Standard TM';
        opportunity1.Signatures_Completed__c = true;
        opportunity1.Opportunity_Accuracy_Validated__c = true;
        opportunity1.Peoplesoft_Project_Id__c = '1111';

        Opportunity opportunity2 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        opportunity2.Name = 'Test Opp2';
        opportunity2.CloseDate = system.today()+60;
        opportunity2.Start_Date__c = system.today()+10;
        opportunity2.End_Date__c = system.today()+40;
        opportunity2.Amount = 55000.00;
        opportunity2.StageName='Closed Won';
        opportunity2.ExpectedPro_DurationinWeeks__c = 3;
        opportunity2.Service__c = 'Program';
        opportunity2.Program_Type__c = 'Strategic';
        opportunity2.LeadSource = 'Salesforce.com';
        opportunity2.Lead_Source__c = 'Salesforce AE';
        opportunity2.Number_of_Contact_Rolls_Added__c = 2;
        opportunity2.Project_Terms__c = 'Time and Materials';
        opportunity2.Payment_Terms__c = 'Invoice Net 15';
        opportunity2.LevementumVertical__c = 'Manufacturing';
        opportunity2.Payment_Schedule__c = 'Standard TM';
        opportunity2.Signatures_Completed__c = true;
        opportunity2.Opportunity_Accuracy_Validated__c = true;
        opportunity2.Peoplesoft_Project_Id__c = '2222';
        //1/18 ST Added Fields

        List<Opportunity> opptyList = new List<Opportunity>{opportunity1, opportunity2};
        insert opptyList;

        System.debug('RepliconService after Account Opportunity Insert');

        Project__c project1 = new Project__c();
        project1.Account__c = newAccount.Id;
        project1.Opportunity__c = opportunity1.Id;
        project1.Name = 'Test Project';
        project1.Project_Status__c = 'In Progress';

        Project__c project2 = new Project__c();
        project2.Account__c = newAccount.Id;
        project2.Opportunity__c = opportunity2.Id;
        project2.Name = 'Test Project Role Project';
        project2.Project_Status__c = 'In Progress';
        
        List<Project__c> projList = new List<Project__c>{project1, project2};
        insert projList;
    }

    @isTest
    static void insertTimeEntryWithNoLookups_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;
    }

    @isTest
    static void insertTimeEntryWithLookups_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;
    }

    @isTest
    static void insertTimeEntryWithConcession_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'U';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.Is_Concession__c = true;
        insert newEntry;
    }

    @isTest
    static void updateTimeEntryWithConcession_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'U';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;


        newEntry.Is_Concession__c = true;
        update newEntry;
    }

    @isTest
    static void updateTimeEntryToDeleted_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        newEntry.Deleted_in_Replicon__c = true;
        update newEntry;
    }

    @isTest
    static void updateTimeEntryToAnotherProject_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Project__c testProj2 = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '2222' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        newEntry.Project__c = testProj2.Id;
        newEntry.Peoplesoft_Project_Id__c = '2222';
        update newEntry;
    }

    @isTest
    static void updateTimeEntryEntryDate_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Project__c testProj2 = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '2222' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Test.startTest();
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        newEntry.EntryDate__c = Date.today().addDays(14);
        update newEntry;
        Test.stopTest();
    }

    @isTest
    static void deleteTimeEntry_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        delete newEntry;
    }

    @isTest
    static void rollupProjectRole_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Opportunity testOppty = [SELECT Id, Name, AccountId, Peoplesoft_Project_Id__c FROM Opportunity WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

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

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev - NA');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        Test.startTest();
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem, projectManagerOppty2OpportunityLineItem};
        insert testOpportunityLineItemList;

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC - Solution Architect', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.TotalHrs__c = 6.25;
        insert newEntry;

        Test.stopTest();

    }

    @isTest
    static void rollupProjectRole2_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Opportunity testOppty = [SELECT Id, Name, AccountId, Peoplesoft_Project_Id__c FROM Opportunity WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

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

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev - NA');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 222, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        Test.startTest();
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem, projectManagerOppty2OpportunityLineItem};
        insert testOpportunityLineItemList;

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC - Solution Architect 2', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = newBillRate.Id);
        insert newTeamMember;
        
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.TotalHrs__c = 6.25;
        insert newEntry;

        Test.stopTest();

    }

    @isTest
    static void insertWithNoCogOrESAId_Test(){
        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Opportunity testOppty = [SELECT Id, Name, AccountId, Peoplesoft_Project_Id__c FROM Opportunity WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Project__c = testProj.Id;
        newEntry.Employee__c = testEmployee.Id;
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.TotalHrs__c = 6.25;
        insert newEntry;

        Replicon_Time_Entry__c assertEntry = [SELECT Id, Name, Cognizant_Employee_Id__c, Peoplesoft_Project_Id__c FROM Replicon_Time_Entry__c WHERE Id =: newEntry.Id LIMIT 1];
        System.assertEquals('1234', assertEntry.Cognizant_Employee_Id__c, 'Cognizant Employee Id was not properly populated when entry was inserted with just Employee Lookup');
        System.assertEquals('1111', assertEntry.Peoplesoft_Project_Id__c, 'Peoplesoft Project Id was not properly populated when entry was inserted with just Project Lookup');


    }

    @isTest
    static void projectRollups_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Set<Id> projIdSet = new Set<Id>{testProj.Id};

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newBillableEntry = new Replicon_Time_Entry__c();
        newBillableEntry.Cognizant_Employee_Id__c = '1234';
        newBillableEntry.Peoplesoft_Project_Id__c = '1111';
        newBillableEntry.Billing_Action__c = 'B';
        newBillableEntry.EntryDate__c = Date.today();
        newBillableEntry.TotalHrs__c = 8;
        newBillableEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newConcessionEntry = new Replicon_Time_Entry__c();
        newConcessionEntry.Cognizant_Employee_Id__c = '1234';
        newConcessionEntry.Peoplesoft_Project_Id__c = '1111';
        newConcessionEntry.Billing_Action__c = 'B';
        newConcessionEntry.EntryDate__c = Date.today().addDays(-14);
        newConcessionEntry.TotalHrs__c = 8;
        newConcessionEntry.Is_Concession__c = true;
        newConcessionEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newNonBillEntry = new Replicon_Time_Entry__c();
        newNonBillEntry.Cognizant_Employee_Id__c = '1234';
        newNonBillEntry.Peoplesoft_Project_Id__c = '1111';
        newNonBillEntry.Billing_Action__c = 'U';
        newNonBillEntry.EntryDate__c = Date.today().addDays(14);
        newNonBillEntry.TotalHrs__c = 8;
        newNonBillEntry.ActivityName__c = 'Business Support';

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{newBillableEntry, newConcessionEntry ,newNonBillEntry};

        Test.startTest();
        insert entryInsertList;

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name FROM Replicon_Timesheet__c];
        Set<Id> timesheetIdSet = new Set<Id>();

        for(Replicon_Timesheet__c timesheet : timesheetList){
            timesheetIdSet.add(timesheet.Id);
        }

        TimeEntryRollupManager.calculateProjectRollupValues(projIdSet);
        TimeEntryRollupManager.calculateTimesheetRollupValues(timesheetIdSet);
        //TimeEntryRollupManager.calculateWeeklyTargetActualsRollup();
        Test.stopTest();
    }

    @isTest
    static void weeklyTargetRollups_Test(){

        Revenue_Forecast__c testCurrentMonthRevForecast = new Revenue_Forecast__c();
        testCurrentMonthRevForecast.RecordTypeId = monthlyTargetRT;
        testCurrentMonthRevForecast.MonthStartDate__c = Date.today().toStartOfMonth();
        testCurrentMonthRevForecast.MonthlyTarget__c = 2300000;
        insert testCurrentMonthRevForecast;

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Set<Id> projIdSet = new Set<Id>{testProj.Id};

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newBillableEntry = new Replicon_Time_Entry__c();
        newBillableEntry.Cognizant_Employee_Id__c = '1234';
        newBillableEntry.Peoplesoft_Project_Id__c = '1111';
        newBillableEntry.Billing_Action__c = 'B';
        newBillableEntry.EntryDate__c = Date.today();
        newBillableEntry.TotalHrs__c = 8;
        newBillableEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newConcessionEntry = new Replicon_Time_Entry__c();
        newConcessionEntry.Cognizant_Employee_Id__c = '1234';
        newConcessionEntry.Peoplesoft_Project_Id__c = '1111';
        newConcessionEntry.Billing_Action__c = 'B';
        newConcessionEntry.EntryDate__c = Date.today().addDays(-14);
        newConcessionEntry.TotalHrs__c = 8;
        newConcessionEntry.Is_Concession__c = true;
        newConcessionEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newNonBillEntry = new Replicon_Time_Entry__c();
        newNonBillEntry.Cognizant_Employee_Id__c = '1234';
        newNonBillEntry.Peoplesoft_Project_Id__c = '1111';
        newNonBillEntry.Billing_Action__c = 'U';
        newNonBillEntry.EntryDate__c = Date.today().addDays(14);
        newNonBillEntry.TotalHrs__c = 8;
        newNonBillEntry.ActivityName__c = 'Business Support';

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{newBillableEntry, newConcessionEntry ,newNonBillEntry};

        Test.startTest();
        insert entryInsertList;

        List<Revenue_Forecast__c> weeklyTargetList = new List<Revenue_Forecast__c>();
        weeklyTargetList = [SELECT Id, Name FROM Revenue_Forecast__c WHERE RecordTypeId =: weeklyTargetRT];
        Set<Id> weeklyTargetIdSet = new Set<Id>();

        for(Revenue_Forecast__c weeklyTarget : weeklyTargetList){
            weeklyTargetIdSet.add(weeklyTarget.Id);
        }
        TimeEntryRollupManager.calculateWeeklyTargetActualsRollup(weeklyTargetIdSet);
        Test.stopTest();
    }


    @isTest
    static void projectRollupsFuture_Test(){

        Contact testEmployee = [SELECT Id, Name FROM Contact LIMIT 1];
        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Peoplesoft_Project_Id__c = '1111' LIMIT 1];
        Set<Id> projIdSet = new Set<Id>{testProj.Id};

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Project__c = testProj.Id, Hourly_Rate__c = 222, Created_in_Salesforce__c = true);
        insert newBillRate;

        Client_Contact__c newTeamMember = new Client_Contact__c(Account__c = testProj.Account__c, Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'Developer');
        insert newTeamMember;
        
        Replicon_Time_Entry__c newBillableEntry = new Replicon_Time_Entry__c();
        newBillableEntry.Cognizant_Employee_Id__c = '1234';
        newBillableEntry.Peoplesoft_Project_Id__c = '1111';
        newBillableEntry.Billing_Action__c = 'B';
        newBillableEntry.EntryDate__c = Date.today();
        newBillableEntry.TotalHrs__c = 8;
        newBillableEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newConcessionEntry = new Replicon_Time_Entry__c();
        newConcessionEntry.Cognizant_Employee_Id__c = '1234';
        newConcessionEntry.Peoplesoft_Project_Id__c = '1111';
        newConcessionEntry.Billing_Action__c = 'B';
        newConcessionEntry.EntryDate__c = Date.today().addDays(-14);
        newConcessionEntry.TotalHrs__c = 8;
        newConcessionEntry.Is_Concession__c = true;
        newConcessionEntry.ActivityName__c = 'Business Support';

        Replicon_Time_Entry__c newNonBillEntry = new Replicon_Time_Entry__c();
        newNonBillEntry.Cognizant_Employee_Id__c = '1234';
        newNonBillEntry.Peoplesoft_Project_Id__c = '1111';
        newNonBillEntry.Billing_Action__c = 'U';
        newNonBillEntry.EntryDate__c = Date.today().addDays(14);
        newNonBillEntry.TotalHrs__c = 8;
        newNonBillEntry.ActivityName__c = 'Business Support';

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{newBillableEntry, newConcessionEntry ,newNonBillEntry};

        Test.startTest();
        insert entryInsertList;

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name FROM Replicon_Timesheet__c];
        Set<Id> timesheetIdSet = new Set<Id>();

        for(Replicon_Timesheet__c timesheet : timesheetList){
            timesheetIdSet.add(timesheet.Id);
        }

        TimeEntryRollupManager.calculateProjectRollupValuesFuture(projIdSet);
        TimeEntryRollupManager.calculateTimesheetRollupValuesFuture(timesheetIdSet);
        //TimeEntryRollupManager.calculateWeeklyTargetActualsRollup();
        Test.stopTest();
    }

}