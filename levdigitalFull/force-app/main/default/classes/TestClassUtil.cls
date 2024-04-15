/*
Created By: Naren Pillai
Date: 7/1/2015
Description: This is a Util class used in test classes.
*/

public with sharing class TestClassUtil {
	
	public static Account newSampleAccount(){
		Account acc = new Account();
    	acc.Name = 'testAccount';
    	acc.PrimaryPractice__c = 'Salesforce';
    	insert acc;
	  	return acc;

	}

    public static Contact createContact(Boolean isInsert, Id acctId) {
        Contact c = new Contact();
        c.AccountId = acctId;
        c.LastName = 'Testing';
        c.Replicon_User_Number__c = Integer.valueof((Math.random() * 100000));

        if (isInsert) {
            insert c;
        }
        return c;
    }

    public static RepliconForecast__c createForecast(Boolean isInsert, String forecastName, Id projectId) {
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Name = forecastName;
        forecast.Project__c = projectId;

        if (isInsert) {
            insert forecast;
        }
        return forecast;
    }

	public static Opportunity newSampleOpportunity(String AccId, String name)
	{
		Opportunity oppo = new Opportunity();
        oppo.Name = name;
        oppo.AccountId = AccId;
        oppo.StageName = 'Verbal Approval';
        oppo.CloseDate = date.today();
        oppo.Start_Date__c = system.today()+10;
        oppo.End_Date__c = system.today()+40;
        oppo.Amount = 55000.00;
        oppo.Service__c = 'Program';
        oppo.Project_Type__c = 'Salesforce.com';
        oppo.Program_Type__c = 'Strategic';
        oppo.Number_of_Contact_Rolls_Added__c = 2;
        oppo.Project_Terms__c = 'Time and Materials';
        oppo.LevementumVertical__c = 'Manufacturing';
        oppo.Payment_Schedule__c = 'Standard TM';
        oppo.Signatures_Completed__c = true;
        oppo.Opportunity_Accuracy_Validated__c = true;
        oppo.Interested_In__c = 'Salesforce';
        oppo.Lead_Source__c = 'Levementum';
        oppo.Project_Health__c = 'Green';
        oppo.Create_Project__c = FALSE;
        oppo.Payment_Terms__c = 'Invoice Net 30';
        oppo.ExpectedPro_DurationinWeeks__c = 3;
        oppo.Opp_Amount_Distribution__c = '70% / 30%';
        oppo.Team_Retirement__c = 'Allyson Reagan';
        oppo.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        oppo.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        oppo.RFP_Proposal__c = 'Yes';
        oppo.DeliveryMethodology__c = 'Agile';
        oppo.Number_of_Products__c = 1;
        oppo.Forecast_Status__c = 'Most Likely';
        insert oppo;
        return oppo;

	}

    public static Project__c createProject(Boolean isInsert, Id acctId, Id oppId) {
        Project__c project = new Project__c();
        project.Account__c = acctId;
        project.RepliconUri__c = 'urn:replicon-tenant:levementum:project:' + String.valueOf(Integer.valueof((Math.random() * 100000)));
        project.Opportunity__c = oppId;

        if (isInsert) {
            insert project;
        }
        return project;
    }

	public static Project__c getProjectforOpp(String OppId)
	{
		  Project__c proj = new Project__c();
       	  proj = [Select Id,Name, Account__c, Opportunity__c, Project_Status__c,Promised_Start_Date__c,Project_Background_Objectives__c,
        		    Key_Project_Success_Metrics__c,SR_Reporting_Period_From__c,SR_Reporting_Period_To__c, SR_Collection_Id__c,SR_Executive_Summary__c,
                    SR_Key_Accomplishments_This_Period__c,SR_Key_Decisions__c,SR_Plans_for_Next_Period__c,
                    SR_Overall_Health_Value__c,SR_Budget_Value__c,SR_Risk_Value__c,
                    SR_Schedule_Value__c,SR_Scope_Value__c,Latest_Status_Report_Date__c,Total_Hours_Invoiced_to_Date__c,
                    Total_Amount_Invoiced_to_Date__c
                    ,SR_Overall_Health_Comments__c,
                    SR_Budget_Comments__c,
                    SR_Risk_Comments__c,
                    SR_Schedule_Comments__c,
                    SR_Scope_Comments__c
                     from Project__c 
                    where Opportunity__c =: OppId];
          return proj;
	}

    public static Replicon_Time_Entry__c createTimeEntry(Boolean isInsert, Id timesheetId, Id employeeId, Project__c project) {
        Replicon_Time_Entry__c timeEntry = new Replicon_Time_Entry__c();
        timeEntry.Replicon_Timesheet__c = timesheetId;
        timeEntry.Employee__c = employeeId;
        timeEntry.Project__c = project.Id;
        timeEntry.Replicon_Project_URI__c = project.RepliconUri__c;

        if (isInsert) {
            insert timeEntry;
        }
        return timeEntry;
    }

    public static Replicon_Timesheet__c createTimesheet(Boolean isInsert, Id employeeId) {
        Replicon_Timesheet__c timesheet = new Replicon_Timesheet__c();
        timesheet.Employee__c = employeeId;
        timesheet.Start_Date__c = System.today();

        if (isInsert) {
            insert timesheet;
        }
        return timesheet;
    }
}