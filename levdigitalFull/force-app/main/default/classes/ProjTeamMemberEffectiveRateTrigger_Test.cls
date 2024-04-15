@isTest
public with sharing class ProjTeamMemberEffectiveRateTrigger_Test {
    public ProjTeamMemberEffectiveRateTrigger_Test() {

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
        oppo.Name = 'Effective Rate Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.Peoplesoft_Project_Id__c = '11111111';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Effective Rate Test Oppty' LIMIT 1];
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); 
        con.Cognizant_Employee_Id__c = '123';
        insert con;

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC - Solution Architect', Hourly_Rate__c = 215, Project__c = testProj.Id, Created_in_Salesforce__c = true );
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        insert testTeamMember;
    }

    @isTest
    static void createEffectiveRates_Test(){


        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Cognizant_Employee_Id__c = '123' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Effective Rate Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 185, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, testTeamMember.Assigned_Billing_Rate__c, newBillRate.Id, Date.today(), testProj.CreatedDate);        

        RepliconForecast__c testForecastOne = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek(), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        testForecastOne.EstimatedHours__c = 1;
        RepliconForecast__c testForecastTwo = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(7), null); //Week of August 8/7/2022 - 8/13/2022
        testForecastTwo.EstimatedHours__c = 2;
        RepliconForecast__c testForecastThree = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-7), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        testForecastThree.EstimatedHours__c = 3;
        RepliconForecast__c testForecastFour = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(14), null); //Week of September 9/4/2022 - 9/10/2022
        testForecastFour.EstimatedHours__c = 4;
        RepliconForecast__c testForecastFive = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-14), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        testForecastFive.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{testForecastOne, testForecastTwo, testForecastThree, testForecastFour, testForecastFive};
        insert testRepliconForecastsToInsert;

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        Project_Team_Member_Billing_Rate__c newBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Email QA Consultant', Hourly_Rate__c = 195, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate2;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, newBillRate.Id, newBillRate2.Id, Date.today().addDays(-7), testProj.CreatedDate);     


    }

    @isTest
    static void updateEffectiveRate_Test(){

        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Cognizant_Employee_Id__c = '123' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Effective Rate Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 185, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, testTeamMember.Assigned_Billing_Rate__c, newBillRate.Id, Date.today(), testProj.CreatedDate);        

        RepliconForecast__c testForecastOne = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek(), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        testForecastOne.EstimatedHours__c = 1;
        RepliconForecast__c testForecastTwo = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(7), null); //Week of August 8/7/2022 - 8/13/2022
        testForecastTwo.EstimatedHours__c = 2;
        RepliconForecast__c testForecastThree = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-7), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        testForecastThree.EstimatedHours__c = 3;
        RepliconForecast__c testForecastFour = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(14), null); //Week of September 9/4/2022 - 9/10/2022
        testForecastFour.EstimatedHours__c = 4;
        RepliconForecast__c testForecastFive = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-14), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        testForecastFive.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{testForecastOne, testForecastTwo, testForecastThree, testForecastFour, testForecastFive};
        insert testRepliconForecastsToInsert;

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        Project_Team_Member_Effective_Rate__c pmEffectiveRate = [SELECT Id, Name, Effective_Date__c, Project_Billing_Rate__c FROM Project_Team_Member_Effective_Rate__c WHERE Project_Billing_Rate__c =: newBillRate.Id LIMIT 1];
        pmEffectiveRate.Effective_Date__c = Date.today().addDays(-14);
        update pmEffectiveRate;  

    }

    @isTest
    static void deleteEffectiveRate_Test(){

        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Cognizant_Employee_Id__c = '123' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Effective Rate Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 185, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, testTeamMember.Assigned_Billing_Rate__c, newBillRate.Id, Date.today(), testProj.CreatedDate);        

        RepliconForecast__c testForecastOne = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek(), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        testForecastOne.EstimatedHours__c = 1;
        RepliconForecast__c testForecastTwo = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(7), null); //Week of August 8/7/2022 - 8/13/2022
        testForecastTwo.EstimatedHours__c = 2;
        RepliconForecast__c testForecastThree = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-7), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        testForecastThree.EstimatedHours__c = 3;
        RepliconForecast__c testForecastFour = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(14), null); //Week of September 9/4/2022 - 9/10/2022
        testForecastFour.EstimatedHours__c = 4;
        RepliconForecast__c testForecastFive = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-14), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        testForecastFive.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{testForecastOne, testForecastTwo, testForecastThree, testForecastFour, testForecastFive};
        insert testRepliconForecastsToInsert;

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        Project_Team_Member_Effective_Rate__c pmEffectiveRate = [SELECT Id, Name, Effective_Date__c, Project_Billing_Rate__c FROM Project_Team_Member_Effective_Rate__c WHERE Project_Billing_Rate__c =: newBillRate.Id LIMIT 1];
        delete pmEffectiveRate;  

    }

    @isTest
    static void updateEffectiveRateDate_Test(){

        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Cognizant_Employee_Id__c = '123' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Effective Rate Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 185, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, testTeamMember.Assigned_Billing_Rate__c, newBillRate.Id, Date.today(), testProj.CreatedDate);        

        RepliconForecast__c testForecastOne = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek(), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        testForecastOne.EstimatedHours__c = 1;
        RepliconForecast__c testForecastTwo = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(7), null); //Week of August 8/7/2022 - 8/13/2022
        testForecastTwo.EstimatedHours__c = 2;
        RepliconForecast__c testForecastThree = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-7), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        testForecastThree.EstimatedHours__c = 3;
        RepliconForecast__c testForecastFour = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(14), null); //Week of September 9/4/2022 - 9/10/2022
        testForecastFour.EstimatedHours__c = 4;
        RepliconForecast__c testForecastFive = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.today().toStartOfWeek().addDays(-14), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        testForecastFive.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{testForecastOne, testForecastTwo, testForecastThree, testForecastFour, testForecastFive};
        insert testRepliconForecastsToInsert;

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '1111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        Project_Team_Member_Effective_Rate__c effectiveRate = [SELECT Id, Name, Effective_Date__c FROM Project_Team_Member_Effective_Rate__c WHERE Project_Billing_Rate__c =: newBillRate.Id LIMIT 1];
        effectiveRate.Effective_Date__c = Date.today().addDays(-10);
        update effectiveRate;

        Client_Contact__c assertTeamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Active_Effective_Billing_Rate__c FROM Client_Contact__c WHERE Id =: testTeamMember.Id LIMIT 1];
        System.assertEquals('MC - Solution Architect', assertTeamMember.Assigned_Billing_Rate__r.Name, 'The Billing Rate did not properly update after the Effective Date was updated on the Effective Rate');
        
        Project_Team_Member_Effective_Rate__c pmEffectiveRate = [SELECT Id, Name, Effective_Date__c, Project_Billing_Rate__c FROM Project_Team_Member_Effective_Rate__c WHERE Project_Billing_Rate__c =: newBillRate.Id LIMIT 1];
        delete pmEffectiveRate;  

    }
}