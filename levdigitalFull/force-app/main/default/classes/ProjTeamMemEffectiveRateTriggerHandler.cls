public with sharing class ProjTeamMemEffectiveRateTriggerHandler {


    public static void onAfterInsert(List<Project_Team_Member_Effective_Rate__c> effectiveRateList){

        System.debug('********************************** ProjTeamMemEffectiveRateTriggerHandler onAfterInsert START **********************************');

        Set<Id> projTeamMemberIdSet = new Set<Id>();
        for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){
            if(effectiveRate.Internal_Project_Team_Member__c != null){
                projTeamMemberIdSet.add(effectiveRate.Internal_Project_Team_Member__c);
            }
        }

        if(projTeamMemberIdSet.size() > 0){
            //Run all Time Entries related to this Project Team Member through the TimeEntryService.populateTimeEntryBillingRate(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate)
            ProjTeamMemEffectiveRateTriggerHelper.checkTimeEntryBillingRatePopulation(projTeamMemberIdSet);
            ProjTeamMemEffectiveRateTriggerHelper.checkForecastBillingRatePopulation(projTeamMemberIdSet);
        }


    }

    public static void onAfterUpdate(List<Project_Team_Member_Effective_Rate__c> effectiveRateList, Map<Id, Project_Team_Member_Effective_Rate__c> oldMap){

        Set<Id> projTeamMemberIdSet = new Set<Id>();
        for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){
            Project_Team_Member_Effective_Rate__c oldEffectiveRate = oldMap.get(effectiveRate.Id);

            if(effectiveRate.Effective_Date__c != oldEffectiveRate.Effective_Date__c || effectiveRate.Project_Billing_Rate__c != oldEffectiveRate.Project_Billing_Rate__c){
                if(effectiveRate.Internal_Project_Team_Member__c != null){
                    projTeamMemberIdSet.add(effectiveRate.Internal_Project_Team_Member__c);
                }
            }
            
        }

        if(projTeamMemberIdSet.size() > 0){
            //Run all Time Entries related to this Project Team Member through the TimeEntryService.populateTimeEntryBillingRate(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate)
            ProjTeamMemEffectiveRateTriggerHelper.checkTimeEntryBillingRatePopulation(projTeamMemberIdSet);
            ProjTeamMemEffectiveRateTriggerHelper.checkForecastBillingRatePopulation(projTeamMemberIdSet);
            ProjTeamMemEffectiveRateTriggerHelper.checkEffectiveRateToAssignForTeamMember(projTeamMemberIdSet);
        }

    }

    public static void onAfterDelete(List<Project_Team_Member_Effective_Rate__c> effectiveRateList){

        Set<Id> projTeamMemberIdSet = new Set<Id>();
        for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){
            if(effectiveRate.Internal_Project_Team_Member__c != null){
                projTeamMemberIdSet.add(effectiveRate.Internal_Project_Team_Member__c);
            }
        }

        if(projTeamMemberIdSet.size() > 0){
            //Run all Time Entries related to this Project Team Member through the TimeEntryService.populateTimeEntryBillingRate(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate)
            ProjTeamMemEffectiveRateTriggerHelper.checkTimeEntryBillingRatePopulation(projTeamMemberIdSet);
            ProjTeamMemEffectiveRateTriggerHelper.checkForecastBillingRatePopulation(projTeamMemberIdSet);
            ProjTeamMemEffectiveRateTriggerHelper.checkEffectiveRateToAssignForTeamMember(projTeamMemberIdSet);
        }

    }
}