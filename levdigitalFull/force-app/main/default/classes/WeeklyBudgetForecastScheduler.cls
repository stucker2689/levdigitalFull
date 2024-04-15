/**
 * @author:         Lev LLC
 * @date:           11/04/2019
 * @description:    Obtains snapshots of the Forecast object fields into the Weekly Budget custom object
 */
global class WeeklyBudgetForecastScheduler implements Database.Batchable<sObject>, Database.Stateful {
    global final String query;
    global Id weeklyBudgetRecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Weekly Budget').getRecordTypeId();
    public Map<Id, Budget__c> budgetsMap = new Map<Id, Budget__c>();

    global WeeklyBudgetForecastScheduler(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {

            List<Budget__c> weeklyBudgets = [Select Id, Forecasted_Hours__c, Forecasted_Revenue__c, Week_Start_Date__c
            From Budget__c where RecordTypeId =: weeklyBudgetRecordTypeId];

            for(RepliconForecast__c rForecast : (List<RepliconForecast__c>) scope) {
                Budget__c weeklyBudget = processWeek(weeklyBudgets, rForecast);
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

    private Budget__c processWeek(List<Budget__c> budgets, RepliconForecast__c forecast) {
        try {
            if(forecast.EstimatedHours__c == null) {forecast.EstimatedHours__c = 0;}
            for(Budget__c bdg : budgets) {
                if(bdg.Week_Start_Date__c >= forecast.Week_Start_Date__c && bdg.Week_Start_Date__c <= forecast.Week_End_Date__c) {
                    Budget__c b = budgetsMap.get(bdg.Id);

                    if (system.today() > forecast.Week_End_Date__c) {
                        if (bdg.Forecasted_Revenue__c != null) {
                            continue;
                        }
                    }

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
                }
            }
            system.debug(budgetsMap);
        } catch(Exception ex) {
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'ForecastScheduler', 'processWeek()', NULL);
        }
        return null;
    }
}