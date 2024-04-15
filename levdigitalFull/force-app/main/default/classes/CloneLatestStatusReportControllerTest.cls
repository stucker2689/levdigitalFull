@isTest
private class CloneLatestStatusReportControllerTest {
    //(SeeAllData = true)

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
        oppo.Name = 'Clone Status Report Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Clone Status Report Test Oppty' LIMIT 1];

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        Status_Report__c strep1 = new Status_Report__c();
        strep1.Name = 'Less Recent Status Report';
        strep1.Account__c = acct.Id;
        strep1.Opportunity__c = oppo.Id;
        strep1.Project__c = testProj.Id;
        strep1.Reporting_Period_From__c = Date.today().addDays(-14);
        strep1.Reporting_Period_Ending__c = Date.today().addDays(-7);
        strep1.Executive_Summary__c = 'Test Exec Summary';
        strep1.Key_Accomplishments_This_Period__c = 'Test Accomplishments';
        strep1.Key_Decisions__c = 'Test Key Decisions';
        strep1.Plans_for_Next_Period__c = 'Test Plans for Next Period';
        strep1.Overall_Health_Value__c = 'Green';
        strep1.Budget_Value__c= 'Green';
        strep1.Risk_Value__c= 'Green';
        strep1.Schedule_Value__c= 'Green';
        strep1.Scope_Value__c= 'Green';
        strep1.Overall_Health_Comments__c = 'Green';
        strep1.Budget_Comments__c= 'Green';
        strep1.Risk_Comments__c= 'Green';
        strep1.Schedule_Comments__c= 'Green';
        strep1.Scope_Comments__c= 'Green';

        insert strep1;

        Status_Report__c strep2 = new Status_Report__c();
        strep2.Name = 'Most Recent Status Report';
        strep2.Account__c = acct.Id;
        strep2.Opportunity__c = oppo.Id;
        strep2.Project__c = testProj.Id;
        strep2.Reporting_Period_From__c = Date.today().addDays(-10);
        strep2.Reporting_Period_Ending__c = Date.today().addDays(-3);
        strep2.Executive_Summary__c = 'Test Exec Summary';
        strep2.Key_Accomplishments_This_Period__c = 'Test Accomplishments';
        strep2.Key_Decisions__c = 'Test Key Decisions';
        strep2.Plans_for_Next_Period__c = 'Test Plans for Next Period';
        strep2.Overall_Health_Value__c = 'Green';
        strep2.Budget_Value__c= 'Green';
        strep2.Risk_Value__c= 'Green';
        strep2.Schedule_Value__c= 'Green';
        strep2.Scope_Value__c= 'Green';
        strep2.Overall_Health_Comments__c = 'Green';
        strep2.Budget_Comments__c= 'Green';
        strep2.Risk_Comments__c= 'Green';
        strep2.Schedule_Comments__c= 'Green';
        strep2.Scope_Comments__c= 'Green';
        
        insert strep2;
                            
    }

    @isTest
    static void testGetLatestStatusReport(){

        Id testProjectId = [SELECT Id, Name FROM Project__c WHERE Name = 'Clone Status Report Test Oppty'].Id;

        Status_Report__c mostRecentStatusReport = new Status_Report__c();
        Test.startTest();
        mostRecentStatusReport = CloneLatestStatusReportLWCController.getLatestStatusReportToClone(testProjectId);
        Test.stopTest();

        System.assertEquals('Most Recent Status Report', mostRecentStatusReport.Name, 'The most recent Status Report was not retrieved properly');

    }

    @isTest
    static void testGetRelatedProject(){

        Id testProjectId = [SELECT Id, Name FROM Project__c WHERE Name = 'Clone Status Report Test Oppty'].Id;

        Project__c relatedProject = new Project__c();
        Test.startTest();
        relatedProject = CloneLatestStatusReportLWCController.getProjectDetailsForNewStatusReport(testProjectId);
        Test.stopTest();

        System.assertEquals('Clone Status Report Test Oppty', relatedProject.Name, 'The related Project was not retrieved properly');

    }
}