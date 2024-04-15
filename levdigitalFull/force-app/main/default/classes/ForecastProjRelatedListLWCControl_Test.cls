@isTest
public with sharing class ForecastProjRelatedListLWCControl_Test {
    public ForecastProjRelatedListLWCControl_Test() {

    }

    @TestSetup
    static void makeData(){
        List<Account> testAccountList = new List<Account>();
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        testAccountList.add(levementumLLCAcct);

        //Create Test Client Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        testAccountList.add(acct);

        //Insert Both Accounts
        insert testAccountList;

        //Create Test Oppty associated with the Client Account
        Opportunity oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.Peoplesoft_Project_Id__c = '123';
        insert oppo;

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = SetupTestDataFactory.createProjectBillingRate(true, testProj.Id, 'Developer', 215);

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, con.Id, Date.today().addDays(-7), testProjMemberBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, con.Id, Date.today(), testProjMemberBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, con.Id, Date.today(), testProjMemberBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, con.Id, Date.today().addDays(7), testProjMemberBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, con.Id, Date.today().addDays(7), testProjMemberBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};
        insert forecastsToInsertList;
    }


    @isTest
    static void getRelatedProjectForecasts_Test(){

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];

        List<ForecastProjectRelatedListLWCController.ForecastDataWrapper> forecastWrapperList = new List<ForecastProjectRelatedListLWCController.ForecastDataWrapper>();
        forecastWrapperList = ForecastProjectRelatedListLWCController.getProjectForecastData(testProj.Id);

        System.assertEquals(5, forecastWrapperList.size(), 'The wrong amount of Forecasts were returned when fetched for the test Project');

    }
}