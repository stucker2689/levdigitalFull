@isTest
public class BudgetTest {

    @isTest
    public static void testWeeklyBudgetInsert() {
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Actual_Revenue__c = 10000;
        forecast.Week_Start_Date__c = system.today();
        insert forecast;
        
        Id RecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Weekly Budget').getRecordTypeId();

        Budget__c b = new Budget__c();
        b.recordTypeId = RecordTypeId;
        b.Budget__c  = 10000;
        b.Week_Start_Date__c = system.today();
        insert b;
    }
    
    @isTest
    public static void testMonthlyBudgetInsert() {       
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Actual_Revenue__c = 10000;
        forecast.Week_Start_Date__c = system.today();
        insert forecast;
        
        Id RecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Monthly Budget').getRecordTypeId();
       
        Budget__c b = new Budget__c();
        b.RecordTypeId = recordTypeId;
        b.Budget__c  = 10000;
        b.Month__c = 'September';
        insert b;
    }
    
    @isTest
    public static void testQuarterlyBudgetInsert() {
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Actual_Revenue__c = 10000;
        forecast.Week_Start_Date__c = system.today();
        insert forecast;
        
        Id RecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Quarterly Budget').getRecordTypeId();
        
        Budget__c b = new Budget__c();
        b.RecordTypeId = recordTypeId;
        b.Budget__c  = 10000;
        b.Quarter__c = 'Q3';
        insert b;
    }
}