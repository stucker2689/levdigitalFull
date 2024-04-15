/**
 * Created 6/27/22 ST 
 * 
 * Created to handle the trigger actions for the Skill Rating Trigger
 */

public with sharing class SkillRatingTriggerHandler {

    public static void onAfterInsert(List<Skill_Rating__c> skillRatingList){

        if(skillRatingList.size() > 0){
            updateDateSkillRatingLastUpdated(skillRatingList);
        }
    }

    public static void onAfterUpdate(List<Skill_Rating__c> skillRatingList, Map<Id, Skill_Rating__c> oldMap){

        List<Skill_Rating__c> updatedSkillRatingList = new List<Skill_Rating__c>();
        for(Skill_Rating__c sr : skillRatingList){

            //Get List of Skill ratings that have had their Rating__c value updated
            if(sr.Rating__c != oldMap.get(sr.Id).Rating__c){
                updatedSkillRatingList.add(sr);
            }

        }

        if(updatedSkillRatingList.size() > 0){
            updateDateSkillRatingLastUpdated(updatedSkillRatingList);
        }

    }

    public static void updateDateSkillRatingLastUpdated(List<Skill_Rating__c> skillRatingList){

        System.debug('*************************************** updateDateSkillRatingLastUpdated **********************************************');
        Set<Id> relatedContactIdSet = new Set<Id>();
        for(Skill_Rating__c sr : skillRatingList){
            if(sr.Resource__c != null){
                relatedContactIdSet.add(sr.Resource__c);
            }
        }

        System.debug('relatedContactIdSet Size: ' + relatedContactIdSet.size());
        System.debug('relatedContactIdSet: ' + relatedContactIdSet);

        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT Id, Name, DateSkillsMatrixLastUpdated__c FROM Contact WHERE Id IN :relatedContactIdSet];

        List<Contact> contactUpdateList = new List<Contact>();
        for(Contact con : contactList){
            System.debug('Contact Being Updated: ' + con.Name);
            if(Date.today() != con.DateSkillsMatrixLastUpdated__c){ //Only update if needed
                System.debug('Today does not equal Date Skills Matrix Last Updated');
                con.DateSkillsMatrixLastUpdated__c = Date.today();
                contactUpdateList.add(con);
            }
        }

        if(contactUpdateList.size() > 0){
            System.debug('Update Contact Skills Rating Last Updated: ' + contactUpdateList.size());
            update contactUpdateList;
        }
    }
}