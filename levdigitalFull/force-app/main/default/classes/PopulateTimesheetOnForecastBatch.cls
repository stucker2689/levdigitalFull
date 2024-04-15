/**
 * Created by ST 8.2.2023
 * Purpose: Populate Existing Forecasts with Timesheet Lookups
 * 
PopulateTimesheetOnForecastBatch newBatchRun = new PopulateTimesheetOnForecastBatch();
Database.executeBatch(newBatchRun, 250);
 */
public with sharing class PopulateTimesheetOnForecastBatch implements Database.Batchable<SObject>{
    
    public final String QueryString;
    private String batchRollupObject;
    private Set<Id> batchRollupIdSet;
    
    public PopulateTimesheetOnForecastBatch() {

        QueryString = 'SELECT Id, Name, Contact__c, Contact__r.Name, Project__c, Project__r.Name, Week_Start_Date__c, Week_End_Date__c, EstimatedHours__c, EstimatedRevenue__c, '
        + ' ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Timesheet__c'
        + ' FROM RepliconForecast__c'
        + ' WHERE Contact__c != null AND Week_Start_Date__c != null AND Timesheet__c = null AND Week_Start_Date__c >= N_YEARS_AGO:3'
        + ' ORDER BY Contact__c, Week_Start_Date__c DESC';
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** PopulateTimesheetOnForecastBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext bc, List<RepliconForecast__c> forecastList){
        System.debug('*************** PopulateTimesheetOnForecastBatch EXECUTE ***************');
        System.debug('*************** Running Batch to Populate ' + forecastList.size() + ' Existing Forecasts with Timesheet Lookups');
        RepliconForecastTriggerHelper.populateForecastTimesheet(forecastList, true);

    }
 
    public void finish(Database.BatchableContext bc){
        System.debug('*************** PopulateTimesheetOnForecastBatch FINISH ***************');

    }
}