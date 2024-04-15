/**
* @author LevDigital
* @date 2019
* 
* @description Batch delete all Replicon Forecasts that haven't been updated today
*/
global class RepliconDeltaForecastBatchDelete implements Database.Batchable<SObject>, Schedulable {
	
    global static String queryDefault = 'SELECT Id FROM RepliconForecast__c WHERE LastModifiedDate != YESTERDAY AND Week_Start_Date__c >= THIS_WEEK AND NotForecasted__c = FALSE AND (ActualHours__c = 0 OR ActualHours__c = NULL)';
    global static String query;
    global static String defaultCronExpression1 = '';
    global static String defaultCronExpression2 = '';
    global static String defaultCronExpression3 = '';
    
    global RepliconDeltaForecastBatchDelete(String queryString) {
        query = queryString;
    }
    
    // Schedulable execute : Run batch
    global void execute(SchedulableContext sc) {
        RepliconDeltaForecastBatchDelete batch = new RepliconDeltaForecastBatchDelete(RepliconDeltaForecastBatchDelete.queryDefault);
        Database.executeBatch(batch);
    }

    // Batch Start : retrieves records not modified today
    global Database.QueryLocator start(Database.BatchableContext bc) {
		Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
    }

    // Batch execute : deletes forecast records
    global void execute(Database.BatchableContext bc, List<RepliconForecast__c> records){
        try {
			delete records;
		}
		catch (Exception e) { 
            Error_Log_Lev__c errorLog = new Error_Log_Lev__c(Error_Message__c = 'Problem deleting records: ' + e.getMessage(), Method_Name__c = 'Batch execute', Class_Name__c = 'RepliconDeltaForecastBatchDelete'); 
            insert errorLog;
		}
    }

    // Batch finish
    global void finish(Database.BatchableContext bc){
    }
}