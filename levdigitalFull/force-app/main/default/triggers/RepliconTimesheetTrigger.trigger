trigger RepliconTimesheetTrigger on Replicon_Timesheet__c (before insert, before update, after insert, after update, after delete) {

    if(Trigger.isInsert && Trigger.isBefore) {
        RepliconTimesheetTriggerHandler.onBeforeInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isBefore) {
        RepliconTimesheetTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isInsert && Trigger.isAfter) {
        RepliconTimesheetTriggerHandler.onAfterInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isAfter) {
        RepliconTimesheetTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isDelete && Trigger.isAfter){
        RepliconTimesheetTriggerHandler.onAfterDelete(Trigger.old);

    }

}