/**
 * Created by jmahapatra on 3/6/18.
 */
@isTest
public with sharing class RepliconClientUpsertTest {



    static testMethod void testClientUpsert(){

        EnableReplicon__c en = new EnableReplicon__c();
        en.IsActiveProject__c = true;
        en.Name ='test';
        insert  en;

        Account ac = new Account();
        ac.Name = 'Test Account';
        insert ac;

        String successPayload = '{"d":{"displayText":"SFDC Test Project 2","name":"SFDC Test Project 2","slug":"sfdc-test-project-2","uri":"urn:replicon-tenant:levementum:project:1154"}}';
        RepliconServiceUpsertMock mock = new RepliconServiceUpsertMock(200, 'Success', successPayload, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);


        Test.startTest();
        RepliconClientUpsert rp = new RepliconClientUpsert(ac.Id);
        Id jobId = System.System.enqueueJob(rp);
        Test.stopTest();
    }
}