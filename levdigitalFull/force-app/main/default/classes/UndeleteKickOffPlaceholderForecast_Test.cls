/**
 * Created 6/3/2022 ST
 * 
 * Purpose to test the Undelete KickOffPlaceholderForecastBatch
 */
@isTest
public with sharing class UndeleteKickOffPlaceholderForecast_Test {
    
    @TestSetup
    static void makeData(){
        Account testAcct = TestDataFactory.createAccount(false, 'Client');
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{testAcct, levementumLLCAcct};
        insert testAccountList;

        //Create Employee
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.RepliconLoginName__c = 'place.holder';
        insert con;

        //Create Opportunity
        Opportunity testOppty = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        testOppty.Name = 'Test Oppty';
        testOppty.StageName = 'Closed Won';
        testOppty.Amount = 10000;
        testOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert testOppty;

        //Create Project
        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =: testOppty.Id LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:987987';
        update testProj;


        //Create Project Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c billRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert billRate;

        Date testFutureWeekEndDate = Date.today().addDays(30).toStartOfWeek().addDays(6); //Sunday of the week that is 30 days away from the current date
        RepliconForecast__c testKickOffPlaceholder1 = TestDataFactory.createForecast(false, 'Test Kickoff Placeholder Forecast #1', testProj.Id, con.Id, testFutureWeekEndDate, billRate.Id);
        RepliconForecast__c testKickOffPlaceholder2 = TestDataFactory.createForecast(false, 'Test Kickoff Placeholder Forecast #2', testProj.Id, con.Id, testFutureWeekEndDate.addDays(7), billRate.Id);
        RepliconForecast__c testKickOffPlaceholder3 = TestDataFactory.createForecast(false, 'Test Kickoff Placeholder Forecast #3', testProj.Id, con.Id, testFutureWeekEndDate.addDays(14), billRate.Id);
        RepliconForecast__c testKickOffPlaceholder4 = TestDataFactory.createForecast(false, 'Test Kickoff Placeholder Forecast #4', testProj.Id, con.Id, testFutureWeekEndDate.addDays(21), billRate.Id);
        testKickOffPlaceholder1.Kickoff_Placeholder_Forecast__c = true;
        testKickOffPlaceholder1.Deleted_in_Replicon__c = true;
        testKickOffPlaceholder2.Kickoff_Placeholder_Forecast__c = true;
        testKickOffPlaceholder2.Deleted_in_Replicon__c = true;
        testKickOffPlaceholder3.Kickoff_Placeholder_Forecast__c = true;
        testKickOffPlaceholder3.Deleted_in_Replicon__c = true;
        testKickOffPlaceholder4.Kickoff_Placeholder_Forecast__c = true;
        testKickOffPlaceholder4.Deleted_in_Replicon__c = true;
        List<RepliconForecast__c> testForecastList = new List<RepliconForecast__c>{testKickOffPlaceholder1, testKickOffPlaceholder2, testKickOffPlaceholder3, testKickOffPlaceholder4};
        insert testForecastList;

    }

    @isTest 
    static void testScheduleBatch(){
        //Purpose: Test the scheduling of the batch run
        String cronExpr = '0 0 0 15 12 ? 2022';
        Test.startTest();
        UndeleteKickOffPlaceholderForecastsBatch newTestScheduler = new UndeleteKickOffPlaceholderForecastsBatch();
        String jobId = System.schedule('Undelete Kick Off Placeholder Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();

    }

    @isTest
    static void testUndeleteKickOffPlaceholderForecasts(){
        //Purpose: Ensure the batch marks any Kick off Placeholder Forecasts that are marked as Deleted in Replicon == true as undeleted by the batch run
        Test.startTest();
        UndeleteKickOffPlaceholderForecastsBatch batch = new UndeleteKickOffPlaceholderForecastsBatch();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        List<RepliconForecast__c> assertForecastList = [SELECT Id, Name, Deleted_in_Replicon__c, ActualHours__c, Kickoff_Placeholder_Forecast__c FROM RepliconForecast__c];

        for(RepliconForecast__c assertForecast : assertForecastList){
            
            System.assertEquals(true, assertForecast.Kickoff_Placeholder_Forecast__c, 'Forecast Should be a Kickoff Placeholder Forecast');
            System.assertEquals(false, assertForecast.Deleted_in_Replicon__c, 'Forecast was not properly undeleted');

        }
        
    }
}