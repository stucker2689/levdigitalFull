global class RepliconPTOBatchScheduler implements Schedulable {
    
    private integer weeksBack;
    private integer currentWeek;
    private List<Contact> employeeList;
    
    //For starting a new chained batch
    global RepliconPTOBatchScheduler(Integer weeksToGoBack) {
        weeksBack = weeksToGoBack;
        currentWeek = 0;
    }
    
    //For continuing a chained batch that needed to reschedule due to too many concurrent jobs
    global RepliconPTOBatchScheduler(List<Contact> inputContactList, Integer weeksToGoBack, Integer week) {
        weeksBack = weeksToGoBack;
        currentWeek = week;
    }
    
    global void execute (SchedulableContext ctx) {
        
        //if (currentApexJobs < 5 || Test.isRunningTest()) {
            RepliconPTOBatch newPTOBatch = new RepliconPTOBatch(System.Today(), weeksBack, currentWeek);
            //Changed from 20 to 10 to 5
            if(!Test.isRunningTest()) { Database.executeBatch(newPTOBatch, 5); }
    }
}