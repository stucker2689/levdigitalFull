public with sharing class InternalProjectTeamMemberTriggerHandler {

    public static void onBeforeInsert(List<Client_Contact__c> newInternalProjTeamMembersList){

        List<Client_Contact__c> linkProjectTeamMemberToBillRateList = new List<Client_Contact__c>();

        List<Client_Contact__c> populateContactRoleTeamMemberList = new List<Client_Contact__c>();
        Set<Id> billingRateIdSet = new Set<Id>();
        
        for(Client_Contact__c projTeamMember : newInternalProjTeamMembersList){
            if(projTeamMember.Project__c != null){
                if(projTeamMember.Contact_Role__c != null){
                    linkProjectTeamMemberToBillRateList.add(projTeamMember);
                }
            }
            if(projTeamMember.Contact_Role__c == null && projTeamMember.Assigned_Billing_Rate__c != null){
                populateContactRoleTeamMemberList.add(projTeamMember);
                billingRateIdSet.add(projTeamMember.Assigned_Billing_Rate__c);
            }

            if(projTeamMember.Internal_Project_Team_Member_Name__c != null && projTeamMember.Internal_Project_Team_Member_Name__c.contains('Place Holder')){
                if(projTeamMember.Is_Placeholder_Team_Member__c != true){
                    projTeamMember.Is_Placeholder_Team_Member__c = true;
                }
            }else{
                if(projTeamMember.Is_Placeholder_Team_Member__c != false){
                    projTeamMember.Is_Placeholder_Team_Member__c = false;
                }
            }   
        }

        if(linkProjectTeamMemberToBillRateList.size() > 0){
            InternalProjectTeamMemberTriggerHelper.linkProjectTeamMemberToBillRate(linkProjectTeamMemberToBillRateList, false);
        }

        if(populateContactRoleTeamMemberList.size() > 0){
            InternalProjectTeamMemberTriggerHelper.updateProjectTeamMemberContactRole(populateContactRoleTeamMemberList, billingRateIdSet, false);
        }

    }

    public static void onAfterInsert(List<Client_Contact__c> newInternalProjTeamMembersList){

        List<Client_Contact__c> populateContactRoleTeamMemberList = new List<Client_Contact__c>();
        Set<Id> billingRateIdSet = new Set<Id>();
        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        for(Client_Contact__c projTeamMember : newInternalProjTeamMembersList){

            if(projTeamMember.Project__c != null && projTeamMember.Client_Contact__c != null){
                projectIdSet.add(projTeamMember.Project__c);
                contactIdSet.add(projTeamMember.Client_Contact__c);
            }

            if(projTeamMember.Contact_Role__c == null && projTeamMember.Assigned_Billing_Rate__c != null){
                populateContactRoleTeamMemberList.add(projTeamMember);
                billingRateIdSet.add(projTeamMember.Assigned_Billing_Rate__c);
            }
        }

        if(populateContactRoleTeamMemberList.size() > 0){
            //InternalProjectTeamMemberTriggerHelper.updateProjectTeamMemberContactRole(populateContactRoleTeamMemberList, billingRateIdSet, true);
        }

        if(projectIdSet.size() > 0 && contactIdSet.size() > 0 && !System.isBatch() && !System.isFuture() && !Test.isRunningTest()){
            LinkTeamMembersToForecastsAndTimeBatch forecastLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Forecast', projectIdSet, contactIdSet);
            Database.executeBatch(forecastLinkBatch, 500);

            LinkTeamMembersToForecastsAndTimeBatch entryLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Time Entry', projectIdSet, contactIdSet);
            Database.executeBatch(entryLinkBatch, 500);
        }
    }

    public static void onBeforeUpdate(List<Client_Contact__c> internalProjTeamMembersList, Map<Id, Client_Contact__c> oldMap){

        List<Client_Contact__c> billRateSwitchTeamMemberList = new List<Client_Contact__c>();
        Set<Id> billingRateIdSet = new Set<Id>();
        for(Client_Contact__c cc : internalProjTeamMembersList){

            if(cc.Client_Contact__c != null && cc.Project__c != null && cc.Assigned_Billing_Rate__c != oldMap.get(cc.Id).Assigned_Billing_Rate__c){
                billRateSwitchTeamMemberList.add(cc);
                billingRateIdSet.add(cc.Assigned_Billing_Rate__c);
            }


            if(cc.Internal_Project_Team_Member_Name__c != null && cc.Internal_Project_Team_Member_Name__c != oldMap.get(cc.Id).Internal_Project_Team_Member_Name__c && cc.Internal_Project_Team_Member_Name__c.contains('Place Holder')){
                if(cc.Is_Placeholder_Team_Member__c != true){
                    cc.Is_Placeholder_Team_Member__c = true;
                }
            }else{
                if(cc.Internal_Project_Team_Member_Name__c != null && !cc.Internal_Project_Team_Member_Name__c.contains('Place Holder') && cc.Is_Placeholder_Team_Member__c != false){
                    cc.Is_Placeholder_Team_Member__c = false;
                }
            } 
        }


        if(billRateSwitchTeamMemberList.size() > 0){
            InternalProjectTeamMemberTriggerHelper.updateProjectTeamMemberContactRole(billRateSwitchTeamMemberList, billingRateIdSet, false);
        }
    }

    public static void onAfterUpdate(List<Client_Contact__c> internalProjTeamMembersList, Map<Id, Client_Contact__c> oldMap){

        List<Client_Contact__c> billRateSwitchTeamMemberList = new List<Client_Contact__c>();
        Set<Id> billingRateIdSet = new Set<Id>();
        for(Client_Contact__c cc : internalProjTeamMembersList){

            if(cc.Client_Contact__c != null && cc.Project__c != null && cc.Assigned_Billing_Rate__c != oldMap.get(cc.Id).Assigned_Billing_Rate__c){
                billRateSwitchTeamMemberList.add(cc);
                billingRateIdSet.add(cc.Assigned_Billing_Rate__c);
            }
        }


        if(billRateSwitchTeamMemberList.size() > 0){
            InternalProjectTeamMemberTriggerHelper.flipTempRateEntries(billRateSwitchTeamMemberList, oldMap);
            InternalProjectTeamMemberTriggerHelper.billingRateChanged(billRateSwitchTeamMemberList, oldMap);
            //InternalProjectTeamMemberTriggerHelper.updateProjectTeamMemberContactRole(billRateSwitchTeamMemberList, billingRateIdSet);
        }

    }

    public static void onAfterDelete(List<Client_Contact__c> deletedInternalProjTeamMembersList){

    }

    public static void onAfterUndelete(List<Client_Contact__c> undeletedInternalProjTeamMembersList){

    }
}