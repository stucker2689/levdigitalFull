public with sharing class TimeEntryTriggerHandler {

    private final String levPTOProjectId = 'a1q6T000003v4mFQAQ';
    private static String concessionRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:d80618d7-7cbf-5c6d-add9-6336e87ce378';

    public static void onBeforeInsert(List<Replicon_Time_Entry__c> entryList){    
        
        populateTimeEntryLookups(entryList);

        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(entryList, null, 'onBeforeInsert');

        for(Replicon_Time_Entry__c entry : entryList){
            //If entry is nonbillable or concession AND it has comments AND comments AND comments has the Case Prefex record id in it, then add it to list to link to NonBill Case
            if((entry.Is_Billable__c == false || entry.Is_Concession__c) && entry.Comments__c != null && (entry.Comments__c).contains('500')){
                nonBillOrConcessionCaseEntryList.add(entry);
            }
        }

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.linkEntryToNonBillOrConcessionCase(nonBillOrConcessionCaseEntryList);
        }
    }

    public static void onAfterInsert(List<Replicon_Time_Entry__c> entryList){
        System.debug('START TimeEntryTriggerHandler onAfterInsert');

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        Set<Id> workDayIdsToRollupList = new Set<Id>();
        Set<Id> forecastIdsToRollupSet = new Set<Id>();

        for(Replicon_Time_Entry__c entry : entryList){

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

            if(entry.Replicon_Forecast__c != null && entry.Associated_Billing_Rate__c != null && entry.TotalHrs__c != 0 && entry.Is_Concession__c ==false && entry.Deleted_in_Replicon__c == false){
                forecastIdsToRollupSet.add(entry.Replicon_Forecast__c);
            }

        }

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupNonBillOrConcessionHoursOnCase(nonBillOrConcessionCaseEntryList);
        }

        //RepliconService newService = new RepliconService();

        //Rollup Project Values
        if(projectIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                System.enqueueJob(new ProjectRollupCalcQueueable(projectIdToRollupSet));
            }else{
                TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Project', projectIdToRollupSet);
                System.enqueueJob(calcBatch);
                //TimeEntryRollupManager.calculateProjectRollupValuesFuture(projectIdToRollupSet);
            }            
        }

        //Rollup Timesheet Values
        if(timesheetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.calculateTimesheetRollupValues(timesheetIdToRollupSet);
            }else{
                //TimeEntryRollupManager.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
                TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Timesheet', timesheetIdToRollupSet);
                System.enqueueJob(calcBatch);
            }
        }

        //Populate Forecast Lookup on Time Entry
        //TimeEntryTriggerHandler.onAfterInsert(entryList);

        //Rollup Weekly Target Actuals
        if(weeklyTargetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
            }else{
                TimeEntryRollupManager.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
            }
        }

        //Rollup Forecast Actuals
        if(forecastIdsToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.rollupTimeActualsOnForecast(forecastIdsToRollupSet);
            }else{
                TimeEntryRollupManager.rollupTimeActualsOnForecastFuture(forecastIdsToRollupSet);
            }
        }

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(entryList, null, 'onAfterInsert');

        if(workDayIdsToRollupList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(workDayIdsToRollupList);
        }

        System.debug('END TimeEntryTriggerHandler onAfterInsert');
    }

    public static void onBeforeUpdate(List<Replicon_Time_Entry__c> entryList, Map<Id, Replicon_Time_Entry__c> oldMap){

        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> populateTimeEntryLookupFieldsList = new List<Replicon_Time_Entry__c>();
        
        for(Replicon_Time_Entry__c entry : entryList){
            if(oldMap.containsKey(entry.Id)){

                Replicon_Time_Entry__c oldEntry = oldMap.get(entry.Id);

                //If a deleted replicon time entry has it's hours updated then undelete the record
                if(entry.Deleted_in_Replicon__c == true && entry.TotalHrs__c != oldEntry.TotalHrs__c && (oldEntry.TotalHrs__c == 0 || oldEntry.TotalHrs__c == null) && (entry.TotalHrs__c != 0 && entry.TotalHrs__c != null)){
                    entry.Deleted_in_Replicon__c = false;
                }

                if(entry.Replicon_Project_URI__c != oldEntry.Replicon_Project_URI__c || entry.Replicon_Billing_Rate_URI__c != oldEntry.Replicon_Billing_Rate_URI__c || entry.Employee__c != oldEntry.Employee__c || 
                    entry.Replicon_Project_Task_URI__c != oldEntry.Replicon_Project_Task_URI__c || entry.EntryDate__c != oldEntry.EntryDate__c || entry.WeeklyTarget__c != oldEntry.WeeklyTarget__c 
                    || entry.Cognizant_Employee_Id__c != oldEntry.Cognizant_Employee_Id__c || entry.Project__c != oldEntry.Project__c || entry.Peoplesoft_Project_Id__c != oldEntry.Peoplesoft_Project_Id__c || entry.Billing_Action__c != oldEntry.Billing_Action__c
                    || entry.Is_Concession__c != oldEntry.Is_Concession__c || entry.Time_Off__c != oldEntry.Time_Off__c || entry.Time_Off_Description__c != oldEntry.Time_Off_Description__c || entry.ForceUpdateCheckbox__c != oldEntry.ForceUpdateCheckbox__c){

                        populateTimeEntryLookupFieldsList.add(entry);
                }

                if((entry.Is_Billable__c == false || entry.Replicon_Billing_Rate_URI__c == null || entry.Replicon_Billing_Rate_URI__c == concessionRateURI || entry.Is_Concession__c) && entry.Comments__c != null && (entry.Comments__c).contains('500') && entry.Deleted_in_Replicon__c == false){
                    //If the entry is updated to meet these criteria then add to helper method that 
                    nonBillOrConcessionCaseEntryList.add(entry);
                }else if((oldEntry.Is_Billable__c == false || oldEntry.Replicon_Billing_Rate_URI__c == null || oldEntry.Replicon_Billing_Rate_URI__c == concessionRateURI || oldEntry.Is_Concession__c) && oldEntry.Comments__c != null && (oldEntry.Comments__c).contains('500') && oldEntry.Deleted_in_Replicon__c == false){
                    //If the entry used to meet the crieria but the newly updated entry does not then add the entry to the list to get the case removed from the lookup
                    nonBillOrConcessionCaseEntryList.add(entry);
                }
            }
        }
        
        //RepliconService newService = new RepliconService();

        if(populateTimeEntryLookupFieldsList.size() > 0){
            populateTimeEntryLookups(entryList);
        }

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(entryList, oldMap, 'onBeforeUpdate');

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.linkEntryToNonBillOrConcessionCase(nonBillOrConcessionCaseEntryList);
        }

        System.debug('END TimeEntryTriggerHandler onBeforeUpdate');
    }

    public static void onAfterUpdate(List<Replicon_Time_Entry__c> entryList, Map<Id, Replicon_Time_Entry__c> oldMap){

        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> rollupEntriesOnProjectList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupEntriesOnTimesheetList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupEntriesOnWeeklyTargetList = new List<Replicon_Time_Entry__c>();

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        Set<Id> workDayIdsToRollupList = new Set<Id>();
        Set<Id> forecastIdsToRollupSet = new Set<Id>();

        for(Replicon_Time_Entry__c entry : entryList){
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
                || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Time_Off__c != oldEntry.Time_Off__c || entry.WorkDay__c != oldEntry.WorkDay__c || entry.Time_Off_Description__c != oldEntry.Time_Off_Description__c
                || entry.Peoplesoft_Project_Id__c != oldEntry.Peoplesoft_Project_Id__c){
                    
                if(entry.WorkDay__c != null){
                    workDayIdsToRollupList.add(entry.WorkDay__c);
                }

                if(entry.WorkDay__c != oldEntry.WorkDay__c && oldEntry.WorkDay__c != null){
                    workDayIdsToRollupList.add(oldEntry.WorkDay__c);
                }
            }

            //Rollup new and/or old project if Project on Entry is Changed
            if(entry.Project__c != oldEntry.Project__c){
                if(entry.Project__c != null){
                    projectIdToRollupSet.add(entry.Project__c);
                }

                if(oldEntry.Project__c != null){
                    projectIdToRollupSet.add(oldEntry.Project__c);
                }
            }

            //Rollup new and/or old Timesheet if Timesheet on Entry is Changed
            if(entry.Replicon_Timesheet__c != oldEntry.Replicon_Timesheet__c){
                if(entry.Replicon_Timesheet__c != null){
                    timesheetIdToRollupSet.add(entry.Replicon_Timesheet__c);
                }

                if(oldEntry.Replicon_Timesheet__c != null){
                    timesheetIdToRollupSet.add(oldEntry.Replicon_Timesheet__c);
                }  
            }
            
            //Rollup new and/or old Weekly Target if Weekly Target on Entry is Changed
            if(entry.WeeklyTarget__c != oldEntry.WeeklyTarget__c){
                if(entry.WeeklyTarget__c != null){
                    weeklyTargetIdToRollupSet.add(entry.WeeklyTarget__c);
                }

                if(oldEntry.WeeklyTarget__c != null){
                    weeklyTargetIdToRollupSet.add(oldEntry.WeeklyTarget__c);
                } 
            }

            //Rollup new and/or old Forecast ST 12.12.2023
            if(entry.Replicon_Forecast__c != oldEntry.Replicon_Forecast__c || entry.TotalHrs__c != oldEntry.TotalHrs__c || entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c
                || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Is_Concession__c != oldEntry.Is_Concession__c){
                if(entry.Replicon_Forecast__c != null){
                    forecastIdsToRollupSet.add(entry.Replicon_Forecast__c);
                }

                if(entry.Replicon_Forecast__c != oldEntry.Replicon_Forecast__c && oldEntry.Replicon_Forecast__c != null){
                    forecastIdsToRollupSet.add(oldEntry.Replicon_Forecast__c);
                }
            }

            //Rollup Non-bill or Concession Hours on the related Case if the Related Case Changes OR Total Hours Change OR if Entry Billing Rate URI was changed from or to Concession Rate or from or to a Non Bill Rate
            if((entry.RelatedNonbillOrConcessionCase__c != oldEntry.RelatedNonbillOrConcessionCase__c) || (entry.TotalHrs__c != oldEntry.TotalHrs__c) || (entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c)
                || ((oldEntry.Replicon_Billing_Rate_URI__c == concessionRateURI ||  entry.Replicon_Billing_Rate_URI__c == concessionRateURI || oldEntry.Is_Concession__c == true || entry.Is_Concession__c == true) && (oldEntry.Is_Concession__c != entry.Is_Concession__c || entry.Replicon_Billing_Rate_URI__c != oldEntry.Replicon_Billing_Rate_URI__c)) || (entry.Is_Billable__c != oldEntry.Is_Billable__c)
                || (oldEntry.ActivityName__c != entry.ActivityName__c && oldEntry.ActivityName__c == 'BCP' || entry.ActivityName__c =='BCP') && entry.RelatedNonbillOrConcessionCase__c != null){
                nonBillOrConcessionCaseEntryList.add(entry);
            }
            if((oldEntry.RelatedNonbillOrConcessionCase__c != entry.RelatedNonbillOrConcessionCase__c && oldEntry.RelatedNonbillOrConcessionCase__c != null)){
                nonBillOrConcessionCaseEntryList.add(oldEntry);
            }

        }

        //RepliconService newService = new RepliconService();

        //Call method Rollup Project Values
        if(projectIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.calculateProjectRollupValues(projectIdToRollupSet);
            }else{
                //TimeEntryRollupManager.calculateProjectRollupValuesFuture(projectIdToRollupSet);
                TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Project', projectIdToRollupSet);
                System.enqueueJob(calcBatch);
            }
        }

        //Call method to rollup Timesheet Values
        if(timesheetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.calculateTimesheetRollupValues(timesheetIdToRollupSet);
            }else{
                //TimeEntryRollupManager.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
                TimeEntryRollupCalcBatch calcBatch = new TimeEntryRollupCalcBatch('Timesheet', timesheetIdToRollupSet);
                System.enqueueJob(calcBatch);
            }
        }

        //Call method to rollup Weekly Target Actuals
        if(weeklyTargetIdToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
            }else{
                TimeEntryRollupManager.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
            }
        }

        //Rollup Forecast Actuals
        if(forecastIdsToRollupSet.size() > 0){
            if(System.isBatch() || System.isFuture()){
                TimeEntryRollupManager.rollupTimeActualsOnForecast(forecastIdsToRollupSet);
            }else{
                TimeEntryRollupManager.rollupTimeActualsOnForecastFuture(forecastIdsToRollupSet);
            }
        }        

        RepliconTimeEntryTriggerHelper.RepliconTimeEntryTriggerHelper_Manager(entryList, oldMap, 'onAfterUpdate');

        if(nonBillOrConcessionCaseEntryList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupNonBillOrConcessionHoursOnCase(nonBillOrConcessionCaseEntryList);
        }

        if(workDayIdsToRollupList.size() > 0){
            RepliconTimeEntryTriggerHelper.rollupWorkDayValues(workDayIdsToRollupList);
        }
    }

    public static void onBeforeDelete(List<Replicon_Time_Entry__c> entryList){

    }

    public static void onAfterDelete(List<Replicon_Time_Entry__c> entryList){

        List<Replicon_Time_Entry__c> nonBillOrConcessionCaseEntryList = new List<Replicon_Time_Entry__c>(); //Added 9.1.22 ST
        List<Replicon_Time_Entry__c> deletedTimeEntriesToRollUpList = new List<Replicon_Time_Entry__c>();

        Set<Id> projectIdToRollupSet = new Set<Id>();
        Set<Id> timesheetIdToRollupSet = new Set<Id>();
        Set<Id> weeklyTargetIdToRollupSet = new Set<Id>();
        Set<Id> workDayIdsToRollupList = new Set<Id>();
        Set<Id> forecastIdsToRollupSet = new Set<Id>();

        for(Replicon_Time_Entry__c entry : entryList){

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

                if(entry.Replicon_Forecast__c != null && entry.TotalHrs__c != 0 && entry.Associated_Billing_Rate__c != null && entry.Is_Concession__c != null && entry.Deleted_in_Replicon__c == false){
                    forecastIdsToRollupSet.add(entry.Replicon_Forecast__c);
                }
            }
        }
        
        if(deletedTimeEntriesToRollUpList.size() > 0){
            //RepliconService newService = new RepliconService();

            if(projectIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    TimeEntryRollupManager.calculateProjectRollupValues(projectIdToRollupSet);
                }else{
                    TimeEntryRollupManager.calculateProjectRollupValuesFuture(projectIdToRollupSet);
                }
            }

            if(timesheetIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    TimeEntryRollupManager.calculateTimesheetRollupValues(timesheetIdToRollupSet);
                }else{
                    TimeEntryRollupManager.calculateTimesheetRollupValuesFuture(timesheetIdToRollupSet);
                }
            }

            if(weeklyTargetIdToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    TimeEntryRollupManager.calculateWeeklyTargetActualsRollup(weeklyTargetIdToRollupSet);
                }else{
                    TimeEntryRollupManager.calculateWeeklyTargetActualsRollupFuture(weeklyTargetIdToRollupSet);
                }
            }

            //Rollup Forecast Actuals
            if(forecastIdsToRollupSet.size() > 0){
                if(System.isBatch() || System.isFuture()){
                    TimeEntryRollupManager.rollupTimeActualsOnForecast(forecastIdsToRollupSet);
                }else{
                    TimeEntryRollupManager.rollupTimeActualsOnForecastFuture(forecastIdsToRollupSet);
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


    /*public static void onBeforeInsert(List<Replicon_Time_Entry__c> entryList){
        System.debug('START TimeEntryTriggerHandler onBeforeInsert');
        List<Replicon_Time_Entry__c> timeEntryForNameList = new List<Replicon_Time_Entry__c>(); //For creating Names for Time Entries
        Map<Replicon_Time_Entry__c, String> timeEntryToCogEmployeeIdMap = new Map<Replicon_Time_Entry__c, String>(); //For linking employees
        Map<Replicon_Time_Entry__c, String> timeEntryToPeoplesoftProjectIdMap = new Map<Replicon_Time_Entry__c, String>(); //For linking Projects
        List<Replicon_Time_Entry__c> timeEntryToFindTimesheetList = new List<Replicon_Time_Entry__c>(); //For linking Timesheets
        List<Replicon_Time_Entry__c> timeEntryToFindBillingRateList = new List<Replicon_Time_Entry__c>(); //For linking Billing Rates
        List<Replicon_Time_Entry__c> timeEntryToLinkWeeklyTargetList = new List<Replicon_Time_Entry__c>(); //For linking Weekly Targets (Revenue Forecasts)
        List<Replicon_Time_Entry__c> timeEntryToLinkWorkDaysList = new List<Replicon_Time_Entry__c>(); //For linking Weekly Targets (Revenue Forecasts)

        for(Replicon_Time_Entry__c entry : entryList){
            //Create Name for Time Entry
            if(entry.Name == null){
                timeEntryForNameList.add(entry);
            }
            //Link Employee for Time Entry
            if(entry.Cognizant_Employee_Id__c != null && entry.Employee__c == null){
                timeEntryToCogEmployeeIdMap.put(entry, entry.Cognizant_Employee_Id__c);
            }
            //Link Project for Time Entry
            if(entry.Peoplesoft_Project_Id__c != null && entry.Project__c == null){
                timeEntryToPeoplesoftProjectIdMap.put(entry, entry.Peoplesoft_Project_Id__c);
            }
            //Link (or Create) Timesheet for Time Entry
            if(entry.Employee__c != null && entry.EntryDate__c != null && entry.Replicon_Timesheet__c == null){
                timeEntryToFindTimesheetList.add(entry);
            }
            //Link Billing Rate
            if(entry.Employee__c != null && entry.Project__c != null && entry.Billing_Action__c == 'B' && entry.Associated_Billing_Rate__c == null){
                timeEntryToFindBillingRateList.add(entry);
            }
            //Link Weekly Target (Revenue Forecast) for Time Entry
            if(entry.EntryDate__c != null && entry.WeeklyTarget__c == null){
                timeEntryToLinkWeeklyTargetList.add(entry);
            }
            //Link Work Day for Time Entry
            if(entry.Employee__c != null && entry.EntryDate__c != null && entry.WorkDay__c == null){
                timeEntryToLinkWorkDaysList.add(entry);
            }
        }

        //Populate Name
        if(timeEntryForNameList.size() > 0){
            TimeEntryService.populateTimeEntryName(timeEntryForNameList, false);
        }

        //Populate Employee Lookup
        if(timeEntryToCogEmployeeIdMap.size() > 0){        
            TimeEntryService.populateTimeEntryEmployee(timeEntryToCogEmployeeIdMap, false);
        }

        //Populate Project, Opportunity, and Account Field Lookups on Time Entry
        if(timeEntryToPeoplesoftProjectIdMap.size() > 0){
            TimeEntryService.populateTimeEntryProject(timeEntryToPeoplesoftProjectIdMap, false);
        }

        //Populate Timesheet(){
        if(timeEntryToFindTimesheetList.size() > 0){
            TimeEntryService.populateTimeEntryTimesheet(timeEntryToFindTimesheetList, false);
        }

        //Populate Associated Billing Rate field
        if(timeEntryToFindBillingRateList.size() > 0){
            TimeEntryService.populateTimeEntryBillingRate(timeEntryToFindBillingRateList, false);
        }

        //Populate Revenue Forecast(Weekly Target Lookup) WeeklyTarget__c
        if(timeEntryToLinkWeeklyTargetList.size() > 0){
            TimeEntryService.populateTimeEntryWeeklyTarget(timeEntryToLinkWeeklyTargetList, false);
        }

        //Populate Work Day
        if(timeEntryToLinkWorkDaysList.size() > 0){
            TimeEntryService.populateTimeEntryWorkDay(timeEntryToLinkWorkDaysList, false);
        }
        System.debug('END TimeEntryTriggerHandler onBeforeInsert');
    }*/

    public static void populateTimeEntryLookups(List<Replicon_Time_Entry__c> entryList){
        TimeEntryService.populateTimeEntryEmployee(entryList, false);
        TimeEntryService.populateTimeEntryProject(entryList, false);
        TimeEntryService.populateTimeEntryName(entryList, false);  
        TimeEntryService.populateTimeEntryUniqueName(entryList, false); 
        TimeEntryService.populateTimeEntryTimesheet(entryList, false);
        TimeEntryService.populateTimeEntryProjectTeamMember(entryList, false);
        TimeEntryService.populateTimeEntryBillingRate(entryList, false);
        TimeEntryService.populateTimeEntryWeeklyTarget(entryList, false);
        TimeEntryService.populateTimeEntryWorkDay(entryList, false);
        TimeEntryService.populateTimeEntryForecast(entryList, false);
    }
}