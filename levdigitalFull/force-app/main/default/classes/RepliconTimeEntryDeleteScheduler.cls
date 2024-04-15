/*********************************************
 * Created By: Sam Tucker 5/11/2021
 */

global class RepliconTimeEntryDeleteScheduler implements Schedulable {
    private integer monthsBack;
    private integer currentMonth;
    private List<Replicon_Time_Entry__c> timeEntryList;
    
    //For starting a new chained batch
    global RepliconTimeEntryDeleteScheduler(Integer monthsToGoBack) {
        monthsBack = monthsToGoBack;
        currentMonth = 1;
    }
    
    //For continuing a chained batch that needed to reschedule due to too many concurrent jobs
    global RepliconTimeEntryDeleteScheduler(List<Replicon_Time_Entry__c> inputTimeEntryList, Integer monthsToGoBack, Integer month) {
        monthsBack = monthsToGoBack;
        currentMonth = month;
    }
    
    global void execute (SchedulableContext ctx) {
            RepliconTimeEntryDeleteBatch newTimeEntryToDeleteBatch = new RepliconTimeEntryDeleteBatch(System.Today(), monthsBack, currentMonth);
            if(!Test.isRunningTest()) { Database.executeBatch(newTimeEntryToDeleteBatch, 200); }
    }
}