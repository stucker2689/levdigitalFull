@isTest
private class StaffingAssignmentTrigger_Test {

    @TestSetup
    static void makeData(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        User u = new User(Alias = uid, Email= uid + '@myorg.com', 
            EmailEncodingKey='UTF-8', FirstName='Test', LastName='User', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com');
            
    Blob b2 = Crypto.GenerateAESKey(128);
        String h2 = EncodingUtil.ConvertTohex(b2);
        String uid2 = h2.SubString(0,8);
        User u2 = new User(Alias = uid2, Email= uid2 + '@myorg.com', 
            EmailEncodingKey='UTF-8', FirstName='Test', LastName='UserTwo', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/New_York', UserName= uid2 + '@myorg.com'); 
        
        List<User> userInsertList = new List<User>{u, u2};
        insert userInsertList; 
        
        System.debug('Apex CPU Time used so far ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime() + ' 11111111111111111');
        Integer previousCpuTime = 0;
        Integer cpuUsage = Limits.getCpuTime() - previousCpuTime;
        previousCpuTime = Limits.getCpuTime();
        System.debug('CPU Time used: ' + String.valueOf(cpuUsage));
        System.debug('-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*');

        //Create Accounts
        Account levAcct = TestDataFactory.createAccount(false, 'Partner');
        levAcct.Name = 'Levementum LLC';

        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        
        List<Account> setupAccountInsertList = new List<Account>{acct};
        insert setupAccountInsertList;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        //testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.StageName = 'Identifying an Opportunity';
        testOppty1.Name = 'Test Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;
        insert testOppty1;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Email = 'testEmployeeEmail@gmail.com';

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.FirstName = 'Test Employee';
        testEmployee2.LastName = 'Number Two';
        testEmployee2.Email = 'testEmployeeEmail2@gmail.com';

        Contact testEmployee3 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee3.FirstName = 'Test Employee';
        testEmployee3.LastName = 'Number Three';
        testEmployee3.Email = 'testEmployeeEmail3@gmail.com';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1, testEmployee2, testEmployee3};
        insert setupEmployeeInsertList;

        //Create Products, Price Book Entries, Opportunity Line Items
        Product2 developerProduct = new Product2(Name = 'Developer');
        Product2 mcSolutionArchitectProduct = new Product2(Name = 'MC - Solution Architect');
        Product2 projectManagerProduct = new Product2(Name = 'Project Manager');
        Product2 coreTechnicalArchitectProduct = new Product2(Name = 'CORE - Techincal Architect');
        List<Product2> testProductsList = new List<Product2>{developerProduct, mcSolutionArchitectProduct, projectManagerProduct, coreTechnicalArchitectProduct};
        insert testProductsList;

        PricebookEntry developerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = developerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry mcSolutionArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = mcSolutionArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry projectManagerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = projectManagerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry coreTechnicalArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = coreTechnicalArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        List<PricebookEntry> testPriceBookEntryList = new List<PricebookEntry>{developerPriceBookEntry, mcSolutionArchitectPriceBookEntry, projectManagerPriceBookEntry, coreTechnicalArchitectPriceBookEntry};
        insert testPriceBookEntryList;

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'ATG');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - UK'); 
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{projectManagerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.CSP_Email__c = 'testemail@gmail.com';
        testOppty1.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        update testOppty1;

    }

    @isTest
    static void createProjectTeamMemberFromStaffingAssignment2(){

        System.debug('createProjectTeamMemberFromStaffingAssignment2');

        Opportunity testOppty1 = [SELECT Id, Name, StageName, CloseDate  FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        //Contact testContact = [SELECT Id, Name FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        List<Contact> testContactList = [SELECT Id, Name FROM Contact];
        //Move Oppty 1 to Closed Won to confirm that
        List<Staffing_Assignment__c> existingStaffingAssignment = new List<Staffing_Assignment__c>();
        existingStaffingAssignment = [SELECT Id, Name, Status__c, Product__r.Name, Product_Name__r.Name, Resource_Assigned__c, Resource_Delivery_Group__c, Opportunity__c, Opportunity__r.Name, 
                                            Opportunity__r.Count_of_Created_Staffing_Created__c, Opportunity__r.Count_of_Staffing_Completed__c, Opportunity__r.Initial_Staffing_Complete__c, Interview_Requested__c 
                                        FROM Staffing_Assignment__c];
                                        //WHERE Opportunity__c =: testOppty1.Id

        List<Staffing_Assignment__c> updateStaffingAssignmentList = new List<Staffing_Assignment__c>();
        Integer iterationCount = 0;
        for(Staffing_Assignment__c sa : existingStaffingAssignment){
            iterationCount++;

            switch on iterationCount{
                when 1{
                    sa.Resource_Assigned__c = testContactList[0].Id;
                }
                when 2{
                    sa.Resource_Assigned__c = testContactList[1].Id;
                }
                when else{
                    sa.Resource_Assigned__c = testContactList[2].Id;
                }
            }
            System.debug('OpportunityI Id: ' + sa.Opportunity__c);
            //sa.Resource_Assigned__c = testContact.Id;
            sa.CSP_Email__c = 'testemail@gmail.com';
            sa.Opportunity_Owner_Email__c = 'testemail@gmail.com';
            sa.Assigned_Resource_Manager_email__c = 'testemail@gmail.com';
            //sa.Status__c = 'Completed';
            updateStaffingAssignmentList.add(sa);
        }

        System.debug('testOppty1: ' + testOppty1.Id);

        update updateStaffingAssignmentList;

        System.debug('Existing Staffing Assignments Size: ' + existingStaffingAssignment.size());
        System.debug('Existing Staffing Assignments: ' + existingStaffingAssignment);

        Test.startTest();
        List<Staffing_Assignment__c> existingStaffingAssignment2 = new List<Staffing_Assignment__c>();
        existingStaffingAssignment2 = [SELECT Id, Name, Status__c, Product__r.Name, Product_Name__r.Name, Resource_Assigned__c, Resource_Delivery_Group__c, Opportunity__c, Opportunity__r.Name, 
                                            Opportunity__r.Count_of_Created_Staffing_Created__c, Opportunity__r.Count_of_Staffing_Completed__c, Opportunity__r.Initial_Staffing_Complete__c, Interview_Requested__c, Completed_Date__c
                                        FROM Staffing_Assignment__c];


        List<Staffing_Assignment__c> updateStaffingAssignmentList2 = new List<Staffing_Assignment__c>();
        for(Staffing_Assignment__c sa : existingStaffingAssignment2){
            System.debug('Oppty Initial Staffing Completed 2: ' + sa.Opportunity__r.Initial_Staffing_Complete__c);
            System.debug('Count of Created Staffing Completed 2: ' + sa.Opportunity__r.Count_of_Staffing_Completed__c);
            System.debug('Count of Created Staffing Created 2: ' + sa.Opportunity__r.Count_of_Created_Staffing_Created__c);
            System.debug('Interview Requested 2: ' + sa.Interview_Requested__c);
            System.debug('Staffing Assignment Status 2: ' + sa.Status__c);
            sa.Status__c = 'Completed';
            updateStaffingAssignmentList2.add(sa);
            //update sa;
        }

        update updateStaffingAssignmentList2;


        List<Staffing_Assignment__c> existingStaffingAssignment3 = new List<Staffing_Assignment__c>();
        existingStaffingAssignment3 = [SELECT Id, Name, Status__c, Product__r.Name, Product_Name__r.Name, Resource_Assigned__c, Resource_Delivery_Group__c, Opportunity__c, Opportunity__r.Name,
                                            Opportunity__r.Count_of_Created_Staffing_Created__c, Opportunity__r.Count_of_Staffing_Completed__c, Opportunity__r.Initial_Staffing_Complete__c, Interview_Requested__c
                                        FROM Staffing_Assignment__c];

        for(Staffing_Assignment__c sa : existingStaffingAssignment3){
            System.debug('Oppty Initial Staffing Completed 3: ' + sa.Opportunity__r.Initial_Staffing_Complete__c);
            System.debug('Count of Created Staffing Completed 3: ' + sa.Opportunity__r.Count_of_Staffing_Completed__c);
            System.debug('Count of Created Staffing Created 3: ' + sa.Opportunity__r.Count_of_Created_Staffing_Created__c);
            System.debug('Interview Requested 3: ' + sa.Interview_Requested__c);
            System.debug('Staffing Assignment Status 3: ' + sa.Status__c);
        }


        Opportunity updateOppty = [SELECT Id, Name, StageName, CloseDate, Count_of_Created_Staffing_Created__c, Count_of_Staffing_Completed__c, Initial_Staffing_Complete__c FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];

        System.debug('Oppty Before Update Check: ' + updateOppty);
        System.debug('Oppty Before Update Check Counts Count of Staffing Completed: ' + updateOppty.Count_of_Staffing_Completed__c + '   Count of Created Staffing Created: ' + updateOppty.Count_of_Created_Staffing_Created__c );
        if(updateOppty.Count_of_Staffing_Completed__c == updateOppty.Count_of_Created_Staffing_Created__c){
            System.debug('*************************** Counts are equal!!!!! ******************************');
        }

        updateOppty.Initial_Staffing_Complete__c = true;
        updateOppty.StageName = 'Closed Won';
        update updateOppty;


        List<Client_Contact__c> internalProjMemberList = new List<Client_Contact__c>();
        internalProjMemberList = [SELECT Id, Name, Contact_Role__c, Project__r.Name, Client_Contact__r.Name
                                    FROM Client_Contact__c];

        System.debug('Internal Proj Member Count: ' + internalProjMemberList.size());

        for(Client_Contact__c cc : internalProjMemberList){
            System.debug('Internal Proj Member: ' + cc);
        }

        Test.stopTest();

        System.assertEquals(2, internalProjMemberList.size(), 'The wrong amount of Internal Project Team Members were or were not created by the Staffing Assignment Process');
        
    }

    @isTest
    static void deleteStaffingAssignment_Test(){

        List<Staffing_Assignment__c> existingStaffingAssignmentsList = new List<Staffing_Assignment__c>();
        existingStaffingAssignmentsList = [SELECT Id, Name, Status__c, Product__r.Name, Product_Name__r.Name, Resource_Assigned__c, Resource_Delivery_Group__c, Opportunity__c, Opportunity__r.Name, 
                                            Opportunity__r.Count_of_Created_Staffing_Created__c, Opportunity__r.Count_of_Staffing_Completed__c, Opportunity__r.Initial_Staffing_Complete__c, Interview_Requested__c 
                                        FROM Staffing_Assignment__c
                                        WHERE Opportunity__r.Name = 'Test Oppty 1'];

        Decimal originalStaffingAssignmentCount = 0;

        List<Staffing_Assignment__c> staffingAssignmentsToDeleteList = new List<Staffing_Assignment__c>();
        for(Staffing_Assignment__c sa : existingStaffingAssignmentsList){
            if(staffingAssignmentsToDeleteList.size() == 0){
                staffingAssignmentsToDeleteList.add(sa);
            }

            originalStaffingAssignmentCount = sa.Opportunity__r.Count_of_Created_Staffing_Created__c;
        }

        if(staffingAssignmentsToDeleteList.size() > 0){
            delete staffingAssignmentsToDeleteList;
        }

        Opportunity testOppty = [SELECT Id, Name, Count_of_Created_Staffing_Created__c
                                    FROM Opportunity
                                    WHERE Name = 'Test Oppty 1' LIMIT 1];


        System.assertEquals(originalStaffingAssignmentCount - 1, testOppty.Count_of_Created_Staffing_Created__c, 'The count of Staffing Assignments on the Opportunity after Staffing Assignment deletion was inproperly calculated');

                                
        
    }
}