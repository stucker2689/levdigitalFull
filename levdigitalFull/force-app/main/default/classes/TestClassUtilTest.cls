@IsTest
public with sharing class TestClassUtilTest {

    @isTest
    public static void testAllTestClassUtil(){
        Account levAccount = new Account();
        levAccount.Name = 'Levementum LLC';
        levAccount.PrimaryPractice__c = 'Salesforce';
        insert levAccount;
        Account acct = TestClassUtil.newSampleAccount();
        Opportunity opp = TestClassUtil.newSampleOpportunity(acct.Id, 'TestUtilClass Oppty');
        Project__c proj = TestClassUtil.createProject(true, acct.Id,opp.Id);
        Contact cont = TestClassUtil.createContact(true, acct.Id);
        RepliconForecast__c repFore = TestClassUtil.createForecast(true, 'Test Replicon Forecast', proj.Id);
        Project__c retrievedProj = TestClassUtil.getProjectforOpp(opp.Id);
        Replicon_Timesheet__c repTimesheet = TestClassUtil.createTimesheet(true, cont.Id);
        Replicon_Time_Entry__c repTimeEntry = TestClassUtil.createTimeEntry(true, repTimesheet.Id, cont.Id, proj);
    }
}