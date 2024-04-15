trigger ApprovalTrigger on Approvals__c (after insert, after update, after delete, after undelete) {

	if(Trigger.isAfter && Trigger.isInsert){
		ApprovalTriggerHandler.onAfterInsert(Trigger.new);
	}

	if(Trigger.isAfter && Trigger.isUpdate){
		ApprovalTriggerHandler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
	}

    if(Trigger.isAfter && Trigger.isDelete){
        ApprovalTriggerHandler.onAfterDelete(Trigger.old);
    }

    if(Trigger.isAfter && Trigger.isUndelete){
        ApprovalTriggerHandler.onAfterUndelete(Trigger.new);
    } 
}