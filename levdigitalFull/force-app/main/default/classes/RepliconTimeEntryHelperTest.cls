/**
 * Created 4/29/2022 ST
 * 
 * Purpose: Test the RepliconTimeEntryHelper Class
 * Function: rollupPTOForecastHours - Rollup Time Off Hours to their related Forecast Record
 * 
 */
@isTest
private class RepliconTimeEntryHelperTest {

    private static String nonbillOrConcessionCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Nonbill Request').getRecordTypeId();

    @testSetup
    static void setupData() {

        Account ptoTestAcccount = TestDataFactory.createAccount(false, 'Client');

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{ptoTestAcccount, levementumLLCAcct};
        insert testAccountList;

        Opportunity ptoTestOppty = TestDataFactory.createOpportunity(false, ptoTestAcccount.Id, 'Salesforce');
        ptoTestOppty.Name = 'Test PTO Oppty';
        ptoTestOppty.StageName = 'Closed Won';
        ptoTestOppty.Amount = 10000;
        ptoTestOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        ptoTestOppty.Peoplesoft_Project_Id__c = '1';
        insert ptoTestOppty;

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =: ptoTestOppty.Id LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:30882';
        update testProj;

        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Cognizant_Employee_Id__c = '12345678';
        insert con;

        //Insert Nonbill Case
        Case nonbillCase = new Case();
        nonbillCase.RecordTypeId = nonbillOrConcessionCaseRT;
        nonbillCase.Subject = 'Test Nonbill Case';
        nonbillCase.ContactId = con.Id;
        insert nonbillCase;
    }
    

    @isTest
    static void testRollupTimeOffHoursOnPTOForecasts(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];

        Contact con = [SELECT Id, Name, Replicon_User_Number__c FROM Contact WHERE Name = 'Test Lev Employee'];

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(true, con.Id);

        Replicon_Time_Entry__c testPtoEntry1 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry1.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testPtoEntry1.EntryDate__c = Date.today();
        testPtoEntry1.TotalHrs__c = 8;
        testPtoEntry1.Time_Off__c = true;
        testPtoEntry1.Peoplesoft_Project_Id__c = '1';
        testPtoEntry1.Cognizant_Employee_Id__c = '12345678';

        Replicon_Time_Entry__c testPtoEntry2 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry2.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testPtoEntry2.EntryDate__c = Date.today();
        testPtoEntry2.TotalHrs__c = 8;
        testPtoEntry2.Time_Off__c = false;
        testPtoEntry2.Peoplesoft_Project_Id__c = '1';
        testPtoEntry2.Cognizant_Employee_Id__c = '12345678';

        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{testPtoEntry1, testPtoEntry2};

        Test.startTest();
        insert entryList;
        Test.stopTest();

        List<RepliconForecast__c> testForecastList = new List<RepliconForecast__c>();
        testForecastList = [SELECT Id, Name, EstimatedHours__c
                            FROM RepliconForecast__c
                            WHERE Project__r.Name = 'Test PTO Oppty'];

        for(RepliconForecast__c forecast : testForecastList){
            System.assertEquals(8, forecast.EstimatedHours__c, 'Forecast Estimated Hours was not properly rolled up on PTO Forecasts');
        }        
    }

    @isTest
    static void testLinkTimeEntryToProjectRole(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        Contact testContact = [SELECT Id, Name, AccountId FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        Client_Contact__c projTeamMember = new Client_Contact__c(Client_Contact__c = testContact.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = devBillRate.Id);
        insert projTeamMember;

        Date postATGDate = Date.newInstance(2022, 6, 20);
        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c(Peoplesoft_Project_Id__c = '1', Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 4, Billing_Action__c = 'B', Cognizant_Employee_Id__c = '12345678',
                                                                        Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882', EntryDate__c = postATGDate, Employee__c = testContact.Id);

        Test.startTest();
        insert timeEntry;
        Test.stopTest();

        Replicon_Time_Entry__c assertTimeEntry = [SELECT Id, Name, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c, ProjectRole__c FROM Replicon_Time_Entry__c LIMIT 1];
        System.debug('****************************testLinkTimeEntryToProjectRole: ' + assertTimeEntry);

        System.assertEquals(devProjRole.Id, assertTimeEntry.ProjectRole__c, 'The Time Entry did not have the Project Role properly populated.');

        ProjectRole__c assertProjectRole = [SELECT Id, Name, Total_Amount_Billed__c, Total_Hours_Billed__c FROM ProjectRole__c LIMIT 1];

        System.assertEquals(800, assertProjectRole.Total_Amount_Billed__c, 'Project Role Total Amount Billed was not properly calculated');
        System.assertEquals(4, assertProjectRole.Total_Hours_Billed__c, 'Project Role Total Hours Billed was not properly calculated');

    }

    @isTest
    static void testLinkTimeEntryToProjectRoleClosestMatch(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        Contact testContact = [SELECT Id, Name, AccountId FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 2', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        Client_Contact__c projTeamMember = new Client_Contact__c(Client_Contact__c = testContact.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = devBillRate.Id);
        insert projTeamMember;

        Date postATGDate = Date.newInstance(2022, 6, 20);
        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c(Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 4, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882',
                                                                        EntryDate__c = postATGDate, Employee__c = testContact.Id, Billing_Action__c = 'B', Cognizant_Employee_Id__c = '12345678');

        Test.startTest();
        insert timeEntry;
        Test.stopTest();

        List<Replicon_Time_Entry__c> entryList = [SELECT Id, Name, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c, Internal_Project_Team_Member__c, ProjectRole__c FROM Replicon_Time_Entry__c];
        System.debug('SIZE: ' + entryList.size());

        Replicon_Time_Entry__c assertTimeEntry = [SELECT Id, Name, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c, Internal_Project_Team_Member__c, ProjectRole__c FROM Replicon_Time_Entry__c LIMIT 1];
        System.debug('Test Link Time Entry To Project Role Closest Match: ' + assertTimeEntry);
        System.debug('Test Link Time Entry To Project Role Closest Match Bill Rate Name: ' + assertTimeEntry.Associated_Billing_Rate__r.Name);
        System.debug('Test Link Time Entry To Project Role Closest Match Bill Rate Name: ' + assertTimeEntry.Associated_Billing_Rate__r.Name);

        System.assertEquals(devProjRole.Id, assertTimeEntry.ProjectRole__c, 'The Time Entry did not have the Project Role properly populated.');

        ProjectRole__c assertProjectRole = [SELECT Id, Name, Total_Amount_Billed__c, Total_Hours_Billed__c FROM ProjectRole__c LIMIT 1];

        System.assertEquals(800, assertProjectRole.Total_Amount_Billed__c, 'Project Role Total Amount Billed was not properly calculated');
        System.assertEquals(4, assertProjectRole.Total_Hours_Billed__c, 'Project Role Total Hours Billed was not properly calculated');

    }

    @isTest
    static void testLinkTimeEntryToProjectRoleClosestMatch2(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        Contact testContact = [SELECT Id, Name, AccountId FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        ProjectRole__c devProjRole2 = new ProjectRole__c(Name = 'Developer 2', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        ProjectRole__c devProjRole3 = new ProjectRole__c(Name = 'Developer 3', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 4', Hourly_Rate__c = 150, Project__c = testProj.Id);
        insert devBillRate;

        Client_Contact__c projTeamMember = new Client_Contact__c(Client_Contact__c = testContact.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = devBillRate.Id);
        insert projTeamMember;

        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c(Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 4, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882', 
                                                                        EntryDate__c = Date.today(), Employee__c = testContact.Id, Billing_Action__c = 'B', Cognizant_Employee_Id__c = '12345678');

        Test.startTest();
        insert timeEntry;
        Test.stopTest();

        Replicon_Time_Entry__c assertTimeEntry = [SELECT Id, Name, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c, ProjectRole__c FROM Replicon_Time_Entry__c LIMIT 1];
        System.debug('****************************testLinkTimeEntryToProjectRoleClosestMatch2: ' + assertTimeEntry);

        System.assertEquals(devProjRole.Id, assertTimeEntry.ProjectRole__c, 'The Time Entry did not have the Project Role properly populated.');

        ProjectRole__c assertProjectRole = [SELECT Id, Name, Total_Amount_Billed__c, Total_Hours_Billed__c FROM ProjectRole__c LIMIT 1];

        System.assertEquals(600, assertProjectRole.Total_Amount_Billed__c, 'Project Role Total Amount Billed was not properly calculated');
        System.assertEquals(4, assertProjectRole.Total_Hours_Billed__c, 'Project Role Total Hours Billed was not properly calculated');

    }

    @isTest
    static void testUndeleteTimeEntryWhenHoursUpdated(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        Contact testContact = [SELECT Id, Name, AccountId FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];

        ProjectRole__c devProjRole = new ProjectRole__c(Name = 'Developer', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        ProjectRole__c devProjRole2 = new ProjectRole__c(Name = 'Developer 2', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        ProjectRole__c devProjRole3 = new ProjectRole__c(Name = 'Developer 3', Project__c = testProj.Id, Rate__c = 200, Resource_Delivery_Group__c = 'Lev');
        insert devProjRole;

        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer 4', Hourly_Rate__c = 150, Project__c = testProj.Id);
        insert devBillRate;

        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c(Deleted_in_Replicon__c = true, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 0, Cognizant_Employee_Id__c = '12345678',
                                                                    Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882', EntryDate__c = Date.today(), Employee__c = testContact.Id);

        Test.startTest();
        insert timeEntry;

        timeEntry.TotalHrs__c = 8;
        update timeEntry;
        Test.stopTest();

        Replicon_Time_Entry__c assertTimeEntry = [SELECT Id, Name, ProjectRole__c, Deleted_in_Replicon__c FROM Replicon_Time_Entry__c LIMIT 1];

        System.assertEquals(false, assertTimeEntry.Deleted_in_Replicon__c, 'The Time Entry was not properly undeleted');

    }

    @isTest
    static void testLinkEntryToNonBillCase(){

        Project__c testProj  = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test PTO Oppty' LIMIT 1];
        Contact testContact = [SELECT Id, Name, AccountId FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Case nonbillCase = [SELECT Id, Subject FROM Case WHERE Subject = 'Test Nonbill Case' LIMIT 1];

        String caseComment = 'Test Case Id in Comments: ' + nonbillCase;

        //Insert Entry With Case Id In Comments
        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c(Deleted_in_Replicon__c = false, Project__c = testProj.Id, TotalHrs__c = 42, 
                                                                        Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882', EntryDate__c = Date.today(), Employee__c = testContact.Id, Comments__C = caseComment );

        Test.startTest();
        insert timeEntry;
        Test.stopTest();

        Replicon_Time_Entry__c assertEntry = [SELECT Id, Name, RelatedNonbillOrConcessionCase__c FROM Replicon_Time_Entry__c LIMIT 1];

        System.assertEquals(nonbillCase.Id, assertEntry.RelatedNonbillOrConcessionCase__c, 'Time entry was not properly linked to a Nonbill or Cnocession Case via the id being populated in the comments');
    }



}