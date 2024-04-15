@isTest
public with sharing class OpptyContactRoleTriggerTest {
    
    private static String partnerContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

    @TestSetup
    static void createCase(){

        Account levInternalAccount = new Account();
        levInternalAccount.Name = 'Levementum LLC';
        insert levInternalAccount;

        Account testAccount = TestClassUtil.newSampleAccount();
        Opportunity testOppty = TestClassUtil.newSampleOpportunity(testAccount.Id, 'Test Oppty Contact Count Oppty');


        Contact testPartnerContact = new Contact();
        testPartnerContact.RecordTypeId = partnerContactRT;
        testPartnerContact.LastName = 'TestPartnerContact';
        testPartnerContact.FirstName = 'FirstName';
        testPartnerContact.Email = 'TestContact@levdigital.com';
        insert testPartnerContact;

        OpportunityContactRole newOpptyContactRole = new OpportunityContactRole();
        newOpptyContactRole.ContactId = testPartnerContact.Id;
        newOpptyContactRole.OpportunityId = testOppty.Id;
        newOpptyContactRole.Role = 'Cognizant - Other';
        insert newOpptyContactRole;

    }

    @isTest
    static void opptyContactRoleInsertTest(){

        Test.StartTest();
        Contact testCon = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE LastName = 'TestPartnerContact' LIMIT 1];
		Test.StopTest();

        //System.assertEquals(testCon.Total_Opportunities__c, 1, 'Total Opportunities not properly updated on Contact on insert');
    }

    @isTest
    static void opptyContactRoleUpdateTest(){

        Account testAcc = [SELECT Id FROM Account WHERE Name = 'testAccount' LIMIT 1];

        Contact ocrContact = [SELECT Id, Name FROM Contact WHERE LastName = 'TestPartnerContact' LIMIT 1];

        OpportunityContactRole testOCR = [SELECT Id, ContactId, OpportunityId, Role FROM OpportunityContactRole WHERE ContactId =: ocrContact.Id LIMIT 1];

        Contact testPartnerContactTwo = new Contact();
        testPartnerContactTwo.RecordTypeId = partnerContactRT;
        testPartnerContactTwo.LastName = 'TestPartnerContactTwo';
        testPartnerContactTwo.FirstName = 'FirstName';
        testPartnerContactTwo.Email = 'TestContactTwo@levdigital.com';
        insert testPartnerContactTwo;

        Test.StartTest();
        testOCR.ContactId = testPartnerContactTwo.Id;
        update testOCR;
        Test.StopTest();

        Contact testCon = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE LastName = 'TestPartnerContact' LIMIT 1];
        Contact testConTwo = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE LastName = 'TestPartnerContactTwo' LIMIT 1];

        //System.assertEquals(testCon.Total_Opportunities__c, 0, 'Total Opportunities not decressed properly on Contact');
        //System.assertEquals(testConTwo.Total_Opportunities__c, 1, 'Total Opportunities not added properly on Contact');
    }

    @isTest
    static void opptyContactRoleDeleteTest(){

        Contact ocrContact = [SELECT Id, Name FROM Contact WHERE LastName = 'TestPartnerContact' LIMIT 1];

        OpportunityContactRole testOCR = [SELECT Id, ContactId, OpportunityId, Role FROM OpportunityContactRole WHERE ContactId =: ocrContact.Id LIMIT 1];

        Contact testPartnerContactTwo = new Contact();
        testPartnerContactTwo.RecordTypeId = partnerContactRT;
        testPartnerContactTwo.LastName = 'TestPartnerContactTwo';
        testPartnerContactTwo.FirstName = 'FirstName';
        testPartnerContactTwo.Email = 'TestContactTwo@levdigital.com';
        insert testPartnerContactTwo;

        Opportunity testOpportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Oppty Contact Count Oppty'];

        OpportunityContactRole newOpptyContactRole = new OpportunityContactRole();
        newOpptyContactRole.ContactId = testPartnerContactTwo.Id;
        newOpptyContactRole.OpportunityId = testOpportunity.Id;
        newOpptyContactRole.Role = 'Cognizant - Client Partner';
        insert newOpptyContactRole;

        Test.StartTest();
        delete testOCR;
		Test.StopTest();

        Contact testCon = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE LastName = 'TestPartnerContact' LIMIT 1];

        //System.assertEquals(testCon.Total_Opportunities__c, 0, 'Total Opportunities not properly updated on Contact');

    }
}