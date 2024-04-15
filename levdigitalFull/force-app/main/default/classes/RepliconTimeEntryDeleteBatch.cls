/*********************************************
 * Created By: Sam Tucker 5/11/2021
 */

global class RepliconTimeEntryDeleteBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    List<Replicon_Time_Entry__c> inputList;
    Integer monthsBackRequested;
    Integer monthsBack;
	Date startingDate;
    
    //This class pulls timeEntries for all employees with a weekendDate of a previous month. If weeksToGoBack is greater than 1,
    //then batch jobs will chain after they finish until the number of weeks is met 
    public RepliconTimeEntryDeleteBatch(Date startDate, Integer monthsToGoBack, Integer currentMonthsBack) {
        Date dateToSearchBackTo;
        Integer addMonthsInteger;
        addMonthsInteger = -1 * monthsToGoBack;
        dateToSearchBackTo = startDate.addMonths(addMonthsInteger);
        Date firstDayOfMonthToGoBack = date.newInstance(dateToSearchBackTo.year(), dateToSearchBackTo.month(), 1); 

        inputList = [SELECT Id, WeekEndDate__c 
                    FROM Replicon_Time_Entry__c 
                    WHERE Deleted_in_Replicon__c = true AND WeekEndDate__c >= :firstDayOfMonthToGoBack
                    LIMIT 30000];

        monthsBackRequested = monthsToGoBack;
        monthsBack = currentMonthsBack;
        startingDate = startDate;
    }
    
    global sObject[] start(Database.BatchableContext BC) {
        return inputList;
    }
    
    global void execute(Database.BatchableContext bc, List<Replicon_Time_Entry__c> records){
        //Calculate date of current batch. This is meant to go backwards a certain number of weeks from a certain date.
        Date currentBatchDate;
        Integer monthsToSubtract = -1 * monthsBack;
        currentBatchDate = startingDate.addMonths(monthsToSubtract);

        //Pull IDs from Time Entries
        DeleteRepliconTimeEntries newDeleteService = new DeleteRepliconTimeEntries();
        List<Id> timeEntryIds = new List<Id>();
        for(Replicon_Time_Entry__c currentEntry : records) {
            if((currentEntry.WeekEndDate__c.month() == currentBatchDate.month()) && 
                (currentEntry.WeekEndDate__c.year() == currentBatchDate.year())){
                timeEntryIds.add(currentEntry.Id);
            }
        }
        if(timeEntryIds.size() > 0){
            System.debug('*******CURRENT BATCH SIZE IS: ' + timeEntryIds.size() + ' *********');
        }
        //Call main method
        if(!Test.isRunningTest()) { DeleteRepliconTimeEntries.getTimeEntriesToDelete(currentBatchDate, timeEntryIds); }
    }
    
    global void finish(Database.BatchableContext bc){
        monthsBack++;
        if(monthsBack <= monthsBackRequested || Test.isRunningTest()) {
            RepliconTimeEntryDeleteBatch newChainBatch = new RepliconTimeEntryDeleteBatch(startingDate, monthsBackRequested, monthsBack);
            if(!Test.isRunningTest()) { Database.executeBatch(newChainBatch, 200); }
        }
    }
}