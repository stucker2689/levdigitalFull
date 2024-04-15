@isTest
public with sharing class CaseTriggerHelperTest {
    
    private static String internalEmployeeContactRT = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();

    private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();
    private static String dealDeskRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Deal Desk Request').getRecordTypeId();
    private static Id sowCaseRT = Schema.sObjectType.Case.getRecordTypeInfosByName().get('Lev SOW').getRecordTypeId();
    private static Id coSowCaseRT = Schema.sObjectType.Case.getRecordTypeInfosByName().get('LEV CO SOW').getRecordTypeId();
    private static Id salesforceRecordType = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String levSwapResourceRequestRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lev Swap Resource Request').getRecordTypeId();

    private static String sprintPlanWeekRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Week').getRecordTypeId();
    private static String sprintPlanMonthRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Month').getRecordTypeId();
    private static String sprintPlanQuarterRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Quarter').getRecordTypeId();

    @TestSetup
    static void createCase(){

        Account levInternalAccount = new Account();
        levInternalAccount.Name = 'Levementum LLC';
        insert levInternalAccount;

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Opp';
        opp1.StageName = 'Identifying an Opportunity';
        opp1.AccountId = levInternalAccount.Id;
        opp1.RecordTypeId = salesforceRecordType;
        opp1.Service__c = 'Program';
        opp1.Program_Type__c = 'Strategic';
        opp1.CloseDate = System.today().addDays(7);
        opp1.Amount = 5500.00;
        opp1.Start_Date__c = System.today().addDays(-7);
        opp1.End_Date__c = System.today().addDays(7);
        opp1.Do_Not_Create_Project__c = true;
        opp1.Change_Order_Revenue__c = 1000;
        opp1.Total_Amount_Invoiced_to_Date__c = 100;
        opp1.Payment_Terms__c = 'Time and Materials';
        opp1.Payment_Schedule__c = 'Standard T&M Monthly';
        opp1.Project_Terms__c = 'Time and Materials';
        opp1.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        opp1.SOW_Hyperlink__c = 'google.com';
        opp1.SOW_Number__C = 'SOW-2019-43891';
        opp1.CO_Number__c = 'CO-2019-40028';
        opp1.Next_Steps__c = 'Take the next steps on the opportunity';
        opp1.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        //opp1.Team_Retirement__c = 'Allyson Reagan';
        opp1.Signatures_Completed__c = true;
        opp1.Opportunity_Accuracy_Validated__c = true;
        opp1.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        opp1.RFP_Proposal__c = 'Yes';
        opp1.DeliveryMethodology__c = 'Agile';

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test Opportunity 2';
        opp2.StageName = 'Identifying an Opportunity';
        opp2.AccountId = levInternalAccount.Id;
        opp2.RecordTypeId = salesforceRecordType;
        opp2.Service__c = 'Program';
        opp2.Program_Type__c = 'Strategic';
        opp2.CloseDate = System.today().addDays(8);
        opp2.Amount = 5500.00;
        opp2.Start_Date__c = System.today().addDays(-8);
        opp2.End_Date__c = System.today().addDays(8);
        opp2.Do_Not_Create_Project__c = true;
        opp2.Change_Order_Revenue__c = 2000;
        opp2.Total_Amount_Invoiced_to_Date__c = 200;
        opp2.Payment_Terms__c = 'Time and Materials';
        opp2.Payment_Schedule__c = 'Standard T&M Monthly';
        opp2.Project_Terms__c = 'Time and Materials';
        opp2.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        opp2.SOW_Hyperlink__c = 'google.com';
        opp2.SOW_Number__C = 'SOW-2019-43892';
        opp2.CO_Number__c = 'CO-2019-40029';
        opp2.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        //opp2.Team_Retirement__c = 'Allyson Reagan';
        opp2.Signatures_Completed__c = true;
        opp2.Opportunity_Accuracy_Validated__c = true;
        opp2.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        opp2.RFP_Proposal__c = 'Yes';
        opp2.DeliveryMethodology__c = 'Agile';

        List<Opportunity> opptyList = new List<Opportunity>{opp1, opp2};
        insert opptyList;

        Contact testContact = new Contact();
        testContact.LastName = 'TestContact';
        testContact.FirstName = 'FirstName';
        testContact.RecordTypeId = internalEmployeeContactRT;
        testContact.Email = 'TestContact@levdigital.com';
        insert testContact;

        Case newCase = new Case();
        newCase.RecordTypeId = internalCaseRT;
        newCase.Subject = 'Sprint Field Test Case';
        newCase.ContactId = testContact.Id;
        newCase.Internal_Ops_Estimated_Hours__c = 100;
        newCase.Due_Date_Internal__c = Date.today().addDays(14);
        newCase.Start_Date__c = Date.today();        
        insert newCase;

        //This should create 7 Sprint Plan Weeks, 3 Sprint Plan Months, 2 Sprint Quarters
        //Estimated Hours per week = 10
        //Estimated Hours for May = 20, June = 40, July = 10
        //Estimated Hours for Q2 = 60, Q3 = 10
        Case newCaseWithSetDates = new Case();
        newCaseWithSetDates.RecordTypeId = internalCaseRT;
        newCaseWithSetDates.Subject = 'Sprint Plan Test Case With Defined Date Fields';
        newCaseWithSetDates.ContactId = testContact.Id;
        newCaseWithSetDates.Internal_Ops_Estimated_Hours__c = 70;
        newCaseWithSetDates.Start_Date__c = Date.valueOf('2021-05-27');
        newCaseWithSetDates.Due_Date_Internal__c = Date.valueOf('2021-07-08');
        insert newCaseWithSetDates;
    }


    @isTest
    static void createSprintFieldsTest(){

        //Query for created Test Case
        Case testThreeWeekSprintFieldsCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];

        //Get the Mondays for 3 sprint weeks that should be assigned for the Test Case to assert against
        DateTime startDateTime = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
        Integer daysToGoBack = 0;
        while(startDateTime.format('EEEE') != 'Monday'){
            startDateTime = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
            daysToGoBack++;
            startDateTime = startDateTime - daysToGoBack;
        }
        Date dateOfFirstMondaySprint = Date.valueOf(startDateTime);
        //Get Dates of the next 2 Sprint Weeks
        Date dateOfSecondMondaySprint = dateOfFirstMondaySprint.addDays(7);
        Date dateOfThirdMondaySprint = dateOfFirstMondaySprint.addDays(14);

        //Create expected String of the 3 sprint weeks to assert created Case Sprint Week with
        String expectedSprintWeeks;
        expectedSprintWeeks = String.valueOf(dateOfFirstMondaySprint.month()) + '/' +  String.valueOf(dateOfFirstMondaySprint.day()) + '/' + String.valueOf(dateOfFirstMondaySprint.year());
        expectedSprintWeeks += ';' + String.valueOf(dateOfSecondMondaySprint.month()) + '/' +  String.valueOf(dateOfSecondMondaySprint.day()) + '/' + String.valueOf(dateOfSecondMondaySprint.year());
        if((DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day())).format('EEEE') != 'Monday'){
            expectedSprintWeeks += ';' +  String.valueOf(dateOfThirdMondaySprint.month()) + '/' +  String.valueOf(dateOfThirdMondaySprint.day()) + '/' + String.valueOf(dateOfThirdMondaySprint.year());
        }

        String expectedSprintMonths;
        expectedSprintMonths = getSprintMonths(expectedSprintWeeks);
        String expectedSprintQuarters;
        expectedSprintQuarters = getSprintQuarters(expectedSprintMonths);

        Test.StartTest();
        //Assert that the correct Sprint Weeks, Months, and Quarters were assigned to the Case
        System.assertEquals(expectedSprintWeeks, testThreeWeekSprintFieldsCase.Sprint_Week__c, 'Internal Case Sprint Week not created properly');
        System.assertEquals(expectedSprintMonths, testThreeWeekSprintFieldsCase.Sprint_Month__c, 'Internal Case Sprint Month not created properly');
        System.assertEquals(expectedSprintQuarters, testThreeWeekSprintFieldsCase.Sprint_Quarter__c, 'Internal Case Sprint Quarter not created properly');

        Test.StopTest();

    }

    @isTest
    static void createSprintPlanTest(){
        Case testSprintPlansCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c 
                                    FROM Case 
                                    WHERE Subject = 'Sprint Plan Test Case With Defined Date Fields' LIMIT 1];
        
        List<Sprint_Plan__c> newCaseSprintPlans = new List<Sprint_Plan__c>();
        newCaseSprintPlans = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                FROM Sprint_Plan__c 
                                WHERE Case__c =: testSprintPlansCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeks = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanMonths = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanQuarters = new List<Sprint_Plan__c>();

        Decimal newCaseSprintPlanWeeksTotalEstimatedHours = 0;
        Decimal newCaseSprintPlanMonthsTotalEstimatedHours = 0;
        Decimal newCaseSprintPlanQuartersTotalEstimatedHours = 0;

        for(Sprint_Plan__c sp : newCaseSprintPlans){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeks.add(sp);
                newCaseSprintPlanWeeksTotalEstimatedHours += sp.Estimated_Hours_per_Week__c;
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonths.add(sp);
                newCaseSprintPlanMonthsTotalEstimatedHours += sp.Estimated_Hours_for_Month__c;
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuarters.add(sp);
                newCaseSprintPlanQuartersTotalEstimatedHours += sp.Estimated_Hours_for_Quarter__c;
            }
        }

        Test.StartTest();
        //Assert that Sprint Plans were created
        System.assertEquals(7, newCaseSprintPlanWeeks.size(), 'Wrong amount of Sprint Plan Weeks were created');
        System.assertEquals(3, newCaseSprintPlanMonths.size(), 'Wrong amount of Sprint Plan Months were created');
        System.assertEquals(2, newCaseSprintPlanQuarters.size(), 'Wrong amount of Sprint Plan Quarters were created');

        //Assert that the Estimated Hours were properly created
        System.assertEquals(10, newCaseSprintPlanWeeks[0].Estimated_Hours_per_Week__c, 'Wrong amount calculated for Estimate Week Hours');
        System.assertEquals(70, newCaseSprintPlanWeeksTotalEstimatedHours, 'Wrong amount of Hours Estimated for Sprint Weeks');
        System.assertEquals(70, newCaseSprintPlanMonthsTotalEstimatedHours, 'Wrong amount of Hours Estimated for Sprint Months');
        System.assertEquals(70, newCaseSprintPlanQuartersTotalEstimatedHours, 'Wrong amount of Hours Estimated for Sprint Quarters');
        
        Test.StopTest();
    }

    @isTest
    static void updateCaseEstimatedHours(){
        Case testSprintPlansCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c 
                                    FROM Case 
                                    WHERE Subject = 'Sprint Plan Test Case With Defined Date Fields' LIMIT 1];

        List<Sprint_Plan__c> newCaseSprintPlans = new List<Sprint_Plan__c>();
        newCaseSprintPlans = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                FROM Sprint_Plan__c 
                                WHERE Case__c =: testSprintPlansCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeksBefore = new List<Sprint_Plan__c>();

        Decimal newCaseSprintPlanWeeksTotalEstimatedHoursBefore = 0;
        Decimal newCaseSprintPlanMonthsTotalEstimatedHoursBefore = 0;
        Decimal newCaseSprintPlanQuartersTotalEstimatedHoursBefore = 0;

        for(Sprint_Plan__c sp : newCaseSprintPlans){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeksBefore.add(sp);
                newCaseSprintPlanWeeksTotalEstimatedHoursBefore += sp.Estimated_Hours_per_Week__c;
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonthsTotalEstimatedHoursBefore += sp.Estimated_Hours_for_Month__c;
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuartersTotalEstimatedHoursBefore += sp.Estimated_Hours_for_Quarter__c;
            }
        }

        Test.StartTest();
        //Assert that the Estimated Hours were properly created
        System.assertEquals(10, newCaseSprintPlanWeeksBefore[0].Estimated_Hours_per_Week__c, 'Wrong amount calculated for Estimate Week Hours');
        System.assertEquals(70, newCaseSprintPlanWeeksTotalEstimatedHoursBefore, 'Wrong amount of Hours Estimated for Sprint Weeks');
        System.assertEquals(70, newCaseSprintPlanMonthsTotalEstimatedHoursBefore, 'Wrong amount of Hours Estimated for Sprint Months');
        System.assertEquals(70, newCaseSprintPlanQuartersTotalEstimatedHoursBefore, 'Wrong amount of Hours Estimated for Sprint Quarters');

        //Change Case Estimated Hours which should get reflected in the related Sprint Plans
        testSprintPlansCase.Internal_Ops_Estimated_Hours__c = 140;
        update testSprintPlansCase;

        List<Sprint_Plan__c> newCaseSprintPlansAfterUpdate = new List<Sprint_Plan__c>();
        newCaseSprintPlansAfterUpdate = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                                Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                        FROM Sprint_Plan__c 
                                        WHERE Case__c =: testSprintPlansCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeksAfter = new List<Sprint_Plan__c>();

        Decimal newCaseSprintPlanWeeksTotalEstimatedHoursAfter = 0;
        Decimal newCaseSprintPlanMonthsTotalEstimatedHoursAfter = 0;
        Decimal newCaseSprintPlanQuartersTotalEstimatedHoursAfter = 0;

        for(Sprint_Plan__c sp : newCaseSprintPlansAfterUpdate){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeksAfter.add(sp);
                newCaseSprintPlanWeeksTotalEstimatedHoursAfter += sp.Estimated_Hours_per_Week__c;
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonthsTotalEstimatedHoursAfter += sp.Estimated_Hours_for_Month__c;
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuartersTotalEstimatedHoursAfter += sp.Estimated_Hours_for_Quarter__c;
            }
        }

        //Assert that the Estimated Hours were properly changed
        System.assertEquals(20, newCaseSprintPlanWeeksAfter[0].Estimated_Hours_per_Week__c, 'Wrong amount calculated for Estimate Week Hours');
        System.assertEquals(140, newCaseSprintPlanWeeksTotalEstimatedHoursAfter, 'Wrong amount of Hours Estimated for Sprint Weeks');
        System.assertEquals(140, newCaseSprintPlanMonthsTotalEstimatedHoursAfter, 'Wrong amount of Hours Estimated for Sprint Months');
        System.assertEquals(140, newCaseSprintPlanQuartersTotalEstimatedHoursAfter, 'Wrong amount of Hours Estimated for Sprint Quarters');
        
        Test.StopTest();
    }

    @isTest
    static void updateCaseDates(){
        Case testSprintPlansCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c 
                                    FROM Case 
                                    WHERE Subject = 'Sprint Plan Test Case With Defined Date Fields' LIMIT 1];

        Test.StartTest();

        testSprintPlansCase.Due_Date_Internal__c = Date.valueOf('2021-10-08');
        update testSprintPlansCase;

        List<Sprint_Plan__c> newCaseSprintPlans = new List<Sprint_Plan__c>();
        newCaseSprintPlans = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                FROM Sprint_Plan__c 
                                WHERE Case__c =: testSprintPlansCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeks = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanMonths = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanQuarters = new List<Sprint_Plan__c>();

        Decimal newCaseSprintPlanWeeksTotalEstimatedHours = 0;
        Decimal newCaseSprintPlanMonthsTotalEstimatedHours = 0;
        Decimal newCaseSprintPlanQuartersTotalEstimatedHours = 0;

        for(Sprint_Plan__c sp : newCaseSprintPlans){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeks.add(sp);
                newCaseSprintPlanWeeksTotalEstimatedHours += sp.Estimated_Hours_per_Week__c;
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonths.add(sp);
                newCaseSprintPlanMonthsTotalEstimatedHours += sp.Estimated_Hours_for_Month__c;
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuarters.add(sp);
                newCaseSprintPlanQuartersTotalEstimatedHours += sp.Estimated_Hours_for_Quarter__c;
            }
        }

        System.assertEquals(20, newCaseSprintPlanWeeks.size(), 'Wrong amount of Sprint Plan Weeks were added');
        System.assertEquals(6, newCaseSprintPlanMonths.size(), 'Wrong amount of Sprint Plan Months were added');
        System.assertEquals(3, newCaseSprintPlanQuarters.size(), 'Wrong amount of Sprint Plan Quarters were  added');

        Test.StopTest();


    }

    @isTest
    static void deleteSprintPlanTest(){
        Case testSprintPlansCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c 
                                    FROM Case 
                                    WHERE Subject = 'Sprint Plan Test Case With Defined Date Fields' LIMIT 1];

        Test.StartTest();

        testSprintPlansCase.Due_Date_Internal__c = Date.valueOf('2021-06-24');
        update testSprintPlansCase;

        List<Sprint_Plan__c> newCaseSprintPlans = new List<Sprint_Plan__c>();
        newCaseSprintPlans = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                FROM Sprint_Plan__c 
                                WHERE Case__c =: testSprintPlansCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeks = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanMonths = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanQuarters = new List<Sprint_Plan__c>();

        for(Sprint_Plan__c sp : newCaseSprintPlans){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeks.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonths.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuarters.add(sp);
            }
        }

        System.assertEquals(5, newCaseSprintPlanWeeks.size(), 'Wrong amount of Sprint Plan Weeks were deleted');
        System.assertEquals(2, newCaseSprintPlanMonths.size(), 'Wrong amount of Sprint Plan Months were deleted');
        System.assertEquals(1, newCaseSprintPlanQuarters.size(), 'Wrong amount of Sprint Plan Quarters were  deleted');

        Test.StopTest();
    }

    @isTest
    static void updateCaseSprintFieldsManuallyToEmpty(){
        Case testThreeWeekSprintFieldsCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        
        Test.StartTest();
        //Assert that Sprint Fields are all populated
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCase.Sprint_Week__c), 'Internal Case Sprint Week(s) were not created properly');
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCase.Sprint_Month__c), 'Internal Case Sprint Month(s) were not created properly');
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCase.Sprint_Quarter__c), 'Internal Case Sprint Quarter(s) were not created properly');
        //Update Case with no Sprint Fields
        testThreeWeekSprintFieldsCase.Sprint_Week__c = NULL;
        update testThreeWeekSprintFieldsCase;
        
        //Query for updated Case
        Case testThreeWeekSprintFieldsCaseAfterUpdate = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        //Assert that all sprint Fields were emptied
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Week__c), 'Internal Case Sprint Week(s) were not deleted properly');
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Month__c), 'Internal Case Sprint Month(s) were not deleted properly');
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Quarter__c), 'Internal Case Sprint Quarter(s) were not deleted properly');
        Test.StopTest();
    }

    @isTest
    static void manualCreateSprintPlan(){
        Case testThreeWeekSprintFieldsCase = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        

        Test.StartTest();
        testThreeWeekSprintFieldsCase.Sprint_Week__c = NULL;
        update testThreeWeekSprintFieldsCase;

        Case testThreeWeekSprintFieldsCaseAfterDelete = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];

        List<Sprint_Plan__c> newCaseSprintPlansBefore = new List<Sprint_Plan__c>();
        newCaseSprintPlansBefore = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                    FROM Sprint_Plan__c 
                                    WHERE Case__c =: testThreeWeekSprintFieldsCase.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeksBefore = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanMonthsBefore = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanQuartersBefore = new List<Sprint_Plan__c>();

        for(Sprint_Plan__c sp : newCaseSprintPlansBefore){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeksBefore.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonthsBefore.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuartersBefore.add(sp);
            }
        }
        //Assert that Sprint Plans were deleted
        System.assertEquals(0, newCaseSprintPlanWeeksBefore.size(), 'Wrong amount of Sprint Plan Weeks were deleted');
        System.assertEquals(0, newCaseSprintPlanMonthsBefore.size(), 'Wrong amount of Sprint Plan Months were deleted');
        System.assertEquals(0, newCaseSprintPlanQuartersBefore.size(), 'Wrong amount of Sprint Plan Quarters were deleted');

        //Assert that Sprint Fields are all populated
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterDelete.Sprint_Week__c), 'Internal Case Sprint Week(s) were not deleted properly after manual delete');
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterDelete.Sprint_Month__c), 'Internal Case Sprint Month(s) were not deleted properly after manual delete');
        System.assertEquals(true, String.isEmpty(testThreeWeekSprintFieldsCaseAfterDelete.Sprint_Quarter__c), 'Internal Case Sprint Quarter(s) were not deleted properly after manual delete');
        //Update Case with no Sprint Fields
        testThreeWeekSprintFieldsCase.Sprint_Week__c = '5/17/2021;5/24/2021;5/31/2021';
        update testThreeWeekSprintFieldsCase;
        
        //Query for updated Case
        Case testThreeWeekSprintFieldsCaseAfterUpdate = [SELECT Id, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        
        List<Sprint_Plan__c> newCaseSprintPlansAfter = new List<Sprint_Plan__c>();
        newCaseSprintPlansAfter = [SELECT Id, Name, RecordTypeId, Sprint_Week__c, Estimated_Hours_per_Week__c, Sprint_Month__c, Estimated_Hours_for_Month__c, 
                                    Sprint_Quarter__c, Estimated_Hours_for_Quarter__c  
                                    FROM Sprint_Plan__c 
                                    WHERE Case__c =: testThreeWeekSprintFieldsCaseAfterUpdate.Id];

        List<Sprint_Plan__c> newCaseSprintPlanWeeksAfter = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanMonthsAfter = new List<Sprint_Plan__c>();
        List<Sprint_Plan__c> newCaseSprintPlanQuartersAfter = new List<Sprint_Plan__c>();

        for(Sprint_Plan__c sp : newCaseSprintPlansAfter){
            if(sp.RecordTypeId == sprintPlanWeekRT){
                newCaseSprintPlanWeeksAfter.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanMonthRT){
                newCaseSprintPlanMonthsAfter.add(sp);
            }
            if(sp.RecordTypeId == sprintPlanQuarterRT){
                newCaseSprintPlanQuartersAfter.add(sp);
            }
        }
        Test.StopTest();
        
        //Assert that all sprint plans were created after Manual creation of Sprint Weeks
        System.assertEquals(3, newCaseSprintPlanWeeksAfter.size(), 'Wrong amount of Sprint Plan Weeks were created after manual update');
        System.assertEquals(1, newCaseSprintPlanMonthsAfter.size(), 'Wrong amount of Sprint Plan Months were created after manual update');
        System.assertEquals(1, newCaseSprintPlanQuartersAfter.size(), 'Wrong amount of Sprint Plan Quarters were created after manual update');
        //Assert that all sprint Fields were created after Manual creation of Sprint Weeks
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Week__c), 'Internal Case Sprint Week(s) were not created properly after manual update');
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Month__c), 'Internal Case Sprint Month(s) were not created properly after manual update');
        System.assertEquals(false, String.isEmpty(testThreeWeekSprintFieldsCaseAfterUpdate.Sprint_Quarter__c), 'Internal Case Sprint Quarter(s) were not created properly after manual update');
    }

    @isTest
    static void caseOpptyToDealDeskOppty(){
        /**Purpose:
         * Test logic to link Case_Opportunity__c field with Deal_Desk_Opportunity__c field on Case for Deal Desk Request Record Types
         */
        Contact testCont = [SELECT Id, Name, Email FROM Contact WHERE Email = 'TestContact@levdigital.com' LIMIT 1];
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Case newCase = new Case();
        newCase.RecordTypeId = dealDeskRequestCaseRT;
        newCase.Subject = 'Deal Desk Case Test';
        newCase.ContactId = testCont.Id;
        newCase.Internal_Ops_Estimated_Hours__c = 100;
        newCase.Due_Date_Internal__c = Date.today().addDays(14);
        newCase.Start_Date__c = Date.today();
        newCase.Case_Opportunity__c = testOpp.Id;        
        insert newCase;

        Case testDealDeskCase = [SELECT Id, Subject, Case_Opportunity__c, Deal_Desk_Opportunity__c FROM Case WHERE Id =: newCase.Id LIMIT 1];

        System.assertEquals(false, String.isEmpty(testDealDeskCase.Deal_Desk_Opportunity__c), 'Deal Desk Oppty was not populated at all');
        System.assertEquals(testDealDeskCase.Case_Opportunity__c, testDealDeskCase.Deal_Desk_Opportunity__c, 'Deal Desk Oppty was not properly populated');


    }

    @isTest
    static void internalCaseOwnerKanbanChange(){
        
        
        Case testOwnerChangeCase = [SELECT Id, OwnerId, Case_Owner__c, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = true AND userType = 'Standard' ORDER BY CreatedDate DESC LIMIT 1];

        Test.StartTest();
        testOwnerChangeCase.Case_Owner__c = testUser.Id;
        update testOwnerChangeCase;
        Test.StopTest();

        Case assertCase = [SELECT Id, OwnerId, Case_Owner__c, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];

        System.assertEquals(testUser.Id, assertCase.OwnerId, 'Case Owner not properly updated via Kanban Update Case Owner Button');
    }

    @isTest
    static void internalCaseOwnerStandardChange(){
        Case testOwnerChangeCase = [SELECT Id, OwnerId, Case_Owner__c, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = true AND userType = 'Standard' ORDER BY CreatedDate DESC LIMIT 1];

        Test.StartTest();
        testOwnerChangeCase.OwnerId = testUser.Id;
        update testOwnerChangeCase;
        Test.StopTest();

        Case assertCase = [SELECT Id, OwnerId, Case_Owner__c, Subject, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];

        System.assertEquals(testUser.Id, assertCase.Case_Owner__c, 'Case Owner not properly Updated via Standard Case Owner Update');
    }

    @isTest
    static void internalCaseUpdateFields(){
        Case testFieldsChangeCase = [SELECT Id, Subject, Start_Date__c, Due_Date_Internal__c, Sprint_Week__c, Sprint_Month__c, Sprint_Quarter__c FROM Case WHERE Subject = 'Sprint Field Test Case' LIMIT 1];

        Test.StartTest();
        testFieldsChangeCase.Subject = 'Test Subject Name Change';
        testFieldsChangeCase.Due_Date_Internal__c = Date.today().addDays(28);
        testFieldsChangeCase.Start_Date__c = Date.today().addDays(7);   
        testFieldsChangeCase.Internal_Ops_Estimated_Hours__c = 200;
        update testFieldsChangeCase;
        Test.StopTest();
    }

    @isTest
    static void levResourceSwapCaseCountOnInsert_Test(){
        Opportunity testOppty = [SELECT Id, Name, AccountId FROM Opportunity WHERE Name = 'Test Opp'];
        
        Project__c proj = TestDataFactory.createProject(false, testOppty.AccountId, testOppty.id);
        proj.Name = 'Test Project';
        insert proj;

        Case newCase = new Case();
        newCase.RecordTypeId = levSwapResourceRequestRT;
        newCase.Subject = 'Lev Swap Resource Case';
        newCase.Project__c = proj.Id;
        newCase.Status = 'New';   
        
        Test.startTest();
        insert newCase;
        Test.stopTest();

        Account assertAccount = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(0, assertAccount.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');
        
    }

    @isTest
    static void levResourceSwapCaseCountOnInsert2_Test(){
        Opportunity testOppty = [SELECT Id, Name, AccountId FROM Opportunity WHERE Name = 'Test Opp'];
        
        Project__c proj = TestDataFactory.createProject(false, testOppty.AccountId, testOppty.id);
        proj.Name = 'Test Project';
        insert proj;

        Case newCase = new Case();
        newCase.RecordTypeId = levSwapResourceRequestRT;
        newCase.Subject = 'Lev Swap Resource Case';
        newCase.Project__c = proj.Id;
        newCase.Status = 'Completed';   
        
        Test.startTest();
        insert newCase;
        Test.stopTest();

        Account assertAccount = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(1, assertAccount.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');
        
    }

    @isTest
    static void levResourceSwapCaseCountOnUpdate_Test(){
        Opportunity testOppty = [SELECT Id, Name, AccountId FROM Opportunity WHERE Name = 'Test Opp'];
        
        Project__c proj = TestDataFactory.createProject(false, testOppty.AccountId, testOppty.id);
        proj.Name = 'Test Project';
        insert proj;

        Case newCase = new Case();
        newCase.RecordTypeId = levSwapResourceRequestRT;
        newCase.Subject = 'Lev Swap Resource Case';
        newCase.Project__c = proj.Id;
        newCase.Status = 'New';   
        insert newCase;

        Account assertAccountBefore = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(0, assertAccountBefore.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');

        newCase.Status = 'Completed';
        Test.startTest();
        update newCase;
        Test.stopTest();

        Account assertAccountAfter = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(1, assertAccountAfter.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');
        
    }

    @isTest
    static void levResourceSwapCaseCountOnUpdate2_Test(){
        Opportunity testOppty = [SELECT Id, Name, AccountId FROM Opportunity WHERE Name = 'Test Opp'];
        
        Project__c proj = TestDataFactory.createProject(false, testOppty.AccountId, testOppty.id);
        proj.Name = 'Test Project';
        insert proj;

        Case newCase = new Case();
        newCase.RecordTypeId = levSwapResourceRequestRT;
        newCase.Subject = 'Lev Swap Resource Case';
        newCase.Project__c = proj.Id;
        newCase.Status = 'Completed';   
        insert newCase;

        Account assertAccountBefore = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(1, assertAccountBefore.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');

        newCase.Status = 'Cancelled';
        Test.startTest();
        update newCase;
        Test.stopTest();

        Account assertAccountAfter = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(0, assertAccountAfter.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');
        
    }

    @isTest
    static void levResourceSwapCaseCountOnDelete_Test(){
        Opportunity testOppty = [SELECT Id, Name, AccountId FROM Opportunity WHERE Name = 'Test Opp'];
        
        Project__c proj = TestDataFactory.createProject(false, testOppty.AccountId, testOppty.id);
        proj.Name = 'Test Project';
        insert proj;

        Case newCase = new Case();
        newCase.RecordTypeId = levSwapResourceRequestRT;
        newCase.Subject = 'Lev Swap Resource Case';
        newCase.Project__c = proj.Id;
        newCase.Status = 'Completed';   
        insert newCase;

        Account assertAccountBefore = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(1, assertAccountBefore.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');

        Test.startTest();
        delete newCase;
        Test.stopTest();

        Account assertAccountAfter = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];

        System.assertEquals(0, assertAccountAfter.Staff_Transitions_Amount__c, 'Accounts Staff Transitions Amount was calculated inproperly');
        
    }

    @isTest
    static void SOWCaseCountTestInsert(){
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        User testUser = [SELECT Id, Name, ManagerId FROM User WHERE IsActive = true AND userType = 'Standard' AND ManagerId != null ORDER BY CreatedDate DESC LIMIT 1];
        Case testSOWCase = new Case();
        testSOWCase.RecordTypeId = sowCaseRT;
        testSOWCase.Subject = 'Test SOW Case';
        testSOWCase.Case_Opportunity__c = testOpp.Id;
        testSOWCase.OwnerId = testUser.Id;
        testSOWCase.Who_is_your_Manager__c = testUser.Id;
        //testSOWCase.Manager_Name__c = testUser.Id;

        Test.StartTest();
        insert testSOWCase;
        Test.StopTest();
        
        //Assert That Opportunity Count Related_SOW_CO_SOW_Cases__c is = 1
        Opportunity validateOpp = [SELECT Id, Name, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        System.assertEquals(1, validateOpp.Related_SOW_CO_SOW_Cases__c, 'Related SOW Cases count was calculated improperly after SOW Insert');

    }

    @isTest
    static void SOWCaseCountTestUpdate(){
        Opportunity testOpp = [SELECT Id, Name, AccountId, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = true AND userType = 'Standard' AND ManagerId != null ORDER BY CreatedDate DESC LIMIT 1];
        Case testSOWCase = new Case();
        testSOWCase.RecordTypeId = sowCaseRT;
        testSOWCase.Subject = 'Test SOW Case';
        testSOWCase.Case_Opportunity__c = testOpp.Id;
        testSOWCase.OwnerId = testUser.Id;
        testSOWCase.Who_is_your_Manager__c = testUser.Id;
        //testSOWCase.Manager_Name__c = testUser.Id;
        insert testSOWCase;
        
        
        Opportunity testOpp2 = [SELECT Id, Name, AccountId, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        testSOWCase.Case_Opportunity__c = testOpp2.Id;
        Test.StartTest();
        update testSOWCase;
        Test.StopTest();

        //Assert That Opportunity Count Related_SOW_CO_SOW_Cases__c is = 0 and new Opp Count is = 1
        Opportunity validateOldOpp = [SELECT Id, Name, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Opportunity validateNewOpp = [SELECT Id, Name, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        System.assertEquals(0, validateOldOpp.Related_SOW_CO_SOW_Cases__c, 'Related SOW Cases count was calculated improperly after SOW Updated from this Opportunity');
        System.assertEquals(1, validateNewOpp.Related_SOW_CO_SOW_Cases__c, 'Related SOW Cases count was calculated improperly after SOW Updated to this Opportunity');

    }

    @isTest
    static void SOWCaseCountTestDelete(){
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = true AND userType = 'Standard' AND ManagerId != null ORDER BY CreatedDate DESC LIMIT 1];
        Case testSOWCase = new Case();
        testSOWCase.RecordTypeId = sowCaseRT;
        testSOWCase.Subject = 'Test SOW Case';
        testSOWCase.Case_Opportunity__c = testOpp.Id;
        testSOWCase.OwnerId = testUser.Id;
        testSOWCase.Who_is_your_Manager__c = testUser.Id;
        //testSOWCase.Manager_Name__c = testUser.Id;
        insert testSOWCase;

        Case deleteCase = [SELECT Id, Subject FROM Case WHERE Subject = 'Test SOW Case' LIMIT 1];
        delete deleteCase;

        //Assert That Opportunity Count Related_SOW_CO_SOW_Cases__c is = 0
        Opportunity validateOpp = [SELECT Id, Name, Related_SOW_CO_SOW_Cases__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        System.assertEquals(0, validateOpp.Related_SOW_CO_SOW_Cases__c, 'Related SOW Cases count was calculated improperly after SOW Delete');
    
    }

    private static String getSprintMonths(String sprintWeeksString){
        String monthMultiPicklist = '';
        List<String> sprintWeeks = new List<String>();
        sprintWeeks = sprintWeeksString.split(';');

        Set<String> sprintWeekMonthsSet = new Set<String>();
        for(String s : sprintWeeks){ 
            sprintWeekMonthsSet.add(s.substringBefore('/'));
        }
        System.debug('Sprint Week Months Set: ' + sprintWeekMonthsSet);
        for(String mn : sprintWeekMonthsSet){
            switch on mn{
                when '1'{
                    monthMultiPicklist += 'January' + ';';
                }
                when '2'{
                    monthMultiPicklist += 'February' + ';';
                }
                when '3'{
                    monthMultiPicklist += 'March' + ';';
                }
                when '4'{
                    monthMultiPicklist += 'April' + ';';
                }
                when '5'{
                    monthMultiPicklist += 'May' + ';';
                }
                when '6'{
                    monthMultiPicklist += 'June' + ';';
                }
                when '7'{
                    monthMultiPicklist += 'July' + ';';
                }
                when '8'{
                    monthMultiPicklist += 'August' + ';';
                }
                when '9'{
                    monthMultiPicklist += 'September' + ';';
                }
                when '10'{
                    monthMultiPicklist += 'October' + ';';
                }
                when '11'{
                    monthMultiPicklist += 'November' + ';';
                }
                when '12'{
                    monthMultiPicklist += 'December' + ';';
                }
            }
        }
      
        monthMultiPicklist = monthMultiPicklist.substring(0,monthMultiPicklist.length() - 1);
        return monthMultiPicklist;
    }
    
    private static String getSprintQuarters(String sprintMonthsString){        
        String quarterMultiPicklist = '';

        if(sprintMonthsString.contains('January') || sprintMonthsString.contains('February') || sprintMonthsString.contains('March')){
            quarterMultiPicklist += 'Q1;';
        }
        if(sprintMonthsString.contains('April') || sprintMonthsString.contains('May') || sprintMonthsString.contains('June')){
            quarterMultiPicklist += 'Q2;';
        }
        if(sprintMonthsString.contains('July') || sprintMonthsString.contains('August') || sprintMonthsString.contains('September')){
            quarterMultiPicklist += 'Q3;';
        }
        if(sprintMonthsString.contains('October') || sprintMonthsString.contains('November') || sprintMonthsString.contains('December')){
            quarterMultiPicklist += 'Q4;';
        }

        return quarterMultiPicklist.substring(0,quarterMultiPicklist.length() - 1);
    }
    
}