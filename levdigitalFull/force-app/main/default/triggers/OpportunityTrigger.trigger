/**
 * Created by jmahapatra on 11/13/17.
 */

trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, after delete, after undelete) {

    if(Trigger.isInsert){
        if(Trigger.isBefore){
            OpportunityTriggerHandler.beforeInsert(Trigger.new);
        }else if(Trigger.isAfter){
            OpportunityTriggerHandler.afterInsert(Trigger.new);
        }
    }

    if(Trigger.isUpdate){
        if(Trigger.isBefore){
            OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }else if(Trigger.isAfter){
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if(Trigger.isDelete){
        if(Trigger.isBefore){
            //OpportunityTriggerHandler.beforeDelete(Trigger.old);
        }else if(Trigger.isAfter){
            OpportunityTriggerHandler.afterDelete(Trigger.old);
        }
    }

    if(Trigger.isUndelete){
        if(Trigger.isBefore){
            //OpportunityTriggerHandler.beforeUndelete(Trigger.new);
        }else if(Trigger.isAfter){
            OpportunityTriggerHandler.afterUndelete(Trigger.new);
        }
    }
}