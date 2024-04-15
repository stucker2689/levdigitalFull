/**
 * Created 5/18/2022 ST
 * 
 * Purpose to test the functionality of the ProjectRoleManager class
 */

@isTest
private class ProjectRoleManager_Test {

    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
    
    @TestSetup
    static void makeData(){
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' SETUP START');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' SETUP START');
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

        //Create Change Orders
        Opportunity testCOOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        testCOOppty1.Name = 'Test Project Role Oppty 1 CO 1';
        testCOOppty1.Change_Orders__c = testOppty1.Id;

        Opportunity testCOOppty2 = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        testCOOppty2.Name = 'Test Project Role Oppty 1 CO 2';
        testCOOppty2.Change_Orders__c = testOppty1.Id;

        Opportunity testCOOppty3 = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        testCOOppty3.Name = 'Test Project Role Oppty 2 CO 1';
        testCOOppty3.Change_Orders__c = testOppty2.Id;

        List<Opportunity> testChangeOrdersList = new List<Opportunity>{testCOOppty1, testCOOppty2, testCOOppty3};
        insert testChangeOrdersList;

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

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100);
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250); 
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE CLOSED WON OPPTY');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE CLOSED WON OPPTY');  

        //Move Opportunities to Closed Won to have Projects and Project Roles created
        /*testOppty1.StageName = 'Closed Won';
        testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1, testOppty2};
        update testUpdateOpptiesToClosedWonList; */

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' SETUP END');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' SETUP END');   

    }

    @isTest
    static void createProjectRoleFromProject_Test(){
        //Purpose: Create Project Roles when a Project is created
        Test.startTest();
        Opportunity testOppty1 = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        Opportunity testOppty2 = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 2' LIMIT 1];
        testOppty1.StageName = 'Closed Won';
        testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1, testOppty2};
        update testUpdateOpptiesToClosedWonList; 

        List<Project__c> projectList = [SELECT Id, Name, Opportunity__c, Opportunity__r.Name FROM Project__c WHERE Name IN ('Test Project Role Oppty 1', 'Test Project Role Oppty 2')];

        System.assertEquals(2, projectList.size(), 'The Wrong number of Projects was created');

        Id projectRoleOppty1ProjectId;
        Id projectRoleOppty2ProjectId;
        for(Project__c proj : projectList){
            if(proj.Name == 'Test Project Role Oppty 1'){
                projectRoleOppty1ProjectId = proj.Id;
            }else if(proj.Name == 'Test Project Role Oppty 2'){
                projectRoleOppty2ProjectId = proj.Id;                
            }
        }

        Map<String, Id> productNameToProductIdMap = new Map<String, Id>();
        for(Product2 product : [SELECT Id, Name FROM Product2]){
            productNameToProductIdMap.put(product.Name, product.Id);
        }
        
        List<ProjectRole__c> projectRolesList = [SELECT Id, Name, Quantity_Sold__c, Total_Amount_Sold__c, Project__c, Product__c, Rate__c FROM ProjectRole__c];

        System.assertEquals(4, projectRolesList.size(), 'The wrong number of Project Role records were created');

        for(ProjectRole__c projectRole : projectRolesList){
            System.assertEquals(projectRoleOppty1ProjectId, projectRole.Project__c, 'The Project Role was associated with the wrong Project Lookup');
            System.assertEquals(productNameToProductIdMap.get(projectRole.Name), projectRole.Product__c, 'The Project Role was associated with the wrong Product Lookup');
            
            if(projectRole.Name == 'Developer'){
                System.assertEquals(100, projectRole.Rate__c, 'The Developer Project Role was created with the wrong Rate');
                System.assertEquals(10, projectRole.Quantity_Sold__c, 'The Developer Project Role was created with the wrong Quantity Sold');
                System.assertEquals(1000, projectRole.Total_Amount_Sold__c, 'The Developer Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'MC - Solution Architect'){
                System.assertEquals(150, projectRole.Rate__c, 'The MC - Solution Architect Project Role was created with the wrong Rate');
                System.assertEquals(15, projectRole.Quantity_Sold__c, 'The MC - Solution Architect Project Role was created with the wrong Quantity Sold');
                System.assertEquals(2250, projectRole.Total_Amount_Sold__c, 'The MC - Solution Architect Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'Project Manager'){
                System.assertEquals(200, projectRole.Rate__c, 'The Project Manager Project Role was created with the wrong Rate');
                System.assertEquals(20, projectRole.Quantity_Sold__c, 'The Project Manager Project Role was created with the wrong Quantity Sold');
                System.assertEquals(4000, projectRole.Total_Amount_Sold__c, 'The Project Manager Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'CORE - Techincal Architect'){
                System.assertEquals(250, projectRole.Rate__c, 'The CORE - Techincal Architect Project Role was created with the wrong Rate');
                System.assertEquals(25, projectRole.Quantity_Sold__c, 'The CORE - Techincal Architect Project Role was created with the wrong Quantity Sold');
                System.assertEquals(6250, projectRole.Total_Amount_Sold__c, 'The CORE - Techincal Architect Project Role was created with the wrong Total Amount Sold');
            }else{
                System.assertEquals(false, true, 'A Project Role has been created with a name that does not match the Opportunity Line Item Names that have been created on the Oppty');
            }
        }
        Test.stopTest();
        
    }

    @isTest
    static void createProjectRoleFromChangeOrder_Test(){
        //Purpose: Create Project Roles when an Opportunity Product is created/editted/deleted on a Change Order
        Test.startTest();
        Opportunity testOppty1 = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        Opportunity testOppty2 = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 2' LIMIT 1];
        testOppty1.StageName = 'Closed Won';
        testOppty2.StageName = 'Closed Won';

        Opportunity changeOrderOppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project Role Oppty 1 CO 1' LIMIT 1];

        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<PricebookEntry> priceBookEntryList = [SELECT Id, Name, UnitPrice FROM PricebookEntry];
        for(PricebookEntry pbe : priceBookEntryList){
            if(pbe.Name == 'Developer'){
                OpportunityLineItem newDeveloperOpptyLineItem = new OpportunityLineItem(OpportunityId = changeOrderOppty.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 100);
                opportunityLineItemsToInsert.add(newDeveloperOpptyLineItem);
            }else if(pbe.Name == 'Project Manager'){
                OpportunityLineItem newProjectManagerOpptyLineItem = new OpportunityLineItem(OpportunityId = changeOrderOppty.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 125);
                opportunityLineItemsToInsert.add(newProjectManagerOpptyLineItem);
            }
        }

        
        //Add Opportunity Line Items to Change Order
        insert opportunityLineItemsToInsert;

        //Update Change Order to Closed Won
        changeOrderOppty.StageName = 'Closed Won';
        //update changeOrderOppty;
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1, testOppty2, changeOrderOppty};
        update testUpdateOpptiesToClosedWonList; 
        
        

        List<ProjectRole__c> projectRolesList = [SELECT Id, Name, Quantity_Sold__c, Total_Amount_Sold__c, Project__c, Product__c, Rate__c FROM ProjectRole__c WHERE Project__r.Name = 'Test Project Role Oppty 1'];

        Test.stopTest();
        System.assertEquals(5, projectRolesList.size(), 'The wrong number of Project Role records were created');

        for(ProjectRole__c projectRole : projectRolesList){
            
            if(projectRole.Name == 'Developer'){
                System.assertEquals(100, projectRole.Rate__c, 'The Developer Project Role was created with the wrong Rate');
                System.assertEquals(15, projectRole.Quantity_Sold__c, 'The Developer Project Role was created with the wrong Quantity Sold');
                System.assertEquals(1500, projectRole.Total_Amount_Sold__c, 'The Developer Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'MC - Solution Architect'){
                System.assertEquals(150, projectRole.Rate__c, 'The MC - Solution Architect Project Role was created with the wrong Rate');
                System.assertEquals(15, projectRole.Quantity_Sold__c, 'The MC - Solution Architect Project Role was created with the wrong Quantity Sold');
                System.assertEquals(2250, projectRole.Total_Amount_Sold__c, 'The MC - Solution Architect Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'Project Manager'){
                System.assertEquals(200, projectRole.Rate__c, 'The Project Manager Project Role was created with the wrong Rate');
                System.assertEquals(20, projectRole.Quantity_Sold__c, 'The Project Manager Project Role was created with the wrong Quantity Sold');
                System.assertEquals(4000, projectRole.Total_Amount_Sold__c, 'The Project Manager Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'CORE - Techincal Architect'){
                System.assertEquals(250, projectRole.Rate__c, 'The CORE - Techincal Architect Project Role was created with the wrong Rate');
                System.assertEquals(25, projectRole.Quantity_Sold__c, 'The CORE - Techincal Architect Project Role was created with the wrong Quantity Sold');
                System.assertEquals(6250, projectRole.Total_Amount_Sold__c, 'The CORE - Techincal Architect Project Role was created with the wrong Total Amount Sold');
            }else if(projectRole.Name == 'Project Manager 2'){
                System.assertEquals(125, projectRole.Rate__c, 'The Project Manager 2 Project Role was created with the wrong Rate');
                System.assertEquals(5, projectRole.Quantity_Sold__c, 'The Project Manager 2 Project Role was created with the wrong Quantity Sold');
                System.assertEquals(625, projectRole.Total_Amount_Sold__c, 'The Project Manager 2 Project Role was created with the wrong Total Amount Sold');
            }else{
                System.assertEquals(false, true, 'A Project Role has been created with a name that does not match the Opportunity Line Item Names that have been created on the Oppty');
            }
        }
    }

    @isTest
    static void createProjectRoleFromOpptyProd_Test(){
        //Purpose: Create Project Roles when an Opportunity Product is created on a Closed Won Opportunity or Change Order

    }

    @isTest
    static void updateProjectRoleFromOpptyProd_Test(){
        //Purpose: Update Project Roles when an Opportunity Product is editted on a Closed Won Opportunity or Change Order

    }

    @isTest
    static void deleteProjectRoleFromOpptyProd_Test(){
        //Purpose: Delete Project Roles when an Opportunity Product is deleted on a Closed Won Opportunity or Change Order

    }
}