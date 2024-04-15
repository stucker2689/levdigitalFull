public with sharing class WorkTriggerHandler {

    private static String assignmentWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Assignment').getRecordTypeId();
    private static String emailDevEmailQAWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Email Dev/Email QA').getRecordTypeId();
    private static String emergingServicesWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Emerging Services').getRecordTypeId();
    private static String projectTaskWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Project Task').getRecordTypeId();
    
    public static void onBeforeInsert(List<Work__c> insertedWorkList){

        List<Work__c> workAssignmentWithOrderForValidationList = new List<Work__c>();
        List<Work__c> checkWorkForUniqueNameList = new List<Work__c>();

        for(Work__c work : insertedWorkList){
            if(work.RecordTypeId == assignmentWorkRT){
                if(work.Milestone__c != null && work.Order__c != null){
                    workAssignmentWithOrderForValidationList.add(work);
                }
            }

            checkWorkForUniqueNameList.add(work);
        }

        if(checkWorkForUniqueNameList.size() > 0){
            WorkTriggerHelper.validateUniqueWorkName(checkWorkForUniqueNameList);
        }

        if(workAssignmentWithOrderForValidationList.size() > 0){
            WorkTriggerHelper.validateUniqueWorkOrderOnMilestone(workAssignmentWithOrderForValidationList);
        }
    }

    public static void onAfterInsert(List<Work__c> insertedWorkList){
        
    }

    public static void onBeforeUpdate(List<Work__c> updatedWorkList, Map<Id, Work__c> oldMap){
        
        List<Work__c> workAssignmentWithOrderForValidationList = new List<Work__c>();
        List<Work__c> checkWorkForUniqueNameList = new List<Work__c>();

        for(Work__c work : updatedWorkList){
            Work__c oldWork = oldMap.get(work.Id);
            
            if(work.RecordTypeId == assignmentWorkRT){
                if(work.Milestone__c != null && work.Order__c != null && work.Order__c != oldWork.Order__c){ //If Order is updated on a Work Assignment, we need to validate that the number is not already taken by another Work Assignment on the same Milestone.
                    workAssignmentWithOrderForValidationList.add(work);
                }
            }

            if(work.Name != oldWork.Name || work.RecordTypeId != oldWork.RecordTypeId){ //Validate that Work Names are unique within their Record Type
                checkWorkForUniqueNameList.add(work);
            }
        }

        if(checkWorkForUniqueNameList.size() > 0){
            WorkTriggerHelper.validateUniqueWorkName(checkWorkForUniqueNameList);
        }

        if(workAssignmentWithOrderForValidationList.size() > 0){
            WorkTriggerHelper.validateUniqueWorkOrderOnMilestone(workAssignmentWithOrderForValidationList);
        }
    }

    public static void onAfterUpdate(List<Work__c> updatedWorkList, Map<Id, Work__c> oldMap){
        
    }

    public static void onAfterDelete(List<Work__c> deletedWorkList){
        
        List<Work__c> deletedWorkAssignmentToReOrderList = new List<Work__c>();

        for(Work__c work : deletedWorkList){
            
            if(work.RecordTypeId == assignmentWorkRT){
                if(work.Milestone__c != null && work.Order__c != null){ //If a Work Assignment is deleted and was on a Milestone and also had an Order assigned, we need to adjust the remaining Work Records on the Milestone to take the .
                    deletedWorkAssignmentToReOrderList.add(work);
                }
            }
        }

        if(deletedWorkAssignmentToReOrderList.size() > 0){
            WorkTriggerHelper.reOrderWorkOrdersAfterWorkDeleted(deletedWorkAssignmentToReOrderList);
        }
    }

}