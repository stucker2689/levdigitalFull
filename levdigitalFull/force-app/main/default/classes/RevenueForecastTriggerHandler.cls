public with sharing class RevenueForecastTriggerHandler {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    public static void onBeforeInsert(List<Revenue_Forecast__c> newList){

        List<Revenue_Forecast__c> monthlyTargetList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyTargetList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : newList){
            if(rf.RecordTypeId == monthlyTargetRT){
                monthlyTargetList.add(rf);
            }else if(rf.RecordTypeId == weeklyTargetRT){
                weeklyTargetList.add(rf);
            }
        }

        if(monthlyTargetList.size() > 0){
            RevenueForecastTriggerHelper.populateMonthlyTargetFields(monthlyTargetList); //Create Name for Monthly Target Record Types
        }
        if(weeklyTargetList.size() > 0){
            RevenueForecastTriggerHelper.rollupWeeklyBookingsOnInsert(weeklyTargetList); //Populate Bookings $
            RevenueForecastTriggerHelper.rollupWeeklyForecastsOnInsert(weeklyTargetList); //Rollup the Forecast Amounts
        }

    }

    public static void onAfterInsert(List<Revenue_Forecast__c> newList){
        Map<Date, Capacity__c> weekStartDateToCapacityToInsertMap = new Map<Date, Capacity__c>(); 
        List<Revenue_Forecast__c> monthlyTargetList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyTargetList = new List<Revenue_Forecast__c>();
        List<Integer> monthsList = new List<Integer>();
        List<Integer> yearsList = new List<Integer>();
        for(Revenue_Forecast__c rf : newList){
            if(rf.RecordTypeId == monthlyTargetRT){
                monthlyTargetList.add(rf);
            }else if(rf.RecordTypeId == weeklyTargetRT){
                weeklyTargetList.add(rf);
                monthsList.add(rf.WeekStartDate__c.month());
                yearsList.add(rf.WeekStartDate__c.year());
            }
        }

        if(monthlyTargetList.size() > 0){
            weekStartDateToCapacityToInsertMap = RevenueForecastTriggerHelper.createWeeklyCapacityRecordsFromMonthlyTarget(monthlyTargetList); //Create Capacity Records
            RevenueForecastTriggerHelper.createWeeklyTargetsFromMonthly(monthlyTargetList, weekStartDateToCapacityToInsertMap); //Create the Weekly Target Records for the Month
        }
        if(weeklyTargetList.size() > 0){
            RevenueForecastTriggerHelper.weeklyForecastsChanged(weeklyTargetList); //Rollup Changed Weekly Forecast Amounts to the related Monthly Actuals Amount
        }

        if(monthsList.size() > 0){
            //Call a batch run to link any existing time entries to the existing project roles when they are inserted
            WeeklyTargetTimeEntryMatchBatchTwo matchTimeEntriesBatch = new WeeklyTargetTimeEntryMatchBatchTwo(monthsList, yearsList);
            Database.executeBatch(matchTimeEntriesBatch, 100); //Batch size (100) determines how many Time Entries to update at a time
        }
    }

    public static void onBeforeUpdate(List<Revenue_Forecast__c> newList, Map<Id, Revenue_Forecast__c> oldMap){

    }

    public static void onAfterUpdate(List<Revenue_Forecast__c> newList, Map<Id, Revenue_Forecast__c> oldMap){
        List<Revenue_Forecast__c> monthlyTargetChangedList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyTargetChangedList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyActualAmountChangedList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyForecastAmountChangedList = new List<Revenue_Forecast__c>();
        List<Revenue_Forecast__c> weeklyBookingsAmountChangedList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : newList){
            if(rf.RecordTypeId == monthlyTargetRT){
                if(rf.MonthlyTarget__c != oldMap.get(rf.Id).MonthlyTarget__c){ //If Monthly Target has changed
                    monthlyTargetChangedList.add(rf);
                }
            }else if(rf.RecordTypeId == weeklyTargetRT){
                if(rf.WeeklyTarget__c != oldMap.get(rf.Id).WeeklyTarget__c){ //If Weekly Target has changed
                    weeklyTargetChangedList.add(rf);
                }
                if(rf.WeeklyActuals__c != oldMap.get(rf.Id).WeeklyActuals__c){ //If Weekly Actuals have changed
                    weeklyActualAmountChangedList.add(rf);
                }
                if(rf.WeeklyForecast__c != oldMap.get(rf.Id).WeeklyForecast__c){ //If Weekly Forecasts have changed
                    weeklyForecastAmountChangedList.add(rf);
                }
                if(rf.Bookings__c != oldMap.get(rf.Id).Bookings__c){ //If Weekly Bookings have changed
                    weeklyBookingsAmountChangedList.add(rf);
                }
            }
        }

        if(monthlyTargetChangedList.size() > 0){
            if(RevenueForecastCheckTriggerRun.runWeeklyTargetChangedOnce()){
                RevenueForecastTriggerHelper.monthlyTargetChanged(monthlyTargetChangedList, oldMap); //Adjust the related Weekly Targets that are under the Monthly Target     
            }       
        }
        if(weeklyTargetChangedList.size() > 0){
            if(RevenueForecastCheckTriggerRun.runWeeklyTargetChangedOnce()){
                RevenueForecastTriggerHelper.weeklyTargetChanged(weeklyTargetChangedList); //Rollup Changed Weekly Target amount to the related Monthly Target Amount 
            }             
        }
        if(weeklyActualAmountChangedList.size() > 0){
            RevenueForecastTriggerHelper.weeklyActualsChanged(weeklyActualAmountChangedList); //Rollup Changed Weekly Actuals to the related Monthly Actuals Amount
        }
        if(weeklyForecastAmountChangedList.size() > 0){
            RevenueForecastTriggerHelper.weeklyForecastsChanged(weeklyForecastAmountChangedList); //Rollup Changed Weekly Forecast Amounts to the related Monthly Actuals Amount
        }
        if(weeklyBookingsAmountChangedList.size() > 0){
            RevenueForecastTriggerHelper.weeklyBookingsChanged(weeklyBookingsAmountChangedList); //Rollup Bookings Amounts to the related Monthly Bookings
        }


    }
}