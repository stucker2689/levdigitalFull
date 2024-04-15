public with sharing class ContactForecastingTableController {

    public static List<String> projectActiveStatusList = new List<String>{'Not Started', 'In Progress', 'On Hold', 'Active'};

    public static ForecastTableDataWrapper getForecastTableData(String contactId){
        ForecastTableDataWrapper forecastTableData = getForecastTableData(contactId, null, null, true);
        return forecastTableData;
    }

    @AuraEnabled(cacheable=true)
    public static ForecastTableDataWrapper getForecastTableData(String contactId, Date startDate, Date endDate, Boolean showOnlyActiveProjects){

        if(startDate == null){
            startDate = Date.today().toStartOfWeek();
        }
        if(endDate == null){
            endDate = Date.today().toStartOfWeek().addMonths(3).toStartOfWeek().addDays(6);
        }
        

        System.debug('Start Date: ' + startDate);
        System.debug('End Date: ' + endDate);    
        System.debug('Contact Id 1: ' + contactId);   

        ForecastTableDataWrapper dataTableWrapper = new ForecastTableDataWrapper();
        //Get All Week Start Dates
        List<Date> weekStartDateList = new List<Date>();
        List<String> weekStartDateStringList = new List<String>();
        List<String> weekStartAndEndRangeStringList = new List<String>();
        Date iterationDate = Date.newInstance(startDate.toStartOfWeek().year(), startDate.toStartOfWeek().month(), startDate.toStartOfWeek().day());
        while(iterationDate <= endDate){
            weekStartDateStringList.add(formatDateToString(iterationDate));
            weekStartDateList.add(iterationDate);

            //Build Forecast Start and End Date Range Strings for Column Headers
            Date weekStartDate = iterationDate;
            Date weekEndDate = iterationDate.addDays(6);
            Datetime weekStartDatetime = Datetime.newInstance(weekStartDate.year(), weekStartDate.month(), weekStartDate.day());
            Datetime weekEndDatetime = Datetime.newInstance(weekEndDate.year(), weekEndDate.month(), weekEndDate.day());

            String dateRangeString = weekStartDatetime.format('MMM d, yyyy') + ' - ' + weekEndDatetime.format('MMM d, yyyy');
            weekStartAndEndRangeStringList.add(dateRangeString);


            iterationDate = iterationDate.addDays(7);
        }

        dataTableWrapper.projectWeekStartDateList = weekStartDateList;
        dataTableWrapper.projectWeekStartStringList = weekStartDateStringList;
        dataTableWrapper.projectWeekStartAndEndRangeStringList = weekStartAndEndRangeStringList;
        dataTableWrapper.tableStartDate = startDate;
        dataTableWrapper.tableEndDate = endDate;

        List<Client_Contact__c> teamMemberList = new List<Client_Contact__c>();
        if(showOnlyActiveProjects){
            teamMemberList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, 
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE (NOT(Project__r.Account__r.Name IN ('Levementum LLC', 'ABC Lev Test', 'ALY TEST'))) AND Client_Contact__c =: contactId AND Project__r.Project_Status__c IN ('Active', 'Not Started', 'On Hold')
                                            ORDER BY Project__r.Name, Client_Contact__r.LastName ASC];
            /*teamMemberList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, 
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE Client_Contact__c =: contactId AND Project__r.Project_Status__c IN ('Active', 'Not Started', 'On Hold')
                                            ORDER BY Project__r.Name, Client_Contact__r.LastName ASC];*/
        }else{
            teamMemberList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, 
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE (NOT(Project__r.Account__r.Name IN ('Levementum LLC', 'ABC Lev Test', 'ALY TEST'))) AND Client_Contact__c =: contactId
                                            ORDER BY Project__r.Name, Client_Contact__r.LastName ASC];

            /*teamMemberList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, 
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE Client_Contact__c =: contactId
                                            ORDER BY Project__r.Name, Client_Contact__r.LastName ASC];*/
        }

        Integer buttonHeight = 40 + (60 * teamMemberList.size());
        dataTableWrapper.dynamicLeftButtonHeightStyle = '';
        dataTableWrapper.dynamicRightButtonHeightStyle = '';
        dataTableWrapper.projectCount = teamMemberList.size();

        Set<Id> contactIdSet = new Set<Id>();
        List<ProjectAllocationDatatableWrapper> forecastTableWrapperList = new List<ProjectAllocationDatatableWrapper>();
        Map<Date, Decimal> weekStartDateToTotalAllocationMap = new Map<Date, Decimal>();
        for(Client_Contact__c cc : teamMemberList){
            contactIdSet.add(cc.Client_Contact__c);

            ProjectAllocationDatatableWrapper newTeamMemberWrapper = new ProjectAllocationDatatableWrapper();
            newTeamMemberWrapper.projectTeamMemberName = cc.Client_Contact__r.Name;
            newTeamMemberWrapper.projectTeamMemberNameLastNameFirst = cc.Client_Contact__r.LastName + ', ' + cc.Client_Contact__r.FirstName;
            newTeamMemberWrapper.projectTeamMemberAssignedBillingRateName = cc.Assigned_Billing_Rate__c != null ? cc.Assigned_Billing_Rate__r.Name : 'N/A';
            newTeamMemberWrapper.projectTeamMemberAssignedBillingRateHourlyRate = cc.Assigned_Billing_Rate__c != null ? cc.Assigned_Billing_Rate__r.Hourly_Rate__c : 210;
            newTeamMemberWrapper.projectTeamMemberId = cc.Id;
            newTeamMemberWrapper.projectTeamMemberContactId = cc.Client_Contact__c;
            newTeamMemberWrapper.projectTeamMemberEmployeeCognizantId = cc.Client_Contact__r.Cognizant_Employee_Id__c;
            newTeamMemberWrapper.projectTeamMemberBillRateId = cc.Assigned_Billing_Rate__c;
            newTeamMemberWrapper.projectTeamMemberTotalProjectAllocationHours = 0;
            newTeamMemberWrapper.projectTeamMemberURL = '/'+ cc.Id;

            newTeamMemberWrapper.projectName = cc.Project__r.Name;
            newTeamMemberWrapper.projectURL = '/'+ cc.Project__c;
            newTeamMemberWrapper.projectId = cc.Project__c;

            Boolean isLevEmployeeBoolean = false;
            if(cc.Client_Contact__c != null && cc.Client_Contact__r.AccountId != null && cc.Client_Contact__r.Account.Name == 'Levementum LLC'){
                isLevEmployeeBoolean = true;
            }
            newTeamMemberWrapper.IsLevEmployee = isLevEmployeeBoolean;

            Boolean isPlaceholder = false;
            if(cc.Client_Contact__c != null && cc.Client_Contact__r.Name == 'Place Holder'){
                isPlaceholder = true;
                newTeamMemberWrapper.placeholderStyleClass = 'placeholderBackground';
                newTeamMemberWrapper.projectTeamMemberNameLastNameFirst = 'Placeholder';
            }
            newTeamMemberWrapper.isPlaceholderEmployee = isPlaceholder;

            //Added 9.13.2023 ST For Outdated Rates
            Boolean hasOutdatedRate = false;
            if(cc.Assigned_Billing_Rate__r.Outdated_Rate__c){
                hasOutdatedRate = true;
            }
            newTeamMemberWrapper.hasOutdatedRateAssigned = hasOutdatedRate;

            List<AllocationDataRollups> allocationRollupsList = new List<AllocationDataRollups>();
            for(Date weekStart : weekStartDateList){
                AllocationDataRollups newAllocationDataRollup = new AllocationDataRollups();
                newAllocationDataRollup.uniqueEmployeeAndWeekStartId = String.valueOf(cc.Client_Contact__c) + ' | ' + String.valueOf(weekStart);
                newAllocationDataRollup.uniqueProjectAndWeekStartId = String.valueOf(cc.Project__c) + ' | ' + String.valueOf(weekStart);
                newAllocationDataRollup.uniqueTeamMemberAndWeekStartId = String.valueOf(cc.Id) + ' | ' + String.valueOf(weekStart);
                newAllocationDataRollup.projectAllocationWeekStartDateString = formatDateToString(weekStart);
                newAllocationDataRollup.projectAllocationWeekStartDate = weekStart;
                newAllocationDataRollup.projectAllocationData = 0;
                newAllocationDataRollup.hasProjectAllocation = false;
                newAllocationDataRollup.projectAllocationClassName = 'invisibleStyle';
                newAllocationDataRollup.otherAllocationData = 0;
                newAllocationDataRollup.hasOtherAllocations = false;
                newAllocationDataRollup.timeOffAllocationData = 0;
                newAllocationDataRollup.hasTimeOffAllocations = false;
                newAllocationDataRollup.totalAllocationHours = 0;
                newAllocationDataRollup.isOverAllocated = false;
                newAllocationDataRollup.allocationDataUniqueId = String.valueOf(cc.Id) +  ' | ' + String.valueOf(weekStart);
                weekStartDateToTotalAllocationMap.put(weekStart, 0); //Added for Weekly Totals
                allocationRollupsList.add(newAllocationDataRollup);
            }

            newTeamMemberWrapper.allocationWeeklyRollups = allocationRollupsList;

            forecastTableWrapperList.add(newTeamMemberWrapper);
        }

        System.debug('Contact Id 2: ' + contactId);
        System.debug('WeekStartDateList: ' + weekStartDateList);

        AggregateResult[] projectAllocationAggregate = [SELECT SUM(EstimatedHours__c) estimatedHoursSum, Contact__c, Contact__r.Name contactName, Internal_Project_Team_Member__c,  Week_Start_Date__c, Project__c, Project__r.Name projName
                                                        FROM RepliconForecast__c
                                                        WHERE Deleted_in_Replicon__c = false AND Contact__c =:contactId AND Week_Start_Date__c IN :weekStartDateList AND EstimatedHours__c != 0
                                                        GROUP BY Contact__c, Contact__r.Name, Internal_Project_Team_Member__c, Week_Start_Date__c, Project__c, Project__r.Name
                                                        ORDER BY Project__c, Week_Start_Date__c ASC];

        Map<String, Decimal> projectAndWeekStartDateIdToProjectAllocationMap = new Map<String, Decimal>();
        Map<Date, Decimal> weekStartDateToProjectAllocationMap = new Map<Date, Decimal>();
        System.debug('projectAllocationAggregate size: ' + projectAllocationAggregate.size());
        for(AggregateResult ar : projectAllocationAggregate){
            Decimal projectAllocatedHours = (Decimal)ar.get('estimatedHoursSum');
            Id employeeId = (Id)ar.get('Contact__c');
            String contactName = (String)ar.get('contactName');
            Date weekStartDate = (Date)ar.get('Week_Start_Date__c');
            Id internalProjTeamMemberId = (Id)ar.get('Internal_Project_Team_Member__c');
            Id projectId = (Id)ar.get('Project__c');
            String projectName = (String)ar.get('projName');

            System.debug('projectId: ' + projectId);
            System.debug('Allocated: ' + projectAllocatedHours + ' on ' + projectName + ' '); 

            //Added 10/24/2023
            String uniqueProjectAndDateId;
            uniqueProjectAndDateId = String.valueOf(projectId) + ' | ' + String.valueOf(weekStartDate);
            if(!projectAndWeekStartDateIdToProjectAllocationMap.containsKey(uniqueProjectAndDateId)){
                //If not yet in the Map then set
                projectAndWeekStartDateIdToProjectAllocationMap.put(uniqueProjectAndDateId, projectAllocatedHours);
            }else{
                //If already in the map then add to the hours
                Decimal existingProjectAllocationHours = projectAndWeekStartDateIdToProjectAllocationMap.get(uniqueProjectAndDateId);
                existingProjectAllocationHours += projectAllocatedHours;
                projectAndWeekStartDateIdToProjectAllocationMap.put(uniqueProjectAndDateId, existingProjectAllocationHours);
            }

            //Added to total up the Total Hours Allocated for each week
            if(!weekStartDateToTotalAllocationMap.containsKey(weekStartDate)){
                weekStartDateToTotalAllocationMap.put(weekStartDate, projectAllocatedHours);
                
                weekStartDateToProjectAllocationMap.put(weekStartDate, projectAllocatedHours);
            }else{
                Decimal totalWeekAllocatedHours = weekStartDateToTotalAllocationMap.get(weekStartDate);
                totalWeekAllocatedHours += projectAllocatedHours;
                System.debug('projectAllocatedHours ' + projectAllocatedHours);
                System.debug('totalWeekAllocatedHours: ' + totalWeekAllocatedHours);
                weekStartDateToTotalAllocationMap.put(weekStartDate, totalWeekAllocatedHours);

                weekStartDateToProjectAllocationMap.put(weekStartDate, totalWeekAllocatedHours);
            }
        }

        System.debug('Week Start To Weekly Allocation: ' + weekStartDateToProjectAllocationMap);

        AggregateResult[] timeOffAggregate = [SELECT SUM(TotalHrs__c) timeOffSum, Employee__c, Timesheet_Period__c
                                                FROM Replicon_Time_Entry__c
                                                WHERE Deleted_in_Replicon__c = false AND Time_Off__c = true AND Employee__c =:contactId AND Timesheet_Period__c IN :weekStartDateList
                                                GROUP BY Employee__c, Internal_Project_Team_Member__c, Timesheet_Period__c
                                                ORDER BY Employee__c, Timesheet_Period__c ASC];

        Map<String, Decimal> employeeAndWeekStartDateIdToTimeOffMap = new Map<String, Decimal>();
        Map<Date, Decimal> weekStartDateToTimeOffAllocationMap = new Map<Date, Decimal>();
        for(AggregateResult ar : timeOffAggregate){
            Decimal timeOffHours = (Decimal)ar.get('timeOffSum');
            Id employeeId = (Id)ar.get('Employee__c');
            Date weekStartDate = (Date)ar.get('Timesheet_Period__c');

            String uniqueEmployeeAndDateId = String.valueOf(employeeId) + ' | ' + String.valueOf(weekStartDate);

            if(!employeeAndWeekStartDateIdToTimeOffMap.containsKey(uniqueEmployeeAndDateId)){
                //If not yet in the Map then set
                employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, timeOffHours);
            }else{
                //If already in the map then add to the hours
                Decimal existingTimeOffHours = employeeAndWeekStartDateIdToTimeOffMap.get(uniqueEmployeeAndDateId);
                existingTimeOffHours += timeOffHours;
                employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, existingTimeOffHours);
            }

            //Added to total up the Total Hours Allocated for each week
            if(!weekStartDateToTotalAllocationMap.containsKey(weekStartDate)){
                weekStartDateToTotalAllocationMap.put(weekStartDate, timeOffHours);

                weekStartDateToTimeOffAllocationMap.put(weekStartDate, timeOffHours);
            }else{
                Decimal totalWeekAllocatedHours = weekStartDateToTotalAllocationMap.get(weekStartDate);
                totalWeekAllocatedHours += timeOffHours;
                weekStartDateToTotalAllocationMap.put(weekStartDate, totalWeekAllocatedHours);

                weekStartDateToTimeOffAllocationMap.put(weekStartDate, totalWeekAllocatedHours);
            }            
        }

        if(weekStartDateToTotalAllocationMap != null){
            dataTableWrapper.weekTotalAllocationHoursList = weekStartDateToTotalAllocationMap.values();
        }

        Map<Date, Integer> weekStartDateToCounterMap = new Map<Date, Integer>();

        for(ProjectAllocationDatatableWrapper wrapper : forecastTableWrapperList){
            wrapper.projectTeamMemberHasProjectAllocation = false;

            for(AllocationDataRollups dataRollup : wrapper.allocationWeeklyRollups){
                Decimal totalAllocation = 0;

                /*********************************** Set Project Allocation Data ***********************************/
                if(projectAndWeekStartDateIdToProjectAllocationMap.containsKey(dataRollup.uniqueProjectAndWeekStartId)){
                    System.debug('Unique Project And Week Start Id inside Map');
                    Decimal projectAllocationHours = projectAndWeekStartDateIdToProjectAllocationMap.get(dataRollup.uniqueProjectAndWeekStartId);
                    dataRollup.projectAllocationData = projectAllocationHours;

                    totalAllocation += projectAllocationHours; //Get Total Allocation across all Forecasts/Time off
                    wrapper.projectTeamMemberTotalProjectAllocationHours += projectAllocationHours; //Get total Project Allocation for Project Team Member Wrapper

                    //Set the Start and End Forecasting Dates. Gets the start date of the earliest forecast they have on the project, and the end date of the latest forecast they have on the project.
                    if(wrapper.projectTeamMemberForecastingStartDate == null || wrapper.projectTeamMemberForecastingStartDate > dataRollup.projectAllocationWeekStartDate.addDays(1)){
                        wrapper.projectTeamMemberForecastingStartDate = dataRollup.projectAllocationWeekStartDate;
                    }

                    if(wrapper.projectTeamMemberForecastingEndDate == null || wrapper.projectTeamMemberForecastingEndDate < dataRollup.projectAllocationWeekStartDate.addDays(6)){
                        wrapper.projectTeamMemberForecastingEndDate = dataRollup.projectAllocationWeekStartDate.addDays(6);
                    }
                    
                    if(projectAllocationHours != 0 && projectAllocationHours != null){
                        dataRollup.hasProjectAllocation = true;
                        dataRollup.projectAllocationClassName = 'unfocusedProjectAllocationBubble';
                        wrapper.projectTeamMemberHasProjectAllocation = true; //Set on the project team member level that they have Forecasts for any week for the project.
                    }
                }

                /*********************************** Set Time Off Allocation Data ***********************************/
                if(employeeAndWeekStartDateIdToTimeOffMap.containsKey(dataRollup.uniqueEmployeeAndWeekStartId)){
                    Decimal timeOffHours = employeeAndWeekStartDateIdToTimeOffMap.get(dataRollup.uniqueEmployeeAndWeekStartId);
                    dataRollup.timeOffAllocationData = timeOffHours;
                    totalAllocation += timeOffHours;

                    if(timeOffHours != 0 && timeOffHours != null){
                        dataRollup.hasTimeOffAllocations = true;
                    }
                }

                /**************************** Set Total Allocation Hours at the Week Level as well as set the Style for the Table cell if the total allocation is over 40 hours **********************/
                dataRollup.totalAllocationHours = totalAllocation;
                if(totalAllocation > 40){
                    dataRollup.isOverAllocated = true;
                    //dataRollup.tableCellStyle = 'bottom:0px;border:2px solid red';
                }else{
                    dataRollup.tableCellStyle = '';
                }

                //Create Counter to find first and last cell in table for Border setting
                if(weekStartDateToCounterMap.containsKey(dataRollup.projectAllocationWeekStartDate)){
                    Integer counter = weekStartDateToCounterMap.get(dataRollup.projectAllocationWeekStartDate);
                    counter++;
                    weekStartDateToCounterMap.put(dataRollup.projectAllocationWeekStartDate, counter);
                }else{
                    Integer counter = 1;
                    weekStartDateToCounterMap.put(dataRollup.projectAllocationWeekStartDate, counter);
                }
                //Check if entire week across all projects is over-allocated
                if(weekStartDateToTotalAllocationMap.containsKey(dataRollup.projectAllocationWeekStartDate)){
                    dataRollup.totalWeekAllocatedHours = weekStartDateToTotalAllocationMap.get(dataRollup.projectAllocationWeekStartDate);
                    if(weekStartDateToTotalAllocationMap.get(dataRollup.projectAllocationWeekStartDate) > 40){
                        if(weekStartDateToCounterMap.get(dataRollup.projectAllocationWeekStartDate) == 1){
                            //For the first Cell in the Over-allocated column
                            dataRollup.isOverAllocated = true;
                            dataRollup.tableCellStyle = 'bottom:0px;border-inline-style:solid;border-inline-color:red;border-inline-width: 3px;border-top: 3px solid red';
                        }else if(weekStartDateToCounterMap.get(dataRollup.projectAllocationWeekStartDate) == forecastTableWrapperList.size()){
                            //For the Last Cell in the Over-allocated column
                            dataRollup.isOverAllocated = true;
                            dataRollup.tableCellStyle = 'bottom:0px;border-inline-style:solid;border-inline-color:red;border-inline-width: 3px;border-bottom: 3px solid red';
                        }else{
                            //For middle cells in the Over-allocated column
                            dataRollup.isOverAllocated = true;
                            dataRollup.tableCellStyle = 'bottom:0px;border-inline-style:solid;border-inline-color:red;border-inline-width: 3px';
                        }
                    }
                }

                if(weekStartDateToProjectAllocationMap.containsKey(dataRollup.projectAllocationWeekStartDate)){
                    System.debug('Week of: ' + dataRollup.projectAllocationWeekStartDate);
                    System.debug('Project Allocation for the Week: ' + weekStartDateToProjectAllocationMap.get(dataRollup.projectAllocationWeekStartDate));
                }

                if(weekStartDateToTimeOffAllocationMap.containsKey(dataRollup.projectAllocationWeekStartDate)){
                    System.debug('Week of: ' + dataRollup.projectAllocationWeekStartDate);
                    System.debug('Time Off Allocation for the Week: ' + weekStartDateToTimeOffAllocationMap.get(dataRollup.projectAllocationWeekStartDate));
                }
            }

            //Populate Project Team member Wrapper after processing from the data allocation loop
            if(wrapper.projectTeamMemberHasProjectAllocation){

                Date forecastRangeStartDate = wrapper.projectTeamMemberForecastingStartDate;
                Date forecastRangeEndDate = wrapper.projectTeamMemberForecastingEndDate;
                Datetime forecastRangeStartDatetime = Datetime.newInstance(forecastRangeStartDate.year(), forecastRangeStartDate.month(), forecastRangeStartDate.day());
                Datetime forecastRangeEndDatetime = Datetime.newInstance(forecastRangeEndDate.year(), forecastRangeEndDate.month(), forecastRangeEndDate.day());

                String dateRangeString = forecastRangeStartDatetime.format('MMM d, yyyy') + ' - ' + forecastRangeEndDatetime.format('MMM d, yyyy');
                
                wrapper.projectTeamMemberForecastingDateRange = dateRangeString;
            }
        }

        dataTableWrapper.teamMemberDataWrapperList = forecastTableWrapperList; //Set the Project Team Member List in the Forecast Table Data Wrapper

        return dataTableWrapper;
    }

    private static String formatDateToString(Date dateToFormat){

        String formattedDate;
        formattedDate = getMonthNameFromNumber(dateToFormat.month()) + ' ' + dateToFormat.day() + ', ' + dateToFormat.year();
        return formattedDate;
    }

    private static String getMonthNameFromNumber(Integer monthNumber){
        String monthName; 
        switch on monthNumber {
            when 1 {
                monthName = 'January';
            }	
            when 2 {
                monthName = 'February';
            }
            when 3 {
                monthName = 'March';
            }
            when 4 {
                monthName = 'April';
            }
            when 5 {		
                monthName = 'May';
            }
            when 6 {
                monthName = 'June';
            }
            when 7 {
                monthName = 'July';
            }
            when 8 {
                monthName = 'August';
            }
            when 9 {
                monthName = 'September';
            }
            when 10 {
                monthName = 'October';
            }
            when 11 {
                monthName = 'November';
            }
            when 12 {
                monthName = 'December';
            }
        }

        return monthName;
    }



    public class ForecastTableDataWrapper{
        @AuraEnabled
        public List<Date> projectWeekStartDateList {get;set;}
        @AuraEnabled
        public List<String> projectWeekStartStringList {get;set;}
        @AuraEnabled
        public List<String> projectWeekStartAndEndRangeStringList {get;set;}
        @AuraEnabled
        public List<ProjectAllocationDatatableWrapper> teamMemberDataWrapperList {get;set;}
        @AuraEnabled
        public Date tableStartDate {get;set;}
        @AuraEnabled
        public Date tableEndDate {get;set;}
        @AuraEnabled
        public List<Decimal> weekTotalAllocationHoursList {get;set;}
        @AuraEnabled
        public String dynamicLeftButtonHeightStyle {get;set;}
        @AuraEnabled
        public String dynamicRightButtonHeightStyle {get;set;}
        @AuraEnabled
        public Integer projectCount {get;set;}
    }

    public class ProjectAllocationDatatableWrapper{
        @AuraEnabled
        public String projectTeamMemberName {get;set;}
        @AuraEnabled
        public String projectTeamMemberNameLastNameFirst {get;set;}
        @AuraEnabled
        public List<AllocationDataRollups> allocationWeeklyRollups {get;set;}
        @AuraEnabled
        public Id projectTeamMemberId {get;set;}
        @AuraEnabled
        public String projectTeamMemberURL {get;set;}
        @AuraEnabled
        public Id projectTeamMemberContactId {get;set;}
        @AuraEnabled
        public Boolean IsLevEmployee {get;set;}
        @AuraEnabled
        public Boolean isPlaceholderEmployee {get;set;}
        @AuraEnabled
        public String placeholderStyleClass {get;set;}
        @AuraEnabled
        public String projectTeamMemberEmployeeCognizantId {get;set;}
        @AuraEnabled
        public Id projectTeamMemberBillRateId {get;set;}
        @AuraEnabled
        public String projectTeamMemberAssignedBillingRateName {get;set;}
        @AuraEnabled
        public Boolean hasOutdatedRateAssigned {get;set;}
        @AuraEnabled
        public Decimal projectTeamMemberAssignedBillingRateHourlyRate {get;set;}
        @AuraEnabled
        public Decimal projectTeamMemberTotalProjectAllocationHours {get;set;}
        @AuraEnabled
        public Boolean projectTeamMemberHasProjectAllocation {get;set;}
        @AuraEnabled
        public Date projectTeamMemberForecastingStartDate {get;set;}
        @AuraEnabled
        public Date projectTeamMemberForecastingEndDate {get;set;}
        @AuraEnabled
        public String projectTeamMemberForecastingDateRange {get;set;}
        @AuraEnabled
        public String projectName {get;set;}
        @AuraEnabled
        public String projectURL {get;set;}
        @AuraEnabled
        public Id projectId {get;set;}
    }

    public class AllocationDataRollups{
        @AuraEnabled
        public String uniqueEmployeeAndWeekStartId {get;set;}
        @AuraEnabled
        public String uniqueProjectAndWeekStartId {get;set;}
        @AuraEnabled
        public String uniqueTeamMemberAndWeekStartId {get;set;}
        @AuraEnabled
        public String projectAllocationWeekStartDateString {get;set;}
        @AuraEnabled
        public Date projectAllocationWeekStartDate {get;set;}
        @AuraEnabled
        public Decimal projectAllocationData {get;set;}
        @AuraEnabled
        public Boolean hasProjectAllocation {get;set;}
        @AuraEnabled
        public String projectAllocationClassName {get;set;}
        @AuraEnabled
        public Decimal otherAllocationData {get;set;}
        @AuraEnabled
        public Boolean hasOtherAllocations {get;set;}
        @AuraEnabled
        public Decimal timeOffAllocationData {get;set;}
        @AuraEnabled
        public Boolean hasTimeOffAllocations {get;set;}
        @AuraEnabled
        public Decimal totalAllocationHours {get;set;}
        @AuraEnabled
        public Boolean isOverAllocated {get;set;}
        @AuraEnabled
        public String tableCellStyle {get;set;}
        @AuraEnabled
        public String allocationDataUniqueId {get;set;}
        @AuraEnabled
        public Decimal totalWeekAllocatedHours {get;set;}
    }

    @AuraEnabled
    public static void upsertForecastFromProjectForecastTable(allocationCreationWrapper wrapper){    

        System.debug('****************************** upsertForecastFromProjectForecastTable START ********************************************');

        System.debug('Contact Id: ' + wrapper.contactId);
        System.debug('Cognizant Employee Id: ' + wrapper.contactCognizantEmployeeId);
        System.debug('Project Id: ' + wrapper.projectId);
        System.debug('Project Name: ' + wrapper.projectName);
        System.debug('Peoplesoft Project Id: ' + wrapper.projectPeoplesoftId);
        System.debug('Start Date: ' + wrapper.allocationRangeStartDate);
        System.debug('End Date: ' + wrapper.allocationRangeEndDate);
        System.debug('Hours for Allocation: ' + wrapper.hoursForAllocation);
        System.debug('Forecast Method: ' + wrapper.allocationEntryMethod);
        System.debug('Project Team Member Id: ' + wrapper.projectTeamMemberId);
        System.debug('Assigned Bill Rate Id: ' + wrapper.projectTeamMemberAssignedBillingRateId);
        System.debug('Contact Id: ' + wrapper.contactId);
        System.debug('Is Placeholder Employee: ' + wrapper.isPlaceholderEmployee);

        try{

            List<RepliconForecast__c> upsertForecastList = new List<RepliconForecast__c>();
            Map<Date, Decimal> weekStartDateToEstimatedHoursMap = new Map<Date, Decimal>();

            if(wrapper.allocationEntryMethod == 'totalHours' || wrapper.allocationEntryMethod == 'hoursPerDay' || wrapper.allocationEntryMethod == 'hoursPerWeek'){
                /**
                 * For Total Hours we have a start and end date and a total hours # to split up for each day/week within the date range
                 * 
                 * Steps:
                 * 1.) Get the hours per day within the range (Estimated Hours / Work Days in range)
                 * 2.) Get the amount of weeks within the date range (If more than one week, then get the date ranges of each week within the larger date range)
                 * 3.) Create map of Week Start Date to Decimal value of how many estimated hours for the forecast entry
                 * 4.) Check if there are existing forecast entries for the contact and for the week start dates
                 * 5a.) If a matching forecast exists, then get the forecast and update the estimated hours
                 * 5b.) If matching forecast DOES NOT exist, then create new forecast and set the estimated hours
                 */

                Date startDate = wrapper.allocationRangeStartDate;
                Date endDate = wrapper.allocationRangeEndDate;
                Decimal totalAllocationHours;
                Decimal allocationPerDayHours;
                Decimal allocationPerWeekHours;

                //Get the Allocation Hours per day
                if(wrapper.allocationEntryMethod == 'totalHours'){
                    totalAllocationHours = wrapper.hoursForAllocation;

                    Decimal workingDaysInRange = calculateWorkingDaysBetweenTwoDates(startDate, endDate);
                    workingDaysInRange = workingDaysInRange != 0 ? workingDaysInRange : 1;
                    allocationPerDayHours = totalAllocationHours / workingDaysInRange;

                }else if(wrapper.allocationEntryMethod == 'hoursPerDay'){
                    allocationPerDayHours = wrapper.hoursForAllocation;
                }else if(wrapper.allocationEntryMethod == 'hoursPerWeek'){
                    allocationPerWeekHours = wrapper.hoursForAllocation;
                }

                if(wrapper.allocationEntryMethod == 'totalHours' || wrapper.allocationEntryMethod == 'hoursPerDay'){
                    System.debug('Allocation Per Day Hours: ' + allocationPerDayHours);
                    Date iterationDate = startDate;
                    Integer iterationCount = 0;
                    do{
                        //Create Map with the Start Dates of each week included in the Date Range
                        System.debug('Iteration Date: ' + iterationDate);
                        Date iterationWeekEndDate = iterationDate.toStartOfWeek().addDays(6);
                        if(endDate < iterationWeekEndDate){
                            iterationWeekEndDate = endDate;

                        }
                        Decimal workingDaysInRange = calculateWorkingDaysBetweenTwoDates(iterationDate, iterationWeekEndDate);
                        System.debug('Working Days in Range: ' + workingDaysInRange);
                        Decimal estimatedHoursForForecastWeek = allocationPerDayHours * workingDaysInRange;
                        estimatedHoursForForecastWeek = estimatedHoursForForecastWeek.setScale(2, System.RoundingMode.HALF_DOWN);
                        System.debug('Estimated Hours for Forecast Week: ' + estimatedHoursForForecastWeek);
                        weekStartDateToEstimatedHoursMap.put(iterationDate.toStartOfWeek(), estimatedHoursForForecastWeek);

                        iterationDate = iterationDate.toStartOfWeek().addDays(7); //Go to next week and check if the allocation should keep looping

                        iterationCount++;
                        System.debug('Iteration Count: ' + iterationCount);
                        /*if(iterationCount == 10){
                            break;
                        }*/

                    }while(iterationDate < endDate);

                    System.debug('Week Start Date to Estimated Hours Map: ' + weekStartDateToEstimatedHoursMap);

                }else if(wrapper.allocationEntryMethod == 'hoursPerWeek'){
                    startDate = startDate.toStartOfWeek(); //For Per Week Forecasting we take the whole week regardless of when in the week the start date is
                    Date iterationDate = startDate;

                    Datetime endDatetime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day());
                    if(endDatetime.format('EEEE') == 'Sunday'){ //If it ends on Sunday, then don't include that week
                        endDate = endDate.addDays(-1);
                    }

                    Integer iterationCount = 0;
                    
                    do{
                        //Create Map with the Start Dates of each week included in the Date Range
                        Decimal estimatedHoursForForecastWeek = allocationPerWeekHours;
                        weekStartDateToEstimatedHoursMap.put(iterationDate.toStartOfWeek(), estimatedHoursForForecastWeek);
    
                        iterationDate = iterationDate.toStartOfWeek().addDays(7); //Go to next week and check if the allocation should keep looping
    
                        iterationCount++;
                        System.debug('Iteration Count: ' + iterationCount);
                        /*if(iterationCount == 10){
                            break;
                        }*/
    
                    }while(iterationDate < endDate);
                }
            }else if(wrapper.allocationEntryMethod == 'onBlur'){

                weekStartDateToEstimatedHoursMap.put(wrapper.allocationRangeStartDate, wrapper.hoursForAllocation);

            }

            Map<Date, RepliconForecast__c> weekStartDateToExistingForecastMap = new Map<Date, RepliconForecast__c>();
            List<RepliconForecast__c> existingForecastList = new List<RepliconForecast__c>();
            if(!wrapper.isPlaceholderEmployee && wrapper.contactId != '0030W00003n00V7QAI'){
            existingForecastList = [SELECT Id, Name, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Peoplesoft_Project_Id__c, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Cognizant_Employee_Id__c, 
                                        EstimatedHours__c, Deleted_in_Replicon__c, ProjectTeamMemberBillingRate__c, Week_Start_Date__c, Week_End_Date__c, ProjectRole__c, NotForecasted__c
                                    FROM RepliconForecast__c
                                    WHERE Kickoff_Placeholder_Forecast__c = false AND Project__c =: wrapper.projectId AND Contact__c =: wrapper.contactId AND Week_Start_Date__c IN :weekStartDateToEstimatedHoursMap.keySet()
                                    ORDER BY Contact__c, Week_Start_Date__c, CreatedDate DESC];
            }else{
                existingForecastList = [SELECT Id, Name, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Peoplesoft_Project_Id__c, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Cognizant_Employee_Id__c, 
                                        EstimatedHours__c, Deleted_in_Replicon__c, ProjectTeamMemberBillingRate__c, Week_Start_Date__c, Week_End_Date__c, ProjectRole__c, NotForecasted__c
                                    FROM RepliconForecast__c
                                    WHERE Kickoff_Placeholder_Forecast__c = false AND Project__c =: wrapper.projectId AND Internal_Project_Team_Member__c =: wrapper.projectTeamMemberId AND Week_Start_Date__c IN :weekStartDateToEstimatedHoursMap.keySet()
                                    ORDER BY Contact__c, Week_Start_Date__c, CreatedDate DESC];
            }

            for(RepliconForecast__c forecast : existingForecastList){
                if(weekStartDateToExistingForecastMap.containsKey(forecast.Week_Start_Date__c)){
                    //If already in the map, then if the existing one is NotForecasted = true then replace it otherwise leave it.
                    RepliconForecast__c existingForecast = weekStartDateToExistingForecastMap.get(forecast.Week_Start_Date__c);
                    if(existingForecast.NotForecasted__c == true){
                        weekStartDateToExistingForecastMap.put(forecast.Week_Start_Date__c, forecast);
                    }
                }else{
                    weekStartDateToExistingForecastMap.put(forecast.Week_Start_Date__c, forecast);
                }
            }

            for(Date weekStartDate : weekStartDateToEstimatedHoursMap.keySet()){

                if(weekStartDateToExistingForecastMap.containsKey(weekStartDate)){ //If Existing Forecast already exists for the same week, then adjust the hours and update
                    RepliconForecast__c existingForecast = weekStartDateToExistingForecastMap.get(weekStartDate);
                    existingForecast.EstimatedHours__c = weekStartDateToEstimatedHoursMap.get(weekStartDate);
                    upsertForecastList.add(existingForecast);

                }else{ //If existing forecast does NOT already exist for the same week then create the forecast and insert
                    System.debug('None Found');
                    upsertForecastList.add(createNewForecastFromWrapper(weekStartDate, weekStartDateToEstimatedHoursMap.get(weekStartDate), wrapper));

                }
            }

            if(upsertForecastList.size() > 0){
                System.debug('***************************************** Upserting ' + upsertForecastList.size() + ' Forecasts from Project Forecasting Table *****************************************');
                upsert upsertForecastList;

            }
            
        }catch(Exception e){
            System.debug('Exception Caught: ' + e.getMessage());
        }

    }

    public static RepliconForecast__c createNewForecastFromWrapper(Date startDate, Decimal allocatedHours, allocationCreationWrapper wrapper){

        RepliconForecast__c newForecast = new RepliconForecast__c();
        newForecast.Project__c = (Id)wrapper.projectId;
        newForecast.Project_Name__c = wrapper.projectName;
        newForecast.Peoplesoft_Project_Id__c = wrapper.projectPeoplesoftId;
        newForecast.Contact__c = (Id)wrapper.contactId;
        newForecast.Cognizant_Employee_Id__c = wrapper.contactCognizantEmployeeId;
        newForecast.EstimatedHours__c = allocatedHours;
        newForecast.Week_Start_Date__c = startDate;
        newForecast.Week_End_Date__c = startDate.toStartOfWeek().addDays(6);
        System.debug('New Forecast PTM Id: ' + wrapper.projectTeamMemberId);
        newForecast.Internal_Project_Team_Member__c = wrapper.projectTeamMemberId;
        System.debug('New Forecast Rate Id: ' + wrapper.projectTeamMemberAssignedBillingRateId);
        newForecast.ProjectTeamMemberBillingRate__c = wrapper.projectTeamMemberAssignedBillingRateId;
        newForecast.Is_Lev_Forecast__c = wrapper.contactIsLevEmployeeBoolean;

        String timesheetStartString = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('MM/dd/YYYY');
        String timesheetEndString = DateTime.newInstance(newForecast.Week_End_Date__c.year(), newForecast.Week_End_Date__c.month(), newForecast.Week_End_Date__c.day()).format('MM/dd/YYYY');

        String forecastName;
        if(wrapper.isPlaceholderEmployee){
            forecastName = timesheetStartString + '-' + timesheetEndString + '-' + '0' + '-' + wrapper.projectTeamMemberAssignedBillingRateName + '-' + wrapper.projectPeoplesoftId;
        }else if(wrapper.contactId == '0030W00003n00V7QAI'){
            forecastName = timesheetStartString + '-' + timesheetEndString + '-' + 'ATG' + '-' + wrapper.projectTeamMemberAssignedBillingRateName + '-' + wrapper.projectPeoplesoftId;
        }else{
            forecastName = timesheetStartString + '-' + timesheetEndString + '-' + wrapper.contactCognizantEmployeeId + '-' + wrapper.projectPeoplesoftId;
        }

        newForecast.Name = forecastName.left(80);

        return newForecast;
    }

    @AuraEnabled
    public static Integer calculateWorkingDaysBetweenTwoDates(Date date1, Date date2){

        List<Holiday> companyHolidayList = [SELECT Id, Name, ActivityDate, IsAllDay FROM Holiday ORDER BY ActivityDate];

        Integer allDaysBetween = date1.daysBetween(date2);
        Integer allWorkingDays = 0;
        for(Integer k = 0; k <= allDaysBetween; k++ ){
            if(checkifItisWorkingDay(date1.addDays(k), companyHolidayList)){
                allWorkingDays++;
            } 
        }
        return allWorkingDays;
    }

    public static boolean checkifItisWorkingDay(Date currentDate,List<Holiday> companyHolidayList){
        Date weekStart  = currentDate.toStartofWeek();
        for(Holiday hDay : companyHolidayList){
            if(currentDate.daysBetween(hDay.ActivityDate) == 0){
                return false;
            }
        }

        if(weekStart.daysBetween(currentDate) == 0 || weekStart.daysBetween(currentDate) == 6){
            return false;
        }else{
            return true;
        }
    }

    public class allocationCreationWrapper{
        @AuraEnabled
        public String contactId {get;set;}
        @AuraEnabled
        public String contactCognizantEmployeeId {get;set;}
        @AuraEnabled
        public Boolean contactIsLevEmployeeBoolean {get;set;}
        @AuraEnabled
        public Boolean isPlaceholderEmployee {get;set;}
        @AuraEnabled
        public String projectId {get;set;}
        @AuraEnabled
        public String projectName {get;set;}
        @AuraEnabled
        public String projectPeoplesoftId {get;set;}
        @AuraEnabled
        public String projectTeamMemberId {get;set;}
        @AuraEnabled
        public String projectTeamMemberAssignedBillingRateId {get;set;}
        @AuraEnabled
        public String projectTeamMemberAssignedBillingRateName {get;set;}
        @AuraEnabled
        public Date allocationRangeStartDate {get;set;}
        @AuraEnabled
        public Date allocationRangeEndDate {get;set;}
        @AuraEnabled
        public Decimal hoursForAllocation {get;set;}
        @AuraEnabled
        public String allocationEntryMethod {get;set;}
    }


    @AuraEnabled(cacheable=true)
    public static List<Product2> getPlaceholderRoles(){
        try {

            List<Product2> placeholderProductRoleList = new List<Product2>();

            List<Product2> productsList = new List<Product2>();
            productsList = [SELECT Id, Name, IsActive
                            FROM Product2
                            WHERE IsActive = true AND (NOT Name LIKE '%Margin User%') AND (NOT Name IN ('Adobe Consulting', 'Adobe Consultant'))
                            ORDER BY Name];

            for(Product2 p : productsList){
                placeholderProductRoleList.add(p);
            }

            return placeholderProductRoleList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Client_Contact__c createPlaceholder(String projectId, String projectName, String contactId, String placeholderRoleName, String productId){

        /**
         * 1.) Check to see if there is a billing rate on the project with the same name as the Placeholder Role Name
         * 2a.) If there is a match then prep that Bill Rate to assign to the Placeholder Internal Project Team Member
         * 2b.) If no match, then create the bill rate with hourly rate of average bill rate for org (average bill rate is on capacity record)
         * 3.) Check if Placeholder with the rate already exists, if they do add a 2 or 3 or etc... to the Internal Project Team Member Name
         * 4.) Insert Placeholder Internal Project Team Member
         */

        List<Project_Team_Member_Billing_Rate__c> relatedProjectBillRateList = new List<Project_Team_Member_Billing_Rate__c>();
        relatedProjectBillRateList = [SELECT Id, Name, Created_in_Salesforce__c, Hourly_Rate__c, Project__c, Product__c, Product__r.Name
                                        FROM Project_Team_Member_Billing_Rate__c
                                        WHERE Project__c =: projectId AND Product__c =: productId AND Created_in_Salesforce__c = true
                                        ORDER BY Hourly_Rate__c ASC];

        Id assignedBillingRateId;
        if(relatedProjectBillRateList.size() > 0){
            for(Project_Team_Member_Billing_Rate__c rate : relatedProjectBillRateList){
                assignedBillingRateId = rate.Id;
            }
        }else{
            //If no matching Rate exists yet then create one
            Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c();
            newRate.Name = placeholderRoleName;
            newRate.Created_in_Salesforce__c = true;
            newRate.Is_Placeholder_Rate__c = true;
            newRate.Hourly_Rate__c = 210;
            newRate.Project__c = (Id)projectId;
            newRate.Product__c = (Id)productId;
            insert newRate;

            assignedBillingRateId = newRate.Id;
        }

        List<Client_Contact__c> existingPlaceholderTeamMemberList = new List<Client_Contact__c>();
        existingPlaceholderTeamMemberList = [SELECT Id, Name, Internal_Project_Team_Member_Name__c, Client_Contact__c, Client_Contact__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name
                                                FROM Client_Contact__c
                                                WHERE Project__c =: projectId AND Client_Contact__c =: contactId AND Assigned_Billing_Rate__c =: assignedBillingRateId];

        String projectTeamMemberName = 'Place Holder - ' + projectName;
        if(existingPlaceholderTeamMemberList.size() > 0){
            projectTeamMemberName += ' ' + String.valueOf(existingPlaceholderTeamMemberList.size() + 1);
            String message = 'A Place Holder with this same Role already exists on this project.';
                AuraHandledException auraError = new AuraHandledException(message);
                auraError.setMessage('A Place Holder with this same Role already exists on this project.');
                throw auraError;
        }
        
        Client_Contact__c newPlaceholderProjectTeamMember = new Client_Contact__c();
        newPlaceholderProjectTeamMember.Project__c = (Id)projectId;
        newPlaceholderProjectTeamMember.Client_Contact__c = (Id)contactId;
        newPlaceholderProjectTeamMember.Internal_Project_Team_Member_Name__c = projectTeamMemberName;
        newPlaceholderProjectTeamMember.Assigned_Billing_Rate__c = assignedBillingRateId;
        newPlaceholderProjectTeamMember.Is_Placeholder_Team_Member__c = true;

        return newPlaceholderProjectTeamMember;
    }

    @AuraEnabled
    public static void replacePlaceholderWithUser(String placeholderTeamMemberId, String contactId, String peoplesoftProjectId, String projectId, String projectName, String replacementBillRateId){

        Contact replacementContact = [SELECT Id, Name, Cognizant_Employee_Id__c, AccountId, Account.Name
                                        FROM Contact
                                        WHERE Id =: contactId LIMIT 1];


        List<Client_Contact__c> teamMemberList = [SELECT Id, Name, Client_Contact__c, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Is_Placeholder_Rate__c, 
                                                        Assigned_Billing_Rate__r.Product__c, Assigned_Billing_Rate__r.Hourly_Rate__c
                                                    FROM Client_Contact__c 
                                                    WHERE Project__c =: projectId AND (Id =: placeholderTeamMemberId OR Client_Contact__c =: contactId)];

        List<Project_Team_Member_Billing_Rate__c> existingProjectBillRates = new List<Project_Team_Member_Billing_Rate__c>();                                           
        existingProjectBillRates = [SELECT Id, Name, Hourly_Rate__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Is_Placeholder_Rate__c, Product__c, Created_in_Salesforce__c
                                    FROM Project_Team_Member_Billing_Rate__c
                                    WHERE Project__c =: projectId AND Created_in_Salesforce__c = true AND Is_Placeholder_Rate__c = false
                                    ORDER BY CreatedDate];

        Map<String, Project_Team_Member_Billing_Rate__c> uniqueIdToBillRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
        Map<Id, Project_Team_Member_Billing_Rate__c> productIdToBillRateMap = new Map<Id, Project_Team_member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c existingRate : existingProjectBillRates){
            String uniqueId = String.valueOf(existingRate.Product__c) + ' | ' + String.valueOf(existingRate.Hourly_Rate__c);
            uniqueIdToBillRateMap.put(uniqueId, existingRate);

            productIdToBillRateMap.put(existingRate.Product__c, existingRate);
        }

        if(teamMemberList.size() > 0){

            if(teamMemberList.size() > 1){
                //The Contact that is trying to replace the Placeholder with, is already existant as a Project Team Member on the project.
                String message = 'Project Team Member with the Contact you are trying to replace the Placeholder with already exists on this project.';
                AuraHandledException auraError = new AuraHandledException(message);
                auraError.setMessage('Project Team Member with the Contact you are trying to replace the Placeholder with already exists on this project.');
                throw auraError;
            }else{
                Client_Contact__c placeholderTeamMember = teamMemberList[0];
                placeholderTeamMember.Is_Placeholder_Team_Member__c = false;
                placeholderTeamMember.Client_Contact__c = contactId;
                placeholderTeamMember.Internal_Project_Team_Member_Name__c = replacementContact.Name + ' - ' + projectName;

                if(teamMemberList[0].Assigned_Billing_Rate__r.Is_Placeholder_Rate__c == true && replacementBillRateId == null){
                    //If trying to convert a Placeholder with a real user they must be assigned a real rate to avoid workarounds of creating Billing Rates that are not Oppty Products
                    //Try to find a matching Bill Rate that can replace the bill rate of the placeholder for the swap
                    String uniqueId = String.valueOf(teamMemberList[0].Assigned_Billing_Rate__r.Product__c) + ' | ' + String.valueOf(teamMemberList[0].Assigned_Billing_Rate__r.Hourly_Rate__c);
                    if(uniqueIdToBillRateMap.containsKey(uniqueId)){
                        placeholderTeamMember.Assigned_Billing_Rate__c = uniqueIdToBillRateMap.get(uniqueId).Id;

                    }else if(productIdToBillRateMap.containsKey(teamMemberList[0].Assigned_Billing_Rate__r.Product__c)){
                        placeholderTeamMember.Assigned_Billing_Rate__c = productIdToBillRateMap.get(teamMemberList[0].Assigned_Billing_Rate__r.Product__c).Id;
                    }else{
                        String message = 'Placeholder Bill Rate cannot be replaced';
                        AuraHandledException auraError = new AuraHandledException(message);
                        auraError.setMessage('Placeholder Bill Rate cannot be replaced');
                        throw auraError;
                    }
                }else if(replacementBillRateId != null){
                    placeholderTeamMember.Assigned_Billing_Rate__c = (Id)replacementBillRateId;
                }

                System.debug('**************************** Swapping Placeholder with Contact record on ' + projectName + ' from Project Forecasting Table ****************************');
                update placeholderTeamMember;
            }
        }

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastList = [SELECT Id, Name, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Client_Contact__r.Cognizant_Employee_Id__c, Week_Start_Date__c, Week_End_Date__c 
                        FROM RepliconForecast__c 
                        WHERE Internal_Project_Team_Member__c =: placeholderTeamMemberId];

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){

            forecast.Contact__c = (Id)contactId;
            forecast.Cognizant_Employee_Id__c = replacementContact.Cognizant_Employee_Id__c;

            String timesheetStartString = DateTime.newInstance(forecast.Week_Start_Date__c.year(), forecast.Week_Start_Date__c.month(), forecast.Week_Start_Date__c.day()).format('MM/dd/YYYY');
            String timesheetEndString = DateTime.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), forecast.Week_End_Date__c.day()).format('MM/dd/YYYY');

            forecast.Name = timesheetStartString + '-' + timesheetEndString + '-' + forecast.Internal_Project_Team_Member__r.Client_Contact__r.Cognizant_Employee_Id__c + '-' + peoplesoftProjectId; 
            forecastUpdateList.add(forecast);
        }

        if(forecastUpdateList.size() > 0){
            System.debug('**************************** Changing the name on ' + forecastUpdateList.size() + ' Forecasts due to switching Placeholder Project Team Member ****************************');
            update forecastUpdateList;
        }

    }


    @AuraEnabled
    public static Decimal getCurrentAllocationForDateRange(Date fromDate, Date toDate, String projectId, String contactId, String projectTeamMemberId){

        Datetime startDatetime = Datetime.newInstance(fromDate.year(), fromDate.month(), fromDate.day());
        Datetime endDatetime = Datetime.newInstance(toDate.year(), toDate.month(), toDate.day());

        Date startDate = fromDate.toStartOfWeek();
        //if(endDatetime.format('EEEE') != 'Sunday')
        Date endDate = toDate.toStartOfWeek();

        /*AggregateResult[] allocationAggregate = [SELECT SUM(EstimatedHours__c) allocatedHours
                                                FROM RepliconForecast__c
                                                WHERE Project__c =: projectId AND Contact__c =: contactId AND EstimatedHours__c != 0 AND Week_Start_Date__c >= :startDate AND Week_Start_Date__c <= :endDate];*/

        AggregateResult[] allocationAggregate = [SELECT SUM(EstimatedHours__c) allocatedHours
                                                FROM RepliconForecast__c
                                                WHERE Project__c =: projectId AND Internal_Project_Team_Member__c =: projectTeamMemberId AND EstimatedHours__c != 0 AND Week_Start_Date__c >= :startDate AND Week_Start_Date__c <= :endDate];

        Decimal allocationHours = 0;
        if(allocationAggregate.size() > 0){
            allocationHours = (Decimal)allocationAggregate[0].get('allocatedHours') != null ? (Decimal)allocationAggregate[0].get('allocatedHours') : 0;
            //allocationHours = (Decimal)allocationAggregate[0].get('allocatedHours');
        }

        return allocationHours;
    }

}