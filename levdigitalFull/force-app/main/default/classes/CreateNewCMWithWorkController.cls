public with sharing class CreateNewCMWithWorkController {

    private static String campaignMilestoneRT = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();

    @AuraEnabled(cacheable=true)
    public static Boolean checkIfMilestoneNameIsUnique(String newMilestoneName, Id projectId){
        Boolean newMilestoneNameIsUnique = true;
        List<Milestone__c> milestoneList = new List<Milestone__c>();
        milestoneList = [SELECT Id, Name, Project__c FROM Milestone__c WHERE Name =: newMilestoneName];

        if(milestoneList.size() > 0){
            newMilestoneNameIsUnique = false;
        }

        return newMilestoneNameIsUnique;
    }

    @AuraEnabled(cacheable=false)
    public static Id createMilestoneAndWorkRecordsFromLWC(String milestoneName, List<WorkWrapper> wrapperList, Id projectId){
        
        Id milestoneRecordId;
        
        try{
            System.debug('milestoneName: ' + milestoneName);
            System.debug('Wrapper List: ' + wrapperList);
            System.debug('Project Id: ' + projectId);

            Milestone__c newMilestone = new Milestone__c(Name = milestoneName.left(80), Project__c = projectId, Status__c = 'New', RecordTypeId = campaignMilestoneRT);
            insert newMilestone;
            milestoneRecordId = newMilestone.Id;

            Project__c relatedProj = [SELECT Id, Name, Project_Manager__c FROM Project__c WHERE Id =: projectId];

            List<Work__c> newWorkToInsertList = new List<Work__c>();
            for(WorkWrapper wrapper : wrapperList){
                Work__c newWork = new Work__c();
                newWork.Milestone__c = newMilestone.Id;
                newWork.pkl_Status__c = 'New';
                newWork.OwnerId = relatedProj.Project_Manager__c == null ? null : relatedProj.Project_Manager__c;
                newWork.Priority__c = 'Medium';
                newWork.lkp_Project__c = projectId;
                newWork.Order__c = wrapper.workIndex;
                //Make Name to be Milestone + WorkName But needs to be limited to 80 characters
                Integer workNameLength = wrapper.workName.length();
                Integer spaceForMilestoneName = (79 - workNameLength) > 0 ? (79 - workNameLength) : 0; //80 is max Name length and made it 79 to account for the space between the Milestone Name and the Work Name
                String workName = milestoneName.left(spaceForMilestoneName) + ' ' + wrapper.workName;
                newWork.Name = workName.left(80);

                newWorkToInsertList.add(newWork);
            }

            if(newWorkToInsertList.size() > 0){
                System.debug('Inserting ' + newWorkToInsertList.size() + ' Work records from LWC');
                insert newWorkToInsertList;
            }

            return milestoneRecordId;
        }catch(Exception e){
            System.debug('Inserting Milestone and Work Error: ' + e);
            return milestoneRecordId;
        }

    }

    public class WorkWrapper{
        @AuraEnabled
        public String workId{get;set;}
        @AuraEnabled
        public String workName{get;set;}
        @AuraEnabled
        public Integer workIndex{get;set;}
    }
}