/**
 * Edits:
 * 5/6/2022: Added checks on the onAfterUpdate function so that logic only gets called if a changed has occured to one of the fields is is processing. This is to limit the amount of queries and CPU time that happens during the Replicon Time Entry Callouts
 */
public class RepliconTimeEntryTriggerHandler {

    private final String levPTOProjectId = 'a1q6T000003v4mFQAQ';
    private static String concessionRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:d80618d7-7cbf-5c6d-add9-6336e87ce378';
    

    public static void onBeforeInsert(List<Replicon_Time_Entry__c> newList) {
        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST

        RepliconService newService = new RepliconService();
        newService.populateTimeEntryLookupFields(newList, null);
        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(newList, null, 'onBeforeInsert');

        for(Replicon_Time_Entry__c entry : newList){
            //If entry is nonbillable or concession AND it has comments AND comments AND comments has the Case Prefex record id in it, then add it to list to link to NonBill or Concession Case
            if((entry.Is_Billable__c == false || entry.Replicon_Billing_Rate_URI__c == null || entry.Replicon_Billing_Rate_URI__c == concessionRateURI) && entry.Comments__c != null && (entry.Comments__c).contains('500')){
                nonBillOrConcessionCaseEntryList.add(entry);
            }
        }

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.linkEntryToNonBillOrConcessionCase(nonBillOrConcessionCaseEntryList);
        }
    }
    
    public static void onBeforeUpdate(List<Replicon_Time_Entry__c> newList, Map<Id, Replicon_Time_Entry__c> oldMap) {
        
        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> populateTimeEntryLookupFieldsList = new List<Replicon_Time_Entry__c>();
        
        for(Replicon_Time_Entry__c entry : newList){
            if(oldMap.containsKey(entry.Id)){

                Replicon_Time_Entry__c oldEntry = oldMap.get(entry.Id);

                //If a deleted replicon time entry has it's hours updated then undelete the record
                if(entry.Deleted_in_Replicon__c == true && entry.TotalHrs__c != oldEntry.TotalHrs__c && (oldEntry.TotalHrs__c == 0 || oldEntry.TotalHrs__c == null) && (entry.TotalHrs__c != 0 && entry.TotalHrs__c != null)){
                    entry.Deleted_in_Replicon__c = false;
                }

                if(entry.Replicon_Project_URI__c != oldEntry.Replicon_Project_URI__c || entry.Replicon_Billing_Rate_URI__c != oldEntry.Replicon_Billing_Rate_URI__c || entry.Employee__c != oldEntry.Employee__c || 
                    entry.Replicon_Project_Task_URI__c != oldEntry.Replicon_Project_Task_URI__c || entry.EntryDate__c != oldEntry.EntryDate__c || entry.WeeklyTarget__c != oldEntry.WeeklyTarget__c){

                        populateTimeEntryLookupFieldsList.add(entry);
                }

                if((entry.Is_Billable__c == false || entry.Replicon_Billing_Rate_URI__c == null || entry.Replicon_Billing_Rate_URI__c == concessionRateURI) && entry.Comments__c != null && (entry.Comments__c).contains('500') && entry.Deleted_in_Replicon__c == false){
                    //If the entry is updated to meet these criteria then add to helper method that 
                    nonBillOrConcessionCaseEntryList.add(entry);
                }else if((oldEntry.Is_Billable__c == false || oldEntry.Replicon_Billing_Rate_URI__c == null || oldEntry.Replicon_Billing_Rate_URI__c == concessionRateURI) && oldEntry.Comments__c != null && (oldEntry.Comments__c).contains('500') && oldEntry.Deleted_in_Replicon__c == false){
                    //If the entry used to meet the crieria but the newly updated entry does not then add the entry to the list to get the case removed from the lookup
                    nonBillOrConcessionCaseEntryList.add(entry);
                }
            }
        }
        
        RepliconService newService = new RepliconService();

        if(populateTimeEntryLookupFieldsList.size() > 0){
            newService.populateTimeEntryLookupFields(populateTimeEntryLookupFieldsList, oldMap);
        }

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(newList, oldMap, 'onBeforeUpdate');

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.linkEntryToNonBillOrConcessionCase(nonBillOrConcessionCaseEntryList);
        }
    }
    
    public static void onAfterInsert(List<Replicon_Time_Entry__c> newList) {

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        Set<Id> workDayIdsToRollupList = new Set<Id>();

        for(Replicon_Time_Entry__c entry : newList){

            if(entry.RelatedNonbillOrConcessionCase__c != null && entry.Deleted_in_Replicon__c == false && entry.ActivityName__c != 'BCP'){
                nonBillOrConcessionCaseEntryList.add(entry);
            }
            
            if(entry.Project__c != null){
                projectIdToRollupSet.add(entry.Project__c);
            }

            if(entry.Replicon_Timesheet__c != null){
                timesheetIdToRollupSet.add(entry.Replicon_Timesheet__c);
            }

            if(entry.WeeklyTarget__c != null){
                weeklyTargetIdToRollupSet.add(entry.WeeklyTarget__c);
            }

            if(entry.WorkDay__c != null){
                workDayIdsToRollupList.add(entry.WorkDay__c);
            }

        }

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupNonBillOrConcessionHoursOnCase(nonBillOrConcessionCaseEntryList);
        }

        RepliconService newService = new RepliconService();

        //Rollup Project Values
        //newService.calculateProjectRollupValues(newList);
        if(projectIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                //newService.calculateProjectRollupValues(projectIdToRollupSet);
                if(BatchResource.isRepliconTimeEntryBatchRunning()){
                    //If Time Entry Batch is running then add project ids to the batch resource set to queue all project ids up together for after insert and after update to be recalced in one single queued call
                    BatchResource.addToProjectIdUpdateSet(projectIdToRollupSet);
                }else{
                    System.enqueueJob(new ProjectRollupCalcQueueable(projectIdToRollupSet));
                }
            }else{
                RepliconService.calculateProjectRollupValuesFuture(projectIdToRollupSet);
            }            
        }

        //Rollup Timesheet Values
        //newService.calculateTimesheetRollupValues(newList);
        if(timesheetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                newService.calculateTimesheetRollupValues(timesheetIdToRollupSet);
            }else{
                RepliconService.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
            }
        }

        //Populate Forecast Lookup on Time Entry
        newService.populateTimeEntryForecastLookup(newList);

        //Rollup Weekly Target Actuals
        //newService.calculateWeeklyTargetActualsRollup(newList);
        if(weeklyTargetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                newService.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
            }else{
                RepliconService.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
            }
        }


        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(newList, null, 'onAfterInsert');

        if(workDayIdsToRollupList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(workDayIdsToRollupList);
        }
    }
    
    public static void onAfterUpdate(List<Replicon_Time_Entry__c> newList, Map<Id, Replicon_Time_Entry__c> oldMap) {


        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> rollupEntriesOnProjectList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupEntriesOnTimesheetList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupEntriesOnWeeklyTargetList = new List<Replicon_Time_Entry__c>();

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        Set<Id> workDayIdsToRollupList = new Set<Id>();

        for(Replicon_Time_Entry__c entry : newList){
            Replicon_Time_Entry__c oldEntry = oldMap.get(entry.Id);


            if(entry.TotalHrs__c != oldEntry.TotalHrs__c || entry.EntryDate__c != oldEntry.EntryDate__c || entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c 
                || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Time_Off__c != oldEntry.Time_Off__c){

                    //rollupEntriesOnProjectList.add(entry);
                    if(entry.Project__c != null){
                        projectIdToRollupSet.add(entry.Project__c);
                    }
                    
                    //rollupEntriesOnTimesheetList.add(entry);
                    if(entry.Replicon_Timesheet__c != null){
                        timesheetIdToRollupSet.add(entry.Replicon_Timesheet__c);
                    }

                    //rollupEntriesOnWeeklyTargetList.add(entry);
                    if(entry.WeeklyTarget__c != null){
                        weeklyTargetIdToRollupSet.add(entry.WeeklyTarget__c);
                    }

            }

            if(entry.TotalHrs__c != oldEntry.TotalHrs__c || entry.EntryDate__c != oldEntry.EntryDate__c || entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c 
                || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Time_Off__c != oldEntry.Time_Off__c || entry.WorkDay__c != oldEntry.WorkDay__c || entry.Time_Off_Description__c != oldEntry.Time_Off_Description__c){
                    
                if(entry.WorkDay__c != null){
                    workDayIdsToRollupList.add(entry.WorkDay__c);
                }

                if(entry.WorkDay__c != oldEntry.WorkDay__c && oldEntry.WorkDay__c != null){
                    workDayIdsToRollupList.add(oldEntry.WorkDay__c);
                }
            }

            //Rollup new and/or old project if Project on Entry is Changed
            if(entry.Project__c != oldEntry.Project__c){
                //rollupEntriesOnProjectList.add(entry);
                if(entry.Project__c != null){
                    projectIdToRollupSet.add(entry.Project__c);
                }

                if(oldEntry.Project__c != null){
                    projectIdToRollupSet.add(oldEntry.Project__c);
                }
            }

            //Rollup new and/or old Timesheet if Timesheet on Entry is Changed
            if(entry.Replicon_Timesheet__c != oldEntry.Replicon_Timesheet__c){
                //rollupEntriesOnTimesheetList.add(entry);
                if(entry.Replicon_Timesheet__c != null){
                    timesheetIdToRollupSet.add(entry.Replicon_Timesheet__c);
                }

                if(oldEntry.Replicon_Timesheet__c != null){
                    timesheetIdToRollupSet.add(oldEntry.Replicon_Timesheet__c);
                }  
            }
            
            //Rollup new and/or old Weekly Target if Weekly Target on Entry is Changed
            if(entry.WeeklyTarget__c != oldEntry.WeeklyTarget__c){
                //rollupEntriesOnWeeklyTargetList.add(entry);
                if(entry.WeeklyTarget__c != null){
                    weeklyTargetIdToRollupSet.add(entry.WeeklyTarget__c);
                }

                if(oldEntry.WeeklyTarget__c != null){
                    weeklyTargetIdToRollupSet.add(oldEntry.WeeklyTarget__c);
                } 
            }

            //Rollup Non-bill or Concession Hours on the related Case if the Related Case Changes OR Total Hours Change OR if Entry Billing Rate URI was changed from or to Concession Rate or from or to a Non Bill Rate
            if((entry.RelatedNonbillOrConcessionCase__c != oldEntry.RelatedNonbillOrConcessionCase__c) || (entry.TotalHrs__c != oldEntry.TotalHrs__c) || (entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c)
                || ((oldEntry.Replicon_Billing_Rate_URI__c == concessionRateURI ||  entry.Replicon_Billing_Rate_URI__c == concessionRateURI) && entry.Replicon_Billing_Rate_URI__c != oldEntry.Replicon_Billing_Rate_URI__c) || (entry.Is_Billable__c != oldEntry.Is_Billable__c)
                || (oldEntry.ActivityName__c != entry.ActivityName__c && oldEntry.ActivityName__c == 'BCP' || entry.ActivityName__c =='BCP') && entry.RelatedNonbillOrConcessionCase__c != null){
                nonBillOrConcessionCaseEntryList.add(entry);
            }
            if((oldEntry.RelatedNonbillOrConcessionCase__c != entry.RelatedNonbillOrConcessionCase__c && oldEntry.RelatedNonbillOrConcessionCase__c != null)){
                nonBillOrConcessionCaseEntryList.add(oldEntry);
            }

        }

        RepliconService newService = new RepliconService();

        //Call method Rollup Project Values
        if(projectIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                if(BatchResource.isRepliconTimeEntryBatchRunning()){
                    //If Time Entry Batch is running then add project ids to the batch resource set to queue all project ids up together for after insert and after update to be recalced in one single queued call
                    BatchResource.addToProjectIdUpdateSet(projectIdToRollupSet);
                }else{
                    //System.enqueueJob(new ProjectRollupCalcQueueable(projectIdToRollupSet));
                    newService.calculateProjectRollupValues(projectIdToRollupSet);
                }
            }else{
                RepliconService.calculateProjectRollupValuesFuture(projectIdToRollupSet);
            }
        }

        //Call method to rollup Timesheet Values
        if(timesheetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                newService.calculateTimesheetRollupValues(timesheetIdToRollupSet);
            }else{
                RepliconService.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
            }
        }

        //Call method to rollup Weekly Target Actuals
        if(weeklyTargetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                newService.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
            }else{
                RepliconService.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
            }
        }
        

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(newList, oldMap, 'onAfterUpdate');

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupNonBillOrConcessionHoursOnCase(nonBillOrConcessionCaseEntryList);
        }

        if(workDayIdsToRollupList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(workDayIdsToRollupList);
        }
    }

    public static void onAfterDelete(List<Replicon_Time_Entry__c> newList) {
        
        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> deletedTimeEntriesToRollUpList = new List<Replicon_Time_Entry__c>();

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        Set<Id> workDayIdsToRollupList = new Set<Id>();

        for(Replicon_Time_Entry__c entry : newList){

            if(entry.Deleted_in_Replicon__c == false){
                deletedTimeEntriesToRollUpList.add(entry);

                //Rollup Non-bill or Concession Hours on the related Case if the Related Case Changes OR Total Hours Change OR 
                if(entry.RelatedNonbillOrConcessionCase__c != null){
                    nonBillOrConcessionCaseEntryList.add(entry);
                }

                if(entry.Project__c != null){
                    projectIdToRollupSet.add(entry.Project__c);
                }

                if(entry.Replicon_Timesheet__c != null){
                    timesheetIdToRollupSet.add(entry.Replicon_Timesheet__c);
                }

                if(entry.WeeklyTarget__c != null){
                    weeklyTargetIdToRollupSet.add(entry.WeeklyTarget__c);
                }

                if(entry.WorkDay__c != null){
                    workDayIdsToRollupList.add(entry.WorkDay__c);
                }
            }
        }
        
        if(deletedTimeEntriesToRollUpList.size() > 0){
            RepliconService newService = new RepliconService();

            //newService.calculateProjectRollupValues(deletedTimeEntriesToRollUpList);
            if(projectIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    newService.calculateProjectRollupValues(projectIdToRollupSet);
                    //System.enqueueJob(new ProjectRollupCalcQueueable(projectIdToRollupSet));
                }else{
                    RepliconService.calculateProjectRollupValuesFuture(projectIdToRollupSet);
                }
            }

            //newService.calculateTimesheetRollupValues(deletedTimeEntriesToRollUpList);
            if(timesheetIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    newService.calculateTimesheetRollupValues(timesheetIdToRollupSet);
                }else{
                    RepliconService.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
                }
            }

            //newService.calculateWeeklyTargetActualsRollup(deletedTimeEntriesToRollUpList);
            if(weeklyTargetIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    newService.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
                }else{
                    RepliconService.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
                }
            }

            RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(deletedTimeEntriesToRollUpList, null, 'onAfterInsert');

            if(nonBillOrConcessionCaseEntryList.size() > 0){
                RepliconTimeEntryTriggerHelper.rollupNonBillOrConcessionHoursOnCase(nonBillOrConcessionCaseEntryList);
            }
        }

        if(workDayIdsToRollupList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(workDayIdsToRollupList);
        }
    }
}