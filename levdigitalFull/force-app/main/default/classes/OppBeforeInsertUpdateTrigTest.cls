@isTest
public with sharing class OppBeforeInsertUpdateTrigTest {

    /*Test insert and Update of Opportunity
    *Create User with First Name and Last Name
    *Have SOW and CO Number (May not need)
    *Work Logs
    *Create Opp with Record Type of Change Order with CO and SOW number
    *Change that SOW and CO Number on Change Order
    *Insert and Update Next Steps
    *Create Record Type of Salesforce and Fill out enough fields to be able to set Opp to Closed Won
    *Have Opp set to stage Veral/Finalize contracts with Total Hours, Invoice Payment Terms and Opp Amount filled
    *
    *
    */
    private static Id salesforceRecordType = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static Id changeOrderRecordType = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    @TestSetup
    static void testSetup(){

        OpportunitySettings__c opptySetting = new OpportunitySettings__c(SOWStages__c = 'Solution Definition, Confirm Value with Power, Verbal Approval (Negotiation), Finalize Contracts, Ready for Order, Closed Won',
                                                                            ChangeOrderStages__c = 'Solution Definition, Confirm Value with Power, Verbal Approval (Negotiation), Finalize Contracts, Ready for Order, Closed Won');
        insert opptySetting;

        Account newAccount = new Account();
        newAccount.Name = 'Test Account123';
        newAccount.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        //newAccount.MSA_Number__c = 'MSA_Test01';

        Account newCompanyAccount = new Account();
        newCompanyAccount.Name = 'Levementum LLC';

        List<Account> setupAccountInsertList = new List<Account>{newAccount, newCompanyAccount};
        insert setupAccountInsertList;

        Contact employee1 = new Contact();
        employee1.FirstName = 'Test2';
        employee1.LastName = 'Employee100';
        employee1.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee1.Email = 'temployee100@levdigital.com';
        employee1.Replicon_User_Number__c = 1;
        employee1.RepliconLoginName__c = 'temployee1';
        insert employee1;

        Opportunity parentOppty1 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        parentOppty1.Name = 'Test Opp';
        parentOppty1.StageName = 'Solution Definition';
        parentOppty1.AccountId = newAccount.Id;
        //parentOppty1.RecordTypeId = salesforceRecordType;
        parentOppty1.CloseDate = System.today().addDays(7);
        parentOppty1.Amount = 5500.00;
        parentOppty1.Program_Type__c = 'Campaign';
        parentOppty1.Start_Date__c = System.today().addDays(-7);
        parentOppty1.End_Date__c = System.today().addDays(7);
        parentOppty1.Do_Not_Create_Project__c = true;
        parentOppty1.Service__c = 'Program';
        parentOppty1.Change_Order_Revenue__c = 1000;
        parentOppty1.Total_Amount_Invoiced_to_Date__c = 100;
        parentOppty1.Payment_Terms__c = 'Time and Materials';
        parentOppty1.Payment_Schedule__c = 'Standard T&M Monthly';
        parentOppty1.Project_Terms__c = 'Time and Materials';
        parentOppty1.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        parentOppty1.SOW_Hyperlink__c = 'google.com';
        //parentOppty1.SOW_Number__C = 'SOW-2019-43891';
        //parentOppty1.CO_Number__c = 'CO-2019-40028';
        parentOppty1.Next_Steps__c = 'Take the next steps on the opportunity';
        parentOppty1.Signatures_Completed__c = true;
        parentOppty1.Opportunity_Accuracy_Validated__c = true;
        parentOppty1.Team_Retirement__c = 'Allyson Reagan';
        parentOppty1.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        parentOppty1.Managers_Notes__c = 'Initial Manager Notes';
        parentOppty1.RFP_Proposal__c = 'Yes';

        Opportunity parentOppty2 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        parentOppty2.Name = 'Test Parent Oppty 2';
        parentOppty2.StageName = 'Solution Definition';
        parentOppty2.AccountId = newAccount.Id;
        //parentOppty2.RecordTypeId = salesforceRecordType;
        parentOppty2.CloseDate = System.today().addDays(7);
        parentOppty2.Amount = 5500.00;
        parentOppty2.Program_Type__c = 'Campaign';
        parentOppty2.Start_Date__c = System.today().addDays(-7);
        parentOppty2.End_Date__c = System.today().addDays(7);
        parentOppty2.Do_Not_Create_Project__c = true;
        parentOppty2.Service__c = 'Program';
        parentOppty2.Change_Order_Revenue__c = 1000;
        parentOppty2.Total_Amount_Invoiced_to_Date__c = 100;
        parentOppty2.Payment_Terms__c = 'Time and Materials';
        parentOppty2.Payment_Schedule__c = 'Standard T&M Monthly';
        parentOppty2.Project_Terms__c = 'Time and Materials';
        parentOppty2.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        parentOppty2.SOW_Hyperlink__c = 'google.com';
        //parentOppty2.SOW_Number__C = 'SOW-2019-43891';
        //parentOppty2.CO_Number__c = 'CO-2019-40028';
        parentOppty2.Next_Steps__c = 'Take the next steps on the opportunity';
        parentOppty2.Signatures_Completed__c = true;
        parentOppty2.Opportunity_Accuracy_Validated__c = true;
        parentOppty2.Team_Retirement__c = 'Allyson Reagan';
        parentOppty2.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        parentOppty2.Managers_Notes__c = 'Initial Manager Notes';
        parentOppty2.RFP_Proposal__c = 'Yes';

        List<Opportunity> setupParentOpptyInsertList = new List<Opportunity>{parentOppty1, parentOppty2};
        insert setupParentOpptyInsertList;
        
        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, newAccount.Id, 'Change Order');
        changeOrderOppty.Name = 'Test CO';
        changeOrderOppty.StageName = 'Solution Definition';
        changeOrderOppty.AccountId = newAccount.Id;
        changeOrderOppty.Change_Orders__c = parentOppty1.Id;
        //changeOrderOppty.RecordTypeId = changeOrderRecordType;
        changeOrderOppty.CloseDate = System.today().addDays(7);
        changeOrderOppty.Amount = 5500.00;
        changeOrderOppty.Program_Type__c = 'Campaign';
        changeOrderOppty.Start_Date__c = System.today().addDays(-7);
        changeOrderOppty.End_Date__c = System.today().addDays(7);
        changeOrderOppty.Do_Not_Create_Project__c = true;
        changeOrderOppty.Service__c = 'Program';
        changeOrderOppty.Change_Order_Revenue__c = 1000;
        changeOrderOppty.Total_Amount_Invoiced_to_Date__c = 100;
        changeOrderOppty.Payment_Terms__c = 'Time and Materials';
        changeOrderOppty.Payment_Schedule__c = 'Standard T&M Monthly';
        changeOrderOppty.Project_Terms__c = 'Time and Materials';
        changeOrderOppty.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        changeOrderOppty.SOW_Hyperlink__c = 'google.com';
        changeOrderOppty.Latest_Work_Log__c = 'Working in progress';
        //changeOrderOppty.SOW_Number__C = 'SOW-2019-12345';
        //changeOrderOppty.CO_Number__c = 'CO-2019-40111';
        changeOrderOppty.Signatures_Completed__c = true;
        changeOrderOppty.Opportunity_Accuracy_Validated__c = true;
        changeOrderOppty.Team_Retirement__c = 'Allyson Reagan';
        changeOrderOppty.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        changeOrderOppty.RFP_Proposal__c = 'No';
        insert changeOrderOppty;
    }

    @isTest
    static void testNextSteps(){

        Opportunity testOpp = [SELECT Id, Name, Next_Steps__c, Next_Steps_Log__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Test.StartTest();
        testOpp.Next_Steps__c = 'Again take next steps but update the log as well';
        update testOpp;
        Test.StopTest();

    }

    @isTest
    static void testChangeOrder(){
        
        Opportunity testOpp = [SELECT Id, Name, Service__c, Program_Type__c, Opportunity_RecordType_Name__c, Next_Steps__c, Next_Steps_Log__c FROM Opportunity WHERE Name = 'Test CO' LIMIT 1];
        Opportunity testOpp2 = [SELECT Id, Name, Service__c, Program_Type__c, Opportunity_RecordType_Name__c, Next_Steps__c, Next_Steps_Log__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Opportunity testParentOpp2 = [SELECT Id, Name, Service__c, Program_Type__c, Opportunity_RecordType_Name__c, Next_Steps__c, Next_Steps_Log__c FROM Opportunity WHERE Name = 'Test Parent Oppty 2' LIMIT 1];

        System.debug('111111111111111 Test Opp Service: ' + testOpp.Service__c);
        System.debug('111111111111111 Test Opp 2 Service: ' + testOpp2.Service__c);
        System.debug('111111111111111 Test Parent Opp 2 Service: ' + testParentOpp2.Service__c);
        System.debug('111111111111111 Test Parent Opp 2 Service: ' + testParentOpp2.Program_Type__c);
        Test.StartTest();
        testOpp.StageName = 'Interested Prospect';
        testOpp.Payment_Terms__c = 'Time and Materials';
        testOpp.Amount = 100000.00;
        testOpp.Latest_Work_Log__c = 'Working in progress Again';
        update testOpp;

        testOpp.RecordTypeId = salesforceRecordType;
        update testOpp;

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, Service__c, Program_Type__c, RecordType.Name, Opportunity_RecordType_Name__c, Change_Orders__c, Change_Orders__r.Name, Change_Orders__r.Service__c
                    FROM Opportunity
                    WHERE Name IN ('Test CO', 'Test Opp', 'Test Parent Oppty 2') 
                    ORDER BY Name];

        for(Opportunity opp : opptyList){
            System.debug('Name: ' + opp.Name + ' Service: ' + opp.Service__c + ' Program Type: ' + opp.Program_Type__c + ' RecordType Formula Name: ' + opp.Opportunity_RecordType_Name__c + ' Oppty RT Name: ' + opp.RecordType.Name + ' Change Orders Name: ' + opp.Change_Orders__r.Name + ' Change Orders Service: ' + opp.Change_Orders__r.Service__c);
        }

        testOpp2.RecordTypeId= changeOrderRecordType;
        testOpp2.Change_Orders__c = testParentOpp2.Id;
        update testOpp2;

        opptyList = [SELECT Id, Name, Service__c, Program_Type__c, RecordType.Name, Opportunity_RecordType_Name__c, Change_Orders__c, Change_Orders__r.Name, Change_Orders__r.Service__c
                    FROM Opportunity
                    WHERE Name IN ('Test CO', 'Test Opp', 'Test Parent Oppty 2') 
                    ORDER BY Name];

                    System.debug('AFTER UPDATE!!!!!!!!!!!!!!!!!');
        for(Opportunity opp : opptyList){
            System.debug('Name: ' + opp.Name + ' Service: ' + opp.Service__c + ' Program Type: ' + opp.Program_Type__c + ' RecordType Formula Name: ' + opp.Opportunity_RecordType_Name__c + ' Oppty RT Name: ' + opp.RecordType.Name + ' Change Orders Name: ' + opp.Change_Orders__r.Name + ' Change Orders Service: ' + opp.Change_Orders__r.Service__c);
        }

        testOpp2.StageName = 'Interested Prospect';
        testOpp2.Amount = 100000.00;
        update testOpp2;
        Test.StopTest();


    }

    @isTest
    static void testManagerNotesWithoutList(){

        Opportunity testOpp = [SELECT Id, Name, Managers_Notes__c, Managers_Notes_Log__c FROM Opportunity WHERE Name = 'Test Opp'];

        Test.StartTest();
        testOpp.Managers_Notes__c = 'Manager Notes here that also update the Managers Notes Log Field';
        update testOpp;
        Test.StopTest();

    }

    @isTest
    static void testManagerNotesWithList(){

        Opportunity testOpp = [SELECT Id, Name, Managers_Notes__c, Managers_Notes_Log__c FROM Opportunity WHERE Name = 'Test Opp'];

        Test.StartTest();
        testOpp.Managers_Notes__c = '<ul><li>ALL OF IT IS A BULLET</li></ul>';
        update testOpp;
        Test.StopTest();

    }

}