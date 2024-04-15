@isTest
private class ProjectTriggerHandlerTest {

    @TestSetup
    static void testSetupData(){
        System.debug('***************** ProjectTriggerHandlerTest Setup Data Start *****************');
        //Create Acc
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        insert acct;
        System.debug('***************** ProjectTriggerHandlerTest Setup Data AFTER ACCOUNT INSERT *****************');


        //Create Opp
        Opportunity oppo = new Opportunity();
        oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'ProjectTriggerHandler Test Oppty';
        insert oppo;
        System.debug('***************** ProjectTriggerHandlerTest Setup Data AFTER OPPTY INSERT *****************');

        //Move to Closed Won
        oppo.StageName='Closed Won';
        oppo.Do_Not_Create_Project__c = false;
        oppo.Project_Background_Objectives__c = 'Testing';
        oppo.Description = 'This is a description';
        oppo.Goals__c = 'These are goals.';
        oppo.SOW_Hyperlink__c = 'www.google.com';        
        update oppo;
        System.debug('***************** ProjectTriggerHandlerTest Setup Data AFTER OPPTY UPDATE *****************');

        //Insert a Change Order
        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = oppo.Id;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        insert changeOrderOppty;
        System.debug('***************** ProjectTriggerHandlerTest Setup Data AFTER CO INSERT *****************');
    }

    @isTest 
	static void test_updateRepliconDataTest() {   
        System.debug('----------------------- ProjectTriggerHandlerTest test_updateRepliconDataTest -----------------------');

        Opportunity testOppty = new Opportunity();
        testOppty = [SELECT Id, Name, Change_Order_Revenue__c, Change_Order_Hours__c, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c FROM Opportunity WHERE Name = 'ProjectTriggerHandler Test Oppty' LIMIT 1];

        //Now Project would have been created. Asserting the Name equals the Opp Name, 
        Project__c proj = new Project__c();
        proj = TestClassUtil.getProjectforOpp(testOppty.Id);

        Test.startTest();
		testOppty.Change_Order_Revenue__c = 2000; 
        testOppty.Change_Order_Hours__c = 2000; 
        testOppty.Total_Hours_Invoiced_to_Date__c = 10;
        testOppty.Total_Amount_Invoiced_to_Date__c = 1000;
        update testOppty;

        proj = TestClassUtil.getProjectforOpp(testOppty.Id);
        System.assertEquals(10,proj.Total_Hours_Invoiced_to_Date__c);
        System.assertEquals(1000,proj.Total_Amount_Invoiced_to_Date__c);

        proj.Total_Hours_Invoiced_to_Date__c = 3000;
        proj.Total_Amount_Invoiced_to_Date__c = 3000;
        proj.SR_Overall_Health_Value__c = 'Red';
        update proj; 
        Test.stopTest();
	}

    //11/23 ST
    //To Test ProjectTriggerHandler PM update functionality
    @isTest 
	static void populateProjectManagerTest() {
        System.debug('----------------------- ProjectTriggerHandlerTest populateProjectManagerTest -----------------------');
        //Create User
        User testUser = new User();
        testUser = [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY CreatedDate DESC LIMIT 1];

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, Project_Manager__c, Opportunity__c FROM Project__c WHERE Opportunity__r.Name = 'ProjectTriggerHandler Test Oppty' LIMIT 1];

        Test.startTest();
        testProj.Project_Manager__c = testUser.Id;
        update testProj;
        Test.stopTest();

        List<Opportunity> relatedOpptyList = new List<Opportunity>();
        relatedOpptyList = [SELECT Id, Name, Project_ManagerLookup__c, Change_Orders__c FROM Opportunity WHERE Id =: testProj.Opportunity__c OR Change_Orders__c =: testProj.Opportunity__c];
        for(Opportunity opp : relatedOpptyList){
            System.assertEquals(opp.Project_ManagerLookup__c, testUser.Id, 'Project Manager Lookup assignment on Project did not cascade to Related Opportunities properly');
        }

    }

    @isTest
    static void updateDetailsOnProjectTest(){

        System.debug('----------------------- ProjectTriggerHandlerTest updateDetailsOnProjectTest -----------------------');

        Opportunity testOppty = new Opportunity();
        testOppty = [SELECT Id, Name, Change_Order_Revenue__c, Change_Order_Hours__c, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c FROM Opportunity WHERE Name = 'ProjectTriggerHandler Test Oppty' LIMIT 1];

        //Now Project would have been created. Asserting the Name equals the Opp Name, 
        Project__c proj = new Project__c();
        proj = TestClassUtil.getProjectforOpp(testOppty.Id);

        proj.Rollup_Billable__c = 100;
        proj.Total_Amount_Invoiced_to_Date__c = 10000;
        proj.Project_Status__c = 'Active';
        
        Test.startTest();
        update proj;        
        Test.stopTest();

        delete proj;

    }

    @isTest
    static void updateProjectToOnHoldTest(){

        Project__c proj = [SELECT Id, Name, Project_Status__c, Account__c FROM Project__c WHERE Name = 'ProjectTriggerHandler Test Oppty' LIMIT 1];

        Test.startTest();
		proj.Project_Status__c = 'On Hold'; 
        update proj;
        Test.stopTest();

        Account assertAccount = [SELECT Id, Name, On_Hold_Projects__c, Closed_Projects__c, ActiveProjectCount__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        System.assertEquals(assertAccount.On_Hold_Projects__c, 1, 'On Hold Projects Count on Account was not properly calculated');

        delete proj;
        
    }

    @isTest
    static void updateProjectToCompletedTest(){

        Project__c proj = [SELECT Id, Name, Project_Status__c FROM Project__c WHERE Name = 'ProjectTriggerHandler Test Oppty' LIMIT 1];

        Test.startTest();
		proj.Project_Status__c = 'Completed'; 
        update proj;
        Test.stopTest();
        
        Account assertAccount = [SELECT Id, Name, On_Hold_Projects__c, Closed_Projects__c, ActiveProjectCount__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        System.assertEquals(assertAccount.Closed_Projects__c, 1, 'Closed Projects Count on Account was not properly calculated');

        delete proj;
    }
}