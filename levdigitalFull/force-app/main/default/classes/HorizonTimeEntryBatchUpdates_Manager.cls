public with sharing class HorizonTimeEntryBatchUpdates_Manager implements Database.Batchable<sObject>{
    public final String QueryString;
    public final Boolean forceUpdate;
    public final List<Id> projectIdList;

    public HorizonTimeEntryBatchUpdates_Manager(Boolean forceUpdateEntries, List<Id> projIdList) {
        
        forceUpdate = forceUpdateEntries;

        if(projIdList != null && projIdList.size() > 0){
            projectIdList = projIdList;
            QueryString = 'SELECT Id, Name, Account__c, ActivityName__c, Associated_Billing_Rate__c, Associated_Billing_Rate_Text__c, Associated_Billing_Rate__r.Name, Billable_Amount__c, Billing_Action__c, Billing_Rate__c, '
            + 'Cognizant_Employee_Id__c, Comments__c, Deleted_in_Replicon__c, Employee__c, Employee__r.Cognizant_Employee_Id__c, EntryDate__c, ForceUpdateCheckbox__c, Internal_Project_Team_Member__c, '
            + 'Is_Billable__c, Is_Concession__c, Is_Lev_Time__c, Opportunity__c, Peoplesoft_Project_Id__c, Project__c, Project__r.Peoplesoft_Project_Id__c, ProjectRole__c, RelatedNonbillOrConcessionCase__c, Replicon_Forecast__c, '
            + 'Replicon_Timesheet__c, Submission_Date__c, Time_Off__c, Time_Off_Description__c, Timesheet_Status__c, TotalHrs__c, Type__c, Unique_Time_Entry_Id__c, WeekEndDate__c, WeeklyTarget__c, WorkDay__c, Replicon_Billing_Rate_URI__c '
            + 'FROM Replicon_Time_Entry__c '
            + 'WHERE Project__c != null AND Employee__c != null AND Project__c IN :projectIdList '
            + 'ORDER BY Employee__c, EntryDate__c';
        }else{
            QueryString = 'SELECT Id, Name, Account__c, ActivityName__c, Associated_Billing_Rate__c, Associated_Billing_Rate_Text__c, Associated_Billing_Rate__r.Name, Billable_Amount__c, Billing_Action__c, Billing_Rate__c, '
            + 'Cognizant_Employee_Id__c, Comments__c, Deleted_in_Replicon__c, Employee__c, Employee__r.Cognizant_Employee_Id__c, EntryDate__c, ForceUpdateCheckbox__c, Internal_Project_Team_Member__c, '
            + 'Is_Billable__c, Is_Concession__c, Is_Lev_Time__c, Opportunity__c, Peoplesoft_Project_Id__c, Project__c, Project__r.Peoplesoft_Project_Id__c, ProjectRole__c, RelatedNonbillOrConcessionCase__c, Replicon_Forecast__c, '
            + 'Replicon_Timesheet__c, Submission_Date__c, Time_Off__c, Time_Off_Description__c, Timesheet_Status__c, TotalHrs__c, Type__c, Unique_Time_Entry_Id__c, WeekEndDate__c, WeeklyTarget__c, WorkDay__c, Replicon_Billing_Rate_URI__c '
            + 'FROM Replicon_Time_Entry__c '
            + 'WHERE Project__c != null AND Employee__c != null AND Project__r.Project_Status__c IN (\'Active\', \'On Hold\', \'Not Started\') '
            + 'ORDER BY Employee__c, EntryDate__c';
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** HorizonTimeEntryBatchUpdates_Manager START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<Replicon_Time_Entry__c> entryList){
        System.debug('*************** HorizonTimeEntryBatchUpdates_Manager EXECUTE ***************');
        
        List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList){

            Boolean needsUpdate = false;

            if(entry.Peoplesoft_Project_Id__c != entry.Project__r.Peoplesoft_Project_Id__c){
                entry.Peoplesoft_Project_Id__c = entry.Project__r.Peoplesoft_Project_Id__c;
                needsUpdate = true;
            }

            if(entry.Cognizant_Employee_Id__c != entry.Employee__r.Cognizant_Employee_Id__c){
                entry.Cognizant_Employee_Id__c = entry.Employee__r.Cognizant_Employee_Id__c;
                needsUpdate = true;
            }

            if(entry.Associated_Billing_Rate__r.Name == 'Concession' && entry.Is_Concession__c == false){
                entry.Is_Concession__c = true;
                needsUpdate = true;
            }

            if(entry.Replicon_Billing_Rate_URI__c != null && entry.Billing_Action__c != 'B'){
                entry.Billing_Action__c = 'B';
                needsUpdate = true;
            }else if(entry.Replicon_Billing_Rate_URI__c == null && entry.Billing_Action__c != 'U'){
                entry.Billing_Action__c = 'U';
                needsUpdate = true;
            }

            if(forceUpdate == true){
                entry.ForceUpdateCheckbox__c = !entry.ForceUpdateCheckbox__c;
                needsUpdate = true;
            }

            if(needsUpdate){
                entryUpdateList.add(entry);
            }
        }

        if(entryUpdateList.size() > 0){
            System.debug('***************************************** Updating ' + entryUpdateList.size() + ' Time Entries from Batch Update Code *****************************************');
            update entryUpdateList;
        }


    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** HorizonTimeEntryBatchUpdates_Manager FINISH ***************');

    }


}