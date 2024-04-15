/**
 * Created 11/29/2022 ST To link existing Entries to Work Days
 * 
 * Called by LinkTimeEntriesToWorkDayBatch linkTimeToWorkDayBatch = new LinkTimeEntriesToWorkDayBatch();
        Database.executeBatch(linkTimeToWorkDayBatch, 50);
 */
public with sharing class LinkTimeEntriesToWorkDayBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    
    public LinkTimeEntriesToWorkDayBatch() {
        System.debug('**** LinkTimeEntriesToWorkDayBatch ****');
        
        QueryString = 'SELECT Id, Name, Employee__c, EntryDate__c, TotalHrs__c, Associated_Billing_Rate__c, Project__c, WeekEndDate__c, Replicon_Timesheet__c, Project__r.RepliconURI__c, Replicon_Project_URI__c, WorkDay__c'
                        + ' FROM Replicon_Time_Entry__c'
                        + ' WHERE Employee__c != null AND EntryDate__c != null AND Replicon_Timesheet__c != null AND WorkDay__c = null AND EntryDate__c = THIS_YEAR'
                        + ' ORDER BY Employee__c, EntryDate__c DESC'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** LinkTimeEntriesToWorkDayBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> entryList){
        System.debug('**** LinkTimeEntriesToWorkDayBatch EXECUTE ****');
        /**
         * Function Purpose: Link Time Entries to their respective Work Days
         */

        List<Id> employeeIdList = new List<Id>();
        List<Date> entryDateList = new List<Date>();

        for(Replicon_Time_Entry__c entry : entryList){
            employeeIdList.add(entry.Employee__c);
            entryDateList.add(entry.EntryDate__c);
        }

        List<WorkDay__c> existingWorkDayList = new List<WorkDay__c>();
        existingWorkDayList = [SELECT Id, Name, Employee__c, WorkDayDate__c, RepliconTimesheet__c
                                FROM WorkDay__c
                                WHERE Employee__c IN :employeeIdList AND WorkDayDate__c IN :entryDateList];

        Map<String, WorkDay__c> existingWorkDayMap = new Map<String, WorkDay__c>();
        for(WorkDay__c wd : existingWorkDayList){
            //Create unique Id map of existing Work Day records (Unique Id is Employee Record Id a+ the WorkDayDate)
            String uniqueId = String.valueOf(wd.Employee__c) + '|' + String.valueOf(wd.WorkDayDate__c);
            existingWorkDayMap.put(uniqueId, wd);
        }

        List<Replicon_Time_Entry__c> entryToUpdateWithWorkDayList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList){

            String uniqueId = String.valueOf(entry.Employee__c) + '|' + String.valueOf(entry.EntryDate__c);

            if(existingWorkDayMap.containsKey(uniqueId)){
                entry.WorkDay__c = existingWorkDayMap.get(uniqueId).Id;
                entryToUpdateWithWorkDayList.add(entry);
            }
        }

        if(entryToUpdateWithWorkDayList.size() > 0){
            System.debug('****************** Linking ' + entryToUpdateWithWorkDayList.size() + ' Time Entries with a Work Day *********************************');
            update entryToUpdateWithWorkDayList;
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** LinkTimeEntriesToWorkDayBatch FINISH ****');

    }
}