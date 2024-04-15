/**
 * Created by jmahapatra on 11/28/17.
 * 
 * ************************************Edits************************************
 * Author				Time			Purpose
 * Sam Tucker			3/25/2021		Moved Data Creation inside of Start.Test, Stop.Test environment to avoid query limits
 */

@IsTest
public with sharing class RepliconServiceTest {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    static Contact employee;
    static Project__c project;
    static Project__c projectOld;
    static Replicon_Timesheet__c timesheet;
    static Replicon_Time_Entry__c timeEntry;
    static String forecastName;
    static RepliconForecast__c forecastMatch;
    static RepliconForecast__c forecastNoMatch;

    @testSetup
    static void setupData() {
        System.debug('RepliconService setupData');
        Account newAccount = new Account();
        newAccount.Name = 'Testing Account';
        newAccount.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        newAccount.MSA_Number__c = 'MSA_Test01';
		
        Account newCompanyAccount = new Account();
        newCompanyAccount.Name = 'Levementum LLC';

        List<Account> acctList = new List<Account>{newAccount, newCompanyAccount};
        insert acctList;

        System.debug('RepliconService after Account Insert');
        
        Contact employee1 = new Contact();
        employee1.FirstName = 'Test';
        employee1.LastName = 'Employee1';
        employee1.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee1.Email = 'temployee1@levdigital.com';
        employee1.Replicon_User_Number__c = 1;
        employee1.RepliconLoginName__c = 'temployee1';
        employee1.AccountId = newCompanyAccount.Id;
        insert employee1;

        System.debug('RepliconService after Account Contact Insert');
        
        /*Contact employee2 = new Contact();
        employee2.FirstName = 'Test';
        employee2.LastName = 'Employee200';
        employee2.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        employee2.Email = 'temp2loyee200@levdigital.com';
        employee2.Replicon_User_Number__c = 200;
        employee2.RepliconLoginName__c = 'temployee200';
        insert employee2;*/
        
        Opportunity opportunity1 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        opportunity1.AccountId = newAccount.Id;
        opportunity1.Name = 'Test Project';
        opportunity1.CloseDate = system.today()+60;
        opportunity1.Start_Date__c = system.today()+10;
        opportunity1.End_Date__c = system.today()+40;
        opportunity1.Amount = 55000.00;
        opportunity1.StageName='Closed Won';
        opportunity1.ExpectedPro_DurationinWeeks__c = 3;
        opportunity1.Service__c = 'Program';
        opportunity1.Program_Type__c = 'Strategic';
        opportunity1.LeadSource = 'Salesforce.com';
        opportunity1.Lead_Source__c = 'Salesforce AE';
        opportunity1.Number_of_Contact_Rolls_Added__c = 2;
        opportunity1.Project_Terms__c = 'Time and Materials';
        opportunity1.LevementumVertical__c = 'Manufacturing';
        opportunity1.Payment_Terms__c = 'Invoice Net 15';
        opportunity1.Payment_Schedule__c = 'Standard TM';
        opportunity1.Signatures_Completed__c = true;
        opportunity1.Opportunity_Accuracy_Validated__c = true;

        Opportunity opportunity2 = TestDataFactory.createOpportunity(false, newAccount.Id, 'Salesforce');
        opportunity2.Name = 'Test Opp2';
        opportunity2.CloseDate = system.today()+60;
        opportunity2.Start_Date__c = system.today()+10;
        opportunity2.End_Date__c = system.today()+40;
        opportunity2.Amount = 55000.00;
        opportunity2.StageName='Closed Won';
        opportunity2.ExpectedPro_DurationinWeeks__c = 3;
        opportunity2.Service__c = 'Program';
        opportunity2.Program_Type__c = 'Strategic';
        opportunity2.LeadSource = 'Salesforce.com';
        opportunity2.Lead_Source__c = 'Salesforce AE';
        opportunity2.Number_of_Contact_Rolls_Added__c = 2;
        opportunity2.Project_Terms__c = 'Time and Materials';
        opportunity2.Payment_Terms__c = 'Invoice Net 15';
        opportunity2.LevementumVertical__c = 'Manufacturing';
        opportunity2.Payment_Schedule__c = 'Standard TM';
        opportunity2.Signatures_Completed__c = true;
        opportunity2.Opportunity_Accuracy_Validated__c = true;
        //1/18 ST Added Fields

        List<Opportunity> opptyList = new List<Opportunity>{opportunity1, opportunity2};
        insert opptyList;

        System.debug('RepliconService after Account Opportunity Insert');

        Project__c project1 = new Project__c();
        project1.Account__c = newAccount.Id;
        project1.Opportunity__c = opportunity1.Id;
        project1.Name = 'Test Project';
        project1.Project_Status__c = 'In Progress';
        project1.RepliconUri__c='urn:replicon-tenant:levementum:project:1154';

        // create a project to test against
        Project__c project2 = new Project__c();
        project2.Account__c = newAccount.Id;
        project2.Opportunity__c = opportunity1.Id;
        project2.Name = 'Test Opp2';
        project2.Project_Status__c = 'In Progress';
        project2.RepliconUri__c='urn:replicon-tenant:levementum:project:1155';

        Project__c project3 = new Project__c();
        project3.Account__c = newAccount.Id;
        project3.Opportunity__c = opportunity1.Id;
        project3.Name = 'Test Placeholder Project';
        project3.Project_Status__c = 'In Progress';
        project3.RepliconUri__c='urn:replicon-tenant:levementum:project:26030';

        Project__c project4 = new Project__c();
        project4.Account__c = newAccount.Id;
        project4.Opportunity__c = opportunity2.Id;
        project4.Name = 'Test Project Role Project';
        project4.Project_Status__c = 'In Progress';
        project4.RepliconUri__c='urn:replicon-tenant:levementum:project:1156';
        
        List<Project__c> projList = new List<Project__c>{project1, project2, project3, project4};
        insert projList;

        System.debug('RepliconService after Opportunity Insert');
        
        List<RepliconDropdowns__c> repliconDropdownList = new List<RepliconDropdowns__c>();
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Payment-Terms-Invoice-Net-15',Group__c='Project-Payment-Terms',Value__c='Invoice Net 15',uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f95'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Payment-Terms-Url',Group__c='Project-Payment-Terms',Value__c='Url',uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f95'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Terms-Time-and-Materials',Group__c='Project-Terms',Value__c='Time & Materials',uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Terms-Url',Group__c='Project-Terms',Value__c='URL',uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='BillingType-Time-and-Materials',Group__c='Project-BillingType',Value__c='Time and Materials',uri__c='urn:replicon:billing-type:time-and-material'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Project-Practice-URL',Group__c='Project-Practice',Value__c='URL',uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Practice-Other',Group__c='Project-Practice',Value__c='Other',uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Type-URL',Group__c='Project-Type',Value__c='Type',uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Type-Project',Group__c='test',Value__c='Other',uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Expense-Entry-Type-Fixed-Price',Group__c='test',Value__c='Other',uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-Inv-Schedule-Url',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Pr-InvTerms-Standard-TM',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Payment-Terms-Url',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Payment-Terms-Invoice-Net-15',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Practice-Url',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Practice-Other',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Pr-Terms-Url',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Pr-Terms-Time-and-Materials',Group__c='test',Value__c='Other',uri__c='test'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Type-Change-Order',Group__c='test',Value__c='Project',uri__c='urn:replicon-tenant:levementum:96d40141c32a'));
        repliconDropdownList.add(new RepliconDropdowns__c(Name='Ts-Type-Url',Group__c='test',Value__c='Project',uri__c='d3e5-4d5f-ba99-96d40141c32a'));
        insert repliconDropdownList;

        System.debug('RepliconService after RepliconDropdowns__c Insert');
    }

    static void init() {
        Account acct = TestClassUtil.newSampleAccount();
        employee = TestClassUtil.createContact(true, acct.Id);

        Opportunity opp = TestClassUtil.newSampleOpportunity(acct.Id, 'Test Opp');
        project = TestClassUtil.createProject(false, acct.Id, opp.Id);
        projectOld = TestClassUtil.createProject(false, acct.Id, opp.Id);
        Project__c projectNoMatch = TestClassUtil.createProject(false, acct.Id, opp.Id);
        List<Project__c> projList = new List<Project__c>{project, projectOld, projectNoMatch};
        insert projList;
        timesheet = TestClassUtil.createTimesheet(true, employee.Id);
        timeEntry = TestClassUtil.createTimeEntry(false, timesheet.Id, employee.Id, project);

        String employeeRepliconNum = String.valueOf(employee.Replicon_User_Number__c);
        String projectRepliconId = project.RepliconUri__c.substringAfterLast(':');

        Date sd = timesheet.Start_Date__c;
        Date ed = timesheet.Start_Date__c + 6;
        String timesheetStartString = DateTime.newInstance(sd.year(), sd.month(), sd.day()).format('MM/dd/YYYY');
        String timesheetEndString = DateTime.newInstance(ed.year(), ed.month(), ed.day()).format('MM/dd/YYYY');

        List<String> forecastDataPointList = new List<String>{
            timesheetStartString, 
            timesheetEndString, 
            employeeRepliconNum, 
            projectRepliconId
        };
        forecastName = String.join(forecastDataPointList, '-');
        forecastMatch = TestClassUtil.createForecast(true, forecastName, project.Id);

        //Project__c projectNoMatch = TestClassUtil.createProject(true, acct.Id, opp.Id);
        forecastNoMatch = TestClassUtil.createForecast(true, 'Let the rabbits wear glasses', projectNoMatch.Id);
    }

    @isTest
    static void getProjectTeamMembersTestInsert() { //Solo test run passed 1/26
        System.debug('****************TEST METHOD getProjectTeamMembersTestInsert****************');
        String teamMembersURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetAllProjectTeamMemberDetails';
        String taskURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetProjectActualsByTask';
        Test.startTest();
        List<Contact> queriedEmployees = [SELECT Id FROM Contact WHERE RecordType.Name = 'Employee'];
        Project__c queriedProject = [SELECT Id FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(teamMembersURL, 'RepliconServiceTeamMembersResponse');
        newHTTPMock.setStaticResource(taskURL, 'TaskResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getProjectInformation(queriedProject.Id);
        
        List<Error_Log_Lev__c> queriedErrorLogs = [SELECT Id, Error_Message__c, Line_Number__c FROM Error_Log_Lev__c];
        System.debug(queriedErrorLogs);
        Test.stopTest();
    }
    
    @isTest
    static void getProjectTeamMembersTestUpdate() { //Solo test run passed 1/26
        System.debug('****************TEST METHOD getProjectTeamMembersTestUpdate****************');
        String teamMembersURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetAllProjectTeamMemberDetails';
        String taskURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetProjectActualsByTask';
        Contact queriedEmployee = [SELECT Id FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        Project__c queriedProject = [SELECT Id FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        Project_Team_Member__c newTeamMember = new Project_Team_Member__c(Employee__c = queriedEmployee.Id, Project__c = queriedProject.Id);
        insert newTeamMember;
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Project_Team_Member__c = newTeamMember.Id, Hourly_Rate__c = 200, Replicon_URI__c = 'urn:replicon:project-specific-billing-rate');
        insert newRate;
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(teamMembersURL, 'RepliconServiceTeamMembersResponse');
        newHTTPMock.setStaticResource(taskURL, 'TaskResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getProjectInformation(queriedProject.Id);
        Test.stopTest();
        
    }
    /*
    @isTest
    static void getProjectTasksTestInsert() {
        String taskURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetProjectActualsByTask';
        
        Test.startTest();
        Project__c queriedProject = [SELECT Id, RepliconUri__c FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(taskURL, 'TaskResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTasksForProject(queriedProject);
        
        List<Error_Log_Lev__c> queriedErrorLogs = [SELECT Id, Error_Message__c, Line_Number__c FROM Error_Log_Lev__c];
        System.debug(queriedErrorLogs);
        Test.stopTest();
    }*/
    /*
    @isTest
    static void getProjectTasksTestUpdate() {
        String taskURL = 'https://na3.replicon.com/levementum/services/ProjectService1.svc/GetProjectActualsByTask';
        
        Project__c queriedProject = [SELECT Id, RepliconUri__c FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        Replicon_Project_Task__c newTask = new Replicon_Project_Task__c(Project__c = queriedProject.Id, Replicon_Uri__c = 'urn:replicon-tenant:levementum:task:1');
        insert newTask;
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(taskURL, 'TaskResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTasksForProject(queriedProject);
        
        List<Error_Log_Lev__c> queriedErrorLogs = [SELECT Id, Error_Message__c, Line_Number__c FROM Error_Log_Lev__c];
        System.debug(queriedErrorLogs);
        Test.stopTest();
    }*/
    
    @isTest
    static void getTimeEntriesInsert() {
        String timesheetURIURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetForDate';
        String timesheetDetailsURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetDetails';
        
        List<Id> employeeIDList = new List<Id>();
        Contact queriedEmployee = [SELECT Id, Name FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        employeeIDList.add(queriedEmployee.Id);
        Project__c queriedProject = [SELECT Id, Name FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        
        Project_Team_Member__c newTeamMember = new Project_Team_Member__c(Employee__c = queriedEmployee.Id, Project__c = queriedProject.Id);
        insert newTeamMember;
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Project_Team_Member__c = newTeamMember.Id, Hourly_Rate__c = 200, Replicon_URI__c = 'urn:replicon:project-specific-billing-rate');
        insert newRate;
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        newHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTimesheetEntries(System.Today(), employeeIDList);
        System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);
        Test.stopTest();
    }

    @isTest
    static void updateTimeEntriesTest() {
        String timesheetURIURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetForDate';
        String timesheetDetailsURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetDetails';
        
        List<Id> employeeIDList = new List<Id>();
        Contact queriedEmployee = [SELECT Id, Name FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        employeeIDList.add(queriedEmployee.Id);
        Project__c queriedProject = [SELECT Id, Name FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        
        Project_Team_Member__c newTeamMember = new Project_Team_Member__c(Employee__c = queriedEmployee.Id, Project__c = queriedProject.Id);
        insert newTeamMember;
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Name = 'Test Rate', Project__c = queriedProject.Id,  Project_Team_Member__c = newTeamMember.Id, Hourly_Rate__c = 200, Replicon_URI__c = 'urn:replicon:project-specific-billing-rate');
        insert newRate;
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        newHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTimesheetEntries(System.Today(), employeeIDList);
        System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);

        MultiStaticResourceCalloutMock secondHTTPMock = new MultiStaticResourceCalloutMock();
        secondHTTPMock.setStatus('SUCCESS');
        secondHTTPMock.setStatusCode(200);
        secondHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        secondHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse2');
        Test.setMock(HttpCalloutMock.class, secondHTTPMock);
        RepliconService newService2 = new RepliconService();
        newService2.getTimesheetEntries(System.Today(), employeeIDList);
        System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);
        Test.stopTest();
    }

    @isTest
    static void insertTimeEntriesWithBillingRates() {
        String timesheetURIURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetForDate';
        String timesheetDetailsURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetDetails';
        
        List<Id> employeeIDList = new List<Id>();
        Contact queriedEmployee = [SELECT Id, Name FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        employeeIDList.add(queriedEmployee.Id);
        Project__c queriedProject = [SELECT Id, Name FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        
        Project_Team_Member__c newTeamMember = new Project_Team_Member__c(Employee__c = queriedEmployee.Id, Project__c = queriedProject.Id);
        insert newTeamMember;
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Name = 'Test Rate', Project__c = queriedProject.Id,  Project_Team_Member__c = newTeamMember.Id, Hourly_Rate__c = 200, Replicon_URI__c = 'urn:replicon:project-specific-billing-rate');
        insert newRate;
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        newHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse3');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTimesheetEntries(System.Today(), employeeIDList);
        System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);
        Test.stopTest();
    }
    
    @isTest
    static void getTimeEntriesUpdate() {
        String timesheetURIURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetForDate';
        String timesheetDetailsURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetDetails';
        
        List<Id> employeeIDList = new List<Id>();
        Contact queriedEmployee = [SELECT Id FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        employeeIDList.add(queriedEmployee.Id);
        Project__c queriedProject = [SELECT Id FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        Project_Team_Member__c newTeamMember = new Project_Team_Member__c(Employee__c = queriedEmployee.Id, Project__c = queriedProject.Id);
        insert newTeamMember;
        Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c(Project_Team_Member__c = newTeamMember.Id, Project__c = queriedProject.Id, Hourly_Rate__c = 200, Replicon_URI__c = 'urn:replicon:project-specific-billing-rate');
        insert newRate;
        Replicon_Timesheet__c newTimeSheet = new Replicon_Timesheet__c(Employee__c = queriedEmployee.Id, Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:test1', Start_Date__c = System.today(), Status__c = 'Rejected');
        insert newTimeSheet;
        Replicon_Time_Entry__c newTimeEntry = new Replicon_Time_Entry__c(Replicon_Timesheet__c = newTimeSheet.Id, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:timesheet:test1', Project__c = queriedProject.Id, Employee__c = queriedEmployee.Id, Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:test2', EntryDate__c = System.today(), TotalHrs__c = 1);
        insert newTimeEntry;
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        newHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTimesheetEntries(System.Today(), employeeIDList);
        //System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);
        update [SELECT Id FROM Replicon_Time_Entry__c limit 100];
        Test.stopTest();
    }
    @isTest
    static void upsertProject_successTest() {
        // retrieve project to pass to upsert method
        Project__c projectData = [SELECT Id, Name FROM Project__c LIMIT 1];
        system.assertEquals('Test Project', projectData.Name);

        // retrieve replicon project data in apex wrapper
        Replicon.Project project = Replicon.getProjectById(projectData.Id);

        // instantiate payload to use in mock http request
        String successPayload = '{"d":{"displayText":"SFDC Test Project 2","name":"SFDC Test Project 2","slug":"sfdc-test-project-2","uri":"urn:replicon-tenant:levementum:project:1154"}}';

        // instantiate the http service mock
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.upsertProject(project, projectData.Id,false);

        Test.stopTest();

        // verify the replicon uri is set on the project record
        Project__c updatedProject = [SELECT Id, RepliconUri__c FROM Project__c WHERE Id=:projectData.Id];
        //system.assertNotEquals(null, updatedProject.RepliconUri__c);
        //system.assertEquals('urn:replicon-tenant:levementum:project:1154', updatedProject.RepliconUri__c);
        //system.assertEquals(null, updatedProject.RepliconUri__c);
    }

    @isTest
    static void upsertProject_errorTest() {
        // retrieve project to pass to upsert method
        Project__c p = [SELECT Id, Name FROM Project__c LIMIT 1];
        system.assertEquals('Test Project', p.Name);

        // retrieve replicon project data in apex wrapper
        Replicon.Project project = Replicon.getProjectById(p.Id);

        // instantiate payload to use in mock http request
        String errorPayload = '{"error":{"code":"Sender","correlationId":"033e7d3fa6064432820b1a2616cea867","reason":"Practice must be provided.\\u000d\\u000aPayment Terms must be provided.","details":{"notifications":[{"displayText":"Practice must be provided.","failureUri":null,"severityUri":"urn:replicon:validation-severity:error"},{"displayText":"Payment Terms must be provided.","failureUri":null,"severityUri":"urn:replicon:validation-severity:error"}]},"type":"ValidationError1"}}';

        // instantiate the http service mock
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'OK', errorPayload, new Map<String, String>());

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);

        RepliconService service = new RepliconService();
        String url = service.upsertProject(project, p.Id,false);

        Test.stopTest();

        // verify the replicon uri is not set on the project record
        //Project__c updatedProject = [SELECT Id, RepliconUri__c FROM Project__c WHERE Id=:p.Id];
        //system.assertEquals('urn:replicon-tenant:levementum:project:1154', updatedProject.RepliconUri__c);
    }

    @isTest
    static void sendErrorTest() {
        // simply calls the send error method of the replicon service to add code coverage

        RepliconService service = new RepliconService();
        service.sendError('test message');
    }

    @isTest
    static void upsertClient_successTest() {
        // retrieve project to pass to upsert method
        Account clientData = [SELECT Id, Name FROM Account LIMIT 1];
        system.assertEquals('Testing Account', clientData.Name);

        // retrieve replicon project data in apex wrapper
        Replicon.Client client = Replicon.getClientById(clientData.Id);

        // instantiate payload to use in mock http request
        String successPayload = '{"d":{"displayText":"SFDC Integration Test Client","name":"SFDC Integration Test Client","slug":"sfdc-integration-test-client","uri":"urn:replicon-tenant:levementum:client:401"}}';

        // instantiate the http service mock
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'OK', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.upsertClient(client, clientData.Id);


        Test.stopTest();

        // verify the replicon uri is set on the project record
        Account updatedAccount = [SELECT Id, RepliconClientUri__c FROM Account WHERE Id=:clientData.Id];
        system.assertNotEquals(null, updatedAccount.RepliconClientUri__c);
        system.assertEquals('urn:replicon-tenant:levementum:client:401', updatedAccount.RepliconClientUri__c);
    }

    @isTest
    static void upsertClient_errorTest() {
        // retrieve project to pass to upsert method
        Account clientData = [SELECT Id, Name FROM Account LIMIT 1];
        system.assertEquals('Testing Account', clientData.Name);

        // retrieve replicon project data in apex wrapper
        Replicon.Client client = Replicon.getClientById(clientData.Id);

        // instantiate payload to use in mock http request
        String errorPayload = '{"error":{"code":"Sender","correlationId":"033e7d3fa6064432820b1a2616cea867","reason":"Practice must be provided.\\u000d\\u000aPayment Terms must be provided.","details":{"notifications":[{"displayText":"Practice must be provided.","failureUri":null,"severityUri":"urn:replicon:validation-severity:error"},{"displayText":"Payment Terms must be provided.","failureUri":null,"severityUri":"urn:replicon:validation-severity:error"}]},"type":"ValidationError1"}}';

        // instantiate the http service mock
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'OK', errorPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.upsertClient(client, clientData.Id);


        Test.stopTest();

        // verify the replicon uri is set on the project record
        Account updatedAccount = [SELECT Id, RepliconClientUri__c FROM Account WHERE Id=:clientData.Id];
        system.assertEquals('urn:replicon-tenant:levementum:client:401', updatedAccount.RepliconClientUri__c);
    }

    @isTest
    static void getMonthTest(){
        Test.startTest();
        RepliconService srv = new RepliconService();
        System.assertEquals(1,srv.getMonth('JAN'));
        System.assertEquals(2,srv.getMonth('FEB'));
        System.assertEquals(3,srv.getMonth('MAR'));
        System.assertEquals(4,srv.getMonth('APR'));
        System.assertEquals(5,srv.getMonth('MAY'));
        System.assertEquals(6,srv.getMonth('JUN'));
        System.assertEquals(7,srv.getMonth('JUL'));
        System.assertEquals(8,srv.getMonth('AUG'));
        System.assertEquals(9,srv.getMonth('SEP'));
        System.assertEquals(10,srv.getMonth('OCT'));
        System.assertEquals(11,srv.getMonth('NOV'));
        System.assertEquals(12,srv.getMonth('DEC'));
        Test.stopTest();
    }

    @isTest
    static void UpdateProjectTest(){
        String successPayload = '{"rate":{"currencyUri":"urn:replicon-tenant:levementum:currency:1","amount":"185.00"},"projectUri":"urn:replicon-tenant:levementum:project:1154","effectiveDate":{"year":"2017","month":"11","day":"29"},"companyBillingRateUri":"urn:replicon:project-specific-billing-rate"}';

        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.UpdateProject(successPayload);
        Test.stopTest();
    }

    @isTest
    static void updateBillingRateTest()
    {
        String successPayload1 = '{"rate":{"currencyUri":"urn:replicon-tenant:levementum:currency:1","amount":"185.00"},"projectUri":"urn:replicon-tenant:levementum:project:1154","effectiveDate":{"year":"2017","month":"11","day":"29"},"companyBillingRateUri":"urn:replicon:project-specific-billing-rate"}';
        String successPayload2 = '{"d":null}';

        // instantiate the http service mock
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload2, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.updateBillingRate('TimeAndMaterialsProjectService1.svc/InsertBillingRateIntoProjectBillingRateSchedule',successPayload2);

        Test.stopTest();
    }

    @isTest
    static void checkTaskTest(){
        String successPayload = '{"d":[{"code":"SOW-2017-42391","costType":null,"customFields":null,"description":null,"displayText":"JanakiTest2CH","estimatedCost":null,"estimatedHours":null,"isClosed":false,"isClosedByInheritance":false,"isTimeEntryAllowed":true,"name":"JanakiTest2CH","parent":null,"percentCompleted":0,"slug":null,"timeAndExpenseEntryType":{"displayText":"Billable & Non-Billable","uri":"urn:replicon:time-and-expense-entry-type:billable-and-non-billable"},"timeEntryDateRange":{"endDate":null,"startDate":{"day":30,"month":11,"year":2017}},"uri":"urn:replicon-tenant:levementum:task:2332"}]}';

        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.checkTask('test task','urn:replicon-tenant:levementum:project:1154');
        Test.stopTest();
    }
    @isTest
    static void UpdateProjectEstimatedHoursTest(){
        String successPayload = '{"d":{"displayText":"TestPass-3","name":"TestPass-3","slug":"test-pass-3","uri":"urn:replicon-tenant:levementum:project:1154"}}';

        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.UpdateProjectEstimatedHours('urn:replicon-tenant:levementum:project:1154','10');
        Test.stopTest();
    }

    @isTest
    static void upsertTaskTest(){
        String successPayload = '{"d":{"displayText":"Ch-test45-2","uri":"urn:replicon-tenant:levementum:task:2333"}}';
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);


        Test.startTest();

        Project__c projectData = [SELECT Id, Name FROM Project__c where Name='Test Opp2' limit 1];
        Replicon.Task task = Replicon.getProjectTaskById(projectData.Id);

        RepliconService service = new RepliconService();
        service.upsertTask(task);
        Test.stopTest();
    }

    @isTest
    static void generateReportTest(){
        String successPayload = '{"d":{"displayText":"Ch-test45-2","payload":"Name Employee Name"}}';
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        RepliconService service = new RepliconService();
        service.generateReport('uri');
        Test.stopTest();
    }

    @isTest
    static void parseDateTest(){
        Test.startTest();
        String dt = '10 10 2017';

        RepliconService service = new RepliconService();
        Date newdt = service.parseDate(dt);
        System.assertEquals(2016,newdt.year());
        Test.stopTest();
    }
    
    @isTest 
    static void testAsyncTeammemberBatch() {
        Test.startTest();
        Project__c newProject = new Project__c(Name = 'Test');
        List<Project__c> newProjectList = new List<Project__c>{newProject};
        RepliconTeamMemberBatch newBatch = new RepliconTeamMemberBatch(newProjectList);
        Database.executeBatch(newBatch);
        Test.stopTest();
    }
    
    @isTest
    static void testAsyncTeammemberSchedulable() {
        Test.startTest();
        String hours = String.valueOf(Datetime.now().hour());
        String minutes = String.valueOf(Datetime.now().minute() + 1); 
        String seconds = String.valueOf(Datetime.now().second());
        String cronString = seconds + ' ' + minutes + ' ' + hours + ' * * ?';
        SchedulableContext nullSchedulableContext = NULL;
        RepliconTeamMemberBatchScheduler newSchedulable = new RepliconTeamMemberBatchScheduler(); 
        newSchedulable.execute(nullSchedulableContext);
        Test.stopTest();
    }
	
    @isTest 
    static void testAsyncTimeEntryBatch() {
        Test.startTest();
        RepliconTimeEntryBatch newBatch = new RepliconTimeEntryBatch(System.Today(), 2, 0);
        Database.executeBatch(newBatch);
        Test.stopTest();
    }
    
    @isTest
    static void testAsyncTimeEntrySchedulable() {
        Test.startTest();
        String hours = String.valueOf(Datetime.now().hour());
        String minutes = String.valueOf(Datetime.now().minute() + 1); 
        String seconds = String.valueOf(Datetime.now().second());
        String cronString = seconds + ' ' + minutes + ' ' + hours + ' * * ?';
        SchedulableContext nullSchedulableContext = NULL;
        RepliconTimeEntryBatchScheduler newSchedulable = new RepliconTimeEntryBatchScheduler(2); 
        newSchedulable.execute(nullSchedulableContext);
        Test.stopTest();
        RepliconTimeEntryBatchScheduler newSchedulableOverload = new RepliconTimeEntryBatchScheduler(NULL, 2, 0); 
    }

    @isTest
    static void test_populateTimeEntryForecast_successInsert() {
        //init();

        // Test        
        System.Test.startTest();
        init();
        insert timeEntry;
        System.Test.stopTest();

        // Post-test
        Id forecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :timeEntry.Id].Replicon_Forecast__c;

        // Assert the correct Forecast record has been set
        //System.assertEquals(forecastMatch.Id, forecastId);
    }

    @isTest
    static void test_populateTimeEntryForecast_successMultiple() {
        //init();
		
        System.Test.startTest();
        init();
		// Build another entry for simultaneous insert
		Replicon_Time_Entry__c anotherTimeEntry = TestClassUtil.createTimeEntry(false, timesheet.Id, employee.Id, projectOld);
		//anotherTimeEntry = [SELECT Id, Project__c FROM Replicon_Time_Entry__c WHERE Id = :anotherTimeEntry.Id];
        //anotherTimeEntry.Project__c = projectOld.Id;
        //anotherTimeEntry.Replicon_Project_URI__c = projectOld.RepliconUri__c;
		
        String employeeRepliconNum = String.valueOf(employee.Replicon_User_Number__c);
        //String projectRepliconId = anotherTimeEntry.Replicon_Project_URI__c.right(4);
        String projectRepliconId = anotherTimeEntry.Replicon_Project_URI__c.substringAfterLast(':');

        Date sd = timesheet.Start_Date__c;
        Date ed = timesheet.Start_Date__c + 6;
        String timesheetStartString = DateTime.newInstance(sd.year(), sd.month(), sd.day()).format('MM/dd/YYYY');
        String timesheetEndString = DateTime.newInstance(ed.year(), ed.month(), ed.day()).format('MM/dd/YYYY');

        List<String> forecastDataPointList = new List<String>{
            timesheetStartString, 
            timesheetEndString, 
            employeeRepliconNum, 
            projectRepliconId
        };
        String forecastName = String.join(forecastDataPointList, '-');
        RepliconForecast__c anotherForecast = TestClassUtil.createForecast(true, forecastName, projectOld.Id);
        List<RepliconForecast__c> forecastList = [SELECT Name FROM RepliconForecast__c];
		
		// Test
		//System.Test.startTest();
		insert new List<Replicon_Time_Entry__c>{ timeEntry, anotherTimeEntry };
		System.Test.stopTest();
		
		// Post-test
		Id forecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :timeEntry.Id].Replicon_Forecast__c;
		Id anotherForecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :anotherTimeEntry.Id].Replicon_Forecast__c;
		
		// Assert that both records were updated with the correct Forecast lookup values
		//System.assertEquals(forecastMatch.Id, forecastId);
		//System.assertEquals(anotherForecast.Id, anotherForecastId);
    }

    @isTest 
    static void test_populateTimeEntryForecast_sameForecast() {
        //init();
        //Replicon_Time_Entry__c anotherTimeEntry = TestClassUtil.createTimeEntry(false, timesheet.Id, employee.Id, project);

        // Test
        System.Test.startTest();
        init();
        Replicon_Time_Entry__c anotherTimeEntry = TestClassUtil.createTimeEntry(false, timesheet.Id, employee.Id, project);
		insert new List<Replicon_Time_Entry__c>{ timeEntry, anotherTimeEntry };
		System.Test.stopTest();
		
		// Post-test
		Id forecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :timeEntry.Id].Replicon_Forecast__c;
		Id anotherForecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :anotherTimeEntry.Id].Replicon_Forecast__c;
		
		// Assert that both records were updated with the correct Forecast lookup values
		//System.assertEquals(forecastMatch.Id, forecastId);
		//System.assertEquals(forecastMatch.Id, anotherForecastId);
    }

    @isTest
    static void test_populateTimeEntryForecast_nullFields() {
		//init();
		//timeEntry.Employee__c = null;
		
		// Test
		System.Test.startTest();
        init();
		timeEntry.Employee__c = null;
		insert timeEntry;
		System.Test.stopTest();
		
		// Post-test 
		Id forecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :timeEntry.Id].Replicon_Forecast__c;
		
		// Assert that the Forecast lookup was not changed 
		System.assertEquals(timeEntry.Replicon_Forecast__c, forecastId);
    }

    @isTest
    static void test_populateTimeEntryForecast_noMatchingForecast() {
		//init();
        //List<RepliconForecast__c> existingForecasts = [SELECT Id FROM RepliconForecast__c ];
		//delete existingForecasts;
		
		// Test
		System.Test.StartTest();
        init();
        List<RepliconForecast__c> existingForecasts = [SELECT Id FROM RepliconForecast__c ];
		delete existingForecasts;
		insert timeEntry;
		System.Test.stopTest();
		
		// Post-test 
		Id forecastId = [SELECT Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id = :timeEntry.Id].Replicon_Forecast__c;
        RepliconForecast__c newForecast = [
            SELECT Id, Name, Project__c, Contact__c, Week_Start_Date__c, Week_End_Date__c, NotForecasted__c
            FROM RepliconForecast__c 
            LIMIT 1
        ];

        Date sd = timesheet.Start_Date__c;
        Date ed = timesheet.Start_Date__c + 6;

		// Assert that a new Forecast record was created for the time entry
		System.assertEquals(forecastName, newForecast.Name);
        System.assertEquals(timeEntry.Project__c, newForecast.Project__c);
        System.assertEquals(timeEntry.Employee__c, newForecast.Contact__c);
        System.assertEquals(timesheet.Start_Date__c, newForecast.Week_Start_Date__c);
        System.assertEquals(timesheet.Start_Date__c + 6, newForecast.Week_End_Date__c);
        System.assertEquals(true, newForecast.NotForecasted__c);

        // Assert that the new Forecast record ID was set on the time entry
        //System.assertEquals(forecastId, newForecast.Id);
    }
    
    @isTest
    static void billableToNonBillableTimeEntrySwitch(){
        
        //Get needed items for createTimeEntry Parameters        
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(true, employeeID);
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testInitiallyBillableTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testInitiallyNonBillableTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 250;
        insert testBillingRate;
        
        //Set Time Entry Billing Rates and Hours (Which in turn sets isBillable field that calculates Billable/NonBillable Hours Booked rollup field)
		testInitiallyBillableTimeEntry.Name = 'Initially Billable Time Entry';
        testInitiallyBillableTimeEntry.Associated_Billing_Rate__c = testBillingRate.Id;
        testInitiallyBillableTimeEntry.TotalHrs__c = 1.75; 
        //Initialize NonBillable Entry with no Billing Rate (Making it NonBillable)
        testInitiallyNonBillableTimeEntry.Name = 'Initially Non-Billable Time Entry';
        testInitiallyNonBillableTimeEntry.TotalHrs__c = 1;
        
        //Add Time Entries to List
        timeEntryList.add(testInitiallyBillableTimeEntry);
        timeEntryList.add(testInitiallyNonBillableTimeEntry);
        
        //Insert Time Entries
        insert timeEntryList; 
        
        //Check that Time Entry is marked correctly as Billable or NonBillable initially
        List<Replicon_Time_Entry__c> checkInitialTimeEntries = new List<Replicon_Time_Entry__c>();
        checkInitialTimeEntries = [SELECT Id, Name, Associated_Billing_Rate__c, TotalHrs__c, Is_Billable__c FROM Replicon_Time_Entry__c WHERE Name LIKE 'Initially%'];
        for (Replicon_Time_Entry__c timeEnt : checkInitialTimeEntries){
            if(timeEnt.Name == 'Initially Billable Time Entry'){
                System.assertEquals(true, timeEnt.Is_Billable__c, 'Billable to Non-Billable Switch was inproperly set on Time Entry');
            }else if(timeEnt.Name == 'Initially Non-Billable Time Entry'){
				System.assertEquals(false, timeEnt.Is_Billable__c, 'Non-Billable to Billable Switch was inproperly set on Time Entry');
            }
        }
     
        Test.startTest();
        //Change from Billable to NonBillable (Delete Associated Billing Rate__c)
        testInitiallyBillableTimeEntry.Associated_Billing_Rate__c = null;
        testInitiallyNonBillableTimeEntry.Associated_Billing_Rate__c = testBillingRate.Id;
        update timeEntryList;
        Test.stopTest();
        
        
        List<Replicon_Time_Entry__c> checkTimeEntries = new List<Replicon_Time_Entry__c>();
        checkTimeEntries = [SELECT Id, Name, Associated_Billing_Rate__c, TotalHrs__c, Is_Billable__c FROM Replicon_Time_Entry__c WHERE Name LIKE 'Initially%'];
        
        
        for (Replicon_Time_Entry__c timeEnt : checkTimeEntries){
            if(timeEnt.Name == 'Initially Billable Time Entry'){
                System.assertEquals(false, timeEnt.Is_Billable__c, 'Billable to Non-Billable Switch was inproperly set on Time Entry');
            }else if(timeEnt.Name == 'Initially Non-Billable Time Entry'){
				System.assertEquals(true, timeEnt.Is_Billable__c, 'Non-Billable to Billable Switch was inproperly set on Time Entry');
            }
        }

    }

    @isTest
    static void calculateRollupsOnProjectTest(){
        
        
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(true, employeeID);
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testNonBillableTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testConcessionTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 250;
        billingRateList.add(testBillingRate);
        Project_Team_Member_Billing_Rate__c testConcessionRate = new Project_Team_Member_Billing_Rate__c();
        testConcessionRate.Hourly_Rate__c = 0;
        billingRateList.add(testConcessionRate);

        insert billingRateList;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 3.25; 
        timeEntryList.add(testBillableTimeEntry1);
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4.5;
        timeEntryList.add(testBillableTimeEntry2); 
        testNonBillableTimeEntry.Associated_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.Override_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.TotalHrs__c = 6; 
        timeEntryList.add(testNonBillableTimeEntry);
        testConcessionTimeEntry.Override_Billing_Rate__c = testConcessionRate.Id;
        testConcessionTimeEntry.Associated_Billing_Rate__c = NULL;
        testConcessionTimeEntry.TotalHrs__c = 8; 
        timeEntryList.add(testConcessionTimeEntry);

        insert timeEntryList;

        Test.startTest();
        RepliconService.calculateRollupsOnProject(testProject.Id);
        Test.stopTest();

        Project__c testProjectAfterCalculate = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, 
                                        Opportunity_Non_Billable_Hours_Booked__c,OpportunityTotal_Amount_Invoiced_To_Date__c,
                                        Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c
                                    FROM Project__c 
                                    WHERE Name = 'Test Project' LIMIT 1]; 
        
        //Opportunity_Billable_Hours_Booked__c is formula field of Rollup_Billable__c 
        System.assertEquals(7.75, testProjectAfterCalculate.Opportunity_Billable_Hours_Booked__c , 'Total Billable Hours did not calculate correctly');
        //Opp_Concession_Non_Billable_Hours_Booked__c is formula field of Rollup_Concession__c 
        System.assertEquals(8, testProjectAfterCalculate.Opp_Concession_Non_Billable_Hours_Booked__c , 'Total Concession Hours did not calculate correctly');
        //Opportunity_Non_Billable_Hours_Booked__c is formula field for Rollup_Nonbillable__c
        System.assertEquals(6, testProjectAfterCalculate.Opportunity_Non_Billable_Hours_Booked__c , 'Total NonBillable Hours did not calculate correctly');
        //OpportunityTotal_Amount_Invoiced_To_Date__c is formula field for Rollup_Revenue__c
        System.assertEquals(1937.5, testProjectAfterCalculate.OpportunityTotal_Amount_Invoiced_To_Date__c , 'Total Billable Revenue Amount did not calculate correctly');

    
    
    }

    @isTest
    static void calculateRollupsOnProjectTest2(){
        
        
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c, Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(true, employeeID);
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testNonBillableTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        Replicon_Time_Entry__c testConcessionTimeEntry = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 250;
        billingRateList.add(testBillingRate);
        Project_Team_Member_Billing_Rate__c testConcessionRate = new Project_Team_Member_Billing_Rate__c();
        testConcessionRate.Hourly_Rate__c = 0;
        billingRateList.add(testConcessionRate);

        insert billingRateList;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 3.25; 
        timeEntryList.add(testBillableTimeEntry1);
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4.5;
        timeEntryList.add(testBillableTimeEntry2); 
        testNonBillableTimeEntry.Associated_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.Override_Billing_Rate__c = NULL;
        testNonBillableTimeEntry.TotalHrs__c = 6; 
        timeEntryList.add(testNonBillableTimeEntry);
        testConcessionTimeEntry.Override_Billing_Rate__c = testConcessionRate.Id;
        testConcessionTimeEntry.Associated_Billing_Rate__c = NULL;
        testConcessionTimeEntry.TotalHrs__c = 8; 
        timeEntryList.add(testConcessionTimeEntry);

        insert timeEntryList;

        Test.startTest();

        testProject.Rollup_Billable__c = 0;
        testProject.Rollup_Concession__c = 0;
        testProject.Rollup_Nonbillable__c = 0;
        update testProject;


        Set<Id> projectIds = new Set<Id>();
        projectIds.add(testProject.Id);
        RepliconService newService = new RepliconService();
        newService.calculateProjectRollupValues(projectIds);
        Test.stopTest();

        Project__c testProjectAfterCalculate = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, 
                                        Opportunity_Non_Billable_Hours_Booked__c,OpportunityTotal_Amount_Invoiced_To_Date__c,
                                        Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c
                                    FROM Project__c 
                                    WHERE Name = 'Test Project' LIMIT 1]; 
        
        //Opportunity_Billable_Hours_Booked__c is formula field of Rollup_Billable__c 
        //System.assertEquals(7.75, testProjectAfterCalculate.Opportunity_Billable_Hours_Booked__c , 'Total Billable Hours did not calculate correctly');
        //Opp_Concession_Non_Billable_Hours_Booked__c is formula field of Rollup_Concession__c 
        //System.assertEquals(8, testProjectAfterCalculate.Opp_Concession_Non_Billable_Hours_Booked__c , 'Total Concession Hours did not calculate correctly');
        //Opportunity_Non_Billable_Hours_Booked__c is formula field for Rollup_Nonbillable__c
        //System.assertEquals(6, testProjectAfterCalculate.Opportunity_Non_Billable_Hours_Booked__c , 'Total NonBillable Hours did not calculate correctly');
        //OpportunityTotal_Amount_Invoiced_To_Date__c is formula field for Rollup_Revenue__c
        //System.assertEquals(1937.5, testProjectAfterCalculate.OpportunityTotal_Amount_Invoiced_To_Date__c , 'Total Billable Revenue Amount did not calculate correctly');

    
    
    }

    @isTest
    static void calculateRollupsOnProjectWithNoEntriesTest(){
        //Test the functionality of reseting the project rollups to 0 when a time entry is deleted (or marked as deleted) leaving the related project with no Active Time Entries
        
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 
        Replicon_Timesheet__c testTimeSheet = TestClassUtil.createTimesheet(true, employeeID);
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, testTimeSheet.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 100;
        billingRateList.add(testBillingRate);

        insert billingRateList;

        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 7, 1);
        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 5; 
        timeEntryList.add(testBillableTimeEntry1);
        Test.startTest();
        insert timeEntryList;

        Project__c testProjectAfterCalculate = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, 
                                        Opportunity_Non_Billable_Hours_Booked__c,OpportunityTotal_Amount_Invoiced_To_Date__c,
                                        Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c
                                    FROM Project__c 
                                    WHERE Name = 'Test Project' LIMIT 1]; 

        
        
        //Opportunity_Billable_Hours_Booked__c is formula field of Rollup_Billable__c 
        //System.assertEquals(5, testProjectAfterCalculate.Opportunity_Billable_Hours_Booked__c , 'Total Billable Hours did not calculate correctly');
        //OpportunityTotal_Amount_Invoiced_To_Date__c is formula field for Rollup_Revenue__c
        //System.assertEquals(500, testProjectAfterCalculate.OpportunityTotal_Amount_Invoiced_To_Date__c , 'Total Billable Revenue Amount did not calculate correctly');

        Replicon_Time_Entry__c testEntry = [SELECT Id, Name, Project__c, Employee__c, TotalHrs__c, Billable_Amount__c, Associated_Billing_Rate__c, Deleted_in_Replicon__c 
                                            FROM Replicon_Time_Entry__c 
                                            WHERE Project__r.Name = 'Test Project' AND Employee__c =: employeeID LIMIT 1];

        
        testEntry.Deleted_in_Replicon__c = true;       
        update testEntry;
        Test.stopTest();

        Project__c testProjectAfterEntryDelete = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opp_Concession_Non_Billable_Hours_Booked__c, 
                                                        Opportunity_Non_Billable_Hours_Booked__c,OpportunityTotal_Amount_Invoiced_To_Date__c,
                                                        Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c
                                                    FROM Project__c 
                                                    WHERE Name = 'Test Project' LIMIT 1]; 
        
        //Opportunity_Billable_Hours_Booked__c is formula field of Rollup_Billable__c 
        System.assertEquals(0, testProjectAfterEntryDelete.Opportunity_Billable_Hours_Booked__c , 'Total Billable Hours did not calculate correctly after Time Entry Delete');
        //OpportunityTotal_Amount_Invoiced_To_Date__c is formula field for Rollup_Revenue__c
        System.assertEquals(0, testProjectAfterEntryDelete.OpportunityTotal_Amount_Invoiced_To_Date__c , 'Total Billable Revenue Amount did not calculate correctly after Time Entry Delete');

    
    
    }

    @isTest
    static void testInsertingPlaceholderEntries(){
        
        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:26030' LIMIT 1];
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testPlaceholderEntry = new Replicon_Time_Entry__c();
        testPlaceholderEntry.EntryDate__c = Date.today();
        testPlaceholderEntry.TotalHrs__c = 0;
        testPlaceholderEntry.Replicon_Project_URI__c = testProject.RepliconURI__c;
        testPlaceholderEntry.Employee__c = employeeID;
        Test.startTest();       
        insert testPlaceholderEntry;
        Test.stopTest();

        Replicon_Time_Entry__c placeholderEntry = [SELECT Id, Name, Replicon_Forecast__c FROM Replicon_Time_Entry__c WHERE Id =: testPlaceholderEntry.Id LIMIT 1];
        //System.assertNotEquals(null, placeholderEntry.Replicon_Forecast__c, 'Placeholder Time Entry was not properly populated with a Forecast Record');
    
    }

    @isTest
    static void insertTimeEntriesWithPTO() {
        String timesheetURIURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetForDate';
        String timesheetDetailsURL = 'https://na3.replicon.com/levementum/services/TimesheetService1.svc/BulkGetTimesheetDetails';
        
        List<Id> employeeIDList = new List<Id>();
        Contact queriedEmployee = [SELECT Id, Name FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c = 1];
        employeeIDList.add(queriedEmployee.Id);
        Project__c queriedProject = [SELECT Id, Name FROM Project__c WHERE RepliconUri__c = 'urn:replicon-tenant:levementum:project:1155'];
        
        Test.startTest();
        MultiStaticResourceCalloutMock newHTTPMock = new MultiStaticResourceCalloutMock();
        newHTTPMock.setStatus('SUCCESS');
        newHTTPMock.setStatusCode(200);
        newHTTPMock.setStaticResource(timesheetURIURL, 'RepliconServiceTimesheetURIResponse');
        newHTTPMock.setStaticResource(timesheetDetailsURL, 'RepliconServiceTimesheetDetailsResponse4');
        Test.setMock(HttpCalloutMock.class, newHTTPMock);
        RepliconService newService = new RepliconService();
        newService.getTimesheetEntries(System.Today(), employeeIDList);
        System.debug([SELECT Error_Message__c, Line_Number__c FROM Error_Log_Lev__c]);
        Test.stopTest();
    }

    @isTest
    static void calculateWeeklyTargetActualsRollup(){


        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 

        Revenue_Forecast__c testAprilMonthlyRevForecast = new Revenue_Forecast__c();
        testAprilMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testAprilMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 4, 1);
        testAprilMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in April 2022
        insert testAprilMonthlyRevForecast;

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;   
        
        //Create List of Time Entries
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>();
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        timeEntryList.add(testBillableTimeEntry1);
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        timeEntryList.add(testBillableTimeEntry2); 

        Test.startTest();
        insert timeEntryList;
        Test.stopTest();

        List<Replicon_Time_Entry__c> timeEntryAssertList = [SELECT Id, Name, WeeklyTarget__c, EntryDate__c, TotalHrs__c FROM Replicon_Time_Entry__c WHERE Id =: testBillableTimeEntry1.Id OR Id =: testBillableTimeEntry2.Id];

        for(Replicon_Time_Entry__c entry : timeEntryAssertList){
            System.assertNotEquals(null, entry.WeeklyTarget__c, 'Time Entry was not properly populated with the Weekly Target');
        }

        List<Revenue_Forecast__c> revForecastList = [SELECT Id, Name, WeeklyActuals__c, RecordType.Id, MonthlyActuals__c, FullWeekStartDate__c FROM Revenue_Forecast__c];

        for(Revenue_Forecast__c rf : revForecastList){
            if(rf.RecordTypeId == monthlyTargetRT){
                //Assert Monthly Actuals for the April 2022 Monthly Target
                System.assertEquals(1200, rf.MonthlyActuals__c, 'The Monthly Target for April 2022 was not rolled up correctly from the Time Entry Insert.');

            }else{
                //Assert Weekly Actuals for the April 2022 Week of 4/3 - 4/9
                if(rf.FullWeekStartDate__c == Date.newInstance(2022, 4, 3)){
                    System.assertEquals(800, rf.WeeklyActuals__c, 'The Weekly Actuals for the week of April 2022 4/3 - 4/9 was not properly rolled up.');
                }
                //Assert Weekly Actuals for the April 2022 Week of 4/17 - 4/23
                if(rf.FullWeekStartDate__c == Date.newInstance(2022, 4, 17)){
                    System.assertEquals(400, rf.WeeklyActuals__c, 'The Weekly Actuals for the week of April 2022 4/17 - 4/23 was not properly rolled up.');
                }
            }
        }
    }

    @isTest
    static void timeEntryDeleteProjectRollup_Test(){
        System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% **************************** timeEntryDeleteProjectRollup_Test START **************************** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' START OF timeEntryDeleteTest');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' START OF timeEntryDeleteTest');

        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;         
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry3 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Name = 'Developer';
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        
        testBillableTimeEntry3.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry3.TotalHrs__c = 2;
        testBillableTimeEntry3.EntryDate__c = Date.newInstance(2022, 4, 19);        
        
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testBillableTimeEntry3};

        Test.startTest();
        insert timeEntryList;

        delete testBillableTimeEntry2;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE ASSERTIONS');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE ASSERTIONS');

        /** Assertions:
         *  1.) Project Rollups are correct
         */

        /********** Assert Project **********/
        Project__c assertProject = [SELECT Id, Name, Rollup_Billable__c, Rollup_Revenue__c FROM Project__c WHERE Id =: testProject.Id LIMIT 1];
        System.assertEquals(10, assertProject.Rollup_Billable__c, 'Project Billable Hours Rollup was not properly calculated after Time Entry was Deleted');
        System.assertEquals(1000, assertProject.Rollup_Revenue__c, 'Project Billable Revenue Rollup was not properly calculated after Time Entry was Deleted');
        
        System.debug('**************************** timeEntryDeleteProjectRollup_Test END ****************************');

    }

    @isTest
    static void timeEntryDeleteTimesheetRollup_Test(){
        System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% **************************** timeEntryDeleteTimesheetRollup_Test START **************************** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' START OF timeEntryDeleteTest');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' START OF timeEntryDeleteTest');

        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;         
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry3 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Name = 'Developer';
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        
        testBillableTimeEntry3.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry3.TotalHrs__c = 2;
        testBillableTimeEntry3.EntryDate__c = Date.newInstance(2022, 4, 19);        
        
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testBillableTimeEntry3};

        Test.startTest();
        insert timeEntryList;

        delete testBillableTimeEntry2;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE ASSERTIONS');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE ASSERTIONS');

        /** Assertions:
         *  1.) Timesheet Rollups are correct
         */        

        /********** Assert Timesheet **********/
        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Employee__c, Total_Billable_Hours__c FROM Replicon_Timesheet__c WHERE Id =: timesheetForThirdWeekOfApril.Id LIMIT 1];
        System.assertEquals(2, assertTimesheet.Total_Billable_Hours__c, 'Timesheet Billable Hours Rollup was not properly calculated after Time Entry was Deleted'); //Assertion on the timesheet that the deleted entry was before

        System.debug('**************************** timeEntryDeleteTimesheetRollup_Test END ****************************');

    }

    @isTest
    static void timeEntryDeleteTimesheetRollup_Test2(){
        System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% **************************** timeEntryDeleteTimesheetRollup_Test START **************************** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' START OF timeEntryDeleteTest');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' START OF timeEntryDeleteTest');

        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;         
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry3 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Name = 'Developer';
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        
        testBillableTimeEntry3.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry3.TotalHrs__c = 2;
        testBillableTimeEntry3.EntryDate__c = Date.newInstance(2022, 4, 19);        
        
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testBillableTimeEntry3};

        Test.startTest();
        insert timeEntryList;

        timesheetForThirdWeekOfApril.Total_Billable_Hours__c = 0;
        update timesheetForThirdWeekOfApril;

        Set<Id> timesheetIdSet = new Set<Id>();
        timesheetIdSet.add(timesheetForFirstFullWeekOfApril.Id);
        timesheetIdSet.add(timesheetForThirdWeekOfApril.Id);
        RepliconService newService = new RepliconService();
        newService.calculateTimesheetRollupValues(timesheetIdSet);

        delete testBillableTimeEntry2;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE ASSERTIONS');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE ASSERTIONS');

        /** Assertions:
         *  1.) Timesheet Rollups are correct
         */        

        /********** Assert Timesheet **********/
        Replicon_Timesheet__c assertTimesheet = [SELECT Id, Employee__c, Total_Billable_Hours__c FROM Replicon_Timesheet__c WHERE Id =: timesheetForThirdWeekOfApril.Id LIMIT 1];
        System.assertEquals(2, assertTimesheet.Total_Billable_Hours__c, 'Timesheet Billable Hours Rollup was not properly calculated after Time Entry was Deleted'); //Assertion on the timesheet that the deleted entry was before

        System.debug('**************************** timeEntryDeleteTimesheetRollup_Test END ****************************');

    }

    @isTest
    static void timeEntryDeleteRevenueForecastRollup_Test(){
        System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% **************************** timeEntryDeleteRevenueForecastRollup_Test START **************************** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' START OF timeEntryDeleteTest');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' START OF timeEntryDeleteTest');

        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;
        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project' LIMIT 1]; 

        Revenue_Forecast__c testAprilMonthlyRevForecast = new Revenue_Forecast__c();
        testAprilMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testAprilMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 4, 1);
        testAprilMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in April 2022
        insert testAprilMonthlyRevForecast;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' AFTER OF Revenue Forecast Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' AFTER OF Revenue Forecast Insert');

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;         
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry3 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Name = 'Developer';
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        
        testBillableTimeEntry3.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry3.TotalHrs__c = 2;
        testBillableTimeEntry3.EntryDate__c = Date.newInstance(2022, 4, 19);        
        
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testBillableTimeEntry3};

        Test.startTest();
        insert timeEntryList;

        delete testBillableTimeEntry2;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE ASSERTIONS');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE ASSERTIONS');

        /** Assertions:
         *  1.) Weekly & Monthly Target Actuals are Rolled Up correctly
         */

        /********** Assert Revenue Forecasts **********/
        List<Revenue_Forecast__c> assertRevenueForecasts = [SELECT Id, Name, WeeklyActuals__c, RecordType.Id, MonthlyActuals__c, FullWeekStartDate__c FROM Revenue_Forecast__c];
        for(Revenue_Forecast__c rf : assertRevenueForecasts){
            if(rf.RecordTypeId == monthlyTargetRT){
                //Assert Monthly Actuals for the April 2022 Monthly Target
                System.assertEquals(1000, rf.MonthlyActuals__c, 'The Monthly Target for April 2022 was not rolled up correctly after Time Entry Deletion.');

            }else{
                //Assert Weekly Actuals for the April 2022 Week of 4/3 - 4/9
                if(rf.FullWeekStartDate__c == Date.newInstance(2022, 4, 3)){
                    System.assertEquals(800, rf.WeeklyActuals__c, 'The Weekly Actuals for the week of April 2022 4/3 - 4/9 was not properly rolled up after Time Entry Deletion.');
                }
                //Assert Weekly Actuals for the April 2022 Week of 4/17 - 4/23
                if(rf.FullWeekStartDate__c == Date.newInstance(2022, 4, 17)){
                    System.assertEquals(200, rf.WeeklyActuals__c, 'The Weekly Actuals for the week of April 2022 4/17 - 4/23 was not properly rolled up after Time Entry Deletion.');
                }
            }
        }
        
        System.debug('**************************** timeEntryDeleteRevenueForecastRollup_Test END ****************************');

    }

    @isTest
    static void timeEntryDeleteProjectRoleRollups_Test(){
        System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% **************************** timeEntryDeleteProjectRoleRollups_Test START **************************** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' START OF timeEntryDeleteTest');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' START OF timeEntryDeleteTest');

        Opportunity oppty = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opp2' LIMIT 1];
    
        Product2 devProd = TestDataFactory.createProduct(false);
        devProd.Name = 'Developer';
        insert devProd;

        PricebookEntry devPbe = TestDataFactory.createPricebookEntry(false, devProd.Id);
        insert devPbe;

        OpportunityLineItem devOli = TestDataFactory.createOpportunityLineItem(false, oppty.Id, devPbe.Id);
        devOli.Quantity = 50;
        devOli.UnitPrice = 100;
        devOli.TotalPrice = null;        
        insert devOli;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' AFTER OF OLI Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' AFTER OF OLI Insert');

        Id employeeID = [SELECT Id FROM Contact WHERE Email = 'temployee1@levdigital.com'].Id;

        Project__c testProject = [SELECT Id, RepliconUri__c, Opportunity_Billable_Hours_Booked__c, Opportunity_Non_Billable_Hours_Booked__c FROM Project__c WHERE Name = 'Test Project Role Project' LIMIT 1]; 

        System.debug('Test Project in Project Roles Query: ' + testProject);

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' AFTER OF Revenue Forecast Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' AFTER OF Revenue Forecast Insert');

        Replicon_Timesheet__c timesheetForFirstFullWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForFirstFullWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220403';
        timesheetForFirstFullWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 3);

        Replicon_Timesheet__c timesheetForThirdWeekOfApril = TestDataFactory.createTimesheet(false, employeeID);
        timesheetForThirdWeekOfApril.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220417';
        timesheetForThirdWeekOfApril.Start_Date__c = Date.newInstance(2022, 4, 17);

        List<Replicon_Timesheet__c> testTimesheetList = new List<Replicon_Timesheet__c>{timesheetForFirstFullWeekOfApril, timesheetForThirdWeekOfApril};
        insert testTimesheetList;         
        
        //Create List of Time Entries
        Replicon_Time_Entry__c testBillableTimeEntry1 = TestClassUtil.createTimeEntry(false, timesheetForFirstFullWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry2 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        Replicon_Time_Entry__c testBillableTimeEntry3 = TestClassUtil.createTimeEntry(false, timesheetForThirdWeekOfApril.Id, employeeID, testProject);
        
        //Create Project_Team_Member_Billing_Rate__c
        Project_Team_Member_Billing_Rate__c testBillingRate = new Project_Team_Member_Billing_Rate__c();
        testBillingRate.Name = 'Developer';
        testBillingRate.Hourly_Rate__c = 100;
        insert testBillingRate;

        testBillableTimeEntry1.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry1.TotalHrs__c = 8; 
        testBillableTimeEntry1.EntryDate__c = Date.newInstance(2022, 4, 6);
        
        testBillableTimeEntry2.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry2.TotalHrs__c = 4;
        testBillableTimeEntry2.EntryDate__c = Date.newInstance(2022, 4, 18);
        
        testBillableTimeEntry3.Associated_Billing_Rate__c = testBillingRate.Id;
        testBillableTimeEntry3.TotalHrs__c = 2;
        testBillableTimeEntry3.EntryDate__c = Date.newInstance(2022, 4, 19);        
        
        List<Replicon_Time_Entry__c> timeEntryList = new List<Replicon_Time_Entry__c>{testBillableTimeEntry1, testBillableTimeEntry2, testBillableTimeEntry3};

        Test.startTest();
        insert timeEntryList;

        delete testBillableTimeEntry2;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' BEFORE ASSERTIONS');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' BEFORE ASSERTIONS');

        //Assertions: that Project Rollup Values are correct

        /** Assertions:
         *  1.) Project Role rollups are correct
         */

        /********** Assert Project Role **********/
        ProjectRole__c assertProjectRole = [SELECT Id, Name, Total_Hours_Billed__c, Total_Amount_Billed__c FROM ProjectRole__c WHERE Project__c =: testProject.Id LIMIT 1];
        System.assertEquals(10, assertProjectRole.Total_Hours_Billed__c, 'Total Billable Hours Rollup on Project Role was not properly calculated after Time Entry was Deleted');
        System.assertEquals(1000, assertProjectRole.Total_Amount_Billed__c, 'Total Billable Revenue Rollup on Project Role was not properly calculated after Time Entry was Deleted');
        
        System.debug('**************************** timeEntryDeleteProjectRoleRollups_Test END ****************************');

    }

}