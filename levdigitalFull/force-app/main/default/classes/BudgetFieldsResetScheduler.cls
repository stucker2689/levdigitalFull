global class BudgetFieldsResetScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        String query = 'Select Id, RecordTypeId, Dynamic_Forecasted_Revenue__c, Quarter_Start_Date__c, Quarter_End_Date__c, Forecasted_Hours__c, Forecasted_Revenue__c, Week_Start_Date__c From Budget__c';
        Id batchJobId = Database.executeBatch(new BudgetFieldsReset(query), 5);
    }
}