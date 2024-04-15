/**
 * Created 5/25/2022 ST
 * 
 * To test the functionality of EmployeeQuarterlyBillableHoursBatch
 * 
 * Test that the batch run will calculate employees Billed Hours this Month and Billed Hours last Month fields
 */
@isTest
public with sharing class EmployeeQuarterlyBillableHoursBatchTest {
    
    @TestSetup
    static void makeData(){
        //Create Account
        Account testAcct = TestDataFactory.createAccount(false, 'Client');
        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{testAcct, levementumLLCAcct};
        insert testAccountList;

        //Create Opportunity
        Opportunity ptoTestOppty = TestDataFactory.createOpportunity(false, testAcct.Id, 'Salesforce');
        ptoTestOppty.Name = 'Test PTO Oppty';
        ptoTestOppty.StageName = 'Closed Won';
        ptoTestOppty.Amount = 10000;
        ptoTestOppty.Do_Not_Create_Project__c = false; //Switch so it Creates a Project when Closed Won
        insert ptoTestOppty;

        //Create Project
        Project__c testProj = new Project__c();
        testProj = [SELECT Id, Name, RepliconURI__c FROM Project__c WHERE Opportunity__c =: ptoTestOppty.Id LIMIT 1];
        testProj.RepliconURI__c = 'urn:replicon-tenant:levementum:project:987987';
        update testProj;

        //Create Employee
        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        //Create Project Team Member Billing Rate
        Project_Team_Member_Billing_Rate__c devBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 200, Project__c = testProj.Id);
        insert devBillRate;

        //Create Time Entries for current, previous, and next Quarter
        Date currentQuarterDate = Date.today();
        Date previousQuarterDate = getPreviousOrNextQuarterDate(currentQuarterDate, true);
        Date nextQuarterDate = getPreviousOrNextQuarterDate(currentQuarterDate, false);
        Replicon_Time_Entry__c currentimeEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 8, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = currentQuarterDate);
        Replicon_Time_Entry__c previousQuarterEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 4, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = previousQuarterDate);
        Replicon_Time_Entry__c nextQuarterEntry = new Replicon_Time_Entry__c(Employee__c = con.Id, Project__c = testProj.Id, Associated_Billing_Rate__c = devBillRate.Id, TotalHrs__c = 2, Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:987987', EntryDate__c = nextQuarterDate);
        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{currentimeEntry, previousQuarterEntry, nextQuarterEntry};
        insert entryList;
    }

    @isTest
    static void scheduleBatchRun_Test(){
        String cronExpr = '0 0 0 15 12 ? 2022';
        Test.startTest();
        EmployeeQuarterlyBillableHoursBatch newTestScheduler = new EmployeeQuarterlyBillableHoursBatch();
        String jobId = System.schedule('Get Employee Quarterly Billable Hours Test Batch Run', cronExpr, newTestScheduler);
        newTestScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void calculateEmployeeCurrentAndPreviousMonthBillHours_Test(){

        Test.startTest();
        EmployeeQuarterlyBillableHoursBatch batch = new EmployeeQuarterlyBillableHoursBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

    }

    private static Date getPreviousOrNextQuarterDate(Date d, Boolean getPreviousQuarterDate){        
        Integer dateMonth = d.month();
        Date returnDate;

        switch on dateMonth {
            when 1, 2, 3{
                if(getPreviousQuarterDate){
                    //Get Date from Previous Quarter
                    returnDate = Date.newInstance(d.year() -1, 10, 1);
                }else{
                    //Get Date from Next Quarter
                    returnDate = Date.newInstance(d.year(), 4, 1);
                }
            }
            when 4, 5, 6{
                if(getPreviousQuarterDate){
                    //Get Date from Previous Quarter
                    returnDate = Date.newInstance(d.year(), 1, 1);
                }else{
                    //Get Date from Next Quarter
                    returnDate = Date.newInstance(d.year(), 7, 1);
                }
            }
            when 7, 8, 9{
                if(getPreviousQuarterDate){
                    //Get Date from Previous Quarter
                    returnDate = Date.newInstance(d.year(), 4, 1);
                }else{
                    //Get Date from Next Quarter
                    returnDate = Date.newInstance(d.year(), 10, 1);
                }
            }
            when 10, 11, 12{
                if(getPreviousQuarterDate){
                    //Get Date from Previous Quarter
                    returnDate = Date.newInstance(d.year(), 7, 1);
                }else{
                    //Get Date from Next Quarter
                    returnDate = Date.newInstance(d.year() + 1, 1, 1);
                }
            }
          }
          return returnDate;
    }
}