/**
TimeEntryRollupCalcBatchScheduler newBatchRun = new TimeEntryRollupCalcBatchScheduler('Project');
System.schedule('Project Remaining Forecast Batch Rollup', '0 35 3 ? * MON', newBatchRun);
 **/
public with sharing class TimeEntryRollupCalcBatchScheduler implements Schedulable{
    
    @TestVisible private String batchRollupObject;

    public TimeEntryRollupCalcBatchScheduler(String rollupObject) {
        batchRollupObject = rollupObject;
    }

    public void execute(SchedulableContext sc) {


        Integer batchSize;
        if(batchRollupObject == 'Project'){
            batchSize = 10;
        }else if(batchRollupObject == 'Timesheet'){
            batchSize = 50;
        }else if(batchRollupObject == 'Work Day'){
            batchSize = 300;
        }

        TimeEntryRollupCalcBatch newRollupBatch = new TimeEntryRollupCalcBatch(batchRollupObject, null);
        Database.executeBatch(newRollupBatch, batchSize);
    }
}