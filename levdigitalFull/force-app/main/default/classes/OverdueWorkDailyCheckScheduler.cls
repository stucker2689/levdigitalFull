/**
 * Created by ST 1/25/2023
 * Purpose: To Run the Overdue Work Record Flow on a scheduled basis and to have the Chatter posts that get posted by the flow to be set as the User that calls the Schedulable function.
 * 
 * Schedulable Apex run to run this code at 5:15 AM Daily:
 * 
    OverdueWorkDailyCheckScheduler overdueWorkCheck = new OverdueWorkDailyCheckScheduler();
    System.schedule('Daily Overdue Work Assignment Chatter Post', '0 15 5 ? * *', overdueWorkCheck);
 */
// Can implement Database.Batchable<sObject> if we expect a large amount of overdue work assignments each daily run
public with sharing class OverdueWorkDailyCheckScheduler implements Schedulable{


    public final String QueryString;

    public OverdueWorkDailyCheckScheduler() {
        System.debug('**** OverdueWorkDailyCheckScheduler ****');
            
        /*QueryString = 'SELECT Id, Name, Days_Over_Due__c, dat_DueDate__c, Milestone__c, Milestone__r.Name, lkp_Project__c, lkp_Project__r.Name, pkl_Status__c, Order__c, RecordTypeId, RecordType.Name, LastModifiedDate, LastModifiedBy.Name, CreatedDate, CreatedBy.Name, Owner.Name, OwnerId'
                        + ' FROM Work__c'
                        + ' WHERE Days_Over_Due__c = 1 AND pkl_Status__c NOT IN (\'Completed\', \'Cancelled\') AND RecordTypeId IN (\'0120W000002AOyoQAG\', \'0120W000001pS9WQAU\')';
                        + ' ORDER BY Milestone__c, Order__c'; */
      
    }

    public void execute(SchedulableContext sc) {
        System.debug('OverdueWorkDailyCheckScheduler SCHEDULE');
        Map<String, Object> myMap = new Map<String, Object>();
        Flow.Interview.Overdue_Work_Daily_Check_AUTO overdueWorkCheckRun = new Flow.Interview.Overdue_Work_Daily_Check_AUTO(myMap);
        overdueWorkCheckRun.start();
    }

    /*public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** OverdueWorkDailyCheckScheduler START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> timeEntryList){
        System.debug('**** OverdueWorkDailyCheckScheduler EXECUTE ****');
        //Function Purpose: Execute the process of finding the proper Project Role to associate with the Time Entry and populate the ProjectRole__c field on the Time Entry

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** ProjectRoleTimeEntryLinkBatch FINISH ****');

    }*/
}