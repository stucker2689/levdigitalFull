/**
 * Created by Sam Tucker 3/4/2022
 * Purpose: To Test RevenueForecastTrigger, RevenueForecastTriggerHandler, RevenueForecastTriggerHelper
 */
@isTest
private class RevenueForecastTriggerTest {

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
        oppo.Name = 'Revenue Forecast Trigger Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.Peoplesoft_Project_Id__c = '12345678';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Revenue Forecast Trigger Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Cognizant_Employee_Id__c = '99999';
        insert con;

        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = new Project_Team_Member_Billing_Rate__c();
        testProjMemberBillRate.Project__c = testProj.Id;
        testProjMemberBillRate.Hourly_Rate__c = 200;
        testProjMemberBillRate.Created_in_Salesforce__c = true;
        testProjMemberBillRate.Name = 'MC - Solution Architect';
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        insert testTeamMember;

        //Create Replicon Team Member
        //Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member


        //Create Replicon Team Member Billing Rate
        //Project_Team_Member_Billing_Rate__c testProjMemberBillRate2 = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
    }

    @isTest
    static void testCreateWeeklyRevenueForecastsFromMonthly() {
        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testCreateWeeklyRevenueForecastsFromMonthly START+++++++++++++++++++++++++++++++++');
        /**
         * Testing Purpose: Creating a Monthly Forecast should create a Weekly Forecast for each week within the month and specific fields
         */

        Revenue_Forecast__c testMarchMonthlyRevForecast = new Revenue_Forecast__c();
        testMarchMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testMarchMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 3, 1);
        testMarchMonthlyRevForecast.MonthlyTarget__c = 2300000; //23 Million for clean distribution of target to weeks because of 23 Business days in March 2022
        
        Test.startTest();
        insert testMarchMonthlyRevForecast;
        Test.stopTest();

        /************************************************************************************************ Monthly Target Assertions  ************************************************************************************************/
        Revenue_Forecast__c marchMonthlyTargetRevForecast = [SELECT Id, BusinessDaysInForecastRange__c, RevenueForecastName__c, MonthEndDate__c
                                                            FROM Revenue_Forecast__c
                                                            WHERE RecordTypeId =: monthlyTargetRT
                                                            LIMIT 1];

        System.assertEquals(23, marchMonthlyTargetRevForecast.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 31), marchMonthlyTargetRevForecast.MonthEndDate__c, 'Wrong Number of Business Days for March 2022');


        /************************************************************************************************ Weekly Target Assertions  ************************************************************************************************/
        //Assertions for the Weekly Target Revenue Forecasts created from Trigger for all Weeks related to the Monthly Target Forecast
        List<Revenue_Forecast__c> weeklyTargetRevForecastList = new List<Revenue_Forecast__c>();
        weeklyTargetRevForecastList = [SELECT Id, BusinessDaysInForecastRange__c, RevenueForecastName__c, WeekStartDate__c, WeekEndDate__c, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyTarget__c, RelatedMonthlyForecast__c
                                        FROM Revenue_Forecast__c
                                        WHERE RecordTypeId =: weeklyTargetRT
                                        ORDER BY WeekStartDate__c ASC]; //Order the query by Week Start Date ASC to get first week first in the list and last week last, (i.e So All weeks are in order First to Last)

        System.assertEquals(5, weeklyTargetRevForecastList.size(), 'Wrong Number of Weekly Targets created from the Month Revenue Forecast Creation'); //5 Weeks in March 2022 so 5 Weekly Targets should get created
        
        //Assertions for the first week of the March 2022 Week of 3/1 (Tuesday) -  3/5 (Saturday)
        Revenue_Forecast__c firstWeekTargetRecord =  weeklyTargetRevForecastList[0];
        System.assertEquals(marchMonthlyTargetRevForecast.Id, firstWeekTargetRecord.RelatedMonthlyForecast__c, 'Related Monthly Target Revenue Forecast not Populated correct on the Weekly Target for the First Weekly Target of March 2022');
        System.assertEquals(4, firstWeekTargetRecord.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for the First Week of March 2022'); 
        System.assertEquals(Date.newInstance(2022, 3, 1), firstWeekTargetRecord.WeekStartDate__c, 'Wrong assigned Start Date for the First Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 5), firstWeekTargetRecord.WeekEndDate__c, 'Wrong assigned End Date for the First Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 2, 27), firstWeekTargetRecord.FullWeekStartDate__c, 'Wrong assigned Full Week Start Date for the First Week of March 2022'); //Full Week Start Date for the First Week of March occurs in February
        System.assertEquals(Date.newInstance(2022, 3, 5), firstWeekTargetRecord.FullWeekEndDate__c, 'Wrong assigned Full Week End Date for the First Week of March 2022');
        System.assertEquals(400000, firstWeekTargetRecord.WeeklyTarget__c, 'Wrong assigned Full Week End Date for the First Week of March 2022'); //4 Business days and 100,000 Target per day (2.300,000 Monthly Target / 23 Business Days in the month) = 400,000
        

        //Assertions for the second week of the March 2022 Week of 3/6 (Sunday) -  3/12 (Saturday)
        Revenue_Forecast__c secondWeekTargetRecord =  weeklyTargetRevForecastList[1];
        System.assertEquals(marchMonthlyTargetRevForecast.Id, secondWeekTargetRecord.RelatedMonthlyForecast__c, 'Related Monthly Target Revenue Forecast not Populated correct on the Weekly Target for the Second Weekly Target of March 2022');
        System.assertEquals(5, secondWeekTargetRecord.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for the Second Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 6), secondWeekTargetRecord.WeekStartDate__c, 'Wrong assigned Start Date for the Second Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 12), secondWeekTargetRecord.WeekEndDate__c, 'Wrong assigned End Date for the Second Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 6), secondWeekTargetRecord.FullWeekStartDate__c, 'Wrong assigned Full Week Start Date for the Second Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 12), secondWeekTargetRecord.FullWeekEndDate__c, 'Wrong assigned Full Week End Date for the Second Week of March 2022');
        System.assertEquals(500000, secondWeekTargetRecord.WeeklyTarget__c, 'Wrong assigned Full Week End Date for the Second Week of March 2022'); //5 Business days and 100,000 Target per day (2.300,000 Monthly Target / 23 Business Days in the month) = 500,000

        //Assertions for the third week of the March 2022 Week of 3/13 (Sunday) -  3/19 (Saturday)
        Revenue_Forecast__c thirdWeekTargetRecord =  weeklyTargetRevForecastList[2];
        System.assertEquals(marchMonthlyTargetRevForecast.Id, thirdWeekTargetRecord.RelatedMonthlyForecast__c, 'Related Monthly Target Revenue Forecast not Populated correct on the Weekly Target for the Third Weekly Target of March 2022');
        System.assertEquals(5, thirdWeekTargetRecord.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for the Third Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 13), thirdWeekTargetRecord.WeekStartDate__c, 'Wrong assigned Start Date for the Third Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 19), thirdWeekTargetRecord.WeekEndDate__c, 'Wrong assigned End Date for the Third Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 13), thirdWeekTargetRecord.FullWeekStartDate__c, 'Wrong assigned Full Week Start Date for the Third Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 19), thirdWeekTargetRecord.FullWeekEndDate__c, 'Wrong assigned Full Week End Date for the Third Week of March 2022');
        System.assertEquals(500000, thirdWeekTargetRecord.WeeklyTarget__c, 'Wrong assigned Full Week End Date for the Third Week of March 2022'); //5 Business days and 100,000 Target per day (2.300,000 Monthly Target / 23 Business Days in the month) = 500,000
        

        //Assertions for the fourth week of the March 2022 Week of 3/20 (Sunday) -  3/26 (Saturday)
        Revenue_Forecast__c fourthWeekTargetRecord =  weeklyTargetRevForecastList[3];
        System.assertEquals(marchMonthlyTargetRevForecast.Id, fourthWeekTargetRecord.RelatedMonthlyForecast__c, 'Related Monthly Target Revenue Forecast not Populated correct on the Weekly Target for the Fourth Weekly Target of March 2022');
        System.assertEquals(5, fourthWeekTargetRecord.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for the Fourth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 20), fourthWeekTargetRecord.WeekStartDate__c, 'Wrong assigned Start Date for the Fourth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 26), fourthWeekTargetRecord.WeekEndDate__c, 'Wrong assigned End Date for the Fourth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 20), fourthWeekTargetRecord.FullWeekStartDate__c, 'Wrong assigned Full Week Start Date for the Fourth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 26), fourthWeekTargetRecord.FullWeekEndDate__c, 'Wrong assigned Full Week End Date for the Fourth Week of March 2022');
        System.assertEquals(500000, fourthWeekTargetRecord.WeeklyTarget__c, 'Wrong assigned Full Week End Date for the Fourth Week of March 2022'); //5 Business days and 100,000 Target per day (2.300,000 Monthly Target / 23 Business Days in the month) = 500,000

        //Assertions for the fifth week of the March 2022 Week of 3/27 (Sunday) -  3/31 (Thursday)
        Revenue_Forecast__c fifthWeekTargetRecord =  weeklyTargetRevForecastList[4];
        System.assertEquals(marchMonthlyTargetRevForecast.Id, fifthWeekTargetRecord.RelatedMonthlyForecast__c, 'Related Monthly Target Revenue Forecast not Populated correct on the Weekly Target for the Fifth Weekly Target of March 2022');
        System.assertEquals(4, fifthWeekTargetRecord.BusinessDaysInForecastRange__c, 'Wrong Number of Business Days for the Fifth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 27), fifthWeekTargetRecord.WeekStartDate__c, 'Wrong assigned Start Date for the Fifth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 31), fifthWeekTargetRecord.WeekEndDate__c, 'Wrong assigned End Date for the Fifth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 3, 27), fifthWeekTargetRecord.FullWeekStartDate__c, 'Wrong assigned Full Week Start Date for the Fifth Week of March 2022');
        System.assertEquals(Date.newInstance(2022, 4, 2), fifthWeekTargetRecord.FullWeekEndDate__c, 'Wrong assigned Full Week End Date for the Fifth Week of March 2022'); //Full Week End Date for the Last Week of March occurs in April
        System.assertEquals(400000, fifthWeekTargetRecord.WeeklyTarget__c, 'Wrong assigned Full Week End Date for the Fifth Week of March 2022'); //4 Business days and 100,000 Target per day (2.300,000 Monthly Target / 23 Business Days in the month) = 400,000

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testCreateWeeklyRevenueForecastsFromMonthly END +++++++++++++++++++++++++++++++++');
	}

    @isTest
    static void testUpdateWeeklyTargets(){
        /**
         * Testing Purpose: Updating a Weekly Target's Weekly Target Amount should update the related Monthly Target Record by adding to the Monthly Target Amount by the amount that was added to the Weekly Forecasts it is related to
         */
        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyTargets START +++++++++++++++++++++++++++++++++');

        Revenue_Forecast__c testJanMonthlyRevForecast = new Revenue_Forecast__c();
        testJanMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJanMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 1, 1);
        testJanMonthlyRevForecast.MonthlyTarget__c = 1900000; //19 Million for clean distribution of target to weeks because of 19 Business days in January 2022 (There are 2 holidays in January, New Years (1/3/2022) & MLK Day (1/17/2022))


        Revenue_Forecast__c testFebMonthlyRevForecast = new Revenue_Forecast__c();
        testFebMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testFebMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 2, 1);
        testFebMonthlyRevForecast.MonthlyTarget__c = 1900000; //19 Million for clean distribution of target to weeks because of 19 Business days in February 2022 (There is one holiday in February, President's Day, on 2/21/2022)
        
        List<Revenue_Forecast__c> monthlyTargetRevenueForecastsTestList = new List<Revenue_Forecast__c>{testJanMonthlyRevForecast, testFebMonthlyRevForecast};
        insert monthlyTargetRevenueForecastsTestList;
        
        List<Revenue_Forecast__c> weeklyTargetsToUpdateList = new List<Revenue_Forecast__c>(); //Add updated Weekly Targets to a List to update them all at once.

        List<Revenue_Forecast__c> janWeeklyTargetsList = [SELECT Id, BusinessDaysInForecastRange__c, WeekStartDate__c, WeekEndDate__c, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyTarget__c, RelatedMonthlyForecast__c
                                                            FROM Revenue_Forecast__c
                                                            WHERE RelatedMonthlyForecast__c =: testJanMonthlyRevForecast.Id];
        //Update Multiple Weekly Target Amounts for January
        for(Revenue_Forecast__c janWeeklyTarget : janWeeklyTargetsList){
            //There are 6 total weeks in January 2022 so adding 125,000 to each Target = adding a total of 125,000 * 6 = 750,000
            janWeeklyTarget.WeeklyTarget__c += 125000;
            weeklyTargetsToUpdateList.add(janWeeklyTarget);
        }

        Revenue_Forecast__c febWeeklyTarget = [SELECT Id, BusinessDaysInForecastRange__c, WeekStartDate__c, WeekEndDate__c, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyTarget__c, RelatedMonthlyForecast__c
                                                FROM Revenue_Forecast__c
                                                WHERE RelatedMonthlyForecast__c =: testFebMonthlyRevForecast.Id
                                                LIMIT 1];

        //Update only one Weekly Target Amounts for February
        febWeeklyTarget.WeeklyTarget__c -= 50000; //Subtracting 50,000 from a single weekly target for February
        weeklyTargetsToUpdateList.add(febWeeklyTarget);


        Test.startTest();
        update weeklyTargetsToUpdateList;
        Test.stopTest();

        List<Revenue_Forecast__c> monthlyTargetsToCheck = [SELECT Id, BusinessDaysInForecastRange__c, MonthStartDate__c, MonthEndDate__c, MonthlyTarget__c
                                                            FROM Revenue_Forecast__c
                                                            WHERE RecordTypeId =: monthlyTargetRT];

        for(Revenue_Forecast__c monthlyForecast : monthlyTargetsToCheck){
            if(monthlyForecast.MonthStartDate__c.month() == 1){ //Assertion for the January Monthly Target
                //2,650,000 = Iniitial 1,900,000 + 750,000 of Weekly Target Amounts updated
                System.assertEquals(2650000, monthlyForecast.MonthlyTarget__c, 'Monthly Target Amount for January was not properly updated when multiple Weekly Target Amounts for that Month were updated'); 
            }else if(monthlyForecast.MonthStartDate__c.month() == 2){ //Assertion for the February Monthly Target
                //1,850,000 = Iniitial 1,900,000 - 50,000 of Weekly Target Amount updated
                System.assertEquals(1850000, monthlyForecast.MonthlyTarget__c, 'Monthly Target Amount for February was not properly updated when a single Weekly Target Amount for that Month was updated');
            }
        }

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyTargets END +++++++++++++++++++++++++++++++++');
    }

    @isTest
    static void testUpdateMonthlyTargets(){
        /**
         * Testing Purpose: Updating a Monthly Target's Monthly Target Amount should update the related Weekly Target Record by dividing amount changed of the Monthly Target into daily amounts 
         * and evenly dispersing that to each of the related weekly targets depending on their Business days in their ranges
         */

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateMonthlyTargets START +++++++++++++++++++++++++++++++++');
        Revenue_Forecast__c testAprilMonthlyRevForecast = new Revenue_Forecast__c();
        testAprilMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testAprilMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 4, 1);
        testAprilMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in April 2022

        Revenue_Forecast__c testMayMonthlyRevForecast = new Revenue_Forecast__c();
        testMayMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testMayMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 5, 1);
        testMayMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in May 2022 (There is one holiday in May 2022, Memorial Day, on 5/30/2022)

        List<Revenue_Forecast__c> testMonthlyRevForecastsInsertList = new List<Revenue_Forecast__c>{testAprilMonthlyRevForecast, testMayMonthlyRevForecast};
        insert testMonthlyRevForecastsInsertList;

        //Query the initial Weekly Forecasts to confirm the initial values of the Weekly Targets
        List<Revenue_Forecast__c> weeklyRevForecastsBeforeUpdate = [SELECT Id, BusinessDaysInForecastRange__c, WeekStartDate__c, WeekEndDate__c, WeeklyTarget__c, RelatedMonthlyForecast__c
                                                                    FROM Revenue_Forecast__c
                                                                    WHERE RecordTypeId =: weeklyTargetRT];
                                                    
        for(Revenue_Forecast__c weeklyTarget : weeklyRevForecastsBeforeUpdate){
            Decimal expectedWeeklyTarget = 100000 * weeklyTarget.BusinessDaysInForecastRange__c; //Expect the weekly target to be 100,000 * the business days in the week for both April and May Weekly Targets
            if(weeklyTarget.WeekStartDate__c.month() == 4){
                System.assertEquals(expectedWeeklyTarget,  weeklyTarget.WeeklyTarget__c, 'Weekly Targets Initial Weekly Target Amount was not set Properly for weeks of April 2022');
            }else if(weeklyTarget.WeekStartDate__c.month() == 5){
                System.assertEquals(expectedWeeklyTarget,  weeklyTarget.WeeklyTarget__c, 'Weekly Targets Initial Weekly Target Amount was not set Properly for Weeks of May 2022');
            }
        }

        //Query the Monthly Targets to update the Monthly Target Amounts
        List<Revenue_Forecast__c> monthlyRevForecasts = [SELECT Id, BusinessDaysInForecastRange__c, MonthStartDate__c, MonthEndDate__c, MonthlyTarget__c
                                                    FROM Revenue_Forecast__c
                                                    WHERE RecordTypeId =: monthlyTargetRT];

        List<Revenue_Forecast__c> monthlyForecastUpdateList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c monthlyTarget : monthlyRevForecasts){
            if(monthlyTarget.MonthStartDate__c.month() == 4){
                monthlyTarget.MonthlyTarget__c += 420000; //Add 420,000 to the April monthly Target so it gets spread evenly for 20,000 per business day of April
                monthlyForecastUpdateList.add(monthlyTarget);
            }else if(monthlyTarget.MonthStartDate__c.month() == 5){
                monthlyTarget.MonthlyTarget__c -= 420000; //Subtract 440,000 from the May monthly Target so it gets spread evenly for 20,000 per business day of May
                monthlyForecastUpdateList.add(monthlyTarget);
            }
        }

        Test.startTest();
        update monthlyForecastUpdateList;
        Test.stopTest();


        //Query the updated Weekly Forecasts to confirm the values of the Weekly Targets have been properly updated due to the Update on the parent Monthly Target amount. (The update should take the change amount and disperse it evenly by business days in the month then adjust the weekly targets in respect to that new change)
        List<Revenue_Forecast__c> weeklyRevForecastsAfterUpdate = [SELECT Id, BusinessDaysInForecastRange__c, WeekStartDate__c, WeekEndDate__c, WeeklyTarget__c, RelatedMonthlyForecast__c
                                                                    FROM Revenue_Forecast__c
                                                                    WHERE RecordTypeId =: weeklyTargetRT];
                                                    
        for(Revenue_Forecast__c weeklyTarget : weeklyRevForecastsAfterUpdate){
            Decimal expectedAprilWeeklyTarget = 120000 * weeklyTarget.BusinessDaysInForecastRange__c; //Expect the weekly target to be 120,000 * the business days in the week for both April Weekly Targets
            Decimal expectedMayWeeklyTarget = 80000 * weeklyTarget.BusinessDaysInForecastRange__c; //Expect the weekly target to be 80,000 * the business days in the week for both May Weekly Targets
            if(weeklyTarget.WeekStartDate__c.month() == 4){
                System.assertEquals(expectedAprilWeeklyTarget,  weeklyTarget.WeeklyTarget__c, 'Weekly Targets for April 2022 were not properely Updated after it\'s related Monthly Target was increased.');
            }else if(weeklyTarget.WeekStartDate__c.month() == 5){
                System.assertEquals(expectedMayWeeklyTarget,  weeklyTarget.WeeklyTarget__c, 'Weekly Targets for May 2022 were not properely Updated after it\'s related Monthly Target was decreased.');
            }
        }
        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateMonthlyTargets END +++++++++++++++++++++++++++++++++');
    }

    @isTest
    static void testUpdateWeeklyActualsFromRepliconEntryInsert(){
        /**
         * Testing Purpose: Updating the Weekly Actuals on a Weekly Target record will rollup to the Monthly amount when updated
         *                  Also test the Replicon Time Entry Trigger functionality that will add to the related Weekly Target Actuals $ when it is created in SF
         */
        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyActualsFromRepliconEntryInsert START +++++++++++++++++++++++++++++++++');

        System.debug('0.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        Revenue_Forecast__c testJuneMonthlyRevForecast = new Revenue_Forecast__c();
        testJuneMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJuneMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 6, 1);
        testJuneMonthlyRevForecast.MonthlyTarget__c = 2200000; //22 Million for clean distribution of target to weeks because of 22 Business days in June 2022

        Revenue_Forecast__c testJulyMonthlyRevForecast = new Revenue_Forecast__c();
        testJulyMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testJulyMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 7, 1);
        testJulyMonthlyRevForecast.MonthlyTarget__c = 2000000; //20 Million for clean distribution of target to weeks because of 20 Business days in July 2022 (There is one holiday in July 2022, July 4th Day, on 7/4/2022)

        List<Revenue_Forecast__c> testMonthlyRevForecastsInsertList = new List<Revenue_Forecast__c>{testJuneMonthlyRevForecast, testJulyMonthlyRevForecast};
        Test.startTest();
        insert testMonthlyRevForecastsInsertList;

        //System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //Query the Both Monthly and Weekly Target Actuals BEFORE the Time Entries get inserted
        List<Revenue_Forecast__c> revForecastsBefore = [SELECT Id, WeekStartDate__c, WeekEndDate__c, WeeklyActuals__c, MonthStartDate__c, MonthEndDate__c, MonthlyActuals__c, RecordTypeId
                                                        FROM Revenue_Forecast__c];

        //System.assertNotEquals(2, revForecastsBefore.size(), 'Wrong Number of Weekly Targets created from the Monthlyy Target Revenue Forecast Creation'); //Just asserting that there are Weekly Targets being created from the Monthly Forecast Creation
        for(Revenue_Forecast__c revForecast : revForecastsBefore){
            if(revForecast.RecordTypeId == weeklyTargetRT){
                //System.assertEquals(null, revForecast.WeeklyActuals__c, 'Weekly Targets were improperly created with Weekly Actuals already populated'); //Assert that Weekly Target Weekly Actuals field is not populated on Creation and Confirm it is all starting at 0 before Time Entry insert
            }else if(revForecast.RecordTypeId == monthlyTargetRT){
                //System.assertEquals(null, revForecast.MonthlyActuals__c, 'Monthly Targets were improperly created with Monthly Actuals already populated'); //Assert that Monthly Target Monthly Actuals were not populated on Creation
            }
        }


        //Build and insert the Timesheet First, then build the Time Entries
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Revenue Forecast Trigger Test Oppty' LIMIT 1];

        Replicon_Timesheet__c timesheetForFirstWeekOfJune = TestDataFactory.createTimesheet(false, testEmployee.Id);
        timesheetForFirstWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220529';
        timesheetForFirstWeekOfJune.Start_Date__c = Date.newInstance(2022, 5, 29); //Start of the Full Week of the First Week of June 2022 (Week Starts in May)
        
        Replicon_Timesheet__c timesheetForSecondWeekOfJune = TestDataFactory.createTimesheet(false, testEmployee.Id);
        timesheetForSecondWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220605';
        timesheetForSecondWeekOfJune.Start_Date__c = Date.newInstance(2022, 6, 5); //First Full Week Entirely in June 2022

        Replicon_Timesheet__c timesheetForFirstWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee.Id);
        timesheetForFirstWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220626';
        timesheetForFirstWeekOfJuly.Start_Date__c = Date.newInstance(2022, 6, 26); //Start of the Full Week of the First Week of July 2022 (Week Starts in June)

        Replicon_Timesheet__c timesheetForSecondWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee.Id);
        timesheetForSecondWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForSecondWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 3); //First Full Week Entirely in July 2022

        Replicon_Timesheet__c timesheetForLastWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee.Id);
        timesheetForLastWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForLastWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 31); //First Full Week Entirely in July 2022

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstWeekOfJune, timesheetForSecondWeekOfJune, timesheetForFirstWeekOfJuly, timesheetForSecondWeekOfJuly, timesheetForLastWeekOfJuly};
        insert testTimesheetList;

        System.debug('2.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Replicon_Time_Entry__c lastWeekOfMayEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, testEmployee.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        lastWeekOfMayEntry.EntryDate__c = Date.newInstance(2022, 5, 31);
        lastWeekOfMayEntry.TotalHrs__c = 5;
        lastWeekOfMayEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfMayEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220531';       
        lastWeekOfMayEntry.Billing_Action__c = 'B'; 

        Replicon_Time_Entry__c firstWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, testEmployee.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        firstWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 1);
        firstWeekOfJuneEntry.TotalHrs__c = 6;
        firstWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220601';
        firstWeekOfJuneEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c secondWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, testEmployee.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 6);
        secondWeekOfJuneEntry.TotalHrs__c = 7;
        secondWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220606';
        secondWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c secondWeekOfJuneEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, testEmployee.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntryTwo.EntryDate__c = Date.newInstance(2022, 6, 8);
        secondWeekOfJuneEntryTwo.TotalHrs__c = 1.5;
        secondWeekOfJuneEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220608';
        secondWeekOfJuneEntryTwo.Billing_Action__c = 'B';

        Replicon_Time_Entry__c lastWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee.Id, testProj);
        lastWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 30);
        lastWeekOfJuneEntry.TotalHrs__c = 8;
        lastWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220631';
        lastWeekOfJuneEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c firstWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee.Id, testProj);
        firstWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntry.TotalHrs__c = 9;
        firstWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220701';
        firstWeekOfJulyEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c firstWeekOfJulyEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee.Id, testProj);
        firstWeekOfJulyEntryTwo.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202207012';
        firstWeekOfJulyEntryTwo.Billing_Action__c = 'U';

        Replicon_Time_Entry__c secondWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJuly.Id, testEmployee.Id, testProj);
        secondWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 3);
        secondWeekOfJulyEntry.TotalHrs__c = 10;
        secondWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220705';
        secondWeekOfJulyEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c lastWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, testEmployee.Id, testProj);
        lastWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 31);
        lastWeekOfJulyEntry.TotalHrs__c = 11;
        lastWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220731';
        lastWeekOfJulyEntry.Billing_Action__c = 'B';

        Replicon_Time_Entry__c firstWeekOfAugustEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, testEmployee.Id, testProj);
        firstWeekOfAugustEntry.EntryDate__c = Date.newInstance(2022, 8, 1);
        firstWeekOfAugustEntry.TotalHrs__c = 12;
        firstWeekOfAugustEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfAugustEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220801';
        firstWeekOfAugustEntry.Billing_Action__c = 'B';


        /**
         * Inserting Time:
         * Last Week of May 2022 Week 5/29 - 5/31 - 5 hours $1000 (1 Entry)
         * 1st June Week 2022 6/1 - 6/4 - 6 hours $1200 (1 Entry)
         * 2nd June Week 2022 6/5 - 6/11 - 8.5 hours $1700 (2 Entries)
         * Last Week of June 2022 6/26 - 6/30 - 8 hours $1600 (1 Entry)
         * 1st Week of July 2022 7/1 - 7/2 - 9 hours $1800 (2 Entries 1 Billable 1 Non-Billable) 
         * 2nd Week of July 2022 7/3 - 7/9 - 10 hours $2000 (1 Entry)
         * Last Week of July 2022 7/31 - 7/31 - 11 hours $2200 (1 Entry)
         * First Week of August 2022 8/1 - 8/6 12 hours $2400 (1 Entry)
         * 
         * Expected June Actuals = $4,500 
         * Expected July Actuals = $6,100
         */
        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{lastWeekOfMayEntry, firstWeekOfJuneEntry, secondWeekOfJuneEntry, secondWeekOfJuneEntryTwo, lastWeekOfJuneEntry, firstWeekOfJulyEntry, firstWeekOfJulyEntryTwo, secondWeekOfJulyEntry, lastWeekOfJulyEntry, firstWeekOfAugustEntry};

        //Test.startTest();
        //insert time entries
        insert timeEntriesList;
        Test.stopTest();

        System.debug('3.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        List<Replicon_Time_Entry__c> checkEntriesList = new List<Replicon_Time_Entry__c>();
        checkEntriesList = [SELECT Name, EntryDate__c, TotalHrs__c, Billable_Amount__c, Is_Billable__c, Deleted_in_Replicon__c, Project__r.Name, Employee__r.Name, WeekEndDate__c, Timesheet_Period__c
                            FROM Replicon_Time_Entry__c
                            ORDER BY WeekEndDate__c];

        Integer counter = 0;
        for(Replicon_Time_Entry__c entry : checkEntriesList){
            counter++;
            System.debug('********************************* Test Entry #' + counter + ' *********************************');
            System.debug(entry.Name);
            System.debug(entry);
        }

        //Query the Monthly Target Actuals AFTER the Time Entries have been inserted
        List<Revenue_Forecast__c> monthlyTargetsAfter = [SELECT Id, MonthStartDate__c, MonthEndDate__c, MonthlyActuals__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE RecordTypeId =: monthlyTargetRT];

        for(Revenue_Forecast__c revForecast : monthlyTargetsAfter){
            System.debug('********************************* Test Rev Forecast *********************************');
            System.debug(revForecast);
        }

        for(Revenue_Forecast__c monthlyTarget : monthlyTargetsAfter){
            if(monthlyTarget.MonthStartDate__c.month() == 6){ //Assertion for the June 2022 Monthly Target
                System.assertEquals(4500, monthlyTarget.MonthlyActuals__c, 'Monthly Actuals for June 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(monthlyTarget.MonthStartDate__c.month() == 7){ //Assertion for the July 2022 Monthly Target
                System.assertEquals(6000, monthlyTarget.MonthlyActuals__c, 'Monthly Actuals for July 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }
        }

        System.debug('4.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        //Query the Weekly Target Actuals AFTER the Time Entries have been inserted
        List<Revenue_Forecast__c> weeklyTargetsAfter = [SELECT Id, WeekStartDate__c, WeekEndDate__c, WeeklyActuals__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE RecordTypeId =: weeklyTargetRT];

        Date weekStartDate;
        for(Revenue_Forecast__c weeklyTarget : weeklyTargetsAfter){
            weekStartDate = weeklyTarget.WeekStartDate__c;

            if(weekStartDate == Date.newInstance(2022, 6, 1)){ //First Week of June 2022
                System.assertEquals(1200, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the first week of June 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(weekStartDate == Date.newInstance(2022, 6, 5)){ //Second Week of June 2022
                System.assertEquals(1700, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the second week of June 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(weekStartDate == Date.newInstance(2022, 6, 26)){ //Last Week of June 2022
                System.assertEquals(1600, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the last week of June 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(weekStartDate == Date.newInstance(2022, 7, 1)){ //First Week of July 2022
                System.assertEquals(1800, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the first week of July 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(weekStartDate == Date.newInstance(2022, 7, 3)){ //Second Week of July 2022
                System.assertEquals(2000, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the second week of July 2022 was incorrectly calculated after the insertion of Replicon Time Entries');

            }else if(weekStartDate == Date.newInstance(2022, 7, 31)){ //Last Week of July 2022
                System.assertEquals(2200, weeklyTarget.WeeklyActuals__c, 'Weekly Actuals for the last week of July 2022 was incorrectly calculated after the insertion of Replicon Time Entries');
            }else{
                //Will get here for Weekly Targets that we are not asserting against.
                System.debug('Week Start Date Not Asserted Against for Actuals: ' + weekStartDate);
            }
        }

        System.debug('5.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyActualsFromRepliconEntryInsert END +++++++++++++++++++++++++++++++++');

    }

    @isTest
    static void testUpdateWeeklyForecastsFromRepliconForecastsInsert(){
        /**
         * Testing Purpose: Updating the Weekly Forecast $ on a Weekly Target record will rollup to the Monthly amount when updated
         *                  Also test the Replicon Forecast Trigger functionality that will add to the related Weekly Target Forecast $ when it is created in SF
         */

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyForecastsFromRepliconForecastsInsert START +++++++++++++++++++++++++++++++++');
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
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Revenue Forecast Trigger Test Oppty' LIMIT 1];
        Project_Team_Member_Billing_Rate__c testBillRate = [SELECT Id, Name, Replicon_URI__c FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];
        

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

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateWeeklyForecastsFromRepliconForecastsInsert END +++++++++++++++++++++++++++++++++');
    }

    @isTest
    static void testUpdateBookings(){

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateBookings START +++++++++++++++++++++++++++++++++');

        Integer currentMonth = Date.today().month();
        Revenue_Forecast__c testCurrentMonthMonthlyRevForecast = new Revenue_Forecast__c();
        testCurrentMonthMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testCurrentMonthMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, currentMonth, 1);
        testCurrentMonthMonthlyRevForecast.MonthlyTarget__c = 2000000; //21 Million for clean distribution of target to weeks because of 21 Business days in September 2022 (There is one holiday in September 2022, Labor Day, on 9/5/2022)
        insert testCurrentMonthMonthlyRevForecast;

        Opportunity testOppty = [SELECT Id, Name, CloseDate, Amount FROM Opportunity WHERE Name = 'Revenue Forecast Trigger Test Oppty' LIMIT 1];
        testOppty.CloseDate = Date.newInstance(2022, currentMonth, 1);
        
        Test.startTest();
        update testOppty;
        Test.stopTest();

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testUpdateBookings END +++++++++++++++++++++++++++++++++');
    }


    @isTest
    static void testRevenueForecastCheckTriggerRun(){

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testRevenueForecastCheckTriggerRun START +++++++++++++++++++++++++++++++++');
        Test.startTest();
        RevenueForecastCheckTriggerRun.runWeeklyTargetChangedOnce();
        RevenueForecastCheckTriggerRun.runWeeklyTargetChangedOnce();
        RevenueForecastCheckTriggerRun.runMonthlyTargetChangedOnce();
        RevenueForecastCheckTriggerRun.runMonthlyTargetChangedOnce();
        Test.stopTest();

        System.debug('+++++++++++++++++++++++++++++++++ RevenueForecastTriggerTest testRevenueForecastCheckTriggerRun END +++++++++++++++++++++++++++++++++');

    }



}