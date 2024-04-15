global class RepliconTimeEntryBatchScheduler implements Schedulable {
    
    private integer weeksBack;
    private integer currentWeek;
    private List<Contact> employeeList;
    
    //For starting a new chained batch
    global RepliconTimeEntryBatchScheduler(Integer weeksToGoBack) {
        weeksBack = weeksToGoBack;
        currentWeek = 0;
    }
    
    //For continuing a chained batch that needed to reschedule due to too many concurrent jobs
    global RepliconTimeEntryBatchScheduler(List<Contact> inputContactList, Integer weeksToGoBack, Integer week) {
        weeksBack = weeksToGoBack;
        currentWeek = week;
    }
    
    global void execute (SchedulableContext ctx) {
        
        //Integer currentApexJobs = [SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')];
        
        //if (currentApexJobs < 5 || Test.isRunningTest()) {
            RepliconTimeEntryBatch newTimeEntryBatch = new RepliconTimeEntryBatch(System.Today(), weeksBack, currentWeek);
            //Changed from 20 to 10
            if(!Test.isRunningTest()) { Database.executeBatch(newTimeEntryBatch, 2); }
        //}
        
        //if(currentApexJobs >= 5 || Test.isRunningTest()) {
        //    RepliconTimeEntryBatchScheduler newSchedulableInstance = new RepliconTimeEntryBatchScheduler(employeeList, weeksBack, currentWeek);
        //    Datetime newDatetime = Datetime.now().addMinutes(15);
        //    String CRONString = newDatetime.format('s m H d M \'?\' yyyy');
        //    if(!Test.isRunningTest()) { Id schedId = System.Schedule('RepliconTimeEntryRetry' + CRONString, CRONString, newSchedulableInstance); }
        //}
    }
}