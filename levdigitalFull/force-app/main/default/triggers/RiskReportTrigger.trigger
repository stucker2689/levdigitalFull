/**
 * Created 7/7/2022 ST
 * 
 * Handle Trigger Logic on Risk Report
 */
trigger RiskReportTrigger on Risk_Report__c (before insert, after insert, before update, after update) {

    if(Trigger.isBefore && Trigger.isInsert){
        RiskReportTriggerHandler.onBeforeInsert(Trigger.new);
    }

	if(Trigger.isBefore && Trigger.isUpdate){
        RiskReportTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}