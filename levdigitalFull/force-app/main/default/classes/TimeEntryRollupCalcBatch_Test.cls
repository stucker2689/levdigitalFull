@isTest(SeeAllData=true)
public with sharing class TimeEntryRollupCalcBatch_Test {

    @isTest
    static void rollupProject_Test(){

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name FROM Project__c WHERE Project_Status__c = 'Active' LIMIT 10];

        Set<Id> projIdSet = new Set<Id>();
        for(Project__c proj : projList){
            projIdSet.add(proj.Id);
        }

        TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Project', projIdSet);
        System.enqueueJob(calcBatch);
    }

    @isTest
    static void rollupTimesheet_Test(){

        List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>();
        timesheetList = [SELECT Id, Name, Start_Date__c FROM Replicon_Timesheet__c WHERE Start_Date__c < TODAY AND Total_Billable_Hours__c > 0 ORDER BY Start_Date__c DESC LIMIT 50];

        Set<Id> timesheetIdSet = new Set<Id>();
        for(Replicon_Timesheet__c timesheet : timesheetList){
            timesheetIdSet.add(timesheet.Id);
        }

        TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Timesheet', timesheetIdSet);
        System.enqueueJob(calcBatch);
    }

    @isTest
    static void rollupWorkDay_Test(){

        List<WorkDay__c> workDayList = new List<WorkDay__c>();
        workDayList = [SELECT Id, Name, WorkDayDate__c FROM WorkDay__c WHERE WorkDayDate__c < TODAY AND TotalBillableHours__c > 0 ORDER BY WorkDayDate__c DESC LIMIT 300];

        Set<Id> workDayIdSet = new Set<Id>();
        for(WorkDay__c wd : workDayList){
            workDayIdSet.add(wd.Id);
        }

        TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Work Day', workDayIdSet);
        System.enqueueJob(calcBatch);
    }

}