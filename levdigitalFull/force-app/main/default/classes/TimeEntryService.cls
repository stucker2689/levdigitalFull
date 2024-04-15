public with sharing class TimeEntryService {

    //private final String placeholderProjectId = 'a1q6T000003v2K0QAI';
    //private final String levPTOProjectId = 'a1q6T000003v4mFQAQ';
    //private final String levementumAccountId = '001d000000JGuQaAAL';
    private static String internalCognizantConcessionProjectESAId = '1000382542';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);

    public static Map<Id, Contact> contactIdToRecordPublicMap = new Map<Id, Contact>();
    public static Map<Id, Project__c> projectIdToRecordPublicMap = new Map<Id, Project__c>();

    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId(); //RecordTypeId of the Weekly Target RT of Revenue Forecasts

    public static void populateTimeEntryUniqueName(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){

        try{

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){

                String uniqueEntryId = '';

                String cogEmployeeId = entry.Cognizant_Employee_Id__c != null ? String.valueOf(entry.Cognizant_Employee_Id__c) : 'null';
                String esaProjectId = entry.Peoplesoft_Project_Id__c != null ? String.valueOf(entry.Peoplesoft_Project_Id__c) : 'null';
                String entryDateFormattedString = entry.EntryDate__c != null ? String.valueOf(entry.EntryDate__c.Format()) : 'null';

                if(entry.Time_Off__c){
                    uniqueEntryId = cogEmployeeId + ' | ' + 'Time-off' + ' | ' + entryDateFormattedString + ' | ' + entry.Time_Off_Description__c;
                }else if(entry.Is_Concession__c){
                    //uniqueEntryId = String.valueOf(entry.Cognizant_Employee_Id__c) + ' | ' + String.valueOf(entry.Peoplesoft_Project_Id__c) + ' | ' + 'Concession' + ' | ' + String.valueOf(entry.EntryDate__c.Format()) + ' | ' + entry.ActivityName__c;
                    uniqueEntryId = cogEmployeeId + ' | ' + esaProjectId + ' | ' + 'Concession' + ' | ' + entryDateFormattedString + ' | ' + entry.ActivityName__c;
                }else{
                    uniqueEntryId = cogEmployeeId + ' | ' + esaProjectId + ' | ' + entry.Billing_Action__c + ' | ' + entryDateFormattedString + ' | ' + entry.ActivityName__c;
                }
                
                if(entry.Unique_Time_Entry_Id__c != uniqueEntryId){
                    entry.Unique_Time_Entry_Id__c = uniqueEntryId;
                    entryUpdateList.add(entry);
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('************************ Updating ' + entryUpdateList.size() + ' Time Entries with Unique Time Entry Ids ******************************');
                update entryUpdateList;
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryUniqueName', null);
        }
    }

    public static void populateTimeEntryEmployee(List<Replicon_Time_Entry__c> entryList,  Boolean needsUpdate){

    try{
        System.debug('START populateTimeEntryEmployee');

        Set<String> cognizantEmployeeIdSet = new Set<String>();
        Set<String> contactIdSet = new Set<String>();
        for(Replicon_Time_Entry__c entry : entryList){
            if(entry.Cognizant_Employee_Id__c != null){
                cognizantEmployeeIdSet.add(entry.Cognizant_Employee_Id__c);
            }else if(entry.Employee__c != null){
                contactIdSet.add(entry.Employee__c);
            }
        }

        List<Contact> relatedContacts = new List<Contact>();
        //Query for Contacts that have matching Cognizant Contact Ids of the inserted Time Entries
        /*relatedContacts = [SELECT Id, Name, Title, Department, Cognizant_Employee_ID__c, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId
                            FROM Contact 
                            WHERE Cognizant_Employee_ID__c IN :cognizantEmployeeIdSet OR Id IN :contactIdSet];*/

        Map<String, Contact> cognizantIdToContact = new Map<String, Contact>();
        for(Contact con : [SELECT Id, Name, Title, Department, Cognizant_Employee_ID__c, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId
                            FROM Contact 
                            WHERE Cognizant_Employee_ID__c IN :cognizantEmployeeIdSet OR Id IN :contactIdSet]){
            cognizantIdToContact.put(con.Cognizant_Employee_ID__c, con);
            contactIdToRecordPublicMap.put(con.Id, con);
        }

        //Loop through queried contacts and assign Contact Ids to Entries that have matching Cognizant Employee Ids
        List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>(); //List to update if functioned called with needsUpdate = true
        for(Replicon_Time_Entry__c timeEntryWithEmployee : entryList){
            Boolean updateNeeded = false;
            if(cognizantIdToContact.containsKey(timeEntryWithEmployee.Cognizant_Employee_Id__c)){
                //Associate Employee__c on Time Entry
                if(timeEntryWithEmployee.Employee__c != cognizantIdToContact.get(timeEntryWithEmployee.Cognizant_Employee_Id__c).Id){
                    timeEntryWithEmployee.Employee__c = cognizantIdToContact.get(timeEntryWithEmployee.Cognizant_Employee_Id__c).Id;
                    updateNeeded = true;
                    
                }

                if(cognizantIdToContact.get(timeEntryWithEmployee.Cognizant_Employee_Id__c).AccountId != null && cognizantIdToContact.get(timeEntryWithEmployee.Cognizant_Employee_Id__c).Account.Name == 'Levementum LLC'){
                    if(timeEntryWithEmployee.Is_Lev_Time__c != true){
                        timeEntryWithEmployee.Is_Lev_Time__c = true;
                        updateNeeded = true;
                    }
                }else{
                    if(timeEntryWithEmployee.Is_Lev_Time__c == true){
                        timeEntryWithEmployee.Is_Lev_Time__c = false;
                        updateNeeded = true;
                    }
                }

                if(updateNeeded){
                    updateEntryList.add(timeEntryWithEmployee);
                }
            
            }else if(contactIdToRecordPublicMap.containsKey(timeEntryWithEmployee.Employee__c)){
                if(contactIdToRecordPublicMap.get(timeEntryWithEmployee.Employee__c).Cognizant_Employee_Id__c != null && timeEntryWithEmployee.Cognizant_Employee_Id__c != contactIdToRecordPublicMap.get(timeEntryWithEmployee.Employee__c).Cognizant_Employee_Id__c){
                    timeEntryWithEmployee.Cognizant_Employee_Id__c = contactIdToRecordPublicMap.get(timeEntryWithEmployee.Employee__c).Cognizant_Employee_Id__c;
                    updateNeeded = true;
                    
                }

                if(contactIdToRecordPublicMap.get(timeEntryWithEmployee.Employee__c).AccountId != null && contactIdToRecordPublicMap.get(timeEntryWithEmployee.Employee__c).Account.Name == 'Levementum LLC'){
                    if(timeEntryWithEmployee.Is_Lev_Time__c != true){
                        timeEntryWithEmployee.Is_Lev_Time__c = true;
                        updateNeeded = true;
                    }
                }else{
                    if(timeEntryWithEmployee.Is_Lev_Time__c == true){
                        timeEntryWithEmployee.Is_Lev_Time__c = false;
                        updateNeeded = true;
                    }
                }

                if(updateNeeded){
                    updateEntryList.add(timeEntryWithEmployee);
                }
            }else{
                System.debug('******* NO CONTACT FOR TIME ENTRY WITH COGNIZANT ID: ' + timeEntryWithEmployee.Cognizant_Employee_Id__c + ' *******');
            }
        }
        System.debug('************************************* ' + updateEntryList.size() + ' New Time Entry Contact Lookups being populated *************************************');
        if(needsUpdate && updateEntryList.size() > 0){
            System.debug('************************************* Updating ' + updateEntryList.size() + ' Time Entries with Contact Lookups *************************************');
            update updateEntryList;
        }
        System.debug('END populateTimeEntryEmployee');

        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryEmployee', null);
        }
    }

    public static void populateTimeEntryProject(List<Replicon_Time_Entry__c> entryList,  Boolean needsUpdate){

        try{

            System.debug('START populateTimeEntryProject');
            Set<String> peoplesoftProjIdSet = new Set<String>();
            Set<String> projIdSet = new Set<String>();
            Map<String, Project__c> peopleSoftToProj = new Map<String, Project__c>();
            
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Peoplesoft_Project_Id__c != null){
                    peoplesoftProjIdSet.add(entry.Peoplesoft_Project_Id__c);
                }else if(entry.Project__c != null){
                    projIdSet.add(entry.Project__c);
                }
            }
            
            if(Project__c.SObjectType.getDescribe().isAccessible()){ //Check if the object is accessible by the running user.
                /*List<Project__c> relatedProjects = new List<Project__c>();        
                //Query for Projects that have matching Peoplesoft Ids of the inserted Time Entries
                relatedProjects = [SELECT Id, PeopleSoft_Project_ID__c, Name, Opportunity__c, Account__c, Project_Status__c FROM Project__c WHERE PeopleSoft_Project_ID__c IN :peoplesoftProjIdSet OR Id IN :projIdSet ORDER BY CreatedDate ASC];*/

                for(Project__c proj : [SELECT Id, PeopleSoft_Project_ID__c, Name, Opportunity__c, Account__c, Project_Status__c FROM Project__c WHERE PeopleSoft_Project_ID__c IN :peoplesoftProjIdSet OR Id IN :projIdSet ORDER BY CreatedDate ASC]){
                    peopleSoftToProj.put(proj.PeopleSoft_Project_ID__c, proj);
                    projectIdToRecordPublicMap.put(proj.Id, proj);
                }
            }

            //Loop through Time Entries with Peoplesoft Project Ids and match them with queried Project with same Peoplesoft Ids
            List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>(); //List to update if functioned called with needsUpdate = true
            for(Replicon_Time_Entry__c entry : entryList){

                Boolean addToUpdateList = false;
                if(peopleSoftToProj.containsKey(entry.Peoplesoft_Project_Id__c)){
                    //Associate Project__c on Time Entry
                    if(entry.Project__c != peopleSoftToProj.get(entry.Peoplesoft_Project_Id__c).Id){
                        entry.Project__c = peopleSoftToProj.get(entry.Peoplesoft_Project_Id__c).Id;
                        entry.Opportunity__c = peopleSoftToProj.get(entry.Peoplesoft_Project_Id__c).Opportunity__c;
                        entry.Account__c = peopleSoftToProj.get(entry.Peoplesoft_Project_Id__c).Account__c;
                        addToUpdateList = true;
                        //updateEntryList.add(entry);
                    }

                }else if(projectIdToRecordPublicMap.containsKey(entry.Project__c) && projectIdToRecordPublicMap.get(entry.Project__c).PeopleSoft_Project_ID__c != null){
                    if(entry.Peoplesoft_Project_Id__c != projectIdToRecordPublicMap.get(entry.Project__c).PeopleSoft_Project_ID__c){
                        entry.Peoplesoft_Project_Id__c = projectIdToRecordPublicMap.get(entry.Project__c).PeopleSoft_Project_ID__c;
                        entry.Opportunity__c = projectIdToRecordPublicMap.get(entry.Project__c).Opportunity__c;
                        entry.Account__c = projectIdToRecordPublicMap.get(entry.Project__c).Account__c;
                        addToUpdateList = true;
                        //updateEntryList.add(entry);
                    }

                }else{
                    System.debug('******* NO PROJECT FOR TIME ENTRY WITH PEOPLESOFT PROJECT ID: ' + entry.Peoplesoft_Project_Id__c  + ' *******');
                }

                if(entry.Peoplesoft_Project_Id__c == internalCognizantConcessionProjectESAId && (entry.Is_Concession__c != true || entry.Billing_Action__c != 'B')){ //Set entry to Concession if it is on the Cognizant internal Project --- ST 8.1.2023
                    if(entry.Is_Concession__c != true){
                        entry.Is_Concession__c = true;
                        addToUpdateList = true;
                    }

                    if(entry.Billing_Action__c != 'B'){
                        entry.Billing_Action__c = 'B';
                        addToUpdateList = true;
                    }
                }

                if(addToUpdateList){
                    updateEntryList.add(entry);
                }
            }

            System.debug('************************************* ' + updateEntryList.size() + ' New Time Entry Project Lookups being populated *************************************');
            if(updateEntryList.size() > 0){
                String debugStatement = needsUpdate ? 'Updating' : 'Setting';
                System.debug('************************************* ' + debugStatement + ' ' + updateEntryList.size() + ' Time Entries with Project Lookups *************************************');
                if(needsUpdate){
                    update updateEntryList;
                }
            }

            System.debug('END populateTimeEntryProject');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryProject', null);
        }
    }

    public static void populateTimeEntryTimesheet(List<Replicon_Time_Entry__c> entryList,  Boolean needsUpdate){
        try{
            System.debug('START populateTimeEntryTimesheet');
            List<Replicon_Time_Entry__c> timeEntriesToCreateNewTimesheetsForList = new List<Replicon_Time_Entry__c>();

            Set<Id> employeeIdSet = new Set<Id>();
            Set<Date> weekStartDateSet = new Set<Date>();
            Set<Id> entryIdSet = new Set<Id>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.EntryDate__c != null){
                    employeeIdSet.add(entry.Employee__c);
                    weekStartDateSet.add((entry.EntryDate__c).toStartofWeek());
                    if(needsUpdate){
                        entryIdSet.add(entry.Id);
                    }
                }
            }

            /*List<Replicon_Timesheet__c> relatedTimesheetList = new List<Replicon_Timesheet__c>();
            relatedTimesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, SubmissionDate__c FROM Replicon_Timesheet__c WHERE Employee__c IN :employeeIdSet AND Start_Date__c IN :weekStartDateSet];*/

            Map<String, Replicon_Timesheet__c> uniqueTimesheetIdMap = new Map<String, Replicon_Timesheet__c>();
            for(Replicon_Timesheet__c sheet : [SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, SubmissionDate__c FROM Replicon_Timesheet__c WHERE Employee__c IN :employeeIdSet AND Start_Date__c IN :weekStartDateSet]){
                String uniqueTimesheetId = String.valueOf(sheet.Employee__c) + '|' + String.valueOf(sheet.Start_Date__c);
                uniqueTimesheetIdMap.put(uniqueTimesheetId, sheet);

            }
            if(needsUpdate){
                entryList = [SELECT Id, Name, Employee__c, Project__c, EntryDate__c, Replicon_Timesheet__c, Submission_Date__c FROM Replicon_Time_Entry__c WHERE Id IN :entryIdSet];
            }
            
            List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Timesheet__c> updateTimesheetList = new List<Replicon_Timesheet__c>();
            for(Replicon_Time_Entry__c entry : entryList){

                if(entry.Employee__c != null && entry.EntryDate__c != null){
                    String uniqueTimesheetId = String.valueOf(entry.Employee__c) + '|' + String.valueOf((entry.EntryDate__c).toStartofWeek());

                    if(uniqueTimesheetIdMap.containsKey(uniqueTimesheetId)){
                        Replicon_Timesheet__c relatedTimesheet = uniqueTimesheetIdMap.get(uniqueTimesheetId);
                        if(entry.Replicon_Timesheet__c != relatedTimesheet.Id){
                            entry.Replicon_Timesheet__c = relatedTimesheet.Id;
                            updateEntryList.add(entry);
                        }

                        if(entry.Submission_Date__c != null && relatedTimesheet.SubmissionDate__c == null){
                            relatedTimesheet.SubmissionDate__c = entry.Submission_Date__c;
                            updateTimesheetList.add(relatedTimesheet);
                        }
                    }else{
                        timeEntriesToCreateNewTimesheetsForList.add(entry);
                    }
                }
            }

            if(needsUpdate && updateEntryList.size() > 0){
                System.debug('************************************* Updating ' + updateEntryList.size() + ' Time Entries with Existing Timesheet Lookups *************************************');
                update updateEntryList;
            }

            if(updateTimesheetList.size() > 0){
                System.debug('************************************* Updating ' + updateTimesheetList.size() + ' Timesheets with Submission Dates *************************************');
                update updateTimesheetList;
            }

            if(timeEntriesToCreateNewTimesheetsForList.size() > 0){
                System.debug('************************************* BEFORE Creating timesheets for' + timeEntriesToCreateNewTimesheetsForList.size() + ' Time Entries with No Existing Timesheet Lookups *************************************');
                createNewTimesheet(timeEntriesToCreateNewTimesheetsForList, false);
            }
            System.debug('END populateTimeEntryTimesheet');

        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryTimesheet', null);
        }
    }

    public static void createNewTimesheet(List<Replicon_Time_Entry__c> entryList,  Boolean needsUpdate){
        try{
            System.debug('START createNewTimesheet');
            Map<String, Replicon_Timesheet__c> uniqueTimesheetIdToTimesheetMap = new Map<String, Replicon_Timesheet__c>();
            Set<Id> relatedEmployeeIdSet = new Set<Id>();

            for(Replicon_Time_Entry__c entry : entryList){
                String uniqueTimesheetId = String.valueOf(entry.Employee__c) + '|' + String.valueOf((entry.EntryDate__c).toStartofWeek());

                if(uniqueTimesheetIdToTimesheetMap.containsKey(uniqueTimesheetId)){ 
                    //Update the Timesheet if the submission date of the entry is prior to the one that is already assigned to the timesheet. (Want the earliest submission date on the timesheet)
                    Replicon_Timesheet__c timesheetToUpdate = uniqueTimesheetIdToTimesheetMap.get(uniqueTimesheetId);
                    if((timesheetToUpdate.SubmissionDate__c == null && entry.Submission_Date__c != null)|| timesheetToUpdate.SubmissionDate__c > entry.Submission_Date__c){
                        timesheetToUpdate.SubmissionDate__c = entry.Submission_Date__c;
                        uniqueTimesheetIdToTimesheetMap.put(uniqueTimesheetId, timesheetToUpdate);
                    }
                    
                }else{//Make map of unique TImesheet Id to Timesheet for creation of each timesheet that does not create duplicates since each week of timesheets will have the same unique timesheet Id of Employee Cognizant ID + the start of the week the time entry is for
                    Replicon_Timesheet__c newTimesheet = new Replicon_Timesheet__c(Employee__c = entry.Employee__c, Start_Date__c = (entry.EntryDate__c).toStartofWeek(), SubmissionDate__c = entry.Submission_Date__c);
                    uniqueTimesheetIdToTimesheetMap.put(uniqueTimesheetId, newTimesheet);
                }

                if(!contactIdToRecordPublicMap.containsKey(entry.Employee__c)){
                    relatedEmployeeIdSet.add(entry.Employee__c);
                }
            }

            //List<Contact> relatedEmployeesList = new List<Contact>();
            if(relatedEmployeeIdSet.size() > 0){
                /*relatedEmployeesList = [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                            RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                        FROM Contact 
                                        WHERE Id IN :relatedEmployeeIdSet];*/

                for(Contact c : [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                    RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                FROM Contact 
                                WHERE Id IN :relatedEmployeeIdSet]){
                    contactIdToRecordPublicMap.put(c.Id, c);
                }
            }

            List<Replicon_Timesheet__c> newTimesheetsToInsert = new List<Replicon_Timesheet__c>();
            for(String uniqueTimesheetId : uniqueTimesheetIdToTimesheetMap.keySet()){
                Replicon_Timesheet__c timesheet = uniqueTimesheetIdToTimesheetMap.get(uniqueTimesheetId);
                
                if(contactIdToRecordPublicMap.containsKey(timesheet.Employee__c)){
                    Contact relatedEmployee = contactIdToRecordPublicMap.get(timesheet.Employee__c);

                    timesheet.Name = (relatedEmployee.Name).left(68) + ': ' + timesheet.Start_Date__c.Format();
                    timesheet.EmployeeDepartment__c = relatedEmployee.Department;
                    timesheet.EmployeeDivision__c = relatedEmployee.Division_New__c;
                    timesheet.EmployeeTitle__c = relatedEmployee.Title;
                    timesheet.EmployeesManager__c = relatedEmployee.ReportsToId;
                    if(relatedEmployee.Account.Name == 'Levementum LLC'){
                        timesheet.Is_Lev_Timesheet__c = true;
                    }else{
                        timesheet.Is_Lev_Timesheet__c = false;
                    }

                    //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                    Decimal timesheetExpectedHours = 0;
                    //Only Calculate Week Target on Timesheet if the Employee is Active OR if the Employee is not active then only calculate timesheet target if the timesheet was before their termination date
                    if(relatedEmployee.Active__c == true || (relatedEmployee.Term_Date__c != null && relatedEmployee.Active__c == false && timesheet.Start_Date__c < relatedEmployee.Term_Date__c)){

                        //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                        if(relatedEmployee.Weekly_Target__c != null && relatedEmployee.RampTime__c != null && relatedEmployee.Ramp_End_Date__c != null && timesheet.Start_Date__c != null){
                            timesheetExpectedHours = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(relatedEmployee.Weekly_Target__c, relatedEmployee.RampTime__c, relatedEmployee.Ramp_End_Date__c.toStartOfWeek(), timesheet.Start_Date__c);
                        
                        //If the Ramp fields are not populated then just populate the expected Hours with the weekly Target if populated
                        }else if(relatedEmployee.Weekly_Target__c != null){
                            timesheetExpectedHours = relatedEmployee.Weekly_Target__c;
                        }

                    //If Timesheet is for an inactive employee and the timesheet is after the related Employee's Termination date then set the expected hours to 0
                    }
                    timesheet.Target__c = timesheetExpectedHours;

                    uniqueTimesheetIdToTimesheetMap.put(uniqueTimesheetId, timesheet);
                }
            }

            if(uniqueTimesheetIdToTimesheetMap.values().size() > 0){
                insert uniqueTimesheetIdToTimesheetMap.values();
            }

            List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                String uniqueTimesheetId = String.valueOf(entry.Employee__c) + '|' + String.valueOf((entry.EntryDate__c).toStartofWeek());

                if(uniqueTimesheetIdToTimesheetMap.containsKey(uniqueTimesheetId)){
                    entry.Replicon_Timesheet__c = uniqueTimesheetIdToTimesheetMap.get(uniqueTimesheetId).Id;
                    updateEntryList.add(entry);
                }
            }

            if(needsUpdate && updateEntryList.size() > 0){
                System.debug('************************************* Updating ' + updateEntryList.size() + ' Time Entries with NEWLY CREATED Timesheet Lookups *************************************');
                update updateEntryList;
            }

            System.debug('END createNewTimesheet');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'createNewTimesheet', null);
        }
    }

    public static void populateTimeEntryProjectTeamMember(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
            System.debug('START populateTimeEntryProjectTeamMember');
            Set<Id> relatedEmployeeIdSet = new Set<Id>();
            Set<Id> relatedProjectIdSet = new Set<Id>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null){
                    relatedEmployeeIdSet.add(entry.Employee__c);
                    relatedProjectIdSet.add(entry.Project__c);
                }
            }

            /*List<Client_Contact__c> relatedProjTeamMembersList = new List<Client_Contact__c>();
            relatedProjTeamMembersList = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Project__c, Project__r.Name, Client_Contact__c, Client_Contact__r.Name 
                                            FROM Client_Contact__c
                                            WHERE Project__c IN :relatedProjectIdSet AND Client_Contact__c IN :relatedEmployeeIdSet
                                            ORDER BY Project__c];*/

            Map<String, Client_Contact__c> uniqueIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
            for(Client_Contact__c ptm : [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Project__c, Project__r.Name, Client_Contact__c, Client_Contact__r.Name 
                                            FROM Client_Contact__c
                                            WHERE Project__c IN :relatedProjectIdSet AND Client_Contact__c IN :relatedEmployeeIdSet
                                            ORDER BY Project__c]){
                String uniqueProjTeamMemberId = String.valueOf(ptm.Project__c) + '|' + String.valueOf(ptm.Client_Contact__c);
                uniqueIdToProjTeamMemberMap.put(uniqueProjTeamMemberId, ptm);
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> entriesWithNoProjectTeamMemberList = new List<Replicon_Time_Entry__c>();
            Set<String> projectIdAndEmployeeIdUniqueIdSet = new Set<String>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null){
                    String uniqueEntryId = String.valueOf(entry.Project__c) + '|' + String.valueOf(entry.Employee__c);

                    if(uniqueIdToProjTeamMemberMap.containsKey(uniqueEntryId)){
                        Client_Contact__c relatedProjTeamMember = uniqueIdToProjTeamMemberMap.get(uniqueEntryId);
                        if(entry.Internal_Project_Team_Member__c != uniqueIdToProjTeamMemberMap.get(uniqueEntryId).Id){
                            entry.Internal_Project_Team_Member__c = uniqueIdToProjTeamMemberMap.get(uniqueEntryId).Id;
                            entryUpdateList.add(entry);
                        }             
                    }else{
                        //If no project team member exists for an incoming Time Entry then create one.
                        projectIdAndEmployeeIdUniqueIdSet.add(uniqueEntryId);
                        entriesWithNoProjectTeamMemberList.add(entry);
                    }
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('**************************** Updating ' + entryUpdateList.size() + ' Time Entries with Project Team Member lookups ***************************');
                update entryUpdateList;
            }

            if(entriesWithNoProjectTeamMemberList.size() > 0){
                if(needsUpdate){
                    createNewProjectTeamMember(entriesWithNoProjectTeamMemberList, true);
                }else{
                    createNewProjectTeamMember(entriesWithNoProjectTeamMemberList, false);
                }
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryProjectTeamMember', null);
        }
    }

    public static void createNewProjectTeamMember(List<Replicon_Time_Entry__c> entryList,  Boolean needsUpdate){

        try{
            Set<Id> projectIdSet = new Set<Id>();
            Set<Id> employeeIdSet = new Set<Id>();
            Set<String> projectIdAndEmployeeIdUniqueIdSet = new Set<String>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Project__c != null && entry.Employee__c != null){
                    String projectIdAndEmployeeIdUniqueId = String.valueOf(entry.Project__c) + '|' + String.valueOf(entry.Employee__c);
                    projectIdAndEmployeeIdUniqueIdSet.add(projectIdAndEmployeeIdUniqueId);

                    if(!projectIdToRecordPublicMap.containsKey(entry.Project__c)){
                        //Check to see if the Project lookup is already in the class public map, if not then need to query it here
                        projectIdSet.add(entry.Project__c);
                    }

                    if(!contactIdToRecordPublicMap.containsKey(entry.Employee__c)){
                        //Check to see if the Contact lookup is already in the class public map, if not then need to query it here
                        employeeIdSet.add(entry.Employee__c);
                    }
                }                
            }
            

            if(projectIdSet.size() > 0){
                /*List<Project__c> relatedProjectsList = new List<Project__c>();
                relatedProjectsList = [SELECT Id, PeopleSoft_Project_ID__c, Name, Opportunity__c, Account__c, Project_Status__c FROM Project__c WHERE Id IN :projectIdSet ORDER BY CreatedDate ASC];*/

                for(Project__c proj : [SELECT Id, PeopleSoft_Project_ID__c, Name, Opportunity__c, Account__c, Project_Status__c FROM Project__c WHERE Id IN :projectIdSet ORDER BY CreatedDate ASC]){
                    projectIdToRecordPublicMap.put(proj.Id, proj);
                }
            }

            if(employeeIdSet.size() > 0){
                /*List<Contact> relatedContactsList = new List<Contact>();
                relatedContactsList = [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                            RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                        FROM Contact
                                        WHERE Id IN :employeeIdSet];*/

                for(Contact c : [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                        RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                    FROM Contact
                                    WHERE Id IN :employeeIdSet]){
                    contactIdToRecordPublicMap.put(c.Id, c);
                }
            }

            Map<String, Client_Contact__c> uniqueProjAndEmployeeIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
            if(projectIdAndEmployeeIdUniqueIdSet != null && projectIdAndEmployeeIdUniqueIdSet.size() > 0){
                for(String uniqueProjAndEmployeeId : projectIdAndEmployeeIdUniqueIdSet){
                    List<String> uniqueIdParts = uniqueProjAndEmployeeId.splitByCharacterTypeCamelCase();
                    Id projectId = (Id)(uniqueProjAndEmployeeId.substringBefore('|'));
                    Id employeeId = (Id)(uniqueProjAndEmployeeId.substringAfter('|'));

                    Client_Contact__c newTeamMember = new Client_Contact__c();
                    newTeamMember.Project__c = projectId;
                    newTeamMember.Client_Contact__c = employeeId;
                    if(projectIdToRecordPublicMap.containsKey(projectId)){
                        newTeamMember.Account__c = projectIdToRecordPublicMap.get(projectId).Account__c;
                    }
                    if(projectIdToRecordPublicMap.containsKey(projectId) && contactIdToRecordPublicMap.containsKey(employeeId)){
                        String projTeamMemberName = (contactIdToRecordPublicMap.get(employeeId).Name + ' - ' + projectIdToRecordPublicMap.get(projectId).Name).left(255);
                        newTeamMember.Internal_Project_Team_Member_Name__c = projTeamMemberName;
                    }
                    
                    uniqueProjAndEmployeeIdToProjTeamMemberMap.put(uniqueProjAndEmployeeId, newTeamMember);
                }
            }

            if(uniqueProjAndEmployeeIdToProjTeamMemberMap.values().size() > 0){
                System.debug('*************************** Inserting ' + uniqueProjAndEmployeeIdToProjTeamMemberMap.values().size() + ' Internal Project Team Members to be populated on Time Entries **********************************');
                insert uniqueProjAndEmployeeIdToProjTeamMemberMap.values();
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Project__c != null && entry.Employee__c != null){
                    String projectIdAndEmployeeIdUniqueId = String.valueOf(entry.Project__c) + '|' + String.valueOf(entry.Employee__c);

                    if(uniqueProjAndEmployeeIdToProjTeamMemberMap.containsKey(projectIdAndEmployeeIdUniqueId)){
                        if(entry.Internal_Project_Team_Member__c != uniqueProjAndEmployeeIdToProjTeamMemberMap.get(projectIdAndEmployeeIdUniqueId).Id){
                            entry.Internal_Project_Team_Member__c = uniqueProjAndEmployeeIdToProjTeamMemberMap.get(projectIdAndEmployeeIdUniqueId).Id;
                            entryUpdateList.add(entry);
                        }                    
                    }
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('****************************** Updating ' + entryUpdateList.size() + ' Time Entries with Internal Project Team Member lookups **********************************');
                update entryUpdateList;
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'createNewProjectTeamMember', null);
        }
    }

    public static void populateTimeEntryName(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){

        try{
            List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){

                String employeeName = contactIdToRecordPublicMap.containsKey(entry.Employee__c) ? contactIdToRecordPublicMap.get(entry.Employee__c).Name : 'null';
                String projectName = projectIdToRecordPublicMap.containsKey(entry.Project__c) ? projectIdToRecordPublicMap.get(entry.Project__c).Name : 'null';
                String entryDateFormattedString = entry.EntryDate__c != null ? String.valueOf(entry.EntryDate__c.Format()) : 'null';

                String timeEntryName = employeeName + ' - ' + entryDateFormattedString + ' - ' + projectName;
                
                if(entry.Name != timeEntryName.left(80)){
                    entry.Name = timeEntryName.left(80);
                    updateEntryList.add(entry);
                }

                /*if(contactIdToRecordPublicMap.containsKey(entry.Employee__c) && projectIdToRecordPublicMap.containsKey(entry.Project__c)){
                    String entryName = contactIdToRecordPublicMap.get(entry.Employee__c).Name + ' - ' + String.valueOf(entry.EntryDate__c.Format()) + ' - ' + projectIdToRecordPublicMap.get(entry.Project__c).Name;
                    if(entry.Name != entryName.left(80)){
                        entry.Name = entryName.left(80);
                        updateEntryList.add(entry);
                    }
                }*/
            }

            if(needsUpdate && updateEntryList.size() > 0){
                System.debug('******************* Updating ' + updateEntryList.size() + ' Time Entries with Name(s) *******************');
                update updateEntryList;
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryName', null);
        }
    }

    public static void populateTimeEntryBillingRate(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
            System.debug('START populateTimeEntryBillingRate');
            Set<Id> relatedEmployeeIdSet = new Set<Id>();
            Set<Id> relatedProjectIdSet = new Set<Id>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.Billing_Action__c == 'B' && entry.Is_Concession__c == false && entry.Time_Off__c == false){
                    relatedEmployeeIdSet.add(entry.Employee__c);
                    relatedProjectIdSet.add(entry.Project__c);
                }else if((entry.Billing_Action__c == 'U' || entry.Time_Off__c == false) && entry.Associated_Billing_Rate__c != null && !entry.Is_Concession__c){
                    entry.Associated_Billing_Rate__c = null;
                }
            }

            /*List<Client_Contact__c> relatedProjTeamMembersList = new List<Client_Contact__c>();
            relatedProjTeamMembersList = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Project__c, Client_Contact__c, 
                                                Active_Effective_Billing_Rate__c, Active_Effective_Billing_Rate__r.Project_Billing_Rate__c, Active_Effective_Billing_Rate__r.Effective_Date__c
                                            FROM Client_Contact__c
                                            WHERE Project__c IN :relatedProjectIdSet AND Client_Contact__c IN :relatedEmployeeIdSet
                                            ORDER BY Project__c];*/

            Map<String, Client_Contact__c> uniqueIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
            for(Client_Contact__c ptm : [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Project__c, Client_Contact__c, 
                                                Active_Effective_Billing_Rate__c, Active_Effective_Billing_Rate__r.Project_Billing_Rate__c, Active_Effective_Billing_Rate__r.Effective_Date__c
                                            FROM Client_Contact__c
                                            WHERE Project__c IN :relatedProjectIdSet AND Client_Contact__c IN :relatedEmployeeIdSet
                                            ORDER BY Project__c]){
                String uniqueProjTeamMemberId = String.valueOf(ptm.Project__c) + '|' + String.valueOf(ptm.Client_Contact__c);
                uniqueIdToProjTeamMemberMap.put(uniqueProjTeamMemberId, ptm);
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> checkEffectiveRatesEntryList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> assignTempRateToEntryList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> assignConcessionRateToEntryList = new List<Replicon_Time_Entry__c>();
            Set<Id> assignTempRateProjIdSet = new Set<Id>();
            List<Client_Contact__c> projTeamMemberWithNoAssignedRateList = new List<Client_Contact__c>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.Billing_Action__c == 'B' && !entry.Is_Concession__c){
                    String uniqueEntryId = String.valueOf(entry.Project__c) + '|' + String.valueOf(entry.Employee__c);

                    if(uniqueIdToProjTeamMemberMap.containsKey(uniqueEntryId)){
                        Client_Contact__c relatedProjTeamMember = uniqueIdToProjTeamMemberMap.get(uniqueEntryId);
                        if( entry.Internal_Project_Team_Member__c != uniqueIdToProjTeamMemberMap.get(uniqueEntryId).Id){
                            entry.Internal_Project_Team_Member__c = uniqueIdToProjTeamMemberMap.get(uniqueEntryId).Id;
                        }
                        if(entry.Billing_Action__c == 'B' && !entry.Is_Concession__c){
                            if(relatedProjTeamMember.Assigned_Billing_Rate__c != null){
                                if(relatedProjTeamMember.Active_Effective_Billing_Rate__c != null && entry.EntryDate__c < relatedProjTeamMember.Active_Effective_Billing_Rate__r.Effective_Date__c){
                                    //If Active Effective Billing Rate is populated AND the currently ACTIVE Effective Billing Rate Effective Date is Past the Entries entry Date 
                                    //then we need to check the effective rates for this Entry in order to make sure it is assigned to correct Bill Rate based on any Effective Bill Rates that the project team member has
                                    System.debug('Check Effective Rates Entry Name: ' + entry.Name);
                                    checkEffectiveRatesEntryList.add(entry);

                                }else if(entry.Associated_Billing_Rate__c != relatedProjTeamMember.Assigned_Billing_Rate__c){
                                    entry.Associated_Billing_Rate__c = relatedProjTeamMember.Assigned_Billing_Rate__c;
                                    System.debug('Update Non Effective Rate Entry Name: ' + entry.Name);
                                    entryUpdateList.add(entry);
                                }
                            }else{
                                //Look for Temp Rate on Project, if one does not exist then create one for the project
                                assignTempRateToEntryList.add(entry);
                                assignTempRateProjIdSet.add(entry.Project__c);
                                projTeamMemberWithNoAssignedRateList.add(relatedProjTeamMember);
                            }
                        }                
                    }
                }else{
                    if(entry.Employee__c != null && entry.Project__c != null && entry.Is_Concession__c){
                        assignConcessionRateToEntryList.add(entry);
                    }
                }
            }

            if(checkEffectiveRatesEntryList.size() > 0){
                System.debug('************************ Checking the Effective Rates of ' + checkEffectiveRatesEntryList.size() + ' Time Entries for Billing Rate Population ******************************');
                List<Replicon_Time_Entry__C> effectiveRateEntriesToUpdateList = new List<Replicon_Time_Entry__c>();
                effectiveRateEntriesToUpdateList = checkEffectiveRatesForTimeEntryBillingRatePopulation(checkEffectiveRatesEntryList);
                System.debug('************************ Returned ' + effectiveRateEntriesToUpdateList.size() + ' from checking Effective Rates for Time Entries for Billing Rate Population ******************************');
                if(effectiveRateEntriesToUpdateList.size() > 0){
                    entryUpdateList.addAll(effectiveRateEntriesToUpdateList);
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('**************** Updating ' + entryUpdateList.size() + ' Time Entries with Billing Rates ****************** ');
                update entryUpdateList;
            }

            if(assignTempRateToEntryList.size() > 0){
                if(needsUpdate){
                    assignTempRateForBillableEntry(assignTempRateToEntryList, assignTempRateProjIdSet, projTeamMemberWithNoAssignedRateList, true);
                }else{
                    assignTempRateForBillableEntry(assignTempRateToEntryList, assignTempRateProjIdSet, projTeamMemberWithNoAssignedRateList, false);
                }
            }

            if(assignConcessionRateToEntryList.size() > 0){
                if(needsUpdate){
                    assignConcessionRate(assignConcessionRateToEntryList, true);
                }else{
                    assignConcessionRate(assignConcessionRateToEntryList, false);
                }
            }
            System.debug('END populateTimeEntryBillingRate');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryBillingRate', null);
        }
    }

    public static List<Replicon_Time_Entry__c> checkEffectiveRatesForTimeEntryBillingRatePopulation(List<Replicon_Time_Entry__c> entryList){

            System.debug('Check Effective Rates START');

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
        try{

            Set<Id> internalProjTeamMemberIdSet = new Set<Id>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Internal_Project_Team_Member__c != null){
                    internalProjTeamMemberIdSet.add(entry.Internal_Project_Team_Member__c);
                }
            }

            /*List<Project_Team_Member_Effective_Rate__c> effectiveRateList = new List<Project_Team_Member_Effective_Rate__c>();
            effectiveRateList = [SELECT Id, Name, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Internal_Project_Team_Member_Name__c, Effective_Date__c
                                    FROM Project_Team_Member_Effective_Rate__c
                                    WHERE Internal_Project_Team_Member__c IN :internalProjTeamMemberIdSet AND Project_Billing_Rate__c != null
                                    ORDER BY Internal_Project_Team_Member__c, Effective_Date__c ASC];*/

            Map<Id, List<Project_Team_Member_Effective_Rate__c>> teamMemberIdToEffectiveRatesListMap = new Map<Id, List<Project_Team_Member_Effective_Rate__c>>();
            for(Project_Team_Member_Effective_Rate__c effectiveRate : [SELECT Id, Name, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Internal_Project_Team_Member_Name__c, Effective_Date__c
                                                                        FROM Project_Team_Member_Effective_Rate__c
                                                                        WHERE Internal_Project_Team_Member__c IN :internalProjTeamMemberIdSet AND Project_Billing_Rate__c != null
                                                                        ORDER BY Internal_Project_Team_Member__c, Effective_Date__c ASC]){
                if(teamMemberIdToEffectiveRatesListMap.containsKey(effectiveRate.Internal_Project_Team_Member__c)){
                    List<Project_Team_Member_Effective_Rate__c> projTeamMemberEffectiveRateList = teamMemberIdToEffectiveRatesListMap.get(effectiveRate.Internal_Project_Team_Member__c);
                    projTeamMemberEffectiveRateList.add(effectiveRate);
                    teamMemberIdToEffectiveRatesListMap.put(effectiveRate.Internal_Project_Team_Member__c, projTeamMemberEffectiveRateList);
                }else{
                    List<Project_Team_Member_Effective_Rate__c> projTeamMemberEffectiveRateList = new List<Project_Team_Member_Effective_Rate__c>();
                    projTeamMemberEffectiveRateList.add(effectiveRate);
                    teamMemberIdToEffectiveRatesListMap.put(effectiveRate.Internal_Project_Team_Member__c, projTeamMemberEffectiveRateList);
                }
            }

            /**
            * Want to find which effective rate the time entry should use as a billing rate.
            * Find what Effective rate has a date that is less than or equal to the Time Entry's Entry Date
            * If there are multiple effecitve rates with Effective Dates less than entry date then use the effective date that is further in the future (or the one that is closer to the entry date using DaysBetween())
            * if there are no effective rates with a date less than the entry entry date then use the effective rate with NO Effective Date populated 
            * 
            */
            for(Replicon_Time_Entry__c entry : entryList){
                //System.debug('Entry Name: ' + entry.Name);
                Id effectiveRateToAssignBillRateId;
                if(entry.Internal_Project_Team_Member__c != null && teamMemberIdToEffectiveRatesListMap.containsKey(entry.Internal_Project_Team_Member__c)){

                    //get list of effective dates for all effective rates
                    List<Project_Team_Member_Effective_Rate__c> projTeamMemberEffectiveRateList = teamMemberIdToEffectiveRatesListMap.get(entry.Internal_Project_Team_Member__c);
                    
                    //loop through all effective dates, find one that is less than the entry date, if more than one then find the one that is closest to entry's entry date
                    for(Project_Team_Member_Effective_Rate__c effectiveRate : projTeamMemberEffectiveRateList){
                        //System.debug('*****************Effective Rate Loop Start: ' + effectiveRate.Project_Billing_Rate__r.Name + ' Effective Date: ' + effectiveRate.Effective_Date__c);
                        if(effectiveRate.Effective_Date__c == null || entry.EntryDate__c >= effectiveRate.Effective_Date__c){  
                            if(effectiveRate.Effective_Date__c != null){

                                //If the Time Entry's Entry Date is past the effective rate then set it as the bill rate to assign to the forecast
                                //This will continue to set it as the bill rate to assign until there is either 1.) No more effective rates to iterate through. OR 2.)The Effective Rate Effective Date is PAST than the Entry's Entry Date.
                                //Since the Effective Rates are ordered by Effective Date ASC, it will iterate through the earliest date first and will continue until there is an effective rate that is past the forecast's week end date.
                                effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                            }else{
                                //Null values will come through first, so we store the rate that has null value to continue to loop through
                                //But if there are no effective dates that are less than the Time Entry's entry date then it will use this rate for the entry.                            
                                effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                                //System.debug('Null Effective Date Bill Rate: ' + effectiveRateToAssignBillRateId);
                            }
                        }else{
                            if(effectiveRateToAssignBillRateId == null){
                                effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                            }
                            break;
                        }
                    }

                    //If it looped through all Effective Rates and none of them had an Effective Rate that was smaller than the Entry's entry date, then use the effective rate that had NO Effective Date that was stored as the bill rate
                    if(effectiveRateToAssignBillRateId != null && entry.Associated_Billing_Rate__c != effectiveRateToAssignBillRateId){
                        entry.Associated_Billing_Rate__c = effectiveRateToAssignBillRateId;
                        //System.debug('Adding Entry to Update From Effective Rate WITHOUT Effective DATE populated Population');
                        entryUpdateList.add(entry);
                    }
                }
            }

            System.debug('Check Effective Rates END');

            return entryUpdateList;
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'checkEffectiveRatesForTimeEntryBillingRatePopulation', null);
            return entryUpdateList;
        }
    }

    public static void assignTempRateForBillableEntry(List<Replicon_Time_Entry__c> entryList, Set<Id> projectIdSet, List<Client_Contact__c> projTeamMembersWithoutAssignedRatesList, Boolean needsUpdate){

        try{
            System.debug('START assignTempRateForBillableEntry');

            //List<Project_Team_Member_Billing_Rate__c> relatedProjTempRateList = new List<Project_Team_Member_Billing_Rate__c>();
            //Search for Temporary Rates on Projects where Billable Time Entries have come in but their related Project Team Member has not been assigned a Billing Rate
            /*relatedProjTempRateList = [SELECT Id, Name, Project__c, Internal_Project_Team_Member__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Hourly_Rate__c, Created_in_Salesforce__c
                                        FROM Project_Team_Member_Billing_Rate__c
                                        WHERE Project__c IN :projectIdSet AND Is_Temporary_Rate__c = true];*/

            Map<Id, Project_Team_Member_Billing_Rate__c> projIdToTempRateMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
            for(Project_Team_Member_Billing_Rate__c billRate : [SELECT Id, Name, Project__c, Internal_Project_Team_Member__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Hourly_Rate__c, Created_in_Salesforce__c
                                                                FROM Project_Team_Member_Billing_Rate__c
                                                                WHERE Project__c IN :projectIdSet AND Is_Temporary_Rate__c = true]){
                projIdToTempRateMap.put(billRate.Project__c, billRate);
            }

            List<Project_Team_Member_Billing_Rate__c> tempRatesInsertList = new List<Project_Team_Member_Billing_Rate__c>();
            //Go through all projects to create Temp Rates if needed
            for(Id projectId : projectIdSet){
                if(!projIdToTempRateMap.containsKey(projectId)){ //If a Temp Rate doesn't exist for a Project that needs it, then create one
                    Project_Team_Member_Billing_Rate__c newTempRate = new Project_Team_Member_Billing_Rate__c(Name = 'Temporary Rate', Project__c = projectId, Created_in_Salesforce__c = true, Hourly_Rate__c = 210, Is_Temporary_Rate__c = true);
                    tempRatesInsertList.add(newTempRate);
                }
            }
            //Insert Temp Rates that are needed and have yet to be created, to be assigned
            if(tempRatesInsertList.size() > 0){
                System.debug('********** Inserting ' + tempRatesInsertList.size() + ' Temporary Rates ************');
                insert tempRatesInsertList;
            }

            for(Project_Team_Member_Billing_Rate__c billRate : tempRatesInsertList){
                projIdToTempRateMap.put(billRate.Project__c, billRate);
            }

            List<Client_Contact__c> updateProjTeamMemberList = new List<Client_Contact__c>();
            for(Client_Contact__c ptm : projTeamMembersWithoutAssignedRatesList){
                if(projIdToTempRateMap.containsKey(ptm.Project__c) && ptm.Assigned_Billing_Rate__c != projIdToTempRateMap.get(ptm.Project__c).Id){
                    ptm.Assigned_Billing_Rate__c = projIdToTempRateMap.get(ptm.Project__c).Id;
                    updateProjTeamMemberList.add(ptm);
                }
            }

            if(updateProjTeamMemberList.size() > 0){
                System.debug('************** Updating ' + updateProjTeamMemberList.size() + ' Internal Project Team Members with Temporary Rate as Assigned Billing Rate ******************');
                update updateProjTeamMemberList;
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            //Assign the temp rates as Associated Billing Rates on billable Entries
            for(Replicon_Time_Entry__c entry : entryList){
                if(projIdToTempRateMap.containsKey(entry.Project__c)){
                    if(entry.Associated_Billing_Rate__c != projIdToTempRateMap.get(entry.Project__c).Id){
                        entry.Associated_Billing_Rate__c = projIdToTempRateMap.get(entry.Project__c).Id;
                        entryUpdateList.add(entry);
                    }
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('********** Updating ' + entryUpdateList.size() + ' Time Entries with Temporary Rates ************');
                update entryUpdateList;
            }

            System.debug('END assignTempRateForBillableEntry');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'assignTempRateForBillableEntry', null);
        }
    }

    public static void assignConcessionRate(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
            System.debug('START assignConcessionRate');

            Set<Id> projectIdSet = new Set<Id>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Is_Concession__c && entry.Project__c != null){
                    projectIdSet.add(entry.Project__c);
                }
            }

            //List<Project_Team_Member_Billing_Rate__c> relatedProjConcessionRateList = new List<Project_Team_Member_Billing_Rate__c>();
            //Search for Concession Rates on Projects where Billable Time Entries have come in but their related Project Team Member has not been assigned a Billing Rate
            /*relatedProjConcessionRateList = [SELECT Id, Name, Project__c, Internal_Project_Team_Member__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Hourly_Rate__c, Created_in_Salesforce__c
                                        FROM Project_Team_Member_Billing_Rate__c
                                        WHERE Project__c IN :projectIdSet AND Is_Concession_Rate__c = true];*/

            Map<Id, Project_Team_Member_Billing_Rate__c> projIdToConcessionRateMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
            for(Project_Team_Member_Billing_Rate__c billRate : [SELECT Id, Name, Project__c, Internal_Project_Team_Member__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Hourly_Rate__c, Created_in_Salesforce__c
                                                                    FROM Project_Team_Member_Billing_Rate__c
                                                                    WHERE Project__c IN :projectIdSet AND Is_Concession_Rate__c = true]){
                projIdToConcessionRateMap.put(billRate.Project__c, billRate);
            }

            List<Project_Team_Member_Billing_Rate__c> concessionRatesInsertList = new List<Project_Team_Member_Billing_Rate__c>();
            //Go through all projects to create Concession Rates if needed
            for(Id projectId : projectIdSet){
                if(!projIdToConcessionRateMap.containsKey(projectId)){ //If a Concession Rate doesn't exist for a Project that needs it, then create one
                    Project_Team_Member_Billing_Rate__c newConcessionRate = new Project_Team_Member_Billing_Rate__c(Name = 'Concession', Project__c = projectId, Created_in_Salesforce__c = true, Hourly_Rate__c = 0, Is_Temporary_Rate__c = false, Is_Concession_Rate__c = true);
                    concessionRatesInsertList.add(newConcessionRate);
                }
            }
            //Insert Concession Rates that are needed and have yet to be created, to be assigned
            if(concessionRatesInsertList.size() > 0){
                System.debug('********** Inserting ' + concessionRatesInsertList.size() + ' Concession Rates ************');
                insert concessionRatesInsertList;
            }

            for(Project_Team_Member_Billing_Rate__c billRate : concessionRatesInsertList){
                projIdToConcessionRateMap.put(billRate.Project__c, billRate);
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            //Assign the Concession rates as Associated Billing Rates
            for(Replicon_Time_Entry__c entry : entryList){
                if(projIdToConcessionRateMap.containsKey(entry.Project__c)){
                    if(entry.Associated_Billing_Rate__c != projIdToConcessionRateMap.get(entry.Project__c).Id){
                        entry.Associated_Billing_Rate__c = projIdToConcessionRateMap.get(entry.Project__c).Id;
                        entry.Unique_Time_Entry_Id__c = String.valueOf(entry.Cognizant_Employee_Id__c) + ' | ' + String.valueOf(entry.Peoplesoft_Project_Id__c) + ' | ' + 'Concession' + ' | ' + String.valueOf(entry.EntryDate__c.Format()) + ' | ' + entry.ActivityName__c;
                        entryUpdateList.add(entry);
                    }
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('********** Updating ' + entryUpdateList.size() + ' Time Entries with Concession Rates ************');
                update entryUpdateList;
            }

            System.debug('END assignConcessionRate');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'assignConcessionRate', null);
        }
    }

    public static void populateTimeEntryWeeklyTarget(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
        System.debug('START populateTimeEntryWeeklyTarget');
        Set<Date> weekStartOfEntryDatesSet= new Set<Date>();
        Set<Id> relatedEmployeeIdSet = new Set<Id>();

        for(Replicon_Time_Entry__c entry : entryList){
            if(entry.Employee__c != null && entry.EntryDate__c != null){
                if(entry.EntryDate__c.toStartOfWeek().month() == entry.EntryDate__c.month()){
                    weekStartOfEntryDatesSet.add(entry.EntryDate__c.toStartOfWeek()); //If the start of the Week is the Same month as the Entry date then the Weekly Target can be found via the Start of the Week Date beca
                }else{
                    weekStartOfEntryDatesSet.add(entry.EntryDate__c.toStartOfMonth()); //If the start of the week is NOT the same month as the Entry Date, then it is the beginning of the month week that we can get the WeekStartDate of via the Start of The Month function to get us the first date in that first partial week
                }

                if(!contactIdToRecordPublicMap.containsKey(entry.Employee__c)){
                    relatedEmployeeIdSet.add(entry.Employee__c);
                }
            }
        }

        if(relatedEmployeeIdSet.size() > 0){
            //List<Contact> relatedEmployeesList = new List<Contact>();
            if(relatedEmployeeIdSet.size() > 0){
                /*relatedEmployeesList = [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                            RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                        FROM Contact 
                                        WHERE Id IN :relatedEmployeeIdSet];*/

                for(Contact c : [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                        RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                    FROM Contact 
                                    WHERE Id IN :relatedEmployeeIdSet]){
                    contactIdToRecordPublicMap.put(c.Id, c);
                }
            }
        }

        /*List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();
        weeklyTargetsList = [SELECT Id, WeekStartDate__c FROM Revenue_Forecast__c WHERE WeekStartDate__c IN :weekStartOfEntryDatesSet AND RecordTypeId =: weeklyTargetRT];*/

        Map<Date, Id> weeklyTargetStartDateToIdMap = new Map<Date, Id>();

        for(Revenue_Forecast__c weeklyTarget : [SELECT Id, WeekStartDate__c FROM Revenue_Forecast__c WHERE WeekStartDate__c IN :weekStartOfEntryDatesSet AND RecordTypeId =: weeklyTargetRT]){
            weeklyTargetStartDateToIdMap.put(weeklyTarget.WeekStartDate__c, weeklyTarget.Id);
        }

        List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList) {
            if(entry.Employee__c != null && entry.EntryDate__c != null){
                //if(relatedEmployees.containsKey(entry.Employee__c) && relatedEmployees.get(entry.Employee__c).AccountId == levementumAccountId){ //Added 6/3/2022 ST to exclude non Lev Time from being logged against the Revenue Forecasts
                if(contactIdToRecordPublicMap.containsKey(entry.Employee__c)){
                    Contact entryEmployee = contactIdToRecordPublicMap.get(entry.Employee__c);
                    //Added 6.8.2022 to check the Entry Date, Employee Account, and Employee Name to determine if it should be linked to a Revenue Forecast
                    if(((entry.EntryDate__c < switchToATGTimeDate && entryEmployee.Name != atgConsultantContactName) || (entry.EntryDate__c >= switchToATGTimeDate && entryEmployee.Account.Name == levementumAccountName && entryEmployee.Name != atgConsultantContactName))){
                        Date entryWeekStartDate;
                        if(entry.EntryDate__c.toStartOfWeek().month() == entry.EntryDate__c.month()){ //If the beginning of the Week is in the same month as the Entries EntryDate then use that day
                            entryWeekStartDate = entry.EntryDate__c.toStartOfWeek();
                        }else{//If the beginning of the week is NOT in the same month then use the first of the month to account for double monthed weeks.
                            entryWeekStartDate = entry.EntryDate__c.toStartOfMonth();
                        }
                        //Get the Related Weekly Target Record to assocate the Time Entry with
                        if(weeklyTargetStartDateToIdMap.containsKey(entryWeekStartDate)){
                            if(entry.WeeklyTarget__c != weeklyTargetStartDateToIdMap.get(entryWeekStartDate)){
                                entry.WeeklyTarget__c = weeklyTargetStartDateToIdMap.get(entryWeekStartDate);
                                updateEntryList.add(entry);
                            }
                        }
                    }
                }
            }
        }

        if(needsUpdate && updateEntryList.size() > 0){
            System.debug('************** Updating ' + updateEntryList.size() + ' Time Entries with Weekly Target Lookups **************');
            update updateEntryList;
        }

        System.debug('END populateTimeEntryWeeklyTarget');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryWeeklyTarget', null);
        }
    }

    public static void populateTimeEntryWorkDay(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
            System.debug('START populateTimeEntryWorkDay');
            Set<Id> relatedEmployeeIdSet = new Set<Id>();
            Set<Date> entryDateSet = new Set<Date>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.EntryDate__c != null){
                    relatedEmployeeIdSet.add(entry.Employee__c);
                    entryDateSet.add(entry.EntryDate__c);
                }
            }

            /*List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
            relatedWorkDayList = [SELECT Id, Name, Employee__c, WorkDayDate__c FROM WorkDay__c WHERE Employee__c IN :relatedEmployeeIdSet AND WorkDayDate__c IN :entryDateSet ORDER BY Employee__c, WorkDayDate__c DESC];*/

            Map<String, WorkDay__c> workDayUniqueStringToRecordMap = new Map<String, WorkDay__c>();
            for(WorkDay__c wd : [SELECT Id, Name, Employee__c, WorkDayDate__c FROM WorkDay__c WHERE Employee__c IN :relatedEmployeeIdSet AND WorkDayDate__c IN :entryDateSet ORDER BY Employee__c, WorkDayDate__c DESC]){

                String uniqueWorkDayEmployeeAndDateId = String.valueOf(wd.Employee__c) + '|' + String.valueOf(wd.WorkDayDate__c);
                workDayUniqueStringToRecordMap.put(uniqueWorkDayEmployeeAndDateId, wd);
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.EntryDate__c != null){
                    String uniqueEntryEmployeeAndDateId = String.valueOf(entry.Employee__c) + '|' + String.valueOf(entry.EntryDate__c);
                    if(workDayUniqueStringToRecordMap.containsKey(uniqueEntryEmployeeAndDateId)){
                        if(entry.WorkDay__c != workDayUniqueStringToRecordMap.get(uniqueEntryEmployeeAndDateId).Id){
                            entry.WorkDay__c = workDayUniqueStringToRecordMap.get(uniqueEntryEmployeeAndDateId).Id;
                            entryUpdateList.add(entry);
                        }
                    }
                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('************** Updating ' + entryUpdateList.size() + ' Time Entries with Work Day Lookups **************');
                update entryUpdateList;
            }
            System.debug('END populateTimeEntryWorkDay');
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryWorkDay', null);
        }
    }

    public static void populateTimeEntryForecast(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){
        try{
            Set<Id> employeeIdSet = new Set<Id>();
            Set<Id> projectIdSet = new Set<Id>();
            Set<Date> weekStartDateSet = new Set<Date>();

            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.EntryDate__c != null){
                    employeeIdSet.add(entry.Employee__c);
                    projectIdSet.add(entry.Project__c);
                    weekStartDateSet.add(entry.EntryDate__c.toStartOfWeek());
                }
            }

            /*List<RepliconForecast__c> relatedForecastList = new List<RepliconForecast__c>();
            relatedForecastList = [SELECT Id, Name, EstimatedHours__c, ProjectTeamMemberBillingRate__c, Week_Start_Date__c, Week_End_Date__c, Project__c, Contact__c, NotForecasted__c, Internal_Project_Team_Member__c
                                    FROM RepliconForecast__c
                                    WHERE Deleted_in_Replicon__c = false AND Contact__c IN :employeeIdSet AND Project__c IN :projectIdSet AND Week_Start_Date__c IN :weekStartDateSet
                                    ORDER BY Project__c, Contact__c, Week_Start_Date__c, CreatedDate ASC];*/

            Map<String, RepliconForecast__c> forecastUniqueIdToForecastMap = new Map<String, RepliconForecast__c>();
            for(RepliconForecast__c forecast : [SELECT Id, Name, EstimatedHours__c, ProjectTeamMemberBillingRate__c, Week_Start_Date__c, Week_End_Date__c, Project__c, Contact__c, NotForecasted__c, Internal_Project_Team_Member__c
                                                FROM RepliconForecast__c
                                                WHERE Deleted_in_Replicon__c = false AND Contact__c IN :employeeIdSet AND Project__c IN :projectIdSet AND Week_Start_Date__c IN :weekStartDateSet
                                                ORDER BY Project__c, Contact__c, Week_Start_Date__c, CreatedDate ASC]){

                String forecastUniqueId = String.valueOf(forecast.Project__c) + ' | ' + String.valueOf(forecast.Contact__c) + ' | ' + String.valueOf(forecast.Week_Start_Date__c);

                if(forecastUniqueIdToForecastMap.containsKey(forecastUniqueId)){
                    RepliconForecast__c existingForecast = forecastUniqueIdToForecastMap.get(forecastUniqueId);
                    if(existingForecast.NotForecasted__c && !forecast.NotForecasted__c){
                        forecastUniqueIdToForecastMap.put(forecastUniqueId, forecast);
                    }
                }else{
                    forecastUniqueIdToForecastMap.put(forecastUniqueId, forecast);
                }
            }

            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            List<Replicon_Time_Entry__c> noForecastToLinkEntryList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.EntryDate__c != null){

                    String forecastUniqueId = String.valueOf(entry.Project__c) + ' | ' + String.valueOf(entry.Employee__c) + ' | ' + String.valueOf(entry.EntryDate__c.toStartOfWeek());

                    if(forecastUniqueIdToForecastMap.containsKey(forecastUniqueId)){
                        if(entry.Replicon_Forecast__c != forecastUniqueIdToForecastMap.get(forecastUniqueId).Id){
                            entry.Replicon_Forecast__c = forecastUniqueIdToForecastMap.get(forecastUniqueId).Id;
                            entryUpdateList.add(entry);
                        }
                    }else{
                        //No Matching Forecast exists for the Time Entry to link to
                        noForecastToLinkEntryList.add(entry);
                    }

                }
            }

            if(needsUpdate && entryUpdateList.size() > 0){
                System.debug('******************************* Updating ' + entryUpdateList.size() + ' Time Entries with Forecast Lookups ******************************************');
                update entryUpdateList;
            }

            if(noForecastToLinkEntryList.size() > 0){
                createNewForecastForTimeEntry(noForecastToLinkEntryList, needsUpdate);
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'populateTimeEntryForecast', null);
        }
    }

    public static void createNewForecastForTimeEntry(List<Replicon_Time_Entry__c> entryList, Boolean needsUpdate){

        try{
            Map<String, RepliconForecast__c> uniqueForecastIdToForecastMap = new Map<String, RepliconForecast__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.EntryDate__c != null){

                    String forecastUniqueId = String.valueOf(entry.Project__c) + ' | ' + String.valueOf(entry.Employee__c) + ' | ' + String.valueOf(entry.EntryDate__c.toStartOfWeek());

                    if(!uniqueForecastIdToForecastMap.containsKey(forecastUniqueId)){
                        //Create Forecast
                        String cogEmployeeId;
                        if(entry.Cognizant_Employee_Id__c != null){
                            cogEmployeeId = entry.Cognizant_Employee_Id__c;
                        }else if(contactIdToRecordPublicMap.containsKey(entry.Employee__c)){
                            cogEmployeeId = contactIdToRecordPublicMap.get(entry.Employee__c).Cognizant_Employee_Id__c;
                        }

                        String projPeoplesoftId;
                        if(entry.Peoplesoft_Project_Id__c != null){
                            projPeoplesoftId = entry.Peoplesoft_Project_Id__c;
                        }else if(projectIdToRecordPublicMap.containsKey(entry.Project__c) && projectIdToRecordPublicMap.get(entry.Employee__c) != null && projectIdToRecordPublicMap.get(entry.Employee__c).Peoplesoft_Project_Id__c != null){
                            projPeoplesoftId = projectIdToRecordPublicMap.get(entry.Employee__c).Peoplesoft_Project_Id__c;
                        }

                        RepliconForecast__c newForecast = new RepliconForecast__c(Project__c = entry.Project__c, Contact__c = entry.Employee__c, Peoplesoft_Project_Id__c = projPeoplesoftId, Cognizant_Employee_Id__c = cogEmployeeId,
                                                                                    EstimatedHours__c = 0, Week_Start_Date__c = entry.EntryDate__c.toStartOfWeek(), Week_End_Date__c = entry.EntryDate__c.toStartOfWeek().addDays(6),
                                                                                    Internal_Project_Team_Member__c = entry.Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c = entry.Associated_Billing_Rate__c, Is_Lev_Forecast__c = entry.Is_Lev_Time__c);
                        
                        String forecastName = String.valueOf((entry.EntryDate__c.toStartOfWeek()).format()) + '-' + String.valueOf((entry.EntryDate__c.toStartOfWeek().addDays(6)).format()) + '-';
                        forecastName += String.valueOf(cogEmployeeId) + '-' + String.valueOf(projPeoplesoftId);
                        newForecast.Name = forecastName;

                        if(projectIdToRecordPublicMap.containsKey(entry.Project__c)){
                            newForecast.Project_Name__c = projectIdToRecordPublicMap.get(entry.Project__c).Name;
                        }

                        uniqueForecastIdToForecastMap.put(forecastUniqueId, newForecast);
                    }
                }
            }

            if(uniqueForecastIdToForecastMap.values().size() > 0){
                insert uniqueForecastIdToForecastMap.values();
            }

            List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                if(entry.Employee__c != null && entry.Project__c != null && entry.EntryDate__c != null){
                    String forecastUniqueId = String.valueOf(entry.Project__c) + ' | ' + String.valueOf(entry.Employee__c) + ' | ' + String.valueOf(entry.EntryDate__c.toStartOfWeek());

                    if(uniqueForecastIdToForecastMap.containsKey(forecastUniqueId)){
                        entry.Replicon_Forecast__c = uniqueForecastIdToForecastMap.get(forecastUniqueId).Id;
                        updateEntryList.add(entry);
                    }
                }
            }

            if(needsUpdate && updateEntryList.size() > 0){
                System.debug('************************************* Updating ' + updateEntryList.size() + ' Time Entries with NEWLY CREATED Forecast Lookups *************************************');
                update updateEntryList;
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'TimeEntryService', 'createNewForecastForTimeEntry', null);
        }
    }

    public static void populateAllTimeEntryLookupFields(){
    }


    
}