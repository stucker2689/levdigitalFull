trigger StaffingAssignmentTrigger on Staffing_Assignment__c (before insert, after insert, before update, after update, before delete, after delete) {

    if(Trigger.isInsert && Trigger.isBefore){
		StaffingAssignmentTriggerHandler.onBeforeInsert(Trigger.new);
	}

    if(Trigger.isInsert && Trigger.isAfter){
		StaffingAssignmentTriggerHandler.onAfterInsert(Trigger.new);
	}

	if(Trigger.isUpdate && Trigger.isBefore){
		StaffingAssignmentTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.oldMap);
	}

    if(Trigger.isUpdate && Trigger.isAfter){
		StaffingAssignmentTriggerHandler.onAfterUpdate(Trigger.new,Trigger.oldMap);
	}

    if(Trigger.isDelete && Trigger.isBefore){
        StaffingAssignmentTriggerHandler.onBeforeDelete(Trigger.old);
	}

	if(Trigger.isDelete && Trigger.isAfter){
        StaffingAssignmentTriggerHandler.onAfterDelete(Trigger.old);
	}

}