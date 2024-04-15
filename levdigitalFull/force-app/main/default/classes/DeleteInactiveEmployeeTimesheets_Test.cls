@isTest
private class DeleteInactiveEmployeeTimesheets_Test {

    @TestSetup
    static void makeData(){
        Account ptoTestAcccount = TestDataFactory.createAccount(false, 'Client');

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{ptoTestAcccount, levementumLLCAcct};
        insert testAccountList;

        Opportunity ptoTestOppty = TestDataFactory.createOpportunity(false, ptoTestAcccount.Id, 'Salesforce');
        ptoTestOppty.Name = 'Test PTO Oppty';
        ptoTestOppty.StageName = 'Closed Won';
        ptoTestOppty.Amount = 10000;
        ptoTestOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert ptoTestOppty;

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =: ptoTestOppty.Id LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:30882';
        update testProj;

        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id);
        con.Active__c = false;
        con.Term_Date__c = Date.newInstance(2022, 1, 1);
        insert con;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(true, con.Id);

    }

    @isTest
    static void testDeleteTimesheets(){
        
        Test.startTest();
        DeleteInactiveEmployeeTimesheetsBatch newDeleteBatch = new DeleteInactiveEmployeeTimesheetsBatch();
        Database.executeBatch(newDeleteBatch, 1000);  
        Test.stopTest();
    }
}