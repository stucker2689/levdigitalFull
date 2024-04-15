/*********************************************
 * Created By: Sam Tucker 9/22/2022
 * Purpose: Used to delete existing Timesheets that have been created for Inactive Employees
 * 
DeleteInactiveEmployeeTimesheetsBatch newDeleteBatch = new DeleteInactiveEmployeeTimesheetsBatch();
Database.executeBatch(newDeleteBatch, 1000);  
*/

public with sharing class DeleteInactiveEmployeeTimesheetsBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    
    public DeleteInactiveEmployeeTimesheetsBatch() {
        System.debug('**** DeleteInactiveEmployeeTimesheetsBatch ****');
        
        QueryString = 'SELECT Id, Name, Employee__c, Employee__r.Name, Employee__r.Active__c, Employee__r.Term_Date__c, Employee__r.Replicon_User_Number__c, Start_Date__c, End_Date__c, Total_Billable_Hours__c, Total_Time_Off_Hours__c'
                        + ' FROM Replicon_Timesheet__c'
                        + ' WHERE Employee__c != null AND Employee__r.Active__c = false AND Employee__r.Term_Date__c != null AND (Total_Billable_Hours__c = null OR Total_Billable_Hours__c = 0)'
                        + ' ORDER BY Employee__c, Start_Date__c DESC'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
            System.debug('**** DeleteInactiveEmployeeTimesheetsBatch START ****');
            return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Timesheet__c> timesheetList){
        System.debug('**** DeleteInactiveEmployeeTimesheetsBatch EXECUTE ****');
        /**
         * Function Purpose: Set the Week Target for Timesheets
         */

        Map<Id, Replicon_Timesheet__c> timesheetToDeleteMap = new Map<Id, Replicon_Timesheet__c>();
        for(Replicon_Timesheet__c timesheet : timesheetList){
            if(timesheet.Start_Date__c > timesheet.Employee__r.Term_Date__c){
                if(timesheet.Total_Billable_Hours__c == null || timesheet.Total_Billable_Hours__c == 0){                    
                    timesheetToDeleteMap.put(timesheet.Id, timesheet);
                    
                }
            }            
        }

        if(timesheetToDeleteMap.size() > 0){
        
            List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
            entryList = [SELECT Id, Name, Employee__c, Employee__r.Name, Project__c, Project__r.Name, WeekEndDate__c, EntryDate__c, 
                            TotalHrs__c, Replicon_Timesheet__c, Deleted_in_Replicon__c, Time_Off__c 
                         FROM Replicon_Time_Entry__c
                         WHERE Replicon_Timesheet__c IN :timesheetToDeleteMap.keySet() AND Deleted_in_Replicon__c = false];
            
            List<Replicon_Time_Entry__c> entriesToDeleteList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                entry.Deleted_in_Replicon__c = true;
                entriesToDeleteList.add(entry);
            }
            
            if(entriesToDeleteList.size() > 0){
                update entriesToDeleteList;
            }
        
            delete timesheetToDeleteMap.values();
        }        
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** DeleteInactiveEmployeeTimesheetsBatch FINISH ****');

    }
}