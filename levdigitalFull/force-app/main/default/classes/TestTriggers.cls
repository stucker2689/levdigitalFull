@isTest (SeeAllData=true)
private class TestTriggers {
	
	private static testMethod void testAccountWorkLogCustNo() {
		//get the max customer number - will be needed if msa is being set on any of these accounts
		/*AggregateResult[] maxCN  = [SELECT Max(Customer_Number__c) cn
	      	FROM Account
	      	WHERE Customer_Number__c != null];
	      	
	    Integer custNo;  	
		for (AggregateResult ar : maxCN)  
		{		   
		    custNo = Integer.valueOf(ar.get('cn'));	    
		}	
		if(custNo == null)
		{
			custNo = 4000;
		}
		else
		{
			custNo += 1;
		}*/
		Integer custNo = 4000;
		//get the rec type for Customer accounts
		Id rt = [Select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Client' limit 1].Id;
		
		Test.startTest();
        	List<Account> accList2 = [Select Id from Account];
        	if(accList2.size()==0)
                Delete accList2;
			Account a = new Account(Name='Test', RecordTypeId = rt, MSA_Number__c = '123A',Customer_Number__c=4000,Latest_Work_Log__c = 'test');
			insert a;	
			
			a.Latest_Work_Log__c = 'test123';
			update a;
		
			Account a1 = [Select Id, Customer_Number__c, Work_Logs__c from Account where id = :a.Id];
			System.AssertEquals(custNo, a1.Customer_Number__c);
			
		
		Test.stopTest();
		
	}
	
	private static testMethod void testContactWorkLog() {
		
		Test.startTest();
			Contact c = new Contact(LastName='Test', Latest_Work_Log__c = 'test');
			insert c;	
			
			c.Latest_Work_Log__c = 'test123';
			update c;
		
			Contact c1 = [Select Id, Work_Logs__c from Contact where id = :c.Id];
			System.assertNotEquals(null, c1.Work_Logs__c);
			
		
		Test.stopTest();
		
	}	
	
	private static testMethod void testLeadWorkLog() {
		
		Test.startTest();
			Lead l = new Lead(LastName='Test', Company='Test', Latest_Work_Log__c = 'test');
			insert l;	
			
			l.Latest_Work_Log__c = 'test123';
			update l;
		
			Lead l1 = [Select Id, Work_Logs__c from Lead where id = :l.Id];
			System.assertNotEquals(null, l1.Work_Logs__c);
			
		
		Test.stopTest();
		
	}
	
	/*private static testMethod void testOppWorkLog() {
		Id rt = [Select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Client' limit 1].Id;
				
		Account a = new Account(Name='Test', RecordTypeId = rt, MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		
		Test.startTest();
			Opportunity o = new Opportunity(Name='Test', AccountId=a.Id, Latest_Work_Log__c = 'test', Payment_Terms__c ='Special',CloseDate = System.today().addDays(10), StageName='Closed Won');
			insert o;	
			
			o.Latest_Work_Log__c = 'test123';
			update o;
		
			Opportunity o1 = [Select Id, Work_Logs__c from Opportunity where id = :o.Id];
			System.assertNotEquals(null, o1.Work_Logs__c);
						
		Test.stopTest();
		
	}

	private static testMethod void testDiscoverySession() {		
				
		Account a = new Account(Name='Test', MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		
		PricebookEntry pbe = [Select Id, Name from PricebookEntry where Name like '%Discovery Only%' limit 1];
		
		Test.startTest();
			Opportunity o = new Opportunity(Name='Test', AccountId=a.Id, Latest_Work_Log__c = 'test', Payment_Terms__c ='Special',CloseDate = System.today().addDays(10), StageName='Closed Won');
			insert o;				
		
			OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o.Id, PricebookEntryId = pbe.Id, Quantity=1, UnitPrice=20);
			insert oli;
			
			Opportunity o2 = [Select Id, Amount, Discovery_Session__c from Opportunity where id = :o.Id];
			System.assertEquals(true, o2.Discovery_Session__c);		
		
		Test.stopTest();
		
	}
	
	private static testMethod void testFirstYearBook() {
		Id rt = [Select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Client' limit 1].Id;
				
		Account a = new Account(Name='Test', RecordTypeId = rt, MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		
		PricebookEntry pbe = [Select Id, Name from PricebookEntry where Name like '%Discovery Only%' limit 1];
		
		Test.startTest();
			Opportunity o = new Opportunity(Name='Test', AccountId=a.Id, Latest_Work_Log__c = 'test', Payment_Terms__c ='Special',CloseDate = System.today().addDays(10), StageName='Closed Won');
			insert o;				
		
			OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o.Id, PricebookEntryId = pbe.Id, Quantity=1, UnitPrice=20);
			insert oli;

			Account a1 = [Select Id, First_Year_Booking__c from Account where Id = :a.Id];
			System.assertEquals(20, a1.First_Year_Booking__c);		
				
			delete o;
			Account a2 = [Select Id, First_Year_Booking__c from Account where Id = :a.Id];
			System.assertEquals(0, a2.First_Year_Booking__c);		
		Test.stopTest();
		
	}
	
	private static testMethod void testCO() {
		Id rt = [Select Id from RecordType where sObjectType = 'Opportunity' and DeveloperName = 'Change_Order' limit 1].Id;
				
		Account a = new Account(Name='Test', MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		
		PricebookEntry pbe = [Select Id, Name from PricebookEntry where IsActive = true limit 1];
		Opportunity o = new Opportunity(Name='Test 1', AccountId=a.Id, Latest_Work_Log__c = 'test', Payment_Terms__c ='Special',CloseDate = System.today().addDays(10), StageName='Closed Won');
		insert o;	
		Test.startTest();
			Opportunity o1 = new Opportunity(Name='Test 4', RecordTypeId = rt, Change_Orders__c = o.Id, AccountId=a.Id, Latest_Work_Log__c = 'test',Payment_Terms__c ='Special', CloseDate = System.today().addDays(10), StageName='Closed Won');
			insert o1;	
		
			OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o1.Id, PricebookEntryId = pbe.Id, Quantity=1, UnitPrice=20);
			insert oli;

			Opportunity a1 = [Select Id, Change_Order_Revenue__c from Opportunity where Id = :o.Id];
			//System.assertEquals(20, a1.Change_Order_Revenue__c);		
						
		Test.stopTest();
		
	}	*/
		
	private static testMethod void testInitialCampaign() {
		
		Campaign c = new Campaign(Name='Test');
		insert c;
		Lead l = new Lead(LastName='Test', Company='Test', Latest_Work_Log__c = 'test');
		insert l;
		Test.startTest();
	
			
			CampaignMember cm = new CampaignMember(LeadId = l.Id,CampaignId=c.Id,Status= 'Sent');
			insert cm;
		
			Lead l1 = [Select Id, Initial_Campaign__c from Lead where id = :l.Id];
			System.assertEquals(c.Id, l1.Initial_Campaign__c);
			
		
		Test.stopTest();
		
	}
	
	private static testMethod void testCaseComment() {
		
		User u = [Select Id from User where IsPortalEnabled = true limit 1];
		//Contact con = [Select Id, Account.Id from Contact where Id = :ssu.ContactId];
		System.runAs(u)
		{
			Case c = new Case(Subject='Test', Status = 'Waiting on Customer'); //, AccountId = con.Account.Id);
			insert c;
			
			CaseComment cc = new CaseComment(ParentId = c.Id, CommentBody = 'test');
			insert cc;
		}
		//Case c1 = [Select Id, Status from Case where id = :c.Id];
		//System.assertEquals(c.Status, 'In Process');		
		
	}		

	/*private static testMethod void testCaseInsert() {
		
		Account a = new Account(Name='Test', MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		Opportunity o = new Opportunity(Name='Test', AccountId=a.Id, Latest_Work_Log__c = 'test', Payment_Terms__c ='Special',CloseDate = System.today().addDays(10), StageName='Closed Won', Has_ASC_Product__c = true);
		insert o;	
		
		Test.startTest();
			
			Case c = new Case(Subject='Test', Status = 'Waiting on Customer', AccountId = a.Id);
			insert c;
			
			Case c1 = [Select Id, In_Force_Service_Contract__c from Case where id = :c.Id];
			System.assertEquals(o.Id, c1.In_Force_Service_Contract__c);
						
		Test.stopTest();
		
	}
		
	private static testMethod void testOppAgree() {
		
		Account a = new Account(Name='Test', MSA_Number__c = '123A', Latest_Work_Log__c = 'test');
		insert a;
		Opportunity o = new Opportunity(Name='Test', AccountId=a.Id, Latest_Work_Log__c = 'test',Payment_Terms__c ='Special', CloseDate = System.today().addDays(10), StageName='Closed Won');
		insert o;	
		
		Test.startTest();
			
			echosign_dev1__SIGN_Agreement__c a1 = new echosign_dev1__SIGN_Agreement__c(echosign_dev1__Opportunity__c = o.Id, echosign_dev1__Status__c = 'Signed',Agreement_Type__c = 'Statement Of Work');
			insert a1;
			
			Opportunity o1 = [Select Id, Date_SOW_Signed__c from Opportunity where id = :o.Id];
			System.assertEquals(system.today(), o1.Date_SOW_Signed__c);
						
		Test.stopTest();
		
	}	*/			
}