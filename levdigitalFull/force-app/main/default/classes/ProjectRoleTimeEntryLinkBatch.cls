/**
 * Created by Sam Tucker 5/11/2022
 * Purpose: To Associate Time Entries with their respective Project Role record
 *          Also will rollup the Total Hours/Amount Billed for the Project Role when the Time Entry gets updated
 * 
 * How to Run:
 * 
 * 
 * Apex:
 * //Calls this function to populate all Non-Deleted and Non-Time-Off Time Entries that don't already have the WeeklyTarget field populated for December (12) of 2021
        ProjectRoleTimeEntryLinkBatch newProjectRoleTimeEntryLinkBatch = new ProjectRoleTimeEntryLinkBatch(true, null);
        Database.executeBatch(newProjectRoleTimeEntryLinkBatch, 100); //Batch size (100) determines how many Time Entries to update at a time
 * 
 * 
 */
public with sharing class ProjectRoleTimeEntryLinkBatch implements Database.Batchable<sObject>, Schedulable{

    public final String QueryString;
    public List<Id> projectsWithProjectRolesIdList = new List<Id>();
    //private static String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);
    public List<Id> projIdList = new List<Id>();

    public void execute(SchedulableContext sc) {
        System.debug('ProjectRoleTimeEntryLinkBatch SCHEDULE');
        ProjectRoleTimeEntryLinkBatch batch = new ProjectRoleTimeEntryLinkBatch(true, null);
        Database.executeBatch(batch, 100);
    }
    
    //Allows this batch to run for all unmatched Time Entries or for only run it for a specific list of projects
    public ProjectRoleTimeEntryLinkBatch(Boolean runForAllTimeEntries, List<Id> projectIdList) {
        System.debug('**** ProjectRoleTimeEntryLinkBatch ****');

        if(runForAllTimeEntries){
            AggregateResult[] projectRoleAgg = [SELECT count(Id), Project__c
                                                FROM ProjectRole__c 
                                                WHERE Project__c != null 
                                                GROUP BY Project__c, Project__r.Name];
            
            for(AggregateResult ar : projectRoleAgg){
                projectsWithProjectRolesIdList.add((Id)ar.get('Project__c'));
            }
            
            QueryString = 'SELECT Id, Name, EntryDate__c, Billable_Amount__c, Deleted_in_Replicon__c, Is_Billable__c, Project__c, Employee__c, TotalHrs__c, Associated_Billing_Rate__c, ProjectRole__c, Replicon_User_Number__c, Employee__r.AccountId, Employee__r.Name, Employee__r.Account.Name, Is_Lev_Time__c'
                            + ' FROM Replicon_Time_Entry__c'
                            + ' WHERE Deleted_in_Replicon__c = false AND Time_Off__c = false AND Project__c != null AND Associated_Billing_Rate__c != null AND ProjectRole__c = null AND Project__c IN :projectsWithProjectRolesIdList'
                            + ' ORDER BY Project__c'; 
        }else{
            projIdList.addAll(projectIdList);
            System.debug('Proj Id List: ' + projIdList);

            QueryString = 'SELECT Id, Name, EntryDate__c, Billable_Amount__c, Deleted_in_Replicon__c, Is_Billable__c, Project__c, Employee__c, TotalHrs__c, Associated_Billing_Rate__c, ProjectRole__c, Replicon_User_Number__c, Employee__r.AccountId, Employee__r.Name, Employee__r.Account.Name, Is_Lev_Time__c'
                            + ' FROM Replicon_Time_Entry__c'
                            + ' WHERE Deleted_in_Replicon__c = false AND Time_Off__c = false AND Project__c != null AND Associated_Billing_Rate__c != null AND ProjectRole__c = null AND Project__c IN :projIdList'
                            + ' ORDER BY Project__c'; 

        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** ProjectRoleTimeEntryLinkBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> timeEntryList){
        System.debug('**** ProjectRoleTimeEntryLinkBatch EXECUTE ****');
        /**
         * Function Purpose: Execute the process of finding the proper Project Role to associate with the Time Entry and populate the ProjectRole__c field on the Time Entry
         */
        List<Replicon_Time_Entry__c> nonLevTimeEntryList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> levTimeEntryList = new List<Replicon_Time_Entry__c>();

        for(Replicon_Time_Entry__c entry : timeEntryList){
            if(((entry.EntryDate__c < switchToATGTimeDate && entry.Employee__r.Name != atgConsultantContactName) || (entry.EntryDate__c >= switchToATGTimeDate && entry.Employee__r.Account.Name == levementumAccountName && entry.Employee__r.Name != atgConsultantContactName))){
                levTimeEntryList.add(entry);
            }else{
                nonLevTimeEntryList.add(entry);
            }
            /*if(entry.Is_Lev_Time__c){
                levTimeEntryList.add(entry);
            }else{
                nonLevTimeEntryList.add(entry);
            }*/
        }

        if(levTimeEntryList.size() > 0){
            System.debug('Lev timeEntryList Size: ' + levTimeEntryList.size());
            RepliconTimeEntryTriggerHelper.linkTimeEntryToProjectRoleRecord(levTimeEntryList, true, false);
        }

        if(nonLevTimeEntryList.size() > 0){
            System.debug('Non-Lev timeEntryList Size: ' + nonLevTimeEntryList.size());
            RepliconTimeEntryTriggerHelper.linkTimeEntryToProjectRoleRecord(nonLevTimeEntryList, true, true);
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** ProjectRoleTimeEntryLinkBatch FINISH ****');

    }
}