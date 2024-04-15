/**
 * Created by Janaki Mahapatra
 * November, 2017
 * 
 * ************************************Edits************************************
 * Author				Time			Purpose
 * Jessica Roberts		Mar/Apr 2018	Time Entry Audit Callout
 * James Qian			Aug 2018		Time Entry and Timesheet Callout/Parsing
 * James Qian			Aug 2018		Team Member and Billing Rate Callout/Parsing
 * James Qian			September 2018	Task processing
 * James Qian			September 2018	Project rollup fields
 * James Qian			October 2018	Timesheet rollup fields
 * Sam Tucker			March 2021		If Time Entry does not have a matching Billing Rate it is set to Null and marked as Non-Billable
 * Sam Tucker           December 2021   Added logic for creating forecast names so projects with URI #'s larger than 4 digits are not cut off short
 * Sam Tucker           February 2022   Added logic to add newly created Forecast to a set rather than a List to prevent duplicate Forecast Records from being created.
 */

public with sharing class RepliconService {

    //================================================================================
    // Properties
    //================================================================================

    private final String COMPANY_KEY = 'levementum';
    private final String AUTH_USERNAME = 'u2014';
    private final String AUTH_PASSWORD = 'aNP3UWeawu7c';
    private final String BASE_URL = 'https://na3.replicon.com/levementum/services/';
    private static final List<String> FORECAST_ASSMT_MANDATORY_FIELDS = new List<String>{
        'Timesheet_Period__c', 'WeekEndDate__c', 'Employee__c', 'Project__c', 'Replicon_User_Number__c'//, 'Replicon_Project_URI__c'
    };

    private final String placeholderProjectId = 'a1q6T000003v2K0QAI';
    private final String levPTOProjectId = 'a1q6T000003v4mFQAQ';
    //private final String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);
    
    private String delim = ',';
    // the input data
    private String[] buffer;
    
    private set<String> storedTimesheetURIs = new Set<String>();
	private Map<String, Contact> repliconToContactMap = new Map<String, Contact>();

    private String temporaryRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:37d7b492-622f-4063-a7b6-e4a698e9f892';
    private String concessionRateURI = 'urn:replicon-tenant:levementum:company-billing-rate:d80618d7-7cbf-5c6d-add9-6336e87ce378';

    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId(); //RecordTypeId of the Weekly Target RT of Revenue Forecasts
    
    public RepliconService() {
    }
	
    /*	
	* Method: getTimesheetEntries
	* James Qian, August 2018
	* This method takes a date and a list of employee contact IDs and calls replicon twice to 
	* get the timesheet URIs for that date, and then all time entries under those timesheets.
	*/
    public void getTimesheetEntries(Date timesheetDate, List<Id> employeeIdList) {
        try {
            
            System.debug('Fetching for Period Including ' + timesheetDate);
            System.debug('For employees: ' + employeeIdList);
            
            //Callout to get Timesheet URIs
            String jsonStringCallout1 = generateJSONGetTimesheetURIs(timesheetDate, employeeIdList);
            
            System.debug('********OUTBOUND JSON 1***********');
            System.debug(jsonStringCallout1);
            
            HttpRequest request1 = this.getRequest('TimesheetService1.svc/BulkGetTimesheetForDate');
            request1.setHeader('X-Replicon-Security-Context', 'User');
            request1.setBody(jsonStringCallout1);
            Http thisHTTP = new Http();
            request1.setTimeout(30000);
            HttpResponse response1 = thisHTTP.send(request1);
            
            System.debug('********INBOUND JSON 1***********');
            System.debug(response1.getBody());
            
            //Callout to get Timesheet details
            RepliconTimesheetURIWrapper deserializedTimesheetURIs = RepliconTimesheetURIWrapper.parse(response1.getBody());
            //Setting storedTimesheetURIs which holds URIs for query for time sheets
            String jsonStringCallout2 = generateJSONGetTimesheetDetails(deserializedTimesheetURIs);
            
            System.debug('********OUTBOUND JSON 2***********');
            System.debug(jsonStringCallout2);
            
            HttpRequest request2 = this.getRequest('TimesheetService1.svc/BulkGetTimesheetDetails');
            request2.setHeader('X-Replicon-Security-Context', 'User');
            request2.setBody(jsonStringCallout2);
            request2.setTimeout(90000);
            HttpResponse response2 = thisHTTP.send(request2);
            
            System.debug('********INBOUND JSON 2***********');
            //System.debug(response2.getBody().length());
            System.debug(response2.getBody());
            
            //Deserialize into class
            RepliconTimeEntriesResponse deserializedTimesheetDetails = RepliconTimeEntriesResponse.parse(response2.getBody());
            //System.debug(deserializedTimesheetDetails);
            
            //Query existing timesheets for update and store in map for searching
            List<Replicon_Timesheet__c> queriedTimesheets = [SELECT Id, Status__c, Replicon_URI__c, Employee__c, Start_Date__c, SubmissionDate__c FROM Replicon_Timesheet__c WHERE Replicon_URI__c IN :storedTimesheetURIs];
            
            Map<String, Replicon_Timesheet__c> queriedTimesheetMap = new Map<String, Replicon_Timesheet__c>();
            for(Replicon_Timesheet__c currentTimesheet : queriedTimesheets) {
                queriedTimesheetMap.put(currentTimesheet.Replicon_URI__c, currentTimesheet);
            }
            
            //Sort deserialized timesheets into existing and not existing in database
            Set<String> repliconProjectURIs = new Set<String>();
            List<RepliconTimeEntriesResponse.d> wrappersToUpdate = new List<RepliconTimeEntriesResponse.d>();
            List<RepliconTimeEntriesResponse.d> wrappersToInsert = new List<RepliconTimeEntriesResponse.d>();
            List<Replicon_Timesheet__c> recordsToUpdate = new List<Replicon_Timesheet__c>();
            List<Replicon_Timesheet__c> recordsToInsert = new List<Replicon_Timesheet__c>();
            if(queriedTimesheetMap.keyset().size() > 0) {
                //Nest FOR LOOP IS BAD
                for(RepliconTimeEntriesResponse.d currentDeserializedTimesheet : deserializedTimesheetDetails.d) {
                    if(queriedTimesheetMap.containsKey(currentDeserializedTimesheet.uri)) {
                        wrappersToUpdate.add(currentDeserializedTimesheet);
                    }
                    else {
                        wrappersToInsert.add(currentDeserializedTimesheet);
                    }
                    for(RepliconTimeEntriesResponse.TimeAllocations currentAllocation : currentDeserializedTimesheet.timeAllocations) {
                        if(currentAllocation.project != NULL) {
                            repliconProjectURIs.add(currentAllocation.project.projectUri);
                        }
                    }
                }
            }
            else {
                wrappersToInsert.addAll(deserializedTimesheetDetails.d);
            }
            
            //If there's an update to timesheet status, add to an update list
            for(RepliconTimeEntriesResponse.d currentDeserializedWrapper : wrappersToUpdate) {
                if(queriedTimesheetMap.containsKey(currentDeserializedWrapper.uri)){
                    Replicon_Timesheet__c currentTimesheet = queriedTimesheetMap.get(currentDeserializedWrapper.uri);
                    Boolean updateTimesheet = false;
                    if(currentDeserializedWrapper.statusUri != NULL && 
                    queriedTimesheetMap.get(currentDeserializedWrapper.uri).Status__c.toLowerCase() != 
                    currentDeserializedWrapper.statusUri.substringAfter('timesheet-status:')) {
                        currentTimesheet.Status__c = currentDeserializedWrapper.statusUri.substringAfter('timesheet-status:').Capitalize();
                        updateTimesheet = true;
                        //recordsToUpdate.add(currentTimesheet);
                    }

                    //Check if the Submission date is populated on the callout timesheet, if it is and the Existing Timesheet doesn't have a value in that field then populate the Submission Date field on the Timesheet and update.
                    if(currentDeserializedWrapper.customFields != null && currentDeserializedWrapper.customFields.size() > 0 && currentDeserializedWrapper.customFields[0].submissionDateFormatted != null && queriedTimesheetMap.get(currentDeserializedWrapper.uri).SubmissionDate__c == null){
                        currentTimesheet.SubmissionDate__c = currentDeserializedWrapper.customFields[0].submissionDateFormatted;
                        updateTimesheet = true;
                        
                    }

                    if(updateTimesheet){
                        recordsToUpdate.add(currentTimesheet);
                    }
                }
            }
            
            //Add new records to an insert list
            for(RepliconTimeEntriesResponse.d currentDeserializedTimesheet : wrappersToInsert) {
                Replicon_Timesheet__c newTimesheet = getTimesheetRecordFromWrapper(currentDeserializedTimesheet);
                if(repliconToContactMap.containsKey(currentDeserializedTimesheet.owner.uri)){
                    Contact relatedContact = repliconToContactMap.get(currentDeserializedTimesheet.owner.uri);
                    newTimesheet.Name = relatedContact.Name + ': ' + newTimesheet.Start_Date__c.Format();
                    newTimesheet.Employee__c = relatedContact.Id;
                    //Created 9/19/2022 ST for Capacity Work
                    
                    //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                    Decimal timesheetExpectedHours = 0;
                    //Only Calculate Week Target on Timesheet if the Employee is Active OR if the Employee is not active then only calculate timesheet target if the timesheet was before their termination date
                    if(relatedContact.Active__c == true || (relatedContact.Term_Date__c != null && relatedContact.Active__c == false && newTimesheet.Start_Date__c < relatedContact.Term_Date__c)){

                        //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                        if(relatedContact.Weekly_Target__c != null && relatedContact.RampTime__c != null && relatedContact.Ramp_End_Date__c != null && newTimesheet.Start_Date__c != null){
                            timesheetExpectedHours = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(relatedContact.Weekly_Target__c, relatedContact.RampTime__c, relatedContact.Ramp_End_Date__c.toStartOfWeek(), newTimesheet.Start_Date__c);
                        
                        //If the Ramp fields are not populated then just populate the expected Hours with the weekly Target if populated
                        }else if(relatedContact.Weekly_Target__c != null){
                            timesheetExpectedHours = relatedContact.Weekly_Target__c;
                        }

                    //If Timesheet is for an inactive employee and the timesheet is after the related Employee's Termination date then set the expected hours to 0
                    }

                    newTimesheet.Target__c = timesheetExpectedHours;

                    newTimesheet.EmployeeDepartment__c = relatedContact.Department;
                    newTimesheet.EmployeeDivision__c = relatedContact.Division_New__c;
                    newTimesheet.EmployeeTitle__c = relatedContact.Title;
                    newTimesheet.EmployeesManager__c = relatedContact.ReportsToId;
    
                }
                //If submission Date is on the callout response Timesheet then set the Submission Date
                if(currentDeserializedTimesheet.customFields != null && currentDeserializedTimesheet.customFields.size() > 0 && currentDeserializedTimesheet.customFields[0].submissionDateFormatted != null ){
                    newTimesheet.SubmissionDate__c = currentDeserializedTimesheet.customFields[0].submissionDateFormatted;
                    
                }
                recordsToInsert.add(newTimesheet);
            }
            
            //DML statements
            if(recordsToUpdate.size() > 0) {
                System.debug('**********Updating timesheet records***********');
                System.debug('**@**' + recordsToUpdate);
                update recordsToUpdate;
            }
            if(recordsToInsert.size() > 0) {
                System.debug('**********Inserting timesheet records***********');
                System.debug('**@**' + recordsToInsert);
                insert recordsToInsert;
            }
            //After DML, put timesheet SF IDs into a map for searching to associate child records
            Map<String, Id> timesheetURIMap = new Map<String, Id>();
            for(String key : queriedTimesheetMap.keyset()) {
                //<Time Sheet URI, TimeSheet Id> of already existing that were queried for
                timesheetURIMap.put(key, queriedTimesheetMap.get(key).Id);
            }
            for(Replicon_Timesheet__c currentTimesheet : recordsToInsert) {
                //<Time Sheet URI, TimeSheet Id> of new that were inserted
                timesheetURIMap.put(currentTimesheet.Replicon_URI__c, currentTimesheet.Id);
            }

            //Query time entries already existing in database based on timesheet URI and put into a map for searching
            //Sam Update add Associated_Billing_Rate__c to Query
            List<Replicon_Time_Entry__c> queriedTimeEntries = [SELECT Id, Name, Replicon_URI__c, Replicon_Timesheet__c, EntryDate__c, Replicon_Project_URI__c,
                                                               Comments__c, TotalHrs__c, ActivityName__c, ProjectCode__c, Replicon_Billing_Rate_URI__c, 
                                                               Time_Off_Description__c, Replicon_Project_Task_URI__c, TaskName__c, Associated_Billing_Rate__c, 
                                                                Replicon_Timesheet_URI__c, Project__c, Employee__r.Replicon_User_Number__c, Deleted_in_Replicon__c
                                                               FROM Replicon_Time_Entry__c 
                                                               WHERE Replicon_Timesheet__r.Replicon_URI__c IN :timesheetURIMap.keyset()];


            Map<String, Replicon_Time_Entry__c> queriedTimeEntryMap = new Map<String, Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c currentTimeEntry : queriedTimeEntries) {
                //<TimeEntry URI, TimeEntry Obj> of existing TimeEntries
                queriedTimeEntryMap.put(currentTimeEntry.Replicon_URI__c, currentTimeEntry);
            }
            
            //Sort time entry wrappers into update and insert columns and add values into lookup fields.
            //If any fields have been changed, add to update list.
            //Add all new time entries to insert list.
            Map<Id, Replicon_Time_Entry__c> timeEntriesToUpdate = new Map<Id, Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> timeEntriesToInsert = new List<Replicon_Time_Entry__c>();
            Set<String> unchangedTimeEntryURIs = new Set<String>();
            for(RepliconTimeEntriesResponse.d currentTimesheetWrapper : deserializedTimesheetDetails.d) {
                //Nested FOR LOOP IS BAD
                for(RepliconTimeEntriesResponse.TimeAllocations currentEntry : currentTimesheetWrapper.timeallocations) {

                    //ST Added to ensure PTO Entries have a URI before using URI in logic to determine if it needs an update or needs to be inserted or if it can be ignored.
                    if(currentEntry.correlatedTimeOffUri != null && currentEntry.uri == null){
                        Date ptoEntryDate = Date.newInstance(currentEntry.dateValue.year, currentEntry.dateValue.month, currentEntry.dateValue.day);
                        currentEntry.uri = currentEntry.correlatedTimeOffUri + String.valueOf(ptoEntryDate);
                    }

                    if(queriedTimeEntryMap.containsKey(currentEntry.uri)){
                        if(TimeEntryNeedsUpdate(currentEntry, queriedTimeEntryMap.get(currentEntry.uri))) {
                            Replicon_Time_Entry__c changedTimeEntry = GetTimeEntryFromWrapper(currentEntry);
                            changedTimeEntry.Id = queriedTimeEntryMap.get(currentEntry.uri).Id;
                            changedTimeEntry.Employee__c = repliconToContactMap.get(currentEntry.user.uri).Id;
                            changedTimeEntry.Replicon_Timesheet__c = timesheetURIMap.get(currentTimesheetWrapper.uri);
                            changedTimeEntry.Replicon_Timesheet_URI__c = currentTimesheetWrapper.uri;
                            /*Sam Tucker 3/29 Billable Fix for Case #00015439
                                Sets Associated Billing Rate to Null (Switching to Non Billable)*/
                            if(currentEntry.billingrate == null){
                            	changedTimeEntry.Associated_Billing_Rate__c = null;
                                changedTimeEntry.Replicon_Billing_Rate_URI__c = null;
                            }else{
                                changedTimeEntry.Replicon_Billing_Rate_URI__c = currentEntry.billingrate.uri;
                            }
                            /*End of Sam Tucker 3/29 Billable Fix*/                            
                            timeEntriesToUpdate.put(changedTimeEntry.Id, changedTimeEntry);
                        }
                        else {
                            unchangedTimeEntryURIs.add(currentEntry.uri);
                        }
                    }
                    //if Time Entry doesn't exist then IF User ID of TimeAllocations is in map initiallized after first outbound call
                    else if(repliconToContactMap.get(currentEntry.user.uri).Id != NULL){
                        //System.debug('Adding time entry for insert ' + currentEntry.uri);
                        Replicon_Time_Entry__c newTimeEntry = GetTimeEntryFromWrapper(currentEntry);
                        newTimeEntry.Employee__c = repliconToContactMap.get(currentEntry.user.uri).Id;
                        newTimeEntry.Replicon_Timesheet__c = timesheetURIMap.get(currentTimesheetWrapper.uri);
                        newTimeEntry.Replicon_Timesheet_URI__c = currentTimesheetWrapper.uri;
                        timeEntriesToInsert.add(newTimeEntry);
                    }
                }
            }            

            //DML for time entries
            if(timeEntriesToUpdate.keyset().size() > 0) {
                System.debug('**********Updating ' + timeEntriesToUpdate.size() + ' time entry records***********');
                System.debug(timeEntriesToUpdate);
                update timeEntriesToUpdate.values();
            }
            if(timeEntriesToInsert.size() > 0) {
                System.debug('**********Inserting ' + timeEntriesToInsert.size() + ' time entry records***********');
                System.debug(timeEntriesToInsert);
                insert timeEntriesToInsert;
            }

            //Handle time entries deleted in Replicon by making Deleted_in_Replicon__c true
            Set<String> urisInTimesheet = new Set<String>();
            for(Replicon_Time_Entry__c currentEntry : timeEntriesToUpdate.values()) {
                if(currentEntry.Replicon_Uri__c != NULL) {
                    urisInTimesheet.add(currentEntry.Replicon_Uri__c);
                }
            }

            for(Replicon_Time_Entry__c currentEntry : timeEntriesToInsert) {
                if(currentEntry.Replicon_Uri__c != NULL) {
                    urisInTimesheet.add(currentEntry.Replicon_Uri__c);
                }
            }

            urisInTimesheet.addAll(unchangedTimeEntryURIs);
            System.debug('Time Entries in Replicon: ' + urisInTimesheet.size());
            System.debug(urisInTimesheet);
            List<Replicon_Time_Entry__c> timeEntriesDeletedInReplicon = new List<Replicon_Time_Entry__c>();
            System.debug('Time Entries in Salesforce: ' + queriedTimeEntryMap.keyset().size());
            for(String uri : queriedTimeEntryMap.keyset()) {
                if(!urisInTimesheet.contains(uri)) {
                    Replicon_Time_Entry__c deletedEntry = queriedTimeEntryMap.get(uri);
                    if(deletedEntry.Deleted_in_Replicon__c != true){
                        deletedEntry.Deleted_in_Replicon__c = true;
                        timeEntriesDeletedInReplicon.add(deletedEntry);
                    }
                }
            }

            //Mark deleted ones first so the calculation for rollups from the updates and inserts following do not include the hours from entries that are going to be deleted
            if(timeEntriesDeletedInReplicon.size() > 0) {
                System.debug('Time entries updating as deleted: ' + timeEntriesDeletedInReplicon.size());
                System.debug(timeEntriesDeletedInReplicon);
                update timeEntriesDeletedInReplicon;
            }

        }
        catch(Exception e) {
            System.debug('Caught Error HERE!!: ' + e);
            LevExceptionHandler.logError(e.getMessage() + ', Date: ' + String.valueOf(timesheetDate) + ', Employee IDs: ' + employeeIdList , e.getLineNumber(), 'RepliconService', 'getTimesheetEntries', NULL);
            if(!Test.isRunningTest()) this.sendError(e.getMessage());
         }
    }
    
    //Method to get project team members, billing rates, and tasks. In Replicon a user can have multiple billing rates for the same project.
	//So billing rate is a child of team member, which is a junction between employee and project. There can also be orphan billing rates
	//for all users on a project (e.g. project-specific-billing-rate). Projects can also include tasks, or buckets for time. This method is meant 
	//to get project team member, billing rate, and task data from Replicon and store it in Salesforce so that when time entries are 
	//pulled from Replicon, they can be associated with the right billing rate and task.
    //James Qian - August 2018
    public void getProjectInformation(Id projectId) {
        try {
            Project__c queriedProject = [SELECT Id, RepliconUri__c, Name FROM Project__c WHERE Id = :projectId LIMIT 1];
            JSONGenerator teamMemberJSONgen = JSON.createGenerator(true);
            teamMemberJSONgen.writeStartObject();
            teamMemberJSONgen.writeStringField('projectUri', queriedProject.RepliconUri__c);
            teamMemberJSONgen.writeNullField('asOfDate');
            teamMemberJSONgen.writeEndObject();
            
            System.debug('*************OUTBOUND JSON 1****************');
            System.debug(teamMemberJSONgen.getAsString());
            
            //Create http request with replicon headers
            HttpRequest req1 = this.getRequest('ProjectService1.svc/GetAllProjectTeamMemberDetails');
            req1.setHeader('X-Replicon-Security-Context', 'User');
            req1.setBody(teamMemberJSONgen.getAsString());
            
            //Send http request to replicon
            Http h = new Http();
            req1.setTimeout(60000);
            HttpResponse response1 = h.send(req1);
            
            System.debug('*************INBOUND JSON 1****************');
            System.debug(response1.getBody());
            
            //Deserializing before second callout because of unexpected behavior of multi static resource mock
            RepliconTeamMemberResponse deserializedTeamMemberResponse = new RepliconTeamMemberResponse();
            if(response1.getstatusCode() == 200 && response1.getbody() != null) {
                String modifiedBody = response1.getBody();
                modifiedBody = modifiedBody.replaceAll('"Currency":', '"CurrencyType":');
                modifiedBody = modifiedBody.replaceAll('"currency":', '"currencyType":');
                //Deserialize response
                deserializedTeamMemberResponse = RepliconTeamMemberResponse.parse(modifiedBody);
            }
            
            //Perform second callout for tasks to avoid DML before callout
            JSONGenerator taskJsonGen = JSON.createGenerator(true);
            taskJsonGen.writeStartObject();
            taskJsonGen.writeStringField('projectUri', queriedProject.RepliconUri__c);
            taskJsonGen.writeEndObject();
            
            System.debug('*************OUTBOUND JSON 2****************');
            System.debug(taskJsonGen.getAsString());
            
            //Create http request with replicon headers
            HttpRequest req2 = this.getRequest('ProjectService1.svc/GetProjectActualsByTask');
            req2.setHeader('X-Replicon-Security-Context', 'User');
            req2.setBody(taskJsonGen.getAsString());
            
            //Send http request to replicon
            req2.setTimeout(60000);
            HttpResponse response2 = h.send(req2);
            
            System.debug('*************INBOUND JSON 2****************');
            System.debug(response2.getbody());
            
            //Process team members and billing rates
            if(response1.getstatusCode() == 200 && response1.getbody() != null) {
                
                //Create wrapper map of Replicon user number to wrapper object
                Map<Decimal, TeamMemberWrapper> teamMemberWrapperMap = new Map<Decimal, TeamMemberWrapper>();
                for(RepliconTeamMemberResponse.d dataRow : deserializedTeamMemberResponse.d) {
                    if(dataRow.resource.uri.containsIgnoreCase('user:')) {
                        dataRow.userNumber = Decimal.valueOf(dataRow.resource.uri.substringAfter('user:'));
                        teamMemberWrapperMap.put(dataRow.userNumber, new TeamMemberWrapper());
                    }
                }           

                
                //Store parent contact IDs in wrapper class
                List<Contact> queriedEmployees = [SELECT Id, Name, Replicon_User_Number__c FROM Contact 
                                                  WHERE Replicon_User_Number__c IN :teamMemberWrapperMap.keyset() 
                                                  AND RecordType.Name = 'Employee'];
                for(Contact currentContact : queriedEmployees) {
                    TeamMemberWrapper currentTMW = teamMemberWrapperMap.get(currentContact.Replicon_User_Number__c);
                    currentTMW.employee = currentContact;
                    //currentTMW.ContactId = currentContact.Id;
                    teamMemberWrapperMap.put(currentContact.Replicon_User_Number__c, currentTMW);
                }
                
                //Store existing team member and billing rate records in wrappers            
                List<Project_Team_Member__c> currentTeamMembers = [SELECT Id, Name, Employee__c, Project__c, Replicon_User_Number__c 
                                                                   FROM Project_Team_Member__c
                                                                   WHERE Project__c = :projectId
                                                                   AND Replicon_User_Number__c IN :teamMemberWrapperMap.keyset()];
                Map<String, Project_Team_Member_Billing_Rate__c> companyWideRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
                List<Project_Team_Member_Billing_Rate__c> currentCompanyWideRates = [SELECT Id, Name, Replicon_URI__c, Replicon_User_Number__c, Hourly_Rate__c
                                                                                     FROM Project_Team_Member_Billing_Rate__c
                                                                                     WHERE Project__c = :projectId
                                                                                     AND Project_Team_Member__c = NULL];
                for(Project_Team_Member_Billing_Rate__c currentBillingRate : currentCompanyWideRates) {
                        companyWideRateMap.put(currentBillingRate.Replicon_URI__c, currentBillingRate);
                    }
                System.debug('Existing company wide rates:');
                System.debug(companyWideRateMap.keyset());
                if(currentTeamMembers.size() > 0) {
                    for(Project_Team_Member__c currentTeamMember : currentTeamMembers) {
                        TeamMemberWrapper currentTMW = teamMemberWrapperMap.get(currentTeamMember.Replicon_User_Number__c);
                        currentTMW.projectTeamMember = currentTeamMember;
                        teamMemberWrapperMap.put(currentTeamMember.Replicon_User_Number__c, currentTMW);
                    }
                    List<Project_Team_Member_Billing_Rate__c> currentBillingRates = [SELECT Id, Name, Replicon_URI__c, Replicon_User_Number__c, Hourly_Rate__c
                                                                                     FROM Project_Team_Member_Billing_Rate__c
                                                                                     WHERE Project_Team_Member__r.Project__c = :projectId
                                                                                     AND Replicon_User_Number__c IN :teamMemberWrapperMap.keyset()];
                    
                    
                    for(Project_Team_Member_Billing_Rate__c currentBillingRate : currentBillingRates) {
                        TeamMemberWrapper currentTMW = teamMemberWrapperMap.get(currentBillingRate.Replicon_User_Number__c);
                        currentTMW.billingRateMap.put(currentBillingRate.Replicon_URI__c, currentBillingRate);
                        teamMemberWrapperMap.put(currentBillingRate.Replicon_User_Number__c, currentTMW);
                    }
                    
                }
                
                //Prepare for DML insert of new team members
                List<Project_Team_Member__c> insertTeamMembersList = new List<Project_Team_Member__c>();
                for(RepliconTeamMemberResponse.d dataRow : deserializedTeamMemberResponse.d) {
                    if(dataRow.resource.uri.containsIgnoreCase('user:')) {
                        if(teamMemberWrapperMap.get(dataRow.userNumber).projectTeamMember == NULL) {
                            Project_Team_Member__c newTeamMember = new Project_Team_Member__c();
                            if(teamMemberWrapperMap.get(dataRow.userNumber).employee == NULL) {
                                LevExceptionHandler.logError('Failed to find employee in Salesforce - Replicon User Number ' + dataRow.userNumber, 0, 'RepliconService', 'getProjectTeamMembers', projectId);
                                if(!Test.isRunningTest()) this.sendError('Failed to find employee in Salesforce - Replicon User Number ' + dataRow.userNumber + ' from Project Id: ' + projectId);
                                continue;
                            }
                            newTeamMember.Employee__c = teamMemberWrapperMap.get(dataRow.userNumber).employee.Id;
                            newTeamMember.Project__c = projectId;
                            String teamMemberNameString = teamMemberWrapperMap.get(dataRow.userNumber).employee.Name + ' - ' + queriedProject.Name;
                            if(teamMemberNameString.length() > 80) {
                                teamMemberNameString = teamMemberNameString.substring(0, 80);
                            }
                            newTeamMember.Name = teamMemberNameString;
                            System.debug('*************Inserting Team Members****************');
                            insertTeamMembersList.add(newTeamMember);
                        }
                    }
                }
                
                //Adds parent IDs to wrapper for child relationship association
                if(insertTeamMembersList.size() > 0) {
                    insert insertTeamMembersList;
                    Set<Id> idSet = new Set<Id>();
                    for(Project_Team_Member__c currentTeamMember : insertTeamMembersList) {
                        idSet.add(currentTeamMember.Id);
                    }
                    List<Project_Team_Member__c> queriedTeamMembers = [SELECT Id, Replicon_User_Number__c FROM Project_Team_Member__c WHERE ID IN :idSet];
                    for(Project_Team_Member__c insertedTeamMember : queriedTeamMembers) {
                        TeamMemberWrapper currentTMW = teamMemberWrapperMap.get(insertedTeamMember.Replicon_User_Number__c);
                        currentTMW.insertedTeamMemberId = insertedTeamMember.Id;
                        teamMemberWrapperMap.put(insertedTeamMember.Replicon_User_Number__c, currentTMW);
                    }
                }
                
                //Prepare for DML insert of new billing rates
                List<Project_Team_Member_Billing_Rate__c> insertBillingRatesList = new List<Project_Team_Member_Billing_Rate__c>();
                for(RepliconTeamMemberResponse.d dataRow : deserializedTeamMemberResponse.d) {
                    if(dataRow.resource.uri.containsIgnoreCase('user:') && dataRow.billingRatesAllowedForBillingTime != NULL) {
                        //NEST FOR LOOP IS BAD
                        for(RepliconTeamMemberResponse.BillingRatesAllowedForBillingTime currentJSONRate : dataRow.billingRatesAllowedForBillingTime) {
                            String billingRateURI = currentJSONRate.billingRate.uri;
                            
                            //If the team member does not exist in Salesforce
                            if(teamMemberWrapperMap.get(dataRow.userNumber).projectTeamMember == NULL) {
                                Project_Team_Member_Billing_Rate__c newRate = createBillingRateRecord(
                                    teamMemberWrapperMap.get(dataRow.userNumber).insertedTeamMemberId, 
                                    currentJSONRate.billingRate.name, 
                                    currentJSONRate.effectiveBillingRate.value.amount, 
                                    billingRateURI,
                                	projectId);
                                insertBillingRatesList.add(newRate);
                            }
                            
                            //If the billing rate does not exist on the team member
                            else if(!teamMemberWrapperMap.get(dataRow.userNumber).billingRateMap.containsKey(billingRateURI)) {
                                Project_Team_Member_Billing_Rate__c newRate = createBillingRateRecord(
                                    teamMemberWrapperMap.get(dataRow.userNumber).projectTeamMember.Id, 
                                    currentJSONRate.billingRate.name, 
                                    currentJSONRate.effectiveBillingRate.value.amount, 
                                    billingRateURI,
                                    projectId);
                                newRate.Currency__c = currentJSONRate.effectiveBillingRate.value.currencytype.symbol;
                                insertBillingRatesList.add(newRate);
                            }
                        }
                    }
                    else if(dataRow.resource.uri.containsIgnoreCase('department:') && dataRow.billingRatesAllowedForBillingTime != NULL) {
                        for(RepliconTeamMemberResponse.BillingRatesAllowedForBillingTime currentJSONRate : dataRow.billingRatesAllowedForBillingTime) {
                            if(!companyWideRateMap.containsKey(currentJSONRate.billingRate.uri)) {
                                System.debug('URI not found: ' + currentJSONRate.billingRate.uri);
                                Project_Team_Member_Billing_Rate__c newRate = createBillingRateRecord(
                                    NULL, 
                                    currentJSONRate.billingRate.name, 
                                    currentJSONRate.effectiveBillingRate.value.amount, 
                                    currentJSONRate.billingRate.uri,
                                    projectId);
                                newRate.Currency__c = currentJSONRate.effectiveBillingRate.value.currencytype.symbol;
                                newRate.Company_Wide_Rate__c = true;
                                insertBillingRatesList.add(newRate);
                            }
                        }
                    }
                }
                if(insertBillingRatesList.size() > 0) {
                    System.debug('*************Inserting Billing Rates****************');
                    System.debug(insertBillingRatesList);
                    insert insertBillingRatesList;
                    
                    //Associate time entries with these billing rate records
                    
                    Map<String, Id> billingRateIdMap = new Map<String, Id>();
                    for(Project_Team_Member_Billing_Rate__c currentRate : insertBillingRatesList) {
                        billingRateIdMap.put(currentRate.Replicon_URI__c, currentRate.Id);
                    }
                    
                    List<Replicon_Time_Entry__c> timeEntriesWithoutRates = [SELECT Id, Replicon_Billing_Rate_URI__c, Associated_Billing_Rate__c 
                                                                            FROM Replicon_Time_Entry__c
                                                                            WHERE Replicon_Billing_Rate_URI__c IN :billingRateIdMap.keyset()
                                                                            AND Associated_Billing_Rate__c = NULL
                                                                            AND Project__c = :projectId];
                    if(timeEntriesWithoutRates.size() > 0) {
                        for(Replicon_Time_Entry__c currentTimeEntry : timeEntriesWithoutRates) {
                            currentTimeEntry.Associated_Billing_Rate__c = billingRateIdMap.get(currentTimeEntry.Replicon_Billing_Rate_URI__c);
                        }
                        System.debug('*************Updating Time Entries****************');
                        System.debug(timeEntriesWithoutRates);
                        update timeEntriesWithoutRates;
                    }
                }
            }
            else {
                LevExceptionHandler.logError('Invalid API response for fetching team members for Project ' + queriedProject.RepliconUri__c , 0, 'RepliconService', 'getProjectTeamMembers', queriedProject.Id);
                if(!Test.isRunningTest()) this.sendError('Invalid API response for fetching team members for Project ' + queriedProject.RepliconUri__c);
            }
            
            //Process project tasks
            if(response2.getstatusCode() == 200 && response2.getbody() != null) {
                
                //Deserialize into wrapper class, iterate through class and get URIs for querying existing project tasks
                try {
                    Map<String, Replicon_Project_Task__c> taskRepliconURIMap = new Map<String, Replicon_Project_Task__c>();
                    RepliconProjectTaskResponse deserializedResponse = RepliconProjectTaskResponse.parse(response2.getBody());
                    if(deserializedResponse.d.size() > 0) {
                        for(RepliconProjectTaskResponse.d currentTask : deserializedResponse.d) {
                            if(currentTask.task != NULL) {
                                taskRepliconURIMap.put(currentTask.task.uri, NULL);
                            }
                        }
                        
                        //Query for existing project tasks and put into a map for searching
                        if(taskRepliconURIMap.keyset().size() > 0) {
                            List<Replicon_Project_Task__c> queriedTasks = [SELECT Id, Replicon_URI__c FROM Replicon_Project_Task__c 
                                                                           WHERE Replicon_URI__c IN :taskRepliconURIMap.keyset() AND Project__c = :queriedProject.Id];
                            if(queriedTasks.size() > 0) {
                                for(Replicon_Project_Task__c currentQueriedTask : queriedTasks) {
                                    taskRepliconURIMap.put(currentQueriedTask.Replicon_URI__c, currentQueriedTask);
                                }
                            }
                        }
                        
                        //Sort into update and insert lists based on whether a record already exists
                        List<Replicon_Project_Task__c> updateList = new List<Replicon_Project_Task__c>();
                        List<Replicon_Project_Task__c> insertList = new List<Replicon_Project_Task__c>();
                        for(RepliconProjectTaskResponse.d currentTask : deserializedResponse.d) {
                            if(currentTask.task != NULL && taskRepliconURIMap.get(currentTask.task.uri) != NULL) {
                                Replicon_Project_Task__c updatedTask = getTaskFromWrapper(currentTask, queriedProject.Id);
                                updatedTask.Id = taskRepliconURIMap.get(currentTask.task.uri).Id;
                                updateList.add(updatedTask);
                            }
                            else {
                                insertList.add(getTaskFromWrapper(currentTask, queriedProject.Id));
                            }
                        }
                        
                        //DML insert/update
                        if(updateList.size() > 0) {
                            update updateList;
                        }
                        if(insertList.size() > 0) {
                            insert insertList;
                            Map<String, Id> insertedURIMap = new Map<String,Id>();
                            for(Replicon_Project_Task__c insertedTask : insertList) {
                                insertedURIMap.put(insertedTask.Replicon_URI__c, insertedTask.Id);
                            }
                            List<Replicon_Time_Entry__c> timeEntriesWithoutTasks = [SELECT Id, Replicon_Project_Task__c, Replicon_Project_Task_URI__c
                                                                                    FROM Replicon_Time_Entry__c
                                                                                    WHERE Replicon_Project_Task_URI__c IN :insertedURIMap.keyset()
                                                                                    AND Replicon_Project_Task__c = NULL];
                            if(timeEntriesWithoutTasks.size() > 0) {
                                for(Replicon_Time_Entry__c currentTimeEntry : timeEntriesWithoutTasks) {
                                    currentTimeEntry.Replicon_Project_Task__c = insertedURIMap.get(currentTimeEntry.Replicon_Project_Task_URI__c);
                                }
                                update timeEntriesWithoutTasks;
                            }
                        }
                    }
                }
                catch(Exception e) {
                    LevExceptionHandler.logError(e, 'RepliconService', 'getProjectInformation', projectID);
                    if(!Test.isRunningTest()) this.sendError(e.getMessage());
                }
            }
            else {
                LevExceptionHandler.logError('Invalid API Response for Task Fetch on Project ' + queriedProject.Id , 0, 'RepliconService', 'getProjectInformation', queriedProject.Id);
                if(!Test.isRunningTest()) this.sendError('Invalid API Response for Task Fetch on Project ' + queriedProject.Id);
            }
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'getProjectInformation', projectID);
            if(!Test.isRunningTest()) this.sendError(e.getMessage());
        }
    }
    
    
    //Associate time entry records with parent records on insert and update. Also sets record name.
    //James Qian, September 2018
    public void populateTimeEntryLookupFields(List<Replicon_Time_Entry__c> newList, Map<Id, Replicon_Time_Entry__c> oldMap) {
        try {
            System.debug('Time Entries in Trigger.New: ' + newList.size());
            System.debug(newList);
            Set<String> repliconProjectURIs = new Set<String>();
            Set<String> repliconBillingRates = new Set<String>();
            Map<String,Replicon_Project_Task__c> taskURIMap = new Map<String,Replicon_Project_Task__c>();
            Map<Id, Contact> relatedEmployees = new Map<Id, Contact>();
            Map<String, Project__c> projectMap = new Map<String, Project__c>();
            Map<String, Project_Team_Member_Billing_Rate__c> billingRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
            List<Date> weekStartOfEntryDatesList = new List<Date>();
            List<Date> entryDateList = new List<Date>();
            Map<String, List<Replicon_Time_Entry__c>> employeeAndEntryDateIdToEntryListMap = new Map<String, List<Replicon_Time_Entry__c>>();
            
            //Populate sets for querying related objects
            for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                //if((currentTimeEntry.Replicon_Project_URI__c != NULL && oldMap == NULL) ||
                //(oldMap != NULL && currentTimeEntry.Replicon_Project_URI__c != oldMap.get(currentTimeEntry.Id).Replicon_Project_URI__c && 
                //currentTimeEntry.Replicon_Project_URI__c != NULL)) {
                if(currentTimeEntry.Replicon_Project_URI__c != NULL) {
                    repliconProjectURIs.add(currentTimeEntry.Replicon_Project_URI__c);
                }
                //if((currentTimeEntry.Replicon_Billing_Rate_URI__c != NULL && oldMap == NULL) ||
                //(oldMap != NULL && currentTimeEntry.Replicon_Billing_Rate_URI__c != oldMap.get(currentTimeEntry.Id).Replicon_Billing_Rate_URI__c && 
                //currentTimeEntry.Replicon_Billing_Rate_URI__c != NULL)) {
                if(currentTimeEntry.Replicon_Billing_Rate_URI__c != NULL) {
                    repliconBillingRates.add(currentTimeEntry.Replicon_User_Number__c + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c);
                	repliconBillingRates.add('0' + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c);
                }
                //if((currentTimeEntry.Employee__c != NULL && oldMap == NULL) ||
                //(oldMap != NULL && currentTimeEntry.Employee__c != oldMap.get(currentTimeEntry.Id).Employee__c && 
                //currentTimeEntry.Employee__c != NULL)) {
                if(currentTimeEntry.Employee__c != NULL) {
                    relatedEmployees.put(currentTimeEntry.Employee__c, NULL);
                }
                if(currentTimeEntry.Replicon_Project_Task_URI__c != NULL) {
                    taskURIMap.put(currentTimeEntry.Replicon_Project_Task_URI__c, NULL);
                }
                if(currentTimeEntry.EntryDate__c != NULL && currentTimeEntry.WeeklyTarget__c == null){
                    if(currentTimeEntry.EntryDate__c.toStartOfWeek().month() == currentTimeEntry.EntryDate__c.month()){
                        weekStartOfEntryDatesList.add(currentTimeEntry.EntryDate__c.toStartOfWeek()); //If the start of the Week is the Same month as the Entry date then the Weekly Target can be found via the Start of the Week Date beca
                    }else{
                        weekStartOfEntryDatesList.add(currentTimeEntry.EntryDate__c.toStartOfMonth()); //If the start of the week is NOT the same month as the Entry Date, then it is the beginning of the month week that we can get the WeekStartDate of via the Start of The Month function to get us the first date in that first partial week
                    }
                }

                //Create map for populating Work Days
                if(currentTimeEntry.EntryDate__c != null && currentTimeEntry.Employee__c != null){
                    entryDateList.add(currentTimeEntry.EntryDate__c);
                    String uniqueEmployeeAndDateId = String.valueOf(currentTimeEntry.Employee__c) + '|' + String.valueOf(currentTimeEntry.EntryDate__c);

                    if(employeeAndEntryDateIdToEntryListMap.containsKey(uniqueEmployeeAndDateId)){
                        //If unique Id of Contact Id + Entry Date is already in the map then add the entry to the list for that Id's mapping
                        List<Replicon_Time_Entry__c> workDayEntryList = employeeAndEntryDateIdToEntryListMap.get(uniqueEmployeeAndDateId);
                        workDayEntryList.add(currentTimeEntry);
                        employeeAndEntryDateIdToEntryListMap.put(uniqueEmployeeAndDateId, workDayEntryList);

                    }else{
                        //If unique Id of Contact Id + Entry Date is NOT YET in the map then create and add the entry to the list for that Id's mapping
                        List<Replicon_Time_Entry__c> workDayEntryList = new List<Replicon_Time_Entry__c>();
                        workDayEntryList.add(currentTimeEntry);
                        employeeAndEntryDateIdToEntryListMap.put(uniqueEmployeeAndDateId, workDayEntryList);
                    }
                }
            }
            
            //Populate Project, Opportunity, and Account field
            if(repliconProjectURIs.size() > 0) {
                List<Project__c> queriedProjects = [SELECT Id, Account__c, Opportunity__c, Name, RepliconUri__c FROM Project__c WHERE RepliconUri__c IN :repliconProjectURIs];
                if(queriedProjects.size() > 0) {
                    for(Project__c currentProject : queriedProjects) {
                        projectMap.put(currentProject.RepliconUri__c, currentProject);
                    }
                    for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                        if(projectMap.containsKey(currentTimeEntry.Replicon_Project_URI__c)) {
                            currentTimeEntry.Project__c = projectMap.get(currentTimeEntry.Replicon_Project_URI__c).Id;
                            currentTimeEntry.Account__c = projectMap.get(currentTimeEntry.Replicon_Project_URI__c).Account__c;
                            currentTimeEntry.Opportunity__c = projectMap.get(currentTimeEntry.Replicon_Project_URI__c).Opportunity__c;
                        }
                    }
                }
            }
            
            //Populate Associated_Billing_Rate__c field
            System.debug('*********************************************************   repliconBillingRates   *********************************************************');
            System.debug('repliconBillingRates Size: ' + repliconBillingRates.size());
            System.debug('repliconBillingRates: ' + repliconBillingRates);
            if(repliconBillingRates.size() > 0) {
                List<Project_Team_Member_Billing_Rate__c> queriedBillingRates = [SELECT Id, Replicon_Project_Billing_Rate_URI__c FROM Project_Team_Member_Billing_Rate__c 
                                                                                 WHERE Replicon_Project_Billing_Rate_URI__c IN :repliconBillingRates
                                                                                 ORDER BY CreatedDate ASC];
                System.debug(queriedBillingRates);
                if(queriedBillingRates.size() > 0) {
                    for(Project_Team_Member_Billing_Rate__c currentBillingRate : queriedBillingRates) {
                        billingRateMap.put(currentBillingRate.Replicon_Project_Billing_Rate_URI__c, currentBillingRate);
                    }
                }
                System.debug('billingRateMap Size: ' + billingRateMap.size());
                System.debug('billingRateMap: ' + billingRateMap);
                for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                    Boolean billingRateMatchFound = false;
                                       
                    if(billingRateMap.size() > 0) {
                        if(billingRateMap.containsKey(currentTimeEntry.Replicon_User_Number__c + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c)) {
                            //System.debug('Regular Billing Rate Found');
                            currentTimeEntry.Associated_Billing_Rate__c = billingRateMap.get(currentTimeEntry.Replicon_User_Number__c + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c).Id;
                            billingRateMatchFound = true;
                        }
                        else if(billingRateMap.containsKey('0' + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c)) {
                            //System.debug('Company Wide Billing Rate Found');
                            currentTimeEntry.Associated_Billing_Rate__c = billingRateMap.get('0' + currentTimeEntry.Replicon_Billing_Rate_URI__c + currentTimeEntry.Replicon_Project_URI__c).Id;
                            billingRateMatchFound = true;
                        }
                    }

                    if(!billingRateMatchFound && currentTimeEntry.Replicon_Billing_Rate_URI__c == temporaryRateURI ){
                        //System.debug('Temporary Rate Found');
                        //Added functionality to populate time entry with temporary rate if it does not already exist 1/26                            
                        Project_Team_Member_Billing_Rate__c newTempRate = new Project_Team_Member_Billing_Rate__c();
                        newTempRate.Project__c = currentTimeEntry.Project__c;
                        newTempRate.Name = 'Temporary Rate';
                        newTempRate.Hourly_Rate__c = 210;
                        newTempRate.Currency__c = 'USD';
                        newTempRate.Company_Wide_Rate__c = true;
                        newTempRate.Replicon_URI__c = currentTimeEntry.Replicon_Billing_Rate_URI__c;
                        insert newTempRate;
                        currentTimeEntry.Associated_Billing_Rate__c = newTempRate.Id;
                        
                    }else if(!billingRateMatchFound && currentTimeEntry.Replicon_Billing_Rate_URI__c == concessionRateURI){
                        //System.debug('Concession Billing Rate Found');
                        //Added functionality to populate time entry with concession rate if it does not already exist 1/26                            
                        Project_Team_Member_Billing_Rate__c newConcessionRate = new Project_Team_Member_Billing_Rate__c();
                        newConcessionRate.Project__c = currentTimeEntry.Project__c;
                        newConcessionRate.Name = 'Concession';
                        newConcessionRate.Hourly_Rate__c = 0;
                        newConcessionRate.Currency__c = 'USD';
                        newConcessionRate.Company_Wide_Rate__c = true;
                        newConcessionRate.Replicon_URI__c = currentTimeEntry.Replicon_Billing_Rate_URI__c;
                        insert newConcessionRate;
                        //System.debug('New Concession Rate: ' + newConcessionRate);
                        //System.debug('New Concession Rate Id: ' + newConcessionRate.Id);
                        currentTimeEntry.Associated_Billing_Rate__c = newConcessionRate.Id;

                    }else if(!billingRateMatchFound && currentTimeEntry.Replicon_Billing_Rate_URI__c != null){
                        System.debug('No Match for Billable Entry -- Billing Rate URI: ' + currentTimeEntry.Replicon_Billing_Rate_URI__c  +' Project URI: ' + currentTimeEntry.Replicon_Project_URI__c);
                    }
                }
            }
            
            //Populate task field
            if(taskURIMap.keyset().size() > 0) {
                List<Replicon_Project_Task__c> queriedTasks = [SELECT Id, Replicon_URI__c FROM Replicon_Project_Task__c WHERE Replicon_URI__c IN :taskURIMap.keyset()];
                for(Replicon_Project_Task__c currentQueriedTask : queriedTasks) {
                    taskURIMap.put(currentQueriedTask.Replicon_URI__c, currentQueriedTask);
                }
                if(taskURIMap.values().size() > 0) {
                    for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                        if(currentTimeEntry.Replicon_Project_Task_URI__c != NULL && taskURIMap.get(currentTimeEntry.Replicon_Project_Task_URI__c) != NULL) {
                            currentTimeEntry.Replicon_Project_Task__c = taskURIMap.get(currentTimeEntry.Replicon_Project_Task_URI__c).Id;
                        }
                    }
                }
            }
            
            //Populate name
            relatedEmployees = new Map<Id, Contact>([SELECT Id, Name, Replicon_User_Number__c, Account.Name, AccountId, Division_New__c, Weekly_Target__c, Quarterly_Target__c, Department FROM Contact WHERE Id IN :relatedEmployees.keyset()]);
            for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                String timeEntryName = '';
                if(relatedEmployees.containsKey(currentTimeEntry.Employee__c)) {
                    Contact entryEmployee = relatedEmployees.get(currentTimeEntry.Employee__c);
                    //System.debug('************************** Entry Employee: ' + entryEmployee);
                    //System.debug('*********** entryEmployee Account Namme ' + entryEmployee.Account.Name);
                    timeEntryName = relatedEmployees.get(currentTimeEntry.Employee__c).Name + ' - ' + currentTimeEntry.EntryDate__c.Format() + ' - ';
                    //Added 6/6/2022 to check a box on the Time Entry to determine if the Time Entry is related to a Lev Employee
                    //if(relatedEmployees.get(currentTimeEntry.Employee__c).AccountId == levementumAccountId){
                    //Added 6.8.2022 to check the Entry Date, Employee Account, and Employee Name to determine if it should be marked as Lev Time
                    if((currentTimeEntry.EntryDate__c < switchToATGTimeDate && entryEmployee.Name != atgConsultantContactName) || (currentTimeEntry.EntryDate__c >= switchToATGTimeDate && entryEmployee.Account.Name == levementumAccountName && entryEmployee.Name != atgConsultantContactName)){
                        currentTimeEntry.Is_Lev_Time__c = true;
                    }else{
                        currentTimeEntry.Is_Lev_Time__c = false;
                    }
                }
                if(projectMap.containsKey(currentTimeEntry.Replicon_Project_URI__c)) {
                    timeEntryName += projectMap.get(currentTimeEntry.Replicon_Project_URI__c).Name;
                }
                if(timeEntryName.length() > 80) {
                    timeEntryName = timeEntryName.substring(0, 80);
                }
                currentTimeEntry.Name = timeEntryName;
            }
            
            //Populate Revenue Forecast (Weekly Target Lookup) WeeklyTarget__c
            List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();
            weeklyTargetsList = [SELECT Id, WeekStartDate__c FROM Revenue_Forecast__c WHERE WeekStartDate__c IN :weekStartOfEntryDatesList AND RecordTypeId =: weeklyTargetRT];
            Map<Date, Id> weeklyTargetStartDateToIdMap = new Map<Date, Id>();
            for(Revenue_Forecast__c weeklyTarget : weeklyTargetsList){
                weeklyTargetStartDateToIdMap.put(weeklyTarget.WeekStartDate__c, weeklyTarget.Id);
            }
            for(Replicon_Time_Entry__c currentTimeEntry : newList) {
                if(currentTimeEntry.EntryDate__c != null && currentTimeEntry.WeeklyTarget__c == null){
                    //if(relatedEmployees.containsKey(currentTimeEntry.Employee__c) && relatedEmployees.get(currentTimeEntry.Employee__c).AccountId == levementumAccountId){ //Added 6/3/2022 ST to exclude non Lev Time from being logged against the Revenue Forecasts
                    if(relatedEmployees.containsKey(currentTimeEntry.Employee__c)){
                        Contact entryEmployee = relatedEmployees.get(currentTimeEntry.Employee__c);
                        //Added 6.8.2022 to check the Entry Date, Employee Account, and Employee Name to determine if it should be linked to a Revenue Forecast
                        if(((currentTimeEntry.EntryDate__c < switchToATGTimeDate && entryEmployee.Name != atgConsultantContactName) || (currentTimeEntry.EntryDate__c >= switchToATGTimeDate && entryEmployee.Account.Name == levementumAccountName && entryEmployee.Name != atgConsultantContactName))){
                            Date entryWeekStartDate;
                            if(currentTimeEntry.EntryDate__c.toStartOfWeek().month() == currentTimeEntry.EntryDate__c.month()){ //If the beginning of the Week is in the same month as the Entries EntryDate then use that day
                                entryWeekStartDate = currentTimeEntry.EntryDate__c.toStartOfWeek();
                            }else{//If the beginning of the week is NOT in the same month then use the first of the month to account for double monthed weeks.
                                entryWeekStartDate = currentTimeEntry.EntryDate__c.toStartOfMonth();
                            }
                            //Get the Related Weekly Target Record to assocate the Time Entry with
                            if(weeklyTargetStartDateToIdMap.containsKey(entryWeekStartDate)){
                                currentTimeEntry.WeeklyTarget__c = weeklyTargetStartDateToIdMap.get(entryWeekStartDate);
                            }
                        }
                    }
                }
            }
            
            
            //Populate Work Day
            if(relatedEmployees.size() > 0 && entryDateList.size() > 0){
                List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
                relatedWorkDayList = [SELECT Id, Name, Employee__c, WorkDayDate__c FROM WorkDay__c WHERE Employee__c IN :relatedEmployees.keySet() AND WorkDayDate__c IN :entryDateList ORDER BY Employee__c, WorkDayDate__c DESC];

                for(WorkDay__c wd : relatedWorkDayList){

                    String uniqueEmployeeAndDateId = String.valueOf(wd.Employee__c) + '|' + String.valueOf(wd.WorkDayDate__c);

                    //If unique Id is in there then loop through the entries and assign the working day lookup field to each entry in the list.
                    if(employeeAndEntryDateIdToEntryListMap.containsKey(uniqueEmployeeAndDateId)){
                        List<Replicon_Time_Entry__c> workingDayEntriesToPopulateList = employeeAndEntryDateIdToEntryListMap.get(uniqueEmployeeAndDateId);
                        for(Replicon_Time_Entry__c entry : workingDayEntriesToPopulateList){
                            if(entry.WorkDay__c != wd.Id){
                                entry.WorkDay__c = wd.Id;
                            }
                        }
                    }
                }
            }           
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'populateTimeEntryLookupFields', NULL);
            if(!Test.isRunningTest()) this.sendError(e.getMessage());
        }
    }

    // Populate Forecast lookup on time entry on insert or update of Project value
    public void populateTimeEntryForecastLookup(List<Replicon_Time_Entry__c> newList) {
        Map<Id, String> timeEntryIdToForecastNameMap = new Map<Id, String>();
        List<Replicon_Time_Entry__c> timeEntryFilteredList = new List<Replicon_Time_Entry__c>();

        try {
            // Map time entry ID to expected forecast name
            for (Replicon_Time_Entry__c timeEntry : newList) {
                Boolean hasMandatoryFields = checkNullsForForecastAssmt(timeEntry);
                if (hasMandatoryFields == true) {

                    String forecastName = buildForecastNameFromTimeEntry(timeEntry);
                    timeEntryIdToForecastNameMap.put(timeEntry.Id, forecastName);   
                }else if(timeEntry.Replicon_Timesheet__c == null && timeEntry.entryDate__c != null && timeEntry.Employee__c != null && timeEntry.Project__c != null && timeEntry.Replicon_User_Number__c != null && (timeEntry.Project__c == placeholderProjectId || (Test.isRunningTest() && timeEntry.Replicon_Project_URI__c == 'urn:replicon-tenant:levementum:project:26030'))){ //For Placeholder Entries to create a Forecast Record
                    Date startDate = timeEntry.entryDate__c.toStartOfWeek();
                    Date endDate = timeEntry.entryDate__c.toStartOfWeek().addDays(6);
                    String timesheetStartString = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('MM/dd/YYYY');
                    String timesheetEndString = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day()).format('MM/dd/YYYY');
                    String employeeRepliconNum = timeEntry.Replicon_User_Number__c;
                    String projectRepliconId = '26030'; //Hard Coded Lev - Internal Placeholder Project URI

                    List<String> forecastDataPointList = new List<String>{
                        timesheetStartString, 
                        timesheetEndString, 
                        employeeRepliconNum, 
                        projectRepliconId
                    };
                    String forecastName = String.join(forecastDataPointList, '-');
                    timeEntryIdToForecastNameMap.put(timeEntry.Id, forecastName); 
                }
            }

            // Retrieve matching Forecast records by expected name
            List<RepliconForecast__c> matchingForecastList = [
                SELECT Id, Name, Project__c, Deleted_in_Replicon__c
                FROM RepliconForecast__c
                WHERE Name IN :timeEntryIdToForecastNameMap.values()
                ORDER BY EstimatedHours__c
            ];
            
            // Map forecast records by name for retrieval during population
            Map<String, Id> forecastNameToIdMap = new Map<String, Id>();
            Map<String, RepliconForecast__c> forecastNameToForecastRecordMap = new Map<String, RepliconForecast__c>();
            for (RepliconForecast__c forecast : matchingForecastList) {
                forecastNameToIdMap.put(forecast.Name, forecast.Id);
                forecastNameToForecastRecordMap.put(forecast.Name, forecast);
            }
            
            // Build new forecast records for any time entries that do not have an existing match already
            List<RepliconForecast__c> forecastInsertList = new List<RepliconForecast__c>();
            Set<RepliconForecast__c> forecastInsertSet = new Set<RepliconForecast__c>(); //Added Set here instead of List to prevent multiple Forecast objects from being created when only one is needed. 2/7/22 ST
            for (Replicon_Time_Entry__c timeEntry : newList) {

                String forecastName = timeEntryIdToForecastNameMap.get(timeEntry.Id);
                if (forecastName != null) {

                    Id forecastId = forecastNameToIdMap.get(forecastName);
                    if (forecastId == null) {
                        RepliconForecast__c newForecast = buildForecastForTimeEntry(timeEntry, forecastName);
                        //forecastInsertList.add(newForecast);
                        forecastInsertSet.add(newForecast);
                    }
                }
            }

            // Insert and map new Forecast records
            /*if(forecastInsertList.size() > 0){
                insert forecastInsertList;
            }*/
            if(forecastInsertSet.size() > 0){
                forecastInsertList.addAll(forecastInsertSet);
                System.debug('****************** Inserting ' + forecastInsertList.size() + ' Forecast Records ******************');
                insert forecastInsertList; //2/7/22 ST
            }
            for (RepliconForecast__c newForecast : forecastInsertList) {
                forecastNameToIdMap.put(newForecast.Name, newForecast.Id);
            }

            // Populate time entry records with forecast lookup
            List<Replicon_Time_Entry__c> timeEntryUpdateList = new List<Replicon_Time_Entry__c>();
            List<RepliconForecast__c> forecastsToUndeleteList = new List<RepliconForecast__c>();
            for (Replicon_Time_Entry__c timeEntry : newList) {

                String forecastName = timeEntryIdToForecastNameMap.get(timeEntry.Id);
                if (forecastName != null) {

                    Id forecastId = forecastNameToIdMap.get(forecastName);
                    if (forecastId != null) {
                        Replicon_Time_Entry__c entryToUpdate = timeEntry.clone(true, false, true, true);
                        entryToUpdate.Replicon_Forecast__c = forecastId;
                        //Update from 5/17/2022 ST - To ensure that a Time Entry is not getting related to a deleted Forecast, and if so then we will undelete the forecast
                        if(forecastNameToForecastRecordMap.containsKey(forecastName) && forecastNameToForecastRecordMap.get(forecastName).Deleted_in_Replicon__c == true){
                            RepliconForecast__c forecastToUpdate = forecastNameToForecastRecordMap.get(forecastName);
                            forecastToUpdate.Deleted_in_Replicon__c = false;
                            forecastsToUndeleteList.add(forecastToUpdate);
                        }
                        timeEntryUpdateList.add(entryToUpdate);
                    }
                }
            }
            if(timeEntryUpdateList.size() > 0){
                System.debug('****************** Updating ' + timeEntryUpdateList.size() + ' Time Entry Records with Forecasts ******************');
                update timeEntryUpdateList;
            }
            if(forecastsToUndeleteList.size() > 0){
                System.debug('****************** Updating ' + forecastsToUndeleteList.size() + ' Forecast Records to mark as NOT deleted ******************');
                update forecastsToUndeleteList;
            }
        }
        catch (Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'populateTimeEntryForecastLookup', NULL);
            if(!System.Test.isRunningTest()) this.sendError(e.getMessage());
        }
    }

    private static Boolean checkNullsForForecastAssmt(Replicon_Time_Entry__c timeEntry) {
        Boolean hasAllFields = true;
        for (String mandatoryField : FORECAST_ASSMT_MANDATORY_FIELDS) {
            if (timeEntry.get(mandatoryField) == null) {
                hasAllFields = false;
            }
        }
        return hasAllFields;
    }

    private static RepliconForecast__c buildForecastForTimeEntry(Replicon_Time_Entry__c timeEntry, String forecastName) {
        RepliconForecast__c forecast = new RepliconForecast__c();
        forecast.Name = forecastName;
        forecast.Project__c = timeEntry.Project__c;
        forecast.Contact__c = timeEntry.Employee__c;
        forecast.NotForecasted__c = true;
        forecast.Week_Start_Date__c = timeEntry.Timesheet_Period__c;
        forecast.Week_End_Date__c = timeEntry.WeekEndDate__c;
        return forecast;
    }

    @TestVisible
    private static String buildForecastNameFromTimeEntry(Replicon_Time_Entry__c timeEntry) {
        Date sd = timeEntry.Timesheet_Period__c;
        Date ed = timeEntry.WeekEndDate__c;
        String timesheetStartString = DateTime.newInstance(sd.year(), sd.month(), sd.day()).format('MM/dd/YYYY');
        String timesheetEndString = DateTime.newInstance(ed.year(), ed.month(), ed.day()).format('MM/dd/YYYY');

        String employeeRepliconNum = timeEntry.Replicon_User_Number__c;
        //String projectRepliconId = timeEntry.Replicon_Project_URI__c.right(4);
        String projectRepliconId = timeEntry.Replicon_Project_URI__c.substringAfterLast(':');

        List<String> forecastDataPointList = new List<String>{
            timesheetStartString, 
            timesheetEndString, 
            employeeRepliconNum, 
            projectRepliconId
        };
        String forecastName = String.join(forecastDataPointList, '-');
        return forecastName;
    }
    
    //Calculates rollup values from time entry to project. This will fail if the projects in the transaction have 50,000 child time entries. 
    //If you want to add a new calculated rollup, just go down to the part with 4 steps and update the test code.
    //James Qian, September 2018
    public void calculateProjectRollupValues(Set<Id> projectIdSet) {
        try {
            //Set current dates 
            Date todaysDate = Date.today();
            Integer currentMonth = todaysDate.month();
            Integer currentYear = todaysDate.year();
            Date dateOfPreviousSaturday = todaysDate.toStartOfWeek().addDays(-1); //Added 5/4/2022 - Goes to the Sunday of todays Week, then goes one more day back to get the previous Saturday

            Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

            //Get all project IDs in trigger.new for querying existing records
            List<Project__c> projectUpdateList = new List<Project__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentProjectMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            List<Id> projectIdsWithNoActiveTimeEntriesList = new List<Id>();
            Map<Id, Project__c> projectWithNoActiveEntriesUpdateMap = new Map<Id, Project__c>();
            for(Id projId : projectIdSet) {
                //if(currentEntry.Project__c != NULL && !currentEntry.Deleted_in_Replicon__c) { Commented this out 4/19 Sam Tucker
                //Added on 4/19 - Sam Tucker
                if(projId != NULL && projId != levPTOProjectId) {
                    parentProjectMap.put(projId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }

            Map<Id, Replicon_Time_Entry__c> projectIdToProjectRelationshipFieldsMap = new Map<Id, Replicon_Time_Entry__c>();
            //Query existing records and put into a map for searching/deduplication
            if(parentProjectMap.keyset().size() > 0) {
                //Step 1 - Add to query
                List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, ActivityName__c,
                                                                           Override_Billing_Rate__c, TotalHrs__c, Project__c, Deleted_in_Replicon__c, EntryDate__c, Project__r.Name,
                                                                           Project__r.Rollup_Billable__c , Project__r.Rollup_Concession__c, Project__r.Rollup_Nonbillable__c, Project__r.Rollup_Revenue__c,
                                                                           Project__r.Replicon_Hours_This_Month__c, Project__r.PreviousWeeksBillableHrs__c, Project__r.BudgetRemainingasofPrevWeek__c,  Project__r.BCPNonbillableHours__c,
                                                                           Project__r.NonLevTotalNonBillableHours__c, Project__r.NonLevRevenueAmountBooked__c, Project__r.NonLevNonBillHours__c, Project__r.NonLevBillableHoursBooked__c,
                                                                           Employee__r.Name, Employee__r.Account.Name
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Project__c IN :parentProjectMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false];

                if(queriedExistingTimeEntries.size() > 0){
                    
                    for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                        Map<Id, Replicon_Time_Entry__c> projectTimeEntryMap = parentProjectMap.get(queriedTimeEntry.Project__c);
                        projectTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                        parentProjectMap.put(queriedTimeEntry.Project__c, projectTimeEntryMap); 
                        if(!projectIdToProjectRelationshipFieldsMap.containsKey(queriedTimeEntry.Project__c)){
                            projectIdToProjectRelationshipFieldsMap.put(queriedTimeEntry.Project__c, queriedTimeEntry);
                        }
                    }
                }

                for(Id projectID : parentProjectMap.keyset()){
                    //Loop through Project
                    if(!projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                        projectIdsWithNoActiveTimeEntriesList.add(projectID);
                    }
                }

                if(projectIdsWithNoActiveTimeEntriesList.size() > 0){
                    Map<Id, Project__c> projWithNoActiveEntriesMap = new Map<Id, Project__c>([SELECT Id, Name, Rollup_Billable__c , Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c,
                                                                                                Replicon_Hours_This_Month__c, PreviousWeeksBillableHrs__c, BudgetRemainingasofPrevWeek__c, 
                                                                                                NonLevTotalNonBillableHours__c, NonLevRevenueAmountBooked__c, NonLevNonBillHours__c, NonLevBillableHoursBooked__c, BCPNonbillableHours__c
                                                                                                FROM Project__c 
                                                                                                WHERE Id IN :projectIdsWithNoActiveTimeEntriesList]);
                    if(projWithNoActiveEntriesMap.size() > 0){
                        projectWithNoActiveEntriesUpdateMap.putAll(projWithNoActiveEntriesMap); 
                    }
                }
            }

            //Loop through structure to calculate rollup values
            for(Id projectID : parentProjectMap.keyset()) {

                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupRevenue = 0;
                Decimal rollupBillableHoursThisMonth = 0;
                Decimal rollupPreviousWeeksBillableHours = 0;
                Decimal rollupBudgetRemainingAsOfPrevWeek = 0;
                Decimal rollupBCPNonBillHours = 0; //Added 9.2.22 ST To rollup BCP Non Bill Hours

                //Lev and Non Lev Rollups
                Decimal levBillableHours = 0;
                Decimal nonLevBillableHours = 0;
                Decimal levNonBillableHours = 0;
                Decimal nonLevNonBillableHours = 0;
                Decimal levConcessionHours = 0;
                Decimal nonLevConcessionHours = 0;
                Decimal levRevenue = 0;
                Decimal nonLevRevenue = 0;
                Decimal nonLevTotalNonBillAndConcessionHours = 0;
                Decimal levBillableHoursAsOfLastWeek = 0;
                Decimal nonLevBillableHoursAsOfLastWeek = 0;
                Decimal levRevenueAmountAsOfLastWeek = 0;
                Decimal nonLevRevenueAmountAsOfLastWeek = 0;
                
                
                for(Id timeEntryID : parentProjectMap.get(projectID).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentProjectMap.get(projectID).get(timeEntryID);

                    Boolean isLevTime = false;
                    if((currentEntry.EntryDate__c < switchToATGTimeDate && currentEntry.Employee__r.Name != atgConsultantContactName) 
                    || (currentEntry.EntryDate__c >= switchToATGTimeDate && currentEntry.Employee__r.Account.Name == levementumAccountName && currentEntry.Employee__r.Name != atgConsultantContactName)){
                        isLevTime = true;
                    }

                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true && currentEntry.TotalHrs__c != null){
                        //New Rollup Calculation Step 2 - Criteria
                        if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Billable Hours
                            if(isLevTime){
                                levBillableHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevBillableHours += currentEntry.TotalHrs__c;
                            }

                            //Replicon Billable Hours for Current Month DLRS Replacement
                            if(currentEntry.EntryDate__c.month() == currentMonth && currentEntry.EntryDate__c.year() == currentYear){
                                rollupBillableHoursThisMonth += currentEntry.TotalHrs__c;
                            }
                            //Replicon Billable Hours as of Previous Week DLRS Replacement 
                            //Replicon Budget Remaining as of Previous Week DLRS Replacement
                            if(currentEntry.EntryDate__c <= dateOfPreviousSaturday){
                                //Changing Total Hours/Budget as of last week to Lev only ST 4.3.23
                                if(isLevTime){
                                    System.debug('currentEntry.TotalHrs__c: ' + currentEntry.TotalHrs__c);
                                    rollupPreviousWeeksBillableHours += currentEntry.TotalHrs__c;
                                    rollupBudgetRemainingAsOfPrevWeek += currentEntry.Billable_Amount__c;
                                }

                                //Lev or Non Lev Hours and Revenue as of Last Week
                                if(isLevTime){
                                    levBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    levRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }else{
                                    nonLevBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    nonLevRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }
                            }
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;

                            //Lev or Non Lev Concession Hours
                            if(isLevTime){
                                levConcessionHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevConcessionHours += currentEntry.TotalHrs__c;
                            }

                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Non Billable Hours
                            if(isLevTime){
                                if(currentEntry.ActivityName__c == 'BCP'){
                                    rollupBCPNonBillHours += currentEntry.TotalHrs__c; //Added 9.2.22 ST
                                }else{
                                    levNonBillableHours += currentEntry.TotalHrs__c;
                                }
                            }else{
                                nonLevNonBillableHours += currentEntry.TotalHrs__c;
                            }
                        }
                        if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
                            rollupRevenue += currentEntry.Billable_Amount__c;

                            //Lev or Non-Lev Revenue
                            if(isLevTime){
                                levRevenue += currentEntry.Billable_Amount__c;
                            }else{
                                nonLevRevenue += currentEntry.Billable_Amount__c;
                            }
                        }

                        nonLevTotalNonBillAndConcessionHours = nonLevNonBillableHours + nonLevConcessionHours;

                    }
                }

                //Lev and Non Lev Project Rollup ST 6/22/2022
                if(projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                    Replicon_Time_Entry__c projectRelatedEntry = projectIdToProjectRelationshipFieldsMap.get(projectID);

                    if(projectRelatedEntry.Project__r.Rollup_Billable__c != levBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Concession__c != levConcessionHours 
                    || projectRelatedEntry.Project__r.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Revenue__c != levRevenue 
                    || projectRelatedEntry.Project__r.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectRelatedEntry.Project__r.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectRelatedEntry.Project__r.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectRelatedEntry.Project__r.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectRelatedEntry.Project__r.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectRelatedEntry.Project__r.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectRelatedEntry.Project__r.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectRelatedEntry.Project__r.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }
                }else if(projectWithNoActiveEntriesUpdateMap.containsKey(projectID)){
                    Project__c projectToUpdate = projectWithNoActiveEntriesUpdateMap.get(projectID);

                    if(projectToUpdate.Rollup_Billable__c != levBillableHours 
                    || projectToUpdate.Rollup_Concession__c != levConcessionHours 
                    || projectToUpdate.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectToUpdate.Rollup_Revenue__c != levRevenue 
                    || projectToUpdate.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectToUpdate.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectToUpdate.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectToUpdate.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectToUpdate.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectToUpdate.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectToUpdate.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectToUpdate.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }



                }
            }

            /************************************************************************************************************************/

            if(projectUpdateList.size() > 0) {
                System.debug('***************************Updating ' + projectUpdateList.size() + ' Project Rollup Values*******************************');
                update projectUpdateList;
            }else{
                System.debug('***************************No Project Rollup Values Calculated*******************************');
            }            
        }
        catch(Exception e) {
            System.debug('calculateProjectRollupValues');
            System.debug(e);
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateProjectRollupValues', NULL);
        }
    }

    @future(callout=false)
    public static void calculateProjectRollupValuesFuture(Set<Id> projectIdSet) {
        try {
            String levPTOProjectId = 'a1q6T000003v4mFQAQ';
            //Set current dates 
            Date todaysDate = Date.today();
            Integer currentMonth = todaysDate.month();
            Integer currentYear = todaysDate.year();
            Date dateOfPreviousSaturday = todaysDate.toStartOfWeek().addDays(-1); //Added 5/4/2022 - Goes to the Sunday of todays Week, then goes one more day back to get the previous Saturday

            Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

            //Get all project IDs in trigger.new for querying existing records
            List<Project__c> projectUpdateList = new List<Project__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentProjectMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            List<Id> projectIdsWithNoActiveTimeEntriesList = new List<Id>();
            Map<Id, Project__c> projectWithNoActiveEntriesUpdateMap = new Map<Id, Project__c>();
            for(Id projId : projectIdSet) {
                //if(currentEntry.Project__c != NULL && !currentEntry.Deleted_in_Replicon__c) { Commented this out 4/19 Sam Tucker
                //Added on 4/19 - Sam Tucker
                if(projId != NULL && projId != levPTOProjectId) {
                    parentProjectMap.put(projId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }

            Map<Id, Replicon_Time_Entry__c> projectIdToProjectRelationshipFieldsMap = new Map<Id, Replicon_Time_Entry__c>();
            //Query existing records and put into a map for searching/deduplication
            if(parentProjectMap.keyset().size() > 0) {
                //Step 1 - Add to query
                List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, ActivityName__c,
                                                                           Override_Billing_Rate__c, TotalHrs__c, Project__c, Deleted_in_Replicon__c, EntryDate__c, Project__r.Name,
                                                                           Project__r.Rollup_Billable__c , Project__r.Rollup_Concession__c, Project__r.Rollup_Nonbillable__c, Project__r.Rollup_Revenue__c,
                                                                           Project__r.Replicon_Hours_This_Month__c, Project__r.PreviousWeeksBillableHrs__c, Project__r.BudgetRemainingasofPrevWeek__c,  Project__r.BCPNonbillableHours__c,
                                                                           Project__r.NonLevTotalNonBillableHours__c, Project__r.NonLevRevenueAmountBooked__c, Project__r.NonLevNonBillHours__c, Project__r.NonLevBillableHoursBooked__c,
                                                                           Employee__r.Name, Employee__r.Account.Name
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Project__c IN :parentProjectMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false];

                if(queriedExistingTimeEntries.size() > 0){
                    
                    for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                        Map<Id, Replicon_Time_Entry__c> projectTimeEntryMap = parentProjectMap.get(queriedTimeEntry.Project__c);
                        projectTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                        parentProjectMap.put(queriedTimeEntry.Project__c, projectTimeEntryMap); 
                        if(!projectIdToProjectRelationshipFieldsMap.containsKey(queriedTimeEntry.Project__c)){
                            projectIdToProjectRelationshipFieldsMap.put(queriedTimeEntry.Project__c, queriedTimeEntry);
                        }
                    }
                }

                for(Id projectID : parentProjectMap.keyset()){
                    //Loop through Project
                    if(!projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                        projectIdsWithNoActiveTimeEntriesList.add(projectID);
                    }
                }

                if(projectIdsWithNoActiveTimeEntriesList.size() > 0){
                    Map<Id, Project__c> projWithNoActiveEntriesMap = new Map<Id, Project__c>([SELECT Id, Name, Rollup_Billable__c , Rollup_Concession__c, Rollup_Nonbillable__c, Rollup_Revenue__c,
                                                                                                Replicon_Hours_This_Month__c, PreviousWeeksBillableHrs__c, BudgetRemainingasofPrevWeek__c, 
                                                                                                NonLevTotalNonBillableHours__c, NonLevRevenueAmountBooked__c, NonLevNonBillHours__c, NonLevBillableHoursBooked__c, BCPNonbillableHours__c
                                                                                                FROM Project__c 
                                                                                                WHERE Id IN :projectIdsWithNoActiveTimeEntriesList]);
                    if(projWithNoActiveEntriesMap.size() > 0){
                        projectWithNoActiveEntriesUpdateMap.putAll(projWithNoActiveEntriesMap); 
                    }
                }
            }

            //Loop through structure to calculate rollup values
            for(Id projectID : parentProjectMap.keyset()) {

                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupRevenue = 0;
                Decimal rollupBillableHoursThisMonth = 0;
                Decimal rollupPreviousWeeksBillableHours = 0;
                Decimal rollupBudgetRemainingAsOfPrevWeek = 0;
                Decimal rollupBCPNonBillHours = 0; //Added 9.2.22 ST To rollup BCP Non Bill Hours

                //Lev and Non Lev Rollups
                Decimal levBillableHours = 0;
                Decimal nonLevBillableHours = 0;
                Decimal levNonBillableHours = 0;
                Decimal nonLevNonBillableHours = 0;
                Decimal levConcessionHours = 0;
                Decimal nonLevConcessionHours = 0;
                Decimal levRevenue = 0;
                Decimal nonLevRevenue = 0;
                Decimal nonLevTotalNonBillAndConcessionHours = 0;
                Decimal levBillableHoursAsOfLastWeek = 0;
                Decimal nonLevBillableHoursAsOfLastWeek = 0;
                Decimal levRevenueAmountAsOfLastWeek = 0;
                Decimal nonLevRevenueAmountAsOfLastWeek = 0;
                
                
                for(Id timeEntryID : parentProjectMap.get(projectID).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentProjectMap.get(projectID).get(timeEntryID);

                    Boolean isLevTime = false;
                    if((currentEntry.EntryDate__c < switchToATGTimeDate && currentEntry.Employee__r.Name != atgConsultantContactName) 
                    || (currentEntry.EntryDate__c >= switchToATGTimeDate && currentEntry.Employee__r.Account.Name == levementumAccountName && currentEntry.Employee__r.Name != atgConsultantContactName)){
                        isLevTime = true;
                    }

                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true && currentEntry.TotalHrs__c != null){
                        //New Rollup Calculation Step 2 - Criteria
                        if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Billable Hours
                            if(isLevTime){
                                levBillableHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevBillableHours += currentEntry.TotalHrs__c;
                            }

                            //Replicon Billable Hours for Current Month DLRS Replacement
                            if(currentEntry.EntryDate__c.month() == currentMonth && currentEntry.EntryDate__c.year() == currentYear){
                                rollupBillableHoursThisMonth += currentEntry.TotalHrs__c;
                            }
                            //Replicon Billable Hours as of Previous Week DLRS Replacement 
                            //Replicon Budget Remaining as of Previous Week DLRS Replacement
                            if(currentEntry.EntryDate__c <= dateOfPreviousSaturday){
                                //Changing Total Hours/Budget as of last week to Lev only ST 4.3.23
                                if(isLevTime){
                                    rollupPreviousWeeksBillableHours += currentEntry.TotalHrs__c;
                                    rollupBudgetRemainingAsOfPrevWeek += currentEntry.Billable_Amount__c;
                                }

                                //Lev or Non Lev Hours and Revenue as of Last Week
                                if(isLevTime){
                                    levBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    levRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }else{
                                    nonLevBillableHoursAsOfLastWeek += currentEntry.TotalHrs__c;
                                    nonLevRevenueAmountAsOfLastWeek += currentEntry.Billable_Amount__c;
                                }
                            }
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;

                            //Lev or Non Lev Concession Hours
                            if(isLevTime){
                                levConcessionHours += currentEntry.TotalHrs__c;
                            }else{
                                nonLevConcessionHours += currentEntry.TotalHrs__c;
                            }

                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;

                            //Lev or Non-Lev Non Billable Hours
                            if(isLevTime){
                                if(currentEntry.ActivityName__c == 'BCP'){
                                    rollupBCPNonBillHours += currentEntry.TotalHrs__c; //Added 9.2.22 ST
                                }else{
                                    levNonBillableHours += currentEntry.TotalHrs__c;
                                }
                            }else{
                                nonLevNonBillableHours += currentEntry.TotalHrs__c;
                            }
                        }
                        if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
                            rollupRevenue += currentEntry.Billable_Amount__c;

                            //Lev or Non-Lev Revenue
                            if(isLevTime){
                                levRevenue += currentEntry.Billable_Amount__c;
                            }else{
                                nonLevRevenue += currentEntry.Billable_Amount__c;
                            }
                        }

                        nonLevTotalNonBillAndConcessionHours = nonLevNonBillableHours + nonLevConcessionHours;

                    }
                }

                //Lev and Non Lev Project Rollup ST 6/22/2022
                if(projectIdToProjectRelationshipFieldsMap.containsKey(projectID)){
                    Replicon_Time_Entry__c projectRelatedEntry = projectIdToProjectRelationshipFieldsMap.get(projectID);

                    if(projectRelatedEntry.Project__r.Rollup_Billable__c != levBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Concession__c != levConcessionHours 
                    || projectRelatedEntry.Project__r.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectRelatedEntry.Project__r.Rollup_Revenue__c != levRevenue 
                    || projectRelatedEntry.Project__r.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectRelatedEntry.Project__r.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectRelatedEntry.Project__r.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectRelatedEntry.Project__r.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectRelatedEntry.Project__r.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectRelatedEntry.Project__r.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectRelatedEntry.Project__r.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectRelatedEntry.Project__r.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }
                }else if(projectWithNoActiveEntriesUpdateMap.containsKey(projectID)){
                    Project__c projectToUpdate = projectWithNoActiveEntriesUpdateMap.get(projectID);

                    if(projectToUpdate.Rollup_Billable__c != levBillableHours 
                    || projectToUpdate.Rollup_Concession__c != levConcessionHours 
                    || projectToUpdate.Rollup_Nonbillable__c != levNonBillableHours 
                    || projectToUpdate.Rollup_Revenue__c != levRevenue 
                    || projectToUpdate.Replicon_Hours_This_Month__c != rollupBillableHoursThisMonth 
                    || projectToUpdate.PreviousWeeksBillableHrs__c != rollupPreviousWeeksBillableHours
                    || projectToUpdate.BudgetRemainingasofPrevWeek__c != rollupBudgetRemainingAsOfPrevWeek
                    || projectToUpdate.NonLevBillableHoursBooked__c != nonLevBillableHours
                    || projectToUpdate.NonLevNonBillHours__c != nonLevNonBillableHours
                    || projectToUpdate.NonLevRevenueAmountBooked__c != nonLevRevenue
                    || projectToUpdate.NonLevTotalNonBillableHours__c != nonLevTotalNonBillAndConcessionHours
                    || projectToUpdate.BCPNonbillableHours__c != rollupBCPNonBillHours){
                        //New Rollup Calculation Step 3 - Assignment
                        projectUpdateList.add(new Project__c(Id = projectID, 
                                                     Rollup_Billable__c = levBillableHours,
                                                     Rollup_Concession__c = levConcessionHours,
                                                     Rollup_Nonbillable__c = levNonBillableHours,
                                                     Rollup_Revenue__c = levRevenue,
                                                     Replicon_Hours_This_Month__c = rollupBillableHoursThisMonth,
                                                     PreviousWeeksBillableHrs__c = rollupPreviousWeeksBillableHours,
                                                     BudgetRemainingasofPrevWeek__c = rollupBudgetRemainingAsOfPrevWeek,
                                                     NonLevBillableHoursBooked__c = nonLevBillableHours,
                                                     NonLevNonBillHours__c = nonLevNonBillableHours,
                                                     NonLevRevenueAmountBooked__c = nonLevRevenue,
                                                     NonLevTotalNonBillableHours__c = nonLevTotalNonBillAndConcessionHours,
                                                     BCPNonbillableHours__c = rollupBCPNonBillHours
                                                     ));
                    }



                }
            }

            /************************************************************************************************************************/

            if(projectUpdateList.size() > 0) {
                System.debug('***************************Updating ' + projectUpdateList.size() + ' Project Rollup Values*******************************');
                update projectUpdateList;
            }else{
                System.debug('***************************No Project Rollup Values Calculated*******************************');
            }            
        }
        catch(Exception e) {
            System.debug('calculateProjectRollupValuesFuture');
            System.debug(e);
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateProjectRollupValuesFuture', NULL);
        }
    }
    
    //Calculates rollup values from time entry to timesheet.
    //James Qian, October 2018
    public void calculateTimesheetRollupValues(Set<Id> timesheetIdSet) {
        try {
            List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentTimesheetMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            for(Id timesheetId : timesheetIdSet) {
                //if(currentEntry.Replicon_Timesheet__c != NULL && !currentEntry.Deleted_in_Replicon__c) {
                //Added on 4/19 - Sam Tucker
                if(timesheetId != NULL) {
                    parentTimesheetMap.put(timesheetId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }
            if(parentTimesheetMap.keyset().size() > 0) {
                List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, 
                                                                           Override_Billing_Rate__c, TotalHrs__c, Replicon_Timesheet__c, Time_Off__c, Deleted_in_Replicon__c, Replicon_Project_URI__c, Time_Off_Description__c
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Replicon_Timesheet__c IN :parentTimesheetMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false];

                for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                    Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = parentTimesheetMap.get(queriedTimeEntry.Replicon_Timesheet__c);
                    timesheetTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                    parentTimesheetMap.put(queriedTimeEntry.Replicon_Timesheet__c, timesheetTimeEntryMap); 
                }
            }
            
            //Commenting this out because it is unneccessary 5/18/2022 ST
            //Put all records from trigger.new into map for searching/deduplication
            /*for(Replicon_Time_Entry__c newTimeEntry : newList) {
                //if(newTimeEntry.Replicon_Timesheet__c != NULL && !newTimeEntry.Deleted_in_Replicon__c) {
                //Added on 4/19 - Sam Tucker
                if(newTimeEntry.Replicon_Timesheet__c != NULL) {
                    Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = parentTimesheetMap.get(newTimeEntry.Replicon_Timesheet__c);
                    timesheetTimeEntryMap.put(newTimeEntry.Id, newTimeEntry);
                    parentTimesheetMap.put(newTimeEntry.Replicon_Timesheet__c, timesheetTimeEntryMap); 
                }
            }*/
            
            //Loop through structure to calculate rollup values
            for(Id timesheetId : parentTimesheetMap.keyset()) {
                
                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupTotalHours = 40;
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupTotalTimeOff = 0;
                Decimal rollupTotalLOAHours = 0;
                
                for(Id timeEntryID : parentTimesheetMap.get(timesheetId).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentTimesheetMap.get(timesheetId).get(timeEntryID);
                    
                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true ){
                        //New Rollup Calculation Step 2 - Criteria
                        if(currentEntry.Time_Off__c) {
                            //Rollup LOA time
                            if(currentEntry.Time_Off_Description__c == 'LOA'){
                                rollupTotalLOAHours += currentEntry.TotalHrs__c;
                            }
                            rollupTotalHours -= currentEntry.TotalHrs__c;
                            rollupTotalTimeOff += currentEntry.TotalHrs__c;
                        }
                        else if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL || currentEntry.Replicon_Project_URI__c == 'urn:replicon-tenant:levementum:project:3689') {
                            rollupConcessionHours += currentEntry.TotalHrs__c;
                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;
                        }
                    }
                }
                
                //New Rollup Calculation Step 3 - Assignment
                timesheetUpdateList.add(new Replicon_Timesheet__c(Id = timesheetId, 
                                                                  Total_Billable_Hours__c = rollupBillableHours,
                                                                  Total_Concession_Hours__c = rollupConcessionHours,
                                                                  Total_Nonbillable_Hours__c = rollupNonBillableHours,
                                                                  Total_Hours__c = rollupTotalHours,
                                                                  Total_Time_Off_Hours__c = rollupTotalTimeOff,
                                                                  TotalLOAHours__c = rollupTotalLOAHours));
            }
            if(timesheetUpdateList.size() > 0) {
                update timesheetUpdateList;
            }
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateTimesheetRollupValues', NULL);
        }
    }

    @future(callout=false)
    public static void calculateTimesheetRollupValuesFuture(Set<Id> timesheetIdSet) {
        try {
            List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();
            Map<Id, Map<Id, Replicon_Time_Entry__c>> parentTimesheetMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
            for(Id timesheetId : timesheetIdSet) {
                //if(currentEntry.Replicon_Timesheet__c != NULL && !currentEntry.Deleted_in_Replicon__c) {
                //Added on 4/19 - Sam Tucker
                if(timesheetId != NULL) {
                    parentTimesheetMap.put(timesheetId, new Map<Id, Replicon_Time_Entry__c>()); 
                }
            }
            if(parentTimesheetMap.keyset().size() > 0) {
                List<Replicon_Time_Entry__c> queriedExistingTimeEntries = [SELECT Id, Associated_Billing_Rate__c, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, 
                                                                           Override_Billing_Rate__c, TotalHrs__c, Replicon_Timesheet__c, Time_Off__c, Deleted_in_Replicon__c, Time_Off_Description__c
                                                                           FROM Replicon_Time_Entry__c 
                                                                           WHERE Replicon_Timesheet__c IN :parentTimesheetMap.keyset()
                                                                           AND Deleted_in_Replicon__c = false];

                for(Replicon_Time_Entry__c queriedTimeEntry : queriedExistingTimeEntries) {
                    Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = parentTimesheetMap.get(queriedTimeEntry.Replicon_Timesheet__c);
                    timesheetTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                    parentTimesheetMap.put(queriedTimeEntry.Replicon_Timesheet__c, timesheetTimeEntryMap); 
                }
            }
            
            //Loop through structure to calculate rollup values
            for(Id timesheetId : parentTimesheetMap.keyset()) {
                
                //New Rollup Calculation Step 1 - Declaration
                Decimal rollupTotalHours = 40;
                Decimal rollupBillableHours = 0;
                Decimal rollupNonBillableHours = 0;
                Decimal rollupConcessionHours = 0;
                Decimal rollupTotalTimeOff = 0;
                Decimal rollupTotalLOAHours = 0;
                
                for(Id timeEntryID : parentTimesheetMap.get(timesheetId).keyset()) {
                    Replicon_Time_Entry__c currentEntry = parentTimesheetMap.get(timesheetId).get(timeEntryID);
                    
                    //Added on 4/19 - Sam Tucker
                    if(currentEntry.Deleted_in_Replicon__c != true ){
                        //New Rollup Calculation Step 2 - Criteria
                        if(currentEntry.Time_Off__c) {
                            //Rollup LOA time
                            if(currentEntry.Time_Off_Description__c == 'LOA'){
                                rollupTotalLOAHours += currentEntry.TotalHrs__c;
                            }
                            rollupTotalHours -= currentEntry.TotalHrs__c;
                            rollupTotalTimeOff += currentEntry.TotalHrs__c;
                        }
                        else if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;
                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;
                        }
                    }
                }
                
                //New Rollup Calculation Step 3 - Assignment
                timesheetUpdateList.add(new Replicon_Timesheet__c(Id = timesheetId, 
                                                                  Total_Billable_Hours__c = rollupBillableHours,
                                                                  Total_Concession_Hours__c = rollupConcessionHours,
                                                                  Total_Nonbillable_Hours__c = rollupNonBillableHours,
                                                                  Total_Hours__c = rollupTotalHours,
                                                                  Total_Time_Off_Hours__c = rollupTotalTimeOff,
                                                                  TotalLOAHours__c = rollupTotalLOAHours));
            }
            if(timesheetUpdateList.size() > 0) {
                update timesheetUpdateList;
            }
        }
        catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateTimesheetRollupValues', NULL);
        }
    }

    /**Calculate the rollups for Weekly Targets **/
    public void calculateWeeklyTargetActualsRollup(Set<Id> weeklyTargetIdSet) {
        try {
            System.debug('######calculateWeeklyTargetActualsRollup');
            //Get List of Weekly Targets to calculate Weekly Actuals for
            /*Set<Id> weeklyTargetIdSet = new Set<Id>();
            for(Replicon_Time_Entry__c entry : weeklyTargetIdSet){
                if(entry.WeeklyTarget__c != null){
                    weeklyTargetIdSet.add(entry.WeeklyTarget__c);
                }
            }*/
            if(weeklyTargetIdSet.size() > 0){
                //Query the sums of the Weekly Targets
                //6/6/2022 Added that the Employee of the Actuals to be rolled up to the Weekly Target Actuals must be on the Levementum LLC Account
                //Changed 8/9/2022 Changed that lev time is rolled up not just Levementum LLC time, since before June 1st 2022 ATG time is still included in Weekly Forecasts
                AggregateResult[] weeklyTargetActuals = [SELECT sum(Billable_Amount__c), WeeklyTarget__c
                                                            FROM Replicon_Time_Entry__c 
                                                            WHERE WeeklyTarget__c IN :weeklyTargetIdSet AND Deleted_in_Replicon__c = false AND Is_Billable__c = true AND Is_Lev_Time__c = true
                                                            GROUP BY WeeklyTarget__c];


                //Create Map of Weekly Target Id to Actual Hours from related Time Entries Sum
                Map<Id, Decimal> weeklyTargetIdToRollupActualsMap = new Map<Id, Decimal>();
                for(AggregateResult ar : weeklyTargetActuals){
                    Decimal rollupRevenue = (Decimal)ar.get('expr0');
                    Id weeklyTargetId = (Id)ar.get('WeeklyTarget__c');
                    weeklyTargetIdToRollupActualsMap.put(weeklyTargetId, rollupRevenue);
                }
                //Query the Weekly Targets that are getting updated
                List<Revenue_Forecast__c> relatedWeeklyTargetsList = new List<Revenue_Forecast__c>();
                relatedWeeklyTargetsList = [SELECT Id, WeeklyActuals__c FROM Revenue_Forecast__c WHERE Id IN :weeklyTargetIdToRollupActualsMap.keySet()];
                //Check to see if Weekly Target needs update on WeeklyActuals field, if they do add to update list and update if not leave them alone.
                List<Revenue_Forecast__c> weeklyTargetsToUpdateList = new List<Revenue_Forecast__c>();
                for(Revenue_Forecast__c weeklyTarget : relatedWeeklyTargetsList){
                    if(weeklyTargetIdToRollupActualsMap.containsKey(weeklyTarget.Id)){
                        if(weeklyTarget.WeeklyActuals__c != weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id)){
                            weeklyTarget.WeeklyActuals__c = weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id);
                            weeklyTargetsToUpdateList.add(weeklyTarget);
                        }
                    }
                }
                if(weeklyTargetsToUpdateList.size() > 0) {
                    update weeklyTargetsToUpdateList;
                }
            }
        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateWeeklyTargetActualsRollup', NULL);
        }
    }

    @future(callout=false)
    public static void calculateWeeklyTargetActualsRollupFuture(Set<Id> weeklyTargetIdList) {
        try {
            System.debug('######calculateWeeklyTargetActualsRollup FUTURE');

            if(weeklyTargetIdList.size() > 0){
                //Query the sums of the Weekly Targets
                //6/6/2022 Added that the Employee of the Actuals to be rolled up to the Weekly Target Actuals must be on the Levementum LLC Account
                //Changed 8/9/2022 Changed that lev time is rolled up not just Levementum LLC time, since before June 1st 2022 ATG time is still included in Weekly Forecasts
                AggregateResult[] weeklyTargetActuals = [SELECT sum(Billable_Amount__c), WeeklyTarget__c
                                                            FROM Replicon_Time_Entry__c 
                                                            WHERE WeeklyTarget__c IN :weeklyTargetIdList AND Deleted_in_Replicon__c = false AND Is_Billable__c = true AND Is_Lev_Time__c = true
                                                            GROUP BY WeeklyTarget__c];


                //Create Map of Weekly Target Id to Actual Hours from related Time Entries Sum
                Map<Id, Decimal> weeklyTargetIdToRollupActualsMap = new Map<Id, Decimal>();
                for(AggregateResult ar : weeklyTargetActuals){
                    Decimal rollupRevenue = (Decimal)ar.get('expr0');
                    Id weeklyTargetId = (Id)ar.get('WeeklyTarget__c');
                    weeklyTargetIdToRollupActualsMap.put(weeklyTargetId, rollupRevenue);
                }
                //Query the Weekly Targets that are getting updated
                List<Revenue_Forecast__c> relatedWeeklyTargetsList = new List<Revenue_Forecast__c>();
                relatedWeeklyTargetsList = [SELECT Id, WeeklyActuals__c FROM Revenue_Forecast__c WHERE Id IN :weeklyTargetIdToRollupActualsMap.keySet()];
                //Check to see if Weekly Target needs update on WeeklyActuals field, if they do add to update list and update if not leave them alone.
                List<Revenue_Forecast__c> weeklyTargetsToUpdateList = new List<Revenue_Forecast__c>();
                for(Revenue_Forecast__c weeklyTarget : relatedWeeklyTargetsList){
                    if(weeklyTargetIdToRollupActualsMap.containsKey(weeklyTarget.Id)){
                        if(weeklyTarget.WeeklyActuals__c != weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id)){
                            weeklyTarget.WeeklyActuals__c = weeklyTargetIdToRollupActualsMap.get(weeklyTarget.Id);
                            weeklyTargetsToUpdateList.add(weeklyTarget);
                        }
                    }
                }
                if(weeklyTargetsToUpdateList.size() > 0) {
                    update weeklyTargetsToUpdateList;
                }
            }
        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateWeeklyTargetActualsRollupFUTURE', NULL);
        }
    }
    /*********************************************/
   
    /**
     * Generates a report and parses the CSV results into an Apex object
     */
    public void generateReport(String reportUri) {
        // create payload to serialize into json
        Map<String, String> params = new Map<String, String>();
//        params.put('reportUri', 'urn:replicon-tenant:levementum:report:db07debf-e1a0-44ea-8ee9-14fe44bb2371');
        params.put('reportUri', reportUri);
        params.put('outputFormatUri', 'urn:replicon:report-output-format-option:csv');
        params.put('filterValues', '');
        system.debug('PARAMS: ' + JSON.serialize(params));

        // create http request with replicon headers
        HttpRequest req = this.getRequest('ReportService1.svc/GenerateReport');
        req.setBody(JSON.serialize(params));

        // send http request to replicon
        Http h = new Http();
        HttpResponse response = h.send(req);

        // deserialize response from replicon
        //TODO: check for and handle error returned
        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');
        String payload = (String) jsonMap.get('payload');

        // parse csv payload into string list
        List<List<String>> parsedPayload = this.parseCSV(payload, true);
        system.debug('PARSED PAYLOAD: ' + parsedPayload);

        /*processProjects(parsedPayload);
        processTimeOff(parsedPayload);*/

        processTimeEntries(parsedPayload);
    }

    /**
     * Creates and Updates a Project in Replicon with Opportunity and Project data
     * in Salesforce.
     *
     * @param project The Replicon Project apex wrapper object to upsert
     * @param projectId The Salesforce Project Id to update with the Replicon response data
     */
    public String upsertProject(Replicon.Project project, String projectId, Boolean updateSF) {
        //System.debug('target:'+ project.target);

        // serialize the project object for insertion into replicon
        String requestBody = project.toString().replace('currency_r','currency').replace('number_r','number');
        System.debug('requestBody'+ requestBody);

        // instantiate the request to send to replicon
        HttpRequest req = this.getRequest('ImportService1.svc/PutProject3');
        req.setBody(requestBody);

        // send the request to replicon to create a new project
        Http h = new Http();
        HttpResponse response = h.send(req);
        system.debug('[upsertProject] Response:' + response.getBody());

        // deserialize the response and prepare it for parsing
        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');
        //system.debug('[upsertProject] JSONMAP: ' + jsonMap);

        String projectURI= '';
        //check for and handle error responses
        if(dMap.containsKey('error')) {

            String errorMessage = 'Request Body:\n' + requestBody + '\n\nResponse:\n' + response.getBody();
            if(!Test.isRunningTest())
            {
                Map<String, Object> jsonMapError = (Map<String, Object>) dMap.get('error');
                if(!String.valueOf(jsonMapError.get('reason')).equalsIgnoreCase('the specified project already exists.')){
                    this.sendError(errorMessage);
                }
            }
        } else {
            // parse the response into an apex object
            Replicon.UpsertResponse parsedResponse = new Replicon.UpsertResponse(jsonMap);
            //system.debug('[upsertProject] Parsed Response: ' + parsedResponse);

            // update the project with the pardot unique id returned from the response

            projectURI = parsedResponse.uri;

//            if(updateSF==true){
//                Project__c updatedProject = new Project__c();
//                updatedProject.Id = projectId;
//                updatedProject.RepliconUri__c = parsedResponse.uri;
//                update updatedProject;
//            }

        }
        return projectURI;
    }

    public void UpdateProject(String jsonString)
    {
        System.debug('Project update Request: '+jsonString);
        HttpRequest req = this.getRequest('ProjectService1.svc/PutProjectInfo4');
        req.setBody(jsonString);

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');

        system.debug('Project Update Response: ' + response.getBody());
    }

    public void updateBillingRate(String requestUrl,String jsonString){
        System.debug('Request URL for Update Client/Billing/Hours: '+jsonString);
        HttpRequest req = this.getRequest(requestUrl);
        req.setBody(jsonString);

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');
        system.debug('Response from Update Client/Billing/Hours: ' + response.getBody());
        response = null;
        req= null;
    }

    public Boolean checkTask(String taskName,String projectUri)
    {
        HttpRequest req = this.getRequest('TaskService1.svc/GetChildrenTaskDetails');
        req.setBody('{"parentUri": "'+projectUri+'"}');

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> jsonMap =  (List<Object>) dMap.get('d');
        if(jsonMap.size()>0){
            for(Integer i=0;i<jsonMap.size();i++){
                //Map<String,Object> jj = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(jsonMap[i]));
                System.debug('jj------'+jsonMap[i]);
            }
        }

        System.debug('Check Task response:'+jsonMap);
        return false;
    }

    public void UpdateProjectEstimatedHours(String projectUri,String hrs){
        String jsonString = '{"projectUri": "'+projectUri+'","estimatedHours": {"hours": "'+hrs+'","minutes": "0","seconds": "0"}}';

        HttpRequest req = this.getRequest('ProjectService1.svc/UpdateEstimatedHours');
        req.setBody(jsonString);

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');

        system.debug('Project Update Hour Response: ' + jsonMap);
    }

    /*
        Replicon :: Task
     */
    public HttpResponse upsertTask(Replicon.Task task){

        HttpRequest req = this.getRequest('ProjectService1.svc/PutTask');
        String requestBody =  task.toString().replace('currency_r','currency').replace('number_r','number');

        system.debug('[upserttask] Request:' + requestBody);
        req.setBody(requestBody);

        Http h = new Http();
        HttpResponse response = h.send(req);
        system.debug('[upsertTask] Response:' + response.getBody());

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');
        //system.debug('[replconChangeOrder] JSONMAP Task: ' + jsonMap);

        if(dMap.containsKey('error')){
            String errorMessage = 'Request Body:\n' + requestBody + '\n\nResponse:\n' + response.getBody();
            if(!Test.isRunningTest()) this.sendError(errorMessage);
        }
        return response;
    }

    /**
     * Creates and Updates a Client in Replicon with Account data in Salesforce.
     */
    public String upsertClient(Replicon.Client client, String accountId) {
        // serialize the client object for insertion into replicon
        String requestBody = client.toString();
        system.debug('[upsertClient] Payload: ' + requestBody);

        // instantiate the request to send to replicon
        HttpRequest req = this.getRequest('ClientService1.svc/PutClient');
        req.setBody(requestBody);

        // send the request to replicon to create a new project
        Http h = new Http();
        HttpResponse response = h.send(req);
        system.debug('[upsertClient] Response:' + response.getBody());

        // deserialize the response and prepare it for parsing
        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> jsonMap = (Map<String, Object>) dMap.get('d');
        system.debug('[upsertClient] JSONMAP: ' + jsonMap);

        String clientUrl='';
        //check for and handle error responses
        if(dMap.containsKey('error')) {
            // create email body with request and response payloads
            String errorMessage = 'Request Body:\n' + requestBody + '\n\nResponse:\n' + response.getBody();
            System.debug(errorMessage);
            // send email when error occurs with record details if not executed from a unit test
           if(!Test.isRunningTest()) this.sendError(errorMessage);
        } else {
            // parse the response into an apex object
            Replicon.UpsertResponse parsedResponse = new Replicon.UpsertResponse(jsonMap);
            system.debug('[upsertClient] Parsed CLient Response: ' + parsedResponse);
            //updateAcc(accountId,parsedResponse.uri);
            // update the project with the pardot unique id returned from the response
            clientUrl = parsedResponse.uri;
        }
        return clientUrl;
    }

    public List<Map<String, Object>> customFieldResponse(String uri){

        HttpRequest req = this.getRequest('CustomFieldService1.svc/GetAllCustomFieldDropDownOptions');
        req.setBody('{"customFieldUri":"'+uri+'"}');
        req.setMethod('GET');

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Map<String, Object>> myMaps = new List<Map<String, Object>>();
        List<Object> myMapObjects = (List<Object>) dMap.get('d');
        for (Object obj : myMapObjects) {
            myMaps.add((Map<String, Object>)obj);
        }
        System.debug(myMaps);

        return myMaps;
    }

    private void processTimeEntries(List<List<String>> parsedPayload) {

        List<String> csvColumns = new List<String>();
        csvColumns.add('User Name');
        csvColumns.add('Project Name');
        csvColumns.add('SalesforceId');
        csvColumns.add('Actual Billable Hours (Selected Dates)');
        csvColumns.add('Actual Non-Billable Hours (Selected Dates)');


        Map<String, Replicon.TimeEntry> timeEntryMap = new Map<String, Replicon.TimeEntry>();
        Integer i =1;
        for(String[] lineItem : parsedPayload) {
            try {
                String entryId = String.valueOf(i); //lineItem[6];
                Replicon.TimeEntry entry = (timeEntryMap.containsKey(entryId)) ? timeEntryMap.get(entryId) : new Replicon.TimeEntry();
                entry.username = lineItem[0];
                entry.projectName = lineItem[3];
                entry.hours = Decimal.valueOf(lineItem[5]);
                timeEntryMap.put(entryId, entry);
                i++;

            } catch(ListException ex) {
                system.debug('--------------------------------------------------------------');
                system.debug('Error: ' + ex.getMessage());
                system.debug('Broken Line Item: ' + lineItem);
                system.debug('--------------------------------------------------------------\n');
            } catch(TypeException ex) {
                system.debug('--------------------------------------------------------------');
                system.debug('Type Error: ' + ex.getMessage());
                system.debug('Line Item: ' + lineItem);
                system.debug('Hours: ' + lineItem[8]);
                system.debug('Hours Split: ' + lineItem[8].split(':'));
                system.debug('--------------------------------------------------------------\n');
            }

        }
        system.debug('Entries: ' + timeEntryMap.values());
        system.debug('Total Entries: ' + timeEntryMap.size());
    }

    @TestVisible
    private Date parseDate(String value) {
        String[] dateObj = value.replace(',', '').replace('"', '').split(' ');
        return Date.newInstance(Integer.valueOf(dateObj[2]), this.getMonth(dateObj[0]), Integer.valueOf(dateObj[1]));
    }
    
    @TestVisible
    private Integer getMonth(String month) {
        switch on month.toUpperCase() {
            when 'JAN' { return 1; }
            when 'FEB' { return 2; }
            when 'MAR' { return 3; }
            when 'APR' { return 4; }
            when 'MAY' { return 5; }
            when 'JUN' { return 6; }
            when 'JUL' { return 7; }
            when 'AUG' { return 8; }
            when 'SEP' { return 9; }
            when 'OCT' { return 10; }
            when 'NOV' { return 11; }
            when 'DEC' { return 12; }
            when else { return 0; }
        }
    }

    private HttpRequest getRequest(String endpoint) {

        Blob headerValue = Blob.valueOf(COMPANY_KEY + '\\' + AUTH_USERNAME + ':' + AUTH_PASSWORD);
        String authHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);

        //System.debug('JNR authHeader: ' + authHeader);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + endpoint);
        //req.setEndpoint('https://requestbin.fullcontact.com/rcyd4wrc');
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }

    private List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();

        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        contents = contents.replaceAll(',"""', ',"DBLQT').replaceall('""",', 'DBLQT",');
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        contents = contents.replaceAll('""', 'DBLQT');
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch(System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            // check for blank CSV lines (only commas)
            if(line.replaceAll(',', '').trim().length() == 0) break;

            List<String> fields = line.split('(?!\\B"[^"]*),(?![^"]*"\\B)');

            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if(field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                } else if(field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if(field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT', '"'));
                    makeCompositeField = false;
                } else if(makeCompositeField) {
                    compositeField += ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                }
            }

            allFields.add(cleanFields);
        }

        if(skipHeaders) allFields.remove(0);

        return allFields;
    }

    //Wrapper class for team member query
    //James Qian - August 2018
    private class TeamMemberWrapper {
        public Project_Team_Member__c projectTeamMember;
        public Datetime lastModifiedDate;
        public Map<String, Project_Team_Member_Billing_Rate__c> billingRateMap;
        public Id contactID;
        public Contact employee;
        public Id insertedTeamMemberId;
        public TeamMemberWrapper() {
            billingRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
        }
    }
    
    //Creates billing rate record from parameters
    //James Qian - August 2018
    private static Project_Team_Member_Billing_Rate__c createBillingRateRecord(Id teamMemberId, String name, Decimal rate, String repliconURI, Id projectId) { 
        Project_Team_Member_Billing_Rate__c newBillingRate = new Project_Team_Member_Billing_Rate__c();
        newBillingRate.Project_Team_Member__c = teamMemberId;
        newBillingRate.Name = name;
        newBillingRate.Hourly_Rate__c = rate;
        newBillingRate.Replicon_URI__c = repliconURI;
        newBillingRate.Project__c = projectId;
        return newBillingRate;
    }
    
    //Empty class for storing nulls from JSON deserialization
    //James Qian - August 2018
    public class obj {}
    
    public class jsonGenDate {}
    
    //Generates JSON for first time entry callout. This was originally created with JSONGenerator
	//but after an hour trying to get it to work I gave up and manually created the string.
    //James Qian - August 2018
    private String generateJSONGetTimesheetURIs(Date timesheetDate, List<Id> employeeIdList) {
        List<Contact> queriedEmployees = [SELECT Id, Name, Weekly_Target__c, Replicon_URI__c, RampTime__c, Ramp_End_Date__c, Active__c, Term_Date__c, Department, Division_New__c, Title, ReportsToId FROM Contact WHERE Id IN :employeeIdList];
        String jsonString = '{';
        jsonString += '"userUris":[';
        for(Contact currentEmployee : queriedEmployees) {
            jsonString += '"' + currentEmployee.Replicon_URI__c + '",';
            //<Contact URI, Contact>
            repliconToContactMap.put(currentEmployee.Replicon_URI__c, currentEmployee);
        }
        jsonString = jsonString.substring(0, jsonString.length() - 1);
        jsonString += '],"date":{"year":';
        jsonString += String.valueOf(timesheetDate.year());
        //jsonString += '2018';
        jsonString += ',"month":';
        //jsonString += '07';
        jsonString += String.valueOf(timesheetDate.month());
        jsonString += ',"day":';
        //jsonString += '17';
        jsonString += String.valueOf(timesheetDate.day());  
        jsonString += '},"timesheetGetOptionUri":"urn:replicon:timesheet-get-option:create-timesheet-if-necessary"}';
        //jsonString += '},"timesheetGetOptionUri":null}';
        return jsonString;
    }
    
    //Generates JSON for second time entry callout
    //James Qian - August 2018
    private String generateJSONGetTimesheetDetails(RepliconTimesheetURIWrapper deserializedResponse) {
	List<String> timeSheetURIs = new List<String>();
        for(RepliconTimesheetURIWrapper.d currentTimesheet : deserializedResponse.d) {
            //System.debug(currentTimesheet);
            if(currentTimesheet.timesheetForDate != NULL && currentTimesheet.timesheetForDate.timesheet != NULL) {
                timeSheetURIs.add(currentTimesheet.timesheetForDate.timesheet.uri);
                storedTimesheetURIs.add(currentTimesheet.timesheetForDate.timesheet.uri);
            }
        }
		String jsonString = '{"timesheetUris":[';
		for(String currentURI : timeSheetURIs) {
			jsonString += '"' + currentURI + '",';
		}
		jsonString = jsonString.substringBeforeLast(',');
        jsonString += ']}';
		return jsonString;
	} 
    
    //Converts timesheet wrapper into SF record
    //James Qian - August 2018
    private Replicon_Timesheet__c GetTimesheetRecordFromWrapper(RepliconTimeEntriesResponse.d wrapper) {
        Replicon_Timesheet__c newTimesheet = new Replicon_Timesheet__c();
        newTimesheet.Replicon_URI__c = wrapper.uri;
        newTimesheet.Start_Date__c = Date.newInstance(Integer.valueOf(wrapper.dateRange.startDate.year), Integer.valueOf(wrapper.dateRange.startDate.month), Integer.valueOf(wrapper.dateRange.startDate.day));
        newTimesheet.Status__c = wrapper.statusUri.substringAfter('timesheet-status:').Capitalize();
        return newTimesheet;
    }
    
    //Converts time entry wrapper into SF record
    //James Qian - August 2018
    private Replicon_Time_Entry__c GetTimeEntryFromWrapper(RepliconTimeEntriesResponse.TimeAllocations timeEntry) {
        Replicon_Time_Entry__c newEntry = new Replicon_Time_Entry__c();
        
        newEntry.Replicon_URI__c = timeEntry.uri;
        newEntry.Comments__c = timeEntry.comments;
        newEntry.TotalHrs__c = Decimal.valueOf(timeEntry.duration.hours);
        newEntry.TotalHrs__c += Decimal.valueOf(timeEntry.duration.minutes)/60;
        if(timeEntry.activity != NULL) {
            newEntry.ActivityName__c = timeEntry.activity.name;
        }
        if(timeEntry.project != NULL) {
            newEntry.ProjectCode__c = timeEntry.project.name;
            newEntry.Replicon_Project_URI__c = timeEntry.project.projectUri;
        }
        newEntry.EntryDate__c = Date.newInstance(timeEntry.dateValue.year, timeEntry.dateValue.month, timeEntry.dateValue.day);
        if(timeEntry.billingrate != NULL) {
            newEntry.Replicon_Billing_Rate_URI__c = timeEntry.billingrate.uri;
        }
        if(timeEntry.Task != NULL) {
            newEntry.TaskName__c = timeEntry.Task.DisplayText;
            newEntry.Replicon_Project_Task_URI__c = timeEntry.Task.uri;
        }
        if(timeEntry.user != NULL) {
            newEntry.UserID__c = timeEntry.user.slug;
        }
        if(timeEntry.timeOffType != NULL) {
            newEntry.Time_Off__c = true;
            newEntry.Time_Off_Description__c = timeEntry.timeOffType.displayText;
            newEntry.Comments__c = NULL;
            //Added 4/14 To give PTO a Replicon URI
            newEntry.Replicon_URI__c = timeEntry.correlatedTimeOffUri + String.valueOf(newEntry.EntryDate__c);
            //Added 7/20/2022 to stop duplicate PTO Entries from getting entered into SF
            //newEntry.Replicon_URI__c = timeEntry.user.uri + String.valueOf(newEntry.EntryDate__c) + String.valueOf(newEntry.TotalHrs__c);
            newEntry.Replicon_Project_URI__c = 'urn:replicon-tenant:levementum:project:30882'; //Associate PTO Entries with Lev - PTO Project
        }

        //System.debug('Check Replicon Service Here');
        newEntry.Deleted_in_Replicon__c = false;
        String timeEntryName = '';
        return newEntry;
    }
    
    private Replicon_Project_Task__c getTaskFromWrapper(RepliconProjectTaskResponse.d currentTask, Id projectId) {
        Replicon_Project_Task__c newTask = new Replicon_Project_Task__c();
        if(currentTask.ActualHoursTotal != NULL) {
            Decimal totalHours = Decimal.valueOf(currentTask.ActualHoursTotal.hours);
            totalHours += Decimal.valueOf(currentTask.ActualHoursTotal.minutes)/100*5/3;
            newTask.Actual_Hours_Total__c = totalHours;
        }
        if(currentTask.actualTimeEntryDateRange != NULL && currentTask.actualTimeEntryDateRange.startDate != NULL) {
            newTask.Start_Date__c = Date.newInstance(currentTask.actualTimeEntryDateRange.startDate.year, currentTask.actualTimeEntryDateRange.startDate.month, currentTask.actualTimeEntryDateRange.startDate.day);
        }
        if(currentTask.actualTimeEntryDateRange != NULL && currentTask.actualTimeEntryDateRange.endDate != NULL) {
            newTask.End_Date__c = Date.newInstance(currentTask.actualTimeEntryDateRange.endDate.year, currentTask.actualTimeEntryDateRange.endDate.month, currentTask.actualTimeEntryDateRange.endDate.day);
        }
        if(currentTask.isClosed != NULL) {
            newTask.Is_Closed__c = currentTask.isClosed;
        }
        if(currentTask.task != NULL) {
            newTask.name = currentTask.task.displayText.left(80);
            newTask.Replicon_URI__c = currentTask.task.uri;
        }
        newTask.Replicon_Synced_On__c = System.now();
        newTask.Project__c = projectId;
        return newTask;
    }
    
    //Checks if time entry record has changed compared to a time entry wrapper
    //James Qian - August 2018
    //Modified November 2018
    //Sam Tucker - March 2021 Add need for Update if incoming Billing Rate is null and existing entry has a billing Rate(Meaning it has been switched from Billable to Non-Billable)
    //||    ((timeEntry.project.projectUri != NULL && existingEntry.Project__r.RepliconURI__c != NULL) && (timeEntry.project.projectUri != existingEntry.Project__r.RepliconURI__c)) ||
    // May 5th 2022, Added to check if the existing Time Entry is marked as Deleted to mark that as a Time Entry for Update
    private Boolean TimeEntryNeedsUpdate(RepliconTimeEntriesResponse.TimeAllocations timeEntry, Replicon_Time_Entry__c existingEntry) {
        //System.debug('@@@timeEntry:: ' + timeEntry);
        //System.debug('@@@existingEntry:: ' + existingEntry);
        if((timeEntry.timeOffType == NULL && existingEntry.Comments__c != timeEntry.comments) ||
            (existingEntry.TotalHrs__c != Decimal.valueOf(timeEntry.duration.hours) + Decimal.valueOf(timeEntry.duration.minutes)/60) ||
            (timeEntry.project != NULL && (existingEntry.Replicon_Project_URI__c != timeEntry.project.projectUri || existingEntry.ProjectCode__c != timeEntry.project.name)) ||
          	(timeEntry.billingrate != NULL && existingEntry.Replicon_Billing_Rate_URI__c != timeEntry.billingrate.uri) ||
            (timeEntry.billingrate != NULL && existingEntry.Associated_Billing_Rate__c == NULL) ||
            (timeEntry.billingrate == NULL && existingEntry.Associated_Billing_Rate__c != NULL ) ||
            (timeEntry.timeOffType != NULL && existingEntry.Time_Off_Description__c != timeEntry.timeOffType.displayText) ||
            (timeEntry.Task != NULL && (existingEntry.Replicon_Project_Task_URI__c != timeEntry.Task.uri || existingEntry.TaskName__c != timeEntry.Task.DisplayText)) ||
            (existingEntry.EntryDate__c != Date.newInstance(timeEntry.dateValue.year, timeEntry.dateValue.month, timeEntry.dateValue.day)) ||
            (timeEntry.activity != NULL && existingEntry.ActivityName__c != timeEntry.activity.name) ||
            (existingEntry.Deleted_in_Replicon__c == true)) {
                System.debug('*****Entry ' + existingEntry.Id + ' Needs Update*****');
                return true;    
            }else{
                /*String[] newNameParts = timeEntry.user.displayText.split(', ');
                String[] existingNameParts = existingEntry.Name.split(' -');
                String nameFromResponse = newNameParts[1] + ' ' + newNameParts[0];
                String existingName = existingNameParts[0];
                if(nameFromResponse !=  existingName){
                    System.debug('****************************NAME CHANGE for ' + nameFromResponse + ' ******************************');
                    return true; 
                }*/
            }
        return false;
    }

    public static void calculateRollupsOnProject(Id projectId){
        try{
            List<Project__c> projectUpdateList = new List<Project__c>();
            List<Replicon_Time_Entry__c> projectTimeEntries = new List<Replicon_Time_Entry__c>();
            if (projectId != NULL){

                projectTimeEntries = [SELECT Id, Name, TotalHrs__c, Billable_Amount__c, Associated_Billing_Rate__c, Billing_Rate__c,
                                        Replicon_Billing_Rate_URI__c, Override_Billing_Rate__c, Project__c 
                                    FROM Replicon_Time_Entry__c
                                    WHERE Deleted_in_Replicon__c = false AND Project__c = :projectId];
            }

                if(projectTimeEntries.size() > 0) {
                
                    //New Rollup Calculation Step 1 - Declaration
                    Decimal rollupBillableHours = 0;
                    Decimal rollupNonBillableHours = 0;
                    Decimal rollupConcessionHours = 0;
                    Decimal rollupRevenue = 0;
                    
                    for(Replicon_Time_Entry__c currentEntry : projectTimeEntries){
                        
                        //New Rollup Calculation Step 2 - Criteria
                        if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                            rollupBillableHours += currentEntry.TotalHrs__c;
                        }
                        else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) {
                            rollupConcessionHours += currentEntry.TotalHrs__c;
                        }
                        else {
                            rollupNonBillableHours += currentEntry.TotalHrs__c;
                        }
                        if(currentEntry.Billable_Amount__c != NULL && currentEntry.Billable_Amount__c > 0) {
                            rollupRevenue += currentEntry.Billable_Amount__c;
                        }
                    }
                    
                    //New Rollup Calculation Step 3 - Assignment
                    projectUpdateList.add(new Project__c(Id = projectID, 
                                                            Rollup_Billable__c = rollupBillableHours,
                                                            Rollup_Concession__c = rollupConcessionHours,
                                                            Rollup_Nonbillable__c = rollupNonBillableHours,
                                                            Rollup_Revenue__c = rollupRevenue));
                }

            if(projectUpdateList.size() > 0) {
                update projectUpdateList;
            }

        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'calculateRollupsOnProject', NULL);
        }
    }

    @TestVisible
    private void sendError(String messageBody) {
        // instantiate new email to send
        try{
            //Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            //message.setToAddresses(new String[]{'repliconintegration@levementum.com'});
            //message.setToAddresses(new String[]{'samuel.tucker@cognizant.com'});
            //message.setSubject('Replicon Integration Error');
            //message.setPlainTextBody(messageBody);
            if(!Test.isRunningTest()) {
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
                LevExceptionHandler.logError(messageBody, 2526, 'RepliconService', 'sendError111', NULL);
            }
        }catch(Exception e) {
            LevExceptionHandler.logError(e, 'RepliconService', 'sendError', NULL);
        }
    }

}