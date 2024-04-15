global class RepliconTimeEntryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    List<Contact> inputList;
    Integer weeksBackRequested;
    Integer weeksBack;
	Date startingDate;
    
    //This class pulls timesheet data for all employees on a specific date. If weeksToGoBack is greater than 1,
    //then batch jobs will chain after they finish until the number of weeks is met 
    public RepliconTimeEntryBatch(Date startDate, Integer weeksToGoBack, Integer currentWeeksBack) {
        inputList = [SELECT Id FROM Contact WHERE RecordType.Name = 'Employee' AND Replicon_User_Number__c != NULL AND Active__c = true];
        weeksBackRequested = weeksToGoBack; //-3
        weeksBack = currentWeeksBack; //0
        startingDate = startDate;
    }
    
    global sObject[] start(Database.BatchableContext BC) {
        return inputList;
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> records){
        
        //Calculate date of current batch. This is meant to go backwards a certain number of weeks from a certain date.
        Date currentBatchDate;
        //if(weeksBack > 0) {
            Integer daysToSubtract = -7 * weeksBack;
            currentBatchDate = startingDate.addDays(daysToSubtract);
        //}
        //else {
        //    currentBatchDate = startingDate;
        //}
        
        //Pull IDs from employee contacts
        RepliconService newService = new RepliconService();
		List<Id> employeeIdList = new List<Id>();
        for(Contact currentContact : records) {
            employeeIdList.add(currentContact.Id);
        }

        //Call main method
        if(!Test.isRunningTest()) {
            BatchResource.setRepliconTimeEntryBatchAsRunning(); 
            newService.getTimesheetEntries(currentBatchDate, employeeIdList); 
        }

        Set<Id> projectIdRollupSet = new Set<Id>();
        projectIdRollupSet = BatchResource.getProjectUpdateSet();
        System.debug('Batch Resource Project Id Set Size: ' + projectIdRollupSet.size());
        if(projectIdRollupSet.size() > 0){
            System.enqueueJob(new ProjectRollupCalcQueueable(projectIdRollupSet));
        }
    }
    
    global void finish(Database.BatchableContext bc){
        if(weeksBackRequested >= 0){
            weeksBack++;//1
            
            if(weeksBack < weeksBackRequested || Test.isRunningTest()) {
                //Integer currentApexJobs = [SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')];
                //if (currentApexJobs < 5 || Test.isRunningTest()) { 
                    RepliconTimeEntryBatch newChainBatch = new RepliconTimeEntryBatch(startingDate, weeksBackRequested, weeksBack);
                    //Changed from 20 to 10
                    if(!Test.isRunningTest()) { Database.executeBatch(newChainBatch, 5); }
                //}
                //if(currentApexJobs >= 5 || Test.isRunningTest()) {
                //    RepliconTimeEntryBatch newChainBatch = new RepliconTimeEntryBatch(inputList, startingDate, weeksBackRequested, weeksBack);
                //    if(!Test.isRunningTest()) { System.ScheduleBatch(newChainBatch, 'Chained Time Entry Job', 15); }
                //}
            }
        }
    }
}