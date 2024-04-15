/**
 * Created 6/23/2022 ST
 * 
 * Batch run to calculate the Lev and Non Lev Rollups for Hours and Revenue on Projects
 * 
 * To RUn this Batch:
 * 
    LevNonLevProjectRollupBatch levNonLevRollupBatch = new LevNonLevProjectRollupBatch(true, null);
    Database.executeBatch(levNonLevRollupBatch, 5)
 */

public with sharing class LevNonLevProjectRollupBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    public List<Id> projectsIdList = new List<Id>();
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

    public LevNonLevProjectRollupBatch(Boolean runForAllProjects, List<Project__c> projectList) {
        System.debug('**** LevNonLevProjectRollupBatch ****');

        if(runForAllProjects){

            QueryString = 'SELECT Id, Name, Opportunity_Amount__c, Project_Status__c '
			                + 'FROM Project__c '
                            + 'WHERE Opportunity_Amount__c != 0';
            
        }else{
            for(Project__c proj : projectList){
                projectsIdList.add(proj.Id);
            }
            System.debug('Projects Id List: ' + projectsIdList);

            QueryString = 'SELECT Id, Name, Opportunity_Amount__c, Project_Status__c '
			                + 'FROM Project__c '
                            + 'WHERE Id IN :projectsIdList';

        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('LevNonLevProjectRollupBatch START');
        System.debug('Query String');

        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Project__c> projectsToRollupList){
        System.debug('LevNonLevProjectRollupBatch Execute Batch Size: ' + projectsToRollupList.size());

        //Set current dates 
        Date todaysDate = Date.today();
        Integer currentMonth = todaysDate.month();
        Integer currentYear = todaysDate.year();
        Date dateOfPreviousSaturday = todaysDate.toStartOfWeek().addDays(-1); //Added 5/4/2022 - Goes to the Sunday of todays Week, then goes one more day back to get the previous Saturday

        Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

        //Get all project IDs in trigger.new for querying existing records
        List<Project__c> projectUpdateList = new List<Project__c>();
        Map<Id, Map<Id, Replicon_Time_Entry__c>> parentProjectMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
        for(Project__c proj : projectsToRollupList) {
            //if(currentEntry.Project__c != NULL && !currentEntry.Deleted_in_Replicon__c) { Commented this out 4/19 Sam Tucker
            //Added on 4/19 - Sam Tucker
            if(proj.Name != 'Lev - PTO') {
                parentProjectMap.put(proj.Id, new Map<Id, Replicon_Time_Entry__c>()); 
            }
        }

        Map<Id, Replicon_Time_Entry__c> projectIdToProjectRelationshipFieldsMap = new Map<Id, Replicon_Time_Entry__c>();
        //Query existing records and put into a map for searching/deduplication
        if(parentProjectMap.keyset().size() > 0) {
            //Step 1 - Add to query
            List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, 
                                                                       Override_Billing_Rate__c, TotalHrs__c, Project__c, Deleted_in_Replicon__c, EntryDate__c, Project__r.Name,
                                                                       Project__r.Rollup_Billable__c , Project__r.Rollup_Concession__c, Project__r.Rollup_Nonbillable__c, Project__r.Rollup_Revenue__c,
                                                                       Project__r.Replicon_Hours_This_Month__c, Project__r.PreviousWeeksBillableHrs__c, Project__r.BudgetRemainingasofPrevWeek__c, 
                                                                       Project__r.NonLevTotalNonBillableHours__c, Project__r.NonLevRevenueAmountBooked__c, Project__r.NonLevNonBillHours__c, Project__r.NonLevBillableHoursBooked__c,
                                                                       Employee__r.Name, Employee__r.Account.Name
                                                                       FROM Replicon_Time_Entry__c 
                                                                       WHERE Project__c IN :parentProjectMap.keyset()
                                                                       AND Deleted_in_Replicon__c = false];
            
            for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                Map<Id, Replicon_Time_Entry__c> projectTimeEntryMap = parentProjectMap.get(queriedTimeEntry.Project__c);
                projectTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                parentProjectMap.put(queriedTimeEntry.Project__c, projectTimeEntryMap); 
                if(!projectIdToProjectRelationshipFieldsMap.containsKey(queriedTimeEntry.Project__c)){
                    projectIdToProjectRelationshipFieldsMap.put(queriedTimeEntry.Project__c, queriedTimeEntry);
                }
            }
        }

        //Loop through structure to calculate rollup values
        for(Id projectID : parentProjectMap.keyset()) {

            //New Rollup Calculation Step 1 - Declaration
            Decimal rollupBillableHoursThisMonth = 0;
            Decimal rollupPreviousWeeksBillableHours = 0;
            Decimal rollupBudgetRemainingAsOfPrevWeek = 0;

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
                if(currentEntry.Deleted_in_Replicon__c != true ){
                    //New Rollup Calculation Step 2 - Criteria
                    if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {

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

                        if(currentEntry.EntryDate__c <= dateOfPreviousSaturday){
                            rollupPreviousWeeksBillableHours += currentEntry.TotalHrs__c;
                            rollupBudgetRemainingAsOfPrevWeek += currentEntry.Billable_Amount__c;

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
                        //Lev or Non Lev Concession Hours
                        if(isLevTime){
                            levConcessionHours += currentEntry.TotalHrs__c;
                        }else{
                            nonLevConcessionHours += currentEntry.TotalHrs__c;
                        }

                    }
                    else {
                        //Lev or Non-Lev Non Billable Hours
                        if(isLevTime){
                            levNonBillableHours += currentEntry.TotalHrs__c;
                        }else{
                            nonLevNonBillableHours += currentEntry.TotalHrs__c;
                        }
                    }
                    if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
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

                if(projectRelatedEntry.Project__r.Rollup_Billable__c != levBillableHours || projectRelatedEntry.Project__r.Rollup_Concession__c != levConcessionHours 
                || projectRelatedEntry.Project__r.Rollup_Nonbillable__c != levNonBillableHours 
                || projectRelatedEntry.Project__r.Rollup_Revenue__c != levRevenue 
                || projectRelatedEntry.Project__r.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                || projectRelatedEntry.Project__r.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                || projectRelatedEntry.Project__r.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek 
                || projectRelatedEntry.Project__r.NonLevBillableHoursBooked__c != nonLevBillableHours 
                || projectRelatedEntry.Project__r.NonLevNonBillHours__c != nonLevNonBillableHours 
                || projectRelatedEntry.Project__r.NonLevRevenueAmountBooked__c != nonLevRevenue 
                || projectRelatedEntry.Project__r.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours){
                    //New Rollup Calculation Step 3 - Assignment
                    projectUpdateList.add(new Project__c(Id = projectID, Rollup_Billable__c = levBillableHours, 
                                                            Rollup_Concession__c = levConcessionHours, 
                                                            Rollup_Nonbillable__c = levNonBillableHours, 
                                                            Rollup_Revenue__c = levRevenue,
                                                            Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth, 
                                                            PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours, 
                                                            BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                            NonLevBillableHoursBooked__c = nonLevBillableHours, 
                                                            NonLevNonBillHours__c = nonLevNonBillableHours, 
                                                            NonLevRevenueAmountBooked__c = nonLevRevenue, 
                                                            NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours));
                }
            }
        }

        /************************************************************************************************************************/

        if(projectUpdateList.size() > 0) {
            System.debug('projectUpdateList: ' + projectUpdateList);
            System.debug('***************************Updating ' + projectUpdateList.size() + ' Project Rollup Values*******************************');
            update projectUpdateList;
        }else{
            System.debug('***************************No Project Rollup Values Calculated*******************************');
        }            


    }

    public void finish(Database.BatchableContext BC){
        System.debug('LevNonLevProjectRollupBatch FINISH');
    }
}