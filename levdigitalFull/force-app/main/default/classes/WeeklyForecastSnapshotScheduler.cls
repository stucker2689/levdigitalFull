/**
 * Created By Sam Tucker 3/10/2022
 * Scheduler for the RevenueForecastSnapshot weeklyForecastSnapshot class 
 * Runs at the Friday of each Week to capture the Week Forecast Snapshot of the current Week for Weekly Target Revenue Forecast record(s)
 * 
 * Schedulable Apex run to run this code at 6 AM on Friday of every week:
 * 
    WeeklyForecastSnapshotScheduler weeklyForecastSnapshot = new WeeklyForecastSnapshotScheduler();
    System.schedule('Weekly Forecast Amount Snapshot', '0 0 6 ? * FRI', weeklyForecastSnapshot);
 */
public with sharing class WeeklyForecastSnapshotScheduler implements Schedulable{

    public WeeklyForecastSnapshotScheduler() {

    }

    public void execute (SchedulableContext ctx) {   

        RevenueForecastSnapshot.weeklyForecastSnapshot(Date.today());
    }
}