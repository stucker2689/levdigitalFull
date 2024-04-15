/**
 * Created By Sam Tucker 2/25/2022
 * Batch Apex class that marks Forecasts as Deleted_in_Replicon__c = false for placeholder forecasts
 */
public with sharing class UndeletePlaceholderForecastsBatch implements Database.Batchable<sObject>{
    
    public final String QueryString;
    public final String placeholderProjectURI = 'urn:replicon-tenant:levementum:project:26030';
    public final Integer initialPlaceHolderForecastsToProcessCount;
    public Integer placeholderForecastsProcessesCount = 0;

    public UndeletePlaceholderForecastsBatch() {
        System.debug('UndeletePlaceholderForecastsBatch');
        AggregateResult [] placeholderForecasts = [SELECT count(Id)
                                                    FROM RepliconForecast__c
                                                    WHERE Deleted_in_Replicon__c = true AND Project__r.RepliconURI__c = 'urn:replicon-tenant:levementum:project:26030' AND Week_End_Date__c >= TODAY];
        if(placeholderForecasts.size() > 0){
            System.debug('placeholderForecasts.size(): ' + placeholderForecasts);
            initialPlaceHolderForecastsToProcessCount = (Integer)placeholderForecasts[0].get('expr0');
        }

        System.debug('Start: ' + initialPlaceHolderForecastsToProcessCount);

        QueryString = 'SELECT Id, Name, Project__c, Project__r.RepliconURI__c, Deleted_in_Replicon__c, Week_End_Date__c FROM RepliconForecast__c WHERE Deleted_in_Replicon__c = true AND Project__r.RepliconURI__c = \'' + placeholderProjectURI + '\' AND Week_End_Date__c >= TODAY AND IsDeleted = false LIMIT 40000';
                                
    }

    //public (Database.QueryLocator | Iterable<sObject>) start(Database.BatchableContext bc) {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('START HERE');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<RepliconForecast__c> placeholderForecastList){
        System.debug('Execute: ' + placeholderForecastList.size());
        
        List<RepliconForecast__c> forecastsToUpdateList = new List<RepliconForecast__c>();
        //Only do work if the query returns forecasts
        if(placeholderForecastList.size() > 0){

            for(RepliconForecast__c forecast : placeholderForecastList){
                forecast.Deleted_in_Replicon__c = false;
                forecastsToUpdateList.add(forecast);
            }

            if(forecastsToUpdateList.size() > 0){
                placeholderForecastsProcessesCount += forecastsToUpdateList.size();
                update forecastsToUpdateList;
            }

        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('Processed Count: ' + placeholderForecastsProcessesCount);
        System.debug('Total Forecasts to be Processed: ' + initialPlaceHolderForecastsToProcessCount);

        if((placeholderForecastsProcessesCount < initialPlaceHolderForecastsToProcessCount)) {
            UndeletePlaceholderForecastsBatch newChainBatch = new UndeletePlaceholderForecastsBatch();
                Database.executeBatch(newChainBatch, 400); 
        }

        /*
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('UndeletePlaceholderForecastsBatch ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });*/
    }
}