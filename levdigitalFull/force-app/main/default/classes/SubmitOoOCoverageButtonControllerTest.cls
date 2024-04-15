@isTest
public with sharing class SubmitOoOCoverageButtonControllerTest {
    
    @isTest
    public static void testGetLevStaffingQueueId(){
        Id testResponse = null;
        Test.startTest();
        testResponse = SubmitOoOCoverageRequestButtonController.getLevStaffingQueue();
        Test.stopTest();

    }

}