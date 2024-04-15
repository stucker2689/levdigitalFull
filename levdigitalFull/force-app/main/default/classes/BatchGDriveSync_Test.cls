@istest
private class BatchGDriveSync_Test {

    private static testMethod void processInovoicesTest()
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
        
        List<Invoices_to_Process__c> inv = new List<Invoices_to_Process__c>();
        Invoices_to_Process__c invp = new Invoices_to_Process__c();
        inv.add(invp);
        insert inv;
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GoogleDriveRestService.driveLogin();

         System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GoogleDriveRestService.JsonObj> searchDrive = GoogleDriveRestService.searchDrive(keyPair);
        Database.BatchableContext bc;
        BatchGDriveSync bClass = new BatchGDriveSync();
        System.Iterator<GoogleDriveRestService.JsonObj> itrbl= (System.Iterator<GoogleDriveRestService.JsonObj> ) bClass.start( bc).iterator();
        List<GoogleDriveRestService.JsonObj> aScopeList = new List<GoogleDriveRestService.JsonObj>();
        while (itrbl.hasNext()) {
            aScopeList.add( (GoogleDriveRestService.JsonObj) itrbl.next());
        }
        bClass.execute(bc,inv);
        bClass.finish(bc);

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
        insert pr;

        List<Invoices_to_Process__c> inv = new List<Invoices_to_Process__c>();
        Invoices_to_Process__c invp = new Invoices_to_Process__c();
        inv.add(invp);
        insert inv;
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GoogleDriveRestService.driveLogin();
        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GoogleDriveRestService.JsonObj> searchDrive =GoogleDriveRestService.searchDrive(keyPair);
        Database.BatchableContext bc;
        BatchGDriveSync bClass = new BatchGDriveSync();
        System.Iterator<GoogleDriveRestService.JsonObj> itrbl= (System.Iterator<GoogleDriveRestService.JsonObj> ) bClass.start( bc).iterator();
        List<GoogleDriveRestService.JsonObj> aScopeList = new List<GoogleDriveRestService.JsonObj>();
        while (itrbl.hasNext()) {
            aScopeList.add( (GoogleDriveRestService.JsonObj) itrbl.next());
        }

        bClass.execute(bc,inv);
        bClass.finish(bc);
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
        
        List<Invoices_to_Process__c> inv = new List<Invoices_to_Process__c>();
        Invoices_to_Process__c invp = new Invoices_to_Process__c();
        inv.add(invp);
        insert inv;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GoogleDriveRestService.driveLogin();
        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GoogleDriveRestService.JsonObj> searchDrive =GoogleDriveRestService.searchDrive(keyPair);
        Database.BatchableContext bc;
        BatchGDriveSync bClass = new BatchGDriveSync();
        System.Iterator<GoogleDriveRestService.JsonObj> itrbl= (System.Iterator<GoogleDriveRestService.JsonObj> ) bClass.start( bc).iterator();
        List<GoogleDriveRestService.JsonObj> aScopeList = new List<GoogleDriveRestService.JsonObj>();
        while (itrbl.hasNext()) {
            aScopeList.add( (GoogleDriveRestService.JsonObj) itrbl.next());
        }

        bClass.execute(bc,inv);
        bClass.finish(bc);
        List<Invoice__c> invs = [SELECT Id, Name, Status__c,InvoiceNum__c,Project__c,Project__r.Opportunity__r.SOW_Number__c,Project__r.Opportunity__c,
                Project__r.Opportunity__r.accountId,Project__r.Opportunity__r.account.Name FROM Invoice__c WHERE Project__r.Opportunity__r.accountId =: ac.Id];
        system.debug('*invs ' + invs.size());
        system.assertEquals(invs.size(),0);
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
        
        List<Invoices_to_Process__c> invsp = new List<Invoices_to_Process__c>();
        Invoices_to_Process__c invp = new Invoices_to_Process__c();
        invsp.add(invp);
        insert invsp;

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GoogleDriveRestService.driveLogin();
        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        List<GoogleDriveRestService.JsonObj> searchDrive =GoogleDriveRestService.searchDrive(keyPair);
        Database.BatchableContext bc;
        BatchGDriveSync bClass = new BatchGDriveSync();
        System.Iterator<GoogleDriveRestService.JsonObj> itrbl= (System.Iterator<GoogleDriveRestService.JsonObj> ) bClass.start( bc).iterator();
        List<GoogleDriveRestService.JsonObj> aScopeList = new List<GoogleDriveRestService.JsonObj>();
        while (itrbl.hasNext()) {
            aScopeList.add( (GoogleDriveRestService.JsonObj) itrbl.next());
        }

        bClass.execute(bc,invsp);
        bClass.finish(bc);
        List<Invoice__c> invs = [SELECT Id, Name, Status__c,InvoiceNum__c,Project__c,Project__r.Opportunity__r.SOW_Number__c,Project__r.Opportunity__c,
                Project__r.Opportunity__r.accountId,Project__r.Opportunity__r.account.Name FROM Invoice__c WHERE Project__r.Opportunity__r.accountId =: ac.Id];
        system.debug('*invs ' + invs.size());
        system.assertEquals(invs.size(),1);
        
        bClass.generateEmail('test456123123@levementum.com','Test Email','Test Subject');
        Test.stopTest();
    }

    private static testMethod void processInovoicesMoreThanOneTest()
    {

        List<Account> acs = new List<Account>();
        Account ac1 = new Account(name = 'test account1');
        Account ac2 = new Account(name = 'test account2');
        Account ac3 = new Account(name = 'test account3');
        acs.add(ac1);
        acs.add(ac2);
        acs.add(ac3);
        insert acs;

        List<Opportunity> opps = new List<Opportunity>();
        Opportunity op1 = new Opportunity(AccountId = ac1.Id,Name = 'Test Opp1',SOW_Number__c='SOW-2018-40000',StageName = 'Finalize Contracts',CloseDate = Date.today());
        Opportunity op2 = new Opportunity(AccountId = ac2.Id,Name = 'Test Opp2',SOW_Number__c='SOW-2018-40001',StageName = 'Finalize Contracts',CloseDate = Date.today());
        Opportunity op3 = new Opportunity(AccountId = ac3.Id,Name = 'Test Opp3',SOW_Number__c='SOW-2018-40002',StageName = 'Finalize Contracts',CloseDate = Date.today());
        opps.add(op1);
        opps.add(op2);
        opps.add(op3);
        insert opps;

        User c = [Select Id from User where FirstName='Adam' and LastName='Canova' limit 1];

        List<Project__c> projs = new List<Project__c>();
        Project__c pr1= new Project__c(Account__c = ac1.Id,Opportunity__c = op1.Id,Name = 'Test Project1',Project_Manager__c = c.Id);
        Project__c pr2= new Project__c(Account__c = ac1.Id,Opportunity__c = op2.Id,Name = 'Test Project2',Project_Manager__c = c.Id);
        Project__c pr3= new Project__c(Account__c = ac1.Id,Opportunity__c = op3.Id,Name = 'Test Project3',Project_Manager__c = c.Id);
        projs.add(pr1);
        projs.add(pr2);
        projs.add(pr3);
        insert projs;
        
        List<Invoices_to_Process__c> inv = new List<Invoices_to_Process__c>();
        Invoices_to_Process__c invp = new Invoices_to_Process__c();
        inv.add(invp);
        insert inv;
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'));
        Map<String,String> keyPair = GoogleDriveRestService.driveLogin();

        System.assertEquals(keyPair.get('access_token'),'HelloWorld!!!');

        //Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files":[{"kind":"drive#file","id":"1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name":"Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType":"application/pdf"},{"kind":"drive#file","id":"1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqO","name":"Comtech SOW-2018-40001 Inv 2018-12466.pdf","mimeType":"application/pdf"},{"kind":"drive#file","id":"1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqP","name":"Comtech SOW-2018-40002 Inv 2018-12467.pdf","mimeType":"application/pdf"}]}'));
        List<GoogleDriveRestService.JsonObj> searchDrive =GoogleDriveRestService.searchDrive(keyPair);
        Database.BatchableContext bc;
        BatchGDriveSync bClass = new BatchGDriveSync();
        //bClass.NumTstfiles = 3;
        System.Iterator<GoogleDriveRestService.JsonObj> itrbl= (System.Iterator<GoogleDriveRestService.JsonObj> ) bClass.start( bc).iterator();
        List<GoogleDriveRestService.JsonObj> aScopeList = new List<GoogleDriveRestService.JsonObj>();
        while (itrbl.hasNext()) {
            aScopeList.add( (GoogleDriveRestService.JsonObj) itrbl.next());
        }
        bClass.execute(bc,inv);
        bClass.finish(bc);

        Test.stopTest();
    }
}