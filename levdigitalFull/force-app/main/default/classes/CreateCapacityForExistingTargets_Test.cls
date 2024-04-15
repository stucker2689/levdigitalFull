@isTest
private class CreateCapacityForExistingTargets_Test {
    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    @TestSetup
    static void makeData(){

        Revenue_Forecast__c testAugustMonthlyRevForecast = new Revenue_Forecast__c();
        testAugustMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testAugustMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 8, 1);
        testAugustMonthlyRevForecast.MonthlyTarget__c = 2300000; //23 Million for clean distribution of target to weeks because of 23 Business days in August 2022

        Revenue_Forecast__c testSeptemberMonthlyRevForecast = new Revenue_Forecast__c();
        testSeptemberMonthlyRevForecast.RecordTypeId = monthlyTargetRT;
        testSeptemberMonthlyRevForecast.MonthStartDate__c = Date.newInstance(2022, 9, 1);
        testSeptemberMonthlyRevForecast.MonthlyTarget__c = 2100000; //21 Million for clean distribution of target to weeks because of 21 Business days in September 2022 (There is one holiday in September 2022, Labor Day, on 9/5/2022)

        /**
         * Should also test with May 2022 and June 2022, because 5/30 is a holiday on a week that spans 2 months (5/29/2022 - 6/4/2022)
         * May not need to test this just can ensure that the week with Labor Day keeps its entire value instead of changing it to 4/5 of what is should bee since there is only 4 business days on that week.
         */

        List<Revenue_Forecast__c> testMonthlyRevForecastsInsertList = new List<Revenue_Forecast__c>{testAugustMonthlyRevForecast, testSeptemberMonthlyRevForecast};
        insert testMonthlyRevForecastsInsertList;

        List<Capacity__c> capacityList = new List<Capacity__c>();
        capacityList = [SELECT Id, Name FROM Capacity__c];
        delete capacityList;
    }

    @isTest
    static void createCapacityRecordsForExistingRevenueForecasts(){

        List<Capacity__c> capacityBeforeList = new List<Capacity__c>();
        capacityBeforeList = [SELECT Id, Name, Actuals__c, Budget__c, Forecast__c, WeekStartDate__c, WeekEndDate__c FROM Capacity__c];
        System.assertEquals(0, capacityBeforeList.size(), 'Capacity Records were not properly deleted before the Create Capacity method was called');

        Test.startTest();
        CreateCapacityForExistingMonthlyTargets.createCapacityRecords(8, 2022);
        Test.stopTest();

        List<Capacity__c> capacityAfterList = new List<Capacity__c>();
        capacityAfterList = [SELECT Id, Name, Actuals__c, Budget__c, Forecast__c, WeekStartDate__c, WeekEndDate__c FROM Capacity__c];
        System.assertNotEquals(0, capacityAfterList.size(), 'Capacity Records were not properly created after the Create Capacity method was called');

    }
}