@isTest
public with sharing class WinzoneChangeOrderConversionBatch_Test {

    @testSetup
    static void makeData(){
        List<Account> testAccountInsertList = new List<Account>();
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        testAccountInsertList.add(levementumLLCAcct);

        //Create Test Client Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        testAccountInsertList.add(acct);

        //Insert Both Accounts
        insert testAccountInsertList;

        List<Opportunity> testOpportunityInsertList = new List<Opportunity>();
        //Create Test Oppty associated with the Client Account
        Opportunity oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'Test Oppty 1';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Won';
        oppo.Peoplesoft_Project_Id__c = '11111111';
        //oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        testOpportunityInsertList.add(oppo);

        Opportunity opptyToConvert = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        opptyToConvert.Name = 'Test Oppty to Convert';
        opptyToConvert.Number_of_Contact_Rolls_Added__c = 1;
        opptyToConvert.Number_of_Products__c = 1;
        opptyToConvert.StageName = '1. Engagement';
        opptyToConvert.WZRelatedOpportunityId__c = '11111111';
        testOpportunityInsertList.add(opptyToConvert);

        insert testOpportunityInsertList;

        Opportunity undoFlowConversionOppty = [SELECT Id, Name, RecordTypeId, RecordType.Name, WZRelatedOpportunityId__c, Change_Orders__c
                                                FROM Opportunity
                                                WHERE Name = 'Test Oppty to Convert'
                                                LIMIT 1];

        undoFlowConversionOppty.RecordTypeId = '012d0000000kcjgAAA';
        undoFlowConversionOppty.Change_Orders__c = null;
        update undoFlowConversionOppty;
    }

    @isTest
    static void convertWZOpptyToChangeOrder_Test(){

        Opportunity testCOConversionOpptyBefore = [SELECT Id, Name, RecordTypeId, RecordType.Name, WZRelatedOpportunityId__c, Change_Orders__c
                                                    FROM Opportunity
                                                    WHERE Name = 'Test Oppty to Convert'
                                                    LIMIT 1];

        System.assertEquals(testCOConversionOpptyBefore.RecordType.Name, 'Salesforce', 'Test Opportunity was not properly set as a Salesforce Opportunity before Test batch run');
        System.assertEquals(testCOConversionOpptyBefore.Change_Orders__c, null, 'Test Opportunity was not properly set up to have no related Parent Opportunity');

        Test.startTest();
        WinzoneChangeOrderConversionBatch winzoneChangeOrderConversionCheck = new WinzoneChangeOrderConversionBatch(false);
        Database.executeBatch(winzoneChangeOrderConversionCheck, 5);
        Test.stopTest();

        Opportunity testCOConversionOpptyAfter = [SELECT Id, Name, RecordTypeId, RecordType.Name, WZRelatedOpportunityId__c, Change_Orders__c, Change_Orders__r.Name
                                                    FROM Opportunity
                                                    WHERE Name = 'Test Oppty to Convert'
                                                    LIMIT 1];

        System.assertEquals(testCOConversionOpptyAfter.RecordType.Name, 'Change Order', 'Test Opportunity was not properly set as a Change Order Opportunity after batch run');
        System.assertNotEquals(testCOConversionOpptyAfter.Change_Orders__c, null, 'Opportunity did not properly get a Parent Opportunity assigned after batch run');
    }

    @isTest
    static void convertWZOpptyToChangeOrderCreatedToday_Test(){

        Opportunity testCOConversionOpptyBefore = [SELECT Id, Name, RecordTypeId, RecordType.Name, WZRelatedOpportunityId__c, Change_Orders__c
                                                    FROM Opportunity
                                                    WHERE Name = 'Test Oppty to Convert'
                                                    LIMIT 1];

        System.assertEquals(testCOConversionOpptyBefore.RecordType.Name, 'Salesforce', 'Test Opportunity was not properly set as a Salesforce Opportunity before Test batch run');
        System.assertEquals(testCOConversionOpptyBefore.Change_Orders__c, null, 'Test Opportunity was not properly set up to have no related Parent Opportunity');

        Test.startTest();
        WinzoneChangeOrderConversionBatch winzoneChangeOrderConversionCheck = new WinzoneChangeOrderConversionBatch(true);
        Database.executeBatch(winzoneChangeOrderConversionCheck, 5);
        Test.stopTest();

        Opportunity testCOConversionOpptyAfter = [SELECT Id, Name, RecordTypeId, RecordType.Name, WZRelatedOpportunityId__c, Change_Orders__c, Change_Orders__r.Name
                                                    FROM Opportunity
                                                    WHERE Name = 'Test Oppty to Convert'
                                                    LIMIT 1];

        System.assertEquals(testCOConversionOpptyAfter.RecordType.Name, 'Change Order', 'Test Opportunity was not properly set as a Change Order Opportunity after batch run');
        System.assertNotEquals(testCOConversionOpptyAfter.Change_Orders__c, null, 'Opportunity did not properly get a Parent Opportunity assigned after batch run');
    }

    @isTest
    static void scheduleWZChangeOrderConversionBatch_Test(){
        String cronExpr = '0 0 0/3 1/1 * ? *';
        Test.startTest();
        WinzoneChangeOrderConversionBatch newTestScheduler = new WinzoneChangeOrderConversionBatch(true);
        String jobId = System.schedule('WinzoneChangeOrderConversionBatch Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }
}