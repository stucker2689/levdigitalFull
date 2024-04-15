/**
 * Created by jmahapatra on 3/12/18.
 */

@IsTest
public with sharing class GdriveSyncTest {

    @isTest
    public static void processInovoicesTest()
    {
        Account ac = new Account();
        ac.name = 'test account';
        insert ac;

        Opportunity op = new Opportunity();
        op.AccountId = ac.Id;
        op.Name = 'Test Opp';
        op.SOW_Number__c='SOW-2018-40000';
        op.StageName = 'Finalize Contracts';
        op.CloseDate = Date.today();
        insert op;

        User c = [Select Id from User where FirstName='Adam' and LastName='Canova' limit 1];

        Project__c pr= new Project__c();
        pr.Account__c = ac.Id;
        pr.Opportunity__c = op.Id;
        pr.Name = 'Test Project';
        pr.Project_Manager__c = c.Id;
        insert pr;


        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GdriveSync.driveLogin();

        System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GdriveSync.JsonObj> searchDrive = GdriveSync.searchDrive(keyPair);
        System.assert(searchDrive.size()>0);
        System.debug('searchDrive: '+searchDrive);
        GdriveSync.processInovoices();

        Test.stopTest();
    }
    @isTest
    public static void processInovoicesTest_ApprovalError()
    {
        Account ac = new Account();
        ac.name = 'test account';
        insert ac;

        Opportunity op = new Opportunity();
        op.AccountId = ac.Id;
        op.Name = 'Test Opp';
        op.SOW_Number__c='SOW-2018-40000';
        op.StageName = 'Finalize Contracts';
        op.CloseDate = Date.today();
        insert op;

        User c = [Select Id from User where FirstName='Adam' and LastName='Canova' limit 1];

        Project__c pr= new Project__c();
        pr.Account__c = ac.Id;
        pr.Opportunity__c = op.Id;
        pr.Name = 'Test Project';
        //pr.Project_Manager__c = c.Id;
        insert pr;


        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GdriveSync.driveLogin();

        System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GdriveSync.JsonObj> searchDrive = GdriveSync.searchDrive(keyPair);
        System.assert(searchDrive.size()>0);
        System.debug('searchDrive: '+searchDrive);
        GdriveSync.processInovoices();

        Test.stopTest();
    }

    @isTest
    public static void processInovoicesTest_withDiffOpp()
    {
        Account ac = new Account();
        ac.name = 'test account';
        insert ac;

        Opportunity op = new Opportunity();
        op.AccountId = ac.Id;
        op.Name = 'Test Opp';
        op.SOW_Number__c='SOW-2018-40001';
        op.StageName = 'Finalize Contracts';
        op.CloseDate = Date.today();
        insert op;

        User c = [Select Id from User where FirstName='Adam' and LastName='Canova' limit 1];

        Project__c pr= new Project__c();
        pr.Account__c = ac.Id;
        pr.Opportunity__c = op.Id;
        pr.Name = 'Test Project';
        pr.Project_Manager__c = c.Id;
        insert pr;


        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GdriveSync.driveLogin();

        System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GdriveSync.JsonObj> searchDrive = GdriveSync.searchDrive(keyPair);
        System.assert(searchDrive.size()>0);
        System.debug('searchDrive: '+searchDrive);
        GdriveSync.processInovoices();

        Test.stopTest();
    }

    @isTest
    public static void processInovoicesTest_withInvoice()
    {
        Account ac = new Account();
        ac.name = 'test account';
        insert ac;

        Opportunity op = new Opportunity();
        op.AccountId = ac.Id;
        op.Name = 'Test Opp';
        op.SOW_Number__c='SOW-2018-40001';
        op.StageName = 'Finalize Contracts';
        op.CloseDate = Date.today();
        insert op;

        User c = [Select Id from User where FirstName='Adam' and LastName='Canova' limit 1];

        Project__c pr= new Project__c();
        pr.Account__c = ac.Id;
        pr.Opportunity__c = op.Id;
        pr.Name = 'Test Project';
        pr.Project_Manager__c = c.Id;
        insert pr;

        Invoice__c inv = new Invoice__c();
        inv.Name = 'Test Invoice';
        inv.Project__c = pr.Id;
        inv.Account__c = pr.Account__c;
        inv.ProjectManager__c = pr.Project_Manager__c;
        inv.InvoiceNum__c = '2018-12465';
        inv.Status__c = 'Draft';
        insert inv;


        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GdriveSync.driveLogin();
        System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GdriveSync.JsonObj> searchDrive = GdriveSync.searchDrive(keyPair);
        System.assert(searchDrive.size()>0);

        System.debug('searchDrive: '+searchDrive);
        GdriveSync.processInovoices();

        Test.stopTest();
    }

    @isTest
    public static void testEmail(){
        Test.startTest();
        try {
            Messaging.reserveSingleEmailCapacity(5000);
            GdriveSync.generateEmail('jmahapatra@levementum.com', 'Test Email', 'Test Subject');
        } catch(Exception ex) {
            system.debug(ex.getStackTraceString() + ' ' + ex.getMessage());
        }
        Test.stopTest();
    }
}