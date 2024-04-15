/**
 * Created 5/27/2022 ST
 * 
 * Purpose: To Test the functionality of the UndeleteForecastsWithActualsBatch class that marks any Forecasts with Actual Hours as Deleted in Replicon = false if it was previously marked as true
 */
@isTest
public with sharing class UndeleteForecastsWithActualsBatchTest {

    @TestSetup
    static void makeData(){
        Account testAcct = TestDataFactory.createAccount(false, 'Client');
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{testAcct, levementumLLCAcct};
        insert testAccountList;

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

        //Create Employee
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Project Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        //Create Entries
        Date currentWeekStartDate = Date.today().toStartOfWeek();
        Replicon_Time_Entry__c currentimeEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 8, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = currentWeekStartDate.addDays(1));
        Replicon_Time_Entry__c previousQuarterEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 4, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = currentWeekStartDate.addDays(2));
        Replicon_Time_Entry__c nextQuarterEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = currentWeekStartDate.addDays(3));
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{currentimeEntry, previousQuarterEntry, nextQuarterEntry};
        insert entryList;
    }

    @isTest 
    static void testScheduleBatch(){
        //Purpose: Test the scheduling of the batch run
        String cronExpr = '0 0 0 15 12 ? 2022';
        Test.startTest();
        UndeleteForecastsWithActualsBatch newTestScheduler = new UndeleteForecastsWithActualsBatch();
        String jobId = System.schedule('Undelete Forecasts with Actuals Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();

    }

    @isTest
    static void testUndeleteForecastsWithActuals(){
        //Purpose: Ensure the batch marks any Forecasts with > 0 Actual Hours that are marked as Deleted in Replicon == true as undeleted
        RepliconForecast__c updateForecast = [SELECT Id, Name, Deleted_in_Replicon__c, ActualHours__c FROM RepliconForecast__c LIMIT 1];
        updateForecast.Deleted_in_Replicon__c = true;
        update updateForecast;

        Test.startTest();
        UndeleteForecastsWithActualsBatch batch = new UndeleteForecastsWithActualsBatch();
        Database.executeBatch(batch, 50);
        Test.stopTest();

        RepliconForecast__c assertForecast = [SELECT Id, Name, Deleted_in_Replicon__c, ActualHours__c FROM RepliconForecast__c LIMIT 1];

        System.assertNotEquals(0, assertForecast.ActualHours__c, 'Forecast Actual Hours should not equal 0');
        System.assertEquals(false, assertForecast.Deleted_in_Replicon__c, 'Forecast was not properly undeleted');
        
    }

    /*@isTest
    static void testUndeleteForecastsWithoutActuals(){
        //Purpose: Make sure the batch doesn't undelete any forecasts with 0 actual hours
    }*/
}