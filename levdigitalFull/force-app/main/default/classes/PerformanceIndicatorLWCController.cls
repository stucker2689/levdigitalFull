/**
 * Created 5/25/2022 ST
 * 
 * Purpose: The Apex controller of multiple LWCs that are contained in the Performance Indicator Tab on the Contact Record Page
 */
public with sharing class PerformanceIndicatorLWCController {

    private static String nonbillOrConcessionCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Nonbill Request').getRecordTypeId();

    @AuraEnabled(cacheable = true)
    public static List<concessionNonBillCaseWrapper> getConccessionAndNonBillCases(String contactRecordId){
        //Controlling Apex Method for the Nonbill / Concession Requests for Staffed Projects LWC
        try {
            //Get Replicon Project Team Members to get the Projects that the Contact is one and engaged in Billing with
            /*List<Project_Team_Member__c> teamMemberList = new List<Project_Team_Member__c>();
            teamMemberList = [SELECT Id, Name, Project__c, Employee__c
                                FROM Project_Team_Member__c
                                WHERE Employee__c =: contactRecordId AND Project__r.Project_Status__c IN ('Active', 'On Hold', 'Not Started') AND Project__c != null];

            List<Id> relatedProjectIdList = new List<Id>();
            for(Project_Team_Member__c projTeamMember : teamMemberList){
                relatedProjectIdList.add(projTeamMember.Project__c);
            }*/

            //Get Internal Project Team Members to get the Projects that the Contact is one and engaged in Billing with
            List<Client_Contact__c> projTeamMemberList = new List<Client_Contact__c>();
            projTeamMemberList = [SELECT Id, Name, Project__c, Client_Contact__c
                                FROM Client_Contact__c
                                WHERE Client_Contact__c =: contactRecordId AND Project__r.Project_Status__c IN ('Active', 'On Hold', 'Not Started') AND Project__c != null];

            List<Id> relatedProjectIdList = new List<Id>();
            for(Client_Contact__c projTeamMember : projTeamMemberList){
                relatedProjectIdList.add(projTeamMember.Project__c);
            }


            List<Case> concessionOrNonBillCaseList = new List<Case>();
            concessionOrNonBillCaseList = [SELECT Id, Subject, Approved_Denied__c, Final_Hours_Approved__c, Final_Hours_Logged__c, Project__c, Project__r.Name, Total_Hours_Requested__c
                                            FROM Case
                                            WHERE Project__c IN :relatedProjectIdList AND RecordTypeId =: nonbillOrConcessionCaseRT
                                            ORDER BY Project__c];

            List<concessionNonBillCaseWrapper> casesForLWCTable = new List<concessionNonBillCaseWrapper>();
            for(Case c : concessionOrNonBillCaseList){
                concessionNonBillCaseWrapper newWrapper = new concessionNonBillCaseWrapper();
                newWrapper.caseId = c.Id;
                newWrapper.caseUrl = '/' + c.Id;
                newWrapper.caseSubject = c.Subject;
                newWrapper.approvedOrDenied = c.Approved_Denied__c;
                newWrapper.totalHoursRequested = c.Total_Hours_Requested__c;
                newWrapper.finalHoursApproved = c.Final_Hours_Approved__c;
                newWrapper.finalHoursLogged = c.Final_Hours_Logged__c;
                newWrapper.caseProjectId = c.Project__c;
                newWrapper.caseProjectName = c.Project__r.Name;
                newWrapper.caseProjectUrl = '/' + c.Project__c;
                casesForLWCTable.add(newWrapper);
            }

            return casesForLWCTable;
            
        } catch (Exception e) {
            System.debug('getConccessionAndNonBillCases ERROR!!' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class concessionNonBillCaseWrapper {
        @AuraEnabled
        public Id caseId {get;set;}
        @AuraEnabled
        public String caseUrl {get;set;}
        @AuraEnabled
        public String caseSubject {get;set;}
        @AuraEnabled
        public String approvedOrDenied {get;set;}
        @AuraEnabled
        public Decimal totalHoursRequested {get;set;}
        @AuraEnabled
        public Decimal finalHoursApproved {get;set;}
        @AuraEnabled
        public Decimal finalHoursLogged {get;set;}
        @AuraEnabled
        public String caseProjectId {get;set;}
        @AuraEnabled
        public String caseProjectName {get;set;}
        @AuraEnabled
        public String caseProjectUrl {get;set;}
    }


    @AuraEnabled(cacheable = true)
    public static List<hoursPerQuarterWrapper> getHoursPerQuarterForContact(String contactRecordId){
        //Controlling Apex Method for the Hours Per Quarter Datatable LWC
        try {
            //Get Replicon Time Entries related to the Contact Id
            List<Replicon_Time_Entry__c> relatedEntryList = new List<Replicon_Time_Entry__c>();
            relatedEntryList = [SELECT Id, TotalHrs__c, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Billing_Rate__c, Billable_Amount__c, EntryDate__c, Is_Billable__c, Project__r.Name, Project__c, Project__r.Peoplesoft_Project_ID__c, Project__r.RepliconURI__c
                                FROM Replicon_Time_Entry__c
                                WHERE Employee__c =: contactRecordId AND Deleted_in_Replicon__c = false AND TotalHrs__c != 0 AND Time_Off__c = false AND EntryDate__c != null
                                ORDER BY EntryDate__c DESC];

            Date currentQuarterStartDate = getQuarterStartDateFromDate(Date.today());
            Date previousQuarterStartDate = currentQuarterStartDate.addMonths(-3);
            Date twoBeforeCurrentQuarterStartDate = previousQuarterStartDate.addMonths(-3);
            Date threeBeforeCurrentQuarterStartDate = twoBeforeCurrentQuarterStartDate.addMonths(-3);
            List<Date> currentAndPreviousThreeQuarterStartDateList = new List<Date>{currentQuarterStartDate, previousQuarterStartDate, twoBeforeCurrentQuarterStartDate, threeBeforeCurrentQuarterStartDate};

            Map<Date, hoursPerQuarterWrapper> quarterStartDateToHoursWrapper = new Map<Date, hoursPerQuarterWrapper>();
            for(Date quarterStartDate : currentAndPreviousThreeQuarterStartDateList){
                //Initialize the values for the current and previous 3 quarters to ensure that at least 4 values are in the table at all times
                hoursPerQuarterWrapper newWrapper = new hoursPerQuarterWrapper();   
                newWrapper.quarterName = getQuarterNameFromDate(quarterStartDate);
                newWrapper.billableHours = 0;
                newWrapper.concessionHours = 0; 
                newWrapper.internalConcessionHours = 0;
                newWrapper.nonBillHours = 0;
                newWrapper.totalCreditedHours = 0;
                quarterStartDateToHoursWrapper.put(quarterStartDate, newWrapper);
            }

            for(Replicon_Time_Entry__c entry : relatedEntryList){

                Date entryQuarterStartDate = getQuarterStartDateFromDate(entry.EntryDate__c);

                if(!quarterStartDateToHoursWrapper.containsKey(entryQuarterStartDate)){ //If the quarter start date is not already in the map add to it and initialize it with 0 hours for the quarter
                    hoursPerQuarterWrapper newWrapper = new hoursPerQuarterWrapper();   
                    newWrapper.quarterName = getQuarterNameFromDate(entryQuarterStartDate);
                    newWrapper.billableHours = 0;
                    newWrapper.concessionHours = 0;
                    newWrapper.internalConcessionHours = 0;
                    newWrapper.nonBillHours = 0;
                    newWrapper.totalCreditedHours = 0;
                    quarterStartDateToHoursWrapper.put(entryQuarterStartDate, newWrapper);
                }

                if(quarterStartDateToHoursWrapper.containsKey(entryQuarterStartDate)){
                    hoursPerQuarterWrapper updateWrapper = quarterStartDateToHoursWrapper.get(entryQuarterStartDate);
                    if(entry.Associated_Billing_Rate__c != null && entry.Billable_Amount__c > 0){ //Add to Billable Hours
                        updateWrapper.billableHours += entry.TotalHrs__c;
                        
                    }else if(entry.Associated_Billing_Rate__c != null && entry.Billable_Amount__c == 0){ //Add to Concession Hours
                        if(entry.Project__r.RepliconURI__c == 'urn:replicon-tenant:levementum:project:3689'){ //Check to see if it is logged against the internal concession project
                            updateWrapper.internalConcessionHours += entry.TotalHrs__c;
                        }else{
                            updateWrapper.concessionHours += entry.TotalHrs__c;
                        }

                    }else if(entry.Associated_Billing_Rate__c == null){ //Add to Non Bill Hours
                        updateWrapper.nonBillHours += entry.TotalHrs__c;
                    }

                    //Rollup total Credited Hours: Billable + Internal Concession + Project Concession
                    if(entry.Associated_Billing_Rate__c != null){
                        updateWrapper.totalCreditedHours += entry.TotalHrs__c;
                    }

                    quarterStartDateToHoursWrapper.put(entryQuarterStartDate, updateWrapper);
                }
            }

            return quarterStartDateToHoursWrapper.values();
            
        } catch (Exception e) {
            System.debug('getHoursPerQuarterForContact ERROR!!' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class hoursPerQuarterWrapper {
        @AuraEnabled
        public String quarterName {get;set;}
        @AuraEnabled
        public Decimal billableHours {get;set;}
        @AuraEnabled
        public Decimal concessionHours {get;set;}
        @AuraEnabled
        public Decimal internalConcessionHours {get;set;}
        @AuraEnabled
        public Decimal nonBillHours {get;set;}
        @AuraEnabled
        public Decimal totalCreditedHours {get;set;}
        
    }

    private static Date getQuarterStartDateFromDate(Date d){        
        Integer dateMonth = d.month();
        Date quarterStartDate;

        switch on dateMonth {
            when 1, 2, 3{
                quarterStartDate = Date.newInstance(d.year(), 1, 1); //Q1
            }
            when 4, 5, 6{
                quarterStartDate = Date.newInstance(d.year(), 4, 1); //Q2
            }
            when 7, 8, 9{
                quarterStartDate = Date.newInstance(d.year(), 7, 1); //Q3
            }
            when 10, 11, 12{
                quarterStartDate = Date.newInstance(d.year(), 10, 1); //Q4
            }
          }
          return quarterStartDate;
    }

    private static String getQuarterNameFromDate(Date d){        
        Integer dateMonth = d.month();
        String quarterName;

        switch on dateMonth {
            when 1, 2, 3{
                quarterName = 'Q1 ' + d.year(); //Q1
            }
            when 4, 5, 6{
                quarterName = 'Q2 ' + d.year(); //Q2
            }
            when 7, 8, 9{
                quarterName = 'Q3 ' + d.year(); //Q3
            }
            when 10, 11, 12{
                quarterName = 'Q4 ' + d.year(); //Q4
            }
          }
          return quarterName;
    }

    @AuraEnabled(cacheable = true)
    public static List<certificationsWrapper> geCertificationsForContact(String contactRecordId){
        //Controlling Apex Method for the Certifications Datatable LWC
        try {
            List<Certification__c> relatedCertList = new List<Certification__c>();
            relatedCertList = [SELECT Id, Name, Type__c, Status__c, Date_Certified__c, Maintenance_Exam__c, MaintenanceExamDate__c
                                FROM Certification__c
                                WHERE Employee__c =: contactRecordId];

            List<certificationsWrapper> certsForTableList = new List<certificationsWrapper>();
            for(Certification__c cert : relatedCertList){
                certificationsWrapper newWrapper = new certificationsWrapper();
                newWrapper.certName = cert.Name;
                newWrapper.certUrl = '/' + cert.Id;
                newWrapper.certType = cert.Type__c;
                newWrapper.certStatus = cert.Status__c;
                newWrapper.certDateCertified = cert.Date_Certified__c;
                newWrapper.certMaintenanceExam = cert.Maintenance_Exam__c;
                newWrapper.certMaintenanceExamDate = cert.MaintenanceExamDate__c;
                certsForTableList.add(newWrapper);
            }            

            return certsForTableList;
            
        } catch (Exception e) {
            System.debug('getHoursPerQuarterForContact ERROR!!' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class certificationsWrapper {
        @AuraEnabled
        public String certName {get;set;}
        @AuraEnabled
        public String certUrl {get;set;}
        @AuraEnabled
        public String certType {get;set;}
        @AuraEnabled
        public String certStatus {get;set;}
        @AuraEnabled
        public Date certDateCertified {get;set;}
        @AuraEnabled
        public String certMaintenanceExam {get;set;}
        @AuraEnabled
        public Date certMaintenanceExamDate {get;set;}
        
    }

    @AuraEnabled(cacheable = true)
    public static List<Contact> getRelatedContact(String contactRecordId){

        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT Id, Name, Quarterly_Target__c, Billed_Hours_this_Quarter__c, QTD_Target_Attainment__c, QTD_Expected_Hours__c
                        FROM Contact
                        WHERE Id =: contactRecordId];

        return contactList;
    }

    @AuraEnabled(cacheable = true)
    public static List<employeeActualsAndForecastWrapper> getProjectActualsVsForecasts(String contactRecordId){
        //Method that fetches data for the Project v Actuals v Forecsat LWC on Contact record
        /**
         * Purpose: Want a stacked bar graph that is grouped by Week End Date
         *          Will have multiple bars for each week in the last 90 days
         *          Each bar for each week end date will be a stacked bar graph of actual hours (billable, non-billable, concession) grouped by Project
         *          Exclude Internal Projects        
         */


        Map<Date, employeeActualsAndForecastWrapper> weekEndDateToWrapperMap = new Map<Date, employeeActualsAndForecastWrapper> ();

        Date currentWeekEndDate = Date.today().toStartOfWeek().addDays(6);
        Date ninetyDaysAgoDate = Date.today().toStartOfWeek().addDays(-90);
        Date ninetyDaysAgoWeekEndDate = ninetyDaysAgoDate.toStartOfWeek().addDays(6);

        Date weekEndDateIterator = ninetyDaysAgoWeekEndDate;

        List<Date> lastNinetyDaysWeekEndDateList = new List<Date>();
        while(weekEndDateIterator <= currentWeekEndDate){
            lastNinetyDaysWeekEndDateList.add(weekEndDateIterator);

            employeeActualsAndForecastWrapper newWrapper = new employeeActualsAndForecastWrapper();
            newWrapper.weekEndDate = weekEndDateIterator;
            newWrapper.totalHours = 0;
            newWrapper.forecastedHours = 0;
            newWrapper.hoursAboveForecast = 0;
            Map<String, projectActualsWrapper> newProjectMap = new Map<String, projectActualsWrapper>();
            newWrapper.projectToWrapperMap = newProjectMap;          
            weekEndDateToWrapperMap.put(newWrapper.weekEndDate, newWrapper);
            weekEndDateIterator = weekEndDateIterator.addDays(7);
        }

        System.debug('Week End Date List: ' + lastNinetyDaysWeekEndDateList);


        List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
        entryList = [SELECT Id, Name, Employee__c, Employee__r.Name, TotalHrs__c, WeekEndDate__c, Is_Billable__c, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Billable_Amount__c, Project__c, Project__r.Name, Employee__r.Current_Utilization_Target__c,
                            Employee__r.Quarterly_Target__c
                        FROM Replicon_Time_Entry__c
                        WHERE Employee__c =: contactRecordId AND WeekEndDate__c IN :lastNinetyDaysWeekEndDateList AND Account__r.Name != 'Levementum LLC' AND Deleted_in_Replicon__c = false AND TotalHrs__c != null AND TotalHrs__c != 0 AND Project__c != null
                        ORDER BY WeekEndDate__c DESC];

        for(Replicon_Time_Entry__c entry : entryList){

            if(weekEndDateToWrapperMap.containsKey(entry.WeekEndDate__c)){
                employeeActualsAndForecastWrapper updateWrapper = weekEndDateToWrapperMap.get(entry.WeekEndDate__c);
                updateWrapper.totalHours += entry.TotalHrs__c;
                updateWrapper.employeeId = entry.Employee__c;
                updateWrapper.employeeName = entry.Employee__r.Name;
                updateWrapper.quarterlyTarget = entry.Employee__r.Quarterly_Target__c;    

                if(updateWrapper.projectToWrapperMap.containsKey(entry.Project__r.Name)){
                    //Get Map, get wrapper object, add total hours,
                    Map<String, projectActualsWrapper> updateProjectMap = updateWrapper.projectToWrapperMap;
                    projectActualsWrapper updateProjectWrapper = updateProjectMap.get(entry.Project__r.Name);
                    updateProjectWrapper.totalProjectHours += entry.TotalHrs__c;
                    updateProjectMap.put(updateProjectWrapper.projectName, updateProjectWrapper);
                    updateWrapper.projectToWrapperMap = updateProjectMap;
                    weekEndDateToWrapperMap.put(updateWrapper.WeekEndDate, updateWrapper);
                }else{
                    //Create map to populate projectToWrapperMap
                    Map<String, projectActualsWrapper> updateProjectMap = updateWrapper.projectToWrapperMap;
                    projectActualsWrapper updateProjectWrapper = new projectActualsWrapper();
                    updateProjectWrapper.projectId = entry.Project__c;
                    updateProjectWrapper.projectName = entry.Project__r.Name;
                    updateProjectWrapper.totalProjectHours = entry.TotalHrs__c;

                    updateProjectMap.put(updateProjectWrapper.projectName, updateProjectWrapper);
                    updateWrapper.projectToWrapperMap = updateProjectMap;
                    weekEndDateToWrapperMap.put(updateWrapper.WeekEndDate, updateWrapper);
                }  
            }
        }

        AggregateResult[] employeeForecastAgg = [SELECT SUM(EstimatedHours__c), Week_End_Date__c, Contact__c, Contact__r.Name conName
                                                    FROM RepliconForecast__c
                                                    WHERE Contact__c =: contactRecordId AND Deleted_in_Replicon__c = false AND EstimatedHours__c != 0 AND Week_End_Date__c = LAST_N_DAYS:90
                                                    GROUP BY Week_End_Date__c, Contact__c, Contact__r.Name
                                                    ORDER BY Week_End_Date__c DESC];

        for(AggregateResult ar : employeeForecastAgg){
            Date weekEndDate = (Date)ar.get('Week_End_Date__c');

            if(weekEndDateToWrapperMap.containsKey(weekEndDate)){
                Id contactId = (Id)ar.get('Contact__c');
                String contactName = (String)ar.get('conName');

                employeeActualsAndForecastWrapper updateWrapper = weekEndDateToWrapperMap.get(weekEndDate);
                updateWrapper.forecastedHours = (Decimal)ar.get('expr0');
                updateWrapper.hoursAboveForecast = updateWrapper.totalHours - updateWrapper.forecastedHours;
                weekEndDateToWrapperMap.put(updateWrapper.WeekEndDate, updateWrapper);
            }
        }

        return weekEndDateToWrapperMap.values();
    }

    public class employeeActualsAndForecastWrapper {
        @AuraEnabled
        public String employeeId {get;set;}
        @AuraEnabled
        public String employeeName {get;set;}
        @AuraEnabled
        public Decimal totalHours {get;set;}
        @AuraEnabled
        public Decimal billableHours {get;set;}
        @AuraEnabled
        public Decimal nonbillableHours {get;set;}
        @AuraEnabled
        public Decimal forecastedHours {get;set;}
        @AuraEnabled
        public Decimal hoursAboveForecast {get;set;}
        @AuraEnabled
        public Date weekEndDate {get;set;}
        @AuraEnabled
        public Decimal quarterlyTarget {get;set;}
        @AuraEnabled
        public Decimal currentUtilizationTarget {get;set;}        
        @AuraEnabled
        public Map<String, projectActualsWrapper> projectToWrapperMap {get;set;}    
    }

    public class projectActualsWrapper {
        @AuraEnabled
        public String projectId {get;set;}
        @AuraEnabled
        public String projectName {get;set;}
        @AuraEnabled
        public Decimal totalProjectHours {get;set;}
    }
}