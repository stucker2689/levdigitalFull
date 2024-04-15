/**
 * Created By Sam Tucker 2/25/2022
 * Scheduler for the UndeletePlaceholderForecastsBatch class that marks Forecasts as Deleted_in_Replicon__c = false for placeholder forecasts
 */
public with sharing class UndeletePlaceholderForecastsScheduler implements Schedulable{
    public UndeletePlaceholderForecastsScheduler() {

    }
    
    public void execute (SchedulableContext ctx) {   

        UndeletePlaceholderForecastsBatch newBatchRun = new UndeletePlaceholderForecastsBatch();
        Database.executeBatch(newBatchRun, 400); 
    }
}