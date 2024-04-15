/**
 * Created by jmahapatra on 11/29/17.
 */
@isTest
public with sharing class RepliconTest {

    @testSetup
    static void setupData()
    {
        Account a = new Account();
        a.Name = 'Test Account';
        a.RepliconClientUri__c = 'urn:replicon-tenant:levementum:client:401';
        insert a;

        // create opportunity
        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.Name = 'Test Opp';
        o.StageName = 'First stage';
        o.CloseDate = system.today()+60;
        o.Amount = 55000.00;
        o.StageName='Closed On';
        o.CloseDate = Date.parse('12/12/2017');
        o.Project_Terms__c = 'Time and Materials';
        o.Payment_Terms__c = 'Invoice Net 15';
        o.LevementumVertical__c = 'CPG';
        o.Payment_Schedule__c = 'Standard TM';
        insert o;

        Opportunity op = new Opportunity();
        op.AccountId = a.Id;
        op.Name = 'Test Opp2';
        op.StageName = 'First stage';
        op.CloseDate = system.today()+60;
        op.Amount = 55000.00;
        op.StageName='Closed On';
        op.CloseDate = Date.parse('12/12/2017');
        op.Project_Terms__c = 'Time and Materials';
        op.Payment_Terms__c = 'Invoice Net 15';
        op.LevementumVertical__c = 'Retail';
        op.Payment_Schedule__c = 'Standard TM';
        insert op;

        Opportunity op2 = new Opportunity();
        op2.AccountId = a.Id;
        op2.Name = 'Test Opp3';
        op2.StageName = 'First stage';
        op2.CloseDate = system.today()+60;
        op2.Amount = 55000.00;
        op2.StageName='Closed On';
        op2.CloseDate = Date.parse('12/12/2017');
        op2.Project_Terms__c = 'Time and Materials';
        op2.Payment_Terms__c = 'Invoice Net 15';
        op2.LevementumVertical__c = 'Manufacturing';
        op2.Payment_Schedule__c = 'Standard TM';
        insert op2;


        // create a project to test against
        Project__c p = new Project__c();
        p.Account__c = a.Id;
        p.Opportunity__c = o.Id;
        p.Name = 'Test Opp';
        p.Project_Status__c = 'In Progress';
        p.RepliconUri__c='urn:replicon-tenant:levementum:project:1154';
        insert p;

        // create a project to test against
        Project__c p2 = new Project__c();
        p2.Account__c = a.Id;
        p2.Opportunity__c = op.Id;
        p2.Name = 'Test Opp2';
        p2.Project_Status__c = 'In Progress';
        p2.RepliconUri__c='urn:replicon-tenant:levementum:project:1154';
        insert p2;

        // create a project to test against
        Project__c p3 = new Project__c();
        p3.Account__c = a.Id;
        p3.Opportunity__c = op2.Id;
        p3.Name = 'Test Opp3';
        p3.Project_Status__c = 'In Progress';
        p3.RepliconUri__c='urn:replicon-tenant:levementum:project:1154';
        insert p3;

        RepliconDropdowns__c rr =new RepliconDropdowns__c(
        Name = 'Pr-Payment-Terms-Invoice-Net-15',
        Group__c='Project-Payment-Terms',
        Value__c='Invoice Net 15',
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
        rr6.Name = 'Pr-Practice-Other';
        rr6.Group__c='Project-Practice';
        rr6.Value__c='Other';
        rr6.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';
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

        RepliconDropdowns__c rr9 =new RepliconDropdowns__c(Name = 'Pr-Expense-Entry-Type-Fixed-Price', Group__c='test', Value__c='Other',
        uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14');
        insert rr9;
        RepliconDropdowns__c rr10 =new RepliconDropdowns__c(Name = 'Pr-Inv-Schedule-Url', Group__c='test', Value__c='Other', uri__c='test');
        insert rr10;
        RepliconDropdowns__c rr11 =new RepliconDropdowns__c(Name = 'Pr-InvTerms-Standard-TM', Group__c='test', Value__c='Other', uri__c='test');
        insert rr11;
        RepliconDropdowns__c rr12 =new RepliconDropdowns__c(Name='Ts-Payment-Terms-Url',Group__c='test',Value__c='Other',uri__c='test');
        insert rr12;
        RepliconDropdowns__c rr13 =new RepliconDropdowns__c(Name='Ts-Payment-Terms-Invoice-Net-15',Group__c='test',Value__c='Other',uri__c='test');
        insert rr13;
        RepliconDropdowns__c rr14 =new RepliconDropdowns__c(Name='Ts-Practice-Url',Group__c='test',Value__c='Other',uri__c='test');
        insert rr14;
        RepliconDropdowns__c rr15 =new RepliconDropdowns__c(Name='Ts-Practice-Other',Group__c='test',Value__c='Other',uri__c='test');
        insert rr15;
        RepliconDropdowns__c rr16 =new RepliconDropdowns__c(Name='Ts-Pr-Terms-Url',Group__c='test',Value__c='Other',uri__c='test');
        insert rr16;
        RepliconDropdowns__c rr17 =new RepliconDropdowns__c(Name='Ts-Pr-Terms-Time-and-Materials',Group__c='test',Value__c='Other',uri__c='test');
        insert rr17;
        RepliconDropdowns__c rr18 =new RepliconDropdowns__c(Name='Ts-Type-Change-Order',Group__c='test',Value__c='Project',uri__c='urn:replicon-tenant:levementum:96d40141c32a');
        insert rr18;
        RepliconDropdowns__c rr19 =new RepliconDropdowns__c(Name='Ts-Type-Url',Group__c='test',Value__c='Project',uri__c='d3e5-4d5f-ba99-96d40141c32a');
        insert rr19;
    }

    @isTest
    public static void getProjectByIdTest(){

        Project__c pr = [Select Id from Project__c where Name='Test Opp' limit 1];
        Project__c pr2 = [Select Id from Project__c where Name='Test Opp2' limit 1];
        Project__c pr3 = [Select Id from Project__c where Name='Test Opp3' limit 1];
        Test.startTest();

        Replicon.Project prj = Replicon.getProjectById(pr.Id);
        System.assert(prj.toString()!='');

        Replicon.Project prj2 = Replicon.getProjectById(pr2.Id);
        System.assert(prj2.toString()!='');

        Replicon.Project prj3 = Replicon.getProjectById(pr3.Id);
        System.assert(prj3.toString()!='');


        Test.stopTest();
    }

    @isTest
    public static void getProjectTaskByIdTest(){

        Project__c pr = [Select Id,RepliconUri__c from Project__c where Name='Test Opp' limit 1];
        Replicon.Task tsk = Replicon.getProjectTaskById(pr.Id);
        tsk.projectUri = 'urn:replicon-tenant:levementum:project:1154';
        Test.startTest();
        System.assertEquals(pr.RepliconUri__c,tsk.projectUri);
        Test.stopTest();
    }

    @isTest
    public static void  getClientByIdTest(){
        Account a = [select Id from Account where Name='Test Account'];
        Replicon.Client cl = Replicon.getClientById(a.Id);
        System.debug('*cl' + cl.toString());
        Test.startTest();
        //System.assertEquals('{"uri":null,"client":{"uri":null,"target":{"uri":"urn:replicon-tenant:levementum:client:401","parameterCorrelationId":null,"name":"Test Account"},"name":"Test Account","isActive":"true","customFieldValues":[],"comment":null,"clientAddress":{"zipPostalCode":null,"website":null,"stateProvince":null,"phoneNumber":null,"faxNumber":null,"email":null,"country":null,"city":null,"address":null},"billingContact":null,"billingAddress":{"zipPostalCode":null,"website":null,"stateProvince":null,"phoneNumber":null,"faxNumber":null,"email":null,"country":{"uri":"urn:replicon:country:united-states","name":"United States"},"city":null,"address":null}}}',cl.toString());
        Test.stopTest();
    }
}