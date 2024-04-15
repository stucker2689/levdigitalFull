public with sharing class TimeEntryRollupManager {

    private final String placeholderProjectId = 'a1q6T000003v2K0QAI';
    private final String levPTOProjectId = 'a1q6T000003v4mFQAQ';
    //private final String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

    private String temporaryRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:37d7b492-622f-4063-a7b6-e4a698e9f892';
    private String concessionRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:d80618d7-7cbf-5c6d-add9-6336e87ce378';

    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId(); //RecordTypeId of the Weekly Target RT of Revenue Forecasts


     //Calculates rollup values from time entry to project. This will fail if the projects in the transaction have 50,000 child time entries. 
    //If you want to add a new calculated rollup, just go down to the part with 4 steps and update the test code.
    //James Qian, September 2018
    public static void calculateProjectRollupValues(Set<Id> projectIdSet) {
        try {
            String levPTOProjectId = 'a1q6T000003v4mFQAQ';
            //Set current dates 
            Date todaysDate = Date.today();
            Integer currentMonth = todaysDate.month();
            Integer currentYear = todaysDate.year();
            Date dateOfPreviousSaturday = todaysDate.toStartOfWeek().addDays(-1); //Added 5/4/2022 - Goes to the Sunday of todays Week, then goes one more day back to get the previous Saturday

            Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

            //Get all project IDs in trigger.new for querying existing records
            List<Project__c> projectUpdateList = new List<Project__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentProjectMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            List<Id> projectIdsWithNoActiveTimeEntriesList = new List<Id>();
            Map<Id, Project__c> projectWithNoActiveEntriesUpdateMap = new Map<Id, Project__c>();
            for(Id projId : projectIdSet) {
                //if(currentEntry.Project__c != NULL && !currentEntry.Deleted_in_Replicon__c) { Commented this out 4/19 Sam Tucker
                //Added on 4/19 - Sam Tucker
                if(projId != NULL && projId != levPTOProjectId) {
                    parentProjectMap.put(projId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }

            Map<Id, Replicon_Time_Entry__c> projectIdToProjectRelationshipFieldsMap = new Map<Id, Replicon_Time_Entry__c>();
            //Query existing records and put into a map for searching/deduplication
            if(parentProjectMap.keyset().size() > 0) {
                //Step 1 - Add to query                    
                for(Replicon_Time_Entry__c queriedTimeEntry : [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, ActivityName__c,
                                                                        Override_Billing_Rate__c, TotalHrs__c, Project__c, Deleted_in_Replicon__c, EntryDate__c, Project__r.Name,
                                                                        Project__r.Rollup_Billable__c , Project__r.Rollup_Concession__c, Project__r.Rollup_Nonbillable__c, Project__r.Rollup_Revenue__c,
                                                                        Project__r.Replicon_Hours_This_Month__c, Project__r.PreviousWeeksBillableHrs__c, Project__r.BudgetRemainingasofPrevWeek__c,  Project__r.BCPNonbillableHours__c,
                                                                        Project__r.NonLevTotalNonBillableHours__c, Project__r.NonLevRevenueAmountBooked__c, Project__r.NonLevNonBillHours__c, Project__r.NonLevBillableHoursBooked__c,
                                                                        Employee__r.Name, Employee__r.Account.Name
                                                                        FROM Replicon_Time_Entry__c 
                                                                        WHERE Project__c IN :parentProjectMap.keyset()
                                                                        AND Deleted_in_Replicon__c = false]) {
                    Map<Id, Replicon_Time_Entry__c> projectTimeEntryMap = parentProjectMap.get(queriedTimeEntry.Project__c);
                    projectTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                    parentProjectMap.put(queriedTimeEntry.Project__c, projectTimeEntryMap); 
                    if(!projectIdToProjectRelationshipFieldsMap.containsKey(queriedTimeEntry.Project__c)){
                        projectIdToProjectRelationshipFieldsMap.put(queriedTimeEntry.Project__c, queriedTimeEntry);
                    }
                }

                for(Id projectID : parentProjectMap.keyset()){
                    //Loop through Project
                    if(!projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                        projectIdsWithNoActiveTimeEntriesList.add(projectID);
                    }
                }

                if(projectIdsWithNoActiveTimeEntriesList.size() > 0){
                    Map<Id, Project__c> projWithNoActiveEntriesMap = new Map<Id, Project__c>([SELECT Id, Name, Rollup_Billable__c , Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c,
                                                                                                Replicon_Hours_This_Month__c, PreviousWeeksBillableHrs__c, BudgetRemainingasofPrevWeek__c, 
                                                                                                NonLevTotalNonBillableHours__c, NonLevRevenueAmountBooked__c, NonLevNonBillHours__c, NonLevBillableHoursBooked__c, BCPNonbillableHours__c
                                                                                                FROM Project__c 
                                                                                                WHERE Id IN :projectIdsWithNoActiveTimeEntriesList]);
                    if(projWithNoActiveEntriesMap.size() > 0){
                        projectWithNoActiveEntriesUpdateMap.putAll(projWithNoActiveEntriesMap); 
                    }
                }
            }

            //Loop through structure to calculate rollup values
            for(Id projectID : parentProjectMap.keyset()) {

                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupRevenue = 0;
                Decimal rollupBillableHoursThisMonth = 0;
                Decimal rollupPreviousWeeksBillableHours = 0;
                Decimal rollupBudgetRemainingAsOfPrevWeek = 0;
                Decimal rollupBCPNonBillHours = 0; //Added 9.2.22 ST To rollup BCP Non Bill Hours

                //Lev and Non Lev Rollups
                Decimal levBillableHours = 0;
                Decimal nonLevBillableHours = 0;
                Decimal levNonBillableHours = 0;
                Decimal nonLevNonBillableHours = 0;
                Decimal levConcessionHours = 0;
                Decimal nonLevConcessionHours = 0;
                Decimal levRevenue = 0;
                Decimal nonLevRevenue = 0;
                Decimal nonLevTotalNonBillAndConcessionHours = 0;
                Decimal levBillableHoursAsOfLastWeek = 0;
                Decimal nonLevBillableHoursAsOfLastWeek = 0;
                Decimal levRevenueAmountAsOfLastWeek = 0;
                Decimal nonLevRevenueAmountAsOfLastWeek = 0;
                
                
                for(Id timeEntryID : parentProjectMap.get(projectID).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentProjectMap.get(projectID).get(timeEntryID);

                    Boolean isLevTime = false;
                    if((currentEntry.EntryDate__c < switchToATGTimeDate && currentEntry.Employee__r.Name != atgConsultantContactName) 
                    || (currentEntry.EntryDate__c >= switchToATGTimeDate && currentEntry.Employee__r.Account.Name == levementumAccountName && currentEntry.Employee__r.Name != atgConsultantContactName)){
                        isLevTime = true;
                    }

                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true && currentEntry.TotalHrs__c != null){
                        //New Rollup Calculation Step 2 - Criteria
                        if((currentEntry.Override_Billing_Rate__c != null || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Billable Hours
                            if(isLevTime){
                                levBillableHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevBillableHours += currentEntry.TotalHrs__c;
                            }

                            //Replicon Billable Hours for Current Month DLRS Replacement
                            if(currentEntry.EntryDate__c.month() == currentMonth && currentEntry.EntryDate__c.year() == currentYear){
                                rollupBillableHoursThisMonth += currentEntry.TotalHrs__c;
                            }
                            //Replicon Billable Hours as of Previous Week DLRS Replacement 
                            //Replicon Budget Remaining as of Previous Week DLRS Replacement
                            if(currentEntry.EntryDate__c <= dateOfPreviousSaturday){
                                //Changing Total Hours/Budget as of last week to Lev only ST 4.3.23
                                if(isLevTime){
                                    System.debug('currentEntry.TotalHrs__c: ' + currentEntry.TotalHrs__c);
                                    rollupPreviousWeeksBillableHours += currentEntry.TotalHrs__c;
                                    rollupBudgetRemainingAsOfPrevWeek += currentEntry.Billable_Amount__c;
                                }

                                //Lev or Non Lev Hours and Revenue as of Last Week
                                if(isLevTime){
                                    levBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    levRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }else{
                                    nonLevBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    nonLevRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }
                            }
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;

                            //Lev or Non Lev Concession Hours
                            if(isLevTime){
                                levConcessionHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevConcessionHours += currentEntry.TotalHrs__c;
                            }

                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Non Billable Hours
                            if(isLevTime){
                                if(currentEntry.ActivityName__c == 'BCP'){
                                    rollupBCPNonBillHours += currentEntry.TotalHrs__c; //Added 9.2.22 ST
                                }else{
                                    levNonBillableHours += currentEntry.TotalHrs__c;
                                }
                            }else{
                                nonLevNonBillableHours += currentEntry.TotalHrs__c;
                            }
                        }
                        if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
                            rollupRevenue += currentEntry.Billable_Amount__c;

                            //Lev or Non-Lev Revenue
                            if(isLevTime){
                                levRevenue += currentEntry.Billable_Amount__c;
                            }else{
                                nonLevRevenue += currentEntry.Billable_Amount__c;
                            }
                        }

                        nonLevTotalNonBillAndConcessionHours = nonLevNonBillableHours + nonLevConcessionHours;

                    }
                }

                //Lev and Non Lev Project Rollup ST 6/22/2022
                if(projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                    Replicon_Time_Entry__c projectRelatedEntry = projectIdToProjectRelationshipFieldsMap.get(projectID);

                    if(projectRelatedEntry.Project__r.Rollup_Billable__c != levBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Concession__c != levConcessionHours 
                    || projectRelatedEntry.Project__r.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Revenue__c != levRevenue 
                    || projectRelatedEntry.Project__r.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectRelatedEntry.Project__r.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectRelatedEntry.Project__r.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectRelatedEntry.Project__r.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectRelatedEntry.Project__r.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectRelatedEntry.Project__r.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectRelatedEntry.Project__r.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectRelatedEntry.Project__r.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }
                }else if(projectWithNoActiveEntriesUpdateMap.containsKey(projectID)){
                    Project__c projectToUpdate = projectWithNoActiveEntriesUpdateMap.get(projectID);

                    if(projectToUpdate.Rollup_Billable__c != levBillableHours 
                    || projectToUpdate.Rollup_Concession__c != levConcessionHours 
                    || projectToUpdate.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectToUpdate.Rollup_Revenue__c != levRevenue 
                    || projectToUpdate.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectToUpdate.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectToUpdate.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectToUpdate.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectToUpdate.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectToUpdate.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectToUpdate.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectToUpdate.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }



                }
            }

            /************************************************************************************************************************/

            if(projectUpdateList.size() > 0) {
                System.debug('***************************Updating ' + projectUpdateList.size() + ' Project Rollup Values*******************************');
                update projectUpdateList;
            }else{
                System.debug('***************************No Project Rollup Values Calculated*******************************');
            }            
        }
        catch(Exception e) {
            System.debug('calculateProjectRollupValues');
            System.debug(e);
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateProjectRollupValues', NULL);
        }
    }

    @future(callout=false)
    public static void calculateProjectRollupValuesFuture(Set<Id> projectIdSet) {
        try {
            String levPTOProjectId = 'a1q6T000003v4mFQAQ';
            //Set current dates 
            Date todaysDate = Date.today();
            Integer currentMonth = todaysDate.month();
            Integer currentYear = todaysDate.year();
            Date dateOfPreviousSaturday = todaysDate.toStartOfWeek().addDays(-1); //Added 5/4/2022 - Goes to the Sunday of todays Week, then goes one more day back to get the previous Saturday

            Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

            //Get all project IDs in trigger.new for querying existing records
            List<Project__c> projectUpdateList = new List<Project__c>();
            Map<Id, Project__c> projectUpdateMap = new Map<Id, Project__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentProjectMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            List<Id> projectIdsWithNoActiveTimeEntriesList = new List<Id>();
            Map<Id, Project__c> projectWithNoActiveEntriesUpdateMap = new Map<Id, Project__c>();
            for(Id projId : projectIdSet) {
                //if(currentEntry.Project__c != NULL && !currentEntry.Deleted_in_Replicon__c) { Commented this out 4/19 Sam Tucker
                //Added on 4/19 - Sam Tucker
                if(projId != NULL && projId != levPTOProjectId) {
                    parentProjectMap.put(projId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }

            Map<Id, Replicon_Time_Entry__c> projectIdToProjectRelationshipFieldsMap = new Map<Id, Replicon_Time_Entry__c>();
            //Query existing records and put into a map for searching/deduplication
            if(parentProjectMap.keyset().size() > 0) {
                //Step 1 - Add to query
                List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, ActivityName__c, Replicon_Project_URI__c,
                                                                           Override_Billing_Rate__c, TotalHrs__c, Project__c, Deleted_in_Replicon__c, EntryDate__c, Project__r.Name,
                                                                           Project__r.Rollup_Billable__c , Project__r.Rollup_Concession__c, Project__r.Rollup_Nonbillable__c, Project__r.Rollup_Revenue__c,
                                                                           Project__r.Replicon_Hours_This_Month__c, Project__r.PreviousWeeksBillableHrs__c, Project__r.BudgetRemainingasofPrevWeek__c,  Project__r.BCPNonbillableHours__c,
                                                                           Project__r.NonLevTotalNonBillableHours__c, Project__r.NonLevRevenueAmountBooked__c, Project__r.NonLevNonBillHours__c, Project__r.NonLevBillableHoursBooked__c,
                                                                           Employee__r.Name, Employee__r.Account.Name
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Project__c IN :parentProjectMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false];

                if(queriedExistingTimeEntries.size() > 0){
                    
                    for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                        Map<Id, Replicon_Time_Entry__c> projectTimeEntryMap = parentProjectMap.get(queriedTimeEntry.Project__c);
                        projectTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                        parentProjectMap.put(queriedTimeEntry.Project__c, projectTimeEntryMap); 
                        if(!projectIdToProjectRelationshipFieldsMap.containsKey(queriedTimeEntry.Project__c)){
                            projectIdToProjectRelationshipFieldsMap.put(queriedTimeEntry.Project__c, queriedTimeEntry);
                        }
                    }
                }

                for(Id projectID : parentProjectMap.keyset()){
                    //Loop through Project
                    if(!projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                        projectIdsWithNoActiveTimeEntriesList.add(projectID);
                    }
                }

                if(projectIdsWithNoActiveTimeEntriesList.size() > 0){
                    Map<Id, Project__c> projWithNoActiveEntriesMap = new Map<Id, Project__c>([SELECT Id, Name, Rollup_Billable__c , Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c,
                                                                                                Replicon_Hours_This_Month__c, PreviousWeeksBillableHrs__c, BudgetRemainingasofPrevWeek__c, 
                                                                                                NonLevTotalNonBillableHours__c, NonLevRevenueAmountBooked__c, NonLevNonBillHours__c, NonLevBillableHoursBooked__c, BCPNonbillableHours__c
                                                                                                FROM Project__c 
                                                                                                WHERE Id IN :projectIdsWithNoActiveTimeEntriesList]);
                    if(projWithNoActiveEntriesMap.size() > 0){
                        projectWithNoActiveEntriesUpdateMap.putAll(projWithNoActiveEntriesMap); 
                    }
                }
            }

            //Loop through structure to calculate rollup values
            for(Id projectID : parentProjectMap.keyset()) {

                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupRevenue = 0;
                Decimal rollupBillableHoursThisMonth = 0;
                Decimal rollupPreviousWeeksBillableHours = 0;
                Decimal rollupBudgetRemainingAsOfPrevWeek = 0;
                Decimal rollupBCPNonBillHours = 0; //Added 9.2.22 ST To rollup BCP Non Bill Hours

                //Lev and Non Lev Rollups
                Decimal levBillableHours = 0;
                Decimal nonLevBillableHours = 0;
                Decimal levNonBillableHours = 0;
                Decimal nonLevNonBillableHours = 0;
                Decimal levConcessionHours = 0;
                Decimal nonLevConcessionHours = 0;
                Decimal levRevenue = 0;
                Decimal nonLevRevenue = 0;
                Decimal nonLevTotalNonBillAndConcessionHours = 0;
                Decimal levBillableHoursAsOfLastWeek = 0;
                Decimal nonLevBillableHoursAsOfLastWeek = 0;
                Decimal levRevenueAmountAsOfLastWeek = 0;
                Decimal nonLevRevenueAmountAsOfLastWeek = 0;
                
                
                for(Id timeEntryID : parentProjectMap.get(projectID).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentProjectMap.get(projectID).get(timeEntryID);

                    Boolean isLevTime = false;
                    if((currentEntry.EntryDate__c < switchToATGTimeDate && currentEntry.Employee__r.Name != atgConsultantContactName) 
                    || (currentEntry.EntryDate__c >= switchToATGTimeDate && currentEntry.Employee__r.Account.Name == levementumAccountName && currentEntry.Employee__r.Name != atgConsultantContactName)){
                        isLevTime = true;
                    }

                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true && currentEntry.TotalHrs__c != null){
                        //New Rollup Calculation Step 2 - Criteria
                        if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Billable Hours
                            if(isLevTime){
                                levBillableHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevBillableHours += currentEntry.TotalHrs__c;
                            }

                            //Replicon Billable Hours for Current Month DLRS Replacement
                            if(currentEntry.EntryDate__c.month() == currentMonth && currentEntry.EntryDate__c.year() == currentYear){
                                rollupBillableHoursThisMonth += currentEntry.TotalHrs__c;
                            }
                            //Replicon Billable Hours as of Previous Week DLRS Replacement 
                            //Replicon Budget Remaining as of Previous Week DLRS Replacement
                            if(currentEntry.EntryDate__c <= dateOfPreviousSaturday){
                                //Changing Total Hours/Budget as of last week to Lev only ST 4.3.23
                                if(isLevTime){
                                    rollupPreviousWeeksBillableHours += currentEntry.TotalHrs__c;
                                    rollupBudgetRemainingAsOfPrevWeek += currentEntry.Billable_Amount__c;
                                }

                                //Lev or Non Lev Hours and Revenue as of Last Week
                                if(isLevTime){
                                    levBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    levRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }else{
                                    nonLevBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    nonLevRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }
                            }
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;

                            //Lev or Non Lev Concession Hours
                            if(isLevTime){
                                levConcessionHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevConcessionHours += currentEntry.TotalHrs__c;
                            }

                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Non Billable Hours
                            if(isLevTime){
                                if(currentEntry.ActivityName__c == 'BCP'){
                                    rollupBCPNonBillHours += currentEntry.TotalHrs__c; //Added 9.2.22 ST
                                }else{
                                    levNonBillableHours += currentEntry.TotalHrs__c;
                                }
                            }else{
                                nonLevNonBillableHours += currentEntry.TotalHrs__c;
                            }
                        }
                        if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
                            rollupRevenue += currentEntry.Billable_Amount__c;

                            //Lev or Non-Lev Revenue
                            if(isLevTime){
                                levRevenue += currentEntry.Billable_Amount__c;
                            }else{
                                nonLevRevenue += currentEntry.Billable_Amount__c;
                            }
                        }

                        nonLevTotalNonBillAndConcessionHours = nonLevNonBillableHours + nonLevConcessionHours;

                    }
                }

                //Lev and Non Lev Project Rollup ST 6/22/2022
                if(projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                    Replicon_Time_Entry__c projectRelatedEntry = projectIdToProjectRelationshipFieldsMap.get(projectID);

                    if(projectRelatedEntry.Project__r.Rollup_Billable__c != levBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Concession__c != levConcessionHours 
                    || projectRelatedEntry.Project__r.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Revenue__c != levRevenue 
                    || projectRelatedEntry.Project__r.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectRelatedEntry.Project__r.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectRelatedEntry.Project__r.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectRelatedEntry.Project__r.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectRelatedEntry.Project__r.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectRelatedEntry.Project__r.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectRelatedEntry.Project__r.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectRelatedEntry.Project__r.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        Project__c updateProj = new Project__c(Id = projectID, 
                                                                Rollup_Billable__c = levBillableHours,
                                                                Rollup_Concession__c = levConcessionHours,
                                                                Rollup_Nonbillable__c = levNonBillableHours,
                                                                Rollup_Revenue__c = levRevenue,
                                                                Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                                PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                                BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                                NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                                NonLevNonBillHours__c = nonLevNonBillableHours,
                                                                NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                                NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                                BCPNonbillableHours__c = rollupBCPNonBillHours
                                                                );
                        projectUpdateList.add(updateProj);
                        projectUpdateMap.put(updateProj.Id, updateProj);
                    }
                }else if(projectWithNoActiveEntriesUpdateMap.containsKey(projectID)){
                    Project__c projectToUpdate = projectWithNoActiveEntriesUpdateMap.get(projectID);

                    if(projectToUpdate.Rollup_Billable__c != levBillableHours 
                    || projectToUpdate.Rollup_Concession__c != levConcessionHours 
                    || projectToUpdate.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectToUpdate.Rollup_Revenue__c != levRevenue 
                    || projectToUpdate.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectToUpdate.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectToUpdate.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectToUpdate.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectToUpdate.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectToUpdate.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectToUpdate.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectToUpdate.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        Project__c updateProj = new Project__c(Id = projectID, 
                                                                Rollup_Billable__c = levBillableHours,
                                                                Rollup_Concession__c = levConcessionHours,
                                                                Rollup_Nonbillable__c = levNonBillableHours,
                                                                Rollup_Revenue__c = levRevenue,
                                                                Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                                PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                                BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                                NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                                NonLevNonBillHours__c = nonLevNonBillableHours,
                                                                NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                                NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                                BCPNonbillableHours__c = rollupBCPNonBillHours
                                                                );
                        projectUpdateList.add(updateProj);
                        projectUpdateMap.put(updateProj.Id, updateProj);
                    }



                }
            }

            /************************************************************************************************************************/

            if(projectUpdateMap.size() > 0) {
                List<Project__c> projectForUpdateList = new List<Project__c>();
                projectForUpdateList = [SELECT Id, Rollup_Billable__c, Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c, Replicon_Hours_This_Month__c, PreviousWeeksBillableHrs__c, BudgetRemainingasofPrevWeek__c, 
                                            NonLevBillableHoursBooked__c, NonLevNonBillHours__c, NonLevRevenueAmountBooked__c, NonLevTotalNonBillableHours__c, BCPNonbillableHours__c
                                        FROM Project__c
                                        WHERE Id IN :projectUpdateMap.keySet() 
                                        FOR UPDATE];
                
                List<Project__c> projFinalUpdateList = new List<Project__c>();
                for(Project__c proj : projectForUpdateList){

                    if(projectUpdateMap.containsKey(proj.Id)){
                        Project__c updateProj = projectUpdateMap.get(proj.Id);
                        proj.Rollup_Billable__c = updateProj.Rollup_Billable__c;
                        proj.Rollup_Concession__c = updateProj.Rollup_Concession__c;
                        proj.Rollup_Nonbillable__c = updateProj.Rollup_Nonbillable__c;
                        proj.Rollup_Revenue__c = updateProj.Rollup_Revenue__c;
                        proj.Replicon_Hours_This_Month__c = updateProj.Replicon_Hours_This_Month__c;
                        proj.PreviousWeeksBillableHrs__c = updateProj.PreviousWeeksBillableHrs__c;
                        proj.BudgetRemainingasofPrevWeek__c = updateProj.BudgetRemainingasofPrevWeek__c;
                        proj.NonLevBillableHoursBooked__c = updateProj.NonLevBillableHoursBooked__c;
                        proj.NonLevNonBillHours__c = updateProj.NonLevNonBillHours__c;
                        proj.NonLevRevenueAmountBooked__c = updateProj.NonLevRevenueAmountBooked__c;
                        proj.NonLevTotalNonBillableHours__c = updateProj.NonLevTotalNonBillableHours__c;
                        proj.BCPNonbillableHours__c = updateProj.BCPNonbillableHours__c;
                        projFinalUpdateList.add(updateProj);
                    }
                }
                System.debug('***************************Updating ' + projFinalUpdateList.size() + ' Project Rollup Values*******************************');
                //update projFinalUpdateList;
                Database.update(projFinalUpdateList, false);
            }else{
                System.debug('***************************No Project Rollup Values Calculated*******************************');
            }            
        }
        catch(Exception e) {
            System.debug('calculateProjectRollupValuesFuture');
            System.debug(e);
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateProjectRollupValuesFuture', NULL);
        }
    }
    
    //Calculates rollup values from time entry to timesheet.
    //James Qian, October 2018
    public static void calculateTimesheetRollupValues(Set<Id> timesheetIdSet) {
        try {
            List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentTimesheetMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            for(Id timesheetId : timesheetIdSet) {
                //if(currentEntry.Replicon_Timesheet__c != NULL && !currentEntry.Deleted_in_Replicon__c) {
                //Added on 4/19 - Sam Tucker
                if(timesheetId != NULL) {
                    parentTimesheetMap.put(timesheetId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }
            if(parentTimesheetMap.keyset().size() > 0) {

                for(Replicon_Time_Entry__c queriedTimeEntry : [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, Project__c, Is_Concession__c,
                                                                           Override_Billing_Rate__c, TotalHrs__c, Replicon_Timesheet__c, Time_Off__c, Deleted_in_Replicon__c, Replicon_Project_URI__c, Time_Off_Description__c
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Replicon_Timesheet__c IN :parentTimesheetMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false]) {
                    Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = parentTimesheetMap.get(queriedTimeEntry.Replicon_Timesheet__c);
                    timesheetTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                    parentTimesheetMap.put(queriedTimeEntry.Replicon_Timesheet__c, timesheetTimeEntryMap); 
                }
            }
            
            //Loop through structure to calculate rollup values
            for(Id timesheetId : parentTimesheetMap.keyset()) {
                
                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupTotalHours = 40;
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupTotalTimeOff = 0;
                Decimal rollupTotalLOAHours = 0;
                
                for(Id timeEntryID : parentTimesheetMap.get(timesheetId).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentTimesheetMap.get(timesheetId).get(timeEntryID);
                    
                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true ){
                        //New Rollup Calculation Step 2 - Criteria
                        if(currentEntry.Time_Off__c) {
                            //Rollup LOA time
                            if(currentEntry.Time_Off_Description__c == 'LOA'){
                                rollupTotalLOAHours += currentEntry.TotalHrs__c;
                            }
                            rollupTotalHours -= currentEntry.TotalHrs__c;
                            rollupTotalTimeOff += currentEntry.TotalHrs__c;
                        }
                        else if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL || currentEntry.Replicon_Project_URI__c == 'urn:replicon-tenant:levementum:project:3689' || currentEntry.Project__c == 'a1q6T000007rOueQAE' || currentEntry.Is_Concession__c == true) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;
                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;
                        }
                    }
                }
                
                //New Rollup Calculation Step 3 - Assignment
                timesheetUpdateList.add(new Replicon_Timesheet__c(Id = timesheetId, 
                                                                  Total_Billable_Hours__c = rollupBillableHours,
                                                                  Total_Concession_Hours__c = rollupConcessionHours,
                                                                  Total_Nonbillable_Hours__c = rollupNonBillableHours,
                                                                  Total_Hours__c = rollupTotalHours,
                                                                  Total_Time_Off_Hours__c = rollupTotalTimeOff,
                                                                  TotalLOAHours__c = rollupTotalLOAHours));
            }
            if(timesheetUpdateList.size() > 0) {
                Database.update(timesheetUpdateList, false);
                //update timesheetUpdateList;
            }
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateTimesheetRollupValues', NULL);
        }
    }

    @future(callout=false)
    public static void calculateTimesheetRollupValuesFuture(Set<Id> timesheetIdSet) {
        try {
            List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentTimesheetMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            for(Id timesheetId : timesheetIdSet) {
                //if(currentEntry.Replicon_Timesheet__c != NULL && !currentEntry.Deleted_in_Replicon__c) {
                //Added on 4/19 - Sam Tucker
                if(timesheetId != NULL) {
                    parentTimesheetMap.put(timesheetId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }
            if(parentTimesheetMap.keyset().size() > 0) {

                for(Replicon_Time_Entry__c queriedTimeEntry : [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, Project__c, Is_Concession__c,
                                                                           Override_Billing_Rate__c, TotalHrs__c, Replicon_Timesheet__c, Time_Off__c, Deleted_in_Replicon__c, Time_Off_Description__c, Replicon_Project_URI__c
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Replicon_Timesheet__c IN :parentTimesheetMap.keyset() AND TotalHrs__c != null
                                                                           AND Deleted_in_Replicon__c = false]) {
                    Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = parentTimesheetMap.get(queriedTimeEntry.Replicon_Timesheet__c);
                    timesheetTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                    parentTimesheetMap.put(queriedTimeEntry.Replicon_Timesheet__c, timesheetTimeEntryMap); 
                }
            }
            
            //Loop through structure to calculate rollup values
            for(Id timesheetId : parentTimesheetMap.keyset()) {
                
                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupTotalHours = 40;
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupTotalTimeOff = 0;
                Decimal rollupTotalLOAHours = 0;
                
                for(Id timeEntryID : parentTimesheetMap.get(timesheetId).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentTimesheetMap.get(timesheetId).get(timeEntryID);
                    
                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true ){
                        //New Rollup Calculation Step 2 - Criteria
                        if(currentEntry.Time_Off__c) {
                            //Rollup LOA time
                            if(currentEntry.Time_Off_Description__c == 'LOA'){
                                rollupTotalLOAHours += currentEntry.TotalHrs__c;
                            }
                            rollupTotalHours -= currentEntry.TotalHrs__c;
                            rollupTotalTimeOff += currentEntry.TotalHrs__c;
                        }
                        else if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL || currentEntry.Replicon_Project_URI__c == 'urn:replicon-tenant:levementum:project:3689' || currentEntry.Project__c == 'a1q6T000007rOueQAE' || currentEntry.Is_Concession__c == true) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;
                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;
                        }
                    }
                }
                
                //New Rollup Calculation Step 3 - Assignment
                timesheetUpdateList.add(new Replicon_Timesheet__c(Id = timesheetId, 
                                                                  Total_Billable_Hours__c = rollupBillableHours,
                                                                  Total_Concession_Hours__c = rollupConcessionHours,
                                                                  Total_Nonbillable_Hours__c = rollupNonBillableHours,
                                                                  Total_Hours__c = rollupTotalHours,
                                                                  Total_Time_Off_Hours__c = rollupTotalTimeOff,
                                                                  TotalLOAHours__c = rollupTotalLOAHours));
            }
            if(timesheetUpdateList.size() > 0) {
                Database.update(timesheetUpdateList, false);
                //update timesheetUpdateList;
            }
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateTimesheetRollupValues', NULL);
        }
    }

    /**Calculate the rollups for Weekly Targets **/
    public static void calculateWeeklyTargetActualsRollup(Set<Id> weeklyTargetIdSet) {
        try {
            System.debug('######calculateWeeklyTargetActualsRollup');
            //Get List of Weekly Targets to calculate Weekly Actuals for
            /*Set<Id> weeklyTargetIdSet = new Set<Id>();
            for(Replicon_Time_Entry__c entry : weeklyTargetIdSet){
                if(entry.WeeklyTarget__c != null){
                    weeklyTargetIdSet.add(entry.WeeklyTarget__c);
                }
            }*/
            if(weeklyTargetIdSet.size() > 0){
                //Query the sums of the Weekly Targets
                //6/6/2022 Added that the Employee of the Actuals to be rolled up to the Weekly Target Actuals must be on the Levementum LLC Account
                //Changed 8/9/2022 Changed that lev time is rolled up not just Levementum LLC time, since before June 1st 2022 ATG time is still included in Weekly Forecasts
                AggregateResult[] weeklyTargetActuals = [SELECT sum(Billable_Amount__c), WeeklyTarget__c
                                                            FROM Replicon_Time_Entry__c 
                                                            WHERE WeeklyTarget__c IN :weeklyTargetIdSet AND Deleted_in_Replicon__c = false AND Is_Billable__c = true AND Is_Lev_Time__c = true
                                                            GROUP BY WeeklyTarget__c];


                //Create Map of Weekly Target Id to Actual Hours from related Time Entries Sum
                Map<Id, Decimal> weeklyTargetIdToRollupActualsMap = new Map<Id, Decimal>();
                for(AggregateResult ar : weeklyTargetActuals){
                    Decimal rollupRevenue = (Decimal)ar.get('expr0');
                    Id weeklyTargetId = (Id)ar.get('WeeklyTarget__c');
                    weeklyTargetIdToRollupActualsMap.put(weeklyTargetId, rollupRevenue);
                }
                //Query the Weekly Targets that are getting updated
                List<Revenue_Forecast__c> relatedWeeklyTargetsList = new List<Revenue_Forecast__c>();
                relatedWeeklyTargetsList = [SELECT Id, WeeklyActuals__c FROM Revenue_Forecast__c WHERE Id IN :weeklyTargetIdToRollupActualsMap.keySet()];
                //Check to see if Weekly Target needs update on WeeklyActuals field, if they do add to update list and update if not leave them alone.
                List<Revenue_Forecast__c> weeklyTargetsToUpdateList = new List<Revenue_Forecast__c>();
                for(Revenue_Forecast__c weeklyTarget : relatedWeeklyTargetsList){
                    if(weeklyTargetIdToRollupActualsMap.containsKey(weeklyTarget.Id)){
                        if(weeklyTarget.WeeklyActuals__c != weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id)){
                            weeklyTarget.WeeklyActuals__c = weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id);
                            weeklyTargetsToUpdateList.add(weeklyTarget);
                        }
                    }
                }
                if(weeklyTargetsToUpdateList.size() > 0) {
                    update weeklyTargetsToUpdateList;
                }
            }
        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateWeeklyTargetActualsRollup', NULL);
        }
    }

    @future(callout=false)
    public static void calculateWeeklyTargetActualsRollupFuture(Set<Id> weeklyTargetIdList) {
        try {
            System.debug('######calculateWeeklyTargetActualsRollup FUTURE');

            if(weeklyTargetIdList.size() > 0){
                //Query the sums of the Weekly Targets
                //6/6/2022 Added that the Employee of the Actuals to be rolled up to the Weekly Target Actuals must be on the Levementum LLC Account
                //Changed 8/9/2022 Changed that lev time is rolled up not just Levementum LLC time, since before June 1st 2022 ATG time is still included in Weekly Forecasts
                AggregateResult[] weeklyTargetActuals = [SELECT sum(Billable_Amount__c), WeeklyTarget__c
                                                            FROM Replicon_Time_Entry__c 
                                                            WHERE WeeklyTarget__c IN :weeklyTargetIdList AND Deleted_in_Replicon__c = false AND Is_Billable__c = true AND Is_Lev_Time__c = true
                                                            GROUP BY WeeklyTarget__c];


                //Create Map of Weekly Target Id to Actual Hours from related Time Entries Sum
                Map<Id, Decimal> weeklyTargetIdToRollupActualsMap = new Map<Id, Decimal>();
                for(AggregateResult ar : weeklyTargetActuals){
                    Decimal rollupRevenue = (Decimal)ar.get('expr0');
                    Id weeklyTargetId = (Id)ar.get('WeeklyTarget__c');
                    weeklyTargetIdToRollupActualsMap.put(weeklyTargetId, rollupRevenue);
                }
                //Query the Weekly Targets that are getting updated
                List<Revenue_Forecast__c> relatedWeeklyTargetsList = new List<Revenue_Forecast__c>();
                relatedWeeklyTargetsList = [SELECT Id, WeeklyActuals__c FROM Revenue_Forecast__c WHERE Id IN :weeklyTargetIdToRollupActualsMap.keySet()];
                //Check to see if Weekly Target needs update on WeeklyActuals field, if they do add to update list and update if not leave them alone.
                List<Revenue_Forecast__c> weeklyTargetsToUpdateList = new List<Revenue_Forecast__c>();
                for(Revenue_Forecast__c weeklyTarget : relatedWeeklyTargetsList){
                    if(weeklyTargetIdToRollupActualsMap.containsKey(weeklyTarget.Id)){
                        if(weeklyTarget.WeeklyActuals__c != weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id)){
                            weeklyTarget.WeeklyActuals__c = weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id);
                            weeklyTargetsToUpdateList.add(weeklyTarget);
                        }
                    }
                }
                if(weeklyTargetsToUpdateList.size() > 0) {
                    update weeklyTargetsToUpdateList;
                }
            }
        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'calculateWeeklyTargetActualsRollupFUTURE', NULL);
        }
    }

    public static void rollupTimeActualsOnForecast(Set<Id> forecastIdSet){
        try {

            Map<Id, Decimal> forecastIdToActualHoursMap = new Map<Id, Decimal>();
            Map<Id, Decimal> forecastIdToActualRevenueMap = new Map<Id, Decimal>();
            for(Id forecastId : forecastIdSet){
                forecastIdToActualHoursMap.put(forecastId, 0);
                forecastIdToActualRevenueMap.put(forecastId, 0);
            }

            AggregateResult[] timeEntryAgg = [SELECT SUM(TotalHrs__c) totalHours, SUM(Billable_Amount__c) totalRevenue, Replicon_Forecast__c
                                                FROM Replicon_Time_Entry__c
                                                WHERE Replicon_Forecast__c IN :forecastIdSet AND Deleted_in_Replicon__c = false AND TotalHrs__c != 0 AND Associated_Billing_Rate__c != null AND Associated_Billing_Rate__r.Name != 'Concession'
                                                GROUP BY Replicon_Forecast__c
                                                ORDER BY Replicon_Forecast__c];

            for(AggregateResult ar : timeEntryAgg){
                Decimal totalHours = (Decimal)ar.get('totalHours');
                Decimal totalRevenue = (Decimal)ar.get('totalRevenue');
                Id forecastId = (Id)ar.get('Replicon_Forecast__c');

                forecastIdToActualHoursMap.put(forecastId, totalHours);
                forecastIdToActualRevenueMap.put(forecastId, totalRevenue);
            }

            List<RepliconForecast__c> relatedForecastList = new List<RepliconForecast__c>();
            relatedForecastList = [SELECT Id, Name, Contact__c, Project__c, ActualHours__c, Actual_Revenue__c
                                    FROM RepliconForecast__c
                                    WHERE Id IN :forecastIdSet
                                    ORDER BY Contact__c, Week_Start_Date__c];

            List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
            for(RepliconForecast__c forecast : relatedForecastList){
                Boolean needsUpdate = false;

                if(forecastIdToActualHoursMap.containsKey(forecast.Id) && forecast.ActualHours__c != forecastIdToActualHoursMap.get(forecast.Id)){
                    forecast.ActualHours__c = forecastIdToActualHoursMap.get(forecast.Id);
                    needsUpdate = true;
                }

                if(forecastIdToActualRevenueMap.containsKey(forecast.Id) && forecast.Actual_Revenue__c != forecastIdToActualRevenueMap.get(forecast.Id)){
                    forecast.Actual_Revenue__c = forecastIdToActualRevenueMap.get(forecast.Id);
                    needsUpdate = true;
                }

                if(needsUpdate){
                    forecastUpdateList.add(forecast);
                }
            }

            if(forecastUpdateList.size() > 0){
                System.debug('Updating Actuals on ' + forecastUpdateList.size() + ' Forecast(s)');
                update forecastUpdateList;
            }

        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'rollupTimeActualsOnForecast', NULL);
        }
    }

    @future(callout=false)
    public static void rollupTimeActualsOnForecastFuture(Set<Id> forecastIdSet){
        try{
            Map<Id, Decimal> forecastIdToActualHoursMap = new Map<Id, Decimal>();
            Map<Id, Decimal> forecastIdToActualRevenueMap = new Map<Id, Decimal>();
            for(Id forecastId : forecastIdSet){
                forecastIdToActualHoursMap.put(forecastId, 0);
                forecastIdToActualRevenueMap.put(forecastId, 0);
            }

            AggregateResult[] timeEntryAgg = [SELECT SUM(TotalHrs__c) totalHours, SUM(Billable_Amount__c) totalRevenue, Replicon_Forecast__c
                                                FROM Replicon_Time_Entry__c
                                                WHERE Replicon_Forecast__c IN :forecastIdSet AND Deleted_in_Replicon__c = false AND TotalHrs__c != 0 AND Associated_Billing_Rate__c != null AND Associated_Billing_Rate__r.Name != 'Concession'
                                                GROUP BY Replicon_Forecast__c
                                                ORDER BY Replicon_Forecast__c];

            for(AggregateResult ar : timeEntryAgg){
                Decimal totalHours = (Decimal)ar.get('totalHours');
                Decimal totalRevenue = (Decimal)ar.get('totalRevenue');
                Id forecastId = (Id)ar.get('Replicon_Forecast__c');

                forecastIdToActualHoursMap.put(forecastId, totalHours);
                forecastIdToActualRevenueMap.put(forecastId, totalRevenue);
            }

            List<RepliconForecast__c> relatedForecastList = new List<RepliconForecast__c>();
            relatedForecastList = [SELECT Id, Name, Contact__c, Project__c, ActualHours__c, Actual_Revenue__c
                                    FROM RepliconForecast__c
                                    WHERE Id IN :forecastIdSet
                                    ORDER BY Contact__c, Week_Start_Date__c];

            List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
            for(RepliconForecast__c forecast : relatedForecastList){
                Boolean needsUpdate = false;

                if(forecastIdToActualHoursMap.containsKey(forecast.Id) && forecast.ActualHours__c != forecastIdToActualHoursMap.get(forecast.Id)){
                    forecast.ActualHours__c = forecastIdToActualHoursMap.get(forecast.Id);
                    needsUpdate = true;
                }

                if(forecastIdToActualRevenueMap.containsKey(forecast.Id) && forecast.Actual_Revenue__c != forecastIdToActualRevenueMap.get(forecast.Id)){
                    forecast.Actual_Revenue__c = forecastIdToActualRevenueMap.get(forecast.Id);
                    needsUpdate = true;
                }

                if(needsUpdate){
                    forecastUpdateList.add(forecast);
                }
            }

            if(forecastUpdateList.size() > 0){
                System.debug('Updating Actuals on ' + forecastUpdateList.size() + ' Forecast(s) with a Future method');
                update forecastUpdateList;
            }

        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'TimeEntryRollupManager', 'rollupTimeActualsOnForecastFuture', NULL);
        }
    }
}