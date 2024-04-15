/**
 * Created By Sam Tucker 4/25/2022
 * Batch Apex class that marks Forecasts as Deleted_in_Replicon__c = false for PTO forecasts
 */
global with sharing class UndeletePTOForecastsBatch implements Database.Batchable<sObject>, Schedulable{
    
    public final String QueryString;
    public final String placeholderProjectURI = 'urn:replicon-tenant:levementum:project:30882';

    // Schedulable execute : Run batch
    global void execute(SchedulableContext sc) {
        System.debug('UndeletePTOForecastsBatch here 1');
        UndeletePTOForecastsBatch batch = new UndeletePTOForecastsBatch();
        Database.executeBatch(batch, 500);

        
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('UndeletePTOForecastsBatch here2');
        String QueryString = 'SELECT Id, Project__r.Name, Deleted_in_Replicon__c, Week_End_Date__c FROM RepliconForecast__c' +
			' WHERE Project__r.RepliconURI__c = \'' + placeholderProjectURI + '\' AND Deleted_in_Replicon__c = true';
        System.debug('UndeletePTOForecastsBatch START');
        return Database.getQueryLocator(QueryString);
    }

    global void execute(Database.BatchableContext BC, List<RepliconForecast__c> ptoForecastList){
        System.debug('UndeletePTOForecastsBatch Execute Batch Size: ' + ptoForecastList.size());

        List<Id> ptoForecastIdList = new List<Id>();
        for(RepliconForecast__c fore : ptoForecastList){
            ptoForecastIdList.add(fore.Id);
        }

        /*List<Replicon_Time_Entry__c> ptoEntryList = new List<Replicon_Time_Entry__c>();
        ptoEntryList = [SELECT Id, Name, Project__c, Project__r.Name, EntryDate__c, TotalHrs__c, Replicon_URI__c, Replicon_Forecast__r.Name, Deleted_in_replicon__c, Replicon_Forecast__c
                        FROM Replicon_Time_Entry__c 
                        WHERE Project__r.RepliconURI__c =: placeholderProjectURI AND Deleted_in_Replicon__c = false AND Time_Off__c = true AND TotalHrs__c > 0 AND Replicon_Forecast__c IN :ptoForecastIdList];

        List<Id> forecastToUndeleteIdList = new List<Id>();
        for(Replicon_Time_Entry__c entry : ptoEntryList){
            forecastToUndeleteIdList.add(entry.Replicon_Forecast__c);
        }*/

        AggregateResult[] timeEntryWithForecastAgg = [SELECT count(Id), Replicon_Forecast__c
                                                        FROM Replicon_Time_Entry__c 
                                                        WHERE Project__r.RepliconURI__c =: placeholderProjectURI AND Deleted_in_Replicon__c = false AND Time_Off__c = true AND TotalHrs__c > 0 AND Replicon_Forecast__c IN :ptoForecastIdList
                                                        GROUP BY Replicon_Forecast__c];

        List<Id> forecastToUndeleteIdList = new List<Id>();
        for(AggregateResult ar : timeEntryWithForecastAgg){
            Id undeleteForecastId;
            if(ar.get('Replicon_Forecast__c') != null){
                undeleteForecastId = (Id)ar.get('Replicon_Forecast__c');
                forecastToUndeleteIdList.add(undeleteForecastId);
            }
        }
        
        List<RepliconForecast__c> forecastsToUpdateList = new List<RepliconForecast__c>();
        //Only do work if the query returns forecasts
        if(ptoForecastList.size() > 0){

            for(RepliconForecast__c forecast : ptoForecastList){
                if(forecastToUndeleteIdList.contains(forecast.Id)){
                    forecast.Deleted_in_Replicon__c = false; //Set each Placeholder forecast to Not Deleted
                    forecastsToUpdateList.add(forecast);
                }
            }

            if(forecastsToUpdateList.size() > 0){
                update forecastsToUpdateList;
            }

        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('UndeletePTOForecastsBatch FINISH');
    }
}