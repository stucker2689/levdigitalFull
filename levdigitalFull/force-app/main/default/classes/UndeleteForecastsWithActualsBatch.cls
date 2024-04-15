/**
 * Created 5/25/2022
 * 
 * Purpose: To mark any Forecasts with ActualHours > 0 as undeleted if they are marked as deleted
 */
public with sharing class UndeleteForecastsWithActualsBatch implements Database.Batchable<sObject>, Schedulable{
    public final String QueryString;
    public final String placeholderProjectURI = 'urn:replicon-tenant:levementum:project:30882';

    // Schedulable execute : Run batch
    public void execute(SchedulableContext sc) {
        System.debug('UndeleteForecastsWithActualsBatch here 1');
        UndeleteForecastsWithActualsBatch batch = new UndeleteForecastsWithActualsBatch();
        Database.executeBatch(batch, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('UndeleteForecastsWithActualsBatch START');

        String QueryString = 'SELECT Id, Project__c, Project__r.Name, Deleted_in_Replicon__c, Week_End_Date__c FROM RepliconForecast__c' +
			' WHERE ActualHours__c > 0 AND Deleted_in_Replicon__c = true ORDER BY Project__c';

        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<RepliconForecast__c> forecastsToUndeleteList){
        System.debug('UndeleteForecastsWithActualsBatch Execute Batch Size: ' + forecastsToUndeleteList.size());

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
        System.debug('UndeleteForecastsWithActualsBatch FINISH');
    }
}