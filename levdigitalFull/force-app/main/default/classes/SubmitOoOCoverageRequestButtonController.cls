public with sharing class SubmitOoOCoverageRequestButtonController {


    @AuraEnabled(cacheable = true)
    public static Id getLevStaffingQueue(){
        Id levStaffingQueueId;
        levStaffingQueueId = [SELECT Id, Name, Type FROM Group WHERE Name Like 'Lev - Staffing' and Type = 'Queue' LIMIT 1].Id;

        return levStaffingQueueId;
    }
}