/**
 * Created 9/19/2022 ST To link existing Timesheets to new Capacity Records
 * 
 * Called by LinkTimesheetsToCapacityBatch newTimesheetToCapacityMatchBatch = new LinkTimesheetsToCapacityBatch(List of Saturdays);
        Database.executeBatch(newTimesheetToCapacityMatchBatch, 100); //Batch size (100) determines how many Time Entries to update at a time
 */
public with sharing class LinkTimesheetsToCapacityBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    public List<Date> weekStartDateList = new List<Date>();
    
    public LinkTimesheetsToCapacityBatch(List<Date> weekStartDates) {
        System.debug('**** LinkTimesheetsToCapacityBatch ****');
        weekStartDateList.addAll(weekStartDates);
        
        QueryString = 'SELECT Id, Name, Capacity__c, Employee__c, Employee__r.Name, Start_Date__c, End_Date__c, Total_Billable_Hours__c, SubmissionDate__c, LateSubmission__c, Target__c, Employee__r.Weekly_Target__c, Is_Lev_Timesheet__c'
                        + ' FROM Replicon_Timesheet__c'
                        + ' WHERE Start_Date__c IN :weekStartDateList'
                        + ' ORDER BY Start_Date__c DESC';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
            System.debug('**** LinkTimesheetsToCapacityBatch START ****');
            return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Timesheet__c> timesheetList){
        System.debug('**** LinkTimesheetsToCapacityBatch EXECUTE ****');
        /**
         * Function Purpose: Link Existing Timesheets to their respective Capacity Records
         */

        RepliconTimesheetTriggerHelper.populateCapacityOnTimesheet(timesheetList, true);

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** LinkTimesheetsToCapacityBatch FINISH ****');

    }
}