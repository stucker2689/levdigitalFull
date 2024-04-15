@isTest(seeAllData=true)
public with sharing class ContactForecastingTableController_Test {
    

    @isTest
    static void getForecastTableData_ActiveProjects_Test(){

        Contact testContact = [SELECT Id, Billed_Hours_this_Quarter__c
                                FROM Contact
                                WHERE Active__c = true AND Billed_Hours_this_Quarter__c > 40
                                LIMIT 1];

        Test.startTest();
        ContactForecastingTableController.getForecastTableData(testContact.Id, null, null, true);
        Test.stopTest();
    }

    @isTest
    static void getForecastTableData_AllProjects_Test(){

        Contact testContact = [SELECT Id, Billed_Hours_this_Quarter__c
                                FROM Contact
                                WHERE Active__c = true AND Billed_Hours_this_Quarter__c > 40
                                LIMIT 1];

        Test.startTest();
        ContactForecastingTableController.getForecastTableData(testContact.Id, null, null, false);
        Test.stopTest();
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

        
        
        ContactForecastingTableController.allocationCreationWrapper newAllocationCreationWrapper = new ContactForecastingTableController.allocationCreationWrapper();
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


        ContactForecastingTableController.upsertForecastFromProjectForecastTable(newAllocationCreationWrapper);
    }

    @isTest
    static void getPlaceholderRoles_Test(){

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ContactForecastingTableController.getPlaceholderRoles();

        System.assertNotEquals(0, placeholderProductRoleList.size(), 'Placeholder Roles were not properly retrieved via the LWC Controller method');
    }

    @isTest
    static void checkWorkDaysInRange_Test(){


        Date dateOne = Date.newInstance(2023, 6, 15); //Thursday
        Date dateTwo = Date.newInstance(2023, 6, 22); //Next Thursday
        Integer daysBetween = ContactForecastingTableController.calculateWorkingDaysBetweenTwoDates(dateOne, dateTwo);
    }


    @isTest
    static void createPlaceholder_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact placeholderContact = [SELECT Id, Name FROM Contact WHERE Name = 'Place Holder'];

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ContactForecastingTableController.getPlaceholderRoles();

        ContactForecastingTableController.createPlaceholder(testProj.Id, testProj.Name, placeholderContact.Id, placeholderProductRoleList[0].Name, placeholderProductRoleList[0].Id);
    }

    @isTest
    static void replacePlaceholderWithUser_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c, Peoplesoft_Project_Id__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact placeholderContact = [SELECT Id, Name FROM Contact WHERE Name = 'Place Holder' LIMIT 1];

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ContactForecastingTableController.getPlaceholderRoles();

        Client_Contact__c placeholderTeamMember = new Client_Contact__c();

        placeholderTeamMember = ContactForecastingTableController.createPlaceholder(testProj.Id, testProj.Name, placeholderContact.Id, placeholderProductRoleList[0].Name, placeholderProductRoleList[0].Id);
        insert placeholderTeamMember;

        Contact testContact = [SELECT Id, Name FROM Contact WHERE Name = 'Sam Tucker'];

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c();
        newBillRate.Name = 'Developer';
        newBillRate.Hourly_Rate__c = 210;
        newBillRate.Project__c = testProj.Id;
        newBillRate.Created_in_Salesforce__c = true;
        insert newBillRate;

        ContactForecastingTableController.replacePlaceholderWithUser(placeholderTeamMember.Id, testContact.Id, testProj.Peoplesoft_Project_Id__c, testProj.Id, testProj.Name, newBillRate.Id);
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

        ContactForecastingTableController.getCurrentAllocationForDateRange(testProj.Start_Date__c, testProj.Planned_Close_Date__c, testProj.Id, forecastList[0].Contact__c, forecastList[0].Internal_Project_Team_Member__c);
    }
}