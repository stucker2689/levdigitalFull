public with sharing class WorkTriggerHelper {

    private static String assignmentWorkRT = Schema.SObjectType.Work__c.getRecordTypeInfosByName().get('Assignment').getRecordTypeId();
    
    public static void validateUniqueWorkOrderOnMilestone(List<Work__c> workList){


        Set<Id> milestoneIdSet = new Set<Id>();
        Map<Id, Work__c> workIdToWorkMap = new Map<Id, Work__c>();
        for(Work__c work : workList){
            milestoneIdSet.add(work.Milestone__c);
            workIdToWorkMap.put(work.Id, work);
        }

        List<Work__c> relatedWorkList = new List<Work__c>();
        relatedWorkList = [SELECT Id, Name, Milestone__c, Milestone__r.Name, lkp_Project__c, pkl_Status__c, Order__c, RecordTypeId
                            FROM Work__c
                            WHERE Milestone__c IN :milestoneIdSet AND Order__c != null AND RecordTypeId =: assignmentWorkRT
                            ORDER BY Milestone__c, Order__c ASC, CreatedDate ASC];

        Map<Id, Set<Decimal>> milestoneIdToWorkUniqueOrderSetMap = new Map<Id, Set<Decimal>>();
        for(Work__c work : relatedWorkList){

            if(!workIdToWorkMap.containsKey(work.Id)){

                //Create Map of Milestone Id to a Set of all unique Work Order numbers on all the Milestone's related Work Assignments
                if(milestoneIdToWorkUniqueOrderSetMap.containsKey(work.Milestone__c)){
                    Set<Decimal> milestoneUniqueWorkOrderSet = milestoneIdToWorkUniqueOrderSetMap.get(work.Milestone__c);
                    milestoneUniqueWorkOrderSet.add(work.Order__c);
                    milestoneIdToWorkUniqueOrderSetMap.put(work.Milestone__c, milestoneUniqueWorkOrderSet);
                }else{
                    Set<Decimal> milestoneUniqueWorkOrderSet = new Set<Decimal>();
                    milestoneUniqueWorkOrderSet.add(work.Order__c);
                    milestoneIdToWorkUniqueOrderSetMap.put(work.Milestone__c, milestoneUniqueWorkOrderSet);
                }
            }
        }

        //Loop through the Work Assignment Records getting created/updated and see if their Order is unique to it's Milestone
        for(Work__c work : workList){
            if(milestoneIdToWorkUniqueOrderSetMap.containsKey(work.Milestone__c)){
                if(milestoneIdToWorkUniqueOrderSetMap.get(work.Milestone__c).contains(work.Order__c)){ 
                    work.addError('Order__c', 'The Order # entered for this Work record already exists for this Milestone. All Work associated to the same Milestone needs to have its own Order #. Please update this to a Order # that is not in use for this Milestone.');
                }
            }
        }
    }


    public static void reOrderWorkOrdersAfterWorkDeleted(List<Work__c> workList){

        Set<Id> milestoneIdSet = new Set<Id>();
        for(Work__c work : workList){
            milestoneIdSet.add(work.Milestone__c);
        }

        List<Work__c> relatedWorkList = new List<Work__c>();
        relatedWorkList = [SELECT Id, Name, Milestone__c, Milestone__r.Name, lkp_Project__c, pkl_Status__c, Order__c, RecordTypeId
                            FROM Work__c
                            WHERE Milestone__c IN :milestoneIdSet AND Order__c != null AND RecordTypeId =: assignmentWorkRT
                            ORDER BY Milestone__c, Order__c ASC, CreatedDate ASC];

        Map<Id, List<Work__c>> milestoneIdToWorkListMap = new Map<Id, List<Work__c>>();
        for(Work__c work: relatedWorkList){

            //Create Map of Milestone Id to a list of all their related Work Records
            if(milestoneIdToWorkListMap.containsKey(work.Milestone__c)){
                List<Work__c> milestoneWorkList = milestoneIdToWorkListMap.get(work.Milestone__c);
                milestoneWorkList.add(work);
                milestoneIdToWorkListMap.put(work.Milestone__c, milestoneWorkList);
            }else{
                List<Work__c> milestoneWorkList = new List<Work__c>();
                milestoneWorkList.add(work);
                milestoneIdToWorkListMap.put(work.Milestone__c, milestoneWorkList);
            }
        }

        List<Work__c> workToUpdateOrderList = new List<Work__c>();
        for(Id milestoneId : milestoneIdToWorkListMap.keySet()){

            Boolean reOrderSetReadyCheck = false;
            Boolean alreadySetReOrderReady = false;
            List<Work__c> milestoneWorkRecordsList = milestoneIdToWorkListMap.get(milestoneId);

            for(Integer i = 1; i <= milestoneWorkRecordsList.size(); i++){
                //Loop through each work record for the Milestone and order them as they are in the list, and update the work records if needed (The Work records should already be in ASC order based on their Order fields because of the ORDER BY clause of the above Query)
                Boolean needsUpdate = false;
                Work__c relatedWork = milestoneWorkRecordsList[i - 1]; //Subtracting 1 because index 0 of list should be Order 1

                if(relatedWork.pkl_Status__c == 'Cancelled' || relatedWork.pkl_Status__c == 'Completed'){
                    reOrderSetReadyCheck = true;
                }else if(reOrderSetReadyCheck && relatedWork.pkl_Status__c == 'New' && !alreadySetReOrderReady){
                    relatedWork.pkl_Status__c = 'Ready';
                    alreadySetReOrderReady = true;
                    needsUpdate = true;
                }else{
                    reOrderSetReadyCheck = false;
                }

                if((Integer)relatedWork.Order__c != i){
                    relatedWork.Order__c = i;
                    needsUpdate = true;
                }

                if(needsUpdate){
                    workToUpdateOrderList.add(relatedWork);
                }
            }
        }

        if(workToUpdateOrderList.size() > 0){
            System.debug('***************************** Updating the Order on ' + workToUpdateOrderList.size() + ' Work Assignments after Deletion of Work record on same Milestone *****************************');
            update workToUpdateOrderList;
        }
    }

    public static void validateUniqueWorkName(List<Work__c> workNameChangedWorkList){
        //Check that a Work Record has a unique name across its own record type. (Names can duplicate if they are of different Record Types but not if they are the same)

        List<String> workNameList = new List<String>();
        List<Id> workNameChangedRecordTypeIdList = new List<Id>();
        List<Work__c> allIncomingWorkToValidateList = new List<Work__c>();
        Map<String, List<Work__c>> workRTIdAndNameToWorkListMap = new Map<String, List<Work__c>>();
        for(Work__c work : workNameChangedWorkList){

            workNameList.add(work.Name);//Add all names to a List
            workNameChangedRecordTypeIdList.add(work.RecordTypeId); //Add all RecordTypeIds to a List
        }

        //Retrieve existing Work records to check against
        List<Work__c> existingWorkRecordsList = new List<Work__c>();
        existingWorkRecordsList = [SELECT Id, Name, RecordType.Name, RecordTypeId FROM Work__c WHERE RecordTypeId IN :workNameChangedRecordTypeIdList AND Name IN :workNameList];

        if(existingWorkRecordsList.size() > 0){
            Map<String, Work__c> existingWorkIdAndNameToWorkMap = new Map<String, Work__c>();
            for(Work__c existingWork : existingWorkRecordsList){

                String uniqueId = String.valueOf(existingWork.RecordTypeId) + ' | ' + existingWork.Name;
                existingWorkIdAndNameToWorkMap.put(uniqueId,  existingWork);
            }

            for(Work__c workToValidate : workNameChangedWorkList){

                String uniqueId = String.valueOf(workToValidate.RecordTypeId) + ' | ' + workToValidate.Name;
                if(existingWorkIdAndNameToWorkMap.containsKey(uniqueId)){

                    workToValidate.addError('Name', 'This Work Name already exists. Please update.');
                }
            }
        }
    }
}