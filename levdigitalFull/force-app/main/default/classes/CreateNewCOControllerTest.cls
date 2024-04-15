/**
* @author LevDigital
* @date 2019
*
* @group Opportunities
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description CreateNewCOControllerTest - apex coverage for CreateNewCOController
*/


@IsTest
private with sharing class CreateNewCOControllerTest {
    /*******************************************************************************************************
    * @description Successfully creates existing information from Related Opportunity
    * @return Returns void
    */
    @IsTest
    static void createNewChangeOrderSuccess(){

        Account  acct= TestClassUtil.newSampleAccount();
        Opportunity opp = TestClassUtil.newSampleOpportunity(Acct.Id, 'oppname');
        System.Test.startTest();
        Id coRecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Change_Order').getRecordTypeId(); 
        CreateNewCOController.ChangeOrder co = CreateNewCOController.getChangeOrderRecordId(opp.Id);
        System.AssertEquals(acct.Id,co.accountId); 
        System.AssertEquals(coRecordTypeId,co.recordTypeId); 
        System.Test.stopTest();
    }
}