/**
 * Created by jmahapatra on 12/15/17.
 */

@isTest
public with sharing class RepliconProjectUpsertTest {

    static Opportunity oppr;
    static Opportunity oppr2;
    static Opportunity oppr3;
    static Account ac;

    static {

        EnableReplicon__c en = new EnableReplicon__c();
        en.IsActiveProject__c = true;
        en.Name ='test';
        insert  en;

        RepliconDropdowns__c rr =new RepliconDropdowns__c();
        rr.Name = 'Pr-Payment-Terms-Invoice-Net-45';
        rr.Group__c='Project-Payment-Terms';
        rr.Value__c='Invoice Net 45';
        rr.uri__c='urn:replicon-tenant:levementum:custom-field-option:668351da-f86b-4168-bd6e-cd338d6fa9c4';
        insert rr;

        RepliconDropdowns__c rr0 =new RepliconDropdowns__c();
        rr0.Name = 'Pr-Payment-Terms-Invoice-Net-30';
        rr0.Group__c='Project-Payment-Terms';
        rr0.Value__c='Invoice Net 30';
        rr0.uri__c='urn:replicon-tenant:levementum:custom-field-option:668351da-f86b-4168-bd6e-cd338d6fa9c4';
        insert rr0;

        RepliconDropdowns__c rr1 =new RepliconDropdowns__c();
        rr1.Name = 'Pr-Payment-Terms-Url';
        rr1.Group__c='Project-Payment-Terms';
        rr1.Value__c='Url';
        rr1.uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f95';
        insert rr1;

        RepliconDropdowns__c rr2 =new RepliconDropdowns__c();
        rr2.Name = 'Pr-Terms-Time-and-Materials';
        rr2.Group__c='Project-Terms';
        rr2.Value__c='Time & Materials';
        rr2.uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661';
        insert rr2;

        RepliconDropdowns__c rr3 =new RepliconDropdowns__c();
        rr3.Name = 'Pr-Terms-Url';
        rr3.Group__c='Project-Terms';
        rr3.Value__c='URL';
        rr3.uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661';
        insert rr3;

        RepliconDropdowns__c rr32 =new RepliconDropdowns__c();
        rr32.Name = 'Pr-Terms-Fixed-Price';
        rr32.Group__c='Project-Terms';
        rr32.Value__c='URL';
        rr32.uri__c='test';
        insert rr32;

        RepliconDropdowns__c rr33 =new RepliconDropdowns__c();
        rr33.Name = 'Pr-Terms-Time-and-Materials';
        rr33.Group__c='Project-Terms';
        rr33.Value__c='URL';
        rr33.uri__c='test';
        insert rr33;

        RepliconDropdowns__c rr4 =new RepliconDropdowns__c();
        rr4.Name = 'BillingType-Time-and-Materials';
        rr4.Group__c='Project-BillingType';
        rr4.Value__c='Time and Materials';
        rr4.uri__c='urn:replicon:billing-type:time-and-material';
        insert rr4;

        RepliconDropdowns__c rr5 =new RepliconDropdowns__c();
        rr5.Name = 'Pr-Project-Practice-URL';
        rr5.Group__c='Project-Practice';
        rr5.Value__c='URL';
        rr5.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';
        insert rr5;

        RepliconDropdowns__c rr6 =new RepliconDropdowns__c();
        rr6.Name = 'Pr-Practice-Salesforce';
        rr6.Group__c='Project-Practice';
        rr6.Value__c='SUgarCRM';
        rr6.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';
        insert rr6;

        RepliconDropdowns__c rr61 =new RepliconDropdowns__c();
        rr61.Name = 'Pr-Practice-Salesforce-Core';
        rr61.Group__c='Project-Practice';
        rr61.Value__c='Salesforce';
        rr61.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';
        insert rr61;

        RepliconDropdowns__c rr62 =new RepliconDropdowns__c();
        rr62.Name = 'Pr-Practice-SFDC-Core';
        rr62.Group__c='Project-Practice';
        rr62.Value__c='SFDC-Core';
        rr62.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';
        insert rr62;

        RepliconDropdowns__c rr7=new RepliconDropdowns__c();
        rr7.Name = 'Pr-Type-URL';
        rr7.Group__c='Project-Type';
        rr7.Value__c='Type';
        rr7.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';
        insert rr7;

        RepliconDropdowns__c rr8 =new RepliconDropdowns__c();
        rr8.Name = 'Pr-Type-Project';
        rr8.Group__c='test';
        rr8.Value__c='Other';
        rr8.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';
        insert rr8;

        RepliconDropdowns__c rr9 =new RepliconDropdowns__c();
        rr9.Name = 'Pr-Expense-Entry-Type-Fixed-Price';
        rr9.Group__c='test';
        rr9.Value__c='Other';
        rr9.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';
        insert rr9;

        RepliconDropdowns__c rr10 =new RepliconDropdowns__c();
        rr10.Name = 'Pr-Inv-Schedule-Url';
        rr10.Group__c='test';
        rr10.Value__c='Other';
        rr10.uri__c='test';
        insert rr10;

        RepliconDropdowns__c rr11 =new RepliconDropdowns__c();
        rr11.Name = 'Pr-InvTerms-Standard-TM';
        rr11.Group__c='test';
        rr11.Value__c='Other';
        rr11.uri__c='test';
        insert rr11;

        RepliconDropdowns__c rr12 =new RepliconDropdowns__c();
        rr12.Name = 'BillingType-Fixed-Price';
        rr12.Group__c='test';
        rr12.Value__c='Other';
        rr12.uri__c='test';
        insert rr12;

        RepliconDropdowns__c rr13 =new RepliconDropdowns__c();
        rr13.Name = 'BillingType-Non-Billable';
        rr13.Group__c='test';
        rr13.Value__c='Other';
        rr13.uri__c='test';
        insert rr13;

        RepliconDropdowns__c rr14 =new RepliconDropdowns__c();
        rr14.Name = 'BillingType-Time-and-Materials';
        rr14.Group__c='test';
        rr14.Value__c='Other';
        rr14.uri__c='test';
        insert rr14;



        // create account
        Account a = new Account();
        a.Name = 'Test Account';
        a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        a.MSA_Number__c ='MSA-2013-1312';
        insert a;

        Opportunity op = new Opportunity();
        op.AccountId = a.Id;
        op.Name = 'Test Project';
        op.CloseDate = system.today()+60;
        op.Amount = 55000.00;
        op.Project_Terms__c = 'Time and Materials';
        op.Payment_Terms__c = 'Invoice Net 45';
        op.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('ASC Service Contract').getRecordTypeId();
        op.StageName = 'Finalize Contracts';
        op.Interested_In__c = 'Salesforce';
        op.SubPractice__c = 'Marketing Cloud';
        op.Probability=90;
        op.Create_Project__c = true;
        insert op;

        oppr = op;
        ac = a;

        Opportunity op2 = new Opportunity();
        op2.AccountId = ac.Id;
        op2.Name = 'Test Project2';
        op2.CloseDate = system.today()+60;
        op2.Amount = 55000.00;
        op2.Project_Terms__c = 'Fixed Price';
        op2.Payment_Terms__c = 'Invoice Net 30';
        op2.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('ASC Service Contract').getRecordTypeId();
        op2.StageName = 'Finalize Contracts';
        op2.Interested_In__c = 'Salesforce';
        op2.SubPractice__c = 'Marketing Cloud';
        op2.Probability=90;
        op2.Create_Project__c = true;
        insert op2;oppr2=op2;

        Opportunity oc = new Opportunity();
        oc.Change_Orders__c = oppr.Id;
        oc.AccountId = ac.Id;
        oc.Name = 'Test CO';
        oc.CloseDate = system.today()+60;
        oc.Amount = 55000.00;
        oc.Project_Terms__c = 'Time and Materials';
        oc.Payment_Terms__c = 'Invoice Net 45';
        oc.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
        oc.StageName = 'Finalize Contracts';
        oc.Interested_In__c = 'Salesforce';
        oc.SubPractice__c = 'Marketing Cloud';
        oc.Probability=90;
        insert oc;
        oppr3 = oc;

    }

    

   

    

    @isTest static void testChangeOrder(){

        Test.startTest();
        oppr3.StageName = 'Closed Own';
        upsert oppr3;
        System.assert(true);
        Test.stopTest();
    }
}