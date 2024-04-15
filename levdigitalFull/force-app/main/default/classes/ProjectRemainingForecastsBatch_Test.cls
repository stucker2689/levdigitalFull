/**
 * Created 5/9/2022 ST
 * 
 * Purpose: To test the functionality of ProjectRemainingForecastsBatch and ProjectRemainingForecastsBatchScheduler
 */

@isTest
private class ProjectRemainingForecastsBatch_Test {

    @testSetup
    static void setupData() {

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';

        Account testAcct = TestDataFactory.createAccount(false, 'Client');

        List<Account> testAccountList = new List<Account>{levementumLLCAcct, testAcct};
        insert testAccountList;

        Opportunity testOppty = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        testOppty.Name = 'Test Oppty';
        testOppty.StageName = 'Closed Won';
        testOppty.Amount = 10000;
        testOppty.Do_Not_Create_Project__c = false;
        insert testOppty;

        Project__c testProj1 = new Project__c();
        testProj1.Account__c = testAcct.Id;
        testProj1.Opportunity__c = testOppty.Id;
        testProj1.Name = 'Test Project 1';
        testProj1.Project_Status__c = 'Active';
        testProj1.Planned_Close_Date__c = Date.today().addDays(14);
        testProj1.RepliconURI__c = 'urn:replicon-tenant:levementum:project:43214321';
        testProj1.Remaining_Forecasted_Hrs__c = 120;

        Project__c testProj2 = new Project__c();
        testProj2.Account__c = testAcct.Id;
        testProj2.Opportunity__c = testOppty.Id;
        testProj2.Name = 'Test Project 2';
        testProj2.Project_Status__c = 'Not Started';
        testProj2.Planned_Close_Date__c = Date.today().addDays(14);
        testProj2.RepliconURI__c = 'urn:replicon-tenant:levementum:project:12341234';
        testProj2.Remaining_Forecasted_Hrs__c = 120;

        List<Project__c> insertProjList = new List<Project__c>{testProj1, testProj2};
        insert insertProjList;

        Project__c testProj3 = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember1 = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj1.Id); //Named Test Replicon Team Member
        Project_Team_Member__c projTeamMember2 = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj2.Id); 
        Project_Team_Member__c projTeamMember3 = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj3.Id);

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate1 = TestDataFactory.createRepliconBillingRate(true, projTeamMember1.Id, testProj1.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate2 = TestDataFactory.createRepliconBillingRate(true, projTeamMember2.Id, testProj2.Id);
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate3 = TestDataFactory.createRepliconBillingRate(true, projTeamMember3.Id, testProj3.Id);

        //Create Forecasts for the Projects
        RepliconForecast__c currentWeekForecast1 = TestDataFactory.createForecast(false, 'Current Week Forecast 1', testProj1.Id, con.Id, Date.today().toStartOfWeek().addDays(6), testProjMemberBillRate1.Id);
        currentWeekForecast1.EstimatedHours__c = 10;

        RepliconForecast__c nextWeekForecastt1 = TestDataFactory.createForecast(false, 'Next Week Forecast 1', testProj1.Id, con.Id, Date.today().toStartOfWeek().addDays(13), testProjMemberBillRate1.Id);
        nextWeekForecastt1.EstimatedHours__c = 20;

        RepliconForecast__c previousWeekForecast1 = TestDataFactory.createForecast(false, 'Previous Week Forecast 1', testProj1.Id, con.Id, Date.today().toStartOfWeek().addDays(-1), testProjMemberBillRate1.Id);
        previousWeekForecast1.EstimatedHours__c = 30;

        RepliconForecast__c currentWeekForecast2 = TestDataFactory.createForecast(false, 'Current Week Forecast 2', testProj2.Id, con.Id, Date.today().toStartOfWeek().addDays(6), testProjMemberBillRate2.Id);
        currentWeekForecast2.EstimatedHours__c = 40;

        RepliconForecast__c previousWeekForecast2 = TestDataFactory.createForecast(false, 'Previous Week Forecast 2', testProj2.Id, con.Id, Date.today().toStartOfWeek().addDays(-1), testProjMemberBillRate2.Id);
        previousWeekForecast2.EstimatedHours__c = 50;

        RepliconForecast__c nextWeekForecast2 = TestDataFactory.createForecast(false, 'Next Week Forecast 2', testProj2.Id, con.Id, Date.today().toStartOfWeek().addDays(13), testProjMemberBillRate2.Id);
        nextWeekForecast2.EstimatedHours__c = 60;

        RepliconForecast__c futureWeekForecast2 = TestDataFactory.createForecast(false, 'Future Week Forecast 2', testProj2.Id, con.Id, Date.today().toStartOfWeek().addDays(20), testProjMemberBillRate2.Id);
        futureWeekForecast2.EstimatedHours__c = 70;

        RepliconForecast__c previousWeekForecast3 = TestDataFactory.createForecast(false, 'Previous Week Forecast 3', testProj3.Id, con.Id, Date.today().toStartOfWeek().addDays(-1), testProjMemberBillRate3.Id);
        System.debug('Previous Week Forecast Date: ' + previousWeekForecast3.Week_Start_Date__c);
        previousWeekForecast3.EstimatedHours__c = 80;

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>{currentWeekForecast1, nextWeekForecastt1, previousWeekForecast1, currentWeekForecast2, previousWeekForecast2, nextWeekForecast2, futureWeekForecast2, previousWeekForecast3};
        insert forecastList;

        testProj2.Remaining_Forecasted_Hrs__c = 220;
        testProj2.Remaining_Forecasted_Rev__c = 44000;

        testProj3.Remaining_Forecasted_Hrs__c = 80;
        testProj3.Remaining_Forecasted_Rev__c = 16000;

        List<Project__c> updateProjList = new List<Project__c>{testProj2, testProj3};
        update updateProjList; //Update Projects to have inaccurate calculations for Remaining Forecasted Hours/Revenue fields

    }

    @isTest
    static void scheduleProjectRemainingForecastsBatch_Test() {
        String cronExpr = '0 0 0 31 12 ? 2025';
        Test.startTest();
        ProjectRemainingForecastsBatchScheduler newTestScheduler = new ProjectRemainingForecastsBatchScheduler();
        String jobId = System.schedule('ProjectRemainingForecastsBatchScheduler Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void runProjectRemainingForecastBatch_Test(){
        System.debug('*************************************************** runProjectRemainingForecastBatch_Test ******************************************');
        
        List<Project__c> beforeBatchRunProjectsList = new List<Project__c>();
        beforeBatchRunProjectsList = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c FROM Project__c];
        System.debug('beforeBatchRunProjectsList: ' + beforeBatchRunProjectsList);
        System.debug('beforeBatchRunProjectsList Size: ' + beforeBatchRunProjectsList.size());

        for(Project__c proj : beforeBatchRunProjectsList){
            if(proj.Name == 'Test Project 1'){
                System.assertEquals(30, proj.Remaining_Forecasted_Hrs__c, '1Remaining Forecasted Hours is not correctly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours correctly calculated
                System.assertEquals(6000, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is not correctly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue correctly calculated
            }else if(proj.Name == 'Test Project 2'){
                System.assertEquals(220, proj.Remaining_Forecasted_Hrs__c, '2Remaining Forecasted Hours is not incorrectly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours incorrectly calculated
                System.assertEquals(44000, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is not incorrectly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue incorrectly calculated
            }else if(proj.Name == 'Test Oppty'){
                System.assertEquals(80, proj.Remaining_Forecasted_Hrs__c, '3Remaining Forecasted Hours is not incorrectly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours incorrectly calculated
                System.assertEquals(16000, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is not incorrectly calculated for this Project BEFORE the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue incorrectly calculated
            }
        }

        Test.startTest();
        ProjectRemainingForecastsBatch newBatch = new ProjectRemainingForecastsBatch();
        Database.executeBatch(newBatch, 10);
        Test.stopTest();

        List<Project__c> afterBatchRunProjectsList = new List<Project__c>();
        afterBatchRunProjectsList = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c FROM Project__c];
        System.debug('beforeBatchRunProjectsList: ' + afterBatchRunProjectsList);

        for(Project__c proj : afterBatchRunProjectsList){

            if(proj.Name == 'Test Project 1'){
                System.assertEquals(30, proj.Remaining_Forecasted_Hrs__c, '4Remaining Forecasted Hours is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours correctly calculated
                System.assertEquals(6000, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue correctly calculated
            }else if(proj.Name == 'Test Project 2'){
                System.assertEquals(170, proj.Remaining_Forecasted_Hrs__c, '5Remaining Forecasted Hours is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours incorrectly calculated
                System.assertEquals(34000, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue incorrectly calculated
            }else if(proj.Name == 'Test Oppty'){
                System.assertEquals(0, proj.Remaining_Forecasted_Hrs__c, '6Remaining Forecasted Hours is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Hours incorrectly calculated
                System.assertEquals(0, proj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue is incorrectly calculated for this Project AFTER the Batch run: ' + proj.Name); //Assert that the Project has Remaining Forecasted Revenue incorrectly calculated
            }
        }
    }
}