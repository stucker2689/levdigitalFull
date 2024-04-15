/**
 * Created 6/10/2022 ST
 * 
 * Purpose to test the functionality of ProjectRoleTrigger and ProjectRoleTriggerHandler
 * 
 */

 @isTest
public with sharing class ProjectRoleTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        insert acct;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        testOppty1.Name = 'Test Project Role Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;

        Opportunity testOppty2 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
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
        Project_Team_Member_Billing_Rate__c devBillRate3 = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 2', Hourly_Rate__c = 250, Project__c = testProj1.Id);
        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>{devBillRate1, devBillRate2};
        insert billRateList;

        Replicon_Time_Entry__c timeEntry1 = new Replicon_Time_Entry__c(Project__c = testProj1.Id, Associated_Billing_Rate__c = devBillRate1.Id, TotalHrs__c = 4 );
        Replicon_Time_Entry__c timeEntry2 = new Replicon_Time_Entry__c(Project__c = testProj2.Id, Associated_Billing_Rate__c = devBillRate2.Id, TotalHrs__c = 4 );
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{timeEntry1, timeEntry2};
        insert entryList;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c pastDevForecast = new RepliconForecast__c(Name = 'Past Dev Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-14), Week_End_Date__c = currentWeekStartDate.addDays(-8), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c pastPMForecast = new RepliconForecast__c(Name = 'Past PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-7), Week_End_Date__c = currentWeekStartDate.addDays(-1), ProjectTeamMemberBillingRate__c = devBillRate1.Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c futureDevForecast = new RepliconForecast__c(Name = 'Future Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        RepliconForecast__c futurePMForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = devBillRate2.Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>{pastDevForecast, pastPMForecast, futureDevForecast, futurePMForecast};
        insert forecastInsertList;

        ProjectRole__c devProjRole1 = new ProjectRole__c(Name = 'Developer', Project__c = testProj1.Id, Rate__c = 150);
        ProjectRole__c devProjRole2 = new ProjectRole__c(Name = 'Developer', Project__c = testProj2.Id, Rate__c = 150);
        List<ProjectRole__c> projRoleList = new List<ProjectRole__c>{devProjRole1, devProjRole2};
        insert projRoleList;
    }

    @isTest
    static void testInsertProjectRoles(){

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Project Role Oppty 1' LIMIT 1];

        ProjectRole__c devProjRole1 = new ProjectRole__c(Name = 'MC - Solution Architect', Project__c = testProj1.Id, Rate__c = 170);
        ProjectRole__c devProjRole2 = new ProjectRole__c(Name = 'Project Manager', Project__c = testProj1.Id, Rate__c = 170);
        List<ProjectRole__c> projRoleList = new List<ProjectRole__c>{devProjRole1, devProjRole2};

        Test.startTest();
        insert projRoleList;
        Test.stopTest();
    }

    @isTest
    static void testUpdateInsertProjectRoles(){

        List<ProjectRole__c> projRoleList = new List<ProjectRole__c>();
        projRoleList = [SELECT Id, Name, Rate__c, Project__c, Project__r.Name FROM ProjectRole__c];

        List<ProjectRole__c> projRoleUpdateList = new List<ProjectRole__c>();
        for(ProjectRole__c projRole : projRoleList){
            projRole.Rate__c = 250;
            projRoleUpdateList.add(projRole);
        }

        Test.startTest();
        update projRoleUpdateList;
        Test.stopTest();

    }
}