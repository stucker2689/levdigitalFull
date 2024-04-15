/*********************************************
 * Created By: Sam Tucker 4/4/2022
 * Changed to delete all Deleted Time Entries
TimeEntryDeleteBatch newDeleteBatch = new TimeEntryDeleteBatch();
Database.executeBatch(newDeleteBatch, 1000);  
*/

global class TimeEntryDeleteBatch implements Database.Batchable<sObject>, Schedulable {

    public final String QueryString;

    public void execute (SchedulableContext ctx) {   

        TimeEntryDeleteBatch newDeleteBatch = new TimeEntryDeleteBatch();
        Database.executeBatch(newDeleteBatch, 1000); 
    }


    public TimeEntryDeleteBatch() {

        QueryString = 'SELECT Id, WeekEndDate__c, Deleted_in_Replicon__c, Project__c FROM Replicon_Time_Entry__c WHERE Deleted_in_Replicon__c = true ORDER BY Project__c, WeekEndDate__c';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** TimeEntryDeleteBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Replicon_Time_Entry__c> timeEntrysToBeDeleted){
        System.debug('*************** TimeEntryDeleteBatch EXECUTE ***************');

        if(timeEntrysToBeDeleted.size() > 0){
            System.debug('*******CURRENT BATCH SIZE IS: ' + timeEntrysToBeDeleted.size() + ' *********');
            delete timeEntrysToBeDeleted;
        }
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('*************** TimeEntryDeleteBatch FINISH ***************');

    }
}