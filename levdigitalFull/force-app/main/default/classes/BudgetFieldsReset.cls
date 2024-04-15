/**
 * @author:         Lev LLC
 * @date:           11/04/2019
 * @description:    Resets cumulative fields to get correct sums
 */
global class BudgetFieldsReset implements Database.Batchable<sObject> {
    global final String query;

    global BudgetFieldsReset(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<Budget__c> budgetsToUpdate = new List<Budget__c>();
            for (Budget__c b : (List<Budget__c>) scope) {
                Id weeklyRecorTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Weekly Budget').getRecordTypeId();
                Id quarterlyBudgetRecordTypeId = Schema.SObjectType.Budget__c.getRecordTypeInfosByName().get('Quarterly Budget').getRecordTypeId();

                if (b.recordTypeId == weeklyRecorTypeId) {
                    if (system.today() > (b.Week_Start_Date__c.addDays(7))) {
                        if (b.Forecasted_Revenue__c != null) {
                            continue;
                        }
                    }
                } // quarters?

                b.Forecasted_Revenue__c = 0;
                b.Forecasted_Hours__c = 0;
                b.Dynamic_Forecasted_Revenue__c = 0;
                budgetsToUpdate.add(b);
            }
            update budgetsToUpdate;

        } catch (Exception ex) {
            system.debug(ex.getStackTraceString());
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'BudgetFieldsReset', 'execute()', NULL);
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {

        } catch (Exception ex) {
            LevExceptionHandler.logError(ex.getMessage() + ', Date: ' + String.valueOf(System.today()), ex.getLineNumber(), 'BudgetFieldsReset', 'finish()', NULL);
        }
    }
}