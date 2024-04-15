trigger ProjectTrigger on Project__c (before insert, before update, after insert, after update, after delete) {

	//Need to call after update method to update account with PHI, budget related values
	//ProjectHandler.updateProjectDetailsInAccount(trigger.oldMap, trigger.newMap);

	SObjects objectHandler = new ProjectTriggerHandler();

	if(Trigger.isBefore && Trigger.isInsert){
		objectHandler.beforeInsert(trigger.new);
	}

	if(Trigger.isAfter && Trigger.isInsert){
		objectHandler.afterInsert(trigger.new);
	}

	if(Trigger.isBefore && Trigger.isUpdate){
		objectHandler.beforeUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
	}

	if(Trigger.isAfter && Trigger.isUpdate){
		objectHandler.afterUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
	}

	if(Trigger.isAfter && Trigger.isDelete){
		ProjectTriggerHandler.afterDelete(Trigger.old);
	}

}