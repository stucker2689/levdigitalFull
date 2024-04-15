@isTest
private class UpdateNewCaseFieldsBatch_Test {

    private static String internalEmployeeContactRT = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();
    

    @TestSetup
    static void makeData(){
        Account levInternalAccount = new Account();
        levInternalAccount.Name = 'Levementum LLC';
        insert levInternalAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'TestContact';
        testContact.FirstName = 'FirstName';
        testContact.RecordTypeId = internalEmployeeContactRT;
        testContact.Email = 'TestContact@levdigital.com';
        insert testContact;

        Case testCaseOne = new Case();
        testCaseOne.RecordTypeId = internalCaseRT;
        testCaseOne.Subject = 'Test Case One';
        testCaseOne.ContactId = testContact.Id;
        testCaseOne.Internal_Ops_Estimated_Hours__c = 100;
        testCaseOne.Due_Date_Internal__c = Date.today().addDays(14);
        testCaseOne.Start_Date__c = Date.today();  
        testCaseOne.Rollout_Needed__c = 'Yes'; 
        testCaseOne.Status = 'Completed';

        Case testCaseTwo = new Case();
        testCaseTwo.RecordTypeId = internalCaseRT;
        testCaseTwo.Subject = 'Test Case Two';
        testCaseTwo.ContactId = testContact.Id;
        testCaseTwo.Internal_Ops_Estimated_Hours__c = 70;
        testCaseTwo.Start_Date__c = Date.valueOf('2022-05-27');
        testCaseTwo.Due_Date_Internal__c = Date.valueOf('2022-07-08');

        List<Case> caseList = new List<Case>{testCaseOne, testCaseTwo};
        insert caseList;

        testCaseOne.DueDateEntered__c = false;
        testCaseOne.DeploymentCompletionDate__c = null;
        testCaseOne.ChangeManagementDueDate__c = null;
        testCaseOne.CaseCompletionDueDate__c = null;
        update testCaseOne;


    }

    @isTest
    static void updateCaseFields_test(){



        Test.startTest();
        UpdateNewCaseFieldsBatch newBatch = new UpdateNewCaseFieldsBatch();
        Database.executeBatch(newBatch, 25);
        Test.stopTest();
    }

}