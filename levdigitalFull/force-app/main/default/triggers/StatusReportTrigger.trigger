trigger StatusReportTrigger on Status_Report__c (after insert,after update, after delete) {

	if(Trigger.isInsert && Trigger.isAfter){
		StatusReportTriggerHandler.updateProjectFieldsAfterInsert(Trigger.new);
	}

	if(Trigger.isUpdate && Trigger.isAfter){

		StatusReportTriggerHandler.updateProjectFieldsAfterUpdate(Trigger.oldMap,Trigger.newMap);
	}

	if(Trigger.isDelete && Trigger.isAfter){
		StatusReportTriggerHandler.updateProjectFieldsAfterDelete(Trigger.oldMap);
	}

}