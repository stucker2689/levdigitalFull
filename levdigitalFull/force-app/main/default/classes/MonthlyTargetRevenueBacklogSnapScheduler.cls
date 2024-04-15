/**
 * Created By Sam Tucker 3/4/2022
 * Scheduler for the RevenueForecastSnapshot monthlyStartAndEndRevenueBacklogSnapshot class 
 * Runs at the beginning of each Month (1st of the Month) to capture the Start Month Revenue Backlog of the current Month and the End of Month Revenue Backlog of the Previous Month for Monthly Target Revenue Forecast records
 * 
 * Schedulable Apex run to run this code at 6 AM on the 1st of every month:
 * 
    MonthlyTargetRevenueBacklogSnapScheduler monthlyTargetRevBacklogSnapScheduler = new MonthlyTargetRevenueBacklogSnapScheduler();
    System.schedule('Monthly Start and End Revenue Backlog Snapshot', '0 0 6 1 * ?', monthlyTargetRevBacklogSnapScheduler);

    to run on 12 pm on every first Monday of the Month

    MonthlyTargetRevenueBacklogSnapScheduler monthlyTargetRevBacklogSnapScheduler = new MonthlyTargetRevenueBacklogSnapScheduler();
    System.schedule('Monthly Start and End Revenue Backlog Snapshot First Monday', '0 0 12 ? * 2#1', monthlyTargetRevBacklogSnapScheduler);

    to run on 12 pm on every first Tuesday of the Month

    MonthlyTargetRevenueBacklogSnapScheduler monthlyTargetRevBacklogSnapScheduler = new MonthlyTargetRevenueBacklogSnapScheduler();
    System.schedule('Monthly Start and End Revenue Backlog Snapshot First Tuesday', '0 0 12 ? * 3#1', monthlyTargetRevBacklogSnapScheduler);

    to run on 12 pm on every first Wednesday of the Month

    MonthlyTargetRevenueBacklogSnapScheduler monthlyTargetRevBacklogSnapScheduler = new MonthlyTargetRevenueBacklogSnapScheduler();
    System.schedule('Monthly Start and End Revenue Backlog Snapshot First Wednesday', '0 0 12 ? * 4#1', monthlyTargetRevBacklogSnapScheduler);



 */
public with sharing class MonthlyTargetRevenueBacklogSnapScheduler implements Schedulable{
    public MonthlyTargetRevenueBacklogSnapScheduler() {

    }

    public void execute (SchedulableContext ctx) {   

        RevenueForecastSnapshot.monthlyStartAndEndRevenueBacklogSnapshot();
    }
}