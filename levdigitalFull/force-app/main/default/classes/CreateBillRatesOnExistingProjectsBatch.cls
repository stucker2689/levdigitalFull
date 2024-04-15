public with sharing class CreateBillRatesOnExistingProjectsBatch implements Database.Batchable<sObject>{
/**
CreateBillRatesOnExistingProjectsBatch createBillRatesBatch= new CreateBillRatesOnExistingProjectsBatch();
Database.executeBatch(createBillRatesBatch, 100); 
 **/

    public final String QueryString;
    public final List<Project__c> projectList;
    public Set<Id> projIdSet = new Set<Id>();
    
    //This class pulls timeEntries for all employees with a weekendDate of a previous month. If weeksToGoBack is greater than 1,
    //then batch jobs will chain after they finish until the number of weeks is met 
    public CreateBillRatesOnExistingProjectsBatch() {

        QueryString = 'SELECT Id, Name, Opportunity__c'
         + ' FROM Project__c'
         + ' WHERE Project_Status__c IN (\'Not Started\', \'Active\', \'On Hold\')';
    }

    public CreateBillRatesOnExistingProjectsBatch(List<Project__c> projList) {
        
        for(Project__c proj : projList){
            projIdSet.add(proj.Id);
        }

        QueryString = 'SELECT Id, Name, Opportunity__c'
         + ' FROM Project__c'
         + ' WHERE Id IN :projIdSet ORDER BY Name';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('*************** CreateBillRatesOnExistingProjectsBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<Project__c> projectList){

        ProjectBillingRateManager.syncProjectBillingRates(projectList);       

    }
    
    public void finish(Database.BatchableContext bc){


    }
}