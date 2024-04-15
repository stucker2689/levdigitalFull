@isTest
public with sharing class ProjectBillingRateManager_Test {
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
        insert testOppty1;

        Opportunity testCO = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        //testCO.StageName = 'Verbal Approval (Negotiation)';
        testCO.StageName = 'Identifying an Opportunity';
        testCO.Name = 'Test Oppty 1 CO';
        testCO.Change_Orders__c = testOppty1.Id;
        insert testCO;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Email = 'testEmployeeEmail@gmail.com';

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.FirstName = 'Test Employee';
        testEmployee2.LastName = 'Number Two';
        testEmployee2.Email = 'testEmployeeEmail2@gmail.com';

        Contact testEmployee3 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee3.FirstName = 'Test Employee';
        testEmployee3.LastName = 'Number Three';
        testEmployee3.Email = 'testEmployeeEmail3@gmail.com';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1, testEmployee2, testEmployee3};
        insert setupEmployeeInsertList;

        //Create Products, Price Book Entries, Opportunity Line Items
        Product2 developerProduct = new Product2(Name = 'Developer', Family = 'Professional Services');
        Product2 mcSolutionArchitectProduct = new Product2(Name = 'MC - Solution Architect', Family = 'Professional Services');
        Product2 projectManagerProduct = new Product2(Name = 'Project Manager', Family = 'Professional Services');
        Product2 coreTechnicalArchitectProduct = new Product2(Name = 'CORE - Techincal Architect', Family = 'Professional Services');
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
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testCO.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - UK'); 
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testCO.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem, projectManagerOppty2OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.CSP_Email__c = 'testemail@gmail.com';
        testOppty1.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        update testOppty1;

    }

    @isTest
    static void checkBillRateCreationOnCW_Test(){

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        testOppty.StageName = 'Won';
        update testOppty;

        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billingRateList = [SELECT Id, Name, Project__c, Project__r.Opportunity__c, Hourly_Rate__c, Product__c, Product__r.Name
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Project__r.Name = 'Test Oppty 1'];

        for(Project_Team_Member_Billing_Rate__c rate : billingRateList){
            System.debug('CW Rate: ' + rate.Name);
        }

        Test.stopTest();

        System.assertEquals(4, billingRateList.size(), 'The incorrect number of Billing Rates were created on Closed Won');
    }

    @isTest
    static void CheckBillRateCreationFromChangeOrder_Test(){

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        testOppty.StageName = 'Won';
        update testOppty;

        Opportunity testCO = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1 CO' LIMIT 1];
        testCO.StageName = 'Won';
        update testCO;

        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billingRateList = [SELECT Id, Name, Project__c, Project__r.Opportunity__c, Hourly_Rate__c, Product__c, Product__r.Name
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Project__r.Name = 'Test Oppty 1'];

        for(Project_Team_Member_Billing_Rate__c rate : billingRateList){
            System.debug('CO Rates Name: ' + rate.Name);
        }

        Test.stopTest();

        System.assertEquals(5, billingRateList.size(), 'The incorrect number of Billing Rates were created on Change Order Closed Won');
    }

    @isTest
    static void checkOutOfDateBillingRates_Test(){

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        testOppty.Create_Project__c = true;
        update testOppty;

        Contact employeeContact = [SELECT Id, Name FROM Contact WHERE Name = 'Test Employee Number Three' LIMIT 1];

        Project_Team_Member_Billing_Rate__c projTeamMemberBillRate = [SELECT Id, Name, Project__c, Project__r.Opportunity__c, Hourly_Rate__c, Product__c, Product__r.Name
                                                                        FROM Project_Team_Member_Billing_Rate__c
                                                                        WHERE Project__r.Name = 'Test Oppty 1' AND Name = 'Project Manager' LIMIT 1];

        Client_Contact__c newClientContact = new Client_Contact__c(Client_Contact__c = employeeContact.Id, Assigned_Billing_Rate__c = projTeamMemberBillRate.Id, Project__c = projTeamMemberBillRate.Project__c);
        insert newClientContact;

        OpportunityLineItem testOli = [SELECT Id, Name, Quantity, UnitPrice FROM OpportunityLineItem WHERE Product2.Name = 'Project Manager' LIMIT 1];

        testOli.UnitPrice = 10;
        update testOli;
        
        Test.stopTest();
    }

    
}