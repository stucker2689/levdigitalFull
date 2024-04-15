/**
 * Created 5/17/2022 ST
 * Purpose: Test the OppLineTrigger, Handler, and Helper
 */
@isTest
private class OppLineTrigger_Test {

    /**
     * Test Project Role Functions
     * 
     * Insert/Update/Delete Opportunity Products on a Closed Won Opportunity
     */

    @TestSetup
    static void setupTestData(){
        System.debug('**************************** OppLineTrigger Test SETUP START ****************************');
        Account acct1 = TestDataFactory.createAccount(false, 'Client');
        acct1.Name = 'Test Client Account 1';
        insert acct1;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Account Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Account Insert');

        Opportunity opp1 = TestDataFactory.createOpportunity(false, acct1.Id, 'Salesforce');
        opp1.Name = 'Test Opp 1';
        insert opp1;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Oppty Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Oppty Insert');

        opp1.Do_Not_Create_Project__c = false;
        //opp1.Create_Project__c = true;
        opp1.StageName = 'Closed Won';
        update opp1;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Oppty Update');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Oppty Update');
        
        Product2 mcPMProd = TestDataFactory.createProduct(false);
        mcPMProd.Name = 'MC - Project Manager';
        Product2 saProd = TestDataFactory.createProduct(false);
        saProd.Name = 'Solution Architect';
        List<Product2> productList = new List<Product2>{mcPMProd, saProd};
        insert productList;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Product Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Product Insert');

        PricebookEntry mcPmPbe = TestDataFactory.createPricebookEntry(false, mcPMProd.Id);
        PricebookEntry saPbe = TestDataFactory.createPricebookEntry(false, saProd.Id);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>{mcPmPbe, saPbe};
        insert pricebookEntryList;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After PriceBook Entry Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After PriceBook Entry Insert');

        OpportunityLineItem testOli1 = TestDataFactory.createOpportunityLineItem(false, opp1.Id, mcPmPbe.Id);
        testOli1.Quantity = 50;
        testOli1.UnitPrice = 200;
        testOli1.TotalPrice = null;
        testOli1.Resource_Delivery_Group__c = 'Lev - Central Europe';

        OpportunityLineItem testOli2 = TestDataFactory.createOpportunityLineItem(false, opp1.Id, saPbe.Id);
        testOli2.Quantity = 25;
        testOli2.UnitPrice = 175;
        testOli2.TotalPrice = null;
        testOli2.Resource_Delivery_Group__c = 'Lev - NA';
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{testOli1, testOli2};        
        insert oliList;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Opportunity Line Item Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Opportunity Line Item Insert');

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' END OF SETUP');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' END OF SETUP');
        System.debug('**************************** OppLineTrigger Test SETUP END ****************************');
    }

    @isTest 
	static void insertOpptyProductOnCWOppty_Test() {
        System.debug('**************************** OppLineTrigger Test INSERT START ****************************');
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        System.debug('2.Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());

        Product2 devProd = new Product2();
        devProd.Name = 'Developer';
        insert devProd;

        PricebookEntry pbe = TestDataFactory.createPricebookEntry(true, devProd.Id);

        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp 1'];

        OpportunityLineItem testOli1 = TestDataFactory.createOpportunityLineItem(false, testOpp.Id, pbe.Id);
        testOli1.Quantity = 10;
        testOli1.UnitPrice = 125;
        testOli1.TotalPrice = null;
        OpportunityLineItem testOli2 = TestDataFactory.createOpportunityLineItem(false, testOpp.Id, pbe.Id);
        testOli2.Quantity = 5;
        testOli2.UnitPrice = 130;
        testOli2.TotalPrice = null;

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{testOli1, testOli2};

        Test.startTest();
        insert oliList;
        Test.stopTest();
    
        System.debug('**************************** OppLineTrigger Test INSERT END ****************************');
    }

    @isTest 
	static void updateOpptyProductOnCWOppty_Test() {
        System.debug('**************************** OppLineTrigger Test UPDATE START ****************************');
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        System.debug('2.Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());

        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];

        OpportunityLineItem existingPMOpptyProd = [SELECT Id, Name, Product2Id, Product2.Name, Opportunity_Product_Family__c, OpportunityId, Opportunity.Change_Orders__c, Discounted_Price__c, Quantity, TotalPrice, Opportunity.RecordTypeId
                                                    FROM OpportunityLineItem
                                                    WHERE OpportunityId =: testOpp.Id  AND Product2.Name = 'MC - Project Manager' LIMIT 1];

        existingPMOpptyProd.Quantity = 60;

        Test.startTest();
        update existingPMOpptyProd;
        Test.stopTest(); 
        System.debug('**************************** OppLineTrigger Test UPDATE END ****************************');
    }    

    @isTest 
	static void deleteOpptyProductOnCWOppty_Test() {
        System.debug('**************************** OppLineTrigger Test DELETE START ****************************');
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        System.debug('2.Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows());

        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];

        OpportunityLineItem existingPMOpptyProd = [SELECT Id, Name, Product2Id, Product2.Name, Opportunity_Product_Family__c, OpportunityId, Opportunity.Change_Orders__c, Discounted_Price__c, Quantity, TotalPrice, Opportunity.RecordTypeId
                                                    FROM OpportunityLineItem
                                                    WHERE OpportunityId =: testOpp.Id  AND Product2.Name = 'MC - Project Manager' LIMIT 1];

        Test.startTest();
        delete existingPMOpptyProd;
        Test.stopTest();          
    
        System.debug('**************************** OppLineTrigger Test DELETE END ****************************');
    }

    /******************************************** Test setOffshoreResourcesOnRelatedOppty method on OppLineTriggerHelper ********************************************/

    @isTest 
	static void insertOffshoreOpptyProduct_Test() {     

        Opportunity testOpp = [SELECT Id, Name, Offshore_Resources__c FROM Opportunity WHERE Name = 'Test Opp 1'];

        List<OpportunityLineItem> existingOliList = [SELECT Id, Name, Resource_Delivery_Group__c FROM OpportunityLineItem WHERE Opportunity.Name = 'Test Opp 1'];
        for(OpportunityLineItem oli : existingOliList){
            System.debug('existingOliList: ' + oli);
        }

        //System.assertEquals(true, testOpp.Offshore_Resources__c, 'Offshore Resources field was not properly set to True AFTER an Opportunity Product with Resource Delivery Group of Offshore was inserted');
    
    }

    @isTest 
	static void updateOpptyProduct_toOffshore_Test() {

        OpportunityLineItem existingOli = [SELECT Id, Name, Resource_Delivery_Group__c FROM OpportunityLineItem WHERE Opportunity.Name = 'Test Opp 1'  AND Product2.Name = 'MC - Project Manager' LIMIT 1];

        Test.startTest();
        existingOli.Resource_Delivery_Group__c = 'Lev - NA';
        update existingOli;
        
        existingOli.Resource_Delivery_Group__c = 'Lev - Central Europe';
        update existingOli;
        Test.stopTest();       

        Opportunity testOppAfter = [SELECT Id, Name, Offshore_Resources__c FROM Opportunity WHERE Name = 'Test Opp 1'];

        System.assertEquals(true, testOppAfter.Offshore_Resources__c, 'Offshore Resources field on Opportunity was not properly set to True AFTER an Opportunity Product was update to Offshore');      
    
    }

    @isTest 
	static void updateOpptyProduct_fromOffshore_Test() {

        OpportunityLineItem existingOli = [SELECT Id, Name, Resource_Delivery_Group__c FROM OpportunityLineItem WHERE Opportunity.Name = 'Test Opp 1'  AND Product2.Name = 'MC - Project Manager' LIMIT 1];

        Test.startTest();
        existingOli.Resource_Delivery_Group__c = 'Lev - NA';
        update existingOli;
        Test.stopTest();       

        Opportunity testOppAfter = [SELECT Id, Name, Offshore_Resources__c FROM Opportunity WHERE Name = 'Test Opp 1'];

        System.assertEquals(false, testOppAfter.Offshore_Resources__c, 'Offshore Resources field on Opportunity was not properly set to False AFTER an Opportunity Product was update from Offshore');           
    
    }

    @isTest 
	static void deleteOffshoreOpptyProduct_Test() {

        List<OpportunityLineItem> existingOliList = [SELECT Id, Name, Resource_Delivery_Group__c FROM OpportunityLineItem WHERE Opportunity.Name = 'Test Opp 1' AND Resource_Delivery_Group__c = 'Lev - Central Europe'];

        Test.startTest();
        delete existingOliList;
        Test.stopTest();       

        Opportunity testOppAfter = [SELECT Id, Name, Offshore_Resources__c FROM Opportunity WHERE Name = 'Test Opp 1'];

        System.assertEquals(false, testOppAfter.Offshore_Resources__c, 'Offshore Resources field on Opportunity was not properly set to False AFTER an Offshore Opportunity Product was deleted');    
    
    }


    @isTest
    static void countCompletedStaffingAssignemnts_Test(){

        //Create Contact for Time Entries
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = TestDataFactory.createEmployee(false, testAccount.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Quarterly_Target__c = 414;
        con.FirstName = 'Jrue';
        con.LastName = 'Holiday';
        insert con;

        Test.startTest();
        Opportunity testOppty = [SELECT Id, Name, CloseDate, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, StageName, CSP_Email__c, Managing_Director_SC_Email__c, Anticipated_Project_Start_Date__c 
                                FROM Opportunity 
                                WHERE Name = 'Test Opp 1' LIMIT 1];

        testOppty.CloseDate = Date.today().addDays(4);
        testOppty.StageName = '5. Negotiation';
        update testOppty;

        List<Staffing_Assignment__c> staffingAssignmentList = new List<Staffing_Assignment__c>();
        staffingAssignmentList = [SELECT Id, Name, Product__c, Product_Name__c, Resource_Assigned__c, Status__c
                                    FROM Staffing_Assignment__c
                                    WHERE Opportunity__r.Name = 'Test Opp 1'];

        List<Staffing_Assignment__c> staffingAssignmentUpdateList = new List<Staffing_Assignment__c>();
        for(Staffing_Assignment__c sa : staffingAssignmentList){
            sa.Resource_Assigned__c = con.Id;
            sa.Status__c = 'Completed';
            staffingAssignmentUpdateList.add(sa);
        }

        
        update staffingAssignmentUpdateList;
        Test.stopTest();

        List<Staffing_Assignment__c> staffingAssignmentList2 = new List<Staffing_Assignment__c>();
        staffingAssignmentList2 = [SELECT Id, Name, Product__c, Product_Name__c, Resource_Assigned__c, Status__c
                                    FROM Staffing_Assignment__c
                                    WHERE Opportunity__r.Name = 'Test Opp 1'];

        for(Staffing_Assignment__c sa : staffingAssignmentList2){
            System.debug('Status of Staffing Assignment: ' + sa.Status__c);
        }

        Opportunity assertOppty = [SELECT Id, Name, Count_Of_Staffing_Completed__c
                                    FROM Opportunity
                                    WHERE Name = 'Test Opp 1' LIMIT 1];

        System.assertEquals(staffingAssignmentList.size(), assertOppty.Count_Of_Staffing_Completed__c, 'The Count of Staffing Records Completed field on the Opportunity was incorrectly rolled up.');

    }

    @isTest
    static void checkForHybridStaffOnProject_Test(){
        System.debug('************************* START OF checkForHybridStaffOnProject_Test *******************************');

        Opportunity testOppty = [SELECT Id, Name, CloseDate, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, StageName, CSP_Email__c, Managing_Director_SC_Email__c, Anticipated_Project_Start_Date__c 
                                FROM Opportunity 
                                WHERE Name = 'Test Opp 1' LIMIT 1];

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name, Opportunity__c, HybridStaff__c
                    FROM Project__c];

        System.debug('Project List Size: ' + projList.size());

        for(Project__c proj : projList){
            System.debug('Project Name: ' + proj.Name + ' Hybrid Staff: ' + proj.HybridStaff__c);
        }
        System.debug('************************* END OF checkForHybridStaffOnProject_Test *******************************');
    }

    @isTest
    static void checkRecentCOProductRateType_Test(){

        Opportunity testOppty = [SELECT Id, Name, AccountId, CloseDate, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, StageName, CSP_Email__c, Managing_Director_SC_Email__c, Anticipated_Project_Start_Date__c 
                                FROM Opportunity 
                                WHERE Name = 'Test Opp 1' LIMIT 1];

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOppty.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Test Opp 1 CO';
        changeOrderOppty.Change_Orders__c = testOppty.Id;
        changeOrderOppty.StageName = '1. Engagement';
        insert changeOrderOppty;

        Product2 devProd = TestDataFactory.createProduct(false);
        devProd.Name = 'Developer';
        Product2 marConProd = TestDataFactory.createProduct(false);
        marConProd.Name = 'Marketing Consultant';
        List<Product2> productList = new List<Product2>{devProd, marConProd};
        insert productList;

        PricebookEntry devPbe = TestDataFactory.createPricebookEntry(false, devProd.Id);
        PricebookEntry marConPbe = TestDataFactory.createPricebookEntry(false, marConProd.Id);
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>{devPbe, marConPbe};
        insert pricebookEntryList;

        OpportunityLineItem testOli1 = TestDataFactory.createOpportunityLineItem(false, changeOrderOppty.Id, devPbe.Id);
        testOli1.Quantity = 23;
        testOli1.UnitPrice = 215;
        testOli1.TotalPrice = null;
        testOli1.Resource_Delivery_Group__c = 'Lev - UK';

        OpportunityLineItem testOli2 = TestDataFactory.createOpportunityLineItem(false, changeOrderOppty.Id, marConPbe.Id);
        testOli2.Quantity = 26;
        testOli2.UnitPrice = 180;
        testOli2.TotalPrice = null;
        testOli2.Resource_Delivery_Group__c = 'Lev - India';

        List<OpportunityLineItem> oliInsertList = new List<OpportunityLineItem>{testOli1, testOli2};
        Test.startTest();
        insert oliInsertList;
        Test.stopTest();

        //System.assertEquals()

    }
}