/**
 * @author:         Lev LLC
 * @date:           11/04/2019
 * @description:    Obtains snapshots of the Forecast object fields into the Quarterly Budget custom object
 */
global class QuarterlyBudgetForecastScheduler implements Database.Batchable<sObject>, Database.Stateful  {
    global final String query;
    global Id quarterlyBudgetRecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Quarterly Budget').getRecordTypeId();
    public Map<Id, Budget__c> budgetsMap = new Map<Id, Budget__c>();

    global QuarterlyBudgetForecastScheduler(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {

            List<Budget__c> quarterlyBudgets = [Select Id, Dynamic_Forecasted_Revenue__c, Quarter_Start_Date__c, Quarter_End_Date__c, Forecasted_Hours__c, Forecasted_Revenue__c, Week_Start_Date__c
            From Budget__c where RecordTypeId =: quarterlyBudgetRecordTypeId];

            for(RepliconForecast__c rForecast : (List<RepliconForecast__c>) scope) {
                Budget__c weeklyBudget = processQuarter(quarterlyBudgets, rForecast);
            }


        } catch(Exception ex) {
            system.debug(ex.getStackTraceString());
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'ForecastScheduler', 'execute()', NULL);
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {
            system.debug(budgetsMap.size() + ' SIZE');
            List<Budget__c> budgetsToUpdate = new List<Budget__c>();
            for(Id budgetId : budgetsMap.keySet()) {
                budgetsToUpdate.add(budgetsMap.get(budgetId));
            }
            update budgetsToUpdate;
        } catch(Exception ex) {
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'ForecastScheduler', 'finish()', NULL);
        }
    }

    private Budget__c processQuarter(List<Budget__c> budgets, RepliconForecast__c forecast) {
        try {
            if(forecast.EstimatedHours__c == null) {forecast.EstimatedHours__c = 0;}
            for(Budget__c bdg : budgets) {
                if(forecast.Week_Start_Date__c >= bdg.Quarter_Start_Date__c && forecast.Week_Start_Date__c <= bdg.Quarter_End_Date__c) {
                    Budget__c b = budgetsMap.get(bdg.Id);

                    if(b != null) {
                        if(b.Forecasted_Revenue__c == null) {b.Forecasted_Revenue__c = 0;}
                        if(b.Forecasted_Hours__c  == null) {b.Forecasted_Hours__c = 0;}
                        b.Forecasted_Revenue__c += forecast.EstimatedRevenue__c != null ? forecast.EstimatedRevenue__c : 0;
                        b.Forecasted_Hours__c += forecast.Estimatedhours__c;
                        budgetsMap.put(b.Id, b);
                    } else {
                        if(bdg.Forecasted_Revenue__c == null) {bdg.Forecasted_Revenue__c = 0;}
                        if(bdg.Forecasted_Hours__c  == null) {bdg.Forecasted_Hours__c = 0;}
                        bdg.Forecasted_Revenue__c += forecast.EstimatedRevenue__c != null ? forecast.EstimatedRevenue__c : 0;
                        bdg.Forecasted_Hours__c += forecast.Estimatedhours__c;
                        budgetsMap.put(bdg.Id, bdg);
                    }
                    break;
                }
            }
        } catch(Exception ex) {
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'ForecastScheduler', 'processQuarter()', NULL);
        }
        return null;
    }
}