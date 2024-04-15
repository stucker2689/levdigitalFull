/**
 * Created 9/19/2022 ST To link existing Timesheets to new Capacity Records
 * 
 * Called by:
 * 
 * Get all the Start Dates of 2022
 
 List<Date> weekStartDateList = new List<Date>();
 Date firstStartDate = Date.newInstance(2021, 12, 26);

 weekStartDateList.add(firstStartDate);
 Date iterationWeekStartDate = firstStartDate;
 for(Integer i = 0; i < 52; i++){
    iterationWeekStartDate = iterationWeekStartDate.addDays(7);
    weekStartDateList.add(iterationWeekStartDate);
 }


 PopulateTimesheetContactDetailsBatch newBatch = new PopulateTimesheetContactDetailsBatch(weekStartDateList);
 Database.executeBatch(newBatch, 100);

 
 */
public with sharing class PopulateTimesheetContactDetailsBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    public List<Date> weekStartDateList = new List<Date>();
    
    public PopulateTimesheetContactDetailsBatch(List<Date> weekStartDates) {
        System.debug('**** PopulateTimesheetContactDetailsBatch ****');
        weekStartDateList.addAll(weekStartDates);
        
        QueryString = 'SELECT Id, Name, Capacity__c, Employee__c, Employee__r.Name, Start_Date__c, End_Date__c, EmployeeDepartment__c, EmployeeTitle__c, EmployeeDivision__c, EmployeesManager__c, Employee__r.Title, Employee__r.Division_New__c, Employee__r.ReportsToId, Employee__r.Department'
                        + ' FROM Replicon_Timesheet__c'
                        + ' WHERE Start_Date__c IN :weekStartDateList'
                        + ' ORDER BY Start_Date__c DESC';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
            System.debug('**** PopulateTimesheetContactDetailsBatch START ****');
            return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Timesheet__c> timesheetList){
        System.debug('**** PopulateTimesheetContactDetailsBatch EXECUTE ****');
        /**
         * Function Purpose: Populate Employee Division, Title, and Manager on Timesheets
         */

        List<Replicon_Timesheet__c> updateTimesheetList = new List<Replicon_Timesheet__c>();

        for(Replicon_Timesheet__c timesheet : timesheetList){
            Boolean needsUpdate = false;

            if(timesheet.Employee__r.Title != null && timesheet.EmployeeTitle__c != timesheet.Employee__r.Title){
                timesheet.EmployeeTitle__c = timesheet.Employee__r.Title;
                needsUpdate = true;
            }

            if(timesheet.Employee__r.Division_New__c != null && timesheet.EmployeeDivision__c != timesheet.Employee__r.Division_New__c){
                timesheet.EmployeeDivision__c = timesheet.Employee__r.Division_New__c;
                needsUpdate = true;
            }

            if(timesheet.Employee__r.ReportsToId != null && timesheet.EmployeesManager__c != timesheet.Employee__r.ReportsToId){
                timesheet.EmployeesManager__c = timesheet.Employee__r.ReportsToId;
                needsUpdate = true;
            }

            if(timesheet.Employee__r.Department != null && timesheet.EmployeeDepartment__c != timesheet.Employee__r.Department){
                timesheet.EmployeeDepartment__c = timesheet.Employee__r.Department;
                needsUpdate = true;
            }

            if(needsUpdate){
                updateTimesheetList.add(timesheet);
            }

        }
        
        if(updateTimesheetList.size() > 0){
            update updateTimesheetList;
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** PopulateTimesheetContactDetailsBatch FINISH ****');

    }
}