@isTest
public class TestDataFactory {
    // Account
    public static Account createAccount(Boolean isInsert, String recordTypeName) {
        Id recordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.PrimaryPractice__c = 'Salesforce';
        acct.RecordTypeId = recordTypeId;
        
        if (isInsert){ 
            insert acct;
        }
        return acct;
    }
    
    // Opportunity
    public static Opportunity createOpportunity(Boolean isInsert, Id acctId, String recordTypeName) {
        Id recordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp123';
        opp.StageName = '1. Engagement';
        opp.AccountId = acctId;
        opp.RecordTypeId = recordTypeId;
        opp.CloseDate = System.today().addDays(7);
        opp.Amount = 5500.00;
        opp.Start_Date__c = System.today().addDays(-7);
        opp.End_Date__c = System.today().addDays(7);
        opp.Do_Not_Create_Project__c = true;
        opp.Service__c = 'Program';
        opp.Program_Type__c = 'Campaign';
        opp.Interested_In__c = 'Salesforce';
        opp.Change_Order_Revenue__c = 1000;
        opp.Total_Amount_Invoiced_to_Date__c = 100;
        opp.Payment_Terms__c = 'Time and Materials';
        opp.Payment_Schedule__c = 'Standard T&M Monthly';
        opp.Project_Terms__c = 'Time and Materials';
        opp.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        opp.SOW_Hyperlink__c = 'google.com';
        opp.Next_Steps__c = 'Take the next steps on the opportunity';
        opp.Signatures_Completed__c = true;
        opp.Opportunity_Accuracy_Validated__c = true;
        //opp.Team_Retirement__c = 'Allyson Reagan';
        opp.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        opp.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        opp.RFP_Proposal__c = 'Yes';
        opp.DeliveryMethodology__c = 'Agile';
        opp.Number_of_Products__c = 1;
        opp.Number_of_Contact_Rolls_Added__c = 1;
        opp.Forecast_Status__c = 'Most Likely';
        opp.Onboarding_Requirements__c = 'Onboarding Requirements here!';
        opp.SOW_Signed__c = 'Yes';

        if (isInsert){
             insert opp;
        }
        return opp;
    }

    // Opportunity Line Item
    public static OpportunityLineItem createOpportunityLineItem(Boolean isInsert, Id oppId, Id pbeId) {
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = oppId;
        oli.PricebookEntryId = pbeId;
        oli.Quantity = 1;
        oli.TotalPrice = 100;

        if (isInsert) insert oli;
        return oli;
    }

    // Pricebook Entry
    public static PricebookEntry createPricebookEntry(Boolean isInsert, Id prodId) {
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = prodId;
        pbe.UnitPrice = 100;
        pbe.UseStandardPrice = false;
        pbe.IsActive = true;

        if (isInsert) insert pbe;
        return pbe;
    }

    // Product 
    public static Product2 createProduct(Boolean isInsert) {
        Product2 prod = new Product2();
        prod.Name = 'Test Product';

        if (isInsert) insert prod;
        return prod;
    }

    //Create Employee record to relate to Skills
    //@Param: NumContacts = Number of Contacts to create
    //@Param: isInsert when true insert the Opportunities
    public static List<Contact> createEmployee(Integer numContacts, Boolean isInsert) {
        List<Contact> employees = new List<Contact>();
        Id recordId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Id acctRcdId = Schema.SObjectType.Account.getRecordTypeinfosByName().get('Client').getRecordTypeId();
        Account a = new Account();
        a.Name = 'Levementum LLC';
        a.RecordTypeId = acctRcdId;
        a.PrimaryPractice__c = 'SFDC-Core';
        a.Salesforce_Business_Unit__c = 'Enterprise';
        a.LevementumVertical__c = 'Other';
        a.Lead_Source_Category__c = 'Levementum';
        a.Lead_Source__c = 'Employee';
        insert a;
        
        for(Integer i = 0; i < numContacts; i++){
            Contact cont = new Contact();
            cont.FirstName = 'Test';
            cont.LastName = 'Lev' + i;
            cont.RecordTypeId = recordId;
            cont.AccountId = a.Id;
            cont.Division__c = 'Projects - CORE';
            cont.Department = 'Operations';
            cont.Active__c = true;
            employees.add(cont);
        }

        if(isInsert) {
            insert employees;
        }
        
        return employees;
    }

    //Create Employee record to relate to Skills
    //@Param: NumContacts = Number of Contacts to create
    //@Param: isInsert when true insert the Opportunities
    public static List<Contact> createEmployeesBulk(Integer numContacts, Boolean isInsert) {
        List<Contact> employees = new List<Contact>();
        Id recordId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Id acctRcdId = Schema.SObjectType.Account.getRecordTypeinfosByName().get('Client').getRecordTypeId();
        Account a = new Account();
        a.Name = 'Levementum LLC';
        a.RecordTypeId = acctRcdId;
        a.PrimaryPractice__c = 'SFDC-Core';
        a.Salesforce_Business_Unit__c = 'Enterprise';
        a.LevementumVertical__c = 'Other';
        a.Lead_Source_Category__c = 'Levementum';
        a.Lead_Source__c = 'Employee';
        insert a;
        
        for(Integer i = 0; i < numContacts; i++){
            Contact cont = new Contact();
            cont.FirstName = 'Test';
            cont.LastName = 'Lev' + i;
            cont.RecordTypeId = recordId;
            cont.AccountId = a.Id;
            cont.Division__c = 'Projects - CORE';
            cont.Department = 'Operations';
            cont.Active__c = true;
            employees.add(cont);
        }

        if(isInsert) {
            insert employees;
        }
        
        return employees;
    }

    //Create Employee record
    public static Contact createEmployee(Boolean isInsert, Id accountId) {
        Id employeeRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();        
        Contact employee = new Contact();
        employee.FirstName = 'Test';
        employee.LastName = 'Lev Employee';
        employee.RecordTypeId = employeeRT;
        employee.AccountId = accountId;
        employee.Department = 'Operations';
        employee.Active__c = true;
        employee.Replicon_User_Number__c = 9999;
        employee.Cognizant_Employee_Id__c = '123456';

        if(isInsert) {
            insert employee;
        }
        
        return employee;
    }
    
    //Create Skill record
    //@Param: NumSkills = Number of Skills to create
    //@Param: isInsert when true insert the Skills
    public static List<Skill__c> createSkills(Integer numSkills, Boolean isInsert) {
        List<Skill__c> skills = new List<Skill__c>();
        
        //Create new Product Area for skills
        Skill_Product_Area__c prod = new Skill_Product_Area__c ();
        prod.Category__c = 'Core';
        prod.Name = 'New Area';
        insert prod;
        
        for(Integer i = 0; i < numSkills; i++){
            Skill__c sk = new Skill__c();
            sk.Active__c = true;
            sk.Description__c = 'test skill inserts';
            sk.Name = 'Test Skill ' + i;
            sk.Product_Area__c = prod.Id;
            skills.add(sk);
        }
        
        if(isInsert) {
            insert skills;
        }
        
        return skills;
    }
        
    //Create Skill Rating record
    //@Param: Employees for each employee create a skill rating for
    //@Param: isInsert when true insert the Skill ratings
    public static List<Skill_Rating__c> createRatings(List<Contact> employees, Boolean isInsert) {
        List<Skill_Rating__c> ratings = new List<Skill_Rating__c>();
        
        //Create new Product Area for skills
        
        //Create new Product Area for skills
        Skill_Product_Area__c prod = new Skill_Product_Area__c ();
        prod.Category__c = 'Core';
        prod.Name = 'New Area';
        insert prod;
        
        Skill__c skill = new Skill__c();
        skill.Active__c = true;
        skill.Description__c = 'test skill inserts';
        skill.Name = 'Test Skill';
        skill.Product_Area__c = prod.Id;
        insert skill;
        
         for(Contact c : employees) {
            Skill_Rating__c sk = new Skill_Rating__c();
			sk.Resource__c = c.Id;
            sk.Rating__c = '1';
            sk.Skill__c = skill.Id;
            ratings.add(sk);
        }
        
        if(isInsert) {
            insert ratings;
        }
        
        return ratings;
    }
     
    //Create Opportunity records
    //@Param: numOpp = Number of Opportunities to create
    //@Param: isInsert when true insert the Opportunities
    public static List<Opportunity> createOpportunity(Integer numOpp, Boolean isInsert) {
        List<Opportunity> opps = new List<Opportunity>();
        
        //Get the Salesforce opportunity Record Type Id
        Id sfOppRec = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
		Id sfActRec = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        
        //Create Account to relate the Opportunity to
        Account a = new Account();
        a.Name = 'Test Account';
        a.Industry = 'Education';
        a.SFVertical__c = 'Retail';
        a.Size__c = 'Enterprise';
        a.PrimaryPractice__c = 'SFDC-Core';
        a.Salesforce_Business_Unit__c = 'Enterprise';
        a.Lead_Source_Category__c = 'Levementum';
        a.Lead_Source__c = 'Other';
        a.RecordTypeId = sfActRec;
        insert a;
                
        //Loop through number of Opportunities provided and add to the list
        for(Integer i = 0; i < numOpp; i++) {
            Opportunity o = new Opportunity();
            o.AccountId = a.Id;
            o.Name = 'Opportunity Test' + i;
            o.StageName = 'Identifying an Opportunity';
            o.RecordTypeId = sfOppRec;
            o.Interested_In__c = 'Salesforce';
            o.SubPractice__c = 'Salesforce Core';
            o.Service__c = 'Project';
            o.CloseDate = Date.today() + 30;
            o.LeadSource = 'Lev';
            o.Lead_Source__c = 'AppExchange';
            o.ExpectedPro_DurationinWeeks__c = 3.0;
            o.Salesforce_Lead_Credit__c = 'Joint';
            opps.add(o);
        }
        
        //If True, insert the opportunities before returning it
        if(isInsert) {
            insert opps;
        }
        
        //Return the Opportunities
        return opps;
    }

    //Create Project
    public static Project__c createProject(Boolean isInsert, Id accountId, Id opportunityId) {
        Project__c project = new Project__c();
        project.Account__c = accountId;
        project.RepliconUri__c = 'urn:replicon-tenant:levementum:project:' + String.valueOf(Integer.valueof((Math.random() * 100000)));
        project.Opportunity__c = opportunityId;

        if (isInsert) {
            insert project;
        }
        return project;
    }

    //Retrieve Project from Opportunity
    public static Project__c getSingleProjectforOpp(Id opportunityId){
		  Project__c project = new Project__c();
          project = [SELECT Id,Name, Account__c, Opportunity__c, Project_Status__c, Total_Amount_Invoiced_to_Date__c, RepliconURI__c
                    FROM Project__c 
                    WHERE Opportunity__c =: opportunityId LIMIT 1];
          return project;
	}

    public static RepliconForecast__c createForecast(Boolean isInsert, String forecastName, Id projectId, Id contactId, Date weekEndDate, Id billingRateId) {
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Name = forecastName;
        forecast.Project__c = projectId;
        forecast.Week_End_Date__c = weekEndDate;
        forecast.Week_Start_Date__c = weekEndDate.toStartOfWeek();
        forecast.Contact__c = contactId;
        forecast.ProjectTeamMemberBillingRate__c = billingRateId;

        if (isInsert) {
            insert forecast;
        }
        return forecast;
    }

    public static List<RepliconForecast__c> createMultipleForecasts(Boolean isInsert, Integer numberOfForecasts, Id ProjectId, Id employeeId, Date WeekEndDate, Boolean markAsDeleted){
        
        Date weekEndDateToUse;
        if(WeekEndDate != null){
            weekEndDateToUse = WeekEndDate;
        }else{
            weekEndDateToUse = Date.today().toStartOfWeek().addDays(6);
        }

        List<RepliconForecast__c> forecastsToCreateList = new List<RepliconForecast__c>();
        for(Integer i = 0; i < numberOfForecasts; i++) {
            RepliconForecast__c forecast = new RepliconForecast__c();
            forecast.Name = 'Test Forecast # ' + i;
            forecast.Deleted_in_Replicon__c = true;
            if(WeekEndDate != null){
                forecast.Week_End_Date__c = weekEndDateToUse;
            }else{
                forecast.Week_End_Date__c = weekEndDateToUse.addDays(7 * i);
            }
            forecast.Project__c = ProjectId;
            forecast.Contact__c = employeeId;
            forecast.Deleted_in_Replicon__c = markAsDeleted;
            forecastsToCreateList.add(forecast);
        }

        if (isInsert && forecastsToCreateList.size() > 0) {
            insert forecastsToCreateList;
        }
        return forecastsToCreateList;

    }

    public static Replicon_Time_Entry__c createTimeEntry(Boolean isInsert, Id timesheetId, Id employeeId, Project__c project) {
        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c();
        timeEntry.Replicon_Timesheet__c = timesheetId;
        timeEntry.Employee__c = employeeId;
        if(project != null){
            timeEntry.Project__c = project.Id;
            timeEntry.Replicon_Project_URI__c = project.RepliconUri__c;
        }

        if (isInsert) {
            insert timeEntry;
        }
        return timeEntry;
    }

    public static Replicon_Timesheet__c createTimesheet(Boolean isInsert, Id employeeId) {
        Replicon_Timesheet__c timesheet = new Replicon_Timesheet__c();
        timesheet.Employee__c = employeeId;
        timesheet.Start_Date__c = System.today().toStartOfWeek();

        if (isInsert) {
            insert timesheet;
        }
        return timesheet;
    }

    public static Project_Team_Member__c createRepliconProjectTeamMember(Boolean isInsert, Id employeeId, Id projectId){
        Project_Team_Member__c projTeamMember = new Project_Team_Member__c();
        projTeamMember.Name = 'Test Replicon Team Member';
        projTeamMember.Employee__c = employeeId;
        projTeamMember.Project__c = projectId;

        if (isInsert) {
            insert projTeamMember;
        }
        return projTeamMember;
    }

    public static Project_Team_Member_Billing_Rate__c createRepliconBillingRate(Boolean isInsert, Id projTeamMemberId, Id projectId){
        Project_Team_Member_Billing_Rate__c testBillRate = new Project_Team_Member_Billing_Rate__c();
        testBillRate.Name = 'Test Billing Rate Rate';
        testBillRate.Hourly_Rate__c = 200;
        testBillRate.Project__c = projectId;
        testBillRate.Project_Team_Member__c = projTeamMemberId;
        testBillRate.Replicon_URI__c = 'urn:replicon-tenant:levementum:company-billing-rate:abc123';

        if (isInsert) {
            insert testBillRate;
        }
        return testBillRate;
    }

    public static Milestone__c createMilestone(Boolean isInsert, Id projId){ 
        
        Milestone__c ms = new Milestone__c();
        ms.Name = 'Test Milestone';
        ms.Project__c = projId;

        if(isInsert){
            insert ms;
        }
        return ms;

    }

    public static Work__c createWork(Boolean isInsert, Id milestoneId, String workName){

        Work__c work = new Work__c();
        work.Name = workName;
        work.dat_DueDate__c = date.today();
        work.pkl_Status__c = 'Ready';
        work.Milestone__c = milestoneId;

        if(isInsert){
            insert work;
        }
        return work;
    }

    public static void createRepliconDropdownRecords(){
        
        EnableReplicon__c en = new EnableReplicon__c();
        en.IsActiveProject__c = true;
        en.Name ='test';
        insert  en;

        RepliconDropdowns__c rd1 = new RepliconDropdowns__c();
        rd1.Name = 'Pr-Payment-Terms-Invoice-Net-45';
        rd1.Group__c='Project-Payment-Terms';
        rd1.Value__c='Invoice Net 45';
        rd1.uri__c='urn:replicon-tenant:levementum:custom-field-option:668351da-f86b-4168-bd6e-cd338d6fa9c4';

        RepliconDropdowns__c rd2 = new RepliconDropdowns__c();
        rd2.Name = 'Pr-Payment-Terms-Invoice-Net-30';
        rd2.Group__c='Project-Payment-Terms';
        rd2.Value__c='Invoice Net 30';
        rd2.uri__c='urn:replicon-tenant:levementum:custom-field-option:668351da-f86b-4168-bd6e-cd338d6fa9c4';

        RepliconDropdowns__c rd3 = new RepliconDropdowns__c();
        rd3.Name = 'Pr-Payment-Terms-Url';
        rd3.Group__c='Project-Payment-Terms';
        rd3.Value__c='Url';
        rd3.uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f95';

        RepliconDropdowns__c rd4 = new RepliconDropdowns__c();
        rd4.Name = 'Pr-Terms-Time-and-Materials';
        rd4.Group__c='Project-Terms';
        rd4.Value__c='Time & Materials';
        rd4.uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661';

        RepliconDropdowns__c rd5 = new RepliconDropdowns__c();
        rd5.Name = 'Pr-Terms-Url';
        rd5.Group__c='Project-Terms';
        rd5.Value__c='URL';
        rd5.uri__c='urn:replicon-tenant:levementum:custom-field-option:5181f179-35e1-4266-9409-a3545ed1f661';

        RepliconDropdowns__c rd6 = new RepliconDropdowns__c();
        rd6.Name = 'Pr-Terms-Fixed-Price';
        rd6.Group__c='Project-Terms';
        rd6.Value__c='URL';
        rd6.uri__c='test';

        RepliconDropdowns__c rd7 = new RepliconDropdowns__c();
        rd7.Name = 'BillingType-Time-and-Materials';
        rd7.Group__c='Project-BillingType';
        rd7.Value__c='Time and Materials';
        rd7.uri__c='urn:replicon:billing-type:time-and-material';

        RepliconDropdowns__c rd8 = new RepliconDropdowns__c();
        rd8.Name = 'Pr-Project-Practice-URL';
        rd8.Group__c='Project-Practice';
        rd8.Value__c='URL';
        rd8.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';

        RepliconDropdowns__c rd9 = new RepliconDropdowns__c();
        rd9.Name = 'Pr-Practice-Salesforce';
        rd9.Group__c='Project-Practice';
        rd9.Value__c='SUgarCRM';
        rd9.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';

        RepliconDropdowns__c rd10 = new RepliconDropdowns__c();
        rd10.Name = 'Pr-Practice-Salesforce-Core';
        rd10.Group__c='Project-Practice';
        rd10.Value__c='Salesforce';
        rd10.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';

        RepliconDropdowns__c rd11 = new RepliconDropdowns__c();
        rd11.Name = 'Pr-Practice-SFDC-Core';
        rd11.Group__c='Project-Practice';
        rd11.Value__c='SFDC-Core';
        rd11.uri__c='urn:replicon-tenant:levementum:custom-field-option:545e64ed-53ed-4bb2-8f31-9445d3c957c3';

        RepliconDropdowns__c rd12 = new RepliconDropdowns__c();
        rd12.Name = 'Pr-Type-URL';
        rd12.Group__c='Project-Type';
        rd12.Value__c='Type';
        rd12.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';

        RepliconDropdowns__c rd13 = new RepliconDropdowns__c();
        rd13.Name = 'Pr-Type-Project';
        rd13.Group__c='test';
        rd13.Value__c='Other';
        rd13.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';

        RepliconDropdowns__c rd14 = new RepliconDropdowns__c();
        rd14.Name = 'Pr-Expense-Entry-Type-Fixed-Price';
        rd14.Group__c='test';
        rd14.Value__c='Other';
        rd14.uri__c='urn:replicon-tenant:levementum:user-defined-field:972768a6-8549-40dd-a5e6-1c0293f21e14';

        RepliconDropdowns__c rd15 = new RepliconDropdowns__c();
        rd15.Name = 'Pr-Inv-Schedule-Url';
        rd15.Group__c='test';
        rd15.Value__c='Other';
        rd15.uri__c='test';

        RepliconDropdowns__c rd16 = new RepliconDropdowns__c();
        rd16.Name = 'Pr-InvTerms-Standard-TM';
        rd16.Group__c='test';
        rd16.Value__c='Other';
        rd16.uri__c='test';

        RepliconDropdowns__c rd17 = new RepliconDropdowns__c();
        rd17.Name = 'BillingType-Fixed-Price';
        rd17.Group__c='test';
        rd17.Value__c='Other';
        rd17.uri__c='test';

        RepliconDropdowns__c rd18 = new RepliconDropdowns__c();
        rd18.Name = 'BillingType-Non-Billable';
        rd18.Group__c='test';
        rd18.Value__c='Other';
        rd18.uri__c='test';

        RepliconDropdowns__c rd19 = new RepliconDropdowns__c();
        rd19.Name = 'Ts-Payment-Terms-Url';
        rd19.Group__c='Url';
        rd19.Value__c='Other';
        rd19.uri__c='urn:replicon-tenant:levementum:user-defined-field:175ee668-c120-426d-810a-57321a3dba23';

        RepliconDropdowns__c rd20 = new RepliconDropdowns__c();
        rd20.Name = 'Pr-Payment-Terms-Time-and-Materials';
        rd20.Group__c='Project-Payment-Terms';
        rd20.Value__c='Url';
        rd20.uri__c='urn:replicon-tenant:levementum:custom-field-option:adc04f51-71e9-4f74-bcdd-4b69577f2f11';

        RepliconDropdowns__c rd21 = new RepliconDropdowns__c();
        rd21.Name = 'Pr-Practice-Other';
        rd21.Group__c='Project-Practice';
        rd21.Value__c='Other';
        rd21.uri__c='urn:replicon-tenant:levementum:custom-field-option:2f956643-81b3-44aa-9309-9bba4bd2a9ad';

        RepliconDropdowns__c rd22 = new RepliconDropdowns__c();
        rd22.Name = 'Pr-InvTerms-Standard-T&M-Monthly';
        rd22.Group__c = 'Pr-Inv-Schedule';
        rd22.Value__c = 'Standard T&M Monthly';
        rd22.uri__c = 'urn:replicon-tenant:levementum:custom-field-option:2fcd941c-c1f1-4665-af64-d613ecf0ebe0';

        List<RepliconDropdowns__c> repliconDropdownInsertList = new List<RepliconDropdowns__c>{rd1, rd2, rd3, rd4, rd5, rd6, rd7, rd8, rd9, rd10, rd11, rd12, rd13, rd14, rd15, rd16, rd17, rd18, rd19, rd20, rd21, rd22};
        insert repliconDropdownInsertList;
    }
}