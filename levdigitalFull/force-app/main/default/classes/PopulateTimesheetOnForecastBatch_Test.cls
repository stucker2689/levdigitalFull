@isTest
public with sharing class PopulateTimesheetOnForecastBatch_Test {
    
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
        oppo.Name = 'Replicon Forecast Trigger Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.Peoplesoft_Project_Id__c = '11111111';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Cognizant_Employee_Id__c = '12345678';
        insert con;


        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(false, null, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        testProjMemberBillRate.Name = 'MC - Solution Architect';
        testProjMemberBillRate.Created_in_Salesforce__c = true;
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        insert testTeamMember;
    }

    @isTest
    static void testRunForecastTimesheetPopulationBatchRun(){

        Date currentDate = Date.today();
        Date previousWeeksDate = currentDate.addDays(-7);
        Date nextWeeksDate = currentDate.addDays(7);

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testEmployee.Id, Date.today(), testBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testEmployee.Id, Date.today().addDays(7), testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testEmployee.Id, Date.today().addDays(14), testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testEmployee.Id, Date.today().addDays(21), testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testEmployee.Id, Date.today().addDays(21), testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};
        insert forecastsToInsertList;

        List<RepliconForecast__c> testForecastList = new List<RepliconForecast__c>();
        testForecastList = [SELECT Id, Name, Contact__c, Contact__r.Name, Project__r.Name, Week_Start_Date__c, Week_End_Date__c, Timesheet__c FROM RepliconForecast__c];

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : testForecastList){
            forecast.Timesheet__c = null;
            forecastUpdateList.add(forecast);
        }

        update forecastUpdateList;


        Test.startTest();

        PopulateTimesheetOnForecastBatch newBatchRun = new PopulateTimesheetOnForecastBatch();
        Database.executeBatch(newBatchRun, 250);

        Test.stopTest();

        List<RepliconForecast__c> forecastAssertList = new List<RepliconForecast__c>();
        forecastAssertList = [SELECT Id, Name, Contact__c, Contact__r.Name, Project__r.Name, Week_Start_Date__c, Week_End_Date__c, Timesheet__c, Timesheet__r.Employee__c, Timesheet__r.Start_Date__c FROM RepliconForecast__c];

        for(RepliconForecast__c forecast : forecastAssertList){

            System.assertNotEquals(null, forecast.Timesheet__c, 'A Timesheet was not properly populated on the Forecast after the Population Batch run.');
            System.assertEquals(forecast.Contact__c, forecast.Timesheet__r.Employee__c, 'The Timesheet associated with the forecast does not belong to the matching Contact lookup.');
            System.assertEquals(forecast.Week_Start_Date__c, forecast.Timesheet__r.Start_Date__c, 'The Timesheet associated with the forecast does not have the proper Week Start Date and does not match the forecast.');
        }

    }

}