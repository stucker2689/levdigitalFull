@IsTest
public with sharing class InternalOpsKanbanControllerTest {
    private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();
    private static String internalEmployeeContactRT = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    private static String caseId;
    private static String sprintPlanWeekRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Week').getRecordTypeId();
    private static String sprintPlanMonthRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Month').getRecordTypeId();
    private static String sprintPlanQuarterRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Quarter').getRecordTypeId();
    
    @testSetup
    static void setupData() {
        Account levInternalAccount = new Account();
        levInternalAccount.Name = 'Levementum LLC';
        insert levInternalAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'TestContact';
        testContact.FirstName = 'FirstName';
        testContact.RecordTypeId = internalEmployeeContactRT;
        testContact.Email = 'TestContact@levdigital.com';
        insert testContact;
    
        Case testCase = new Case();
        testCase.RecordTypeId = internalCaseRT;
        testCase.Subject = 'Test Case for Kanban';
        testCase.Type = 'Ops Management';
        testCase.Status = 'In Process';
        testCase.Start_Date__c = Date.today();
        testCase.Due_Date_Internal__c = Date.today().addDays(14);
        testCase.Internal_Ops_Estimated_Hours__c = 10;
        testCase.Primary_Department__c = 'Sales';
        testCase.ContactId = testContact.Id;
        testCase.Rollout_Needed__c = 'No';

        Case testCase2 = new Case();
        testCase2.RecordTypeId = internalCaseRT;
        testCase2.Subject = 'Test Case for Kanban WRONG TYPE';
        testCase2.Type = 'IT Support';
        testCase2.Status = 'In Process';
        testCase2.Start_Date__c = Date.today();
        testCase2.Due_Date_Internal__c = Date.today().addDays(14);
        testCase2.Internal_Ops_Estimated_Hours__c = 10;
        testCase2.Primary_Department__c = 'Sales';
        testCase2.ContactId = testContact.Id;
        testCase.Rollout_Needed__c = 'No';
        
        List<Case> caseList = new List<Case>{testCase, testCase2};
        insert caseList;
    }

    @isTest
    static void getInternalCasesTest(){
        List<Case> assertCaseList = new List<Case>();
        Test.startTest();
        assertCaseList = InternalOpsKanbanController.getInternalCasesForStatusKanban();
        Test.stopTest();
        System.debug('assertCaseList: ' + assertCaseList);
        //System.assertEquals(1, assertCaseList.size(), 'Wrong number of Cases returned for Kanban Status View');
    }

    @isTest
    static void getSprintPlanWeeksTest(){
        List<Sprint_Plan__c> assertSprintPlanList = new List<Sprint_Plan__c>();

        Test.startTest();
        assertSprintPlanList = InternalOpsKanbanController.getSprintWeekPlansForWeekKanban();
        Test.stopTest();

        System.assertNotEquals(0, assertSprintPlanList.size(), 'Wrong number of Sprint Plans returned for Kanban Sprint Week View');
    }

    @isTest
    static void getSprintPlanMonthsTest(){
        List<Sprint_Plan__c> assertSprintPlanList = new List<Sprint_Plan__c>();

        Test.startTest();
        assertSprintPlanList = InternalOpsKanbanController.getSprintMonthPlansForMonthKanban();
        Test.stopTest();

        System.assertNotEquals(0, assertSprintPlanList.size(), 'Wrong number of Sprint Plans returned for Kanban Sprint Month View');
    }

    @isTest
    static void getSprintPlanQuartersTest(){
        List<Sprint_Plan__c> assertSprintPlanList = new List<Sprint_Plan__c>();

        Test.startTest();
        assertSprintPlanList = InternalOpsKanbanController.getSprintQuarterPlansForQuarterKanban();
        Test.stopTest();

        System.assertNotEquals(0, assertSprintPlanList.size(), 'Wrong number of Sprint Plans returned for Kanban Sprint Quarter View');
    }

    @IsTest
    static void updateObjectTest(){
        
        Case testCase = [SELECT Id, Subject, Status FROM Case WHERE Subject = 'Test Case for Kanban' LIMIT 1];

        Test.startTest();
        InternalOpsKanbanController.updateRec(testCase.Id, 'Status', 'On Hold');
        Test.stopTest();


    }
}