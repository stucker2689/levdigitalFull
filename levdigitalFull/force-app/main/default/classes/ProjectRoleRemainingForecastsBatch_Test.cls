/**
 * Created 5/20/2022 ST
 * 
 * Purpose: To test the ProjectRoleRemainingForecastBatch functionality of calculating the Remaining Forecasted Hours/Revenue on Project Role records
 */
@isTest
private class ProjectRoleRemainingForecastsBatch_Test {
    
    @TestSetup
    static void makeData(){
        /**
         * Data to Setup
         *  1.) Create Account, Opportunity, Project
         *  2.) Create Project Role (with Name, Project)
         *  3.) Create Forecasts with dates in the future and past with Project, Estimated Hours and Project Team Member Billing Rate
         */
        //Create Account
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        insert acct;

        //Create Opportunity
        Opportunity oppty = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppty.Name = 'Test Oppty';
        insert oppty;

        Project__c proj = TestDataFactory.createProject(false, acct.Id, oppty.id);
        proj.Name = 'Test Project';
        insert proj;

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = proj.Id, Rate__c = 200);
        ProjectRole__c pmProjRole = new ProjectRole__c(Name = 'Project Manager', Project__c = proj.Id, Rate__c = 100);
        List<ProjectRole__c> projectRoleInsertList = new List<ProjectRole__c>{devProjRole, pmProjRole};
        insert projectRoleInsertList;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = proj.Id);
        Project_Team_Member_Billing_Rate__c pmBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 100, Project__c = proj.Id);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{devBillRate, pmBillRate};
        insert billRateInsertList;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c pastDevForecast = new RepliconForecast__c(Name = 'Past Dev Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-14), Week_End_Date__c = currentWeekStartDate.addDays(-8), ProjectTeamMemberBillingRate__c = devBillRate.Id, EstimatedHours__c = 10, Project__c = proj.Id);
        RepliconForecast__c pastPMForecast = new RepliconForecast__c(Name = 'Past PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(-7), Week_End_Date__c = currentWeekStartDate.addDays(-1), ProjectTeamMemberBillingRate__c = pmBillRate.Id, EstimatedHours__c = 10, Project__c = proj.Id);
        RepliconForecast__c futureDevForecast = new RepliconForecast__c(Name = 'Future Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate.Id, EstimatedHours__c = 10, Project__c = proj.Id);
        RepliconForecast__c futurePMForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = pmBillRate.Id, EstimatedHours__c = 10, Project__c = proj.Id);
        List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>{pastDevForecast, pastPMForecast, futureDevForecast, futurePMForecast};
        insert forecastInsertList;

        
    }

    @isTest
    static void testScheduleProjectRoleRemainingBatch(){
        String cronExpr = '0 0 0 15 12 ? 2023';
        Test.startTest();
        ProjectRoleRemainingForecastsBatch newTestScheduler = new ProjectRoleRemainingForecastsBatch();
        String jobId = System.schedule('Project Role Remaining Forecast Calculation Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testProjRoleRemainingHoursAndRevenueCalc(){
        //Test that running the Batch will properly calculate the Project Role Remaining Forecasted Hours/Revenue
        List<ProjectRole__c> projectRoleToUpdateList = new List<ProjectRole__c>();
        List<ProjectRole__c> beforeBatchRunProjectRoleList = [SELECT Id, Name, Project__r.Name, Remaining_Forecasted_Hours__c, Remaining_Forecasted_Revenue__c FROM ProjectRole__c];
        System.debug('beforeBatchRunProjectRoleList Size: ' + beforeBatchRunProjectRoleList.size());
        for(ProjectRole__c pr : beforeBatchRunProjectRoleList){
            System.debug('Project Role: ' + pr);
            if(pr.Name == 'Developer'){
                System.assertEquals(10, pr.Remaining_Forecasted_Hours__c, 'Developer Project Role had its Remaining Forecasted Hours calculated incorrectly before batch run');
                System.assertEquals(2000, pr.Remaining_Forecasted_Revenue__c, 'Developer Project Role had its Remaining Forecasted Revenue calculated incorrectly before batch run');
                pr.Remaining_Forecasted_Hours__c = 20; 
                pr.Remaining_Forecasted_Revenue__c = 3000;
                projectRoleToUpdateList.add(pr);
            }else if(pr.Name == 'Project Manager'){
                System.assertEquals(10, pr.Remaining_Forecasted_Hours__c, 'Project Manager Project Role had its Remaining Forecasted Hours calculated incorrectly before batch run');
                System.assertEquals(1000, pr.Remaining_Forecasted_Revenue__c, 'Project Manager Project Role had its Remaining Forecasted Revenue calculated incorrectly before batch run');
                pr.Remaining_Forecasted_Hours__c = 20;
                pr.Remaining_Forecasted_Revenue__c = 3000;
                projectRoleToUpdateList.add(pr);
            }
        }

        update projectRoleToUpdateList; //Update Project Role to incorrect Remaining Forecasted Hours/Revenue for Batch run to update them back to proper amounts

        Test.startTest();
        ProjectRoleRemainingForecastsBatch batch = new ProjectRoleRemainingForecastsBatch();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        List<ProjectRole__c> afterBatchRunProjectRoleList = [SELECT Id, Name, Project__r.Name, Remaining_Forecasted_Hours__c, Remaining_Forecasted_Revenue__c FROM ProjectRole__c];
        System.debug('afterBatchRunProjectRoleList Size: ' + afterBatchRunProjectRoleList.size());
        for(ProjectRole__c pr : afterBatchRunProjectRoleList){
            System.debug('Project Role: ' + pr);
            if(pr.Name == 'Developer'){
                System.assertEquals(10, pr.Remaining_Forecasted_Hours__c, 'Developer Project Role had its Remaining Forecasted Hours calculated incorrectly before batch run');
                System.assertEquals(2000, pr.Remaining_Forecasted_Revenue__c, 'Developer Project Role had its Remaining Forecasted Revenue calculated incorrectly before batch run');
            }else if(pr.Name == 'Project Manager'){
                System.assertEquals(10, pr.Remaining_Forecasted_Hours__c, 'Project Manager Project Role had its Remaining Forecasted Hours calculated incorrectly before batch run');
                System.assertEquals(1000, pr.Remaining_Forecasted_Revenue__c, 'Project Manager Project Role had its Remaining Forecasted Revenue calculated incorrectly before batch run');
            }
        }
    }
}