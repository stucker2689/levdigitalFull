/**
 * Created 5/9/2022 ST
 * 
 * Purpose: Schedule the ProjectRemainingForecastsBatch class to rollup the Remaining Forecasts on a Project on a scheduled basis
 */
public with sharing class ProjectRemainingForecastsBatchScheduler implements Schedulable{
    public ProjectRemainingForecastsBatchScheduler() {

    }

    public void execute (SchedulableContext ctx) {   

        ProjectRemainingForecastsBatch newBatchRun = new ProjectRemainingForecastsBatch();
        Database.executeBatch(newBatchRun, 10); 
    }
}