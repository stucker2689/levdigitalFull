trigger WorkTrigger on Work__c (before insert, before update, after insert, after update, after delete) {

    if(Trigger.isInsert && Trigger.isBefore) {
        WorkTriggerHandler.onBeforeInsert(Trigger.new);

    }else if(Trigger.isInsert && Trigger.isAfter) {
        WorkTriggerHandler.onAfterInsert(Trigger.new);

    }else if(Trigger.isUpdate && Trigger.isBefore) {
        WorkTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isUpdate && Trigger.isAfter) {
        WorkTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);

    }else if(Trigger.isDelete && Trigger.isAfter){
        WorkTriggerHandler.onAfterDelete(Trigger.old);

    }    
}