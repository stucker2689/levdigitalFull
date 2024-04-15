public with sharing class WorkDayTriggerHandler {

    public static void onBeforeUpdate(List<WorkDay__c> workDayList, Map<Id, WorkDay__c> oldMap){

        List<WorkDay__c> loaUpdatedWorkDayList = new List<WorkDay__c>();

        for(WorkDay__c wd : workDayList){
            WorkDay__c oldWorkDay = oldMap.get(wd.Id);

            if(wd.TotalLOAHours__c != oldWorkDay.TotalLOAHours__c){

                loaUpdatedWorkDayList.add(wd);
            }
        }

        if(loaUpdatedWorkDayList.size() > 0){
            WorkDayTriggerHelper.setWorkDayWorkingHours(loaUpdatedWorkDayList, false);
        }
    }
}