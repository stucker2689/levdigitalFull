@isTest
public class TestOppAgreeAfterInsertUpdate {
    public static testmethod void testInsert() {
        echosign_dev1__SIGN_Agreement__c echo = new echosign_dev1__SIGN_Agreement__c();
        insert echo;
        
        Account acc = new Account(
                Name = 'TEST'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                SOW_Number__c = 'SOW-2018-40000',
                CloseDate = System.today(),
                StageName = 'Closed Won',
                Name = 'Test Opp',
                Do_Not_Create_Project__c = true
        );
        insert opp;
    }
}