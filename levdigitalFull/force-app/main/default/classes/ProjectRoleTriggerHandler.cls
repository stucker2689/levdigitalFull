/**
 * Created 6/1/2022
 * 
 * Purpose to handle logic that should occur on Project Role Trigger
 */

public with sharing class ProjectRoleTriggerHandler {
    
    public static void onAfterInsert(List<ProjectRole__c> projectRoleList){

        List<Id> projIdList = new List<Id>();
        for(ProjectRole__c projRole : projectRoleList){
            if(projRole.Project__c != null){
                projIdList.add(projRole.Project__c);
            }
        }

        //if(projIdList.size() > 0 && !Test.isRunningTest()){
        if(projIdList.size() > 0){
            //Call a batch run to link any existing time entries to the existing project roles when they are inserted
            ProjectRoleTimeEntryLinkBatch newProjectRoleTimeEntryLinkBatch = new ProjectRoleTimeEntryLinkBatch(false, projIdList);
            Database.executeBatch(newProjectRoleTimeEntryLinkBatch, 100); //Batch size (100) determines how many Time Entries to update at a time

            //Call a batch run to link any existing time entries to the existing project roles when they are inserted
            ProjectRoleForecastLinkBatch forecastLinkBatch = new ProjectRoleForecastLinkBatch(false, projIdList);
            Database.executeBatch(forecastLinkBatch, 250);
        }

    }

    public static void onAfterUpdate(List<ProjectRole__c> projectRoleList, Map<Id, ProjectRole__c> oldMap){

        List<Id> projIdList = new List<Id>();
        for(ProjectRole__c projRole : projectRoleList){
            if(oldMap.containsKey(projRole.Id)){
                ProjectRole__c oldProjRole = oldMap.get(projRole.Id);
                if((projRole.Rate__c != oldProjRole.Rate__c || projRole.Resource_Delivery_Group__c != oldProjRole.Resource_Delivery_Group__c || projRole.Name != oldProjRole.Name) && projRole.Project__c != null){
                    projIdList.add(projRole.Project__c);
                }
            }
        }

        if(projIdList.size() > 0){
            //Call a batch run to link any existing time entries to the existing project roles when they are inserted
            ProjectRoleTimeEntryLinkBatch newProjectRoleTimeEntryLinkBatch = new ProjectRoleTimeEntryLinkBatch(false, projIdList);
            Database.executeBatch(newProjectRoleTimeEntryLinkBatch, 100); //Batch size (100) determines how many Time Entries to update at a time

            //Call a batch run to link any existing time entries to the existing project roles when they are inserted
            ProjectRoleForecastLinkBatch forecastLinkBatch = new ProjectRoleForecastLinkBatch(false, projIdList);
            Database.executeBatch(forecastLinkBatch, 250);
        }

    }
}