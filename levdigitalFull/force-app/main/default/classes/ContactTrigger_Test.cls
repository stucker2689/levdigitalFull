/**
 * Created on 12/2/2022 ST
 * 
 * Test out ContactTriggerHandler, ContactTriggerHelper
 */
@isTest
public with sharing class ContactTrigger_Test {
    

    @TestSetup
    static void makeData(){
        
        //Create Accounts
        Account levAcct = TestDataFactory.createAccount(false, 'Partner');
        levAcct.Name = 'Levementum LLC';

        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        
        List<Account> setupAccountInsertList = new List<Account>{acct};
        insert setupAccountInsertList;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        //testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.StageName = 'Identifying an Opportunity';
        testOppty1.Name = 'Test Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;

        List<Opportunity> testOpportunitiesList = new List<Opportunity>{testOppty1};
        insert testOpportunitiesList;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Hire_Date__c = Date.newInstance(2022, 6, 1);
        testEmployee1.RampTime__c = 6;

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.FirstName = 'Test Employee';
        testEmployee2.LastName = 'Number Two';

        Contact testEmployee3 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee3.FirstName = 'Test Employee';
        testEmployee3.LastName = 'Number Three';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1};
        insert setupEmployeeInsertList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        testOppty1.StageName = 'Closed Won';
        //testOppty2.StageName = 'Closed Won';
        List<Opportunity> testUpdateOpptiesToClosedWonList = new List<Opportunity>{testOppty1};
        update testUpdateOpptiesToClosedWonList; 

        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =:testOppty1.Id LIMIT 1];
        testproj.RepliconURI__c = 'urn:replicon-tenant:levementum:time-allocation:20220606';
        update testProj;
        
        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, testEmployee1.Id, testProj.Id); //Named Test Replicon Team Member
 
        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        Replicon_Timesheet__c timesheetForFirstWeekOfJune = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForFirstWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220529';
        timesheetForFirstWeekOfJune.Start_Date__c = Date.newInstance(2022, 5, 29); //Start of the Full Week of the First Week of June 2022 (Week Starts in May)
        
        Replicon_Timesheet__c timesheetForSecondWeekOfJune = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForSecondWeekOfJune.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220605';
        timesheetForSecondWeekOfJune.Start_Date__c = Date.newInstance(2022, 6, 5); //First Full Week Entirely in June 2022

        Replicon_Timesheet__c timesheetForFirstWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForFirstWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220626';
        timesheetForFirstWeekOfJuly.Start_Date__c = Date.newInstance(2022, 6, 26); //Start of the Full Week of the First Week of July 2022 (Week Starts in June)

        Replicon_Timesheet__c timesheetForSecondWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForSecondWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForSecondWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 3); //First Full Week Entirely in July 2022

        Replicon_Timesheet__c timesheetForLastWeekOfJuly = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForLastWeekOfJuly.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220703';
        timesheetForLastWeekOfJuly.Start_Date__c = Date.newInstance(2022, 7, 31); //First Full Week Entirely in July 2022

        Replicon_Timesheet__c timesheetForCurrentWeek = TestDataFactory.createTimesheet(false, testEmployee1.Id);
        timesheetForCurrentWeek.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:currentWeek';
        Date currentDateStart = Date.today().toStartOfWeek();
        timesheetForCurrentWeek.Start_Date__c = currentDateStart; //First Full Week Entirely in July 2022

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstWeekOfJune, timesheetForSecondWeekOfJune, timesheetForFirstWeekOfJuly, timesheetForSecondWeekOfJuly, timesheetForLastWeekOfJuly, timesheetForCurrentWeek};
        insert testTimesheetList;

        Replicon_Time_Entry__c lastWeekOfMayEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, testEmployee1.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        lastWeekOfMayEntry.EntryDate__c = Date.newInstance(2022, 5, 31);
        lastWeekOfMayEntry.TotalHrs__c = 5;
        lastWeekOfMayEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfMayEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220531';        

        Replicon_Time_Entry__c firstWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJune.Id, testEmployee1.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        firstWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 1);
        firstWeekOfJuneEntry.TotalHrs__c = 6;
        firstWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220601';

        Replicon_Time_Entry__c secondWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, testEmployee1.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 6);
        secondWeekOfJuneEntry.TotalHrs__c = 7;
        secondWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220606';

        Replicon_Time_Entry__c secondWeekOfJuneEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJune.Id, testEmployee1.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        secondWeekOfJuneEntryTwo.EntryDate__c = Date.newInstance(2022, 6, 8);
        secondWeekOfJuneEntryTwo.TotalHrs__c = 1.5;
        secondWeekOfJuneEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJuneEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220608';

        Replicon_Time_Entry__c lastWeekOfJuneEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee1.Id, testProj);
        lastWeekOfJuneEntry.EntryDate__c = Date.newInstance(2022, 6, 30);
        lastWeekOfJuneEntry.TotalHrs__c = 8;
        lastWeekOfJuneEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJuneEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220631';

        Replicon_Time_Entry__c firstWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee1.Id, testProj);
        firstWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntry.TotalHrs__c = 9;
        firstWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220701';

        Replicon_Time_Entry__c firstWeekOfJulyEntryTwo = TestDataFactory.createTimeEntry(false, timesheetForFirstWeekOfJuly.Id, testEmployee1.Id, testProj);
        firstWeekOfJulyEntryTwo.EntryDate__c = Date.newInstance(2022, 7, 1);
        firstWeekOfJulyEntryTwo.TotalHrs__c = 0.5;
        firstWeekOfJulyEntryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfJulyEntryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202207012';

        Replicon_Time_Entry__c secondWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForSecondWeekOfJuly.Id, testEmployee1.Id, testProj);
        secondWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 3);
        secondWeekOfJulyEntry.TotalHrs__c = 10;
        secondWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        secondWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220705';

        Replicon_Time_Entry__c lastWeekOfJulyEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, testEmployee1.Id, testProj);
        lastWeekOfJulyEntry.EntryDate__c = Date.newInstance(2022, 7, 31);
        lastWeekOfJulyEntry.TotalHrs__c = 11;
        lastWeekOfJulyEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        lastWeekOfJulyEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220731';

        Replicon_Time_Entry__c firstWeekOfAugustEntry = TestDataFactory.createTimeEntry(false, timesheetForLastWeekOfJuly.Id, testEmployee1.Id, testProj);
        firstWeekOfAugustEntry.EntryDate__c = Date.newInstance(2022, 8, 1);
        firstWeekOfAugustEntry.TotalHrs__c = 12;
        firstWeekOfAugustEntry.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        firstWeekOfAugustEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20220801';


        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{lastWeekOfMayEntry, firstWeekOfJuneEntry, secondWeekOfJuneEntry, secondWeekOfJuneEntryTwo, lastWeekOfJuneEntry, firstWeekOfJulyEntry, firstWeekOfJulyEntryTwo, secondWeekOfJulyEntry, lastWeekOfJulyEntry, firstWeekOfAugustEntry};
        insert timeEntriesList;


    }

    @isTest
    static void updateWorkingHoursFromRampTimeUpdate(){

        Contact con = [SELECT Id, Name, Hire_Date__c, RampTime__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        con.Hire_Date__c = con.Hire_Date__c.addDays(7);
        Test.startTest();
        update con;
        Test.stopTest();

    }

    @isTest
    static void updateWorkingHoursFromTerminationDateUpdate(){
        Contact con = [SELECT Id, Name, Hire_Date__c, RampTime__c, Term_Date__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        con.Term_Date__c = con.Hire_Date__c.addDays(21);
        Test.startTest();
        update con;
        Test.stopTest();
    }

    @isTest
    static void updateWorkingHoursFromTargetUpdate(){
        Contact con = [SELECT Id, Name, Hire_Date__c, RampTime__c, Term_Date__c, Quarterly_Target__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        con.Quarterly_Target__c = 395;
        Test.startTest();
        update con;
        Test.stopTest();
    }


}