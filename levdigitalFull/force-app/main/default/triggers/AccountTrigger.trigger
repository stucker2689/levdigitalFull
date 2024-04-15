/**
 * Created by jmahapatra on 11/13/17.
 */

trigger AccountTrigger on Account (before insert, before update, after update) {

    if(Trigger.isInsert){
        if(Trigger.isBefore){
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }else if(Trigger.isAfter){
            //AccountTriggerHandler.afterInsert(Trigger.new);
        }
    }

    if(Trigger.isUpdate){
        if(Trigger.isBefore){
            AccountTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }else if(Trigger.isAfter){
            AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}