/**
 * Created 6/6/2022 ST
 * 
 * Purpose to test the functionality of TimeEntryIsLevBatch and ForecastIsLevBatch
 * To ensure that they properly function to populate the Is_lev_Time__c and Is_Lev_Forecast__c fields on the Replicon Time Entry and Replicon Forecast Entry Fields respectively
 */
@isTest
public with sharing class IsLevTimeEntryAndForecastBatch_Test {
    
    @TestSetup
    static void makeData(){
        //Create Account
        Account clientAccount = TestDataFactory.createAccount(false, 'Client');
        clientAccount.Name = 'Test Client Account';

        Account levAccount = TestDataFactory.createAccount(false, 'Client');
        levAccount.Name = 'Levementum LLC';
        List<Account> accountList = new List<Account>{clientAccount, levAccount};
        insert accountList;

        Contact levContact = TestDataFactory.createEmployee(false, levAccount.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        Contact nonLevContact = TestDataFactory.createEmployee(false, clientAccount.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        nonLevContact.Replicon_User_Number__c = 9998;
        List<Contact> contactList = new List<Contact>{levContact, nonLevContact};
        insert contactList;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, clientAccount.Id, 'Salesforce');
        testOppty1.Name = 'Test Project Role Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;

        Opportunity testOppty2 = TestDataFactory.createOpportunity(false, clientAccount.Id, 'Salesforce');
        testOppty2.Name = 'Test Project Role Oppty 2';
        testOppty2.Do_Not_Create_Project__c = false;

        List<Opportunity> testOpportunitiesList = new List<Opportunity>{testOppty1, testOppty2};
        insert testOpportunitiesList;

        //Move Opportunities to Closed Won to have Projects and Project Roles created
        testOppty1.StageName = 'Closed Won';
        testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1, testOppty2};
        update testUpdateOpptiesToClosedWonList; 

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];
        Project__c testProj2 = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project Role Oppty 2' LIMIT 1];

        //Create Time Entries
        Project_Team_Member_Billing_Rate__c devBillRate1 = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 150, Project__c = testProj1.Id);
        Project_Team_Member_Billing_Rate__c devBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 150, Project__c = testProj2.Id);
        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>{devBillRate1, devBillRate2};
        insert billRateList;

        Replicon_Time_Entry__c timeEntry1 = new Replicon_Time_Entry__c(Project__c = testProj1.Id, Associated_Billing_Rate__c = devBillRate1.Id, TotalHrs__c = 4, Employee__c = levContact.Id, EntryDate__c = Date.newInstance(2022, 6, 20));
        Replicon_Time_Entry__c timeEntry2 = new Replicon_Time_Entry__c(Project__c = testProj1.Id, Associated_Billing_Rate__c = devBillRate1.Id, TotalHrs__c = 4, Employee__c = levContact.Id, EntryDate__c = Date.newInstance(2022, 5, 20));
        Replicon_Time_Entry__c timeEntry3 = new Replicon_Time_Entry__c(Project__c = testProj2.Id, Associated_Billing_Rate__c = devBillRate2.Id, TotalHrs__c = 4, Employee__c = nonLevContact.Id, EntryDate__c = Date.newInstance(2022, 6, 20));
        Replicon_Time_Entry__c timeEntry4 = new Replicon_Time_Entry__c(Project__c = testProj2.Id, Associated_Billing_Rate__c = devBillRate2.Id, TotalHrs__c = 4, Employee__c = nonLevContact.Id, EntryDate__c = Date.newInstance(2022, 5, 1));
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{timeEntry1, timeEntry2, timeEntry3, timeEntry4};
        insert entryList;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c pastDevForecast = new RepliconForecast__c(Name = 'Past Dev Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-14), Week_End_Date__c = currentWeekStartDate.addDays(-8), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c pastPMForecast = new RepliconForecast__c(Name = 'Past PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-7), Week_End_Date__c = currentWeekStartDate.addDays(-1), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c futureDevForecast = new RepliconForecast__c(Name = 'Future Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        RepliconForecast__c futurePMForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>{pastDevForecast, pastPMForecast, futureDevForecast, futurePMForecast};
        insert forecastInsertList;

    }

    @isTest
    static void runForecastIsLevBatch(){
        ForecastIsLevBatch newBatch = new ForecastIsLevBatch();
        Database.executeBatch(newBatch, 250);

    }

    @isTest
    static void runTimeEntryIsLevBatch(){
        TimeEntryIsLevBatch newBatch = new TimeEntryIsLevBatch();
        Database.executeBatch(newBatch, 250);
    }
}