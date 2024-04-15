/**
 * Created By Sam Tucker 3/4/2022
 * Scheduler for the RevenueForecastSnapshot weeklyStartAndEndRevenueBacklogSnapshot class 
 * Runs at the beginning of each Week (MONDAY - WEDNESDAY) to capture the Start of Week Revenue Backlog of the current Week and the End of Week Revenue Backlog of the Previous Week for Weekly Target Revenue Forecast records
 * 
    NEW AS OFSchedulable Apex to run this code at 12:00 PM (noon) every Monday - Wednesday 

    WeeklyTargetRevenueBacklogSnapScheduler weeklyTargetRevBacklogSnapScheduler = new WeeklyTargetRevenueBacklogSnapScheduler();
    System.schedule('Weekly Start and End Revenue Backlog Snapshot MON-WED', '0 5 12 ? * 2-4', weeklyTargetRevBacklogSnapScheduler);
 */
public with sharing class WeeklyTargetRevenueBacklogSnapScheduler implements Schedulable{
    public WeeklyTargetRevenueBacklogSnapScheduler() {

    }

    public void execute (SchedulableContext ctx) {   

        RevenueForecastSnapshot.weeklyStartAndEndRevenueBacklogSnapshot();
    }
}