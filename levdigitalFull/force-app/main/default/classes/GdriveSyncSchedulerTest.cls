/**
 * Created by jmahapatra on 3/16/18.
 * Perfected by wfrohwein on 8/28/18.
 */

@IsTest
private class GdriveSyncSchedulerTest {

//    public static testMethod void testExecute() {
//
//        Test.setMock(HttpCalloutMock.class, new MockGSyncHttpResponseGenerator('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "Comtech SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'));
//
//        Test.startTest();
//
//        GdriveSyncScheduler sync = new GdriveSyncScheduler();
//        String cronTriggerId = System.schedule('Test Scheduler', '0 5 * * * ?', sync);
//
//        Test.stopTest();
//
//        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :Id.valueOf(cronTriggerId)];
//        System.assert(ct != null);
//        System.assertEquals(ct.State, 'WAITING');
//    }

    @testSetup static void setData() {
        String accountName = 'Comtech';

        Account acc = new Account(
                Name = accountName
        );
        insert acc;

        LevUtility.executeOppTriggers = false;

        Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                SOW_Number__c = 'SOW-2018-40000',
                CloseDate = System.today(),
                StageName = 'Closed Won',
                Name = 'Test Opp',
                Do_Not_Create_Project__c = true
        );
        insert opp;
        
        Project__c pro = new Project__c();
        pro.Name = 'Test2';
        pro.Opportunity__c = opp.Id;
        pro.Account__c = acc.id;
        insert pro;

        Invoices_to_Process__c itp = new Invoices_to_Process__c(
                Kind__c = 'drive#file',
                ID__c = '1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM',
                Filename__c = accountName+' SOW-2018-40000 inv 2018-12465.pdf',
                MimeType__c = 'application/pdf',
                Status__c = 'Unprocessed'
        );
        insert itp;
    }

    public static testMethod void testExecuteLongAccountName() {
        MockGSyncHttpResponseGenerator mock = new MockGSyncHttpResponseGenerator();
        mock.add('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'); // login response
        //mock.add('{"files": [{"kind": "drive#file","id": "1LJHnof-x17Gyxb5DQO_-bfAi7PG1FCqM","name": "'+accountName+' SOW-2018-40000 Inv 2018-12465.pdf","mimeType": "application/pdf"}]}'); // search files response
        //mock.add('{"access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'); // login response again?
        mock.add(Blob.valueOf('This is a test blob')); // getDriveFileContent response
        mock.add('deleted'); // deleteFilefromGDrive response, body doesnt matter. Nothign done with it



//        GdriveSyncScheduler sync = new GdriveSyncScheduler();
//        String cronTriggerId = System.schedule('Test Scheduler', '0 5 * * * ?', sync);

//        List<GooleDriveSync__mdt> keyVals = [
//                SELECT DeveloperName,Value__c
//                FROM GooleDriveSync__mdt
//                WHERE DeveloperName = 'BatchSize'
//        ] ;
//
//        String BatchSize = '';
//
//        if (keyVals.size() > 0) {
//            BatchSize = keyVals[0].Value__c;
//        } else {
//            BatchSize = '10';
//        }

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, mock);

        //Database.executeBatch(new BatchGDriveSync(), Integer.valueOf(BatchSize));
        Database.executeBatch(new BatchGDriveSync(), 3);

        Test.stopTest();

//        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :Id.valueOf(cronTriggerId)];
//        System.assert(ct != null);
//        System.assertEquals(ct.State, 'WAITING');
    }
    
    public static testMethod void testEmail() {
        Test.startTest();
        	BatchGDriveSync batch = new BatchGDriveSync();
        	batch.generateEmail('test@test.com', 'TEST', 'TEST');
        	batch.processWarnings(null, 'test', 'WARN', 'TEST');
        	batch.processContentDocumentLinks(new Invoice__c(), new ContentVersion());
        Test.stopTest();
    }
    
    public static testMethod void testNewBatchConstructor() {
        MockGSyncHttpResponseGenerator mock = new MockGSyncHttpResponseGenerator();
        mock.add('{"folder_id":"789uihiu", "access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'); // login response
        mock.add(Blob.valueOf('This is a test blob')); // getDriveFileContent response
        mock.add('deleted'); // deleteFilefromGDrive response, body doesnt matter. Nothign done with it
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
			GdriveInvoiceScheduler sh1 = new GdriveInvoiceScheduler();
			String sch = '0 0 23 * * ?';
        	system.schedule('GDrive Scheduler', sch, sh1);
        Test.stopTest();
    }
    
    public static testMethod void testMoreThanOneInvoice() {
        
        Account acc1 = new Account(
                Name = 'Acc Test'
        );
        insert acc1;

        Opportunity opp1 = new Opportunity(
                AccountId = acc1.Id,
                SOW_Number__c = 'SOW-2018-40001',
                CloseDate = System.today(),
                StageName = 'Closed Won',
                Name = 'Test Opp2',
                Do_Not_Create_Project__c = true
        );
        insert opp1;
        
        Project__c pro1 = new Project__c();
        pro1.Name = 'Test22';
        pro1.Opportunity__c = opp1.Id;
        pro1.Account__c = acc1.id;
        insert pro1;
        
        List<Invoice__c> invoices = new List<Invoice__c>();
        Invoice__c inv = new Invoice__c();
        inv.Name = 'Test001';
        inv.InvoiceNum__c = '2018-12465';
        inv.Project__c = pro1.Id;
        inv.Account__c = acc1.Id;
        invoices.add(inv);
        
        Invoice__c inv2 = new Invoice__c();
        inv2.Name = 'Test002';
        inv2.InvoiceNum__c = '2018-40000';
        inv2.Project__c = pro1.Id;
        inv2.Account__c = acc1.Id;
        invoices.add(inv2);
        
        insert invoices;
        
        MockGSyncHttpResponseGenerator mock = new MockGSyncHttpResponseGenerator();
        mock.add('{"folder_id":"789uihiu", "access_token": "HelloWorld!!!","token_type": "Bearer","expires_in": 3600}'); // login response
        mock.add(Blob.valueOf('This is a test blob')); // getDriveFileContent response
        mock.add('deleted'); // deleteFilefromGDrive response, body doesnt matter. Nothign done with it
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
			GdriveInvoiceScheduler sh1 = new GdriveInvoiceScheduler();
			String sch = '0 0 23 * * ?';
        	system.schedule('GDrive Scheduler', sch, sh1);
        Test.stopTest();
    }
}