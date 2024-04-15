@isTest
public with sharing class AddBillingRatesToRepliconProject_Test {
    
    
    @TestSetup
    static void makeData(){
        TestDataFactory.createRepliconDropdownRecords(); //Insert Replicon Dropdowns for Project Creation in Replicon callout

        List<Account> testAccountList = new List<Account>();
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        testAccountList.add(levementumLLCAcct);

        //Create Test Client Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        testAccountList.add(acct);

        //Insert Both Accounts
        insert testAccountList;

        //Create Test Oppty associated with the Client Account
        Opportunity oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'Replicon Forecast Trigger Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

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

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev-Onshore');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150, Resource_Delivery_Group__c = 'Lev-Onshore'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev-Onshore'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev-Onshore'); 
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;
    }

    @isTest
    static void addBillRatesToReplicon_Test(){
        System.debug('******************************** addBillRatesToReplicon_Test ********************************');
        String getBillingRatesResponse = 'https://na3.replicon.com/levementum/services/TimeAndMaterialsProjectService1.svc/GetCouldBeEnabledBillingRates';
        String addBillingRatesResponse = 'https://na3.replicon.com/levementum/services/TimeAndMaterialsProjectService1.svc/UpdateBillingRateIsAvailableForAssignmentToTeamMembers';
        String updateBillingRatesResponse = 'https://na3.replicon.com/levementum/services/TimeAndMaterialsProjectService1.svc/UpdateProjectBillingRateScheduleOverDateRange';

        Project__c queriedProject = [SELECT Id, Name FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:44444'];
        
        Test.startTest();

        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(getBillingRatesResponse, 'GetBillingRatesRepliconServiceResponse');
        newHTTPMock.setStaticResource(addBillingRatesResponse, 'RepliconDnullResponse');
        newHTTPMock.setStaticResource(updateBillingRatesResponse, 'RepliconDnullResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        AddBillingRatesToRepliconProject.addOpportunityProductsAsRepliconBillRates(queriedProject.Id);

        Test.stopTest();

        System.debug([SELECT Error_Message__c, Line_Number__c, Method_Name__c, Class_Name__c FROM Error_Log_Lev__c]);

    }

    @isTest
    static void getAllBillingRates_Test(){
        System.debug('******************************** getAllBillingRates_Test ********************************');

        String getBillingRatesResponse = 'https://na3.replicon.com/levementum/services/TimeAndMaterialsProjectService1.svc/GetCouldBeEnabledBillingRates';

        Project__c queriedProject = [SELECT Id, Name, RepliconUri__c FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:44444'];
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(getBillingRatesResponse, 'GetBillingRatesRepliconServiceResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        AddBillingRatesToRepliconProject.getAllRepliconBillingRates(queriedProject.RepliconUri__c);
        Test.stopTest();

        System.debug([SELECT Error_Message__c, Line_Number__c, Method_Name__c, Class_Name__c FROM Error_Log_Lev__c]);

    }
}