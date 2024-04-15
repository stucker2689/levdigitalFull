/**
 * Created by wfrohwein on 8/28/18.
 */

global class GdriveInvoiceScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new GdriveInvoiceBatch(), 1);
    }
}