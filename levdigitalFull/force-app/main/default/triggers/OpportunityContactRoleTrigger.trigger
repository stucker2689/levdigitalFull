trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, after insert, before update, after update, before delete, after delete) {


    if(Trigger.isBefore && Trigger.isInsert){
        OpportunityContactRoleTriggerHandler.beforeInsert(trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert){
        OpportunityContactRoleTriggerHandler.afterInsert(trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate){
        OpportunityContactRoleTriggerHandler.beforeUpdate(trigger.new, trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        OpportunityContactRoleTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        OpportunityContactRoleTriggerHandler.beforeDelete(trigger.old);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        OpportunityContactRoleTriggerHandler.afterDelete(trigger.old, trigger.oldMap);
    }


}