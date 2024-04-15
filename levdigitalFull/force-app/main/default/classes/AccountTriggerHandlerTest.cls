@isTest
public with sharing class AccountTriggerHandlerTest {
    
    private static String employeeContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();

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
            
        Blob b2 = Crypto.GenerateAESKey(128);
        String h2 = EncodingUtil.ConvertTohex(b2);
        String uid2 = h2.SubString(0,8);
        User u2 = new User(Alias = uid2, Email= uid2 + '@myorg.com', 
            EmailEncodingKey='UTF-8', FirstName='Sam', LastName='TuckerTwo', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/New_York', UserName= uid2 + '@myorg.com'); 

        Blob b3 = Crypto.GenerateAESKey(128);
        String h3 = EncodingUtil.ConvertTohex(b3);
        String uid3 = h3.SubString(0,8);
        User u3 = new User(Alias = uid3, Email= uid3 + '@myorg.com', 
            EmailEncodingKey='UTF-8', FirstName='Sam', LastName='TuckerThree', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/New_York', UserName= uid3 + '@myorg.com'); 
        
        List<User> userInsertList = new List<User>{u, u2, u3};
        insert userInsertList;    

        u2.ManagerId = u.Id;
        u.ManagerId = u3.Id;    
        List<User> userUpdateList = new List<User>{u, u2};
        update userUpdateList;

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
        oppo.Name = 'Account Trigger Handler Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.SOW_Signed__c = 'Yes';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Account Trigger Handler Test Oppty' LIMIT 1];
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
    }

    @isTest
    static void testAccountDirectorChange(){
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
        testUser = [SELECT Id, Name FROM User WHERE IsActive = true AND LastName = 'Tucker' LIMIT 1];

        Account acc = new Account();
    	acc.Name = 'testAccount';
    	acc.PrimaryPractice__c = 'Salesforce';
        acc.Delivery_Account_Lead__c = testUser.Id;
        insert acc;

        //Opportunity opp = TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp Name');
        Opportunity opp = TestDataFactory.createOpportunity(false, acc.Id, 'Salesforce');
        opp.Name = 'Test Opp Name';
        insert opp;

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

        System.debug('HERE!!!');

        Test.startTest();
        System.debug('HERE 2222222222222222');
        User testUser2 = new User();
        testUser2 = [SELECT Id, Name FROM User WHERE IsActive = true AND LastName = 'TuckerTwo' ORDER BY CreatedDate DESC LIMIT 1][0];
        acc.Delivery_Account_Lead__c = testUser2.Id;
        update acc;
        System.debug('HERE 33333333333333333');
        Test.stopTest();

        System.debug('HERE 4444444444444');
    }

    @isTest
    static void testLevSupportEmailChange(){

        Account acc = new Account();
    	acc.Name = 'testAccount';
    	acc.PrimaryPractice__c = 'Salesforce';
        acc.Lev_Support_Email_Address__c = 'testclientaccountsupportemail@email.com';
        insert acc;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Account Insert');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Account Insert');

        //Opportunity opp1 = TestClassUtil.newSampleOpportunity(acc.Id, 'Test Opp1 Name');
        Opportunity opp1 = TestDataFactory.createOpportunity(false, acc.Id, 'Salesforce');
        opp1.Name = 'Test Opp1 Name';
        insert opp1;

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Opportunity Creation');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Opportunity Creation');

        Project__c proj1 = new Project__c();
        proj1.Account__c = acc.Id;
        proj1.Opportunity__c = opp1.Id;
        insert proj1;

        Project__c testProjectBefore = [SELECT Id, Lev_Support_Email_Address__c FROM Project__c WHERE Id = :proj1.Id LIMIT 1];
        System.assertEquals('testclientaccountsupportemail@email.com', testProjectBefore.Lev_Support_Email_Address__c, 'Project Support Email did not properlyget populated with related Accounts existing Support Email.');

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Project Creation');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Project Creation');

        Test.startTest();
        acc.Lev_Support_Email_Address__c = 'changedlevsupportemailaddress@email.com';
        update acc;
        Test.stopTest();

        System.debug('1. Number of Queries used in this apex code so far: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries() + ' After Lev Support Email Address Update');
        System.debug('2. Number of rows queried in this apex code so far: ' + Limits.getDmlRows() + ' out of ' + Limits.getLimitDmlRows() + ' After Lev Support Email Address Update');

        Project__c testProjectAfter = [SELECT Id, Lev_Support_Email_Address__c FROM Project__c WHERE Id = :proj1.Id LIMIT 1];
        System.assertEquals('changedlevsupportemailaddress@email.com', testProjectAfter.Lev_Support_Email_Address__c, 'Project Support Email did not properly change when Accounts Email was updated.');


    }

    @isTest
    static void testAccountRiskAmountCounter(){
        System.debug('*************************************************************************************************** START OF Test Account Risk Amount Counter *********************************************************************************************************');
        Account acc = new Account();
    	acc.Name = 'testAccount';
    	acc.PrimaryPractice__c = 'Salesforce';
        acc.Lev_Support_Email_Address__c = 'testclientaccountsupportemail@email.com';
        acc.InternalLevAtRisk__c = 'Green';
        insert acc;

        Test.startTest();
        acc.InternalLevAtRisk__c = 'Yellow';
        update acc;
        Test.stopTest();

        Account assertAcct = [SELECT Id, Name, InternalLevAtRisk__c, Yellow_Risk_Level_Amount__c, Orange_Risk_Level_Amount__c, Red_Risk_Level_Amount__c  FROM Account WHERE Name = 'testAccount' LIMIT 1];

        System.assertEquals(1, assertAcct.Yellow_Risk_Level_Amount__c, 'Yellow Risk Level Amount Count field was not properly counted');
        System.debug('**************************************************************************************************** END OF Test Account Risk Amount Counter *****************************************************************************************************');

    }

    @isTest
    static void testCSPUpdate(){

        User testUser2 = new User();
        testUser2 = [SELECT Id, Name FROM User WHERE IsActive = true AND LastName = 'TuckerTwo' ORDER BY CreatedDate DESC LIMIT 1][0];

        Account testAccount = [SELECT Id, Name, Delivery_Account_Lead__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];

        Test.startTest();
        testAccount.Delivery_Account_Lead__c = testUser2.Id;
        update testAccount;
        Test.stopTest();

    }
}