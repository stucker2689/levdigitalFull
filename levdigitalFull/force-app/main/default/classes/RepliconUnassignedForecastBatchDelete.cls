/**
* @author LevDigital
* @date 2019
* 
* @description Batch delete all unassigned forecast records for current and future weeks
*/
global class RepliconUnassignedForecastBatchDelete implements Database.Batchable<SObject>, Schedulable {

    // Schedulable execute : Run batch
    global void execute(SchedulableContext sc) {
        RepliconUnassignedForecastBatchDelete batch = new RepliconUnassignedForecastBatchDelete();
        Database.executeBatch(batch);
    }

    // Batch Start : retrieves current and future forecast records assigned to Placeholder Contact
    global Database.QueryLocator start(Database.BatchableContext bc) {
		String queryString = 
			'SELECT Id FROM RepliconForecast__c' +
			' WHERE Contact__r.Name = \'Place Holder\'' +
			' AND Week_Start_Date__c >= THIS_WEEK';
		
		Database.QueryLocator ql = Database.getQueryLocator(queryString);
        return ql;
    }

    // Batch execute : deletes forecast records
    global void execute(Database.BatchableContext bc, List<RepliconForecast__c> records){
        try {
			delete records;
		}
		catch (Exception e) {
			Error_Log_Lev__c errorLog = new Error_Log_Lev__c();
			errorLog.Error_Message__c = 'Problem deleting records: ' + e.getMessage();
            errorLog.Method_Name__c = 'Batch execute';
            errorLog.Class_Name__c = 'RepliconUnassignedForecastBatchDelete';
			insert errorLog;
		}
    }

    // Batch finish
    global void finish(Database.BatchableContext bc){
		// Empty
    }
}