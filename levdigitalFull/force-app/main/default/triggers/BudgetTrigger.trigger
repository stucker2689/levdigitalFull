trigger BudgetTrigger on Budget__c (before insert, before update) {
    if(trigger.isInsert) {
        BudgetTriggerHandler.updateRepliconForecast(trigger.new);
    } else if(trigger.isUpdate) {
        BudgetTriggerHandler.setUpdateFlag(true);
        BudgetTriggerHandler.updateRepliconForecast(trigger.new);
    }
}