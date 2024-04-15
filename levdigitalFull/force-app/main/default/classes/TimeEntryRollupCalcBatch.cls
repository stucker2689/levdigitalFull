/**
TimeEntryRollupCalcBatch newBatchRun = new TimeEntryRollupCalcBatch('Project', null);
System.schedule('Project Remaining Forecast Batch Rollup', '0 35 3 ? * MON', newBatchRun);
 **/

public class TimeEntryRollupCalcBatch implements Queueable, Database.Batchable<SObject>{
    
    public final String QueryString;
    private String batchRollupObject;
    private Set<Id> batchRollupIdSet;
    
    public TimeEntryRollupCalcBatch(String rollupObject, Set<Id> objectIdsToRollupSet) {

        batchRollupObject = rollupObject;
        batchRollupIdSet = objectIdsToRollupSet;

        if(batchRollupObject == 'Project'){
            if(batchRollupIdSet == null){
                QueryString = 'SELECT Id, Name FROM Project__c WHERE LastModifiedDate >= LAST_YEAR';
            }else{
                QueryString = 'SELECT Id, Name FROM Project__c WHERE Id IN :batchRollupIdSet';
            }
            
        }else if(batchRollupObject == 'Timesheet'){
            if(batchRollupIdSet == null){
                QueryString = 'SELECT Id, Name FROM Replicon_Timesheet__c';
            }else{
                QueryString = 'SELECT Id, Name FROM Replicon_Timesheet__c WHERE Id IN :batchRollupIdSet';
            }

        }else if(batchRollupObject == 'Work Day'){
            if(batchRollupIdSet == null){
                QueryString = 'SELECT Id, Name FROM WorkDay__c';
            }else{
                QueryString = 'SELECT Id, Name FROM WorkDay__c WHERE Id IN :batchRollupIdSet';
            }

        }
    }

    /*public void execute(SchedulableContext sc) {
        Integer batchSize;
        if(batchRollupObject == 'Project'){
            batchSize = 10;
        }else if(batchRollupObject == 'Timesheet'){
            batchSize = 50;
        }else if(batchRollupObject == 'Work Day'){
            batchSize = 300;
        }

        TimeEntryRollupCalcBatch newRollupBatch = new TimeEntryRollupCalcBatch(batchRollupObject, batchRollupIdSet);
        Database.executeBatch(newRollupBatch, batchSize);
    }*/

    public void execute(System.QueueableContext qc){ //Queueable Method
        Integer batchSize;
        if(batchRollupObject == 'Project'){
            batchSize = 10;
        }else if(batchRollupObject == 'Timesheet'){
            batchSize = 50;
        }else if(batchRollupObject == 'Work Day'){
            batchSize = 300;
        }
        TimeEntryRollupCalcBatch newRollupBatch = new TimeEntryRollupCalcBatch(batchRollupObject, batchRollupIdSet);
        Database.executeBatch(newRollupBatch, batchSize);
        System.debug('batch started');
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** TimeEntryRollupCalcBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> rollupObjectList){
        System.debug('*************** TimeEntryRollupCalcBatch EXECUTE ***************');

        Set<Id> rollupIdSet = new Set<Id>();
        if(batchRollupObject == 'Project'){
            for(sObject obj : rollupObjectList){
                Project__c proj = (Project__c)obj;
                rollupIdSet.add(proj.Id);
            }

            System.debug('Rolling up ' + rollupIdSet.size() + ' Projects');
            TimeEntryRollupManager.calculateProjectRollupValues(rollupIdSet);
            
        }else if(batchRollupObject == 'Timesheet'){
            for(sObject obj : rollupObjectList){
                Replicon_Timesheet__c timesheet = (Replicon_Timesheet__c)obj;
                rollupIdSet.add(timesheet.Id);
            }

            System.debug('Rolling up ' + rollupIdSet.size() + ' Timesheets');
            TimeEntryRollupManager.calculateTimesheetRollupValues(rollupIdSet);

        }else if(batchRollupObject == 'Work Day'){
            for(sObject obj : rollupObjectList){
                WorkDay__c wd = (WorkDay__c)obj;
                rollupIdSet.add(wd.Id);
            }
            System.debug('Rolling up ' + rollupIdSet.size() + ' Work Days');
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(rollupIdSet);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** TimeEntryRollupCalcBatch FINISH ***************');

    }
}