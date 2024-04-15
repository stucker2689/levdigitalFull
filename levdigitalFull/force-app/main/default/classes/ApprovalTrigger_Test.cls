@isTest
public with sharing class ApprovalTrigger_Test {

    @TestSetup
    static void makeData(){
        
        User testUser = [SELECT Id, Name FROM User WHERE Name LIKE '%House%' LIMIT 1];
        Case newCase = new Case();
        newCase.Subject = 'Test Approvals Case';
        newCase.Status = 'New';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByName().get('Lev SOW').getRecordTypeId();
        newCase.Who_is_your_Manager__c = testUser.Id;
        insert newCase;
    }

    @isTest
    static void rollupValidatedApprovalRecords_OnInsert_Test(){
        Case testCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c 
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(0, testCase.Validated_Approval_Records__c, 'Validated Approval Records was not properly set as 0.');

        Test.startTest();
        Approvals__c testApproval = new Approvals__c();
        testApproval.Status__c = 'Approved';
        testApproval.Case__c = testCase.Id;
        testApproval.Approval_In_Process__c = false;
        insert testApproval;
        Test.stopTest();

        Case assertCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(1, assertCase.Validated_Approval_Records__c, 'Validated Approval Records was not properly rolled up after insert.');

            
    }

    @isTest
    static void rollupValidatedApprovalRecords_OnUpdate_Test(){
        Case testCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c 
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        Approvals__c testApproval = new Approvals__c();
        testApproval.Status__c = 'Not Started';
        testApproval.Case__c = testCase.Id;
        testApproval.Approval_In_Process__c = false;
        insert testApproval;

        Test.startTest();
        testApproval.Status__c = 'Approved';
        update testApproval;
        Test.stopTest();

        Case assertCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];
                            
        /*List<Approvals__c> approvalCheckList = new List<Approvals__c>();
        approvalCheckList = [SELECT Id, Name, Status__c, Case__r.Subject, Approval_In_Process__c FROM Approvals__c];
        for(Approvals__c app : approvalCheckList){
            System.debug('Approvals Check: ' + app);
        }*/

        System.assertEquals(1, assertCase.Validated_Approval_Records__c, 'Validated Approval Records was not properly rolled up after update.');

            
    }

    @isTest
    static void rollupApprovalRecordsInProcess_Test(){
        Case testCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c 
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(0, testCase.Approval_Records_In_Process__c, 'Approved Approval Records was not properly set as 0.');

        Test.startTest();
        Approvals__c testApproval = new Approvals__c();
        testApproval.Status__c = 'Under Review';
        testApproval.Case__c = testCase.Id;
        testApproval.Approval_In_Process__c = true;
        insert testApproval;
        Test.stopTest();

        Case assertCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.debug('Assert Case: ' + assertCase);

        System.assertEquals(1, assertCase.Approval_Records_In_Process__c, 'Approved Approval Records was not properly rolled up after insert.');

    }

    @isTest
    static void rollupTotalApprovalRecords_onInsert_Test(){
        Case testCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c 
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(2, testCase.Total_Approval_Records__c, 'Validated Approval Records was not properly set as 0.');

        Approvals__c testApproval1 = new Approvals__c();
        testApproval1.Status__c = 'Not Started';
        testApproval1.Case__c = testCase.Id;
        testApproval1.Approval_In_Process__c = true;

        Approvals__c testApproval2 = new Approvals__c();
        testApproval2.Status__c = 'Approved';
        testApproval2.Case__c = testCase.Id;
        testApproval2.Approval_In_Process__c = false;

        Approvals__c testApproval3 = new Approvals__c();
        testApproval3.Status__c = 'Not Started';
        testApproval3.Case__c = testCase.Id;
        testApproval3.Approval_In_Process__c = false;

        List<Approvals__c> approvalsInsertList = new List<Approvals__c>{testApproval1, testApproval2, testApproval3};
        insert approvalsInsertList;

        Case assertCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(5, assertCase.Total_Approval_Records__c, 'Total Approval Records was not properly rolled up after insert.');

    }

    @isTest
    static void rollupTotalApprovalRecords_onDelete_Test(){
        Case testCase = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c 
                            FROM Case 
                            WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(2, testCase.Total_Approval_Records__c, 'Validated Approval Records was not properly set as 0.');

        Approvals__c testApproval1 = new Approvals__c();
        testApproval1.Status__c = 'Not Started';
        testApproval1.Case__c = testCase.Id;
        testApproval1.Approval_In_Process__c = true;

        Approvals__c testApproval2 = new Approvals__c();
        testApproval2.Status__c = 'Approved';
        testApproval2.Case__c = testCase.Id;
        testApproval2.Approval_In_Process__c = false;

        Approvals__c testApproval3 = new Approvals__c();
        testApproval3.Status__c = 'Not Started';
        testApproval3.Case__c = testCase.Id;
        testApproval3.Approval_In_Process__c = false;

        List<Approvals__c> approvalsInsertList = new List<Approvals__c>{testApproval1, testApproval2, testApproval3};
        insert approvalsInsertList;

        Test.startTest();
        List<Approvals__c> approvalsDeleteList = new List<Approvals__c>{testApproval1, testApproval2};
        delete approvalsDeleteList;
        Test.stopTest();

        Case assertCaseAfterDelete = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                                        FROM Case 
                                        WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(3, assertCaseAfterDelete.Total_Approval_Records__c, 'Total Approval Records was not properly rolled up after delete');

        List<Approvals__c> allApprovalsList = [SELECT Id, Name FROM Approvals__c WHERE IsDeleted = true ALL ROWS]; 

        undelete allApprovalsList;

        Case assertCaseAfterUnDelete = [SELECT Id, Subject, Approval_Records_In_Process__c, Validated_Approval_Records__c, Total_Approval_Records__c
                                        FROM Case 
                                        WHERE Subject = 'Test Approvals Case' LIMIT 1];

        System.assertEquals(5, assertCaseAfterUnDelete.Total_Approval_Records__c, 'Total Approval Records was not properly rolled up after undelete');
    }
}