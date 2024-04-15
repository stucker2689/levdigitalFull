/**
 * Created 6/3/2022
 * 
 * Purpose: To mark any existing Kickoff Placeholder Forecasts as undeleted if they are marked as deleted by the Replicon Integration Deletion process
 */
public with sharing class UndeleteKickOffPlaceholderForecastsBatch implements Database.Batchable<sObject>, Schedulable{
    public final String QueryString;

    // Schedulable execute : Run batch
    public void execute(SchedulableContext sc) {
        System.debug('UndeleteKickOffPlaceholderForecastsBatch here 1');
        UndeleteKickOffPlaceholderForecastsBatch batch = new UndeleteKickOffPlaceholderForecastsBatch();
        Database.executeBatch(batch, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('UndeleteKickOffPlaceholderForecastsBatch START');

        String QueryString = 'SELECT Id, Project__c, Project__r.Name, Deleted_in_Replicon__c, Week_End_Date__c, Kickoff_Placeholder_Forecast__c FROM RepliconForecast__c' +
			' WHERE Kickoff_Placeholder_Forecast__c = true AND Deleted_in_Replicon__c = true';

        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<RepliconForecast__c> forecastsToUndeleteList){
        System.debug('UndeleteKickOffPlaceholderForecastsBatch Execute Batch Size: ' + forecastsToUndeleteList.size());

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastsToUndeleteList){
            forecast.Deleted_in_Replicon__c = false;
            forecastUpdateList.add(forecast);
        }

        if(forecastUpdateList.size() > 0){
            update forecastUpdateList;
        }        
    }

    public void finish(Database.BatchableContext BC){
        System.debug('UndeleteKickOffPlaceholderForecastsBatch FINISH');
    }
}