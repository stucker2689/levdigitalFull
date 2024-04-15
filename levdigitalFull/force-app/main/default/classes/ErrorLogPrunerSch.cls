global class ErrorLogPrunerSch implements Schedulable{
    global void execute(SchedulableContext SC) {
        List<Error_Log__c> customObj = [select Id FROM Error_Log__c WHERE createddate = LAST_N_DAYS:30];
        if(!customObj.isEmpty())
            delete customObj;
    }
}