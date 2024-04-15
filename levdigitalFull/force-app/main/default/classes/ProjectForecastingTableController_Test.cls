@isTest(seeAllData = true)
public with sharing class ProjectForecastingTableController_Test {
    
    //@TestSetup
    static void makeData(){
        //Create Account

        //Create Opportunity

        //Create Products and OpportunityLineItems

        //Click Expedited Staffing

        //

        //Create Accounts
        /*Account levAcct = TestDataFactory.createAccount(false, 'Partner');
        levAcct.Name = 'Levementum LLC';

        Account acct = TestDataFactory.createAccount(false, 'Client');
        acct.Name = 'Test Client Account';
        
        List<Account> setupAccountInsertList = new List<Account>{acct};
        insert setupAccountInsertList;

        //Create 2 Opportunities
        Opportunity testOppty1 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        //testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.Peoplesoft_Project_Id__c = '18181818';
        testOppty1.StageName = 'Identifying an Opportunity';
        testOppty1.Name = 'Test Oppty 1';
        testOppty1.Do_Not_Create_Project__c = false;


        Opportunity testOppty2 = TestDataFactory.createOpportunity(false, acct.Id, 'Salesforce');
        //testOppty1.StageName = 'Verbal Approval (Negotiation)';
        testOppty1.Peoplesoft_Project_Id__c = '77777777';
        testOppty2.StageName = 'Closed Won';
        testOppty2.Name = 'Test Oppty 2';
        testOppty2.Do_Not_Create_Project__c = false;
        
        List<Opportunity> opptyInsertList = new List<Opportunity>{testOppty1, testOppty2};
        insert opptyInsertList;

        //Create Test Contacts
        Contact testEmployee1 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee1.Cognizant_Employee_Id__c = '123';
        testEmployee1.FirstName = 'Test Employee';
        testEmployee1.LastName = 'Number One';
        testEmployee1.Email = 'testEmployeeEmail@gmail.com';

        Contact testEmployee2 = TestDataFactory.createEmployee(false, levAcct.Id);
        testEmployee2.Cognizant_Employee_Id__c = '321';
        testEmployee2.FirstName = 'Test Employee';
        testEmployee2.LastName = 'Number Two';
        testEmployee2.Email = 'testEmployee2@gmail.com';

        Contact placeholderEmployee = TestDataFactory.createEmployee(false, levAcct.Id);
        placeholderEmployee.FirstName = 'Place';
        placeholderEmployee.LastName = 'Holder';

        List<Contact> setupEmployeeInsertList = new List<Contact>{testEmployee1, testEmployee2, placeholderEmployee};
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

        testOppty1.Expedited_Staffing__c = true;
        update testOppty1;

        List<Staffing_Assignment__c>  staffAssignmentList = new List<Staffing_Assignment__c>();
        staffAssignmentList = [SELECT Id, Name, Status__c, Resource_Assigned__c FROM Staffing_Assignment__c WHERE Opportunity__c =: testOppty1.Id];

        List<Staffing_Assignment__c>  updateStaffAssignmentList = new List<Staffing_Assignment__c>();
        Integer iterationCounter = 0;
        for(Staffing_Assignment__c sa : staffAssignmentList){
            iterationCounter++; 

            switch on iterationCounter {
                when 1 {
                    sa.Resource_Assigned__c = testEmployee1.Id;
                }
                when 2 {
                    sa.Resource_Assigned__c = testEmployee2.Id;
                }
                when else {
                    sa.Resource_Assigned__c = testEmployee1.Id;
                }
            }

            sa.Assigned_Resource_Manager_email__c = 'testManagerEmail@gmail.com';
            sa.Status__c = 'Completed';
            updateStaffAssignmentList.add(sa);
        }

        update updateStaffAssignmentList;

        //Move Oppty 1 to Closed Won to have Projects and Internal Project Team Members created
        testOppty1.StageName = 'Won';
        //testOppty1.CSP_Email__c = 'testemail@gmail.com';
        //testOppty1.Managing_Director_SC_Email__c = 'testemail@gmail.com';
        update testOppty1;


        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billRateList = [SELECT Id, Name, Hourly_Rate__c FROM Project_Team_Member_Billing_Rate__c ];

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Opportunity__c =: testOppty1.Id];
        Project__c testProj2 = [SELECT Id, Name FROM Project__c WHERE Opportunity__c =: testOppty2.Id];

        Date currentWeekStartDate = Date.today().toStartOfWeek();
        RepliconForecast__c pastDevForecast = new RepliconForecast__c(Name = 'Past Dev Forecast', Contact__c = testEmployee1.Id, Week_Start_Date__c = currentWeekStartDate.addDays(14), Week_End_Date__c = currentWeekStartDate.addDays(120), ProjectTeamMemberBillingRate__c = billRateList[0].Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c pastPMForecast = new RepliconForecast__c(Name = 'Past PM Forecast', Contact__c = testEmployee1.Id, Week_Start_Date__c = currentWeekStartDate.addDays(21), Week_End_Date__c = currentWeekStartDate.addDays(27), ProjectTeamMemberBillingRate__c = billRateList[0].Id, EstimatedHours__c = 10, Project__c = testProj1.Id);
        RepliconForecast__c futureDevForecast = new RepliconForecast__c(Name = 'Future Dev Forecast', Contact__c = testEmployee1.Id, Week_Start_Date__c = currentWeekStartDate, Week_End_Date__c = currentWeekStartDate.addDays(6), ProjectTeamMemberBillingRate__c = billRateList[0].Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        RepliconForecast__c futurePMForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Contact__c = testEmployee1.Id, Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = billRateList[0].Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        RepliconForecast__c placeholderForecast = new RepliconForecast__c(Name = 'Future PM Forecast', Contact__c = placeholderEmployee.Id, Week_Start_Date__c = currentWeekStartDate.addDays(7), Week_End_Date__c = currentWeekStartDate.addDays(13), ProjectTeamMemberBillingRate__c = billRateList[0].Id, EstimatedHours__c = 10, Project__c = testProj2.Id);
        List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>{pastDevForecast, pastPMForecast, futureDevForecast, futurePMForecast, placeholderForecast};
        insert forecastInsertList;*/
    }

    @isTest
    static void getForecastTableData_Weekly_Test(){
        System.debug('HERE');

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];

        
        ProjectForecastingTableController.ForecastTableDataWrapper testWrapper = new ProjectForecastingTableController.ForecastTableDataWrapper();
        testWrapper = ProjectForecastingTableController.getForecastTableData(testProj1.id);
    }

    @isTest
    static void getForecastTableData_Monthly_Test(){
        System.debug('HERE');

        Project__c testProj1 = [SELECT Id, Name FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];

        
        ProjectForecastingTableController.ForecastTableDataWrapper testWrapper = new ProjectForecastingTableController.ForecastTableDataWrapper();
        testWrapper = ProjectForecastingTableController.getForecastTableData(testProj1.id, null, null, 'Monthly');
    }

    @isTest
    static void upsertForecastByDateRangeHoursPerWeek_Test(){

        /*Project__c testProj = [SELECT Id, Name, Account__c 
                                FROM Project__c 
                                WHERE Rollup_Billable__c > 0 AND Total_Remaining_Forecasted_Hours__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null AND Account__r.Name != 'Levementum LLC' 
                                LIMIT 1];*/

        Project__c testProj = [SELECT Id, Name, Account__c 
                                FROM Project__c 
                                WHERE Rollup_Billable__c > 0 AND  Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null AND Account__r.Name != 'Levementum LLC' 
                                LIMIT 1];

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastList = [SELECT Id, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Contact__r.AccountId, Project__c, Project__r.Peoplesoft_Project_Id__c, Project__r.Name, Week_Start_Date__c, EstimatedHours__c, 
                            ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name
                        FROM RepliconForecast__c
                        WHERE Project__c =: testProj.Id AND Internal_Project_Team_Member__c != null
                        ORDER BY Contact__c, Week_Start_Date__c];

        System.debug('Forecast List Size: ' + forecastList.size());

        Map<Id, Client_Contact__c> contactToProjTeamMemberMap = new Map<Id, Client_Contact__c>();
        for(RepliconForecast__c forecast : forecastList){
            
            
            if(!contactToProjTeamMemberMap.containsKey(forecast.Contact__c) && forecast.ProjectTeamMemberBillingRate__c != null){

                Client_Contact__c newTeamMember = new Client_Contact__c();
                newTeamMember.Client_Contact__c = forecast.Contact__c;
                newTeamMember.Project__c = testProj.Id;
                newTeamMember.Account__c = testProj.Account__c;
                newTeamMember.Assigned_Billing_Rate__c = forecast.ProjectTeamMemberBillingRate__c;

                contactToProjTeamMemberMap.put(forecast.Contact__c, newTeamMember);
            }
        }

        insert contactToProjTeamMemberMap.values();

        
        
        ProjectForecastingTableController.allocationCreationWrapper newAllocationCreationWrapper = new ProjectForecastingTableController.allocationCreationWrapper();
        newAllocationCreationWrapper.contactId = forecastList[0].Contact__c;
        newAllocationCreationWrapper.contactCognizantEmployeeId = forecastList[0].Contact__r.Cognizant_Employee_Id__c;
        newAllocationCreationWrapper.contactIsLevEmployeeBoolean = true;
        newAllocationCreationWrapper.isPlaceholderEmployee = false;
        newAllocationCreationWrapper.projectId = forecastList[0].Project__c;
        newAllocationCreationWrapper.projectName = forecastList[0].Project__r.Name;
        newAllocationCreationWrapper.projectPeoplesoftId = forecastList[0].Project__r.Peoplesoft_Project_Id__c;
        newAllocationCreationWrapper.projectTeamMemberId = contactToProjTeamMemberMap.get(forecastList[0].Contact__c).Id; //
        newAllocationCreationWrapper.projectTeamMemberAssignedBillingRateId = forecastList[0].ProjectTeamMemberBillingRate__c;
        newAllocationCreationWrapper.projectTeamMemberAssignedBillingRateName = forecastList[0].ProjectTeamMemberBillingRate__r.Name;
        newAllocationCreationWrapper.allocationRangeStartDate = forecastList[0].Week_Start_Date__c;
        newAllocationCreationWrapper.allocationRangeEndDate = forecastList[0].Week_Start_Date__c.addDays(20);
        newAllocationCreationWrapper.hoursForAllocation = 40;
        newAllocationCreationWrapper.allocationEntryMethod = 'hoursPerWeek';


        ProjectForecastingTableController.upsertForecastFromProjectForecastTable(newAllocationCreationWrapper);
    }

    @isTest
    static void upsertForecastByDateRangeTotalHours_Test(){

       /*Project__c testProj = [SELECT Id, Name, Account__c 
                                FROM Project__c 
                                WHERE Rollup_Billable__c > 0 AND Total_Remaining_Forecasted_Hours__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null 
                                LIMIT 1];*/

        Project__c testProj = [SELECT Id, Name, Account__c 
                                FROM Project__c 
                                WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null 
                                LIMIT 1];

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastList = [SELECT Id, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Contact__r.AccountId, Project__c, Project__r.Peoplesoft_Project_Id__c, Project__r.Name, Week_Start_Date__c, EstimatedHours__c, 
                            ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name
                        FROM RepliconForecast__c
                        WHERE Project__c =: testProj.Id AND Internal_Project_Team_Member__c != null
                        ORDER BY Contact__c, Week_Start_Date__c];

        Map<Id, Client_Contact__c> contactToProjTeamMemberMap = new Map<Id, Client_Contact__c>();
        for(RepliconForecast__c forecast : forecastList){
            
            
            if(!contactToProjTeamMemberMap.containsKey(forecast.Contact__c) && forecast.ProjectTeamMemberBillingRate__c != null){

                Client_Contact__c newTeamMember = new Client_Contact__c();
                newTeamMember.Client_Contact__c = forecast.Contact__c;
                newTeamMember.Project__c = testProj.Id;
                newTeamMember.Account__c = testProj.Account__c;
                newTeamMember.Assigned_Billing_Rate__c = forecast.ProjectTeamMemberBillingRate__c;

                contactToProjTeamMemberMap.put(forecast.Contact__c, newTeamMember);
            }
        }

        insert contactToProjTeamMemberMap.values();

        
        
        ProjectForecastingTableController.allocationCreationWrapper newAllocationCreationWrapper = new ProjectForecastingTableController.allocationCreationWrapper();
        newAllocationCreationWrapper.contactId = forecastList[0].Contact__c;
        newAllocationCreationWrapper.contactCognizantEmployeeId = forecastList[0].Contact__r.Cognizant_Employee_Id__c;
        newAllocationCreationWrapper.contactIsLevEmployeeBoolean = true;
        newAllocationCreationWrapper.isPlaceholderEmployee = false;
        newAllocationCreationWrapper.projectId = forecastList[0].Project__c;
        newAllocationCreationWrapper.projectName = forecastList[0].Project__r.Name;
        newAllocationCreationWrapper.projectPeoplesoftId = forecastList[0].Project__r.Peoplesoft_Project_Id__c;
        newAllocationCreationWrapper.projectTeamMemberId = contactToProjTeamMemberMap.get(forecastList[0].Contact__c).Id; //
        newAllocationCreationWrapper.projectTeamMemberAssignedBillingRateId = forecastList[0].ProjectTeamMemberBillingRate__c;
        newAllocationCreationWrapper.projectTeamMemberAssignedBillingRateName = forecastList[0].ProjectTeamMemberBillingRate__r.Name;
        newAllocationCreationWrapper.allocationRangeStartDate = forecastList[0].Week_Start_Date__c;
        newAllocationCreationWrapper.allocationRangeEndDate = forecastList[0].Week_Start_Date__c.addDays(6);
        newAllocationCreationWrapper.hoursForAllocation = 40;
        newAllocationCreationWrapper.allocationEntryMethod = 'totalHours';


        ProjectForecastingTableController.upsertForecastFromProjectForecastTable(newAllocationCreationWrapper);
    }

    @isTest
    static void getPlaceholderRoles_Test(){

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ProjectForecastingTableController.getPlaceholderRoles();

        System.assertNotEquals(0, placeholderProductRoleList.size(), 'Placeholder Roles were not properly retrieved via the LWC Controller method');
    }

    @isTest
    static void checkWorkDaysInRange_Test(){


        Date dateOne = Date.newInstance(2023, 6, 15); //Thursday
        Date dateTwo = Date.newInstance(2023, 6, 22); //Next Thursday
        Integer daysBetween = ProjectForecastingTableController.calculateWorkingDaysBetweenTwoDates(dateOne, dateTwo);
    }


    @isTest
    static void createPlaceholder_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact placeholderContact = [SELECT Id, Name FROM Contact WHERE Name = 'Place Holder'];

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ProjectForecastingTableController.getPlaceholderRoles();

        ProjectForecastingTableController.createPlaceholder(testProj.Id, testProj.Name, placeholderContact.Id, placeholderProductRoleList[0].Name, placeholderProductRoleList[0].Id);
    }

    @isTest
    static void replacePlaceholderWithUser_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact placeholderContact = [SELECT Id, Name FROM Contact WHERE Name = 'Place Holder' LIMIT 1];

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ProjectForecastingTableController.getPlaceholderRoles();

        Client_Contact__c placeholderTeamMember = new Client_Contact__c();

        placeholderTeamMember = ProjectForecastingTableController.createPlaceholder(testProj.Id, testProj.Name, placeholderContact.Id, placeholderProductRoleList[0].Name, placeholderProductRoleList[0].Id);
        insert placeholderTeamMember;

        Contact testContact = [SELECT Id, Name FROM Contact WHERE Name = 'Sam Tucker'];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c();
        newBillRate.Name = 'Developer';
        newBillRate.Hourly_Rate__c = 210;
        newBillRate.Project__c = testProj.Id;
        newBillRate.Created_in_Salesforce__c = true;
        insert newBillRate;

        ProjectForecastingTableController.replacePlaceholderWithUser(placeholderTeamMember.Id, testContact.Id, testProj.Peoplesoft_Project_Id__c, testProj.Id, testProj.Name, newBillRate.Id);
    }

    @isTest
    static void getAllocationForDateRange_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c, Start_Date__c, Planned_Close_Date__c
                                FROM Project__c 
                                WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null AND Start_Date__c != null AND Planned_Close_Date__c != null
                                LIMIT 1];

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastList = [SELECT Id, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Contact__r.AccountId, Project__c, Project__r.Peoplesoft_Project_Id__c, Project__r.Name, Week_Start_Date__c, EstimatedHours__c, 
                            ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Internal_Project_Team_Member__c
                        FROM RepliconForecast__c
                        WHERE Project__c =: testProj.Id AND Internal_Project_Team_Member__c != null
                        ORDER BY Contact__c, Week_Start_Date__c];

        ProjectForecastingTableController.getCurrentAllocationForDateRange(testProj.Start_Date__c, testProj.Planned_Close_Date__c, testProj.Id, forecastList[0].Contact__c, forecastList[0].Internal_Project_Team_Member__c);
    }

    
}