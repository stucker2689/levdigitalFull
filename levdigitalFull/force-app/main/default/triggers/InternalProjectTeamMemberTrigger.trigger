trigger InternalProjectTeamMemberTrigger on Client_Contact__c (after insert, before insert, before update, after update, after delete, after undelete) {

    if(Trigger.isInsert && Trigger.isBefore){
        InternalProjectTeamMemberTriggerHandler.onBeforeInsert(Trigger.new);
	}

    if(Trigger.isInsert && Trigger.isAfter){
        InternalProjectTeamMemberTriggerHandler.onAfterInsert(Trigger.new);
	}

    if(Trigger.isUpdate && Trigger.isBefore){
        InternalProjectTeamMemberTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
	}

    if(Trigger.isUpdate && Trigger.isAfter){
        InternalProjectTeamMemberTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
	}

	if(Trigger.isDelete && Trigger.isAfter){
        //InternalProjectTeamMemberTriggerHandler.onAfterDelete(Trigger.old);
	}

    if(Trigger.isUndelete && Trigger.isAfter){
        //InternalProjectTeamMemberTriggerHandler.onAfterDelete(Trigger.new);
	}
}