public with sharing class ApprovalTriggerHelper {


   public static void rollupApprovalsUnderReviewOnCase(Set<Id> caseIdSet){
       System.debug('rollupApprovalsUnderReviewOnCase START');
        Map<Id, Decimal> caseIdToApprovalsUnderReviewCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> caseIdToApprovedApprovalsCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> caseIdToApprovalsCountMap = new Map<Id, Decimal>();
        for(Id caseId : caseIdSet){
            caseIdToApprovalsUnderReviewCountMap.put(caseId, 0);
            caseIdToApprovedApprovalsCountMap.put(caseId, 0);
            caseIdToApprovalsCountMap.put(caseId, 0);
        }

        AggregateResult[] underReviewApprovalsAgg = [SELECT COUNT(Id), Case__c, Status__c, Approval_In_Process__c
                                                        FROM Approvals__c
                                                        WHERE Case__c IN :caseIdSet
                                                        GROUP BY Case__c, Status__c, Approval_In_Process__c
                                                        ORDER BY Case__c];

        for(AggregateResult ar : underReviewApprovalsAgg){
            Decimal approvalCount = (Decimal)ar.get('expr0');
            Id caseId = (Id)ar.get('Case__c');
            String approvalStatus = (String)ar.get('Status__c');
            Boolean approvalInProcess = (Boolean)ar.get('Approval_In_Process__c');

            if(approvalInProcess == true){
                Decimal underApprovalApprovalCount = caseIdToApprovalsUnderReviewCountMap.get(caseId);
                underApprovalApprovalCount += approvalCount;
                caseIdToApprovalsUnderReviewCountMap.put(caseId, underApprovalApprovalCount);
            }

            if(approvalStatus == 'Approved'){
                Decimal approvedApprovalCount = caseIdToApprovedApprovalsCountMap.get(caseId);
                approvedApprovalCount += approvalCount;
                caseIdToApprovedApprovalsCountMap.put(caseId, approvedApprovalCount);
            }

            Decimal caseApprovalCount = caseIdToApprovalsCountMap.get(caseId);
            caseApprovalCount += approvalCount;
            caseIdToApprovalsCountMap.put(caseId, caseApprovalCount);

        }

        List<Case> caseUpdateList = new List<Case>();
        for(Case c : [SELECT Id, Subject, Approval_Records_In_Process__c, Total_Approval_Records__c, Validated_Approval_Records__c
                            FROM Case
                            WHERE Id IN :caseIdSet]){
            Boolean needsUpdate = false;

            if(caseIdToApprovalsUnderReviewCountMap.containsKey(c.Id) && c.Approval_Records_In_Process__c != caseIdToApprovalsUnderReviewCountMap.get(c.Id)){
                c.Approval_Records_In_Process__c = caseIdToApprovalsUnderReviewCountMap.get(c.Id);
                needsUpdate = true;
            }

            if(caseIdToApprovedApprovalsCountMap.containsKey(c.Id) && c.Validated_Approval_Records__c != caseIdToApprovedApprovalsCountMap.get(c.Id)){
                c.Validated_Approval_Records__c = caseIdToApprovedApprovalsCountMap.get(c.Id);
                needsUpdate = true;
            }

            if(caseIdToApprovalsCountMap.containsKey(c.Id) && c.Total_Approval_Records__c != caseIdToApprovalsCountMap.get(c.Id)){
                c.Total_Approval_Records__c = caseIdToApprovalsCountMap.get(c.Id);
                needsUpdate = true;
            }

            if(needsUpdate){
                caseUpdateList.add(c);
            }
        }

        if(caseUpdateList.size() > 0){
            System.debug('Update Approvals Count(s) on Case for ' + caseUpdateList.size() + ' Case(s)');
            update caseUpdateList;
        }

    }
}