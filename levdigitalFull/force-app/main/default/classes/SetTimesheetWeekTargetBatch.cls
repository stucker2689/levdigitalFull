/**
 * Created 9/19/2022 ST To link existing Timesheets to new Capacity Records
 * 
 * Called by SetTimesheetWeekTargetBatch setTimesheetTargetBatch = new SetTimesheetWeekTargetBatch();
        Database.executeBatch(setTimesheetTargetBatch, 100); //Batch size (100) determines how many Time Entries to update at a time
 */
public with sharing class SetTimesheetWeekTargetBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    
    public SetTimesheetWeekTargetBatch() {
        System.debug('**** SetTimesheetWeekTargetBatch ****');
        
        QueryString = 'SELECT Id, Name, Capacity__c, Employee__c, Employee__r.Name, Start_Date__c, End_Date__c, Target__c, Employee__r.Weekly_Target__c, Is_Lev_Timesheet__c, Employee__r.RampTime__c, Employee__r.Ramp_End_Date__c, Employee__r.Active__c, Employee__r.Term_Date__c'
                        + ' FROM Replicon_Timesheet__c'
                        + ' WHERE (Start_Date__c = THIS_YEAR OR End_Date__c = THIS_YEAR) AND Employee__r.Weekly_Target__c != null AND Employee__r.Weekly_Target__c != 0'
                        + ' ORDER BY Start_Date__c DESC'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
            System.debug('**** SetTimesheetWeekTargetBatch START ****');
            return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Timesheet__c> timesheetList){
        System.debug('**** SetTimesheetWeekTargetBatch EXECUTE ****');
        /**
         * Function Purpose: Set the Week Target for Timesheets
         */

        List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();

        for(Replicon_Timesheet__c timesheet : timesheetList){

            Decimal timesheetExpectedHours;
            //Only Calculate Week Target on Timesheet if the Employee is Active OR if the Employee is not active then only calculate timesheet target if the timesheet was before their termination date
            if(timesheet.Employee__r.Active__c == true || (timesheet.Employee__r.Term_Date__c != null && timesheet.Employee__r.Active__c == false && timesheet.Start_Date__c < timesheet.Employee__r.Term_Date__c)){

                //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                if(timesheet.Employee__r.Weekly_Target__c != null && timesheet.Employee__r.RampTime__c != null && timesheet.Employee__r.Ramp_End_Date__c != null && timesheet.Start_Date__c != null){
                    timesheetExpectedHours = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(timesheet.Employee__r.Weekly_Target__c, timesheet.Employee__r.RampTime__c, timesheet.Employee__r.Ramp_End_Date__c, timesheet.Start_Date__c);

                //If the Ramp fields are not populated then just populate the expected Hours with the weekly Target if populated
                }else if(timesheet.Employee__r.Weekly_Target__c != null){
                    timesheetExpectedHours = timesheet.Employee__r.Weekly_Target__c;

                //If Weekly Target is not populated then set Expected hours to 0
                }else{
                    timesheetExpectedHours = 0;
                }
            //If Timesheet is for an inactive employee and the timesheet is after the related Employee's Termination date then set the expected hours to 0
            }else{
                timesheetExpectedHours = 0;
            }

            //If expected hours is not already equal to the timesheets existing expected hours then set it and add it to update list.
            if(timesheet.Target__c != timesheetExpectedHours){
                timesheet.Target__c = timesheetExpectedHours;
                timesheetUpdateList.add(timesheet);
            }
        }

        if(timesheetUpdateList.size() > 0){
            update timesheetUpdateList;
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** SetTimesheetWeekTargetBatch FINISH ****');

    }
}