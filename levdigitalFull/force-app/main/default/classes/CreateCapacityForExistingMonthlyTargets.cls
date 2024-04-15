public with sharing class CreateCapacityForExistingMonthlyTargets {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();


    public static void createCapacityRecords(Integer month, Integer year){

        List<Revenue_Forecast__c> weeklyTargetList = new List<Revenue_Forecast__c>();
        weeklyTargetList = [SELECT Id, Name, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyActuals__c, WeeklyForecast__c, Capacity__c, WeeklyTarget__c
                            FROM Revenue_Forecast__c
                            WHERE RecordTypeId =: weeklyTargetRT AND CALENDAR_MONTH(FullWeekStartDate__c) =: month AND CALENDAR_YEAR(FullWeekStartDate__c) =: year];


        Set<Date> weekStartDateSet = new Set<Date>();
        Map<Date, Decimal> weekStartToActualsMap = new Map<Date, Decimal>();
        Map<Date, Decimal> weekStartToForecastsMap = new Map<Date, Decimal>();
        Map<Date, Decimal> weekStartToBudgetMap = new Map<Date, Decimal>();
        for(Revenue_Forecast__c weeklyTarget : weeklyTargetList){

            if(weeklyTarget.FullWeekStartDate__c != null){
                weekStartDateSet.add(weeklyTarget.FullWeekStartDate__c);
                
                if(weekStartToActualsMap.containsKey(weeklyTarget.FullWeekStartDate__c)){

                    Decimal moreActuals = 0; 
                    Decimal moreForecasts = 0;
                    Decimal moreBudget = 0;
                    moreActuals = weeklyTarget.WeeklyActuals__c != null ? weeklyTarget.WeeklyActuals__c : 0;
                    moreForecasts = weeklyTarget.WeeklyForecast__c != null ? weeklyTarget.WeeklyForecast__c : 0;
                    moreBudget = weeklyTarget.WeeklyTarget__c != null ?  weeklyTarget.WeeklyTarget__c : 0;

                    Decimal actuals = weekStartToActualsMap.get(weeklyTarget.FullWeekStartDate__c);
                    actuals += moreActuals;

                    Decimal forecasts = weekStartToForecastsMap.get(weeklyTarget.FullWeekStartDate__c);
                    forecasts += moreForecasts;

                    Decimal budget = weekStartToBudgetMap.get(weeklyTarget.FullWeekStartDate__c);
                    budget += moreBudget;

                }else{

                    Decimal actuals = 0; 
                    Decimal forecasts = 0;
                    Decimal budget = 0;
                    actuals = weeklyTarget.WeeklyActuals__c != null ? weeklyTarget.WeeklyActuals__c : 0;
                    forecasts = weeklyTarget.WeeklyForecast__c != null ? weeklyTarget.WeeklyForecast__c : 0;
                    budget = weeklyTarget.WeeklyTarget__c != null ?  weeklyTarget.WeeklyTarget__c : 0;

                    weekStartToActualsMap.put(weeklyTarget.FullWeekStartDate__c, actuals);
                    weekStartToForecastsMap.put(weeklyTarget.FullWeekStartDate__c, forecasts);
                    weekStartToBudgetMap.put(weeklyTarget.FullWeekStartDate__c, budget);
                }
            }
        }

        List<Capacity__c> existingCapacityList = new List<Capacity__c>();
        existingCapacityList = [SELECT Id, Name, WeekStartDate__c, WeekEndDate__c FROM Capacity__c WHERE WeekStartDate__c IN :weekStartDateSet];

        Map<Date, Capacity__c> existingCapacityStartDateToRecordMap = new Map<Date, Capacity__c>();
        for(Capacity__c cap : existingCapacityList){
            existingCapacityStartDateToRecordMap.put(cap.WeekStartDate__c, cap);
        }

        List<Capacity__c> newCapacityInsertList = new List<Capacity__c>();

        Date previousWeekStartDate = Date.today().toStartOfWeek().addDays(-7);

        for(Date startDate : weekStartDateSet){

            if(!existingCapacityStartDateToRecordMap.containsKey(startDate)){
                Capacity__c newCapacity = new Capacity__c();
                newCapacity.WeekStartDate__c = startDate;
                newCapacity.WeekEndDate__c = startDate.addDays(6);
                newCapacity.Name = 'Capacity for Week: ' + newCapacity.WeekStartDate__c.format() + ' - ' + newCapacity.WeekEndDate__c.format();
                newCapacity.Actuals__c = weekStartToActualsMap.get(startDate);
                newCapacity.Forecast__c = weekStartToForecastsMap.get(startDate);
                newCapacity.Budget__c = weekStartToBudgetMap.get(startDate);
                if(startDate <= previousWeekStartDate){
                    newCapacity.ShowActualsInsteadOfForecast__c = true;
                }

                newCapacityInsertList.add(newCapacity);
            }
        }

        if(newCapacityInsertList.size() > 0){
            insert newCapacityInsertList;

            List<Capacity__c> newlyInsertedCapacityList = new List<Capacity__c>();
            newlyInsertedCapacityList = [SELECT Id, Name, WeekStartDate__c, WeekEndDate__c FROM Capacity__c WHERE WeekStartDate__c IN :weekStartDateSet];

            Map<Date, Id> capacityStartDateToIdMap = new Map<Date, Id>();
            for(Capacity__c cap : newlyInsertedCapacityList){
                capacityStartDateToIdMap.put(cap.WeekStartDate__c, cap.Id);
            }

            List<Revenue_Forecast__c> weeklyTargetToPopulateList = new List<Revenue_Forecast__c>();
            weeklyTargetToPopulateList = [SELECT Id, Name, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyActuals__c, WeeklyForecast__c, Capacity__c, WeeklyTarget__c
                                            FROM Revenue_Forecast__c
                                            WHERE RecordTypeId =: weeklyTargetRT AND FullWeekStartDate__c IN :weekStartDateSet];

            List<Revenue_Forecast__c> weeklyTargetUpdateList = new List<Revenue_Forecast__c>();
            for(Revenue_Forecast__c rf : weeklyTargetToPopulateList){
                if(capacityStartDateToIdMap.containsKey(rf.FullWeekStartDate__c)){
                    rf.Capacity__c = capacityStartDateToIdMap.get(rf.FullWeekStartDate__c);
                    weeklyTargetUpdateList.add(rf);
                }
            }

            if(weeklyTargetUpdateList.size() > 0){
                update weeklyTargetUpdateList;
            }
        }



    }
}