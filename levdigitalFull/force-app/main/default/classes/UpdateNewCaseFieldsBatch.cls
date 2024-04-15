/**
 * Created 9/26/2022 ST
 * 
 * Purpose to populate the new Case fields for existing cases
 * 
 * 
 * 
UpdateNewCaseFieldsBatch newBatch = new UpdateNewCaseFieldsBatch();
Database.executeBatch(newBatch, 25);
 * 
 * 
 */

public with sharing class UpdateNewCaseFieldsBatch implements Database.Batchable<sObject>{

    public final String QueryString;

    public UpdateNewCaseFieldsBatch() {

        QueryString = 'SELECT Id, Subject, DueDateEntered__c, ChangeManagementDueDate__c, Due_Date_Internal__c, CaseCompletionDueDate__c, DeploymentCompletionDate__c, Type, Rollout_Needed__c, Internal_Request_Type__c, RecordTypeId, RecordType.Name, ClosedDate '
                    + ' FROM Case'
                    + ' WHERE RecordType.Name = \'Levementum Internal Case\' AND (Due_Date_Internal__c != null OR ClosedDate != null)'
                    + ' ORDER BY CreatedDate DESC';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('*************** UpdateNewCaseFieldsBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> caseList){
        System.debug('*************** UpdateNewCaseFieldsBatch EXECUTE ***************');

        List<Case> updateCaseList = new List<Case>();
        for(Case c : caseList){

            Boolean updateNeeded = false;

            //Set Due Date Entered field
            if(c.Due_Date_Internal__c != null && !c.DueDateEntered__c){
                c.DueDateEntered__c = true;
                updateNeeded = true;
            }

            //Set Deployment Completion Date
            if(c.ClosedDate != null && c.DeploymentCompletionDate__c == null){
                c.DeploymentCompletionDate__c = Date.newInstance(c.ClosedDate.year(), c.ClosedDate.month(), c.ClosedDate.day());
                updateNeeded = true;
            }

            //Set Change Management Due Date to 2 weeks after Due Date
            if(c.Due_Date_Internal__c != null && c.ChangeManagementDueDate__c == null && c.Rollout_Needed__c == 'Yes'){
                c.ChangeManagementDueDate__c = (c.Due_Date_Internal__c).addDays(14);
                updateNeeded = true;
            }

            //Set Case Completion Date as the 15th of the next quarter of the due date
            if(c.Due_Date_Internal__c != null && c.CaseCompletionDueDate__c == null && c.Rollout_Needed__c == 'Yes' && c.Type != 'IT Support'){
                
                Date caseCompletionDate;

                switch on c.Due_Date_Internal__c.month() {
                    when 1, 2, 3 {
                        caseCompletionDate = Date.newInstance((c.Due_Date_Internal__c).year(), 4, 15);
                    }
                    when 4, 5, 6 {
                        caseCompletionDate = Date.newInstance((c.Due_Date_Internal__c).year(), 7, 15);
                    }
                    when 7, 8, 9 {
                        caseCompletionDate = Date.newInstance((c.Due_Date_Internal__c).year(), 10, 15);
                    }
                    when 10, 11, 12 {
                        caseCompletionDate = Date.newInstance((c.Due_Date_Internal__c).year() + 1, 1, 15);
                    }
                    when else {
                        caseCompletionDate = null;
                    }
                }

                if(caseCompletionDate != null){
                    c.CaseCompletionDueDate__c = caseCompletionDate;
                    updateNeeded = true;
                }
            }

            if(updateNeeded){
                updateCaseList.add(c);
            }
        }

        if(updateCaseList.size() > 0){
            System.debug('*******CURRENT BATCH UPDATE SIZE IS: ' + updateCaseList.size() + ' *********');
            update updateCaseList;
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** UpdateNewCaseFieldsBatch FINISH ***************');

    }
}