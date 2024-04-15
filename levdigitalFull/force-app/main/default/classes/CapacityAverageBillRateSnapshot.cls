/**
 * Created 9.20.2022 ST
 * 
 * Purpose: This is created to schedule the population of Org Average Billing Rate to put on Capacity Records
 *          To be ran at the beginning of each month to keep capacity records with the accurate average billing rate of a rolling last 6 months
 * 
 * 
To be scheduled to run on the first of every month at 6 AM with the following code:

CapacityAverageBillRateSnapshot newAvgBilLRateBatch = new CapacityAverageBillRateSnapshot();
System.schedule('Monthly Start Capacity Average Bill Rate Snapshot', '0 0 6 1 * ?', newAvgBilLRateBatch);

 *
 */



public with sharing class CapacityAverageBillRateSnapshot implements Database.Batchable<sObject>, Database.Stateful, Schedulable{

    public final String QueryString;
    public List<Decimal> billingRatesList;

    public CapacityAverageBillRateSnapshot() {
        System.debug('**** WeeklyTimesheetCapacitySnapshots ****');

        billingRatesList = new List<Decimal>();
        
        QueryString = 'SELECT Billing_Rate__c'
                        + ' FROM Replicon_Time_Entry__c'
                        + ' WHERE Deleted_in_Replicon__c = false AND Is_Lev_Time__c = true AND Billing_Rate__c > 100 AND (EntryDate__c = THIS_MONTH OR EntryDate__c = LAST_N_MONTHS:5)'
                        + ' ORDER BY EntryDate__c DESC'; 
    }

    // Schedulable execute : Run batch
    public void execute(SchedulableContext sc) {
        System.debug('UndeletePTOForecastsBatch EXECUTE SCHEDULABLE');
        CapacityAverageBillRateSnapshot batch = new CapacityAverageBillRateSnapshot();
        Database.executeBatch(batch, 5000);        
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('CapacityAverageBillRateSnapshot START');

        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> entryList){
        System.debug('CapacityAverageBillRateSnapshot EXECUTE Batch Size: ' + entryList.size());

        Decimal batchAggregateBillRate = 0;
        for(Replicon_Time_Entry__c entry : entryList){
            batchAggregateBillRate += entry.Billing_Rate__c;
        }

        Decimal batchAverageBillRate = batchAggregateBillRate / entryList.size();
        billingRatesList.add(batchAverageBillRate);

    }

    public void finish(Database.BatchableContext BC){
        System.debug('CapacityAverageBillRateSnapshot FINISH');

        List<Capacity__c> updateCapacityList = new List<Capacity__c>();

        Decimal aggregateBillingRateTotal = 0;
        for(Decimal billRate : billingRatesList){
            aggregateBillingRateTotal += billRate;
        }

        Decimal rollingSixMonthsOrgAvgLevBillRate = (aggregateBillingRateTotal / billingRatesList.size()).setScale(2, System.RoundingMode.HALF_EVEN);

        List<Capacity__c> futureCapacityList = new List<Capacity__c>();
        futureCapacityList = [SELECT Id, AverageBillingRate__c, WeekEndDate__c, WeekStartDate__c FROM Capacity__c WHERE WeekEndDate__c > TODAY];

        for(Capacity__c cap : futureCapacityList){
            if(cap.AverageBillingRate__c != rollingSixMonthsOrgAvgLevBillRate){
                cap.AverageBillingRate__c = rollingSixMonthsOrgAvgLevBillRate;
                updateCapacityList.add(cap);
            }
        }

        if(updateCapacityList.size() > 0){
            System.debug('****************************** Updating Average Billing Rates on ' + updateCapacityList.size() + ' Capacity Records ****************************************');
            update updateCapacityList;
            
        }
    }
}