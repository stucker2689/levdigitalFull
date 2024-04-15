@istest
class TestBudgetSchedulers {

    static testmethod void testBudgetFieldsReset() {
        Test.startTest();

        Account a = new Account();
        a.Name = 'testScheduledApexFromTestMethod';
        insert a;

        // Schedule the test job
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('BudgetFieldsResetScheduler', CRON_EXP, new BudgetFieldsResetScheduler());

        Test.stopTest();

    }

    static testmethod void testWeeklyBudget() {
        Test.startTest();

        Account a = new Account();
        a.Name = 'testScheduledApexFromTestMethod';
        insert a;

        // Schedule the test job
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('WeeklyBudgetForecastSch', CRON_EXP, new WeeklyBudgetForecastSch());

        Test.stopTest();

    }

    static testmethod void testQuarterlyBudget() {
        Test.startTest();

        Account a = new Account();
        a.Name = 'testScheduledApexFromTestMethod';
        insert a;

        // Schedule the test job
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('QuarterlyBudgetForecastSch', CRON_EXP, new QuarterlyBudgetForecastSch());

        Test.stopTest();

    }
}