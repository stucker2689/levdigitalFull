@isTest
public with sharing class InternalProjectTeamMemberTrigger_Test {
    
    @TestSetup
    static void makeData(){
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
        testOppty1.Peoplesoft_Project_Id__c = '12345678';
        testOppty1.StageName = 'Closed Won';
        insert testOppty1;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Email = 'testEmployeeEmail@gmail.com';
        testEmployee1.Cognizant_Employee_Id__c = '11111111';

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.FirstName = 'Test Employee';
        testEmployee2.LastName = 'Number Two';
        testEmployee2.Email = 'testEmployeeEmail2@gmail.com';
        testEmployee2.Cognizant_Employee_Id__c = '22222222';

        Contact testEmployee3 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee3.FirstName = 'Test Employee';
        testEmployee3.LastName = 'Number Three';
        testEmployee3.Email = 'testEmployeeEmail3@gmail.com';
        testEmployee3.Cognizant_Employee_Id__c = '33333333';

        Contact placeholderEmployee = TestDataFactory.createEmployee(false, levAcct.Id);
        placeholderEmployee.FirstName = 'Place';
        placeholderEmployee.LastName = 'Holder';
        placeholderEmployee.Email = 'placeholder@gmail.com';
        placeholderEmployee.Cognizant_Employee_Id__c = '44444444';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1, testEmployee2, testEmployee3, placeholderEmployee};
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

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{developerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem, projectManagerOppty1OpportunityLineItem, coreTechnicalArchitectOppty1OpportunityLineItem, projectManagerOppty2OpportunityLineItem};
        insert testOpportunityLineItemList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        /*testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.CSP_Email__c = 'testemail@gmail.com';
        testOppty1.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        update testOppty1;*/
    }

    @isTest
    static void updateTeamMemberWithTempRate_Test(){

        Test.startTest();
        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        /*Opportunity oppty = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Oppty 1' LIMIT 1];
        oppty.StageName = 'Closed Won';
        update oppty;*/
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];

        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        newEntry.Cognizant_Employee_Id__c = '11111111';
        newEntry.Peoplesoft_Project_Id__c = '12345678';
        newEntry.Billing_Action__c = 'B';
        newEntry.EntryDate__c = Date.today();
        newEntry.ActivityName__c = 'Business Support';
        newEntry.TotalHrs__c = 8;
        insert newEntry;

        Project_Team_Member_Billing_Rate__c tempBillRate = [SELECT Id, Name, Hourly_Rate__c FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'Temporary Rate' LIMIT 1];

        RepliconForecast__c firstWeekOfAugustForecast = TestDataFactory.createForecast(false, '7/31/2022 - 8/6/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 6), tempBillRate.Id); //Also includes last week of July 7/31/2022 - 8/6/2022
        firstWeekOfAugustForecast.EstimatedHours__c = 1;
        RepliconForecast__c secondWeekOfJuneForecast = TestDataFactory.createForecast(false, '8/7/2022 - 8/13/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 8, 13), tempBillRate.Id); //Week of August 8/7/2022 - 8/13/2022
        secondWeekOfJuneForecast.EstimatedHours__c = 2;
        RepliconForecast__c lastWeekOfAugustForecast = TestDataFactory.createForecast(false, '8/28/2022 - 9/3/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 3), null); //Also includes first week of September 8/28/2022 - 9/3/2022
        lastWeekOfAugustForecast.EstimatedHours__c = 3;
        RepliconForecast__c secondWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/4/2022 - 9/10/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 9, 10), null); //Week of September 9/4/2022 - 9/10/2022
        secondWeekOfSeptemberForecast.EstimatedHours__c = 4;
        RepliconForecast__c lastWeekOfSeptemberForecast = TestDataFactory.createForecast(false, '9/25/2022 - 10/1/2022 Forecast', testProj.Id, testEmployee.Id, Date.newInstance(2022, 10, 1), null); //Also includes first week of August 9/25/2022 - 10/1/2022
        lastWeekOfSeptemberForecast.EstimatedHours__c = 5;

        List<RepliconForecast__c> testRepliconForecastsToInsert = new List<RepliconForecast__c>{firstWeekOfAugustForecast, secondWeekOfJuneForecast, lastWeekOfAugustForecast, secondWeekOfSeptemberForecast, lastWeekOfSeptemberForecast};
        insert testRepliconForecastsToInsert;

        Client_Contact__c teamMember = [SELECT Id, Client_Contact__c, Project__c, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c
                                        FROM Client_Contact__c
                                        WHERE Project__c =: testProj.Id AND Client_Contact__c =: testEmployee.Id];

        //Project_Team_Member_Billing_Rate__c billRate = [SELECT Id, Name, Hourly_Rate__c FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'CORE - Techincal Architect' LIMIT 1];
        Project_Team_Member_Billing_Rate__c billRate = new Project_Team_Member_Billing_Rate__c(Name = 'Testing Bill Rate', Hourly_Rate__c = 214, Project__c = testProj.Id);
        insert billRate;

        teamMember.Assigned_Billing_Rate__c = billRate.Id;
        update teamMember;
        Test.stopTest();
    }

    @isTest
    static void linkBillRateToTeamMember_Test(){

        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];

        Client_Contact__c newTeamMember = new Client_Contact__c(Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'CORE - Techincal Architect');
        Test.startTest();
        insert newTeamMember;
        Test.stopTest();

        Client_Contact__c assertTeamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: testEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

        System.assertEquals('CORE - Techincal Architect', assertTeamMember.Assigned_Billing_Rate__r.Name, 'Assigned Billing Rate was not properly assigned on Team Member creation.');
    }

    @isTest
    static void updateTeamMemberContactRoleOnUpdate_Test(){

        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Project_Team_Member_Billing_Rate__c mcSolutionArchitectRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect'];


        Client_Contact__c newTeamMember = new Client_Contact__c(Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Contact_Role__c = 'CORE - Techincal Architect');
        insert newTeamMember;

        newTeamMember.Assigned_Billing_Rate__c = mcSolutionArchitectRate.Id;
        Test.startTest();
        update newTeamMember;
        Test.stopTest();

        Client_Contact__c assertTeamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Contact_Role__c
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: testEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

                                            

        System.assertEquals('MC - Solution Architect', assertTeamMember.Contact_Role__c, 'Project Team Member Contact Role was not properly updated when Assigned Billing Rate was changed.');
    }

    @isTest
    static void updateTeamMemberContactRoleOnInsert_Test(){

        Contact testEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Test Employee Number One' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Project_Team_Member_Billing_Rate__c mcSolutionArchitectRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect'];


        Client_Contact__c newTeamMember = new Client_Contact__c(Client_Contact__c = testEmployee.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = mcSolutionArchitectRate.Id);

        Test.startTest();
        insert newTeamMember;
        Test.stopTest();

        Client_Contact__c assertTeamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Contact_Role__c
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: testEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

                                            

        System.assertEquals('MC - Solution Architect', assertTeamMember.Contact_Role__c, 'Project Team Member Contact Role was not properly populated when Assigned Billing Rate populated on Insert.');
    }

    @isTest
    static void markPlaceholderOnProjTeamMemberOnInsert_Test(){
        Contact placeholderEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Project_Team_Member_Billing_Rate__c mcSolutionArchitectRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Client_Contact__c placeholderMember = new Client_Contact__c(Internal_Project_Team_Member_Name__c = 'Place Holder - Test Oppty 1', Client_Contact__c = placeholderEmployee.Id, Project__c = testProj.Id, 
                                                                        Assigned_Billing_Rate__c = mcSolutionArchitectRate.Id, Is_Placeholder_Team_Member__c = false);

        Test.startTest();
        insert placeholderMember;
        Test.stopTest();

        Client_Contact__c assertTeamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Contact_Role__c, Is_Placeholder_Team_Member__c
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: placeholderEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

        System.assertEquals(true, assertTeamMember.Is_Placeholder_Team_Member__c, 'Placeholder checkbox was not properly checked as true when Placeholder was created.');
    }

    @isTest
    static void markPlaceholderOnProjTeamMemberOnUpdate_Test(){
        Contact placeholderEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Project_Team_Member_Billing_Rate__c mcSolutionArchitectRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];

        Client_Contact__c placeholderMember = new Client_Contact__c(Client_Contact__c = placeholderEmployee.Id, Project__c = testProj.Id, 
                                                                        Assigned_Billing_Rate__c = mcSolutionArchitectRate.Id, Is_Placeholder_Team_Member__c = false);
        insert placeholderMember;

        Client_Contact__c assertTeamMemberBefore = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Contact_Role__c, Is_Placeholder_Team_Member__c
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: placeholderEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

        System.assertEquals(false, assertTeamMemberBefore.Is_Placeholder_Team_Member__c, 'Placeholder checkbox was inproperly checked as true when Placeholder was created without a proper Internal Project Team Member Name.');

        Test.startTest();
        placeholderMember.Internal_Project_Team_Member_Name__c = 'Place Holder - Test Oppty 1';
        update placeholderMember;
        Test.stopTest();

        Client_Contact__c assertTeamMemberAfter = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Contact_Role__c, Is_Placeholder_Team_Member__c
                                                FROM Client_Contact__c
                                                WHERE Client_ConTact__c =: placeholderEmployee.Id AND Project__c =: testProj.Id LIMIT 1];

        System.assertEquals(true, assertTeamMemberAfter.Is_Placeholder_Team_Member__c, 'Placeholder checkbox was not properly checked as true when Placeholder was updated to have proper Internal Project Team Member Name.');
    }

    /*@isTest
    static void updatePlaceholderBillRate_Test(){
        Contact placeholderEmployee = [SELECT Id, Name, Cognizant_Employee_Id__c FROM Contact WHERE Name = 'Place Holder' LIMIT 1];
        Project__c testProj = [SELECT Id, Name, RepliconURI__c, CreatedDate FROM Project__c WHERE Name = 'Test Oppty 1' LIMIT 1];
        Project_Team_Member_Billing_Rate__c mcSolutionArchitectRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'MC - Solution Architect' LIMIT 1];
        Project_Team_Member_Billing_Rate__c projectManagerRate = [SELECT Id, Name FROM Project_Team_Member_Billing_Rate__c WHERE Name = 'Project Manager' LIMIT 1];

        Client_Contact__c placeholderMember = new Client_Contact__c(Internal_Project_Team_Member_Name__c = 'Place Holder - Test Oppty 1', Client_Contact__c = placeholderEmployee.Id, Project__c = testProj.Id, Assigned_Billing_Rate__c = mcSolutionArchitectRate.Id, Is_Placeholder_Team_Member__c = true);
        insert placeholderMember;

        RepliconForecast__c newForecast = new RepliconForecast__c(Contact__c = placeholderEmployee.Id, Project__c = testProj.Id, Week_Start_Date__c = Date.today().toStartOfWeek(), Week_End_Date__c = Date.today().toStartOfWeek().addDays(6), EstimatedHours__c = 8, 
                                                                    Internal_Project_Team_Member__c = placeholderMember.Id, ProjectTeamMemberBillingRate__c = placeholderMember.Assigned_Billing_Rate__c);
        insert newForecast;

        Test.startTest();
        placeholderMember.Assigned_Billing_Rate__c = projectManagerRate.Id;
        update placeholderMember;
        Test.stopTest();

        List<RepliconForecast__c> relatedForecasts = [SELECT Id, Name, ProjectTeamMemberBillingRate__c FROM RepliconForecast__c WHERE Contact__c =: placeholderEmployee.Id];

        for(RepliconForecast__c forecast : relatedForecasts){

            System.assertEquals(projectManagerRate.Id, forecast.ProjectTeamMemberBillingRate__c, 'The related Placeholder forecasts were not properly updated to the new updated Billing Rate');
        }


    }*/

}