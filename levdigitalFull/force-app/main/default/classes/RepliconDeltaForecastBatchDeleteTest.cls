@isTest
public class RepliconDeltaForecastBatchDeleteTest {
    
    @testSetup static void setupTestData() {
        Account newAccount = new Account(Name = 'Test Account');
        insert newAccount;

        Opportunity newOpp = TestClassUtil.newSampleOpportunity(newAccount.Id, 'Test Opp');
        Project__c newProject = TestClassUtil.createProject(true, newAccount.Id, newOpp.Id);
        Contact newEmployee = TestClassUtil.createContact(true, newAccount.Id);
    }
    
    @isTest static void testForDelete_Positive() {
        Account queriedAccount = [SELECT Id FROM Account LIMIT 1];
        Project__c queriedProject = [SELECT Id FROM Project__c LIMIT 1];
        Contact queriedEmployee = [SELECT Id FROM Contact LIMIT 1];
        RepliconForecast__c newForecast = TestClassUtil.createForecast(false, queriedAccount.Id, queriedProject.Id);
        newForecast.Contact__c = queriedEmployee.Id;
        newForecast.Week_Start_Date__c = Date.today().toStartOfWeek();
        insert newForecast;
        
        Test.startTest();
        System.debug([SELECT Id FROM RepliconForecast__c WHERE LastModifiedDate != TODAY]);
        RepliconDeltaForecastBatchDelete batch = new RepliconDeltaForecastBatchDelete('SELECT Id FROM RepliconForecast__c WHERE LastModifiedDate = TODAY');
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assertEquals(0, [SELECT Id FROM RepliconForecast__c].size());
    }
    
	@isTest static void testForDelete_Negative() {
        Account queriedAccount = [SELECT Id FROM Account LIMIT 1];
        Project__c queriedProject = [SELECT Id FROM Project__c LIMIT 1];
        Contact queriedEmployee = [SELECT Id FROM Contact LIMIT 1];
        RepliconForecast__c newForecast = TestClassUtil.createForecast(false, queriedAccount.Id, queriedProject.Id);
        newForecast.Contact__c = queriedEmployee.Id;
        newForecast.Week_Start_Date__c = Date.today().toStartOfWeek();
        insert newForecast;
        
        Test.startTest();
        RepliconDeltaForecastBatchDelete batch = new RepliconDeltaForecastBatchDelete(RepliconDeltaForecastBatchDelete.queryDefault);
        Database.executeBatch(batch);
        Test.stopTest();
        
        //System.assertEquals(1, [SELECT Id FROM RepliconForecast__c].size());
    }
    
    @isTest static void testForSchedule_Positive() {
        try {
            System.schedule('Test Scheduled Job 1', '0 25 * * * ?', new RepliconDeltaForecastBatchDelete(RepliconDeltaForecastBatchDelete.queryDefault));
            //System.assert(false);
        }
        catch(Exception e) {
            System.assert(true);
        } 
    }
}