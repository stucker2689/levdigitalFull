/*
* @author LevDigital
* @date 2019
*
* @group Cases
* @group-content ../../ApexDocContent/Cases.htm
*
* @description LevAuraCasesControllerTest apex coverage for LevAuraCasesController
*/
@IsTest
private with sharing class LevAuraCasesControllerTest {
    static Account acc;
    static Contact con;
    static Opportunity opp;
    static Project__c pro;
    /*******************************************************************************************************
    * @description retrieves all record types for a specific sobject and asserts
    * @return Returns void
    */
     @IsTest
    static void fetchRecordTypeValuesPickSuccess(){
        acc = TestClassUtil.newSampleAccount();
        acc.Name = 'Levementum LLC';
        update acc;       
        con = TestClassUtil.createContact(true, acc.Id);
        LevUtility.executeOppTriggers = false;
        opp =  TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp');
        pro = TestClassUtil.createProject(true,acc.Id, opp.Id);

        System.Test.startTest();
        LevAuraCasesController.CasesWrapper caseWrap = LevAuraCasesController.fetchRecordTypeValuesPick('Case',pro.Id,'Project');

        List<LevAuraCasesController.PickListOptions> options = caseWrap.pickListOptions;
        System.Assert(options.size() > 0);
        Project__c proj = caseWrap.proj;
        System.AssertEquals(pro.Id,proj.Id);
        System.Test.stopTest();
    }
    @IsTest
    static void fetchRecordTypeValuesPickChildSuccess(){
        acc = TestClassUtil.newSampleAccount();
        acc.Name = 'Levementum LLC';
        update acc;       
        con = TestClassUtil.createContact(true, acc.Id);
        LevUtility.executeOppTriggers = false;
        opp =  TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp');
        pro = TestClassUtil.createProject(true,acc.Id, opp.Id);

        System.Test.startTest();
        LevAuraCasesController.ChildWrapper childWrap = LevAuraCasesController.fetchRecordTypeValuesPickChild(pro.Id,'Work');
        List<LevAuraCasesController.PickListOptions> options = childWrap.pickListOptions;
        System.Assert(options.size() > 0);
        Project__c proj = childWrap.proj;
        System.AssertEquals(pro.Id,proj.Id);
        System.Assert(childWrap.objectName != Null);
        System.Assert(childWrap.objectLabel != Null);
        System.Test.stopTest();
    }
    /*******************************************************************************************************
    * @description calls Campaign Services Flowand asserts
    * @return Returns void
    */
     @IsTest
    static void campaignServicesSuccess(){
        acc = TestClassUtil.newSampleAccount();
        acc.Name = 'Levementum LLC';
        update acc;       
        con = TestClassUtil.createContact(true, acc.Id);
        LevUtility.executeOppTriggers = false;
        opp =  TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp');
        pro = TestClassUtil.createProject(true,acc.Id, opp.Id);
        Id projectTaskRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('LevProjectTask').getRecordTypeId();
        System.Test.startTest();

        String errorMessage = LevAuraCasesController.callCampaignFlow(pro.Id,projectTaskRecordTypeId, con.Name,'test');
        System.AssertEquals(null,errorMessage);
        System.Test.stopTest();
    }
}