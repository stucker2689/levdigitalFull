public with sharing class WeeklyTargetTimeEntryMatchBatchTwo implements Database.Batchable<sObject>{

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    public final String QueryString;
    public List<Integer> monthsToMatchList = new List<Integer>();
    public List<Integer> yearsToMatchList =new List<Integer>();
    
    public WeeklyTargetTimeEntryMatchBatchTwo(List<Integer> months, List<Integer> years) {
        System.debug('**** WeeklyTargetTimeEntryMatchBatch ****');
        System.debug('months list: ' + months);
        System.debug('years list: ' + years);
        monthsToMatchList.addAll(months);
        yearsToMatchList.addAll(years);
        
        QueryString = 'SELECT Id, Name, EntryDate__c, Billable_Amount__c, WeekEndDate__c, WeeklyTarget__c, Deleted_in_Replicon__c, Time_Off__c, Is_Billable__c, Project__c, Employee__c, Replicon_Forecast__c, Replicon_User_Number__c, Timesheet_Period__c, TotalHrs__c'
                        + ' FROM Replicon_Time_Entry__c'
                        + ' WHERE Deleted_in_Replicon__c = false AND Time_Off__c = false AND CALENDAR_MONTH(EntryDate__c) IN  :monthsToMatchList  AND CALENDAR_YEAR(EntryDate__c) IN :yearsToMatchList AND WeeklyTarget__c = null'
                        + ' ORDER BY Project__c, Employee__c, EntryDate__c'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
            System.debug('**** WeeklyTargetTimeEntryMatchBatch START ****');
            return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> timeEntryList){
        System.debug('**** WeeklyTargetTimeEntryMatchBatch EXECUTE ****');
        /**
         * Function Purpose: Execute the process of finding the proper Weekly Target Revenue Forecast to associate with the Time Entry and populate the WeeklyTarget field on the Time Entry
         */

         List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();
         weeklyTargetsList = [SELECT Id, Name, RevenueForecastName__c, WeekStartDate__c, WeekEndDate__c, RelatedMonthlyForecast__c
                                FROM Revenue_Forecast__c
                                WHERE CALENDAR_MONTH(WeekStartDate__c) IN :monthsToMatchList AND CALENDAR_YEAR(WeekStartDate__c) =: yearsToMatchList AND RecordTypeId =: weeklyTargetRT];

        List<Date> allRelatedDatesList = new List<Date>();
        Map<Date, Id> weekStartDateToWeeklyTargetId = new Map<Date, Id>();
        for(Revenue_Forecast__c weeklyTarget : weeklyTargetsList){
            if(weeklyTarget.WeekStartDate__c != null && weeklyTarget.WeekEndDate__c != null){ //Ensure there is a value for both Week Start and End Dates on the Weekly Target
                weekStartDateToWeeklyTargetId.put(weeklyTarget.WeekStartDate__c, weeklyTarget.Id); //Put in Map for Week Start Date to the Weekly Target Id
                allRelatedDatesList.add(weeklyTarget.WeekStartDate__c); //Add the Weekly Target Start Date first to the all EntryDate List for the Query

                //Iterate through each day of the week until Week End Date to get list of all possible dates for a date that should be associated with the Weekly Target
                Date iterationDate;
                Integer dayCount = 1;
                iterationDate = weeklyTarget.WeekStartDate__c.addDays(dayCount);
                while(iterationDate <= weeklyTarget.WeekEndDate__c){ //While the next day is NOT AFTER THE Week End Date then continue to add to the days and Add the next Date of the Week to the List
                    iterationDate = iterationDate.addDays(dayCount); //Add the Date first, then add a day to the Day Counter. Purpose is to add the day that is either before or equal to the Week End Date then if that next Date is past the Week End Date then stop adding to the list
                    dayCount++;
                    allRelatedDatesList.add(iterationDate); //If the Iteration Date is before than the Week End Date, then continue to add one more day until the iteration date IS the Week End Date

                    if(dayCount > 6){ //Ensure that is can never add more than a whole weeks worth of Dates for eligible dates to relate to a Weekly Target (Should only at max add Dates for Satuday - Sunday of the week, 6 total dates)
                        break; 
                    }
                }
            }
        }


        List<Replicon_Time_Entry__c> timeEntryListToUpdate = new List<Replicon_Time_Entry__c>();
        //Loop through all the Time Entries within this batch run to associate the Weekly Targets
        for(Replicon_Time_Entry__c entry : timeEntryList){
            if(entry.EntryDate__c.toStartOfWeek().month() != entry.EntryDate__c.month()){ //If the Start of the Week is a different month, then get the start of the month to find the first day of the month within the week for the Weekly Target WeekStartDate
                if(weekStartDateToWeeklyTargetId.containsKey(entry.EntryDate__c.toStartOfMonth())){ //Check to see it is in the Map before assigning it
                    entry.WeeklyTarget__c = weekStartDateToWeeklyTargetId.get(entry.EntryDate__c.toStartOfMonth()); //Get First Day of Month for Partial Weeks
                    timeEntryListToUpdate.add(entry);
                }
            }else if(entry.EntryDate__c.toStartOfWeek().month() == entry.EntryDate__c.month()){
                if(weekStartDateToWeeklyTargetId.containsKey(entry.EntryDate__c.toStartOfWeek())){ //Check to see it is in the Map before assigning it
                    entry.WeeklyTarget__c = weekStartDateToWeeklyTargetId.get(entry.EntryDate__c.toStartOfWeek()); //get First Day of Week for Full Weeks
                    timeEntryListToUpdate.add(entry);
                }
            }
        }

        if(timeEntryListToUpdate.size() > 0){
            update timeEntryListToUpdate;
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** WeeklyTargetTimeEntryMatchBatch FINISH ****');

    }
}