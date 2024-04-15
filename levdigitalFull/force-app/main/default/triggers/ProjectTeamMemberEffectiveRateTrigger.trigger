trigger ProjectTeamMemberEffectiveRateTrigger on Project_Team_Member_Effective_Rate__c (after insert, after update, after delete) {

	if(Trigger.isAfter && Trigger.isInsert){
        ProjTeamMemEffectiveRateTriggerHandler.onAfterInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        ProjTeamMemEffectiveRateTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        ProjTeamMemEffectiveRateTriggerHandler.onAfterDelete(Trigger.old);
    }

}