/**
 * Created By Sam Tucker 10/7/2022
 * Scheduler for the RevenueForecastSnapshot weeklyForecastSnapshot class 
 * Runs at the Monday of each Week to  flip the ShowActualsInsteadOfForecast__c of the previous weeks Capacity record
 * 
 * Schedulable Apex run to run this code at 6 AM on Monday of every week:
 * 
    CapacityShowActualsScheduled capacityActualsFlip = new CapacityShowActualsScheduled();
    System.schedule('Capacity Show Actuals Flip', '0 0 6 ? * MON', capacityActualsFlip);
 */

public with sharing class CapacityShowActualsScheduled implements Schedulable {

    public void execute(SchedulableContext sc) {
        CapacityShowActualsScheduled.FlipCapacityToShowActualsInsteadOfForecast();    
    }


    public static void FlipCapacityToShowActualsInsteadOfForecast(){
        /**
         * Purpose: Run this function weekly to flip the Show Actuals Instead of Forecasts field to True on the PREVIOUS week's Capacity record
         *             This is because we get actuals a week late so we would still want to show the Forecasts until Actuals start coming in for that week.
         */

        Date previousWeekStartDate = Date.today().toStartOfWeek().addDays(-7);

        Capacity__c previousWeekCapacity = new Capacity__c();
        previousWeekCapacity = [SELECT Id, WeekStartDate__c, ShowActualsInsteadOfForecast__c FROM Capacity__c WHERE WeekStartDate__c =: previousWeekStartDate LIMIT 1];

        if(previousWeekCapacity != null){
            previousWeekCapacity.ShowActualsInsteadOfForecast__c = true;

            update previousWeekCapacity;
        }

    }
}