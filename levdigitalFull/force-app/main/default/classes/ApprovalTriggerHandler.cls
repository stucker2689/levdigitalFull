public with sharing class ApprovalTriggerHandler {
    
    public static void onAfterInsert(List<Approvals__c> newApprovalsList){

        Set<Id> approvalsUnderReviewToRollupCaseIdSet = new Set<Id>();
        for(Approvals__c approval : newApprovalsList){
            if(approval.Case__c != null){
                approvalsUnderReviewToRollupCaseIdSet.add(approval.Case__c);
            }
        }

        if(approvalsUnderReviewToRollupCaseIdSet.size() > 0){
            ApprovalTriggerHelper.rollupApprovalsUnderReviewOnCase(approvalsUnderReviewToRollupCaseIdSet);
        }
    }

    public static void onAfterUpdate(List<Approvals__c> newAppovalsList, List<Approvals__c> oldApprovalsList, Map<Id, Approvals__c> newApprovalsMap, Map<Id, Approvals__c> oldApprovalsMap){

        Set<Id> approvalsUnderReviewToRollupCaseIdSet = new Set<Id>();
        for(Approvals__c approval : newAppovalsList){
            Approvals__c oldApproval = oldApprovalsMap.get(approval.Id);
            if(approval.Case__c != oldApproval.Case__c || approval.Approval_In_Process__c != oldApproval.Approval_In_Process__c || (approval.Status__c != oldApproval.Status__c && (approval.Status__c == 'Approved' || oldApproval.Status__c == 'Approved'))){
                approvalsUnderReviewToRollupCaseIdSet.add(approval.Case__c);
                if(approval.Case__c != oldApproval.Case__c && oldApproval.Case__c != null){
                    approvalsUnderReviewToRollupCaseIdSet.add(oldApproval.Case__c);
                }
            }
        }

        if(approvalsUnderReviewToRollupCaseIdSet.size() > 0){
            ApprovalTriggerHelper.rollupApprovalsUnderReviewOnCase(approvalsUnderReviewToRollupCaseIdSet);
        }

    }

    public static void onAfterDelete(List<Approvals__c> deletedApprovalsList){

        Set<Id> approvalsUnderReviewToRollupCaseIdSet = new Set<Id>();
        for(Approvals__c approval : deletedApprovalsList){
            if(approval.Case__c != null){
                approvalsUnderReviewToRollupCaseIdSet.add(approval.Case__c);
            }
        }

        if(approvalsUnderReviewToRollupCaseIdSet.size() > 0){
            ApprovalTriggerHelper.rollupApprovalsUnderReviewOnCase(approvalsUnderReviewToRollupCaseIdSet);
        }
    }

    public static void onAfterUndelete(List<Approvals__c> undeletedApprovalsList){
        
        Set<Id> approvalsUnderReviewToRollupCaseIdSet = new Set<Id>();
        for(Approvals__c approval : undeletedApprovalsList){
            if(approval.Case__c != null){
                approvalsUnderReviewToRollupCaseIdSet.add(approval.Case__c);
            }
        }

        if(approvalsUnderReviewToRollupCaseIdSet.size() > 0){
            ApprovalTriggerHelper.rollupApprovalsUnderReviewOnCase(approvalsUnderReviewToRollupCaseIdSet);
        }
    }

}