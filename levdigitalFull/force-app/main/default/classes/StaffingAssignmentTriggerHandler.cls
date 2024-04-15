public with sharing class StaffingAssignmentTriggerHandler {

    public static List<String> completedStaffingAssignmentStatusList = new List<String>{'Completed', 'Cancelled', 'Pending'};
    
    public static void onBeforeInsert(List<Staffing_Assignment__c> newStaffingAssignmentsList){

    }

    public static void onAfterInsert(List<Staffing_Assignment__c> newStaffingAssignmentsList){

        List<Staffing_Assignment__c> staffingAssignmentsToCreateTeamMemberList = new List<Staffing_Assignment__c>();
        Set<Id> calcStaffingAssignmentCreatedCountOpptyIdSet = new Set<Id>();
        Set<Id> calcStaffingAssignmentCompletedCountOpptyIdSet = new Set<Id>();
        for(Staffing_Assignment__c sa : newStaffingAssignmentsList){
            
            if(sa.Status__c == 'Completed'){
                staffingAssignmentsToCreateTeamMemberList.add(sa);
            }

            if(completedStaffingAssignmentStatusList.contains(sa.Status__c) && sa.Opportunity__c != null){
                calcStaffingAssignmentCompletedCountOpptyIdSet.add(sa.Opportunity__c);
            }

            if(sa.Opportunity__c != null){
                calcStaffingAssignmentCreatedCountOpptyIdSet.add(sa.Opportunity__c);
            }
            
        }

        if(staffingAssignmentsToCreateTeamMemberList.size() > 0){
            StaffingAssignmentTriggerHelper.createProjectTeamMembersFromStaffingAssignments(staffingAssignmentsToCreateTeamMemberList);
        }

        if(calcStaffingAssignmentCreatedCountOpptyIdSet.size() > 0){
            StaffingAssignmentTriggerHelper.countStaffingAssignmentsCreatedOnOppty(calcStaffingAssignmentCreatedCountOpptyIdSet);
        }

        if(calcStaffingAssignmentCompletedCountOpptyIdSet.size() > 0){
            StaffingAssignmentTriggerHelper.countStaffingAssignmentsCompletedOnOppty(calcStaffingAssignmentCompletedCountOpptyIdSet);
        }

    }

    public static void onBeforeUpdate(List<Staffing_Assignment__c> updatedStaffingAssignmentsList, Map<Id, Staffing_Assignment__c> oldMap){

    }

    public static void onAfterUpdate(List<Staffing_Assignment__c> updatedStaffingAssignmentsList, Map<Id, Staffing_Assignment__c> oldMap){

        List<Staffing_Assignment__c> staffingAssignmentsToCreateTeamMemberList = new List<Staffing_Assignment__c>();
        Set<Id> calcStaffingAssignmentCompletedCountOpptyIdSet = new Set<Id>();
        for(Staffing_Assignment__c sa : updatedStaffingAssignmentsList){

            Staffing_Assignment__c oldStaffingAssignment = oldMap.get(sa.Id);
            if(sa.Status__c != oldStaffingAssignment.Status__c && sa.Status__c == 'Completed'){
                staffingAssignmentsToCreateTeamMemberList.add(sa);
            }

            if(sa.Status__c != oldStaffingAssignment.Status__c && (completedStaffingAssignmentStatusList.contains(sa.Status__c) || completedStaffingAssignmentStatusList.contains(oldStaffingAssignment.Status__c))){
                calcStaffingAssignmentCompletedCountOpptyIdSet.add(sa.Opportunity__c);
            }
            
        }

        if(staffingAssignmentsToCreateTeamMemberList.size() > 0){
            StaffingAssignmentTriggerHelper.createProjectTeamMembersFromStaffingAssignments(staffingAssignmentsToCreateTeamMemberList);
        }

        if(calcStaffingAssignmentCompletedCountOpptyIdSet.size() > 0){
            StaffingAssignmentTriggerHelper.countStaffingAssignmentsCompletedOnOppty(calcStaffingAssignmentCompletedCountOpptyIdSet);
        }

    }

    public static void onBeforeDelete(List<Staffing_Assignment__c> deletedStaffingAssignmentsList){

    }

    public static void onAfterDelete(List<Staffing_Assignment__c> deletedStaffingAssignmentsList){

        Set<Id> calcStaffingAssignmentCreatedCountOpptyIdSet = new Set<Id>();
        Set<Id> calcStaffingAssignmentCompletedCountOpptyIdSet = new Set<Id>();
        for(Staffing_Assignment__c sa : deletedStaffingAssignmentsList){

            if(sa.Opportunity__c != null){
                calcStaffingAssignmentCreatedCountOpptyIdSet.add(sa.Opportunity__c);

                if(completedStaffingAssignmentStatusList.contains(sa.Status__c)){
                    calcStaffingAssignmentCompletedCountOpptyIdSet.add(sa.Opportunity__c);
                }
            }            
        }

        if(calcStaffingAssignmentCreatedCountOpptyIdSet.size() > 0){
            StaffingAssignmentTriggerHelper.countStaffingAssignmentsCreatedOnOppty(calcStaffingAssignmentCreatedCountOpptyIdSet);
        }

        if(calcStaffingAssignmentCompletedCountOpptyIdSet.size() > 0){
            StaffingAssignmentTriggerHelper.countStaffingAssignmentsCompletedOnOppty(calcStaffingAssignmentCompletedCountOpptyIdSet);
        }
    }
}