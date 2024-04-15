public with sharing class MilestoneTriggerHandler {

    private static String campaignMilestoneRT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();

    /******************************************************************** Before Insert Functions *******************************************************************/
    public static void onBeforeInsert(List<Milestone__c> newMilestoneList){

        List<Milestone__c> milestoneNameCheckList = new List<Milestone__c>();
        Set<String> milestoneNameSet = new Set<String>();
        for(Milestone__c milestone : newMilestoneList){

            //Check Names for Uniqueness
            if(milestone.Name != null){
                milestoneNameCheckList.add(milestone);
                milestoneNameSet.add(milestone.Name);
            }
        }

        if(milestoneNameCheckList.size() > 0){
            checkMilestoneNameUniqueness(milestoneNameCheckList, milestoneNameSet);
        }
    }
    /******************************************************************** Before Update Functions *******************************************************************/
    public static void onBeforeUpdate(List<Milestone__c> updatedMilstoneList, Map<Id, Milestone__c> oldMap){

        List<Milestone__c> milestoneNameCheckList = new List<Milestone__c>();
        Set<String> milestoneNameSet = new Set<String>();
        for(Milestone__c milestone : updatedMilstoneList){

            //Check Names for Uniqueness
            if(milestone.Name != oldMap.get(milestone.Id).Name){
                milestoneNameCheckList.add(milestone);
                milestoneNameSet.add(milestone.Name);
            }
        }

        if(milestoneNameCheckList.size() > 0){
            checkMilestoneNameUniqueness(milestoneNameCheckList, milestoneNameSet);
        }
    }

    /******************************************************************** After Update Functions *******************************************************************/
    public static void onAfterUpdate(List<Milestone__c> updatedMilstoneList, Map<Id, Milestone__c> oldMap){

        Map<Id, Milestone__c> nameUpdatedMilestoneMap = new Map<Id, Milestone__c>();
        for(Milestone__c milestone : updatedMilstoneList){

            //If Names changes then send to helper method that cascades name change to related Work records
            if(milestone.Name != oldMap.get(milestone.Id).Name){
                nameUpdatedMilestoneMap.put(milestone.Id, milestone);
            }
        }


        if(nameUpdatedMilestoneMap.size() > 0){
            changeRelatedWorkRecordNames(nameUpdatedMilestoneMap, oldMap);
        }
    }

    /******************************************************************** Before Delete Functions *******************************************************************/
    public static void onBeforeDelete(List<Milestone__c> deletedMilstonesList){

        if(deletedMilstonesList.size() > 0){
            deleteRelatedWorkRecords(deletedMilstonesList);
        }
    }

    /******************************************************************** Helper Functions *******************************************************************/
    private static void deleteRelatedWorkRecords(List<Milestone__c> deleteMilestonesList){
        /**Functionality:
         * Finds related Work records of Milestone that is getting deleted and deletes them
         */

        List<Id> milestoneIdList = new List<Id>();
        for(Milestone__c ms : deleteMilestonesList){
            //if(ms.RecordTypeId == campaignMilestoneRT){
                milestoneIdList.add(ms.Id);
            //}
        }

         List<Work__c> relatedWorkRecordsList = new List<Work__c>();
         if(milestoneIdList.size() > 0){
            relatedWorkRecordsList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c IN :milestoneIdList];
         }

         if(relatedWorkRecordsList.size() > 0){
             delete relatedWorkRecordsList;
         }
    }

    private static void changeRelatedWorkRecordNames(Map<Id, Milestone__c> updatedNameMilestoneMap, Map<Id, Milestone__c> oldMap){
        /** Functionality:
         * When Milestone Name changes, it also changes the names of all related Work Records b/c work record name = '*Milestone Name* + Staticname of work record created via flow'
         */

        List<Work__c> relatedWorkRecordsList = new List<Work__c>();
        relatedWorkRecordsList = [SELECT Id, Name, Milestone__c FROM Work__c WHERE Milestone__c IN :updatedNameMilestoneMap.keySet() ORDER BY Milestone__c];

        List<Work__c> workUpdateList = new List<Work__c>();
        for(Work__c w : relatedWorkRecordsList){
            //Loop through work, replace the old Milestone Name with new Milestone Name in the Work Record's Name field
            if(oldMap.containsKey(w.Milestone__c) && updatedNameMilestoneMap.containsKey(w.Milestone__c)){
                String oldMilestoneName = oldMap.get(w.Milestone__c).Name;
                String newMilestoneName = updatedNameMilestoneMap.get(w.Milestone__c).Name;

                //Only Change Work Record Names if they have the previous Milestone's name in the Work Records existing Name
                if(w.Name.contains(oldMilestoneName)){
                    //Replace function replaces the first parameter with the second parameter, so we are just replacing the old Milestone Name with the new for the Work record's Name
                    String newWorkName = ((w.Name).replace(oldMilestoneName, newMilestoneName)).left(80);

                    if(w.Name != newWorkName){
                        w.Name = newWorkName;
                        workUpdateList.add(w);
                    }
                }
            }
        }

        if(workUpdateList.size() > 0){
            update workUpdateList;
        }
    }

    private static void checkMilestoneNameUniqueness(List<Milestone__c> milestoneList, Set<String> milestoneNameSet){

        List<Milestone__c> existingMilestoneList = new List<Milestone__c>();
        existingMilestoneList = [SELECT Id, Name, RecordType.Name
                                    FROM Milestone__c
                                    WHERE Name IN :milestoneNameSet];

        Set<String> existingMilestoneNameSet = new Set<String>();
        for(Milestone__c existingMilestone : existingMilestoneList){
            existingMilestoneNameSet.add(existingMilestone.Name);
        }

        for(Milestone__c milestone : milestoneList){
            if(existingMilestoneNameSet.contains(milestone.Name)){
                milestone.addError('Name', 'Campaign Milestone names must be unique across all existing Projects in our instance and this name has already been used. Please change the Milestone name to make it unique across all of Salesforce before proceeding.');
            }
        }
    }
}