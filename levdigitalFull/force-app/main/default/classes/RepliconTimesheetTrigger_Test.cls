@isTest
private class RepliconTimesheetTrigger_Test {

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
        oppo.Name = 'Timesheet Trigger Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Department = 'Consulting';
        con.Division_New__c = 'Next Lev';
        con.Division__c = 'Not Ops Management';
        con.Quarterly_Target__c=414;
        con.RampTime__c = 10;
        con.Hire_Date__c = Date.today();
        insert con;

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        Revenue_Forecast__c testMarchMonthlyRevForecast = new Revenue_Forecast__c();
        testMarchMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testMarchMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 10, 1);
        testMarchMonthlyRevForecast.MonthlyTarget__c = 2100000;
        insert testMarchMonthlyRevForecast;
    }


    @isTest
    static void populateCapacityOnLevTimesheet_Test(){
        Contact testCon = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testCon.Id);
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.Start_Date__c = Date.newInstance(2022, 10, 9);

        Test.startTest();
        insert testTimesheet;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Capacity__c, Capacity__r.WeekStartDate__c, Capacity__r.WeekEndDate__c, Start_Date__c, End_Date__c, Is_Lev_Timesheet__c FROM Replicon_Timesheet__c WHERE Employee__c =: testCon.Id];

        for(Replicon_Timesheet__c timesheet : timesheetList){

            System.assertNotEquals(null, timesheet.Capacity__c, 'Capacity was not correctly linked to the timesheet');
            System.assertEquals(timesheet.Capacity__r.WeekStartDate__c, timesheet.Start_Date__c, 'Wrong Capacity week was linked to the Timesheet');
        }

    }

    @isTest
    static void updateWeeklyTargetOnContactTimesheet_Test(){
        Contact testCon = [SELECT Id, Name, Quarterly_Target__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testCon.Id);
        testTimesheet.Start_Date__c = Date.newInstance(2022, 10, 9);
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        insert testTimesheet;

        Test.startTest();
        testCon.Quarterly_Target__c = 345;
        update testCon;
        Test.stopTest();

        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Name, Capacity__c, Capacity__r.WeekStartDate__c, Capacity__r.WeekEndDate__c, Start_Date__c, End_Date__c, Is_Lev_Timesheet__c, Target__c FROM Replicon_Timesheet__c WHERE Id =: testTimesheet.Id LIMIT 1];


        System.assertNotEquals(30, assertTimesheet.Target__c, 'Timesheet Target was not correctly re-calculated');
        
        
    }


    @isTest
    static void rollupCapacityExpectedHours_Test(){
        //Build and insert the Timesheet First, then build the Time Entries
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testEmployee.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.Start_Date__c = Date.newInstance(2022, 10, 9); 
        testTimesheet.Target__c = 36;

        Test.startTest();
        insert testTimesheet;
        Test.stopTest();
        
        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Name, Start_Date__c, End_Date__c, Capacity__r.TotalExpectedHours__c, Target__c FROM Replicon_Timesheet__c WHERE Id =: testTimesheet.Id LIMIT 1];

        System.assertEquals(36, assertTimesheet.Capacity__r.TotalExpectedHours__c, 'Capacity Record incorrectly rolled up the total Expected Hours from Timesheet Target');
    }

    @isTest
    static void rollupCapacityTotalPTOHours_Test(){
        //Build and insert the Timesheet First, then build the Time Entries
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testEmployee.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.Start_Date__c = Date.newInstance(2022, 10, 9); 
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Target__c = 36;
        insert testTimesheet;

        Test.startTest();
        testTimesheet.Total_Time_Off_Hours__c = 8;
        update testTimesheet;
        Test.stopTest();
        
        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Name, Start_Date__c, End_Date__c, Capacity__r.TotalTimeOffHours__c, Total_Time_Off_Hours__c, Capacity__c, Capacity__r.Name, Target__c, EmployeeDepartment__c FROM Replicon_Timesheet__c WHERE Id =: testTimesheet.Id LIMIT 1];
        System.debug('Test Total PTO Hours Timesheet: ' + assertTimesheet);
        System.debug('Test Total PTO Hours Timesheet Employee Department: ' + assertTimesheet.EmployeeDepartment__c );
        System.debug('Test Total PTO Hours Timesheet Time Off Hours: ' + assertTimesheet.Total_Time_Off_Hours__c);
        System.debug('Test Total PTO Hours Timesheet Capacity: ' + assertTimesheet.Capacity__c);
        System.debug('Test Total PTO Hours Timesheet Capacity Name: ' + assertTimesheet.Capacity__r.Name);


        System.assertEquals(8, assertTimesheet.Capacity__r.TotalTimeOffHours__c, 'Capacity Record incorrectly rolled up the total Expected Hours from Timesheet Target');
    }

    @isTest
    static void rollupCapacityRollupsAfterTimesheetDelete_Test(){
        //Build and insert the Timesheet First, then build the Time Entries
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];

        Date timesheetWeekStartDate = Date.newInstance(2022, 10, 9); 
        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testEmployee.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Start_Date__c = timesheetWeekStartDate;
        testTimesheet.Target__c = 36;
        insert testTimesheet;

        testTimesheet.Total_Time_Off_Hours__c = 8;
        update testTimesheet;

        Capacity__c assertCapacityBefore = [SELECT Id, Name, WeekStartDate__c, TotalTimeOffHours__c, TotalExpectedHours__c FROM Capacity__c WHERE WeekStartDate__c =: timesheetWeekStartDate LIMIT 1];

        System.assertEquals(8, assertCapacityBefore.TotalTimeOffHours__c, 'Capacity Record incorrectly rolled up the Total PTO Hours from Timesheet After Timesheet Updated');
        System.assertEquals(36, assertCapacityBefore.TotalExpectedHours__c, 'Capacity Record incorrectly rolled up the total Expected Hours from Timesheet After Timesheet Updated');

        Test.startTest();
        delete testTimesheet;
        Test.stopTest();
        
        Capacity__c assertCapacityAfter = [SELECT Id, Name, WeekStartDate__c, TotalTimeOffHours__c, TotalExpectedHours__c FROM Capacity__c WHERE WeekStartDate__c =: timesheetWeekStartDate LIMIT 1];

        System.assertEquals(0, assertCapacityAfter.TotalTimeOffHours__c, 'Capacity Record incorrectly rolled up the Total PTO Hours from Timesheet After Timesheet Deletion');
        System.assertEquals(0, assertCapacityAfter.TotalExpectedHours__c, 'Capacity Record incorrectly rolled up the total Expected Hours from Timesheet After Timesheet Deletion');
    }

    @isTest
    static void changeTimesheetCapacityLookup_Test(){
        //Build and insert the Timesheet First, then build the Time Entries
        Contact testEmployee = [SELECT Id, Name, Replicon_URI__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Timesheet Trigger Test Oppty' LIMIT 1];

        Date timesheetWeekStartDate = Date.newInstance(2022, 10, 9); 
        Date newTimesheetWeekStartDate = Date.newInstance(2022, 10, 9); 
        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, testEmployee.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet.Name = 'Test Lev Employee: 10/9/2022';
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Start_Date__c = timesheetWeekStartDate;
        testTimesheet.Target__c = 36;
        insert testTimesheet;

        Test.startTest();
        testTimesheet.Start_date__c = newTimesheetWeekStartDate;
        update testTimesheet;
        Test.stopTest();

        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Name, Capacity__c, Capacity__r.WeekStartDate__c, Capacity__r.WeekEndDate__c, Start_Date__c, End_Date__c, Is_Lev_Timesheet__c FROM Replicon_Timesheet__c WHERE Employee__c =: testEmployee.Id];

        System.assertNotEquals(null, assertTimesheet.Capacity__c, 'Capacity was not correctly linked to the timesheet');
        System.assertEquals(assertTimesheet.Capacity__r.WeekStartDate__c, newTimesheetWeekStartDate, 'Wrong Capacity week was linked to the Timesheet after Timesheet Week Start Date Change');
    
    }

    @isTest
    static void getTimesheetTarget_Test(){

        System.debug(' 123456789 123456789 123456789 123456789 123456789 Get Timesheet Target Test START 123456789 123456789 123456789 123456789 123456789 123456789');

        Date currentWeekStartDate = Date.today().toStartOfWeeK();

        //getTimesheetExpectedHours(Decimal weeklyTarget, Decimal rampTime, Date rampEndDate, Date timesheetStartDate)
        Decimal rampTimeTwoTargetWeekZero = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 2, currentWeekStartDate.addDays(14), currentWeekStartDate);
        Decimal rampTimeTwoTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 2, currentWeekStartDate.addDays(14), currentWeekStartDate.addDays(7));
        Decimal rampTimeTwoTargetWeekTwo = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 2, currentWeekStartDate.addDays(14), currentWeekStartDate.addDays(14));

        System.assertEquals(67, rampTimeTwoTargetWeekZero, 'Target was not properly calculated for Week Zero of Ramp Time 2');
        System.assertEquals(90, rampTimeTwoTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 2');
        System.assertEquals(100, rampTimeTwoTargetWeekTwo, 'Target was not properly calculated for Week Two of Ramp Time 2');

        Decimal rampTimeThreeTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 3, currentWeekStartDate.addDays(14), currentWeekStartDate);
        Decimal rampTimeThreeTargetWeekTwo = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 3, currentWeekStartDate.addDays(14), currentWeekStartDate.addDays(7));
        Decimal rampTimeThreeTargetWeekThree = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 3, currentWeekStartDate.addDays(14), currentWeekStartDate.addDays(14));

        System.assertEquals(25, rampTimeThreeTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 3');
        System.assertEquals(67, rampTimeThreeTargetWeekTwo, 'Target was not properly calculated for Week Two of Ramp Time 3');
        System.assertEquals(100, rampTimeThreeTargetWeekThree, 'Target was not properly calculated for Week Three of Ramp Time 3');

        Decimal rampTimeFourTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 4, currentWeekStartDate.addDays(21), currentWeekStartDate);
        Decimal rampTimeFourTargetWeekTwo = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 4, currentWeekStartDate.addDays(21), currentWeekStartDate.addDays(7));
        Decimal rampTimeFourTargetWeekThree = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 4, currentWeekStartDate.addDays(21), currentWeekStartDate.addDays(14));
        Decimal rampTimeFourTargetWeekFour = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 4, currentWeekStartDate.addDays(21), currentWeekStartDate.addDays(21));

        System.assertEquals(0, rampTimeFourTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 4');
        System.assertEquals(25, rampTimeFourTargetWeekTwo, 'Target was not properly calculated for Week Two of Ramp Time 4');
        System.assertEquals(67, rampTimeFourTargetWeekThree, 'Target was not properly calculated for Week Three of Ramp Time 4');
        System.assertEquals(100, rampTimeFourTargetWeekFour, 'Target was not properly calculated for Week Four of Ramp Time 4');

        Decimal rampTimeFiveTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 5, currentWeekStartDate.addDays(28), currentWeekStartDate);
        Decimal rampTimeFiveTargetWeekThree = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 5, currentWeekStartDate.addDays(28), currentWeekStartDate.addDays(14));
        Decimal rampTimeFiveTargetWeekFour = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 5, currentWeekStartDate.addDays(28), currentWeekStartDate.addDays(21));
        Decimal rampTimeFiveTargetWeekFive = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 5, currentWeekStartDate.addDays(28), currentWeekStartDate.addDays(28));

        System.assertEquals(0, rampTimeFiveTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 5');
        System.assertEquals(25, rampTimeFiveTargetWeekThree, 'Target was not properly calculated for Week Three of Ramp Time 5');
        System.assertEquals(67, rampTimeFiveTargetWeekFour, 'Target was not properly calculated for Week Four of Ramp Time 5');
        System.assertEquals(100, rampTimeFiveTargetWeekFive, 'Target was not properly calculated for Week Five of Ramp Time 5');
        
        Decimal rampTimeSixTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 6, currentWeekStartDate.addDays(35), currentWeekStartDate);
        Decimal rampTimeSixTargetWeekFour = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 6, currentWeekStartDate.addDays(35), currentWeekStartDate.addDays(21));
        Decimal rampTimeSixTargetWeekFive = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 6, currentWeekStartDate.addDays(35), currentWeekStartDate.addDays(28));
        Decimal rampTimeSixTargetWeekSix = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 6, currentWeekStartDate.addDays(35), currentWeekStartDate.addDays(35));

        System.assertEquals(0, rampTimeSixTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 6');
        System.assertEquals(25, rampTimeSixTargetWeekFour, 'Target was not properly calculated for Week Four of Ramp Time 6');
        System.assertEquals(67, rampTimeSixTargetWeekFive, 'Target was not properly calculated for Week Five of Ramp Time 6');
        System.assertEquals(100, rampTimeSixTargetWeekSix, 'Target was not properly calculated for Week Six of Ramp Time 6');
        
        Decimal rampTimeSevenTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 7, currentWeekStartDate.addDays(42), currentWeekStartDate);
        Decimal rampTimeSevenTargetWeekFive = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 7, currentWeekStartDate.addDays(42), currentWeekStartDate.addDays(28));
        Decimal rampTimeSevenTargetWeekSix = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 7, currentWeekStartDate.addDays(42), currentWeekStartDate.addDays(35));
        Decimal rampTimeSevenTargetWeekSeven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 7, currentWeekStartDate.addDays(42), currentWeekStartDate.addDays(42));

        System.assertEquals(0, rampTimeSevenTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 7');
        System.assertEquals(25, rampTimeSevenTargetWeekFive, 'Target was not properly calculated for Week Five of Ramp Time 7');
        System.assertEquals(67, rampTimeSevenTargetWeekSix, 'Target was not properly calculated for Week Six of Ramp Time 7');
        System.assertEquals(100, rampTimeSevenTargetWeekSeven, 'Target was not properly calculated for Week Seven of Ramp Time 7');

        Decimal rampTimeEightTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 8, currentWeekStartDate.addDays(49), currentWeekStartDate);
        Decimal rampTimeEightTargetWeekSix = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 8, currentWeekStartDate.addDays(49), currentWeekStartDate.addDays(35));
        Decimal rampTimeEightTargetWeekSeven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 8, currentWeekStartDate.addDays(49), currentWeekStartDate.addDays(42));
        Decimal rampTimeEightTargetWeekEight = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 8, currentWeekStartDate.addDays(49), currentWeekStartDate.addDays(49));

        System.assertEquals(0, rampTimeEightTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 8');
        System.assertEquals(25, rampTimeEightTargetWeekSix, 'Target was not properly calculated for Week Six of Ramp Time 8');
        System.assertEquals(67, rampTimeEightTargetWeekSeven, 'Target was not properly calculated for Week Seven of Ramp Time 8');
        System.assertEquals(100, rampTimeEightTargetWeekEight, 'Target was not properly calculated for Week Eight of Ramp Time 8');

        Decimal rampTimeNineTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 9, currentWeekStartDate.addDays(56), currentWeekStartDate);
        Decimal rampTimeNineTargetWeekSeven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 9, currentWeekStartDate.addDays(56), currentWeekStartDate.addDays(42));
        Decimal rampTimeNineTargetWeekEight = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 9, currentWeekStartDate.addDays(56), currentWeekStartDate.addDays(49));
        Decimal rampTimeNineTargetWeekNine = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 9, currentWeekStartDate.addDays(56), currentWeekStartDate.addDays(56));

        System.assertEquals(0, rampTimeNineTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 9');
        System.assertEquals(25, rampTimeNineTargetWeekSeven, 'Target was not properly calculated for Week Seven of Ramp Time 9');
        System.assertEquals(67, rampTimeNineTargetWeekEight, 'Target was not properly calculated for Week Eight of Ramp Time 9');
        System.assertEquals(100, rampTimeNineTargetWeekNine, 'Target was not properly calculated for Week Nine of Ramp Time 9');

        Decimal rampTimeTenTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate);
        Decimal rampTimeTenTargetWeekSix = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate.addDays(35));
        Decimal rampTimeTenTargetWeekSeven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate.addDays(42));
        Decimal rampTimeTenTargetWeekEight = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate.addDays(49));
        Decimal rampTimeTenTargetWeekNine = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate.addDays(56));
        Decimal rampTimeTenTargetWeekTen = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 10, currentWeekStartDate.addDays(63), currentWeekStartDate.addDays(63));

        System.assertEquals(0, rampTimeTenTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 10');
        System.assertEquals(42, rampTimeTenTargetWeekSix, 'Target was not properly calculated for Week Six of Ramp Time 10');
        System.assertEquals(56, rampTimeTenTargetWeekSeven, 'Target was not properly calculated for Week Seven of Ramp Time 10');
        System.assertEquals(70, rampTimeTenTargetWeekEight, 'Target was not properly calculated for Week Eight of Ramp Time 10');
        System.assertEquals(84, rampTimeTenTargetWeekNine, 'Target was not properly calculated for Week Nine of Ramp Time 10');
        System.assertEquals(100, rampTimeTenTargetWeekTen, 'Target was not properly calculated for Week Ten of Ramp Time 10');

        Decimal rampTimeFourteenTargetWeekOne = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate);
        Decimal rampTimeFourteenTargetWeekSeven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(49));
        Decimal rampTimeFourteenTargetWeekEight = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(56));
        Decimal rampTimeFourteenTargetWeekNine = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(63));
        Decimal rampTimeFourteenTargetWeekTen = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(70));
        Decimal rampTimeFourteenTargetWeekEleven = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(77));
        Decimal rampTimeFourteenTargetWeekTwelve = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(84));
        Decimal rampTimeFourteenTargetWeekThirteen = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(91));
        Decimal rampTimeFourteenTargetWeekFourteen = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(100, 14, currentWeekStartDate.addDays(98), currentWeekStartDate.addDays(98));

        System.assertEquals(0, rampTimeFourteenTargetWeekOne, 'Target was not properly calculated for Week One of Ramp Time 14');
        System.assertEquals(14, rampTimeFourteenTargetWeekSeven, 'Target was not properly calculated for Week Seven of Ramp Time 14');
        System.assertEquals(28, rampTimeFourteenTargetWeekEight, 'Target was not properly calculated for Week Eight of Ramp Time 14');
        System.assertEquals(42, rampTimeFourteenTargetWeekNine, 'Target was not properly calculated for Week Nine of Ramp Time 14');
        System.assertEquals(56, rampTimeFourteenTargetWeekTen, 'Target was not properly calculated for Week Ten of Ramp Time 14');
        System.assertEquals(70, rampTimeFourteenTargetWeekEleven, 'Target was not properly calculated for Week Eleven of Ramp Time 14');
        System.assertEquals(84, rampTimeFourteenTargetWeekTwelve, 'Target was not properly calculated for Week Twelve of Ramp Time 14');
        System.assertEquals(98, rampTimeFourteenTargetWeekThirteen, 'Target was not properly calculated for Week Thirteen of Ramp Time 14');
        System.assertEquals(100, rampTimeFourteenTargetWeekFourteen, 'Target was not properly calculated for Week Fourteen of Ramp Time 14');


        System.debug(' 123456789 123456789 123456789 123456789 123456789 Get Timesheet Target Test END 123456789 123456789 123456789 123456789 123456789 123456789');


    }
}