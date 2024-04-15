@isTest(SeeAllData=true)
public with sharing class ContactBeforeInsertUpdateTest {

    private static String employeeContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    private static String placeholderEmployeeContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Placeholder Employee').getRecordTypeId();
    private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();

    @isTest
    static void testWorkLogInsert(){
        Contact c = new Contact(LastName='Test', Latest_Work_Log__c = 'test');

        Test.startTest();
        insert c;        
        Test.stopTest();

        Contact c1 = [Select Id, Work_Logs__c from Contact where id = :c.Id];
        System.assertNotEquals(null, c1.Work_Logs__c);        
    }

    @isTest
    static void testWorkLogUpdate(){
        Contact c = new Contact(LastName='Test', Latest_Work_Log__c = 'test');
        insert c;

        Test.startTest();
        c.Latest_Work_Log__c = 'test123';
        update c;
        Test.stopTest();
    
        Contact c1 = [Select Id, Work_Logs__c from Contact where id = :c.Id];
        System.assertNotEquals(null, c1.Work_Logs__c);
    }

    @isTest
    static void testNPSContextInsert(){
        Contact con = new Contact(LastName='Test', NPS_Context__c = 'Test NPS Context Log');
        
        Test.startTest();
        insert con;        
        Test.stopTest();

        Contact conAssert = [Select Id, NPS_Context__c, NPS_Context_Log__c from Contact where id =: con.Id];
        System.assertNotEquals(null, conAssert.NPS_Context_Log__c);        
    }

    @isTest
    static void testNPSContextUpdate(){
        Contact con = new Contact(LastName='Test', NPS_Context__c = 'Test NPS Context Log');
        insert con; 
        
        Test.startTest();
        con.NPS_Context_Log__c = '2nd Entry of NPS Context Log';
        update con;        
        Test.stopTest();

        Contact conAssert = [Select Id, NPS_Context__c, NPS_Context_Log__c from Contact where id =: con.Id];
        System.assertNotEquals(null, conAssert.NPS_Context_Log__c);
    }

    @isTest
    static void testSkillsMatrixCreation(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(LastName='Test', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Consulting', Division__c = 'Not Ops Management', Active__c = true);
        
        Test.startTest();
        insert con;     
        Test.stopTest();

        List<Skill_Rating__c> skillRatingAsserts = new List<Skill_Rating__c>();
        skillRatingAsserts = [SELECT Id, Name, Resource__c FROM Skill_Rating__c WHERE Resource__c =: con.Id];
        System.assert(skillRatingAsserts.size() > 0, 'The Skill Ratings were not properly created for the test Contact');
    }

    @isTest
    static void testSkillsMatrixDeletion(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(LastName='Test', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Consulting', Division__c = 'Not Ops Management', Active__c = true);
        insert con;

        Test.startTest();
        con.Active__c = false;
        update con;
        Test.stopTest();

        List<Skill_Rating__c> skillRatingAsserts = new List<Skill_Rating__c>();
        skillRatingAsserts = [SELECT Id, Name, Resource__c FROM Skill_Rating__c WHERE Resource__c =: con.Id];  
        System.assertEquals(0, skillRatingAsserts.size(), 'Skill Ratings were not properly deleted for test Contact');
        
    }

    @isTest
    static void testReportsToIdChange(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        List<Contact> contactInsertList = new List<Contact>();
        Contact con = new Contact(LastName='Test', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true);
        Contact con2 = new Contact(LastName='TestManager', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true);
        Contact con3 = new Contact(LastName='Test Contact 2', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true);
        contactInsertList.add(con);
        contactInsertList.add(con2);
        contactInsertList.add(con3);
        insert contactInsertList;

        User testUser = new User();
        testUser = [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY CreatedDate DESC LIMIT 1];

        Account acc = new Account();
    	acc.Name = 'testAccount';
    	acc.PrimaryPractice__c = 'Salesforce';
        acc.Delivery_Account_Lead__c = testUser.Id;
        insert acc;

        Opportunity opp = TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp Name');

        Project__c proj = new Project__c();
        proj.Account__c = acc.Id;
        proj.RepliconUri__c = String.valueOf(Integer.valueof((Math.random() * 100000)));
        proj.Opportunity__c = opp.Id;
        proj.Project_Manager__c = testUser.Id;
        insert proj;


        Case OoOCase = new Case(Subject='OoO Test Case', RecordTypeId=OoOCoverageRequestCaseRT, ContactId=con.Id, Out_of_Office_Start_Date__c = System.today(), Out_of_Office_End_Date__c = system.today()+40,
                                Out_of_Office_Coverage_Resource__c = con.Id, Description = 'Test Description', ResourceType__c = 'CORE - Technical QA Consultant', Project__c=proj.Id, Estimated_Hours__c=10, 
                                Estimated_Hours_per_Week__c =5, Outstandingresponsibilitiesofcurrent__c='Responsibilities', What_skillsets_are_required_in_the_new_r__c='Skills');
        insert OoOCase;

        Test.startTest();
        con.ReportsToId = con2.Id;
        update con;
        Test.stopTest();
    }

    /*@isTest
    static void testCreateSurvey(){

        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        List<Contact> contactInsertList = new List<Contact>();
        Contact con = new Contact(LastName='Test', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true);
        insert con;

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, Client_Project_Lead__c FROM Project__c WHERE Project_Status__c = 'Completed' LIMIT 1];
        testProj.Client_Project_Lead__c = con.Id;
        update testProj;

        con.Is_Survey_Completed__c = true;
        update con;

        List<Survey__c> surveyList = new List<Survey__c>();
        surveyList = [SELECT Id, Name, Project__c FROM Survey__c WHERE Project__c =: testProj.Id];

        System.assertNotEquals(0, surveyList.size(), 'Surveys were not properly created');

    }*/
    
    @isTest
    static void deleteFutureTimesheetsForInactiveEmployee_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='Inactive Employee', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Division_New__c = 'Next Lev', Active__c = true,
        Quarterly_Target__c=414, RampTime__c = 10, Hire_Date__c = Date.today(), Replicon_User_Number__c = 4444);
        insert con;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Start_Date__c = Date.today().toStartOfWeek().addDays(14);
        insert testTimesheet;

        Test.startTest();
        con.Active__c = false;
        update con;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];


        System.assertEquals(0, timesheetList.size(), 'Timesheets were not properly Deleted');

    }

    @isTest
    static void updateTimesheetWeekTargets_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='TimesheetWeekTargets', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Division_New__c = 'Next Lev', Active__c = true,
        Quarterly_Target__c=414, RampTime__c = 10, Hire_Date__c = Date.today().addDays(-100), Replicon_User_Number__c = 4444);
        insert con;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Start_Date__c = Date.today().toStartOfWeek().addDays(14);
        insert testTimesheet;

        Test.startTest();
        con.Quarterly_Target__c = 115;
        update con;
        Test.stopTest();


        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];


        System.assertEquals(10, timesheetList[0].Target__c, 'Timesheets were not properly updated with the new Weekly Target of the related Employee');

    }

    @isTest
    static void updateEmployeeDetailsOnTimesheet_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con1 = new Contact(FirstName='Test', LastName='UpdateOnTimesheetDetails', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Division_New__c = 'Next Lev', Active__c = true,
        Quarterly_Target__c=414, RampTime__c = 10, Hire_Date__c = Date.today(), Replicon_User_Number__c = 4444);

        Contact con2 = new Contact(FirstName='Test', LastName='Placeholder Boss', RecordTypeId = employeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Division_New__c = 'Next Lev', Active__c = true,
        Quarterly_Target__c=414, RampTime__c = 10, Hire_Date__c = Date.today(), Replicon_User_Number__c = 4445);
        
        List<Contact> contactList = new List<Contact>{con1, con2};
        insert contactList;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con1.Id);
        testTimesheet.Start_Date__c = Date.today().toStartOfWeek().addDays(14);
        insert testTimesheet;

        Test.startTest();
        con1.Division_New__c = 'Executive';
        con1.Department = 'Department';
        con1.Title = 'New Title';
        con1.ReportsToId = con2.Id;
        update con1;
        Test.stopTest();


        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con1.Id];


        System.assertEquals('Executive', timesheetList[0].EmployeeDivision__c, 'Timesheets were not properly updated with the new Employee Division');
        System.assertEquals('Department', timesheetList[0].EmployeeDepartment__c, 'Timesheets were not properly updated with the new Employee Department');
        System.assertEquals('New Title', timesheetList[0].EmployeeTitle__c, 'Timesheets were not properly updated with the new Employee Title');
        System.assertEquals(con2.Id, timesheetList[0].EmployeesManager__c, 'Timesheets were not properly updated with the new Employee Manager');


    }

    @isTest
    static void createPlaceholderTimesheetsOnInsert_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='PlaceholderTestOnInsert', RecordTypeId = placeholderEmployeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true
                                    , Quarterly_Target__c=414, RampTime__c = 10, Hire_Date__c = Date.today());

        Test.startTest();
        insert con;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];


        System.assertNotEquals(0, timesheetList.size(), 'Placeholder Timesheets were not properly created');


    }

    @isTest
    static void createPlaceholderTimesheetsOnInsert2_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='PlaceholderTestOnInsert', RecordTypeId = placeholderEmployeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true
                                    , Quarterly_Target__c=414, RampTime__c = 14, Hire_Date__c = Date.today());

        Test.startTest();
        insert con;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];


        System.assertNotEquals(0, timesheetList.size(), 'Placeholder Timesheets were not properly created');


    }

    @isTest
    static void createPlaceholderTimesheetsOnUpdate_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='PlaceholderTestOnUpdate', RecordTypeId = placeholderEmployeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true
                                    , Quarterly_Target__c=414, RampTime__c = 6, Hire_Date__c = Date.today());

        insert con;

        Test.startTest();
        con.Quarterly_Target__c = 392;
        update con;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];


        System.assertNotEquals(0, timesheetList.size(), 'Placeholder Timesheets were not properly created');


    }


    @isTest
    static void createPlaceholderTimesheetsChangeRT_test(){
        Account levAccount = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        Contact con = new Contact(FirstName='Test', LastName='PlaceholderTimesheetChange', RecordTypeId = placeholderEmployeeContactRT, AccountId = levAccount.Id, Department = 'Operations', Division__c = 'Not Ops Management', Active__c = true
                                    , Quarterly_Target__c=414, RampTime__c = 2, Hire_Date__c = Date.today());

        insert con;

        Test.startTest();
        con.RecordTypeId = employeeContactRT;
        update con;
        Test.stopTest();

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Target__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c
                            FROM Replicon_Timesheet__c
                            WHERE Employee__c =: con.Id];
        


        System.assertEquals(0, timesheetList.size(), 'Placeholder Timesheets were not properly deleted');


    }

}