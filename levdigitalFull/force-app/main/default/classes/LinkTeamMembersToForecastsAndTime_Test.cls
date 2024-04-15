@isTest
public with sharing class LinkTeamMembersToForecastsAndTime_Test {
    
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
        oppo.Name = 'Test Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 1;
        oppo.Number_of_Products__c = 1;
        oppo.StageName = 'Closed Won';
        oppo.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        oppo.Peoplesoft_Project_Id__c = '11111111';
        insert oppo;

        //Query for Created Proj from Oppty to use Id
        Project__c testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:44444';
        update testProj;

        //Create Contact for Time Entries
        Contact con = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        con.FirstName = 'Test';
        con.LastName = 'EmployeeOne';
        con.Cognizant_Employee_Id__c = '1234';
        Contact placeholderCon = TestDataFactory.createEmployee(false, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999
        placeholderCon.FirstName = 'Place';
        placeholderCon.LastName = 'Holder';
        List<Contact> contactInsertList = new List<Contact>{con, placeholderCon};
        insert contactInsertList;

        //Create Replicon Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c testProjMemberBillRate = TestDataFactory.createRepliconBillingRate(false, null, testProj.Id); //Being created with a $200 Hourly Rate, Named Test Billing Rate Rate, Replicon URI of urn:replicon-tenant:levementum:company-billing-rate:abc123
        testProjMemberBillRate.Name = 'MC - Solution Architect';
        insert testProjMemberBillRate;

        Client_Contact__c testTeamMember = new Client_Contact__c(Client_Contact__c = con.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id);
        Client_Contact__c placeholderTeamMember = new Client_Contact__c(Client_Contact__c = placeholderCon.Id, Project__c = testProj.Id, Contact_Role__c = 'MC - Solution Architect', Assigned_Billing_Rate__c = testProjMemberBillRate.Id, Is_Placeholder_Team_Member__c = true);
        List<Client_Contact__c> teamMemberInsertList = new List<Client_Contact__c>{testTeamMember, placeholderTeamMember};
        insert teamMemberInsertList;
    }

    @isTest
    static void linkTeamMembers_Test(){

        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Contact placeholder = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];
        Client_Contact__c testTeamMember = [SELECT Id, Name, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Contact_Role__c FROM Client_Contact__c LIMIT 1];

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '11111111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        insert newEntry;

        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
        entryList = [SELECT Id, Name, Internal_Project_Team_Member__c FROM Replicon_Time_Entry__c];

        List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList){
            entry.Internal_Project_Team_Member__c = null;
            entryUpdateList.add(entry);
        }

        update entryUpdateList;

        RepliconForecast__c firstWeekOfAugustForecast = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 6), null); //Also includes last week of July 7/31/2022 - 8/6/2022
        firstWeekOfAugustForecast.EstimatedHours__c = 1;
        RepliconForecast__c secondWeekOfJuneForecast = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 13), null); //Week of August 8/7/2022 - 8/13/2022
        secondWeekOfJuneForecast.EstimatedHours__c = 2;
        RepliconForecast__c lastWeekOfAugustForecast = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 3), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        lastWeekOfAugustForecast.EstimatedHours__c = 3;
        RepliconForecast__c secondWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, placeholder.Id, Date.newInstance(2022, 9, 10), null); //Week of September 9/4/2022 - 9/10/2022
        secondWeekOfSeptemberForecast.EstimatedHours__c = 4;
        RepliconForecast__c lastWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, placeholder.Id, Date.newInstance(2022, 10, 1), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        lastWeekOfSeptemberForecast.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{firstWeekOfAugustForecast, secondWeekOfJuneForecast, lastWeekOfAugustForecast, secondWeekOfSeptemberForecast, lastWeekOfSeptemberForecast};
        insert testRepliconForecastsToInsert;

        List<RepliconForecast__c> forecastList = [SELECT Id, Name, Internal_Project_Team_Member__c FROM RepliconForecast__c];

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            forecast.Internal_Project_Team_Member__c = null;
            forecastUpdateList.add(forecast);
        }

        update forecastUpdateList;

        Test.startTest();
        Set<Id> projectIdSet = new Set<Id>{testProj.Id};
        Set<Id> contactIdSet = new Set<Id>{testEmployee.Id};
        LinkTeamMembersToForecastsAndTimeBatch teamMemberForecastLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Forecast', projectIdSet, contactIdSet);
        Database.executeBatch(teamMemberForecastLinkBatch, 500);

        LinkTeamMembersToForecastsAndTimeBatch teamMemberTimeEntryLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Time Entry', projectIdSet, contactIdSet);
        Database.executeBatch(teamMemberTimeEntryLinkBatch, 500);
        Test.stopTest();

    }

    @isTest
    static void createProjectTeamMemberLink_Test(){
        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test EmployeeOne' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty' LIMIT 1];

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '1234';
        newEntry.Peoplesoft_Project_Id__c = '11111111';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.TotalHrs__c = 8;
        insert newEntry;

        List<Client_Contact__c> teamMembers = [SELECT Id, Name, Project__c FROM Client_Contact__c];
        delete teamMembers;

        Client_Contact__c newTeamMember = new Client_Contact__c(Project__c = testProj.Id, Client_Contact__c = testEmployee.Id);
        insert newTeamMember;
        
        Test.startTest();
        Set<Id> projectIdSet = new Set<Id>{testProj.Id};
        Set<Id> contactIdSet = new Set<Id>{testEmployee.Id};
        LinkTeamMembersToForecastsAndTimeBatch teamMemberTimeEntryLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Time Entry', projectIdSet, contactIdSet);
        Database.executeBatch(teamMemberTimeEntryLinkBatch, 500);
        Test.stopTest();
    }
}