/**
 * Created by jmahapatra on 12/1/17.
 */


@isTest
public with sharing class RepliconTaskUpsertTest {


    static Opportunity oppr;
    static Account ac;

    static {
        CheckFirst.calculateAcc = false;
        CheckFirst.calculateOpp = false;

        EnableReplicon__c en = new EnableReplicon__c();
        en.IsActiveProject__c = true;
        en.Name ='test';
        insert  en;

        RepliconDropdowns__c rr =new RepliconDropdowns__c(Name = 'Pr-Payment-Terms-Invoice-Net-15',Group__c='Project-Payment-Terms',Value__c='Invoice Net 15',
                uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f95');
        insert rr;

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

        List<RepliconDropdowns__c> rep = new List<RepliconDropdowns__c>();
        RepliconDropdowns__c rr12 =new RepliconDropdowns__c(Name='Ts-Payment-Terms-Url',Group__c='test',Value__c='Other',uri__c='test');rep.add(rr12);
        RepliconDropdowns__c rr13 =new RepliconDropdowns__c(Name='Ts-Payment-Terms-Invoice-Net-15',Group__c='test',Value__c='Other',uri__c='test');rep.add( rr13);
        RepliconDropdowns__c rr14 =new RepliconDropdowns__c(Name='Ts-Practice-Url',Group__c='test',Value__c='Salesforce',uri__c='test');rep.add( rr14);
        RepliconDropdowns__c rr15 =new RepliconDropdowns__c(Name='Ts-Practice-Salesforce',Group__c='test',Value__c='Salesforce',uri__c='test');rep.add( rr15);
        RepliconDropdowns__c rr16 =new RepliconDropdowns__c(Name='Ts-Pr-Terms-Url',Group__c='test',Value__c='Other',uri__c='test');rep.add( rr16);
        RepliconDropdowns__c rr17 =new RepliconDropdowns__c(Name='Ts-Pr-Terms-Time-and-Materials',Group__c='test',Value__c='Other',uri__c='test');rep.add( rr17);
        RepliconDropdowns__c rr18 =new RepliconDropdowns__c(Name='Ts-Type-Change-Order',Group__c='test',Value__c='Project',uri__c='urn:replicon-tenant:levementum:96d40141c32a');rep.add( rr18);
        RepliconDropdowns__c rr19 =new RepliconDropdowns__c(Name='Ts-Type-Url',Group__c='test',Value__c='Project',uri__c='d3e5-4d5f-ba99-96d40141c32a');rep.add( rr19);
        insert rep;



        // create account
        Account a = new Account();
        a.Name = 'Test Account';
        a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        insert a;

        ac = a;


        //List<Opportunity> ops =new List<Opportunity>();
        //Opportunity
        Opportunity op = new Opportunity();
        op.AccountId = a.Id;
        op.Name = 'Test Project';
        op.CloseDate = system.today()+60;
        op.Amount = 55000.00;
        op.Project_Terms__c = 'Time and Materials';
        op.Payment_Terms__c = 'Invoice Net 15';
        op.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('ASC Service Contract').getRecordTypeId();
        op.StageName = 'Closed Won';
        //op.StageName = 'Finalized Contracts';
        op.Interested_In__c = 'Salesforce';
        op.SubPractice__c = 'Marketing Cloud';
        insert op;

        oppr = op;

        Product2 pr = new Product2();
        pr.Name = 'SFDC - Engineer';
        insert pr;

        PricebookEntry price = new PricebookEntry();
        price.UnitPrice = 150;
        price.Product2Id =  pr.Id;
        price.Pricebook2Id = Test.getStandardPricebookId();
        price.IsActive = true;
        insert price;

        OpportunityLineItem lt = new OpportunityLineItem();
        lt.OpportunityId = oppr.Id;
        lt.Product2 = pr;
        lt.Quantity = 10;
        lt.PricebookEntryId = price.Id;
        lt.UnitPrice = 185;
        insert lt;

        Opportunity op2 = new Opportunity();
        op2.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
        op2.Change_Orders__c = oppr.Id;
        op2.AccountId = ac.Id;
        op2.Name = 'CO TEst';
        op2.Project_Terms__c = 'Other';
        op2.Payment_Terms__c = 'Other';
        op2.CloseDate = system.today()+70;
        op2.Amount = 1000.00;
        op2.StageName = 'Closed Won';
        op2.Interested_In__c = 'Saleforce';
        //op2.SubPractice__c = 'SugarCRM';
        insert op2;
    }

    

}