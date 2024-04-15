/**
 * Created By Sam Tucker 6/9/2023
 * Scheduler for the DeleteZeroForecastsBatch 
 * Runs to delete all Forecasts that have Estimated Hours = 0 that have not Time Entries associated with it.
 * 
 * Schedulable Apex run to run this code at 2 AM on Monday of every week:
 * 
    DeleteZeroForecastsBatch deleteEmptyForecastsBatch = new DeleteZeroForecastsBatch();
    System.schedule('Delete 0 Estimated Hours Forecasts with No related Time Entries Daily Job', '0 0 2 ? * *', deleteEmptyForecastsBatch);
 */
public with sharing class DeleteZeroForecastsBatch implements Database.Batchable<sObject>, Schedulable{
    public final String QueryString;

    public void execute (SchedulableContext ctx) {   

        DeleteZeroForecastsBatch newForecastDeleteBatch = new DeleteZeroForecastsBatch();
        Database.executeBatch(newForecastDeleteBatch, 100); 
    }


    public DeleteZeroForecastsBatch() {

        QueryString = 'SELECT Id, Name, Project__c, Project__r.Name, Contact__c, Contact__r.Name, Week_Start_Date__c, Week_End_Date__c, EstimatedHours__c, Deleted_in_Replicon__c, (SELECT Id, Name FROM Replicon_Time_Entries__r)'
                    + ' FROM RepliconForecast__c WHERE EstimatedHours__c = 0 OR EstimatedHours__c = null ORDER BY Project__c, Contact__c, Week_Start_Date__c';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** DeleteZeroForecastsBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<RepliconForecast__c> forecastList){
        System.debug('*************** DeleteZeroForecastsBatch EXECUTE ***************');

        List<RepliconForecast__c> forecastDeleteList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Replicon_Time_Entries__r.size() == 0){
                forecastDeleteList.add(forecast);
            }
        }

        if(forecastDeleteList.size() > 0){
            System.debug('***************************** Deleting ' + forecastDeleteList.size() + ' Forecasts with 0 Estimated Hours and NO related Time Entries *******************************');
            delete forecastDeleteList;
        }

    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** DeleteZeroForecastsBatch FINISH ***************');

    }
}