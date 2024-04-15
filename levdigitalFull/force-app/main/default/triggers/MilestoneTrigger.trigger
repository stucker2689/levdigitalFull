trigger MilestoneTrigger on Milestone__c (before insert, after insert, before update, after update, before delete, after delete) {

    if(Trigger.isInsert) { //Insert Trigger Logic
        if(Trigger.isBefore){
            MilestoneTriggerHandler.onBeforeInsert(Trigger.new);
        }else if(Trigger.isAfter){

        }
    }else if(Trigger.isUpdate) { //Update Trigger Logic
        if(Trigger.isBefore){
            MilestoneTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }else if(Trigger.isAfter){
            MilestoneTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }else if(Trigger.isDelete) { //Delete Trigger Logic
        if(Trigger.isBefore){
            MilestoneTriggerHandler.onBeforeDelete(Trigger.Old);
        }else if(Trigger.isAfter){
            
        }
    }

}