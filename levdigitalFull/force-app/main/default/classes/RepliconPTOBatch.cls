/**
 * Created By ST 5/4/2022
 * 
 */
global class RepliconPTOBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    List<Contact> inputList;
    Integer weeksBackRequested;
    Integer weeksBack;
	Date startingDate;
    
    //This class pulls timesheet data for all employees on a specific date. If weeksToGoBack is greater than 1,
    //then batch jobs will chain after they finish until the number of weeks is met 
    public RepliconPTOBatch(Date startDate, Integer weeksToGoBack, Integer currentWeeksBack) {
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
        Integer daysToSubtract = -7 * weeksBack;
        currentBatchDate = startingDate.addDays(daysToSubtract);
            
        //Pull IDs from employee contacts
        RepliconService newService = new RepliconService();
		List<Id> employeeIdList = new List<Id>();
        for(Contact currentContact : records) {
            employeeIdList.add(currentContact.Id);
        }

        //Call main method
        if(!Test.isRunningTest()) { newService.getTimesheetEntries(currentBatchDate, employeeIdList); }
    }
    
    global void finish(Database.BatchableContext bc){
        if(weeksBackRequested >= 0){
            
        }else{
            weeksBack--;
            
            if(weeksBack > weeksBackRequested || Test.isRunningTest()) {
                    RepliconPTOBatch newChainBatch = new RepliconPTOBatch(startingDate, weeksBackRequested, weeksBack);
                    //Changed from 20 to 10
                    if(!Test.isRunningTest()) { Database.executeBatch(newChainBatch, 5); }
            }
        }
    }
}