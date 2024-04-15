@isTest
private class CreateNewCMWithWorkController_Test {
    
    private static String campaignMilestoneRT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Account testAccount = TestDataFactory.createAccount(false, 'Client');

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{testAccount, levementumLLCAcct};
        insert testAccountList;

        Opportunity testOppty = TestDataFactory.createOpportunity(false, testAccount.Id, 'Salesforce');
        testOppty.Name = 'Test Milestone Oppty';
        testOppty.StageName = 'Closed Won';
        testOppty.Amount = 10000;
        testOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert testOppty;

        User pmUser = [SELECT Id, Name, IsActive FROM User LIMIT 1];

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =: testOppty.Id LIMIT 1];
        testProj.Project_Manager__c = pmUser.Id;
        update testProj;

        Milestone__c testMilestone = new Milestone__c(Name = 'First Milestone', Project__c = testProj.Id, Status__c = 'New', RecordTypeId = campaignMilestoneRT);
        insert testMilestone;
    }

    @isTest
    static void checkIfMilestoneNameIsUnique_notUnique_test(){
        //Call the checkIfMilestoneNameIsUnique method and assert a false name
        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name = 'Test Milestone Oppty' LIMIT 1];

        Test.startTest();
        Boolean uniqueCheck = CreateNewCMWithWorkController.checkIfMilestoneNameIsUnique('First Milestone', testProj.Id);
        Test.stopTest();

        System.assertEquals(false, uniqueCheck, 'Milestone Name and project uniqueness check was incorrectly assessed');
    }

    @isTest
    static void checkIfMilestoneNameIsUnique_Unique_test(){
        //Call the checkIfMilestoneNameIsUnique method and assert a true name
        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name =: 'Test Milestone Oppty' LIMIT 1];

        Test.startTest();
        Boolean uniqueCheck = CreateNewCMWithWorkController.checkIfMilestoneNameIsUnique('Second Milestone', testProj.Id);
        Test.stopTest();

        System.assertEquals(true, uniqueCheck, 'Milestone Name and project uniqueness check was incorrectly assessed');

    }

    @isTest
    static void createMilestoneAndWorkRecordsFromLWC_test(){
        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Name =: 'Test Milestone Oppty' LIMIT 1];

        List<CreateNewCMWithWorkController.WorkWrapper> wrapperList = new List<CreateNewCMWithWorkController.WorkWrapper>();
        for(Integer i=0; i<5; i++){
            CreateNewCMWithWorkController.WorkWrapper newWrapper = new CreateNewCMWithWorkController.WorkWrapper();
            newWrapper.workName = 'New Work Item: ' + String.valueOf(i);
            newWrapper.workIndex = i;
            newWrapper.workId = newWrapper.workName + String.valueOf(i);
            wrapperList.add(newWrapper);
        }

        Test.startTest();
        CreateNewCMWithWorkController.createMilestoneAndWorkRecordsFromLWC('Create Milestone', wrapperList, testProj.Id);
        Test.stopTest();

        Milestone__c createdMilestoneList = [SELECT Id, Name, Project__c, Status__c, RecordTypeId, RecordType.Name FROM Milestone__c WHERE Name = 'Create Milestone' LIMIT 1];

        System.assertEquals('Create Milestone', createdMilestoneList.Name, 'Milestone was not properly created from Apex');

        List<Work__c> createdWorkList = new List<Work__c>();
        createdWorkList = [SELECT Id, Name, Milestone__c, pkl_Status__c, OwnerId, Priority__c, lkp_Project__c, Order__c
                            FROM Work__c];

        System.assertEquals(5, createdWorkList.size(), 'The apex method created the wrong amount of Work Records');

    }



}