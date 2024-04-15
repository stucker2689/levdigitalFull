@isTest
private class CaseTrgHandlerTest
{
	static testmethod void addCaseTest()
	{

		Account a = createAccount();
		Opportunity op = createOpportunity(a.Id);
		Project__c pr = createProject(op.Id, a.Id);

		Test.StartTest();
			List<Case> casesList = createCases(pr.Id);

			Project__c projects = [SELECT Id, TotalNumberofCases__c, TotalCasesOpen__c, TotalsCasesClosed__c, Total_Actual_Hours__c, TotalEstimatedHours__c FROM Project__c WHERE Id = :pr.Id];
			System.assertEquals(projects.TotalNumberofCases__c, 20);
			System.assertEquals(projects.TotalCasesOpen__c, 15);
			System.assertEquals(projects.TotalsCasesClosed__c, 5);
			System.assertEquals(projects.TotalEstimatedHours__c, 500);
		Test.StopTest();
	}

	static testmethod void deleteCaseTest()
	{
		Account a = createAccount();
		Opportunity op = createOpportunity(a.Id);
		Project__c pr = createProject(op.Id, a.Id);
		List<Case> casesList = createCases(pr.Id);

		Test.StartTest();
			delete casesList.get(0);

			Project__c projects = [SELECT Id, TotalNumberofCases__c, TotalCasesOpen__c, TotalsCasesClosed__c, Total_Actual_Hours__c, TotalEstimatedHours__c FROM Project__c WHERE Id = :pr.Id];
			System.assertEquals(projects.TotalNumberofCases__c, 19);
			System.assertEquals(projects.TotalCasesOpen__c, 14);
			System.assertEquals(projects.TotalsCasesClosed__c, 5);
			System.assertEquals(projects.TotalEstimatedHours__c, 500);
		Test.StopTest();
	}

	//static testmethod void nullProjectTest() {
	//	Account portalAccount = new Account(Name='Test Co.');
	//	insert portalAccount;

	//	Contact contact = new Contact();
	//	contact.LastName = 'Test';
	//	contact.AccountId = portalAccount.Id;
	//	insert contact;

	//	Profile p = [SELECT Id FROM Profile WHERE Name='LEV - Customer Portal Manager' LIMIT 1];
	//	User u = new User(Alias='portusr', Email='portusertest@levementum.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=p.Id, TimeZoneSidKey='America/Phoenix', UserName='portusertest@levementum.com', ContactId=contact.Id);
	//	insert u;

	//	//User u = [SELECT Id FROM User WHERE IsPortalEnabled=true LIMIT 1];

	//	Account a = createAccount();
	//	Opportunity op = createOpportunity(a.Id);

	//	OpportunityShare os = new OpportunityShare();
	//	os.OpportunityAccessLevel = 'Edit';
	//	os.OpportunityId = op.Id;
	//	os.UserOrGroupId = u.Id;
	//	insert os;

	//	Project__c pr = createProject(op.Id, a.Id);
	//	system.debug('fail PROJECT ID: ' + pr.Id);

	//	system.runAs(u) {


	//		Case c = new Case();
	//		c.OwnerId = u.Id;
	//		c.Project__c = pr.Id;
	//		c.Status = 'New';
	//		c.Estimated_Hours__c = 100;
	//		c.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Case' AND Name='Levementum Standard Case'].Id;
	//		insert c;

	//		c.Status = 'Waiting on Customer';
	//		update c;

	//		system.assertEquals('Waiting on Customer', [SELECT Status FROM Case WHERE Id=:c.Id].Status);

	//		CaseComment comment = new CaseComment();
	//		comment.ParentId = c.Id;
	//		comment.CommentBody = 'Test comment';

	//		Test.startTest();
	//		try {
	//			insert comment;
	//			//system.assert(false, 'This should never be reached.'); // this should never be reached
	//		} catch(Exception e) {
	//			system.debug(e);
	//			system.assertEquals('NullPointerException', e.getTypeName());
	//		} finally {
	//			system.assertEquals('In Process', [SELECT Status FROM Case WHERE Id=:c.Id].Status);
	//		}

	//		Test.stopTest();

	//		CaseComment[] comments = [SELECT Id FROM CaseComment];
	//		system.assertEquals(0, comments.size());
	//	}

	//}

	private static Account createAccount() {
    Account a = new Account();
		a.Name = 'TestAccount';
		a.PrimaryPractice__c = 'Salesforce';

		insert a;
		return a;
	}

	private static Opportunity createOpportunity(Id acc) {
    	Opportunity op = new Opportunity();
		op.Name = 'TestAccount';
		op.AccountId = acc;
		op.Interested_In__c = 'Salesforce';
		//op.StageName = 'Closed Won';
		op.StageName = 'Identifying an Opportunity';
		op.CloseDate = date.today();
		op.Start_Date__c = date.today();
		op.End_Date__c = date.today();
		op.Amount = 55000.00;
        op.Service__c = 'Program';
        op.Project_Type__c = 'Salesforce.com';
        op.Program_Type__c = 'Strategic';
        op.Number_of_Contact_Rolls_Added__c = 2;
        op.Project_Terms__c = 'Time and Materials';
        op.LevementumVertical__c = 'Manufacturing';
        op.Payment_Schedule__c = 'Standard TM';
        op.Signatures_Completed__c = true;
        op.Opportunity_Accuracy_Validated__c = true;
        op.Lead_Source__c = 'Levementum';
        op.Project_Health__c = 'Green';
        op.Create_Project__c = FALSE;
        op.Payment_Terms__c = 'Invoice Net 30';
        op.ExpectedPro_DurationinWeeks__c = 3;
        op.Opp_Amount_Distribution__c = '70% / 30%';
        op.Team_Retirement__c = 'Allyson Reagan';
        op.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        op.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        op.RFP_Proposal__c = 'Yes';
        op.DeliveryMethodology__c = 'Agile';

		insert op;
		return op;
	}

	private static Project__c createProject(Id op, Id acc) {

		Project__c pr = new Project__c();
		pr.name = 'Test project';
		pr.Account__c = acc;
		pr.Opportunity__c = op;

		insert pr;
		return pr;
	}

	private static List<Case> createCases(Id proj) {

		List<Case> casesList = new List<Case>();
		for(Integer i = 1; i <= 20; i++){

			Case c = new Case();
			c.Project__c = proj;

			if(i <= 10){

				c.Status = 'New';
			}
			else if(i > 10 && i <= 15){
				c.Status = 'Completed';
			}
			else{
				c.Estimated_Hours__c = 100;
			}

			casesList.add(c);
		}

		insert casesList;
		return casesList;
	}
}