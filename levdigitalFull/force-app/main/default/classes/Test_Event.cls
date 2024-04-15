/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_Event {

    static testMethod void myUnitTest() {
    	//get the rec type for Customer accounts
		Id rt = [Select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Client' limit 1].Id;
		Id ar = [SELECT Id FROM RecordType WHERE sObjectType = 'Event' AND DeveloperName = 'Account_Review' limit 1].Id;
		
		//create and insert account
        Account a = new Account(Name='Test', RecordTypeId = rt, MSA_Number__c = '123A', Latest_Work_Log__c = 'test', Last_Account_Review__c = date.today(), Next_Account_Review__c = date.today());
		insert a;
		
		//create and insert an event related to the account
		Event e = new Event(RecordTypeId = ar, Subject = 'Test', StartDateTime = date.today(), EndDateTime = date.today(), WhatId = a.Id);
		insert e;
		
		e.Account_Review__c = true;
		update e;
		system.assertEquals(a.Next_Account_Review__c, e.StartDateTime);
		
		//update the event to fire the update trigger
		e.Meeting_Status__c = 'Held';
		update e;
		
		system.assertEquals(a.Last_Account_Review__c, e.EndDateTime);
    }
}