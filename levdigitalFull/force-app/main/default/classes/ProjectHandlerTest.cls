@isTest
private class ProjectHandlerTest {
	

    @TestSetup
    static void testSetupData(){
        //Create Acc
        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account 2';
        acct.Lev_Support_Email_Address__c = 'TestClientAccountSupportEmail@email.com';
        insert acct;


        //Create Opp
        Opportunity oppo = new Opportunity();
        //oppo = TestClassUtil.newSampleOpportunity(acc.Id,'Test1');
        oppo = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        oppo.Name = 'ProjectHandlerTest Oppty';
        oppo.Number_of_Contact_Rolls_Added__c = 2;
        insert oppo;

        //Move to Closed Won
        oppo.StageName='Closed Won';
        oppo.Create_Project__c = TRUE;
        oppo.Do_Not_Create_Project__c = FALSE;
        oppo.Project_Background_Objectives__c = 'Testing';
        oppo.Description = 'This is a description';
        oppo.Goals__c = 'These are goals.';
        oppo.SOW_Hyperlink__c = 'www.google.com';
        oppo.Team_Retirement__c = 'Allyson Reagan';
        oppo.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        oppo.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        oppo.RFP_Proposal__c = 'Yes';
        //As of 12/28 this is required past 60%
        //oppo.DeliveryMethodology__c = 'Agile';
        
        update oppo;

        //Insert a Change Order
        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, acct.Id, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = oppo.Id;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        insert changeOrderOppty;
    }

    @isTest 
	static void test_updateRepliconDataTest() {   

        Opportunity testOppty = new Opportunity();
        testOppty = [SELECT Id, Name, Change_Order_Revenue__c, Change_Order_Hours__c, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c FROM Opportunity WHERE Name = 'ProjectHandlerTest Oppty'];

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
	static void populateProjectManager() {
        //Create User
        User testUser = new User();
        testUser = [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY CreatedDate DESC LIMIT 1];

        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, Project_Manager__c, Opportunity__c FROM Project__c WHERE Opportunity__r.Name = 'ProjectHandlerTest Oppty' LIMIT 1];

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

    
	
}