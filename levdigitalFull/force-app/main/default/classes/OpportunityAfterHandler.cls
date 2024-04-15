public with sharing class OpportunityAfterHandler {

    private static Id changeOrderOpptyRT = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    public static List<String> createProjectStageNamesList = new List<String>{'Verbal Approval (Negotiation)', 'Finalize Contracts', 'Closed Won'};
    
    public static void onAfterInsert(List<Opportunity> newOpptyList){

        Set<Id> reCalculateOpptyIdSet = new Set<Id>();
        Set<Id> reCalculateAccountIdSet = new Set<Id>();
        List<Opportunity> opptysToCreateProjectList = new List<Opportunity>();

        for(Opportunity opp : newOpptyList){
            
            if(opp.Change_Orders__c != null &&  opp.RecordTypeId == changeOrderOpptyRT){
                reCalculateOpptyIdSet.add(opp.Change_Orders__c);
            }

            if(opp.IsWon){
                reCalculateAccountIdSet.add(opp.AccountId);
            }

            if(opp.Create_Project__c && !opp.Do_Not_Create_Project__c && createProjectStageNamesList.contains(opp.StageName)) {
                opptysToCreateProjectList.add(opp);                        
            }
        }

        if(reCalculateOpptyIdSet.size() > 0){
            recalculateOppty(reCalculateOpptyIdSet);
        }
        if(reCalculateAccountIdSet.size() > 0){
            AccountCalculations.FirstYearBooking(reCalculateAccountIdSet);
        }
        if(opptysToCreateProjectList.size() > 0){
            CreateProject.CreateProject(opptysToCreateProjectList);
        }

    }

    public static void onAfterUpdate(List<Opportunity> newOpptyList, Map<Id,Opportunity> oldOpptyMap,  Map<Id,Opportunity> newOpptyMap){

        Set<Id> reCalculateOpptyIdSet = new Set<Id>();
        Set<Id> reCalculateAccountIdSet = new Set<Id>();
        List<Opportunity> opptysToCreateProjectList = new List<Opportunity>();

        for(Opportunity opp : newOpptyList){
            Opportunity oldOppty = oldOpptyMap.get(opp.Id);

            /** Recalculate Oppty if:
             * The Parent Oppty of a Change Order changes
             * The Amount or StageName Changes
             */
            if(opp.Change_Orders__c != oldOppty.Change_Orders__c && opp.RecordTypeId == changeOrderOpptyRT){
                if(oldOppty.Change_Orders__c != null){
				    reCalculateOpptyIdSet.add(oldOppty.Change_Orders__c);
                }
                if(opp.Change_Orders__c != null){
                    reCalculateOpptyIdSet.add(opp.Change_Orders__c);
                }
			}else if(opp.Change_Orders__c != null &&  opp.RecordTypeId == changeOrderOpptyRT && (opp.Amount != oldOppty.Amount || opp.StageName != oldOppty.StageName)){
                reCalculateOpptyIdSet.add(oldOppty.Change_Orders__c);
            }
            
            //If Oppty moves to Close Won OR Closed Won Oppty changes its Amount or Close Date
            if(opp.IsWon && !oldOppty.isWon || (opp.IsWon && (opp.Amount != oldOppty.Amount || opp.CloseDate != oldOppty.CloseDate))){
                reCalculateAccountIdSet.add(opp.AccountId);
            }

            //If Oppty has Do Not Create Project = false AND Create Project = true AND Oppty Stage moves to one of these stages 'Verbal Approval (Negotiation)', 'Finalize Contracts', 'Closed Won' 
            if(!opp.Do_Not_Create_Project__c && opp.Create_Project__c && (createProjectStageNamesList.contains(opp.StageName) && !createProjectStageNamesList.contains(oldOppty.StageName))) {
                opptysToCreateProjectList.add(opp);                        
            }
        }

        if(newOpptyMap.size() > 0 && oldOpptyMap.size() > 0){
            ProjectHandler.updateReplionDatainProject(oldOpptyMap, newOpptyMap);
        }

        if(reCalculateOpptyIdSet.size() > 0){
            recalculateOppty(reCalculateOpptyIdSet);
        }
        if(reCalculateAccountIdSet.size() > 0){
            AccountCalculations.FirstYearBooking(reCalculateAccountIdSet);
        }
        if(opptysToCreateProjectList.size() > 0){
            CreateProject.CreateProject(opptysToCreateProjectList);
        }

    }

    public static void onAfterDelete(List<Opportunity> newOpptyList){

        Set<Id> reCalculateOpptyIdSet = new Set<Id>();
        Set<Id> reCalculateAccountIdSet = new Set<Id>();

        for(Opportunity opp : newOpptyList){

            if(opp.Change_Orders__c != null){
				reCalculateOpptyIdSet.add(opp.Change_Orders__c);
			}

            if(opp.AccountId != null){
                reCalculateAccountIdSet.add(opp.AccountId);
            }
        }

        if(reCalculateOpptyIdSet.size() > 0){
            recalculateOppty(reCalculateOpptyIdSet);
        }
        if(reCalculateAccountIdSet.size() > 0){
            AccountCalculations.FirstYearBooking(reCalculateAccountIdSet);
        }
        
    }

    public static void onAfterUndelete(List<Opportunity> newOpptyList){

        Set<Id> reCalculateOpptyIdSet = new Set<Id>();
        Set<Id> reCalculateAccountIdSet = new Set<Id>();

        for(Opportunity opp : newOpptyList){

            if(opp.Change_Orders__c != null && opp.RecordTypeId == changeOrderOpptyRT){
                reCalculateOpptyIdSet.add(opp.Change_Orders__c);
            }

            if(opp.IsWon){
                reCalculateAccountIdSet.add(opp.AccountId);
            }
        }

        if(reCalculateOpptyIdSet.size() > 0){
            recalculateOppty(reCalculateOpptyIdSet);
        }
        if(reCalculateAccountIdSet.size() > 0){
            AccountCalculations.FirstYearBooking(reCalculateAccountIdSet);
        }
    }

    public static void recalculateOppty(Set<Id> opptyIdSet){

        if(CheckFirst.calculateOpp == true) {
			if(opptyIdSet.size() > 0){
				OpportunityCalculations.relOppReCalc(opptyIdSet);
			}
		}

    }
}