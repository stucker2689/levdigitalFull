public with sharing class CapacityTriggerHandler {

    public static void onBeforeInsert(List<Capacity__c> newCapacityList){

    }

    public static void onAfterInsert(List<Capacity__c> newCapacityList){

        List<Date> weekStartDateList = new List<Date>();
        for(Capacity__c cap : newCapacityList){
            if(cap.WeekStartDate__c != null){
                weekStartDateList.add(cap.WeekStartDate__c);
            }   
        }

        if(weekStartDateList.size() > 0){
            LinkTimesheetsToCapacityBatch newTimesheetToCapacityMatchBatch = new LinkTimesheetsToCapacityBatch(weekStartDateList);
            Database.executeBatch(newTimesheetToCapacityMatchBatch, 100);
        }
    }

    public static void onBeforeUpdate(List<Capacity__c> newCapacityList, Map<Id, Capacity__c> oldMap){

    }

    public static void onAfterUpdate(List<Capacity__c> newCapacityList, Map<Id, Capacity__c> oldMap){

    }

    public static void onAfterDelete(List<Capacity__c> newCapacityList){

    }
}