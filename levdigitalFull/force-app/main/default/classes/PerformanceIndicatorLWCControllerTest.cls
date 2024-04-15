/**
 * Created 5/28/2022 ST
 * 
 */
@isTest
public with sharing class PerformanceIndicatorLWCControllerTest {

    private static String nonbillOrConcessionCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Nonbill Request').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Account testAccount = TestDataFactory.createAccount(false, 'Client');

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{testAccount, levementumLLCAcct};
        insert testAccountList;

        Opportunity ptoTestOppty = TestDataFactory.createOpportunity(false, testAccount.Id, 'Salesforce');
        ptoTestOppty.Name = 'Test PTO Oppty';
        ptoTestOppty.StageName = 'Closed Won';
        ptoTestOppty.Amount = 10000;
        ptoTestOppty.Peoplesoft_Project_Id__c = '1234';
        ptoTestOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert ptoTestOppty;

        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Cognizant_Employee_Id__c = '12345678';
        insert con;
    }

    @isTest
    static void testGetNonBillOrConcessionCase(){

        Contact con = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c proj = [SELECT Id, Name FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        
        /*Project_Team_Member__c newPtm = new Project_Team_Member__c(Name = 'Test Project Team Member', Employee__c = con.Id, Project__c = proj.Id);
        insert newPtm;*/

        Client_Contact__c newPtm = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = proj.Id);
        insert newPtm;

        Case testCase = new Case(Subject = 'Test Non Bill Case', Approved_Denied__c = 'Approved', Final_Hours_Approved__c = 100, Final_Hours_Logged__c = 90, Project__c = proj.Id, RecordTypeId = nonbillOrConcessionCaseRT);
        insert testCase;

        Test.startTest();
        List<PerformanceIndicatorLWCController.concessionNonBillCaseWrapper> testConcessionNonBillWrapperList = PerformanceIndicatorLWCController.getConccessionAndNonBillCases(con.Id);
        Test.stopTest();

        System.assertEquals(1, testConcessionNonBillWrapperList.size(), 'Concession/Nonbill Cases were not properly retrieved');
    } 

    @isTest
    static void testGetHoursPerQuarter(){

        Contact con = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c proj = [SELECT Id, Name FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = proj.Id);
        Project_Team_Member_Billing_Rate__c concessionRate = new Project_Team_Member_Billing_Rate__c(Name = 'Concession', Hourly_Rate__c = 0, Project__c = proj.Id);
        List<Project_Team_Member_Billing_Rate__c> insertBillRateList = new List<Project_Team_Member_Billing_Rate__c>();
        insert insertBillRateList;

        Replicon_Time_Entry__c testcurrentQuarterEntry = TestDataFactory.createTimeEntry(false, null, con.Id, null);
        testcurrentQuarterEntry.Project__c = proj.Id;
        testcurrentQuarterEntry.Peoplesoft_Project_Id__c = '1234';
        testcurrentQuarterEntry.Cognizant_Employee_Id__c = '12345678';
        testcurrentQuarterEntry.EntryDate__c = Date.today();
        testcurrentQuarterEntry.TotalHrs__c = 8;
        testcurrentQuarterEntry.ActivityName__c = 'Activity';
        testcurrentQuarterEntry.Billing_Action__c = 'B';
        testcurrentQuarterEntry.Associated_Billing_Rate__c = devBillRate.Id;

        Replicon_Time_Entry__c testTwoYearsAgoEntry = TestDataFactory.createTimeEntry(false, null, con.Id, null);
        testTwoYearsAgoEntry.Project__c = proj.Id;
        testTwoYearsAgoEntry.Peoplesoft_Project_Id__c = '1234';
        testTwoYearsAgoEntry.Cognizant_Employee_Id__c = '12345678';
        testTwoYearsAgoEntry.EntryDate__c = Date.today().addYears(-2);
        testTwoYearsAgoEntry.TotalHrs__c = 8;
        testTwoYearsAgoEntry.ActivityName__c = 'Activity';
        testTwoYearsAgoEntry.Billing_Action__c = 'B';
        testTwoYearsAgoEntry.Associated_Billing_Rate__c = devBillRate.Id;

        Replicon_Time_Entry__c testConcessionEntry = TestDataFactory.createTimeEntry(false, null, con.Id, null);
        testConcessionEntry.Project__c = proj.Id;
        testConcessionEntry.Peoplesoft_Project_Id__c = '1234';
        testConcessionEntry.Cognizant_Employee_Id__c = '12345678';
        testConcessionEntry.EntryDate__c = Date.today();
        testConcessionEntry.TotalHrs__c = 8;
        testConcessionEntry.ActivityName__c = 'Activity';
        testConcessionEntry.Billing_Action__c = 'B';
        testConcessionEntry.Is_Concession__c = true;
        testConcessionEntry.Associated_Billing_Rate__c = concessionRate.Id;

        Replicon_Time_Entry__c testNonBillEntry = TestDataFactory.createTimeEntry(false, null, con.Id, null);
        testNonBillEntry.Project__c = proj.Id;
        testNonBillEntry.Peoplesoft_Project_Id__c = '1234';
        testNonBillEntry.Cognizant_Employee_Id__c = '12345678';
        testNonBillEntry.EntryDate__c = Date.today().addYears(-2);
        testNonBillEntry.TotalHrs__c = 8;
        testNonBillEntry.ActivityName__c = 'Activity';
        testNonBillEntry.Billing_Action__c = 'U';
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{testcurrentQuarterEntry, testTwoYearsAgoEntry, testConcessionEntry, testNonBillEntry};
        insert entryList;

        Test.startTest();
        List<PerformanceIndicatorLWCController.hoursPerQuarterWrapper> testHoursPerQuarterWrapperList = PerformanceIndicatorLWCController.getHoursPerQuarterForContact(con.Id);
        Test.stopTest();


    }

    @isTest
    static void testGetContactCertifications(){

        Contact con = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Certification__c testCert = new Certification__c(Type__c = 'Salesforce Certified Experience Cloud Consultant', Status__c = 'Current', Date_Certified__c = Date.today(), Employee__c = con.Id);
        insert testCert;

        Test.startTest();
        List<PerformanceIndicatorLWCController.certificationsWrapper> testCertificationWrapperList = PerformanceIndicatorLWCController.geCertificationsForContact(con.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetRelatedContact(){
        Contact con = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        Test.startTest();
        List<Contact> testContactList = PerformanceIndicatorLWCController.getRelatedContact(con.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetProjectActuals(){

        Date currentDate = Date.today();
        Date previousWeeksDate = currentDate.addDays(-7);
        Date nextWeeksDate = currentDate.addDays(7);

        Contact con = [SELECT Id, Name FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Project__c proj = [SELECT Id, Name FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 2', Hourly_Rate__c = 200, Project__c = proj.Id);
        insert devBillRate;

        Replicon_Time_Entry__c testEntry1 = new Replicon_Time_Entry__c(Employee__c = con.Id, TotalHrs__c = 8, EntryDate__c = Date.today(), Associated_Billing_Rate__c = devBillRate.Id, Project__c = proj.Id);
        Replicon_Time_Entry__c testEntry2 = new Replicon_Time_Entry__c(Employee__c = con.Id, TotalHrs__c = 4, EntryDate__c = Date.today().addDays(1), Associated_Billing_Rate__c = devBillRate.Id, Project__c = proj.Id);
        Replicon_Time_Entry__c testEntry3 = new Replicon_Time_Entry__c(Employee__c = con.Id, TotalHrs__c = 2, EntryDate__c = Date.today().addDays(-14), Associated_Billing_Rate__c = devBillRate.Id, Project__c = proj.Id);
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{testEntry1, testEntry2, testEntry3};
        insert entryList;

        RepliconForecast__c previousWeekForecast = TestDataFactory.createForecast(false, 'Previous Week Test Forecast', proj.Id, con.Id, previousWeeksDate, devBillRate.Id); 
        previousWeekForecast.EstimatedHours__c = 1;
        insert previousWeekForecast;

        Test.startTest();
        List<PerformanceIndicatorLWCController.employeeActualsAndForecastWrapper> testEmployeeActualsWrapperList = PerformanceIndicatorLWCController.getProjectActualsVsForecasts(con.Id);
        Test.stopTest();
    }

}