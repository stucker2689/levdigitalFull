trigger CapacityTrigger on Capacity__c (before insert, after insert, before update, after update) {

    if(Trigger.isInsert && Trigger.isBefore) {
        CapacityTriggerHandler.onBeforeInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isBefore) {
        CapacityTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isInsert && Trigger.isAfter) {
        CapacityTriggerHandler.onAfterInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isAfter) {
        CapacityTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isDelete && Trigger.isAfter){
        CapacityTriggerHandler.onAfterDelete(Trigger.old);

    }

}