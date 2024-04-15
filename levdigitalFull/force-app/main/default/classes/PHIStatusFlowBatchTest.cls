/**
 * Create by Sam Tucker 2/28/2022
 * Test Class for PhiStatusFlowBatchScheduler, PHIStatusFlowBatch
 */
@isTest
private class PHIStatusFlowBatchTest {

    @testSetup
    static void setupData() {
        Account phiTestAcct = TestDataFactory.createAccount(true, 'Client');

        Opportunity phiTestOppty = TestDataFactory.createOpportunity(false, phiTestAcct.Id, 'Salesforce');
        phiTestOppty.Name = 'PHI Status Flow Oppty';
        phiTestOppty.StageName = 'Closed Won';
        phiTestOppty.Amount = 10000;
        insert phiTestOppty;

        Product2 testProduct = TestDataFactory.createProduct(true);
        PricebookEntry testPriceBookEntry = TestDataFactory.createPricebookEntry(true, testProduct.Id);
        OpportunityLineItem testOli = TestDataFactory.createOpportunityLineItem(false, phiTestOppty.Id, testPriceBookEntry.Id);
        testOli.Resource_Delivery_Group__c = 'Lev-Onshore';
        insert testOli;

        List<Project__c> projList = new List<Project__c>();
        Project__c phiTestProj1 = new Project__c();
        phiTestProj1.Account__c = phiTestAcct.Id;
        phiTestProj1.Opportunity__c = phiTestOppty.Id;
        phiTestProj1.Name = 'PHI Status Flow Proj 1';
        phiTestProj1.Project_Status__c = 'Active';
        phiTestProj1.Planned_Close_Date__c = Date.today().addDays(14);
        projList.add(phiTestProj1);

        Project__c phiTestProj2 = new Project__c();
        phiTestProj2.Account__c = phiTestAcct.Id;
        phiTestProj2.Opportunity__c = phiTestOppty.Id;
        phiTestProj2.Name = 'PHI Status Flow Proj 2';
        phiTestProj2.Project_Status__c = 'Not Started';
        phiTestProj2.Planned_Close_Date__c = Date.today().addDays(14);
        projList.add(phiTestProj2);
        insert projList;


        PHI_History__c testPhiHistory = new PHI_History__c();
        testPhiHistory.Name = 'Test PHI History 1';
        testPhiHistory.Current_PHI__c = 'Red';
        testPhiHistory.Date_Moved_to_Red__c = Date.today().addDays(-14);
        testPhiHistory.Date_Moved_to_Yellow__c = Date.today().addDays(-21);
        testPhiHistory.Initial_Escalation_Color__c = 'Yellow';
        testPhiHistory.Project_Name__c = phiTestProj2.Id;
        testPhiHistory.Resolved__c = false;
        insert testPhiHistory;

    }

    @isTest
    static void getPhiStatusFlowBatchTest() {
        String cronExpr = '0 0 0 15 12 ? 2022';
        Test.startTest();
        PhiStatusFlowBatchScheduler newTestScheduler = new PhiStatusFlowBatchScheduler();
        String jobId = System.schedule('PhiStatusFlowBatchScheduler Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void getPHIStatusFlowTest(){
        List<Opportunity> opptyList = [SELECT Id, Name, Initial_Staffing_Complete_Timestamp__c
                                        FROM Opportunity
                                        WHERE Name LIKE 'PHI Status%'];  
        List<Opportunity> opptyListToUpdate = new List<Opportunity>();
        for(Opportunity opp : opptyList){
            System.debug('Test Oppty Name: ' + opp.Name);
            System.debug('Test Oppty x2 Initial Staffing: ' + opp.Initial_Staffing_Complete_Timestamp__c);
            opp.Initial_Staffing_Complete_Timestamp__c = DateTime.now().addDays(-35);
            opptyListToUpdate.add(opp);
        }

        if(opptyListToUpdate.size() > 0){
            update opptyListToUpdate;
        }


        List<Project__c> inputList = [SELECT Id, Name, Project_Status__c, SR_Overall_Health_Value__c, Project_Terms__c, Estimate_to_Complete__c, Non_Bill_Hours_Perc__c, SR_Budget_Value__c, Run_Rate_Difference__c, X20_Greater_Remaining_Hours__c,
                                                Planned_Go_Live_Date__c, Planned_Close_Date__c, Remaining_Forecasted_Hrs__c, X10_Greater_Remaining_Hours__c, X30_Days_before_ESA_End_Date__c, X60_Days_Before_ESA_EndDate__c, X25_Greater_Remaining_Hours__c,
                                                SR_Schedule_Value__c, Previous_PHI_Value__c, Active_History_Record__c, X2_Weeks_from_Initial_Staffing__c, Initial_Staffing_Complete_Timestamp__c 
                                        FROM Project__c
                                        WHERE Name LIKE 'PHI Status%'];  
                    
        for(Project__c p : inputList){
            System.debug('Test Project Name: ' + p.Name);
            System.debug('Test Project Status: ' + p.Project_Status__c);
            System.debug('Test Project x2 Initial Staffing: ' + p.X2_Weeks_from_Initial_Staffing__c);
        }

        Test.startTest();
        PHIStatusFlowBatch newPHIBatch = new PHIStatusFlowBatch();
        Database.executeBatch(newPHIBatch, 50);
        Test.stopTest();
    }
}