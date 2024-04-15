global class WeeklyBudgetForecastSch implements Schedulable {

    global void execute(SchedulableContext sc) {
        String forecastQuery = 'Select Id, Week_Start_Date__c, Week_End_Date__c, estimatedrevenue__c, estimatedhours__c from RepliconForecast__c';
        Id batchJobId = Database.executeBatch(new WeeklyBudgetForecastScheduler(forecastQuery), 50);
    }
}