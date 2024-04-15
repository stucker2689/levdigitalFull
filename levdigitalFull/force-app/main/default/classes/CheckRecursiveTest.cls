@isTest
public with sharing class CheckRecursiveTest {
    
    @isTest
    static void checkRunBeforeInsertOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runbeforeInsertOnce();
        Test.stopTest();
        
        System.assertEquals(true, checkRunOnce, 'Before Insert not flagged that runbeforeInsertOnce ran Once');
    }

    @isTest
    static void checkRunBeforeUpdateOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce= CheckRecursive.runbeforeUpdateOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'Before Update not flagged that runbeforeUpdateOnce ran Once');
    }

    @isTest
    static void checkRunAferInsertOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runafterInsertOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Insert not flagged that runafterInsertOnce ran Once');
    }

    @isTest
    static void checkRunAfterUpdateOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runafterUpdateOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runafterUpdateOnce ran Once');
    }
    @isTest
    static void checkRunAfterUpdate2OnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runafterUpdateOnce2();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runafterUpdateOnce2 ran Once');
    }
    @isTest
    static void checkRunAfterUpdate3OnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runafterUpdateOnce3();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runafterUpdateOnce3 ran Once');
    }

    @isTest
    static void checkRunCreateProjectsOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runCreateProjectsOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runCreateProjectsOnce ran Once');
    }

    @isTest
    static void checkRunCalculateAccountOnceTest(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runCalculateAccountOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runCalculateAccountOnce ran Once');
    }

    @isTest
    static void checkRunUpdateAcctLowestBudgetRemainingOnce(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runUpdateAcctLowestBudgetRemainingOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runUpdateAcctLowestBudgetRemainingOnce ran Once');
    }

    @isTest
    static void runUpdateAccountFirstYearBookingOnce(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runUpdateAccountFirstYearBookingOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runUpdateAccountFirstYearBookingOnce ran Once');
    }

    @isTest
    static void runCountAccountRiskLevelOnce(){
        Boolean checkRunOnce;

        Test.startTest();
        checkRunOnce = CheckRecursive.runCountAccountRiskLevelOnce();
        Test.stopTest();

        System.assertEquals(true, checkRunOnce, 'After Update not flagged that runCountAccountRiskLevelOnce ran Once');
    }

    //Testing running Check Twice
    @isTest
    static void checkRunBeforeInsertTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runbeforeInsertOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runbeforeInsertOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'Before Insert not flagged that runbeforeInsertOnce ran Twice');
    }

    @isTest
    static void checkRunBeforeUpdateTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runbeforeUpdateOnce();

        Test.startTest();
        checkRunTwice= CheckRecursive.runbeforeUpdateOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'Before Update not flagged that runbeforeUpdateOnce ran Twice');
    }
    
    @isTest
    static void checkRunAferInsertTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runafterInsertOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runafterInsertOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Insert not flagged that runafterInsertOnce ran Twice');
    }

    @isTest
    static void checkRunAfterUpdateTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runafterUpdateOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runafterUpdateOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runafterUpdateOnce ran Twice');
    }

    @isTest
    static void checkRunAfterUpdate2TwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runafterUpdateOnce2();

        Test.startTest();
        checkRunTwice = CheckRecursive.runafterUpdateOnce2();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runafterUpdateOnce2 ran Twice');
    }

    @isTest
    static void checkRunAfterUpdate3TwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runafterUpdateOnce3();

        Test.startTest();
        checkRunTwice = CheckRecursive.runafterUpdateOnce3();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runafterUpdateOnce3 ran Twice');
    }

    @isTest
    static void checkRunCreateProjectTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runCreateProjectsOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runCreateProjectsOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runCreateProjectsOnce ran Twice');
    }

    @isTest
    static void checkRunCalculateAccountTwiceTest(){
        Boolean checkRunTwice;
        CheckRecursive.runCalculateAccountOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runCalculateAccountOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runCalculateAccountOnce ran Twice');
    }

    @isTest
    static void checkRunUpdateAcctLowestBudgetRemainingTwice(){
        Boolean checkRunTwice;
        CheckRecursive.runUpdateAcctLowestBudgetRemainingOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runUpdateAcctLowestBudgetRemainingOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runUpdateAcctLowestBudgetRemainingOnce ran Twice');
    }

    @isTest
    static void runUpdateAccountFirstYearBookingTwice(){
        Boolean checkRunTwice;
        CheckRecursive.runUpdateAccountFirstYearBookingOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runUpdateAccountFirstYearBookingOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runUpdateAccountFirstYearBookingOnce ran Twice');
    }

    @isTest
    static void runCountAccountRiskLevelTwice(){
        Boolean checkRunTwice;
        CheckRecursive.runCountAccountRiskLevelOnce();

        Test.startTest();
        checkRunTwice = CheckRecursive.runCountAccountRiskLevelOnce();
        Test.stopTest();

        System.assertEquals(false, checkRunTwice, 'After Update not flagged that runCountAccountRiskLevelOnce ran Twice');
    }
}