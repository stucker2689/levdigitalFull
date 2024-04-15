/**
 * Create 4/28/2022 ST
 * 
 * Purpose: Test the UndeletePTOForecastsBatch class
 */

@isTest
private class UndeletePTOForecastsBatchTest {
    @testSetup
    static void setupData() {

        Account ptoTestAcccount = TestDataFactory.createAccount(false, 'Client');

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        
        List<Account> testAccountList = new List<Account>{ptoTestAcccount, levementumLLCAcct};
        insert testAccountList;

        Opportunity ptoTestOppty = TestDataFactory.createOpportunity(false, ptoTestAcccount.Id, 'Salesforce');
        ptoTestOppty.Name = 'Undelete PTO Forecast Oppty';
        ptoTestOppty.StageName = 'Closed Won';
        ptoTestOppty.Amount = 10000;
        insert ptoTestOppty;

        Project__c nonPtoPoject = new Project__c();
        nonPtoPoject.Account__c = ptoTestAcccount.Id;
        nonPtoPoject.Opportunity__c = ptoTestOppty.Id;
        nonPtoPoject.Name = 'Undelete PTO Forecast Non PTO Project';
        nonPtoPoject.Project_Status__c = 'Active';
        nonPtoPoject.Planned_Close_Date__c = Date.today().addDays(14);

        Project__c ptoProject = new Project__c();
        ptoProject.Account__c = ptoTestAcccount.Id;
        ptoProject.Opportunity__c = ptoTestOppty.Id;
        ptoProject.Name = 'Lev - PTO';
        ptoProject.Project_Status__c = 'Not Started';
        ptoProject.RepliconURI__c = 'urn:replicon-tenant:levementum:project:30882';
        ptoProject.Planned_Close_Date__c = Date.today().addDays(14);

        List<Project__c> testProjectList = new List<Project__c>{nonPtoPoject, ptoProject};
        insert testProjectList;

        Contact con = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee' and Replicon User Number of 9999

        RepliconForecast__c testPTOForecast = TestDataFactory.createForecast(false, 'Test PTO Forecast', ptoProject.Id, con.Id, Date.today().toStartOfWeek().addDays(6), null);
        testPTOForecast.Deleted_in_Replicon__c = true;
        insert testPTOForecast;

        Replicon_Timesheet__c testTimesheet = TestDataFactory.createTimesheet(true, con.Id);

        Replicon_Time_Entry__c testPtoEntry1 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry1.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testPtoEntry1.EntryDate__c = Date.today();
        testPtoEntry1.TotalHrs__c = 8;
        testPtoEntry1.Time_Off__c = true;
        testPtoEntry1.Replicon_Forecast__c = testPTOForecast.id;
        testPtoEntry1.Deleted_in_Replicon__c = false;

        Replicon_Time_Entry__c testPtoEntry2 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry1.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testPtoEntry2.EntryDate__c = Date.today();
        testPtoEntry2.TotalHrs__c = 8;
        testPtoEntry2.Time_Off__c = true;
        testPtoEntry2.Deleted_in_Replicon__c = true;

        Replicon_Time_Entry__c testNonPtoEntry3 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry1.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testNonPtoEntry3.EntryDate__c = Date.today();
        testNonPtoEntry3.TotalHrs__c = 8;
        testNonPtoEntry3.Time_Off__c = false;
        testNonPtoEntry3.Deleted_in_Replicon__c = true;

        Replicon_Time_Entry__c testNonPtoEntry4 = TestDataFactory.createTimeEntry(false, testTimesheet.Id, con.Id, null);
        testPtoEntry1.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882';
        testNonPtoEntry4.EntryDate__c = Date.today();
        testNonPtoEntry4.TotalHrs__c = 8;
        testNonPtoEntry4.Time_Off__c = false;
        testNonPtoEntry4.Deleted_in_Replicon__c = false;

        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>{testPtoEntry1, testPtoEntry2, testNonPtoEntry3, testNonPtoEntry4};
        insert entryList;

    }

    @isTest
    static void getUndeletePTOForecasts(){

        List<Replicon_Time_Entry__c> testEntryList = new List<Replicon_Time_Entry__c>();

        testEntryList = [SELECT Id, Name, Replicon_User_Number__c, Project__c, Employee__c, WeekEndDate__c, Timesheet_Period__c, Deleted_in_Replicon__c, Replicon_Timesheet__c, Time_Off__c, Project__r.Name, Replicon_Forecast__c, TotalHrs__c
                        FROM Replicon_Time_Entry__c
                        WHERE Project__r.Name = 'Lev - PTO'];

        List<Id> forecastWithUndeletedPTOEntriesList = new List<Id>();
        for(Replicon_Time_Entry__c entry : testEntryList){
            if(entry.Deleted_in_Replicon__c == false && entry.TotalHrs__c > 0 && entry.Replicon_Forecast__c != null){
                forecastWithUndeletedPTOEntriesList.add(entry.Replicon_Forecast__c);
            }
        }

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();

        forecastList = [SELECT Id, Name, Deleted_in_Replicon__c 
                        FROM RepliconForecast__c];

                        System.debug('forecastList.size() ' + forecastList.size());
        List<RepliconForecast__c> forecastToMarkAsDeletedList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            forecast.Deleted_in_Replicon__c = true;
            forecastToMarkAsDeletedList.add(forecast);
        }

        update forecastToMarkAsDeletedList;        

        Test.startTest();
        UndeletePTOForecastsBatch newBatch = new UndeletePTOForecastsBatch();
        Database.executeBatch(newBatch, 50);
        Test.stopTest();

        forecastList = [SELECT Id, Name, Deleted_in_Replicon__c, Project__r.Name
                        FROM RepliconForecast__c];

        for(RepliconForecast__c forecastToCheck : forecastList){
            if(forecastToCheck.Project__r.Name == 'Lev - PTO' && forecastWithUndeletedPTOEntriesList.contains(forecastToCheck.Id)){
                System.assertEquals(false, forecastToCheck.Deleted_in_Replicon__c, 'PTO Forecast was not mark as Deleted in Replicon = false as expected');
            }
        }
    }
}