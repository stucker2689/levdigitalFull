@isTest
public with sharing class OverdueWorkDailyCheckSch_Test {

    @isTest
    static void getPhiStatusFlowBatchTest() {
        String cronExpr = '0 15 5 ? * *';
        Test.startTest();
        OverdueWorkDailyCheckScheduler overdueWorkCheck = new OverdueWorkDailyCheckScheduler();
        String jobId = System.schedule('Daily Overdue Work Assignment Chatter Post Test', cronExpr, overdueWorkCheck);
        overdueWorkCheck.execute(null);
        Test.stopTest();
    }
}