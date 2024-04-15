trigger ContactTrigger on Contact (before insert, after insert, before update, after update, after delete) {


    if(Trigger.isInsert && Trigger.isBefore) {
        ContactTriggerHandler.onBeforeInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isBefore) {
        ContactTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isInsert && Trigger.isAfter) {
        ContactTriggerHandler.onAfterInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isAfter) {
        ContactTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isDelete && Trigger.isAfter){
        ContactTriggerHandler.onAfterDelete(Trigger.old);

    }
    
}