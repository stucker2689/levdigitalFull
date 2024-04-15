trigger RevenueForecastTrigger on Revenue_Forecast__c (before insert, after insert, before update, after update) {

    if(Trigger.isBefore && Trigger.isInsert){
        RevenueForecastTriggerHandler.onBeforeInsert(Trigger.new);
    }

	if(Trigger.isAfter && Trigger.isInsert){
        RevenueForecastTriggerHandler.onAfterInsert(Trigger.new);
    }

	if(Trigger.isBefore && Trigger.isUpdate){
        RevenueForecastTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

	if(Trigger.isAfter && Trigger.isUpdate){
        RevenueForecastTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

}