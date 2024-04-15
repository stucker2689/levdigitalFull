/**
 * Created By Sam Tucker 2/28/2022
 * To take snapshots of the Revenue Backlog for the Revenue Forecast Object to populate the Revenue Backlog field on both the Monthly and Weekly Target Revenue Forecast records
 * To take snapshot of Weekly Forecast $ on the Weekly Target Record Type
 */

public with sharing class RevenueForecastSnapshot {
    
    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    public static void weeklyStartAndEndRevenueBacklogSnapshot(){
        /**
         * Purpose: Run this function weekly on Mondays to snapshot the Start of Week Revenue Backlog (StartOfWeekRevenueBacklog__c) for the current week's Revenue Forecast Weekly Target record
         *          As well as populate the End of Week Revenue Backlog (EndOfWeekRevenueBacklog__c) for the previous week's Revenue Forecast Weekly Target
         */
        Date currentWeekFullStartDate = Date.today().toStartOfWeek(); //Current Week Start Date (Sunday) to set Week Start Backlog Revenue
        Date previousWeekFullEndDate = currentWeekFullStartDate.addDays(-1); //Previous Week End Date (Saturday) to set Week End Backlog Revenue

        //Query for the Weekly Targets to be updated
        List<Revenue_Forecast__c> weeklyTargetsList = [SELECT Id, StartOfWeekRevenueBacklog__c, EndOfWeekRevenueBacklog__c, FullWeekStartDate__c, FullWeekEndDate__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE (FullWeekStartDate__c =: currentWeekFullStartDate OR FullWeekEndDate__c =: previousWeekFullEndDate) AND RecordTypeId =: weeklyTargetRT];

        //Query for the total Remaining Amount from all Projects
        AggregateResult[] revenueBacklogSum = [SELECT sum(Opportunity_Remaining_Amount__c)
                                                FROM Project__c
                                                WHERE Project_Status__c IN ('Active', 'Not Started') AND Planned_Close_Date__c >= TODAY];

        Decimal revenueBacklogSnapshot = (Decimal)revenueBacklogSum[0].get('expr0');

        List<Revenue_Forecast__c> weeklyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : weeklyTargetsList){
            if(rf.FullWeekStartDate__c == currentWeekFullStartDate){ //For Snapshoting the Start of Week Revenue Backlog
                rf.StartOfWeekRevenueBacklog__c = revenueBacklogSnapshot;
                weeklyTargetsToUpdate.add(rf);
            }else if(rf.FullWeekEndDate__c == previousWeekFullEndDate){ //For Snapshoting the End of Week Revenue Backlog
                rf.EndOfWeekRevenueBacklog__c = revenueBacklogSnapshot;
                weeklyTargetsToUpdate.add(rf);
            }
        }

        if(weeklyTargetsToUpdate.size() > 0){
            update weeklyTargetsToUpdate;
        }
    }

    public static void monthlyStartAndEndRevenueBacklogSnapshot(){
        /**
         * Purpose: Run this function on the first of the Month to snapshot the Start of Month Revenue Backlog (StartOfMonthRevenueBacklog__c) for the current month's Revenue Forecast Monthly Target record
         *          As well as populate the snapshot the End of Month Revenue Backlog (EndOfMonthRevenueBacklog__c) for the current month's Revenue Forecast Monthly Target record
         */
        Date currentMonthStartDate = Date.today().toStartOfMonth(); //Current Month Start Date (Sunday) to set Month Start Backlog Revenue
        Date previousMonthEndDate = currentMonthStartDate.addDays(-1); //Previous Month End Date (Saturday) to set Month End Backlog Revenue

        //Query for the Monthly Targets to be updated
        List<Revenue_Forecast__c> monthlyTargetsList = [SELECT Id, StartOfMonthRevenueBacklog__c, EndOfMonthRevenueBacklog__c, MonthStartDate__c, MonthEndDate__c
                                                        FROM Revenue_Forecast__c
                                                        WHERE (MonthStartDate__c =: currentMonthStartDate OR MonthEndDate__c =: previousMonthEndDate) AND RecordTypeId =: monthlyTargetRT];

        //Query for the total Remaining Amount from all Projects
        AggregateResult[] revenueBacklogSum = [SELECT sum(Opportunity_Remaining_Amount__c)
                                                FROM Project__c
                                                WHERE Project_Status__c IN ('Active', 'Not Started') AND Planned_Close_Date__c >= TODAY];

        Decimal revenueBacklogSnapshot = (Decimal)revenueBacklogSum[0].get('expr0');

        List<Revenue_Forecast__c> monthlyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : monthlyTargetsList){
            if(rf.MonthStartDate__c == currentMonthStartDate){ //For Snapshoting the Start of Month Revenue Backlog
                rf.StartOfMonthRevenueBacklog__c = revenueBacklogSnapshot;
                monthlyTargetsToUpdate.add(rf);
            }else if(rf.MonthEndDate__c == previousMonthEndDate){ //For Snapshoting the End of Month Revenue Backlog
                rf.EndOfMonthRevenueBacklog__c = revenueBacklogSnapshot;
                monthlyTargetsToUpdate.add(rf);
            }
        }

        if(monthlyTargetsToUpdate.size() > 0){
            update monthlyTargetsToUpdate;
        }
    }

    public static void weeklyForecastSnapshot(Date snapshotDate){
        /**
         * Purpose: Run this function every Friday to capture the Forecast $ on the Weekly Target Revenue Forecast record for the current week
         *          Captures a static value of the Forecast $ on every Friday and logs in on the WeekForecastSnapshot__c field on the Weekly Target for the current week
         */
        
        Date fullWeekStartDate; //Sunday of the current Week
        //fullWeekStartDate = Date.today().toStartOfWeek();
        fullWeekStartDate = snapshotDate.toStartOfWeek();

        //Query for the Weekly Target Record(s) for the current Week

        List<Revenue_Forecast__c> currentWeeklyTargetList = new List<Revenue_Forecast__c>();
        currentWeeklyTargetList = [SELECT Id, WeekStartDate__c, WeekEndDate__c, WeekForecastSnapshot__c, WeeklyForecast__c, FullWeekStartDate__c
                                   FROM  Revenue_Forecast__c
                                   WHERE FullWeekStartDate__c =: fullWeekStartDate AND RecordTypeId =: weeklyTargetRT];

        List<Revenue_Forecast__c> weeklyTargetSnapshotList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c weeklyTarget : currentWeeklyTargetList){
            if(weeklyTarget.WeeklyForecast__c != null){
                weeklyTarget.WeekForecastSnapshot__c = weeklyTarget.WeeklyForecast__c;
                weeklyTargetSnapshotList.add(weeklyTarget);
            }
        }


        if(weeklyTargetSnapshotList.size() > 0){
            update weeklyTargetSnapshotList;
        }

    }
}