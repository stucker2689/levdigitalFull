@isTest
public class AccountBeforeInsertUpdateTest {

    @isTest
    static void testAccountWorkLogsAndLatestUpdate_OnInsert(){
        Account acct1 = TestDataFactory.createAccount(false, 'Client');
        acct1.Name = 'Test Client Account 1';
        acct1.Acct_Latest_Updt__c = 'Account Latest Update Insert';
        acct1.Latest_Work_Log__c = 'Latest Work Log Insert';

        System.Test.startTest();
        insert acct1;
        System.Test.stopTest();

        Account validateAccount = [SELECT Id, Name, Latest_Work_Log__c, Acct_Latest_Updt__c, Account_Updates_Log__c, Work_Logs__c FROM Account WHERE Name = 'Test Client Account 1' LIMIT 1];
        System.assertNotEquals(null, validateAccount.Account_Updates_Log__c, 'Account Updates Log not properly Populated on Account on Insert');
        System.assertNotEquals(null, validateAccount.Work_Logs__c, 'Work Log not properly Populated on Account on Insert');

    }

    @isTest
    static void testAccountWorkLogsAndLatestUpdate_OnUpdate(){
        Account acct1 = TestDataFactory.createAccount(false, 'Client');
        acct1.Name = 'Test Client Account 1';
        insert acct1;

        System.Test.startTest();
        acct1.Latest_Work_Log__c = 'Latest Work Log Update';
        acct1.Acct_Latest_Updt__c = 'Account Latest Update';
        update acct1;
        System.Test.stopTest();

        Account validateAccount = [SELECT Id, Name, Latest_Work_Log__c, Acct_Latest_Updt__c, Account_Updates_Log__c, Work_Logs__c FROM Account WHERE Name = 'Test Client Account 1' LIMIT 1];
        System.assertNotEquals(null, validateAccount.Account_Updates_Log__c, 'Account Updates Log not properly Populated on Account on Update');
        System.assertNotEquals(null, validateAccount.Work_Logs__c, 'Work Log not properly Populated on Account on Update');
    }


}