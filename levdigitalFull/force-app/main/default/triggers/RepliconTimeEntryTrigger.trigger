trigger RepliconTimeEntryTrigger on Replicon_Time_Entry__c (before insert, before update, after insert, after update, after delete) {
    if(Trigger.isInsert && Trigger.isBefore) {
        System.debug('--------------------------TimeEntryTrigger Before Insert-----------------------------');
        //RepliconTimeEntryTriggerHandler.onBeforeInsert(Trigger.new);
        TimeEntryTriggerHandler.onBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore) {
        System.debug('--------------------------TimeEntryTrigger Before Update-----------------------------');
        //RepliconTimeEntryTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        TimeEntryTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }   
    else if(Trigger.isInsert && Trigger.isAfter) {
        System.debug('--------------------------TimeEntryTrigger After Insert-----------------------------');
        //RepliconTimeEntryTriggerHandler.onAfterInsert(Trigger.new);
        TimeEntryTriggerHandler.onAfterInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isAfter) {
        System.debug('--------------------------TimeEntryTrigger After Update-----------------------------');
        //RepliconTimeEntryTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        TimeEntryTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }else if(Trigger.isDelete && Trigger.isAfter){
        System.debug('--------------------------TimeEntryTrigger After Delete-----------------------------');
        //RepliconTimeEntryTriggerHandler.onAfterDelete(Trigger.old);
        TimeEntryTriggerHandler.onAfterDelete(Trigger.old);
    }



    /*if(Trigger.isInsert && Trigger.isBefore) {
        System.debug('--------------------------TimeEntryTrigger Before Insert-----------------------------');
        TimeEntryTriggerHandler.onBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore) {
        System.debug('--------------------------TimeEntryTrigger Before Update-----------------------------');
        TimeEntryTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }   
    else if(Trigger.isInsert && Trigger.isAfter) {
        System.debug('--------------------------TimeEntryTrigger After Insert-----------------------------');
        TimeEntryTriggerHandler.onAfterInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isAfter) {
        System.debug('--------------------------TimeEntryTrigger After Update-----------------------------');
        TimeEntryTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }else if(Trigger.isDelete && Trigger.isAfter){
        System.debug('--------------------------TimeEntryTrigger After Delete-----------------------------');
        TimeEntryTriggerHandler.onAfterDelete(Trigger.old);
    }*/
}