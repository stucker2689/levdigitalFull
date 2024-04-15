@isTest(seeAllData=true)
private class TemporaryRateScheduledEmailReport_Test {
    
    /*@TestSetup
    static void makeData(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        User u = new User(Alias = uid, Email= uid + '@myorg.com', 
            EmailEncodingKey='UTF-8', FirstName='Sam', LastName='Tucker', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com');      
        insert u;
        

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
        oppo.Name = 'Weekly Target Match Batch Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Ini';
        oppo.Peoplesoft_Project_Id__c = '11111111';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Weekly Target Match Batch Test Oppty' LIMIT 1];
        testProj.Opportunity__c = oppo.Id;
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        testProj.Project_Manager__c = u.Id;
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        Contact con2 = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con2.FirstName = 'Test Two';
        con2.LastName = 'Lev Employee Two';
        con2.Replicon_User_Number__c = 9998;
        con2.Cognizant_Employee_Id__c = '1234';
        List<Contact> insertContactList = new List<Contact>{con, con2};
        insert insertContactList;


        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member
        Project_Team_Member__c projTeamMember2 = TestDataFactory.createRepliconProjectTeamMember(true, con2.Id, testProj.Id); //Named Test Replicon Team Member

        //Create Replicon Team Member Billing Rate
        //Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(false, projTeamMember.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        //Project_Team_Member_Billing_Rate__c testProjMemberBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC - Project Manager', Hourly_Rate__c = 200, Project__c = testProj.Id);
        //Project_Team_Member_Billing_Rate__c testProjMemberBillRateTwo = TestDataFactory.createRepliconBillingRate(false, projTeamMember2.Id, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        //Project_Team_Member_Billing_Rate__c testProjMemberBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'MC - Solution Architect', Hourly_Rate__c = 200, Project__c = testProj.Id);

        //testProjMemberBillRate.Name = 'Temporary Rate';
       //testProjMemberBillRateTwo.Name = 'Temporary Rate';
        //List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>{testProjMemberBillRate, testProjMemberBillRateTwo};
        //insert billRateList;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220102';
        testTimesheet.Start_Date__c = Date.today().toStartOfWeek().addDays(-7);
        //insert testTimesheet;

        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.today().toStartOfWeek().addDays(-5);
        entryOne.TotalHrs__c = 5;
        //entryOne.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221024';        
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111';

        Replicon_Time_Entry__c entryTwo = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con2.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryTwo.EntryDate__c = Date.today().toStartOfWeek().addDays(-4);
        entryTwo.TotalHrs__c = 5;
        //entryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221025';  
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111' ;

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo};
        //insert timeEntriesList;
        
    }*/

/*
    @isTest
    static void sendTempRateEmail_Test(){

        Project__c proj = [SELECT Id, Name, Peoplesoft_Project_Id__c FROM Project__c LIMIT 1];
        Contact con = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Replicon_User_Number__c = 9999 LIMIT 1];
        Contact con2 = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE LastName = 'Lev Employee Two' LIMIT 1];

        Test.startTest();
        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, null, con.Id, proj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.today().toStartOfWeek().addDays(-5);
        entryOne.TotalHrs__c = 5;
        //entryOne.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221024';        
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111';

        Replicon_Time_Entry__c entryTwo = TestDataFactory.createTimeEntry(false, null, con2.Id, proj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryTwo.EntryDate__c = Date.today().toStartOfWeek().addDays(-4);
        entryTwo.TotalHrs__c = 5;
        //entryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221025';  
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111' ;

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo};
        insert timeEntriesList;

        TemporaryRateScheduledEmailReport.scheduleJob();
        Test.stopTest();

    }

    @isTest
    static void scheduleTempRateScheduleEmail_Test(){

        Project__c proj = [SELECT Id, Name, Peoplesoft_Project_Id__c FROM Project__c LIMIT 1];
        Contact con = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Replicon_User_Number__c = 9999 LIMIT 1];
        Contact con2 = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE LastName = 'Lev Employee Two' LIMIT 1];

        String cronExpr = '0 0 0 31 12 ? 2023';
        Test.startTest();
        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, null, con.Id, proj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.today().toStartOfWeek().addDays(-5);
        entryOne.TotalHrs__c = 5;
        //entryOne.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221024';        
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111';

        Replicon_Time_Entry__c entryTwo = TestDataFactory.createTimeEntry(false, null, con2.Id, proj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryTwo.EntryDate__c = Date.today().toStartOfWeek().addDays(-4);
        entryTwo.TotalHrs__c = 5;
        //entryTwo.Replicon_Billing_Rate_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';
        //entryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221025';  
        entryOne.Billing_Action__c = 'B';
        entryOne.Cognizant_Employee_Id__c = '1234';
        entryOne.Peoplesoft_Project_Id__c = '11111111' ;

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo};
        insert timeEntriesList;

        TemporaryRateScheduledEmailReport newTestScheduler = new TemporaryRateScheduledEmailReport();
        String jobId = System.schedule('Temp Rate Scheduler Email Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();

    }*/

    @isTest
    static void sendTempRateEmail_Test2(){

        Test.startTest();

        TemporaryRateScheduledEmailReport.scheduleJob();
        Test.stopTest();

    }

    @isTest
    static void scheduleTempRateScheduleEmail_Test2(){
        Test.startTest();
        String cronExpr = '0 0 0 31 12 ? 2025';
        TemporaryRateScheduledEmailReport newTestScheduler = new TemporaryRateScheduledEmailReport();
        String jobId = System.schedule('Temp Rate Scheduler Email Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();

    }
}