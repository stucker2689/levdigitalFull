/**
 * Created By Sam Tucker 2/25/2022
 * Scheduler for the PHIStatusFlowBatch class that runs the Project PHI Status/History Flow in Batches
 */
public with sharing class PhiStatusFlowBatchScheduler implements Schedulable{
    public PhiStatusFlowBatchScheduler() {

    }
    
    public void execute (SchedulableContext ctx) {   

        PHIStatusFlowBatch newPHIBatchRun = new PHIStatusFlowBatch();
        Database.executeBatch(newPHIBatchRun, 50); 
    }
}