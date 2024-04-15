public with sharing class ProjectForecastingTableController {

    public static List<String> projectActiveStatusList = new List<String>{'Not Started', 'In Progress', 'On Hold', 'Active'};

    public static ForecastTableDataWrapper getForecastTableData(String projectId){
        ForecastTableDataWrapper forecastTableData = getForecastTableData(projectId, null, null, 'Weekly');
        return forecastTableData;
    }

    @AuraEnabled(cacheable=true)
    public static ForecastTableDataWrapper getForecastTableData(String projectId, Date startDate, Date endDate, String timePeriodView){

        Project__c proj = [SELECT Id, Name, Start_Date__c, Planned_Close_Date__c, Project_Status__c, Remaining_Forecasted_Rev__c, Remaining_Forecasted_Hrs__c, Remaining_Hours__c, Opportunity_Remaining_Amount__c,
                                Difference__c, Hours_Difference__c
                            FROM Project__c
                            WHERE id =: projectId
                            LIMIT 1];

        if(startDate == null){
            startDate = proj.Start_Date__c != null ? proj.Start_Date__c : Date.today().addMonths(-2);
        }
        if(endDate == null){
            endDate = proj.Planned_Close_Date__c != null ? proj.Planned_Close_Date__c : Date.today().addMonths(3);
        }
        

        System.debug('Start Date: ' + startDate);
        System.debug('End Date: ' + endDate);       
        
        ForecastTableDataWrapper dataTableWrapper = new ForecastTableDataWrapper();
        dataTableWrapper.levRemainingForecastedHours = proj.Remaining_Forecasted_Hrs__c;
        dataTableWrapper.levRemainingForecastedBudget = proj.Remaining_Forecasted_Rev__c;
        dataTableWrapper.levHoursRemaining = proj.Remaining_Hours__c;
        dataTableWrapper.levBudgetRemaining = proj.Opportunity_Remaining_Amount__c;
        dataTableWrapper.budgetAmountDiffernce = proj.Difference__c;
        dataTableWrapper.budgetHoursDifference = proj.Hours_Difference__c;
        dataTableWrapper.dynamicForecastedHoursTotal = 0;

        List<Date> weekStartDateList = new List<Date>();
        List<String> weekStartDateStringList = new List<String>();
        List<String> weekStartAndEndRangeStringList = new List<String>();

        Date monthlyViewStartDate;
        Date monthlyViewEndDate;

        if(timePeriodView == 'Weekly'){
            //Get All Week Start Dates
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
            
        }else if(timePeriodView == 'Monthly'){

            Date iterationDate = Date.newInstance(startDate.year(), startDate.month(), 1);
            monthlyViewStartDate = Date.newInstance(startDate.year(), startDate.month(), 1);
            while(iterationDate <= endDate){
                weekStartDateStringList.add(formatDateToString(iterationDate));
                weekStartDateList.add(iterationDate);

                //Build Forecast Start and End Date Range Strings for Column Headers
                Date weekStartDate = iterationDate;
                Integer daysInMonth = Date.daysInMonth(weekStartDate.year(), weekStartDate.month());
                Date weekEndDate = iterationDate.addDays(daysInMonth - 1);
                Datetime weekStartDatetime = Datetime.newInstance(weekStartDate.year(), weekStartDate.month(), weekStartDate.day());
                Datetime weekEndDatetime = Datetime.newInstance(weekEndDate.year(), weekEndDate.month(), weekEndDate.day());

                String dateRangeString = weekStartDatetime.format('MMM d, yyyy') + ' - ' + weekEndDatetime.format('MMM d, yyyy');
                weekStartAndEndRangeStringList.add(dateRangeString);


                iterationDate = iterationDate.addMonths(1);
            }

            monthlyViewEndDate = iterationDate.addMonths(-1);

            dataTableWrapper.projectWeekStartDateList = weekStartDateList;
            dataTableWrapper.projectWeekStartStringList = weekStartDateStringList;
            dataTableWrapper.projectWeekStartAndEndRangeStringList = weekStartAndEndRangeStringList;
        }

        List<Client_Contact__c> placeholderTeamMembersList = new List<Client_Contact__c>();
        placeholderTeamMembersList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, Client_Contact__r.RecordType.Name,
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE Project__c =: projectId AND (Is_Placeholder_Team_Member__c = true OR Client_Contact__r.Name = 'Place Holder')
                                            ORDER BY Client_Contact__r.LastName ASC];

        List<Client_Contact__c> internalProjectTeamMembersList = new List<Client_Contact__c>();
        internalProjectTeamMembersList = [SELECT Id, Name, Client_Contact__c, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__r.Cognizant_Employee_Id__c, Client_Contact__r.RecordType.Name,
                                                Project__c, Project__r.Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Client_Contact__r.AccountId, Client_Contact__r.Account.Name, Is_Placeholder_Team_Member__c
                                            FROM Client_Contact__c
                                            WHERE Project__c =: projectId AND Is_Placeholder_Team_Member__c = false AND Client_Contact__r.Name != 'Place Holder'
                                            ORDER BY Client_Contact__r.LastName ASC];

        List<Client_Contact__c> allTeamMembersList = new List<Client_Contact__c>();
        if(placeholderTeamMembersList.size() > 0){
            allTeamMembersList.addAll(placeholderTeamMembersList);
        }

        if(internalProjectTeamMembersList.size() > 0){
            allTeamMembersList.addAll(internalProjectTeamMembersList);
        }

        Set<Id> contactIdSet = new Set<Id>();
        List<ProjectAllocationDatatableWrapper> forecastTableWrapperList = new List<ProjectAllocationDatatableWrapper>();
        for(Client_Contact__c cc : allTeamMembersList){
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
            newTeamMemberWrapper.contactRecordTypeName = cc.Client_Contact__r.RecordType.Name;

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
                newAllocationDataRollup.allocationDataUniqueIdParentDiv = 'ParentDiv' + ' | ' + String.valueOf(cc.Id) +  ' | ' + String.valueOf(weekStart);
                allocationRollupsList.add(newAllocationDataRollup);
            }

            newTeamMemberWrapper.allocationWeeklyRollups = allocationRollupsList;

            forecastTableWrapperList.add(newTeamMemberWrapper);
        }

        Map<String, Decimal> employeeAndWeekStartDateIdToProjectAllocationMap = new Map<String, Decimal>();
        Map<String, Decimal> teamMemberAndWeekStartDateIdToProjectAllocationMap = new Map<String, Decimal>();

        if(timePeriodView == 'Weekly'){
            AggregateResult[] projectAllocationAggregate = [SELECT SUM(EstimatedHours__c) estimatedHoursSum, Contact__c, Contact__r.Name contactName, Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c, 
                                                                ProjectTeamMemberBillingRate__r.Name billingRateName, Week_Start_Date__c
                                                            FROM RepliconForecast__c
                                                            WHERE Deleted_in_Replicon__c = false AND Project__c =:projectId AND Contact__c IN :contactIdSet AND Week_Start_Date__c IN :weekStartDateList AND EstimatedHours__c != 0
                                                            GROUP BY Contact__c, Contact__r.Name, Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Week_Start_Date__c
                                                            ORDER BY Contact__c, Week_Start_Date__c ASC];

            
            for(AggregateResult ar : projectAllocationAggregate){
                Decimal projectAllocatedHours = (Decimal)ar.get('estimatedHoursSum');
                Id contactId = (Id)ar.get('Contact__c');
                String contactName = (String)ar.get('contactName');
                Id billingRateId = (Id)ar.get('ProjectTeamMemberBillingRate__c');
                String billingRateName = (String)ar.get('billingRateName');
                Date weekStartDate = (Date)ar.get('Week_Start_Date__c');
                Id internalProjTeamMemberId = (Id)ar.get('Internal_Project_Team_Member__c');

                //Added 10/24/2023
                String uniqueTeamMemberAndDateId;
                uniqueTeamMemberAndDateId = String.valueOf(internalProjTeamMemberId) + ' | ' + String.valueOf(weekStartDate);
                if(!teamMemberAndWeekStartDateIdToProjectAllocationMap.containsKey(uniqueTeamMemberAndDateId)){
                    //If not yet in the Map then set
                    teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, projectAllocatedHours);
                }else{
                    //If already in the map then add to the hours
                    Decimal existingProjectAllocationHours = teamMemberAndWeekStartDateIdToProjectAllocationMap.get(uniqueTeamMemberAndDateId);
                    existingProjectAllocationHours += projectAllocatedHours;
                    teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, existingProjectAllocationHours);
                }

                //Get Total Forecasted Amount Displayed
                dataTableWrapper.dynamicForecastedHoursTotal += projectAllocatedHours;
            }
        }else if(timePeriodView == 'Monthly'){

            List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
            forecastList = [SELECT EstimatedHours__c, Contact__c, Contact__r.Name, Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Week_Start_Date__c, Week_End_Date__c
                            FROM RepliconForecast__c
                            WHERE Deleted_in_Replicon__c = false AND Project__c =:projectId AND Contact__c IN :contactIdSet AND (Week_End_Date__c >= :monthlyViewStartDate OR Week_Start_Date__c >= :monthlyViewEndDate) AND EstimatedHours__c != 0
                            ORDER BY Contact__c, Week_Start_Date__c ASC];

            for(RepliconForecast__c forecast : forecastList){

                String uniqueTeamMemberAndDateId;
                //Need to split up forecasted hours into daily bits to get hours for different months if forecast spans a week that contains 2 months.
                if(forecast.Week_Start_Date__c.month() == forecast.Week_End_Date__c.month() && forecast.Week_Start_Date__c.year() == forecast.Week_End_Date__c.year()){
                    uniqueTeamMemberAndDateId = String.valueOf(forecast.Internal_Project_Team_Member__c) + ' | ' + String.valueOf(Date.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), 1)); //Forecast spans only 1 month

                    if(!teamMemberAndWeekStartDateIdToProjectAllocationMap.containsKey(uniqueTeamMemberAndDateId)){
                        //If not yet in the Map then set
                        teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, forecast.EstimatedHours__c);
                    }else{
                        //If already in the map then add to the hours
                        Decimal existingProjectAllocationHours = teamMemberAndWeekStartDateIdToProjectAllocationMap.get(uniqueTeamMemberAndDateId);
                        existingProjectAllocationHours += forecast.EstimatedHours__c;
                        teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, existingProjectAllocationHours);
                    }
                }else{
                    //Break into daily amount and split into multiple months
                    Decimal dailyForecastedAmount = (forecast.EstimatedHours__c / 5).setscale(2);
                    Datetime iterationDatetime = Datetime.newInstance(forecast.Week_Start_Date__c.year(), forecast.Week_Start_Date__c.month(), forecast.Week_Start_Date__c.day());
                    Datetime weekEndDatetime = Datetime.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), forecast.Week_End_Date__c.day());
                    System.debug('Iteration Date BEFORE LOOP: ' + iterationDatetime);
                    System.debug('Week End Datetime: ' + weekEndDatetime);
                    Integer whileLoopCount = 0;
                    while(iterationDatetime <= weekEndDatetime){
                        whileLoopCount++;
                        System.debug('Iteration Date INSIDE LOOP: ' + iterationDatetime);
                        if(iterationDatetime.format('EEEE') != 'Saturday' && iterationDatetime.format('EEEE') != 'Sunday'){
                            uniqueTeamMemberAndDateId = String.valueOf(forecast.Internal_Project_Team_Member__c) + ' | ' + String.valueOf(Date.newInstance(iterationDatetime.year(), iterationDatetime.month(), 1));

                            if(!teamMemberAndWeekStartDateIdToProjectAllocationMap.containsKey(uniqueTeamMemberAndDateId)){
                                //If not yet in the Map then set
                                teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, dailyForecastedAmount);
                            }else{
                                //If already in the map then add to the hours
                                Decimal existingProjectAllocationHours = teamMemberAndWeekStartDateIdToProjectAllocationMap.get(uniqueTeamMemberAndDateId);
                                existingProjectAllocationHours += dailyForecastedAmount;
                                teamMemberAndWeekStartDateIdToProjectAllocationMap.put(uniqueTeamMemberAndDateId, existingProjectAllocationHours);
                            }
                        }

                        iterationDatetime = iterationDatetime.addDays(1);

                        if(whileLoopCount > 8){
                            break;
                        }
                    }
                }
            
                //Get Total Forecasted Amount Displayed
                dataTableWrapper.dynamicForecastedHoursTotal += forecast.EstimatedHours__c;
            }
        }

        /**************************** Get Forecasts for OTHER Projects ***************************************************************************************************************/
        Map<String, Decimal> employeeAndWeekStartDateIdToOtherAllocationMap = new Map<String, Decimal>();
        Map<String, List<OtherAllocationBreakdown>> employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap = new Map<String, List<OtherAllocationBreakdown>>();
        Map<String, Map<String, OtherAllocationBreakdown>> employeeAndWeekStartDateIdToOtherAllocationBreakdownMap = new Map<String, Map<String, OtherAllocationBreakdown>>();
        if(timePeriodView == 'Weekly'){
            /*AggregateResult[] otherAllocationHoursAggregate = [SELECT SUM(EstimatedHours__c) estimatedHoursSum, Internal_Project_Team_Member__c, Contact__c, Contact__r.Name contactName, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name billingRateName, Week_Start_Date__c
                                                                FROM RepliconForecast__c
                                                                WHERE Deleted_in_Replicon__c = false AND Project__c !=:projectId AND Contact__c IN :contactIdSet 
                                                                    AND Week_Start_Date__c IN :weekStartDateList  AND Project__r.Name != 'Lev - PTO' AND (NOT(Contact__r.Name IN ('Place Holder', 'ATG Consultant', 'Global Employee'))) AND EstimatedHours__c != 0
                                                                GROUP BY Internal_Project_Team_Member__c, Contact__c, Contact__r.Name, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Week_Start_Date__c
                                                                ORDER BY Contact__c, Week_Start_Date__c ASC];

            for(AggregateResult ar : otherAllocationHoursAggregate){
                Decimal otherAllocatedHours = (Decimal)ar.get('estimatedHoursSum');
                Id contactId = (Id)ar.get('Contact__c');
                String contactName = (String)ar.get('contactName');
                Id billingRateId = (Id)ar.get('ProjectTeamMemberBillingRate__c');
                String billingRateName = (String)ar.get('billingRateName');
                Date weekStartDate = (Date)ar.get('Week_Start_Date__c');
                Id internalProjTeamMemberId = (Id)ar.get('Internal_Project_Team_Member__c');

                String uniqueEmployeeAndDateId;
                uniqueEmployeeAndDateId = String.valueOf(contactId) + ' | ' + String.valueOf(weekStartDate);

                if(!employeeAndWeekStartDateIdToOtherAllocationMap.containsKey(uniqueEmployeeAndDateId)){
                    //If not yet in the Map then set
                    employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, otherAllocatedHours);
                }else{
                    //If already in the map then add to the hours
                    Decimal existingOtherAllocationHours = employeeAndWeekStartDateIdToOtherAllocationMap.get(uniqueEmployeeAndDateId);
                    existingOtherAllocationHours += otherAllocatedHours;
                    employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, existingOtherAllocationHours);
                }
            }*/

            AggregateResult[] otherAllocationHoursAggregate = [SELECT SUM(EstimatedHours__c) estimatedHoursSum, Internal_Project_Team_Member__c, Contact__c, Contact__r.Name contactName, Week_Start_Date__c,
                                                                Project__c, Project__r.Name projName
                                                                FROM RepliconForecast__c
                                                                WHERE Deleted_in_Replicon__c = false AND Project__c !=:projectId AND Contact__c IN :contactIdSet 
                                                                    AND Week_Start_Date__c IN :weekStartDateList  AND Project__r.Name != 'Lev - PTO' AND (NOT(Contact__r.Name IN ('Place Holder', 'ATG Consultant', 'Global Employee'))) AND EstimatedHours__c != 0
                                                                GROUP BY Internal_Project_Team_Member__c, Contact__c, Contact__r.Name, Week_Start_Date__c, Project__c, Project__r.Name
                                                                ORDER BY Contact__c, Project__c, Week_Start_Date__c ASC];

            for(AggregateResult ar : otherAllocationHoursAggregate){
                Decimal otherAllocatedHours = (Decimal)ar.get('estimatedHoursSum');
                Id contactId = (Id)ar.get('Contact__c');
                String contactName = (String)ar.get('contactName');
                //Id billingRateId = (Id)ar.get('ProjectTeamMemberBillingRate__c');
                //String billingRateName = (String)ar.get('billingRateName');
                Date weekStartDate = (Date)ar.get('Week_Start_Date__c');
                Id internalProjTeamMemberId = (Id)ar.get('Internal_Project_Team_Member__c');
                String projectName = (String)ar.get('projName');

                String uniqueEmployeeAndDateId;
                uniqueEmployeeAndDateId = String.valueOf(contactId) + ' | ' + String.valueOf(weekStartDate);

                if(!employeeAndWeekStartDateIdToOtherAllocationMap.containsKey(uniqueEmployeeAndDateId)){
                    //If not yet in the Map then set
                    employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, otherAllocatedHours);
                }else{
                    //If already in the map then add to the hours
                    Decimal existingOtherAllocationHours = employeeAndWeekStartDateIdToOtherAllocationMap.get(uniqueEmployeeAndDateId);
                    existingOtherAllocationHours += otherAllocatedHours;
                    employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, existingOtherAllocationHours);
                }

                //Create Map of Employee Id and Week Start Date to 
                if(!employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.containsKey(uniqueEmployeeAndDateId)){
                    //If not yet in the Map then set
                    OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                    newOtherAllocationBreakdown.projectName = projectName;
                    newOtherAllocationBreakdown.projectForecastedHours = otherAllocatedHours;
                    List<OtherAllocationBreakdown> otherAllocationBreakdownList = new List<OtherAllocationBreakdown>();
                    otherAllocationBreakdownList.add(newOtherAllocationBreakdown);
                    employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.put(uniqueEmployeeAndDateId, otherAllocationBreakdownList);
                }else{
                    OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                    newOtherAllocationBreakdown.projectName = projectName;
                    newOtherAllocationBreakdown.projectForecastedHours = otherAllocatedHours;
                    List<OtherAllocationBreakdown> otherAllocationBreakdownList = employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.get(uniqueEmployeeAndDateId);
                    otherAllocationBreakdownList.add(newOtherAllocationBreakdown);
                    employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.put(uniqueEmployeeAndDateId, otherAllocationBreakdownList);
                }
            }

        }else if(timePeriodView == 'Monthly'){

            List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
            forecastList = [SELECT EstimatedHours__c, Contact__c, Contact__r.Name, Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Week_Start_Date__c, Week_End_Date__c, Project__c, Project__r.Name
                            FROM RepliconForecast__c
                            WHERE Deleted_in_Replicon__c = false AND Project__c != :projectId AND Contact__c IN :contactIdSet AND (Week_End_Date__c >= :monthlyViewStartDate OR Week_Start_Date__c >= :monthlyViewEndDate) AND EstimatedHours__c != 0
                                AND Project__r.Name != 'Lev - PTO' AND (NOT(Contact__r.Name IN ('Place Holder', 'ATG Consultant', 'Global Employee')))
                            ORDER BY Contact__c, Week_Start_Date__c ASC];

            for(RepliconForecast__c forecast : forecastList){

                String uniqueEmployeeAndDateId;
                //Need to split up forecasted hours into daily bits to get hours for different months if forecast spans a week that contains 2 months.
                if(forecast.Week_Start_Date__c.month() == forecast.Week_End_Date__c.month() && forecast.Week_Start_Date__c.year() == forecast.Week_End_Date__c.year()){
                    uniqueEmployeeAndDateId = String.valueOf(forecast.Contact__c) + ' | ' + String.valueOf(Date.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), 1)); //Forecast spans only 1 month

                    if(!employeeAndWeekStartDateIdToOtherAllocationMap.containsKey(uniqueEmployeeAndDateId)){
                        //If not yet in the Map then set
                        employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, forecast.EstimatedHours__c);
                    }else{
                        //If already in the map then add to the hours
                        Decimal existingProjectAllocationHours = employeeAndWeekStartDateIdToOtherAllocationMap.get(uniqueEmployeeAndDateId);
                        existingProjectAllocationHours += forecast.EstimatedHours__c;
                        employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, existingProjectAllocationHours);
                    }

                    //Create Map of Other Allocation Breakdown
                    if(!employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.containsKey(uniqueEmployeeAndDateId)){
                        //If not yet in the Map then set

                        //Create Inner Map of Project Name --> OtherAllocationBreakdown
                        Map<String, OtherAllocationBreakdown> projectToAllocationBreakdownMap = new Map<String, OtherAllocationBreakdown>();
                        OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                        newOtherAllocationBreakdown.projectName = forecast.Project__r.Name;
                        newOtherAllocationBreakdown.projectForecastedHours = forecast.EstimatedHours__c;
                        projectToAllocationBreakdownMap.put(forecast.Project__r.Name, newOtherAllocationBreakdown);

                        employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.put(uniqueEmployeeAndDateId, projectToAllocationBreakdownMap);

                    }else{
                        //If Employee is already in Other Allocation breakdown map
                        Map<String, OtherAllocationBreakdown> projectToAllocationBreakdownMap = employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.get(uniqueEmployeeAndDateId);

                        //Check if project is already in inner Map
                        if(!projectToAllocationBreakdownMap.containsKey(forecast.Project__r.Name)){//Check if Project is already in Map
                            OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                            newOtherAllocationBreakdown.projectName = forecast.Project__r.Name;
                            newOtherAllocationBreakdown.projectForecastedHours = forecast.EstimatedHours__c;
                            projectToAllocationBreakdownMap.put(forecast.Project__r.Name, newOtherAllocationBreakdown);
                        }else{
                            OtherAllocationBreakdown otherAllocationBreakdownToUpdate = projectToAllocationBreakdownMap.get(forecast.Project__r.Name);
                            otherAllocationBreakdownToUpdate.projectForecastedHours += forecast.EstimatedHours__c;
                            projectToAllocationBreakdownMap.put(forecast.Project__r.Name, otherAllocationBreakdownToUpdate);
                        }

                        employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.put(uniqueEmployeeAndDateId, projectToAllocationBreakdownMap);
                    }

                }else{
                    //Break into daily amount and split into multiple months
                    Decimal dailyForecastedAmount = (forecast.EstimatedHours__c / 5).setscale(2);
                    Datetime iterationDatetime = Datetime.newInstance(forecast.Week_Start_Date__c.year(), forecast.Week_Start_Date__c.month(), forecast.Week_Start_Date__c.day());
                    Datetime weekEndDatetime = Datetime.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), forecast.Week_End_Date__c.day());

                    Integer whileLoopCount = 0;
                    while(iterationDatetime <= weekEndDatetime){
                        whileLoopCount++;
                        if(iterationDatetime.format('EEEE') != 'Saturday' && iterationDatetime.format('EEEE') != 'Sunday'){
                            uniqueEmployeeAndDateId = String.valueOf(forecast.Contact__c) + ' | ' + String.valueOf(Date.newInstance(iterationDatetime.year(), iterationDatetime.month(), 1));

                            if(!employeeAndWeekStartDateIdToOtherAllocationMap.containsKey(uniqueEmployeeAndDateId)){
                                //If not yet in the Map then set
                                employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, dailyForecastedAmount);
                            }else{
                                //If already in the map then add to the hours
                                Decimal existingProjectAllocationHours = employeeAndWeekStartDateIdToOtherAllocationMap.get(uniqueEmployeeAndDateId);
                                existingProjectAllocationHours += dailyForecastedAmount;
                                employeeAndWeekStartDateIdToOtherAllocationMap.put(uniqueEmployeeAndDateId, existingProjectAllocationHours);
                            }

                            //Create Map of Other Allocation Breakdown
                            if(!employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.containsKey(uniqueEmployeeAndDateId)){
                                //If not yet in the Map then set

                                //Create Inner Map of Project Name --> OtherAllocationBreakdown
                                Map<String, OtherAllocationBreakdown> projectToAllocationBreakdownMap = new Map<String, OtherAllocationBreakdown>();
                                OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                                newOtherAllocationBreakdown.projectName = forecast.Project__r.Name;
                                newOtherAllocationBreakdown.projectForecastedHours = dailyForecastedAmount;
                                projectToAllocationBreakdownMap.put(forecast.Project__r.Name, newOtherAllocationBreakdown);

                                employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.put(uniqueEmployeeAndDateId, projectToAllocationBreakdownMap);

                            }else{
                                //If Employee is already in Other Allocation breakdown map
                                Map<String, OtherAllocationBreakdown> projectToAllocationBreakdownMap = employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.get(uniqueEmployeeAndDateId);

                                //Check if project is already in inner Map
                                if(!projectToAllocationBreakdownMap.containsKey(forecast.Project__r.Name)){//Check if Project is already in Map
                                    OtherAllocationBreakdown newOtherAllocationBreakdown = new OtherAllocationBreakdown();
                                    newOtherAllocationBreakdown.projectName = forecast.Project__r.Name;
                                    newOtherAllocationBreakdown.projectForecastedHours = dailyForecastedAmount;
                                    projectToAllocationBreakdownMap.put(forecast.Project__r.Name, newOtherAllocationBreakdown);
                                }else{
                                    OtherAllocationBreakdown otherAllocationBreakdownToUpdate = projectToAllocationBreakdownMap.get(forecast.Project__r.Name);
                                    otherAllocationBreakdownToUpdate.projectForecastedHours += dailyForecastedAmount;
                                    projectToAllocationBreakdownMap.put(forecast.Project__r.Name, otherAllocationBreakdownToUpdate);
                                }

                                employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.put(uniqueEmployeeAndDateId, projectToAllocationBreakdownMap);
                            }
                        }

                        iterationDatetime = iterationDatetime.addDays(1);

                        if(whileLoopCount > 7){
                            break;
                        }
                    }
                }
            }
        }

        /************************** Get Team Members PTO **************************************************************************************************************************************/
        Map<String, Decimal> employeeAndWeekStartDateIdToTimeOffMap = new Map<String, Decimal>();
        if(timePeriodView == 'Weekly'){
            AggregateResult[] timeOffAggregate = [SELECT SUM(TotalHrs__c) timeOffSum, Employee__c, Timesheet_Period__c
                                                    FROM Replicon_Time_Entry__c
                                                    WHERE Deleted_in_Replicon__c = false AND Time_Off__c = true AND Employee__c IN :contactIdSet AND Project__c !=:projectId AND Timesheet_Period__c IN :weekStartDateList
                                                    GROUP BY Employee__c, Internal_Project_Team_Member__c, Timesheet_Period__c
                                                    ORDER BY Employee__c, Timesheet_Period__c ASC];

            for(AggregateResult ar : timeOffAggregate){
                Decimal timeOffHours = (Decimal)ar.get('timeOffSum');
                Id contactId = (Id)ar.get('Employee__c');
                Date weekStartDate = (Date)ar.get('Timesheet_Period__c');

                String uniqueEmployeeAndDateId = String.valueOf(contactId) + ' | ' + String.valueOf(weekStartDate);

                if(!employeeAndWeekStartDateIdToTimeOffMap.containsKey(uniqueEmployeeAndDateId)){
                    //If not yet in the Map then set
                    employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, timeOffHours);
                }else{
                    //If already in the map then add to the hours
                    Decimal existingTimeOffHours = employeeAndWeekStartDateIdToTimeOffMap.get(uniqueEmployeeAndDateId);
                    existingTimeOffHours += timeOffHours;
                    employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, existingTimeOffHours);
                }
            }
        }else if(timePeriodView == 'Monthly'){

            //List<Replicon_Time_Entry__c> timeOffEntryList = new List<Replicon_Time_Entry__c>();
            AggregateResult[] timeOffAggregate = [SELECT CALENDAR_MONTH(EntryDate__c) calendarMonth, CALENDAR_YEAR(EntryDate__c) calendarYear, SUM(TotalHrs__c) timeOffSum, Employee__c
                                                    FROM Replicon_Time_Entry__c
                                                    WHERE Deleted_in_Replicon__c = false AND Time_Off__c = true AND Employee__c IN :contactIdSet AND Project__c !=:projectId AND EntryDate__c >= :monthlyViewStartDate AND EntryDate__c <= :monthlyViewEndDate
                                                    GROUP BY CALENDAR_MONTH(EntryDate__c), CALENDAR_YEAR(EntryDate__c), Employee__c
                                                    ORDER BY CALENDAR_YEAR(EntryDate__c), CALENDAR_MONTH(EntryDate__c)];

            for(AggregateResult ar : timeOffAggregate){
                
                Decimal timeOffHours = (Decimal)ar.get('timeOffSum');
                Id contactId = (Id)ar.get('Employee__c');
                Integer monthNumber = (Integer)ar.get('calendarMonth');
                Integer yearNumber = (Integer)ar.get('calendarYear');

                Date monthStartDateForTimeOffAgg = Date.newInstance(yearNumber, monthNumber, 1);

                String uniqueEmployeeAndDateId = String.valueOf(contactId) + ' | ' + String.valueOf(monthStartDateForTimeOffAgg);

                if(!employeeAndWeekStartDateIdToTimeOffMap.containsKey(uniqueEmployeeAndDateId)){
                    //If not yet in the Map then set
                    employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, timeOffHours);
                }else{
                    //If already in the map then add to the hours
                    Decimal existingTimeOffHours = employeeAndWeekStartDateIdToTimeOffMap.get(uniqueEmployeeAndDateId);
                    existingTimeOffHours += timeOffHours;
                    employeeAndWeekStartDateIdToTimeOffMap.put(uniqueEmployeeAndDateId, existingTimeOffHours);
                }
            }
        }

        for(ProjectAllocationDatatableWrapper wrapper : forecastTableWrapperList){
            wrapper.projectTeamMemberHasProjectAllocation = false;

            for(AllocationDataRollups dataRollup : wrapper.allocationWeeklyRollups){

                Decimal totalAllocation = 0;

                /*********************************** Set Project Allocation Data ***********************************/
                /*if(employeeAndWeekStartDateIdToProjectAllocationMap.containsKey(dataRollup.uniqueEmployeeAndWeekStartId)){
                    Decimal projectAllocationHours = employeeAndWeekStartDateIdToProjectAllocationMap.get(dataRollup.uniqueEmployeeAndWeekStartId);
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
                        wrapper.projectTeamMemberHasProjectAllocation = true; //Set on the project team member level that they have Forecasts for any week for the project.
                    }
                }*/

                /*********************************** Set Project Allocation Data with Internal Project Team Member Id ***********************************/
                if(teamMemberAndWeekStartDateIdToProjectAllocationMap.containsKey(dataRollup.uniqueTeamMemberAndWeekStartId)){
                    Decimal projectAllocationHours = teamMemberAndWeekStartDateIdToProjectAllocationMap.get(dataRollup.uniqueTeamMemberAndWeekStartId);
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
                        //dataRollup.projectAllocationClassName = '';
                        wrapper.projectTeamMemberHasProjectAllocation = true; //Set on the project team member level that they have Forecasts for any week for the project.
                    }else{
                        //dataRollup.projectAllocationClassName = 'invisibleStyle';
                    }
                }

                /*********************************** Set Other Project Allocation Data ***********************************/
                if(employeeAndWeekStartDateIdToOtherAllocationMap.containsKey(dataRollup.uniqueEmployeeAndWeekStartId)){
                    Decimal otherProjectAllocationsHours = employeeAndWeekStartDateIdToOtherAllocationMap.get(dataRollup.uniqueEmployeeAndWeekStartId);
                    dataRollup.otherAllocationData = otherProjectAllocationsHours;
                    totalAllocation += otherProjectAllocationsHours;

                    if(otherProjectAllocationsHours != 0 && otherProjectAllocationsHours != null){
                        dataRollup.hasOtherAllocations = true;
                    }
                }

                /************************************ Set Other Project Allocation Breakdown ****************************/
                if(timePeriodView == 'Weekly'){
                    if(employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.containsKey(dataRollup.uniqueEmployeeAndWeekStartId)){
                        dataRollup.otherAllocationBreakdownList = employeeAndWeekStartDateIdToOtherAllocationBreakdownListMap.get(dataRollup.uniqueEmployeeAndWeekStartId);
                    }
                }else if(timePeriodView == 'Monthly'){
                    if(employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.containsKey(dataRollup.uniqueEmployeeAndWeekStartId)){
                        dataRollup.otherAllocationBreakdownList = employeeAndWeekStartDateIdToOtherAllocationBreakdownMap.get(dataRollup.uniqueEmployeeAndWeekStartId).values();
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
                if(timePeriodView == 'Weekly'){
                    if(totalAllocation > 40){
                        dataRollup.isOverAllocated = true;
                        dataRollup.tableCellStyle = 'bottom:0px;border:2px solid red';
                    }else{
                        dataRollup.tableCellStyle = '';
                    }
                }else if(timePeriodView == 'Monthly'){
                    if(totalAllocation > 160){
                        dataRollup.isOverAllocated = true;
                        dataRollup.tableCellStyle = 'bottom:0px;border:2px solid red';
                    }else{
                        dataRollup.tableCellStyle = '';
                    }
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
        public Decimal levRemainingForecastedHours {get;set;}
        @AuraEnabled
        public Decimal levRemainingForecastedBudget{get;set;}
        @AuraEnabled
        public Decimal levHoursRemaining {get;set;}
        @AuraEnabled
        public Decimal levBudgetRemaining {get;set;}
        @AuraEnabled
        public Decimal budgetAmountDiffernce {get;set;}
        @AuraEnabled
        public Decimal budgetHoursDifference {get;set;}
        @AuraEnabled
        public Decimal dynamicForecastedHoursTotal {get;set;}


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
        public String contactRecordTypeName {get;set;}
    }

    public class AllocationDataRollups{
        @AuraEnabled
        public String uniqueEmployeeAndWeekStartId {get;set;}
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
        public String allocationDataUniqueIdParentDiv {get;set;}
        @AuraEnabled
        public List<OtherAllocationBreakdown> otherAllocationBreakdownList {get;set;}
    }

    public class OtherAllocationBreakdown{
        @AuraEnabled
        public String projectName {get;set;}
        @AuraEnabled
        public Decimal projectForecastedHours {get;set;}
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