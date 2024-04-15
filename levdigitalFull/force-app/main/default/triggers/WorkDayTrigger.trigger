trigger WorkDayTrigger on WorkDay__c (before update) {

	if(Trigger.isBefore && Trigger.isUpdate){
        WorkDayTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}