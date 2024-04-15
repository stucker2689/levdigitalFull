/**
 * Created by Sam Tucker 4/11/2022
 * Purpose: To Test RepliconForecastTrigger, RepliconForecastTriggerHandler, RepliconForecastTriggerHelper
 */
@isTest
private class RepliconForecastTrigger_Test {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

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
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(false, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        testProjMemberBillRate.Name = 'MC - Solution Architect';
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        insert testTeamMember;
    
    }

    @isTest
    static void testForecastRollupsToProjectOnInsert(){

        Date currentDate = Date.today();
        Date previousWeeksDate = currentDate.addDays(-7);
        Date nextWeeksDate = currentDate.addDays(7);

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testEmployee.Id, previousWeeksDate, testBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testEmployee.Id, currentDate, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testEmployee.Id, currentDate, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testEmployee.Id, nextWeeksDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testEmployee.Id, nextWeeksDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};

        Test.startTest();
        insert forecastsToInsertList;
        Test.stopTest();

        Project__c assertProj = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c
                                    FROM Project__c 
                                    WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];

        System.assertEquals(14, assertProj.Remaining_Forecasted_Hrs__c, 'Remaining Forecasted Hours was incorrectly calculated after insert');
        System.assertEquals(2800, assertProj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue was incorrectly calculated after insert');

    }

    @isTest
    static void testForecastRollupsToProjectOnUpdate(){

        Date currentDate = Date.today();
        Date previousWeeksDate = currentDate.addDays(-7);
        Date nextWeeksDate = currentDate.addDays(7);

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testEmployee.Id, previousWeeksDate, testBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testEmployee.Id, currentDate, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testEmployee.Id, currentDate, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testEmployee.Id, nextWeeksDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testEmployee.Id, nextWeeksDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};

        insert forecastsToInsertList;

        List<RepliconForecast__c> repliconForecastsToUpdate = new List<RepliconForecast__c>();
        repliconForecastsToUpdate = [SELECT Id, Name, EstimatedHours__c, EstimatedRevenue__c, Project__c
                                    FROM RepliconForecast__c
                                    ORDER BY EstimatedHours__c ASC];

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c fore : repliconForecastsToUpdate){
            fore.EstimatedHours__c += 1;
            forecastUpdateList.add(fore);
        }

        Test.startTest();
        update forecastUpdateList;
        Test.stopTest();

        Project__c assertProj = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c
                                    FROM Project__c 
                                    WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];

        System.assertEquals(18, assertProj.Remaining_Forecasted_Hrs__c, 'Remaining Forecasted Hours was incorrectly calculated after update');
        System.assertEquals(3600, assertProj.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue was incorrectly calculated after update');


    }

    @isTest
    static void testForecastRollupsOnDelete(){

        Date currentDateSaturday = Date.today().toStartOfWeek().addDays(6);
        Date previousWeeksEndDate = currentDateSaturday.addDays(-7);
        Date nextWeeksEndDate = currentDateSaturday.addDays(7);

        Project__c testProj = [SELECT Id, Name FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', testProj.Id, testEmployee.Id, previousWeeksEndDate, testBillRate.Id); //Previous Weeks Forecast not to be included in Rollup ($200)
        previousWeekForecast.EstimatedHours__c = 1;
        RepliconForecast__c currentWeekForecastOne = TestDataFactory.createForecast(false, 'Current Week Test Forecast #1', testProj.Id, testEmployee.Id, currentDateSaturday, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($400)
        currentWeekForecastOne.EstimatedHours__c = 2;
        RepliconForecast__c currentWeekForecastTwo = TestDataFactory.createForecast(false, 'Current Week Test Forecast #2', testProj.Id, testEmployee.Id, currentDateSaturday, testBillRate.Id); //Current Weeks Forecast to be included in Rollup ($600)
        currentWeekForecastTwo.EstimatedHours__c = 3;
        RepliconForecast__c nextWeekForecastOne = TestDataFactory.createForecast(false, 'Next Week Test Forecast #1', testProj.Id, testEmployee.Id, nextWeeksEndDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($800)
        nextWeekForecastOne.EstimatedHours__c = 4;
        RepliconForecast__c nextWeekForecastTwo = TestDataFactory.createForecast(false, 'Next Week Test Forecast #2', testProj.Id, testEmployee.Id, nextWeeksEndDate, testBillRate.Id); //Next Weeks Forecast to be included in Rollup ($1000)
        nextWeekForecastTwo.EstimatedHours__c = 5;

        List<RepliconForecast__c> forecastsToInsertList = new List<RepliconForecast__c>{previousWeekForecast, currentWeekForecastOne, currentWeekForecastTwo, nextWeekForecastOne, nextWeekForecastTwo};
        insert forecastsToInsertList;

        Project__c assertProjBefore = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c
                                        FROM Project__c 
                                        WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];

        //Commented out this section because Forecast Rollups on Project have been changed to a @Future method
        //System.assertEquals(14, assertProjBefore.Remaining_Forecasted_Hrs__c, 'Remaining Forecasted Hours was incorrectly calculated after insert');
        //System.assertEquals(2800, assertProjBefore.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue was incorrectly calculated after insert');

        List<RepliconForecast__c> repliconForecastsToDelete = new List<RepliconForecast__c>();
        repliconForecastsToDelete = [SELECT Id, Name, EstimatedHours__c, EstimatedRevenue__c, Project__c
                                    FROM RepliconForecast__c
                                    WHERE Week_End_Date__c =: nextWeeksEndDate
                                    ORDER BY EstimatedHours__c ASC];

        Test.startTest();
        delete repliconForecastsToDelete;
        Test.stopTest();

        Project__c assertProjAfter = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c
                                        FROM Project__c 
                                        WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];

        System.assertEquals(5, assertProjAfter.Remaining_Forecasted_Hrs__c, 'Remaining Forecasted Hours was incorrectly calculated after delete');
        System.assertEquals(1000, assertProjAfter.Remaining_Forecasted_Rev__c, 'Remaining Forecasted Revenue was incorrectly calculated after delete');
    }


    @isTest
    static void testLinkForecastToProjectRole(){
        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c devForecast = new RepliconForecast__c(Name = 'Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate.Id, 
                                                                    EstimatedHours__c = 10, Project__c = testProj.Id, Contact__c = testEmployee.Id);

        Test.startTest();
        insert devForecast;
        Test.stopTest();

        RepliconForecast__c assertForecast = [SELECT Id, Name, ProjectRole__c FROM RepliconForecast__c LIMIT 1];

        System.assertEquals(devProjRole.Id, assertForecast.ProjectRole__c, 'The Forecast did not have the Project Role properly populated.');

        ProjectRole__c assertProjectRole = [SELECT Id, Name, Forecasted_Hours__c, Forecasted_Revenue__c FROM ProjectRole__c LIMIT 1];

        System.assertEquals(2000, assertProjectRole.Forecasted_Revenue__c, 'Project Role Forecasted Hours was not properly calculated');
        System.assertEquals(10, assertProjectRole.Forecasted_Hours__c, 'Project Role Forecast Revenue was not properly calculated');
    }

    @isTest
    static void testLinkForecastToProjectRoleClosestMatch(){

        System.debug('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& testLinkForecastToProjectRoleClosestMatch START ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Contact testEmployee = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 2', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c devForecast = new RepliconForecast__c(Name = 'Dev Forecast', Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = devBillRate.Id, 
                                                                    EstimatedHours__c = 10, Project__c = testProj.Id, Contact__c = testEmployee.Id);

        Test.startTest();
        insert devForecast;
        Test.stopTest();

        RepliconForecast__c assertForecast = [SELECT Id, Name, ProjectRole__c, Is_Lev_Forecast__c FROM RepliconForecast__c LIMIT 1];

        System.debug('Is it a Lev Forecast??: + assertForecast: ' + assertForecast);

        System.assertEquals(devProjRole.Id, assertForecast.ProjectRole__c, 'The Forecast did not have the Project Role properly populated.');

        ProjectRole__c assertProjectRole = [SELECT Id, Name, Forecasted_Hours__c, Forecasted_Revenue__c FROM ProjectRole__c LIMIT 1];

        System.assertEquals(2000, assertProjectRole.Forecasted_Revenue__c, 'Project Role Forecasted Hours was not properly calculated');
        System.assertEquals(10, assertProjectRole.Forecasted_Hours__c, 'Project Role Forecast Revenue was not properly calculated');


        System.debug('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& testLinkForecastToProjectRoleClosestMatch END ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
    }


    @isTest
    static void testUpdateWeeklyForecastsFromRepliconForecastsInsert(){
        /**
         * Testing Purpose: Updating the Weekly Forecast $ on a Weekly Target record will rollup to the Monthly amount when updated
         *                  Also test the Replicon Forecast Trigger functionality that will add to the related Weekly Target Forecast $ when it is created in SF
         */
        Revenue_Forecast__c testAugustMonthlyRevForecast = new Revenue_Forecast__c();
        testAugustMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testAugustMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 8, 1);
        testAugustMonthlyRevForecast.MonthlyTarget__c = 2300000; //23 Million for clean distribution of target to weeks because of 23 Business days in August 2022

        Revenue_Forecast__c testSeptemberMonthlyRevForecast = new Revenue_Forecast__c();
        testSeptemberMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testSeptemberMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 9, 1);
        testSeptemberMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in September 2022 (There is one holiday in September 2022, Labor Day, on 9/5/2022)

        /**
         * Should also test with May 2022 and June 2022, because 5/30 is a holiday on a week that spans 2 months (5/29/2022 - 6/4/2022)
         * May not need to test this just can ensure that the week with Labor Day keeps its entire value instead of changing it to 4/5 of what is should bee since there is only 4 business days on that week.
         */

        List<Revenue_Forecast__c> testMonthlyRevForecastsInsertList = new List<Revenue_Forecast__c>{testAugustMonthlyRevForecast, testSeptemberMonthlyRevForecast};
        insert testMonthlyRevForecastsInsertList;

        //Query both the Monthly and Weekly Forecast $ BEFORE the Forecasts get inserted
        List<Revenue_Forecast__c> revForecastsBefore = [SELECT Id, WeekStartDate__c, WeekEndDate__c, WeeklyForecast__c, MonthStartDate__c, MonthEndDate__c, MonthlyForecast__c, RecordTypeId
                                                        FROM Revenue_Forecast__c];

        System.assertNotEquals(2, revForecastsBefore.size(), 'Wrong Number of Revenue Forecasts created from the Monthly Target Revenue Forecast Creation'); //Just asserting that there are Weekly Targets being created from the Monthly Forecast Creation
        for(Revenue_Forecast__c revForecast : revForecastsBefore){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                System.assertEquals(null, revForecast.WeeklyForecast__c, 'Weekly Targets were improperly created with Weekly Forecast $ already populated'); //Assert that Weekly Target Weekly Actuals field is not populated on Creation and Confirm it is all starting at 0 before Time Entry insert
            
            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                System.assertEquals(0, revForecast.MonthlyForecast__c, 'Monthly Targets were improperly created with Monthly Forecast $ already populated'); //Assert that Monthly Target Monthly Actuals were not populated on Creation
            
            }
        }

        //Build the Forecasts
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name, Replicon_URI__c FROM Project_Team_Member_Billing_Rate__c WHERE Replicon_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123' LIMIT 1];
        

        RepliconForecast__c firstWeekOfAugustForecast = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 6), testBillRate.Id); //Also includes last week of July 7/31/2022 - 8/6/2022
        firstWeekOfAugustForecast.EstimatedHours__c = 1;
        RepliconForecast__c secondWeekOfJuneForecast = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 13), testBillRate.Id); //Week of August 8/7/2022 - 8/13/2022
        secondWeekOfJuneForecast.EstimatedHours__c = 2;
        RepliconForecast__c lastWeekOfAugustForecast = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 3), testBillRate.Id); //Also includes first week of September 8/28/2022 - 9/3/2022
        lastWeekOfAugustForecast.EstimatedHours__c = 3;
        RepliconForecast__c secondWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 10), testBillRate.Id); //Week of September 9/4/2022 - 9/10/2022
        secondWeekOfSeptemberForecast.EstimatedHours__c = 4;
        RepliconForecast__c lastWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 10, 1), testBillRate.Id); //Also includes first week of August 9/25/2022 - 10/1/2022
        lastWeekOfSeptemberForecast.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{firstWeekOfAugustForecast, secondWeekOfJuneForecast, lastWeekOfAugustForecast, secondWeekOfSeptemberForecast, lastWeekOfSeptemberForecast};

        Test.startTest();
        //insert Forecasts
        insert testRepliconForecastsToInsert;
        Test.stopTest();

        List<RepliconForecast__c> checkForecastsList = new List<RepliconForecast__c>();
        checkForecastsList = [SELECT Name, Week_Start_Date__c, Week_End_Date__c, EstimatedRevenue__c, EstimatedHours__c, Deleted_in_Replicon__c
                            FROM RepliconForecast__c
                            ORDER BY Week_End_Date__c ASC];

        Integer counter = 0;
        for(RepliconForecast__c forecast : checkForecastsList){
            counter++;
            System.debug('********************************* Test Forecast #' + counter + ' *********************************');
            System.debug(forecast.Name);
            System.debug(forecast);
        }

        //Query both the Monthly and Weekly Forecast $ AFTER the Forecasts get inserted
        List<Revenue_Forecast__c> monthlyTargetsAfter = [SELECT Id, MonthStartDate__c, MonthEndDate__c, MonthlyForecast__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE RecordTypeId =: monthlyTargetRT];

        for(Revenue_Forecast__c monthlyTarget : monthlyTargetsAfter){
            if(monthlyTarget.MonthStartDate__c.month() == 8){ //Assertion for the August 2022 Monthly Target
                //System.assertEquals(1320, monthlyTarget.MonthlyForecast__c, 'Monthly Forecast $ for August 2022 was incorrectly calculated after the insertion of Replicon Forecasts');

            }else if(monthlyTarget.MonthStartDate__c.month() == 9){ //Assertion for the September 2022 Monthly Target
                //System.assertEquals(2280, monthlyTarget.MonthlyForecast__c, 'Monthly Forecast $ for September 2022 was incorrectly calculated after the insertion of Replicon Forecasts');

            }
        }

        //Query the Weekly Target Actuals AFTER the Time Entries have been inserted
        List<Revenue_Forecast__c> weeklyTargetsAfter = [SELECT Id, WeekStartDate__c, WeekEndDate__c, WeeklyForecast__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE RecordTypeId =: weeklyTargetRT];

        Date weekStartDate;
        for(Revenue_Forecast__c weeklyTarget : weeklyTargetsAfter){
            weekStartDate = weeklyTarget.WeekStartDate__c;
            System.debug('Week Target: ' + weeklyTarget);

            if(weekStartDate == Date.newInstance(2022, 8, 1)){ //First Week of August 2022
                System.assertEquals(200, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the first week of August 2022 was incorrectly calculated after the insertion of Replicon Forecasts');

            }else if(weekStartDate == Date.newInstance(2022, 8, 7)){ //Second Week of August 2022
                System.assertEquals(400, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the second week of August 2022 was incorrectly calculated after the insertion of Replicon Forecasts');

            }else if(weekStartDate == Date.newInstance(2022, 8, 28)){ //Last Week of August 2022
                System.assertEquals(360, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the last week of August 2022 was incorrectly calculated after the insertion of Replicon Forecasts'); //Full Week Forecast of $600 broken into 5 days of the week = 240 per day (3 days in this August Week)

            }else if(weekStartDate == Date.newInstance(2022, 9, 1)){ //First Week of September 2022
                System.assertEquals(240, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the first week of September 2022 was incorrectly calculated after the insertion of Replicon Forecasts'); //Full Week Forecast of $600 broken into 5 days of the week = 240 per day (2 days in this September Week)

            }else if(weekStartDate == Date.newInstance(2022, 9, 4)){ //Second Week of September 2022 (Labor Day on 9/5/2022)
                System.assertEquals(800, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the second week of September 2022 was incorrectly calculated after the insertion of Replicon Forecasts');

            }else if(weekStartDate == Date.newInstance(2022, 9, 25)){ //Last Week of September 2022
                System.assertEquals(1000, weeklyTarget.WeeklyForecast__c, 'Weekly Forecast $ for the last week of September 2022 was incorrectly calculated after the insertion of Replicon Forecasts');
            }else{
                //Will get here for Weekly Targets that we are not asserting against.
                System.debug('Week Start Date Not Asserted Against for Forecasts: ' + weekStartDate);
            }
        }
    }

    @isTest
    static void rollupForecastsOnRelatedProjects_Test(){
        //Build the Forecasts
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name, Replicon_URI__c FROM Project_Team_Member_Billing_Rate__c WHERE Replicon_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123' LIMIT 1];
        

        RepliconForecast__c firstWeekOfAugustForecast = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 6), testBillRate.Id); //Also includes last week of July 7/31/2022 - 8/6/2022
        firstWeekOfAugustForecast.EstimatedHours__c = 1;
        RepliconForecast__c secondWeekOfJuneForecast = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 13), testBillRate.Id); //Week of August 8/7/2022 - 8/13/2022
        secondWeekOfJuneForecast.EstimatedHours__c = 2;
        RepliconForecast__c lastWeekOfAugustForecast = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 3), testBillRate.Id); //Also includes first week of September 8/28/2022 - 9/3/2022
        lastWeekOfAugustForecast.EstimatedHours__c = 3;
        RepliconForecast__c secondWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 10), testBillRate.Id); //Week of September 9/4/2022 - 9/10/2022
        secondWeekOfSeptemberForecast.EstimatedHours__c = 4;
        RepliconForecast__c lastWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 10, 1), testBillRate.Id); //Also includes first week of August 9/25/2022 - 10/1/2022
        lastWeekOfSeptemberForecast.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{firstWeekOfAugustForecast, secondWeekOfJuneForecast, lastWeekOfAugustForecast, secondWeekOfSeptemberForecast, lastWeekOfSeptemberForecast};

        Test.startTest();
        //insert Forecasts
        insert testRepliconForecastsToInsert;

        RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(testRepliconForecastsToInsert);
        Test.stopTest();
    }

    @isTest
    static void populateEffectiveBillingRateOnForecasts_Test(){

        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Replicon Forecast Trigger Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];


        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 185, Project__c = testProj.Id, Created_in_Salesforce__c = true);
        insert newBillRate;

        InternalProjTeamMemberLWCController.createEffectiveRate(testTeamMember.Id, testTeamMember.Assigned_Billing_Rate__c, newBillRate.Id, Date.newInstance(2022, 9, 5), testProj.CreatedDate);        

        RepliconForecast__c firstWeekOfAugustForecast = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 6), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        firstWeekOfAugustForecast.EstimatedHours__c = 1;
        RepliconForecast__c secondWeekOfJuneForecast = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 13), null); //Week of August 8/7/2022 - 8/13/2022
        secondWeekOfJuneForecast.EstimatedHours__c = 2;
        RepliconForecast__c lastWeekOfAugustForecast = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 3), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        lastWeekOfAugustForecast.EstimatedHours__c = 3;
        RepliconForecast__c secondWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 10), null); //Week of September 9/4/2022 - 9/10/2022
        secondWeekOfSeptemberForecast.EstimatedHours__c = 4;
        RepliconForecast__c lastWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 10, 1), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        lastWeekOfSeptemberForecast.EstimatedHours__c = 5;

        Test.startTest();
        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{firstWeekOfAugustForecast, secondWeekOfJuneForecast, lastWeekOfAugustForecast, secondWeekOfSeptemberForecast, lastWeekOfSeptemberForecast};
        insert testRepliconForecastsToInsert;

        RepliconForecastTriggerHelper.populateForecastBillingRate(testRepliconForecastsToInsert, true);
        Test.stopTest();

        
    }
}