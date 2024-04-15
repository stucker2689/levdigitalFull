/**
 * Created By Sam Tucker 6/12/2023
 * Scheduler for the ProjectTeamMemberEffectiveRateDailyCheck 
 * Runs to assign effective rates to project team members if the effective date is the current date.
 * 
 * Schedulable Apex run to run this code at 5:30 AM on Monday - Friday:
 * 
    ProjectTeamMemberEffectiveRateDailyCheck effectiveRateCheck = new ProjectTeamMemberEffectiveRateDailyCheck();
    System.schedule('Effective Rate Daily Assignment Check', '0 20 5 ? * *', effectiveRateCheck);
 */

public with sharing class ProjectTeamMemberEffectiveRateDailyCheck implements Database.Batchable<sObject>, Schedulable{

    public final String QueryString;

    public void execute (SchedulableContext ctx) {   

        ProjectTeamMemberEffectiveRateDailyCheck newEffectiveRateCheck = new ProjectTeamMemberEffectiveRateDailyCheck();
        Database.executeBatch(newEffectiveRateCheck, 100); 
    }


    public ProjectTeamMemberEffectiveRateDailyCheck() {

        QueryString = 'SELECT Id, Name, Internal_Project_Team_Member__c, Project_Billing_Rate__c, Effective_Date__c, Project_Billing_Rate__r.Product__c, Project_Billing_Rate__r.Product__r.Name' + 
                        ' FROM Project_Team_Member_Effective_Rate__c WHERE Effective_Date__c = TODAY ORDER BY Internal_Project_Team_Member__c, CreatedDate ASC';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('*************** ProjectTeamMemberEffectiveRateDailyCheck START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<Project_Team_Member_Effective_Rate__c> effectiveRateList){
        System.debug('*************** ProjectTeamMemberEffectiveRateDailyCheck EXECUTE ***************');

        Map<Id, Project_Team_Member_Effective_Rate__c> projTeamMemberIdToNewEffectiveRateMap = new Map<Id, Project_Team_Member_Effective_Rate__c>();
        for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){

            projTeamMemberIdToNewEffectiveRateMap.put(effectiveRate.Internal_Project_Team_Member__c, effectiveRate);
        }


        List<Client_Contact__c> relatedProjTeamMembersList = new List<Client_Contact__c>();
        relatedProjTeamMembersList = [SELECT Id, Name, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c
                                        FROM Client_Contact__c
                                        WHERE Id IN :projTeamMemberIdToNewEffectiveRateMap.keySet()];

        List<Client_Contact__c> projTeamMemberUpdateList = new List<Client_Contact__c>();
        for(Client_Contact__c projTeamMember : relatedProjTeamMembersList){

            if(projTeamMemberIdToNewEffectiveRateMap.containsKey(projTeamMember.Id)){
                if(projTeamMember.Assigned_Billing_Rate__c != projTeamMemberIdToNewEffectiveRateMap.get(projTeamMember.Id).Project_Billing_Rate__c){
                    projTeamMember.Assigned_Billing_Rate__c = projTeamMemberIdToNewEffectiveRateMap.get(projTeamMember.Id).Project_Billing_Rate__c;
                    projTeamMember.Contact_Role__c = String.valueOf(projTeamMemberIdToNewEffectiveRateMap.get(projTeamMember.Id).Project_Billing_Rate__r.Product__r.Name);
                    projTeamMember.Active_Effective_Billing_Rate__c = projTeamMemberIdToNewEffectiveRateMap.get(projTeamMember.Id).Id;
                    projTeamMemberUpdateList.add(projTeamMember);
                }
            }

        }

        if(projTeamMemberUpdateList.size() > 0){
            System.debug('*************************************** Updating ' + projTeamMemberUpdateList.size() + ' Internal Project Team Members with new Assigned Billing Rates from Effective Rate Check Daily Batch ***************************************');
            update projTeamMemberUpdateList;
        }


    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** ProjectTeamMemberEffectiveRateDailyCheck FINISH ***************');

    }
}