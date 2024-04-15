trigger RepliconForecastTrigger on RepliconForecast__C (before insert, after insert, before update, after update, after delete) {

    if(Trigger.isBefore && Trigger.isInsert){
        RepliconForecastTriggerHandler.onBeforeInsert(Trigger.new);
    }

	if(Trigger.isAfter && Trigger.isInsert){
        RepliconForecastTriggerHandler.onAfterInsert(Trigger.new);
    }

	if(Trigger.isBefore && Trigger.isUpdate){
        RepliconForecastTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

	if(Trigger.isAfter && Trigger.isUpdate){
        RepliconForecastTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        RepliconForecastTriggerHandler.onAfterDelete(Trigger.old);
    }

}