/**
 * Created by jmahapatra on 11/15/17.
 */
@isTest
private class OpportunityTriggerHandler_Test {
    /** TEST DATA */
    /*private static Account acct1;
    private static Account acct2;
    private static Opportunity opp1;
    private static Opportunity opp2;
    private static Opportunity opp4;
    private static List<Opportunity> oppsList;
    private static List<OpportunityLineItem> oliList;*/
    private static Id oppProdId;

    /** TEST DATA INITIALIZATION */
    private static void init(Boolean needsLineItems) {
		/*
        // Accounts
        acct1 = TestDataFactory.createAccount(true, 'Client');
        acct2 = TestDataFactory.createAccount(true, 'Client');

        // Opportunities for Account 1
        opp1 = TestDataFactory.createOpportunity(false, acct1.Id, 'Salesforce');
        opp1.Name = 'Test Opp 1111';
        opp1.Change_Order_Revenue__c = 1000;
        opp1.Total_Amount_Invoiced_to_Date__c = 100;

        opp2 = TestDataFactory.createOpportunity(false, acct1.Id, 'Salesforce');
        opp2.Name = 'Test Opp 2222';
        opp2.Change_Order_Revenue__c = 1000;
        opp2.Total_Amount_Invoiced_to_Date__c = 500;

        // Opportunities for Account 2
        Opportunity opp3 = TestDataFactory.createOpportunity(false, acct2.Id, 'Salesforce');
        opp3.Name = 'Test Opp 3333';
        opp3.Change_Order_Revenue__c = 1000;
        opp3.Total_Amount_Invoiced_to_Date__c = 100;

        opp4 = TestDataFactory.createOpportunity(false, acct2.Id, 'Salesforce');
        opp4.Name = 'Test Opp 4444';
        opp4.Change_Order_Revenue__c = 1000;
        opp4.Total_Amount_Invoiced_to_Date__c = 600;

        oppsList = new List<Opportunity>{ opp1, opp2, opp3, opp4 };
        
        // Opportunity Products
		if (needsLineItems) {
            insert oppsList;
            
            Product2 prod = TestDataFactory.createProduct(true);
            PricebookEntry pbe = TestDataFactory.createPricebookEntry(true, prod.Id);
			
			oliList = new List<OpportunityLineItem>();
			for (Integer i = 0; i < 5; i++) {
				oliList.add(TestDataFactory.createOpportunityLineItem(false, opp1.Id, pbe.Id));
				oliList.add(TestDataFactory.createOpportunityLineItem(false, opp2.Id, pbe.Id));
			}
		}*/
    }

    @TestSetup
    static void testSetupData(){
        Account acct1 = TestDataFactory.createAccount(false, 'Client');
        acct1.Name = 'Test Client Account 1';
        Account acct2 = TestDataFactory.createAccount(false, 'Client');
        acct2.Name = 'Test Client Account 2';

        List<Account> accountsList = new List<Account>{acct1, acct2};
        insert accountsList;

        // Opportunities for Account 1
        Opportunity opp1 = TestDataFactory.createOpportunity(false, acct1.Id, 'Salesforce');
        opp1.Name = 'Test Opp 1111';
        opp1.Change_Order_Revenue__c = 1000;        
        //opp1.SOW_Number__C = 'SOW-2019-43891';
        opp1.Total_Amount_Invoiced_to_Date__c = 100;

        Opportunity opp2 = TestDataFactory.createOpportunity(false, acct1.Id, 'Salesforce');
        opp2.Name = 'Test Opp 2222';
        opp2.Change_Order_Revenue__c = 1000;
        opp2.Total_Amount_Invoiced_to_Date__c = 500;

        // Opportunities for Account 2
        Opportunity opp3 = TestDataFactory.createOpportunity(false, acct2.Id, 'Salesforce');
        opp3.Name = 'Test Opp 3333';
        opp3.Change_Order_Revenue__c = 1000;
        opp3.Total_Amount_Invoiced_to_Date__c = 100;

        Opportunity opp4 = TestDataFactory.createOpportunity(false, acct2.Id, 'Salesforce');
        opp4.Name = 'Test Opp 4444';
        opp4.Change_Order_Revenue__c = 1000;
        opp4.Total_Amount_Invoiced_to_Date__c = 600;

        List<Opportunity> oppsList = new List<Opportunity>{ opp1, opp2, opp3, opp4 };

        insert oppsList;
        
        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(true, prod.Id);
        oppProdId = pbe.Id;
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 5; i++) {
            oliList.add(TestDataFactory.createOpportunityLineItem(false, opp1.Id, pbe.Id));
            oliList.add(TestDataFactory.createOpportunityLineItem(false, opp2.Id, pbe.Id));
        }
        
        insert oliList;
    }

    /*@isTest
    static void testInit() {
        init(true);
    }*/
    
    /** TEST METHODS */
    @isTest 
	static void updateAccountLowestProjectBudgetRemaining_singleAccountUpsertTest() {
        //init(true);
    
        // Test
        System.Test.startTest();
        //insert opptyLineItemList;
        System.Test.stopTest();

        // Posttest
        Decimal accountBudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 1'].Lowest_Project_Budget_Remaining_Percent__c;
        Opportunity updatedOpp = [SELECT Id, Percent_Of_Budget_Remaining__c FROM Opportunity WHERE Name = 'Test Opp 1111'];

        // Asserts
        System.assertEquals(66.67, accountBudgetRemaining, 'Account Budget Remaining Calculated Incorrectly');
        System.assertEquals(66.67, Math.min(accountBudgetRemaining, updatedOpp.Percent_Of_Budget_Remaining__c), 'Lowest Percentage of Account Budget Remaining not calculated Correctly');
    }
    
    @isTest 
	static void updateAccountLowestProjectBudgetRemaining_singleAccountUpdateTest() {
        //init(true);

        Opportunity testOpp = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c FROM Opportunity WHERE Name = 'Test Opp 2222' LIMIT 1];

        testOpp.Total_Amount_Invoiced_to_Date__c = 600;

        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();

        // Posttest
        Decimal accountBudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 1'].Lowest_Project_Budget_Remaining_Percent__c;
        
        // Asserts
        System.assertEquals(60.00, accountBudgetRemaining, 'Lowest Project BUdget Remaining Percentage not updated correctly');
    }

    @isTest 
	static void updateAccountLowestProjectBudgetRemaining_multiAccountupsertTest() {
        //init(false);
        
        // Test
        System.Test.startTest();
        //insert oppsList;
        System.Test.stopTest();

        // Posttest
        Decimal account1BudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 1'].Lowest_Project_Budget_Remaining_Percent__c;
        Decimal account2BudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 2'].Lowest_Project_Budget_Remaining_Percent__c;
        
        // Asserts
        System.assertEquals(66.67, account1BudgetRemaining, 'Account 1 Budget Remaining Calculated incorrectly from multi Account Upsert');
        System.assertEquals(90.00, account2BudgetRemaining, 'Account 2 Budget Remaining Calculated incorrectly from multi Account Upsert');
    }

    @isTest 
	static void updateAccountLowestProjectBudgetRemaining_multiAccountUpdateTest() {
        //init(true);

        List<Opportunity> testOppList = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c FROM Opportunity WHERE Name IN ('Test Opp 2222', 'Test Opp 4444')];


        List<Opportunity> updateOpptyList = new List<Opportunity>();
        for(Opportunity opp : testOppList){
            if(opp.Name == 'Test Opp 2222'){
                opp.Total_Amount_Invoiced_to_Date__c = 700;
                updateOpptyList.add(opp);
            }else if(opp.Name == 'Test Opp 4444'){
                opp.Total_Amount_Invoiced_to_Date__c = 800;
                updateOpptyList.add(opp);
            }
        }

        // Test
        System.Test.startTest();
        update updateOpptyList;
        System.Test.stopTest();

        // Posttest
        Decimal account1BudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 1'].Lowest_Project_Budget_Remaining_Percent__c;
        Decimal account2BudgetRemaining = [SELECT Lowest_Project_Budget_Remaining_Percent__c FROM Account WHERE Name = 'Test Client Account 2'].Lowest_Project_Budget_Remaining_Percent__c;
        
        // Asserts
        System.assertEquals(53.33, account1BudgetRemaining, 'Account 1 Lowest Project Budget Remaining Percent not calculated properly from multi Account Update');
        System.assertEquals(20.00, account2BudgetRemaining, 'Account 2 Lowest Project Budget Remaining Percent not calculated properly from multi Account Update');
    }
    
    @isTest 
	static void pushCountTest_oneMonthTest() {
        //init(false);
		
        Opportunity testOpp = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];

        testOpp.PushCount__c = null;

        // Test
        System.Test.startTest();
        testOpp.CloseDate = testOpp.CloseDate.addMonths(1);
        update testOpp;
        System.Test.stopTest();

        // Posttest
        Opportunity updatedOpp = [SELECT PushCount__c FROM Opportunity WHERE Id = :testOpp.Id];
        
        // Assert
        System.assertEquals(1, updatedOpp.PushCount__c, 'Opportunity Push Count not properly updated');
    }

    @isTest 
	static void pushCountTest_noChangeTest() {
        //init(false);

        Opportunity testOpp = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
		
        testOpp.CloseDate = Date.newInstance(2015, 12, 11);
        testOpp.PushCount__c = 1;
        update testOpp;

        testOpp.CloseDate = Date.newInstance(2015, 12, 31);

        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();

        // Posttest
        Opportunity updatedOpp = [SELECT PushCount__c FROM Opportunity WHERE Id = :testOpp.Id];

        // Assert
        System.assertEquals(1, updatedOpp.PushCount__c, 'Push Count Not correctly calculated');
    }

    @isTest 
	static void pushCountTest_nextYearTest() {
        //init(false);
		Opportunity testOpp = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.CloseDate = Date.newInstance(2015, 12, 11);
        testOpp.PushCount__c = 1;
        update testOpp;

        // make it next year, but an earlier month, pushcount+1
        testOpp.CloseDate = Date.newInstance(2016, 1, 1);
        
        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();

        // Posttest
        Opportunity updatedOpp = [SELECT PushCount__c FROM Opportunity WHERE Id=:testOpp.Id];

        // Assert
        System.assertEquals(2, updatedOpp.PushCount__c);
    }

    @isTest 
	static void pushCountTest_bulkTest() {
        //init(true);
        List<Opportunity> testOppList = [SELECT Id, Name, Total_Amount_Invoiced_to_Date__c, CloseDate FROM Opportunity WHERE Name IN ('Test Opp 1111', 'Test Opp 2222', 'Test Opp 3333', 'Test Opp 4444')];

        List<Opportunity> testUpdateOppList = new List<Opportunity>();
        for (Opportunity opp : testOppList) {
            opp.CloseDate = opp.CloseDate.addMonths(1);
            testUpdateOppList.add(opp);
        }

        // Test
        System.Test.startTest();
            update testUpdateOppList;
        System.Test.stopTest();

        // Posttest
        Opportunity[] updatedOpps = [SELECT PushCount__c FROM Opportunity];
        
        // Asserts
        System.assertEquals(4, updatedOpps.size());

        for(Opportunity updatedOpp : updatedOpps) {
            System.assertEquals(1, updatedOpp.PushCount__c, 'Push Count Was Not Properly set from Bulk Updates');
        }
    }

    @isTest 
	static void updateAccountFirstYearBooking_upsertTest() {
        //init(false);

        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
		
        testOpp.Amount = 200;
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';

        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();
		
		// Posttest 
		Account updatedAccount = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
		
		// Assert
        System.assertEquals(500, updatedAccount.First_Year_Booking__c);
    }

    @isTest static void updateAccountFirstYearBooking_updateAmountTest() {
		//init(false);
        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';
        testOpp.CloseDate = testOpp.CloseDate.addDays(10);
		update testOpp;
		
		testOpp.Amount = 500;

        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();
		
		// Posttest 
		Account updatedAccount = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
		
		// Assert
        System.assertEquals(500, updatedAccount.First_Year_Booking__c);
    }

    @isTest static void updateAccountFirstYearBooking_updateStageToWonTest() {
        //init(false);
        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
		testOpp.Payment_Terms__c = 'Time and Materials';
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';
        testOpp.Amount = 500;
        testOpp.CloseDate = testOpp.CloseDate.addDays(10);

        // Test
        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();
		
		// Posttest 
		Account updatedAccount = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
		
		// Assert
        System.assertEquals(500, updatedAccount.First_Year_Booking__c);
    }

    @isTest static void updateAccountFirstYearBooking_updateStageToNotWonTest() {
        System.debug('///////////////////////////*******************/////////////////// updateAccountFirstYearBooking_updateStageToNotWonTest START ///////////////////////////*******************///////////////////');
        //init(false);
        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c, Lost_Reason_Description__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';
        testOpp.CloseDate = testOpp.CloseDate.addDays(10);
        testOpp.Amount = 500;
		update testOpp;
		
		testOpp.StageName = 'Closed Lost';
        testOpp.Lost_Reason_Description__c = 'Poor Test Classes';
        testOpp.Loss_Reason__c = 'Timing';
        testOpp.Loss_Reason_Details__c = 'Budget';

        // Test
        Test.startTest();
        update testOpp;
        Test.stopTest();
		
		// Posttest 
		Account updatedAccount1 = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
		
		// Assert
        System.assertEquals(0, updatedAccount1.First_Year_Booking__c, 'The Related Account did not properly have its First Year Booking field properly reset to zero after the opportunity was moved from CW to Closed Lost');

        System.debug('///////////////////////////*******************/////////////////// updateAccountFirstYearBooking_updateStageToNotWonTest END ///////////////////////////*******************///////////////////');
    }

    @isTest static void updateAccountFirstYearBooking_updateCloseDateTest() {
        //init(false);
        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';
        testOpp.CloseDate = testOpp.CloseDate.addDays(10);
        testOpp.Amount = 500;
        update testOpp;

        // Test
        Test.startTest();
        testOpp.CloseDate = testOpp.CloseDate.addYears(2);
        update testOpp;
        Account updatedAccount = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
        System.assertEquals(0, updatedAccount.First_Year_Booking__c);
        testOpp.CloseDate = Date.today().addMonths(6);
        update testOpp;
        Test.stopTest();

        // Assert
        updatedAccount = [SELECT First_Year_Booking__c FROM Account WHERE Id = :testOpp.AccountId];
        //System.assertEquals(500.00, updatedAccount.First_Year_Booking__c);
    }

    @isTest static void updateAccountFirstYearBooking_deleteTest() {
        //init(false);
        Opportunity testOpp = [SELECT Id, Name, StageName, Amount, Total_Amount_Invoiced_to_Date__c, PushCount__c, CloseDate, AccountId, Number_of_Contact_Rolls_Added__c FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.Number_of_Contact_Rolls_Added__c = 2;
        testOpp.StageName = 'Closed Won';
        testOpp.CloseDate = testOpp.CloseDate.addDays(10);
        testOpp.Amount = 500;
		update testOpp;

        // Test
        System.Test.startTest();
        delete testOpp;
        System.Test.stopTest();
		
		// Posttest 
		Account updatedAccount1 = [SELECT First_Year_Booking__c FROM Account WHERE Id =:testOpp.AccountId];
		
		// Assert
        System.assertEquals(0, updatedAccount1.First_Year_Booking__c);
    }

    @isTest static void opportunityAfter_coverage() {
        //init(false);
        Account testAcct = [SELECT Id FROM Account WHERE Name = 'Test Client Account 1'];

        Opportunity parentOpp = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        parentOpp.Name = 'Test Parent Oppty';
        insert parentOpp;
        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
        changeOrderOppty.Number_of_Contact_Rolls_Added__c = 2;
        changeOrderOppty.Change_Orders__c = parentOpp.Id;
        changeOrderOppty.StageName = 'Closed Won';
        changeOrderOppty.Create_Project__c = true;
        changeOrderOppty.Do_Not_Create_Project__c = false;

        // Test
        System.Test.startTest();

        // Coverage for insert create task
        insert changeOrderOppty;

        // Coverage for update recalc and create task 
        changeOrderOppty.Amount = 250;
        update changeOrderOppty;

        // Coverage for update with new parent opportunity
        //opp2.Change_Orders__c = newParentOpp.Id;

        // Coverage for isDelete trigger recalc
        delete changeOrderOppty;

        System.Test.stopTest();
    }
    
    /*@isTest static void cloneOppsWithProductsTest() {
        Account a = getAccount();
        upsert a;

        Opportunity o = getOpportunity(a.Id);
        o.Multi_Year_Term__c = '12 Months';
        o.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND RecordType.Name LIKE 'Sugar License%' LIMIT 1].Id;
        upsert o;

        Test.startTest();

        o.Deployment_Location__c = 'On-Site';
        o.StageName = 'Closed Won';
        update o;

        Test.stopTest();

        Opportunity[] opps = [SELECT Id FROM Opportunity WHERE AccountId=:a.Id];
        system.assertEquals(2, opps.size());

        Opportunity clonedOpp = [SELECT Id, StageName, Name, Opportunity_Unique_Name__c, SOW_Number__c, Unique_SOW_Number__c, Effective_Date__c, Expiration_Date__c, CloseDate FROM Opportunity WHERE StageName='Identifying an Opportunity'];
        system.assertNotEquals(o.Id, clonedOpp.Id);
        system.assertEquals('Identifying an Opportunity', clonedOpp.StageName);
        system.assert(clonedOpp.Name.contains('Future'), 'The cloned opportunity should contain the future naming convention');
        system.assert(clonedOpp.Opportunity_Unique_Name__c.contains('Future'), 'The cloned opportunity should contain the future naming convention');
        system.assertEquals(null, clonedOpp.SOW_Number__c);
        system.assertEquals(null, clonedOpp.Unique_SOW_Number__c);
        system.assertEquals(system.today().addMonths(12), clonedOpp.Effective_Date__c);
        system.assertEquals(system.today().addMonths(12), clonedOpp.Expiration_Date__c);
        system.assertEquals(system.today().addMonths(12), clonedOpp.CloseDate);
    }*/

    @isTest 
    static void opportunityExpectedDurationinWeeksPlusCOsTest_BeforeCO() {
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.ExpectedPro_DurationinWeeks__c = 5;

        System.Test.startTest();
        update testOpp;
        System.Test.stopTest();

        Opportunity testOppResult1 = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c  FROM Opportunity WHERE Id =: testOpp.Id];
        System.assertEquals(5, testOppResult1.Total_Expected_Proj_Duration_Weeks__c, 'Total Expected Proj Duration Plus CO Not Calculating correctly before CO is created');
    }

    @isTest 
    static void opportunityExpectedDurationinWeeksPlusCOsTest_InsertCO() {
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.ExpectedPro_DurationinWeeks__c = 5;
        update testOpp;

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOpp.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = testOpp.Id;
        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 10;
        changeOrderOppty.StageName = 'Identifying an Opportunity';

        System.Test.startTest();
        insert changeOrderOppty;
        System.Test.stopTest();

        Opportunity testOppResult1 = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Id =: testOpp.Id];
        System.assertEquals(15, testOppResult1.Total_Expected_Proj_Duration_Weeks__c, 'Total Expected Proj Duration Plus CO Not Calculating correctly after CO is created');

    }

    @isTest 
    static void opportunityExpectedDurationinWeeksPlusCOsTest_UpdateCO() {
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.ExpectedPro_DurationinWeeks__c = 5;
        update testOpp;

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOpp.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = testOpp.Id;
        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 10;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        System.Test.startTest();
        insert changeOrderOppty;

        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 5;

        
        update changeOrderOppty;
        System.Test.stopTest();

        Opportunity testOppResult1 = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c  FROM Opportunity WHERE Id =: testOpp.Id];
        System.assertEquals(10, testOppResult1.Total_Expected_Proj_Duration_Weeks__c, 'Total Expected Proj Duration Plus CO Not Calculating correctly when CO is Updated');

    }

    @isTest 
    static void opportunityExpectedDurationinWeeksPlusCOsTest_DeleteCO() {
       
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];
        testOpp.ExpectedPro_DurationinWeeks__c = 5;
        update testOpp;

        
        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOpp.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = testOpp.Id;
        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 10;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        System.Test.startTest();
        insert changeOrderOppty;

        
        delete changeOrderOppty;
        System.Test.stopTest();

        Opportunity testOppResult1 = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c  FROM Opportunity WHERE Id =: testOpp.Id];
        System.assertEquals(5, testOppResult1.Total_Expected_Proj_Duration_Weeks__c, 'Total Expected Proj Duration Plus CO Not Calculating correctly when CO is Deleted');

    }

    @isTest
    static void updateCOToClosedWonTest(){
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOpp.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = testOpp.Id;
        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 10;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        insert changeOrderOppty;
        
        System.Test.startTest();
        changeOrderOppty.Number_of_Contact_Rolls_Added__c = 2;
        changeOrderOppty.StageName = 'Closed Won';
        update changeOrderOppty;

        Product2 prod = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(true, prod.Id);

        TestDataFactory.createOpportunityLineItem(true, changeOrderOppty.Id, pbe.Id);
        System.Test.stopTest();

    }
    
    @isTest
    static void deleteChangeOrder_Test(){
        Opportunity testOpp = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c,Total_Expected_Proj_Duration_Weeks__c, Expected_Duration_in_Weeks_of_COs__c, AccountId  FROM Opportunity WHERE Name = 'Test Opp 1111' LIMIT 1];

        Opportunity changeOrderOppty = TestDataFactory.createOpportunity(false, testOpp.AccountId, 'Change Order');
        changeOrderOppty.Name = 'Change order Opp 1';
        changeOrderOppty.Change_Orders__c = testOpp.Id;
        changeOrderOppty.ExpectedPro_DurationinWeeks__c = 10;
        changeOrderOppty.StageName = 'Identifying an Opportunity';
        insert changeOrderOppty;
        
        Test.startTest();
        changeOrderOppty.Number_of_Contact_Rolls_Added__c = 2;
        changeOrderOppty.StageName = 'Closed Won';
        update changeOrderOppty;
        
        delete changeOrderOppty;
        Test.stopTest();
    }
}