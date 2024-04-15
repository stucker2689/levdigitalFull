@isTest
private class CreateProjectTest {
	    
        @isTest 
        static void testCreateProjects() {

                // create account
                Account a = new Account();
                a.Name = 'Test Account';
                a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
                insert a;

                //Opportunity
                Opportunity oppo = TestDataFactory.createOpportunity(false, a.Id, 'Salesforce');
                oppo.Name = 'Test Project';
                oppo.CloseDate = system.today()+60;
                oppo.Amount = 55000.00;
                oppo.Project_Terms__c = 'Time and Materials';
                oppo.Payment_Terms__c = 'Invoice Net 45';
                oppo.StageName = 'Closed Won';
                oppo.Interested_In__c = 'Salesforce';
                oppo.SubPractice__c = 'Salesforce Core';
                oppo.Do_Not_Create_Project__c = false;
                oppo.Create_Project__c = TRUE;
                //oppo.Probability=75;
                insert oppo;


                //Now Project would have been created. Asserting the Name equals the Opp Name,
                Project__c proj = new Project__c();
                proj = TestClassUtil.getProjectforOpp(oppo.Id);
                System.assertEquals('Test Project', proj.Name);


                // Project Background objectives is updated only when the status is Closed Won, so asserting that this field is Null
                //System.assertEquals(NULL,proj.Project_Background_Objectives__c);

                //Setting Opp stage to Closed Won
                oppo.Key_Project_Success_Metrics__c = 'Test Key Project Success Metrics';
                oppo.Project_Background_Objectives__c = 'Test Project Background';
                oppo.Payment_Terms__c = 'Invoice Net 30';
                oppo.StageName = 'Closed Won';
                update oppo;

                proj = TestClassUtil.getProjectforOpp(oppo.Id);
                //System.assertEquals('Test Key Project Success Metrics',proj.Key_Project_Success_Metrics__c);

                //Setting Opp Stage to Closed Lost. Since the proj is created, setting the status value to Canceled - Opportunity Lost'
                oppo.StageName = 'Closed Lost';
                oppo.Lost_Reason_Description__c = 'Test Lost';
                oppo.Loss_Reason__c = 'Not a Lev Service Offering';
                oppo.Loss_Reason_Details__c = 'Staff Augmentation';
                update oppo;

                Opportunity testOpp = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Project' LIMIT 1];
                System.debug('TEST OPPTY Name : ' + testOpp.Name + ' STAGE: ' + testOpp.StageName);

                proj = TestClassUtil.getProjectforOpp(oppo.Id);
                //System.assertEquals('Terminated - Opportunity Lost',proj.Project_Status__c);
	}
        @isTest 
        static void testCreateProjects_no_closedOn() {

                // create account
                Account a = new Account();
                a.Name = 'Test Account';
                a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
                insert a;

                //Opportunity
                Opportunity oppo = TestDataFactory.createOpportunity(false, a.Id, 'Salesforce');
                oppo.Name = 'Test Project';
                oppo.CloseDate = system.today()+60;
                oppo.Amount = 55000.00;
                oppo.Project_Terms__c = 'Time and Materials';
                oppo.Payment_Terms__c = 'Invoice Net 45';
                oppo.StageName = 'Finalize Contracts';
                oppo.Interested_In__c = 'Salesforce';
                oppo.SubPractice__c = 'Salesforce Core';
                oppo.Create_Project__c = TRUE;
                oppo.Do_Not_Create_Project__c = false;
                oppo.Probability=90;
                insert oppo;


                //Now Project would have been created. Asserting the Name equals the Opp Name,
                Project__c proj = new Project__c();
                proj = TestClassUtil.getProjectforOpp(oppo.Id); System.debug('proj: '+proj);
                System.assertEquals('Test Project',proj.Name);


                // Project Background objectives is updated only when the status is Closed Won, so asserting that this field is Null
                //System.assertEquals(NULL,proj.Project_Background_Objectives__c);

                //Setting Opp stage to Closed Won
                oppo.Key_Project_Success_Metrics__c = 'Test Key Project Success Metrics';
                oppo.Project_Background_Objectives__c = 'Test Project Background';
                oppo.Payment_Terms__c = 'Invoice Net 30';
                oppo.StageName = 'Closed Won';
                update oppo;

                proj = TestClassUtil.getProjectforOpp(oppo.Id);
                //System.assertEquals('Test Key Project Success Metrics',proj.Key_Project_Success_Metrics__c);

                //Setting Opp Stage to Closed Lost. Since the proj is created, setting the status value to Canceled - Opportunity Lost'
                oppo.StageName = 'Closed Lost';
                oppo.Lost_Reason_Description__c = 'Test Lost';
                oppo.Loss_Reason__c = 'Not a Lev Service Offering';
                oppo.Loss_Reason_Details__c = 'Staff Augmentation';
                update oppo;

                proj = TestClassUtil.getProjectforOpp(oppo.Id);
                //System.assertEquals('Terminated- Opportunity Lost',proj.Project_Status__c);
        }

}