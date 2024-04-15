@isTest
private class ProjectRollupCalcQueueable_Test {
    

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

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220925';
        testTimesheet.Name = 'Test Lev Employee: 09/25/2022';
        testTimesheet.EmployeeDepartment__c = 'Consulting';
        testTimesheet.Start_Date__c = Date.newInstance(2022, 9, 25);
        testTimesheet.Target__c = 36;

        Replicon_Timesheet__c testTimesheet2 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet2.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221002';
        testTimesheet2.Name = 'Test Lev Employee: 10/02/2022';
        testTimesheet2.EmployeeDepartment__c = 'Consulting';
        testTimesheet2.Start_Date__c = Date.newInstance(2022, 10, 2);

        Replicon_Timesheet__c testTimesheet3 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet3.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221009';
        testTimesheet3.Name = 'Test Lev Employee: 10/09/2022';
        testTimesheet3.EmployeeDepartment__c = 'Consulting';
        testTimesheet3.Start_Date__c = Date.newInstance(2022, 10, 9);

        Replicon_Timesheet__c testTimesheet4 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet4.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221016';
        testTimesheet4.Name = 'Test Lev Employee: 10/16/2022';
        testTimesheet4.EmployeeDepartment__c = 'Consulting';
        testTimesheet4.Start_Date__c = Date.newInstance(2022, 10, 16);

        Replicon_Timesheet__c testTimesheet5 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet5.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221023';
        testTimesheet5.Name = 'Test Lev Employee: 10/23/2022';
        testTimesheet5.EmployeeDepartment__c = 'Consulting';
        testTimesheet5.Start_Date__c = Date.newInstance(2022, 10, 23);

        Replicon_Timesheet__c testTimesheet6 = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet6.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20221030';
        testTimesheet6.Name = 'Test Lev Employee: 10/30/2022';
        testTimesheet6.Start_Date__c = Date.newInstance(2022, 10, 30);

        List<Replicon_Timesheet__c> timesheetInsertList = new List<Replicon_Timesheet__c>{testTimesheet, testTimesheet2, testTimesheet3, testTimesheet4, testTimesheet5, testTimesheet6};
        insert timesheetInsertList;

        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(true, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123

        Replicon_Time_Entry__c testEntry = TestDataFactory.createTimeEntry(false, testTimesheet3.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        testEntry.EntryDate__c = Date.newInstance(2022, 10, 11);
        testEntry.TotalHrs__c = 5;
        testEntry.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:2022123';        

        Replicon_Time_Entry__c testEntry2 = TestDataFactory.createTimeEntry(false, testTimesheet5.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        testEntry2.EntryDate__c = Date.newInstance(2022, 10, 28);
        testEntry2.TotalHrs__c = 6;
        testEntry2.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        testEntry2.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221234';

        Replicon_Time_Entry__c testEntry3 = TestDataFactory.createTimeEntry(false, testTimesheet5.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        testEntry3.EntryDate__c = Date.newInstance(2022, 9, 2);
        testEntry3.TotalHrs__c = 6;
        testEntry3.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        testEntry3.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:202212345';

        Replicon_Time_Entry__c testEntry4 = TestDataFactory.createTimeEntry(false, testTimesheet5.Id, con.Id, testProj); //Entry That should be rolled up to First Week of June Weekly Target
        testEntry4.EntryDate__c = Date.newInstance(2022, 9, 2);
        testEntry4.TotalHrs__c = 6;
        testEntry4.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        testEntry4.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:2022123456';
        testEntry4.ActivityName__c = 'BCP';

        List<Replicon_Time_Entry__c> entryInsertList = new List<Replicon_Time_Entry__c>{testEntry, testEntry2, testEntry3, testEntry4};
        insert entryInsertList;
    }

    @isTest
    static void rollupProjectWithQueueable_Test(){
        Set<Id> queueableProjIdSet = new Set<Id>();

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name FROM Project__c];

        for(Project__c proj : projList){
            queueableProjIdSet.add(proj.Id);
        }

        Test.startTest();
        System.enqueueJob(new ProjectRollupCalcQueueable(queueableProjIdSet));
        Test.stopTest();
    }

    @isTest
    static void rollupProjectWithQueueableTwo_Test(){
        Set<Id> queueableProjIdSet = new Set<Id>();

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name, Rollup_Billable__c FROM Project__c];

        List<Project__c> updateProjList = new List<Project__c>();
        for(Project__c proj : projList){
            queueableProjIdSet.add(proj.Id);
            proj.Rollup_Billable__c = 10000;
            updateProjList.add(proj);
        }

        Test.startTest();
        update updateProjList;
        System.enqueueJob(new ProjectRollupCalcQueueable(queueableProjIdSet));
        Test.stopTest();
    }

    @isTest
    static void rollupProjectWithNoEntries_Test(){

        Account testAcct = [SELECT Id, Name FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Opportunity oppo = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        oppo.Name = 'No Entry Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'No Entry Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44445';
        update testProj;

        Set<Id> queueableProjIdSet = new Set<Id>{testProj.Id};

        Test.startTest();
        System.enqueueJob(new ProjectRollupCalcQueueable(queueableProjIdSet));
        Test.stopTest();
    }

    @isTest
    static void rollupProjectWithSetList(){

        Account testAcct = [SELECT Id, Name FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Opportunity oppo = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        oppo.Name = 'No Entry Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'No Entry Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44445';
        update testProj;


        Set<Id> queueableProjIdSet = new Set<Id>();

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name, Rollup_Billable__c FROM Project__c];

        List<Project__c> updateProjList = new List<Project__c>();
        for(Project__c proj : projList){
            queueableProjIdSet.add(proj.Id);
            proj.Rollup_Billable__c = 10000;
            proj.Rollup_Concession__c = 1000;
            proj.Rollup_Nonbillable__c = 1000;
            proj.Rollup_Revenue__c = 1000;
            proj.Replicon_Hours_This_Month__c = 1000;
            proj.PreviousWeeksBillableHrs__c = 1000;
            proj.BudgetRemainingasofPrevWeek__c = 1000;
            proj.NonLevBillableHoursBooked__c = 1000;
            updateProjList.add(proj);
        }

        Test.startTest();
        update updateProjList;
        RepliconService newService = new RepliconService();
        newService.calculateProjectRollupValues(queueableProjIdSet);
        Test.stopTest();
    }

}