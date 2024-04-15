/**
 * Created by jmahapatra on 3/6/18.
 * 
 * Edited 5/19/2022 ST - To make it an actual test class
 */

@isTest
private class OpportunityCalculationsTest {

    //@TestVisible private static Id changeOrderOpptyRT = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
    //@TestVisible private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Account a = new Account();
        a.Name = 'Test Opportunity Calculations Account';
        a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        insert a;

        // Opportunity
        Opportunity oppo = TestDataFactory.createOpportunity(false, a.Id, 'Salesforce');
        oppo.Name = 'Test Opportunity Calculations Oppty';
        oppo.Change_Order_Revenue__c = 0;

        /*Opportunity oppo2 = TestDataFactory.createOpportunity(false, a.Id, 'Salesforce');
        oppo2.Name = 'Test Opportunity Calculations Oppty #2';
        oppo2.Change_Order_Revenue__c = 0;*/

        //List<Opportunity> opptyInsertList = new List<Opportunity>{oppo, oppo2}; //As of 10/19/2022 adding 2 Opptys and 2 COs is causing a 'Too Many SOQL Queries Error'
        List<Opportunity> opptyInsertList = new List<Opportunity>{oppo};
        insert opptyInsertList;

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, a.Id, 'Change Order');
        changeOrderOppty.Name = 'Test Opportunity Calculations Change Order';
        changeOrderOppty.Change_Order_Revenue__c = 0;
        changeOrderOppty.Change_Orders__c = oppo.Id;

        /*Opportunity changeOrderOppty2 = TestDataFactory.createOpportunity(false, a.Id, 'Change Order');
        changeOrderOppty2.Name = 'Test Opportunity Calculations Change Order #2';
        oppo2.Change_Order_Revenue__c = 0;
        changeOrderOppty2.Change_Orders__c = oppo2.Id;
        changeOrderOppty2.StageName = 'Closed Won';*/

        //List<Opportunity> changeOrderInsertList = new List<Opportunity>{changeOrderOppty, changeOrderOppty2}; //As of 10/19/2022 adding 2 Opptys and 2 COs is causing a 'Too Many SOQL Queries Error'
        List<Opportunity> changeOrderInsertList = new List<Opportunity>{changeOrderOppty};
        insert changeOrderInsertList;
        
        //Create Products, Price Book Entries, Opportunity Line Items
        Product2 developerProduct = new Product2(Name = 'Developer');
        Product2 projectManagerProduct = new Product2(Name = 'Project Manager');
        List<Product2> testProductsList = new List<Product2>{developerProduct, projectManagerProduct};
        insert testProductsList;

        PricebookEntry developerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = developerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry projectManagerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = projectManagerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        List<PricebookEntry> testPriceBookEntryList = new List<PricebookEntry>{developerPriceBookEntry, projectManagerPriceBookEntry};
        insert testPriceBookEntryList;

        OpportunityLineItem developerOpptyProduct = new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev - UK');
        OpportunityLineItem projectManagerOpptyProduct= new OpportunityLineItem(OpportunityId = oppo.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'ATG');
        OpportunityLineItem coDeveloperOpptyProduct = new OpportunityLineItem(OpportunityId = changeOrderOppty.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 5, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev - NA');
        OpportunityLineItem coProjectManagerOpptyProduct = new OpportunityLineItem(OpportunityId = changeOrderOppty.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 5, UnitPrice = 200, Resource_Delivery_Group__c = 'ATG');
        
        /*OpportunityLineItem developerOpptyProduct2 = new OpportunityLineItem(OpportunityId = oppo2.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev-UK');
        OpportunityLineItem projectManagerOpptyProduct2 = new OpportunityLineItem(OpportunityId = oppo2.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'ATG');
        OpportunityLineItem coDeveloperOpptyProduct2 = new OpportunityLineItem(OpportunityId = changeOrderOppty2.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 5, UnitPrice = 100, Resource_Delivery_Group__c = 'Lev-Onshore');
        OpportunityLineItem coProjectManagerOpptyProduct2 = new OpportunityLineItem(OpportunityId = changeOrderOppty2.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 5, UnitPrice = 200, Resource_Delivery_Group__c = 'CTSH-Regional');

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOpptyProduct, projectManagerOpptyProduct, coDeveloperOpptyProduct, coProjectManagerOpptyProduct,
                                                                                                developerOpptyProduct2, projectManagerOpptyProduct2, coDeveloperOpptyProduct2, coProjectManagerOpptyProduct2};*/
        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOpptyProduct, projectManagerOpptyProduct, coDeveloperOpptyProduct, coProjectManagerOpptyProduct};
        insert testOpportunityLineItemList;

        oppo.StageName = 'Closed Won';
        //oppo2.StageName = 'Closed Won';

        //List<Opportunity> updateOpptyList = new List<Opportunity>{oppo, oppo2};
        List<Opportunity> updateOpptyList = new List<Opportunity>{oppo};
        update updateOpptyList; 
    }

    @isTest
    static void setUpDataAssertionsTest(){
        
        Opportunity testOppty = [SELECT Id, Amount, PS_Hours__c, Total_Hours__c, Non_Lev_Opportunity_Hours__c, Non_Lev_Opportunity_Revenue__c, Lev_Opportunity_Hours__c, Lev_Opportunity_Revenue__c,
                                        Change_Order_Revenue__c, Change_Order_Hours__c, Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c 
                                    FROM Opportunity WHERE Name = 'Test Opportunity Calculations Oppty' LIMIT 1];

        System.assertEquals(5000, testOppty.Amount, 'The Amount on the Opportunity was not calculated as expected');
        System.assertEquals(30, testOppty.PS_Hours__c, 'The Service Hours on the Opportunity was not calculated as expected');
        System.assertEquals(30, testOppty.Total_Hours__c, 'The Opportunity Hours on the Opportunity was not calculated as expected');

        System.assertEquals(20, testOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(4000, testOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assert(testOppty.Non_Lev_Change_Order_Hours__c == 0 || testOppty.Non_Lev_Change_Order_Hours__c == null, 'Non Lev Change Order Hours was calculated incorrectly');
        System.assert(testOppty.Non_Lev_Change_Order_Revenue__c == 0 || testOppty.Non_Lev_Change_Order_Revenue__c == null, 'Non Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(10, testOppty.Lev_Opportunity_Hours__c, 'Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(1000, testOppty.Lev_Opportunity_Revenue__c, 'Lev Opportunity Revenue was calculated incorrectly');
        System.assert(testOppty.Change_Order_Lev_Hours__c == 0 || testOppty.Change_Order_Lev_Hours__c == null, 'Lev Change Order Hours was calculated incorrectly');
        System.assert(testOppty.Change_Order_Lev_Revenue__c == 0 || testOppty.Change_Order_Lev_Revenue__c == null, 'Lev Change Order Revenue was calculated incorrectly');
        System.assert(testOppty.Change_Order_Hours__c == 0 || testOppty.Change_Order_Hours__c == null, 'Change Order Hours was calculated incorrectly');
        System.assert(testOppty.Change_Order_Revenue__c == 0 || testOppty.Change_Order_Revenue__c == null, 'Change Order Revenue was calculated incorrectly');
        System.assert(testOppty.Number_of_Change_Orders__c == 0 || testOppty.Number_of_Change_Orders__c == null, 'Number of Change Orders was calculated incorrectly');

    }

    /*@isTest
    static void setUpDataAssertionsTest_Two(){
        
        Opportunity testOppty = [SELECT Id, Amount, PS_Hours__c, Total_Hours__c, Non_Lev_Opportunity_Hours__c, Non_Lev_Opportunity_Revenue__c, Lev_Opportunity_Hours__c, Lev_Opportunity_Revenue__c,
                                        Change_Order_Revenue__c, Change_Order_Hours__c, Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c 
                                    FROM Opportunity WHERE Name = 'Test Opportunity Calculations Oppty #2' LIMIT 1];

        System.assertEquals(5000, testOppty.Amount, 'The Amount on the Opportunity was not calculated as expected');
        System.assertEquals(30, testOppty.PS_Hours__c, 'The Service Hours on the Opportunity was not calculated as expected');
        System.assertEquals(30, testOppty.Total_Hours__c, 'The Opportunity Hours on the Opportunity was not calculated as expected');

        System.assertEquals(20, testOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(4000, testOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(20, testOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(4000, testOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(5, testOppty.Non_Lev_Change_Order_Hours__c, 'Non Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(1000, testOppty.Non_Lev_Change_Order_Revenue__c, 'Non Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(10, testOppty.Lev_Opportunity_Hours__c, 'Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(1000, testOppty.Lev_Opportunity_Revenue__c, 'Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(5, testOppty.Change_Order_Lev_Hours__c, 'Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(500, testOppty.Change_Order_Lev_Revenue__c, 'Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(10, testOppty.Change_Order_Hours__c, 'Change Order Hours was calculated incorrectly');
        System.assertEquals(1500, testOppty.Change_Order_Revenue__c, 'Change Order Revenue was calculated incorrectly');
        System.assertEquals(1, testOppty.Number_of_Change_Orders__c, 'Number of Change Orders was calculated incorrectly');

    }*/

    @isTest
    static void updateChangeOrderAmountTest(){

        Test.startTest();
        Opportunity testChangeOrderOppty = [SELECT Id, Amount, Total_Hours__c, RecordType.Name, StageName
                                            FROM Opportunity WHERE Name = 'Test Opportunity Calculations Change Order' LIMIT 1];

        
        testChangeOrderOppty.StageName = 'Closed Won';
        update testChangeOrderOppty;
        Test.stopTest();

        Opportunity assertChangeOrderOppty = [SELECT Id, Amount, PS_Hours__c, Total_Hours__c, Non_Lev_Opportunity_Hours__c, Non_Lev_Opportunity_Revenue__c, Lev_Opportunity_Hours__c, Lev_Opportunity_Revenue__c,
                                                    Change_Order_Revenue__c, Change_Order_Hours__c, Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c 
                                                FROM Opportunity WHERE Name = 'Test Opportunity Calculations Oppty' LIMIT 1];

        System.assertEquals(20, assertChangeOrderOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(4000, assertChangeOrderOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(5, assertChangeOrderOppty.Non_Lev_Change_Order_Hours__c, 'Non Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(1000, assertChangeOrderOppty.Non_Lev_Change_Order_Revenue__c, 'Non Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(10, assertChangeOrderOppty.Lev_Opportunity_Hours__c, 'Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(1000, assertChangeOrderOppty.Lev_Opportunity_Revenue__c, 'Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(5, assertChangeOrderOppty.Change_Order_Lev_Hours__c, 'Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(500, assertChangeOrderOppty.Change_Order_Lev_Revenue__c, 'Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(10, assertChangeOrderOppty.Change_Order_Hours__c, 'Change Order Hours was calculated incorrectly');
        System.assertEquals(1500, assertChangeOrderOppty.Change_Order_Revenue__c, 'Change Order Revenue was calculated incorrectly');
        System.assertEquals(1, assertChangeOrderOppty.Number_of_Change_Orders__c, 'Number of Change Orders was calculated incorrectly');

    }

    /*@isTest
    static void updateChangeOrderFromClosedWon(){

        Opportunity testChangeOrderOppty = [SELECT Id, Amount, Total_Hours__c, RecordType.Name, StageName
                                            FROM Opportunity WHERE Name = 'Test Opportunity Calculations Change Order #2' LIMIT 1];

        Test.startTest();
        testChangeOrderOppty.StageName = 'Confirm Value with Power';
        update testChangeOrderOppty;
        Test.stopTest();

        Opportunity assertChangeOrderOppty = [SELECT Id, Amount, PS_Hours__c, Total_Hours__c, Non_Lev_Opportunity_Hours__c, Non_Lev_Opportunity_Revenue__c, Lev_Opportunity_Hours__c, Lev_Opportunity_Revenue__c,
                                                    Change_Order_Revenue__c, Change_Order_Hours__c, Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c 
                                                FROM Opportunity WHERE Name = 'Test Opportunity Calculations Oppty' LIMIT 1];

        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Change_Order_Hours__c, 'Non Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Change_Order_Revenue__c, 'Non Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Lev_Opportunity_Hours__c, 'Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Lev_Opportunity_Revenue__c, 'Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Lev_Hours__c, 'Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Lev_Revenue__c, 'Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Hours__c, 'Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Revenue__c, 'Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Number_of_Change_Orders__c, 'Number of Change Orders was calculated incorrectly');

    }

    @isTest
    static void changeOpptyFromCOtoParentOppty(){

        Opportunity testChangeOrderOppty = [SELECT Id, Amount, Total_Hours__c, RecordType.Name, StageName, RecordTypeId, Change_Orders__c
                                            FROM Opportunity WHERE Name = 'Test Opportunity Calculations Change Order #2' LIMIT 1];

        Test.startTest();
        testChangeOrderOppty.RecordTypeId = salesforceOpptyRT;
        testChangeOrderOppty.Opp_Amount_Distribution__c = '70% / 30%';
        update testChangeOrderOppty;
        Test.stopTest();

        Opportunity assertChangeOrderOppty = [SELECT Id, Amount, PS_Hours__c, Total_Hours__c, Non_Lev_Opportunity_Hours__c, Non_Lev_Opportunity_Revenue__c, Lev_Opportunity_Hours__c, Lev_Opportunity_Revenue__c,
                                                    Change_Order_Revenue__c, Change_Order_Hours__c, Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c 
                                                FROM Opportunity WHERE Name = 'Test Opportunity Calculations Oppty' LIMIT 1];

        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Opportunity_Hours__c, 'Non Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Opportunity_Revenue__c, 'Non Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Change_Order_Hours__c, 'Non Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Non_Lev_Change_Order_Revenue__c, 'Non Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Lev_Opportunity_Hours__c, 'Lev Opportunity Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Lev_Opportunity_Revenue__c, 'Lev Opportunity Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Lev_Hours__c, 'Lev Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Lev_Revenue__c, 'Lev Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Hours__c, 'Change Order Hours was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Change_Order_Revenue__c, 'Change Order Revenue was calculated incorrectly');
        System.assertEquals(0, assertChangeOrderOppty.Number_of_Change_Orders__c, 'Number of Change Orders was calculated incorrectly');

    }*/
}