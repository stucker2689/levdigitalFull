trigger ProjectRoleTrigger on ProjectRole__c (after insert, after update) {

    if(Trigger.isInsert && Trigger.isAfter){
        ProjectRoleTriggerHandler.onAfterInsert(Trigger.new);
	}

	if(Trigger.isUpdate && Trigger.isAfter){
        ProjectRoleTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
	}

}