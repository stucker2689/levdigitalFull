@isTest
private class StatusReportTriggerHandlerTest {
	
	@isTest static void testStatusReportInsert() {
	
        //Create Acc
        Account acc = new Account();
        acc = TestClassUtil.newSampleAccount();
        
        //Create Opp
        Opportunity oppo = new Opportunity();
        //oppo = TestClassUtil.newSampleOpportunity(acc.Id, 'Test');
        oppo = TestDataFactory.createOpportunity(true, acc.Id, 'Salesforce');
       
        //Setting Opp stage to Closed Won
        oppo.Number_of_Contact_Rolls_Added__c = 2;
        oppo.Key_Project_Success_Metrics__c = 'Test Key Project Success Metrics';
        oppo.Project_Background_Objectives__c = 'Test Project Background';
        oppo.StageName = 'Closed Won';
        update oppo;

        Project__c proj = new Project__c();
        proj = TestClassUtil.createProject(true, acc.Id, oppo.Id);

        //Create new Status Report: 
        Status_Report__c strep = new Status_Report__c();
        strep.Name = 'Test Status Rep Name';
        strep.Account__c = acc.Id;
        strep.Opportunity__c = oppo.Id;
        strep.Project__c = proj.Id;
        strep.Reporting_Period_From__c = Date.today().addDays(-14);
        strep.Reporting_Period_Ending__c = Date.today().addDays(-7);
        strep.Executive_Summary__c = 'Test Exec Summary';
        strep.Key_Accomplishments_This_Period__c = 'Test Accomplishments';
        strep.Key_Decisions__c = 'Test Key Decisions';
        strep.Plans_for_Next_Period__c = 'Test Plans for Next Period';
        strep.Overall_Health_Value__c = 'Green';
        strep.Budget_Value__c= 'Green';
        strep.Risk_Value__c= 'Green';
        strep.Schedule_Value__c= 'Green';
        strep.Scope_Value__c= 'Green';
        strep.Overall_Health_Comments__c = 'Green';
        strep.Budget_Comments__c= 'Green';
        strep.Risk_Comments__c= 'Green';
        strep.Schedule_Comments__c= 'Green';
        strep.Scope_Comments__c= 'Green';
        insert strep;

        proj = TestClassUtil.getProjectforOpp(oppo.Id);
		//System.assertEquals('Green',proj.SR_Overall_Health_Value__c);
		//System.assertEquals('Test Key Decisions',proj.SR_Key_Decisions__c);

		//Insert a recent Status Report 
		Status_Report__c strep2 = new Status_Report__c();
        strep2.Name = 'Test Status Rep Name 2';
        strep2.Account__c = acc.Id;
        strep2.Opportunity__c = oppo.Id;
        strep2.Project__c = proj.Id;
        strep2.Reporting_Period_From__c = Date.today().addDays(-7);
        strep2.Reporting_Period_Ending__c = Date.today().addDays(-3);
        strep2.Executive_Summary__c = 'Test Exec Summary 2';
        strep2.Key_Accomplishments_This_Period__c = 'Test Accomplishments 2';
        strep2.Key_Decisions__c = 'Test Key Decisions 2';
        strep2.Plans_for_Next_Period__c = 'Test Plans for Next Period 2';
        strep2.Overall_Health_Value__c = 'Yellow';
        strep2.Budget_Value__c= 'Yellow';
        strep2.Risk_Value__c= 'Yellow';
        strep2.Schedule_Value__c= 'Yellow';
        strep2.Scope_Value__c= 'Yellow';
        strep2.Overall_Health_Comments__c = 'Yellow';
        strep2.Budget_Comments__c= 'Yellow';
        strep2.Risk_Comments__c= 'Yellow';
        strep2.Schedule_Comments__c= 'Yellow';
        strep2.Scope_Comments__c= 'Yellow';

        insert strep2;

        proj = TestClassUtil.getProjectforOpp(oppo.Id);
		//System.assertEquals('Yellow',proj.SR_Overall_Health_Value__c);
		//System.assertNotEquals('Test Key Decisions',proj.SR_Key_Decisions__c);

        List<Status_Report__c> srList = new List<Status_Report__c>();
		//Now, update first status report date to make it the current status report 
		strep.Reporting_Period_Ending__c = Date.today().addDays(-2);
        strep2.Reporting_Period_Ending__c = Date.today().addDays(-7);
		srList.add(strep);
        srList.add(strep2);
        update srList;
        //update strep;

		//proj = TestClassUtil.getProjectforOpp(oppo.Id);
		//System.assertEquals('Green',proj.SR_Overall_Health_Value__c);

		//Now, update the first status report date to push it back, so the strep2 will become the current status report.
		//strep.Reporting_Period_Ending__c = Date.today().addDays(-7);
		//update strep;

		/*proj = TestClassUtil.getProjectforOpp(oppo.Id);
		System.assertEquals('Yellow',proj.SR_Overall_Health_Value__c);*/

        delete strep;
    
      
	}
	
	
}