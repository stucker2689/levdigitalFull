trigger OppLineTrigger on OpportunityLineItem (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    if(Trigger.isBefore && Trigger.isInsert){
        OppLineTriggerHandler.onBeforeInsert(Trigger.new);
    }

	if(Trigger.isAfter && Trigger.isInsert){
        OppLineTriggerHandler.onAfterInsert(Trigger.new);
    }

	if(Trigger.isBefore && Trigger.isUpdate){
        OppLineTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

	if(Trigger.isAfter && Trigger.isUpdate){
        OppLineTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        OppLineTriggerHandler.onBeforeDelete(Trigger.old, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        OppLineTriggerHandler.onAfterDelete(Trigger.old, Trigger.oldMap);
    }

    /*if(Trigger.isAfter && Trigger.isUnDelete){
        OppLineTriggerHandler.onAfterUnDelete(Trigger.new, Trigger.oldMap);
    }*/
}