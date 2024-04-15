@isTest 
private class Cirrus_Files_Status_ReportTests{ 
    static testMethod void test_Job() { 
        Test.startTest();
        
        Account a = new Account(Name = 'Test');
        insert a;
       // RecordType rt = [select id,Name from RecordType where SobjectType='Status_Report__c' and Name='Old_Do_Not_Use' Limit 1];
    
        sObject sobj = new Status_Report__c(
            Name = 'test',
            Account__c = a.Id,
            Period_Ending__c = Date.today().addDays(10),
            Go_Live_Date__c = Date.today().addDays(30),
            A_R_Status__c = 'Current',
            Budget_Risk__c = 'High',
            Timeline_Risk__c = 'High',
            Scope_Risk__c = 'High',
          //RecordTypeId=rt.Id,
            Budget_Comments__c = 'Test',
            Overall_Health_Comments__c = 'Test',
            Risk_Comments__c = 'Test',
            Schedule_Comments__c = 'Test',
            Scope_Comments__c= 'Test',
            Reporting_Period_Ending__c= date.today()
        ); 
        sobj = IGD.CirrusFilesTests.CreateRecord(sobj); 
        System.assertNotEquals(null, sobj.Id, 'There was a problem inserting the test record. Make sure that all required fields are being set.');
        Test.stopTest(); 
    } 
}