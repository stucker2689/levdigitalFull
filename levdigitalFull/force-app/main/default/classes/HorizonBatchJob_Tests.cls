@isTest
public with sharing class HorizonBatchJob_Tests {
    
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
        oppo.Peoplesoft_Project_Id__c = '11111111';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        testProj.Project_Status__c = 'Active';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.FirstName = 'Test';
        con.LastName = 'EmployeeOne';
        con.Cognizant_Employee_Id__c = '1234';
        Contact placeholderCon = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        placeholderCon.FirstName = 'Place';
        placeholderCon.LastName = 'Holder';
        List<Contact> contactInsertList = new List<Contact>{con, placeholderCon};
        insert contactInsertList;

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = new Project_Team_Member_Billing_Rate__c();
        testProjMemberBillRate.Project__c = testProj.Id;
        testProjMemberBillRate.Hourly_Rate__c = 200;
        testProjMemberBillRate.Created_in_Salesforce__c = true;
        testProjMemberBillRate.Name = 'MC - Solution Architect';
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        Client_Contact__c placeholderTeamMember = new Client_Contact__c(Client_Contact__c = placeholderCon.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id, Is_Placeholder_Team_Member__c = true);
        List<Client_Contact__c> teamMemberInsertList = new List<Client_Contact__c>{testTeamMember, placeholderTeamMember};
        insert teamMemberInsertList;
    }

    @isTest
    static void deleteZeroForecastsBatchRun_Test(){

        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testCon.Id, Date.today().addDays(-7), testProjMemberBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 0;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testCon.Id, Date.today(), testProjMemberBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 0;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testCon.Id, Date.today(), testProjMemberBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 0;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testCon.Id, Date.today().addDays(7), testProjMemberBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 0;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testCon.Id, Date.today().addDays(7), testProjMemberBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};
        insert forecastsToInsertList;

        DeleteZeroForecastsBatch newForecastDeleteBatch = new DeleteZeroForecastsBatch();
        Database.executeBatch(newForecastDeleteBatch, 100); 

    }

    @isTest
    static void scheduleDeleteZeroForecastsBatchRun_Test(){
        //Purpose: Test the scheduling of the batch run
        String cronExpr = '0 0 0 15 12 ? 2023';
        Test.startTest();
        DeleteZeroForecastsBatch newTestScheduler = new DeleteZeroForecastsBatch();
        String jobId = System.schedule('Delete Zero Forecasts Daily Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void dailyEffectiveRateCheck_Test(){

        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Client_Contact__c teamMember = [SELECT Id, Name, Client_Contact__c, Assigned_Billing_Rate__c, Project__c FROM Client_Contact__c LIMIT 1];
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Replicon_Time_Entry__c entryOne = new Replicon_Time_Entry__c();
        entryOne.EntryDate__c = Date.today();
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111';
        entryOne.TotalHrs__c = 8;
        entryOne.Billing_Action__c = 'B';

        Replicon_Time_Entry__c entryTwo = new Replicon_Time_Entry__c();
        entryTwo.EntryDate__c = Date.today().addDays(1);
        entryTwo.Cognizant_Employee_Id__c = '1234';
        entryTwo.Peoplesoft_Project_Id__c = '11111111';
        entryTwo.TotalHrs__c = 8;
        entryTwo.Billing_Action__c = 'B';

        Replicon_Time_Entry__c entryThree = new Replicon_Time_Entry__c();
        entryThree.EntryDate__c = Date.today().addDays(-1);
        entryThree.Cognizant_Employee_Id__c = '1234';
        entryThree.Peoplesoft_Project_Id__c = '11111111';
        entryThree.TotalHrs__c = 8;
        entryThree.Billing_Action__c = 'B';
        
        Test.startTest();
        List<Replicon_Time_Entry__c> newEntryList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo, entryThree};
        insert newEntryList;

        Project_Team_Member_Billing_Rate__c pmRate = new Project_Team_Member_Billing_Rate__c();
        pmRate.Project__c = testProj.Id;
        pmRate.Hourly_Rate__c = 185;
        pmRate.Created_in_Salesforce__c = true;
        pmRate.Name = 'Project Manager';
        insert pmRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, teamMember.Assigned_Billing_Rate__c, pmRate.Id, Date.today(), testProj.CreatedDate);

        Client_Contact__c teamMemberRemove = [SELECT Id, Name, Client_Contact__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Project__c FROM Client_Contact__c LIMIT 1];
        teamMemberRemove.Active_Effective_Billing_Rate__c = null;
        teamMemberRemove.Assigned_Billing_Rate__c = null;
        update teamMemberRemove;
        Test.stopTest();

        ProjectTeamMemberEffectiveRateDailyCheck newEffectiveRateCheck = new ProjectTeamMemberEffectiveRateDailyCheck();
        Database.executeBatch(newEffectiveRateCheck, 100);

    }

    @isTest
    static void horizonTimeEntryUpdate_Test(){

        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Client_Contact__c teamMember = [SELECT Id, Name, Client_Contact__c, Assigned_Billing_Rate__c, Project__c FROM Client_Contact__c LIMIT 1];
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Replicon_Time_Entry__c entryOne = new Replicon_Time_Entry__c();
        entryOne.EntryDate__c = Date.today();
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111';
        entryOne.TotalHrs__c = 8;
        entryOne.Billing_Action__c = 'B';

        Replicon_Time_Entry__c entryTwo = new Replicon_Time_Entry__c();
        entryTwo.EntryDate__c = Date.today().addDays(1);
        entryTwo.Cognizant_Employee_Id__c = '1234';
        entryTwo.Peoplesoft_Project_Id__c = '11111111';
        entryTwo.TotalHrs__c = 8;
        entryTwo.Billing_Action__c = 'B';

        Replicon_Time_Entry__c entryThree = new Replicon_Time_Entry__c();
        entryThree.EntryDate__c = Date.today().addDays(-1);
        entryThree.Cognizant_Employee_Id__c = '1234';
        entryThree.Peoplesoft_Project_Id__c = '11111111';
        entryThree.TotalHrs__c = 8;
        entryThree.Billing_Action__c = 'B';
        
        List<Replicon_Time_Entry__c> newEntryList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo, entryThree};
        insert newEntryList;

        HorizonTimeEntryBatchUpdates_Manager horizonUpdateBatch = new HorizonTimeEntryBatchUpdates_Manager(true, null);
        Database.executeBatch(horizonUpdateBatch);

    }

    @isTest
    static void horizonTimeEntryUpdateWithProjList_Test(){

        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        Contact testCon = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Client_Contact__c teamMember = [SELECT Id, Name, Client_Contact__c, Assigned_Billing_Rate__c, Project__c FROM Client_Contact__c LIMIT 1];
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Replicon_Time_Entry__c entryOne = new Replicon_Time_Entry__c();
        entryOne.EntryDate__c = Date.today();
        entryOne.Employee__c = testCon.Id;
        entryOne.Project__c = testProj.Id;
        entryOne.TotalHrs__c = 8;
        entryOne.Billing_Action__c = 'B';

        Replicon_Time_Entry__c entryTwo = new Replicon_Time_Entry__c();
        entryTwo.EntryDate__c = Date.today().addDays(1);
        entryTwo.Employee__c = testCon.Id;
        entryTwo.Project__c = testProj.Id;
        entryTwo.TotalHrs__c = 8;
        entryTwo.Replicon_Billing_Rate_URI__c = 'testingBillRateURI';

        Replicon_Time_Entry__c entryThree = new Replicon_Time_Entry__c();
        entryThree.EntryDate__c = Date.today().addDays(-1);
        entryThree.Employee__c = testCon.Id;
        entryThree.Project__c = testProj.Id;
        entryThree.TotalHrs__c = 8;
        
        List<Replicon_Time_Entry__c> newEntryList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo, entryThree};
        insert newEntryList;

        List<Id> projIdList = new List<Id>{testProj.Id};
        HorizonTimeEntryBatchUpdates_Manager horizonUpdateBatch = new HorizonTimeEntryBatchUpdates_Manager(true, projIdList);
        Database.executeBatch(horizonUpdateBatch);

    }
}