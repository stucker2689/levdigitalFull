@isTest
private class NonbillWeeklyCheck_Test {

    @TestSetup
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
        oppo.Program_Type__c = 'Strategic';
        oppo.Name = 'Weekly Target Match Batch Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Weekly Target Match Batch Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        testProj.Project_Manager__c = u.Id;
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.Quarterly_Target__c = 414;
        Contact con2 = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con2.Quarterly_Target__c = 414;
        con2.FirstName = 'Test Two';
        con2.LastName = 'Lev Employee Two';
        con2.Replicon_User_Number__c = 9998;
        List<Contact> insertContactList = new List<Contact>{con, con2};
        insert insertContactList;


        //Create Replicon Team Member
        Project_Team_Member__c projTeamMember = TestDataFactory.createRepliconProjectTeamMember(true, con.Id, testProj.Id); //Named Test Replicon Team Member
        Project_Team_Member__c projTeamMember2 = TestDataFactory.createRepliconProjectTeamMember(true, con2.Id, testProj.Id); //Named Test Replicon Team Member


        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(false, con.Id);
        testTimesheet.Replicon_URI__c = 'urn:replicon-tenant:levementum:timesheet:20220102';
        testTimesheet.Start_Date__c = Date.today().toStartOfWeek().addDays(-7);
        insert testTimesheet;

        Replicon_Time_Entry__c entryOne = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryOne.EntryDate__c = Date.today().toStartOfWeek().addDays(-5);
        entryOne.TotalHrs__c = 5;
        entryOne.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221024';        

        Replicon_Time_Entry__c entryTwo = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con2.Id, testProj); //Entry That should NOT be rolled up to First Week of June Weekly Target
        entryTwo.EntryDate__c = Date.today().toStartOfWeek().addDays(-4);
        entryTwo.TotalHrs__c = 5;
        entryTwo.Replicon_URI__c = 'urn:replicon-tenant:levementum:time-allocation:20221025';   

        List<Replicon_Time_Entry__c> timeEntriesList = new List<Replicon_Time_Entry__c>{entryOne, entryTwo};
        insert timeEntriesList;
    }


    @isTest
    static void sendNonbillCheckEmail_Test(){

        Test.startTest();
        NonbillWeeklyCheck.sendNonbillCheck();
        Test.stopTest();

    }

    @isTest
    static void scheduleNonbillCheckScheduleEmail_Test(){

        String cronExpr = '0 0 0 31 12 ? 2025';
        Test.startTest();
        NonbillWeeklyCheck newTestScheduler = new NonbillWeeklyCheck();
        String jobId = System.schedule('Nonbill Scheduler Email Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();

    }
}