/**
 * Created 3/1/2022
 * ST
 * 
 */
public with sharing class RepliconForecastTriggerHelper {
    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    private static List<String> cdpProductsList = new List<String>{'Marketing Consultant', 'Project Manager', 'Solution Architect'};
    private static List<String> coreProductsList = new List<String>{'Project Manager', 'Solution Architect', 'Techinical Architect', 'Technical QA Consultant'};
    private static List<String> dmpProductsList = new List<String>{'Paid Media & Analytics', 'Project Manager', 'Solution Architect'};
    private static List<String> dtrProductsList = new List<String>{'Marketing Consultant', 'Project Manager', 'Solution Architect'};
    private static List<String> interactionStudioProductsList = new List<String>{'Project Manager', 'Solution Architect', 'Creative Services', 'Technical QA Consultant', 'Developer', 'Marketing Consultant', 'Paid Media & Analytics', 'UX Developer'};
    private static List<String> mcProductsList = new List<String>{'Campaign Email QA Consultant', 'Campaign Manager', 'Campaign Technical QA Consultant', 'Creative Services', 'Email QA Consultant', 'Marketing Consultant', 'Paid Media & Analytics', 'Platform Architect',
                                                                    'Solution Architect', 'Technical Producer', 'Technical QA Consultant', 'Campaign Solution Architect', 'Campaign Technical Producer'};
    private static List<String> pardotProductsList = new List<String>{'Marketing Consultant', 'Solution Architect', 'Technical Producer'};
    private static List<String> projectRolePrefixList = new List<String>{'CDP', 'CORE', 'DMP', 'DTR', 'Interaction Studio', 'MC', 'Pardot'};

    //private static String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeWeekEndDate = Date.newInstance(2022, 6, 4);

    public static Map<Id, Contact> contactIdToRecordPublicMap = new Map<Id, Contact>();
    public static Map<Id, Project__c> projectIdToRecordPublicMap = new Map<Id, Project__c>();

    public static void rollupForecastRevenueOnRevenueForecasts(List<RepliconForecast__c> forecastsToRollup){
        System.debug('******************* RepliconForecastTriggerHelper *************'); 
        /**
         * Purpose: To rollup the existing Replicon Forecast Estimated Revenue to the Weekly target on Insert
         */
        List<Date> forecastsEndDateList = new List<Date>();
        for(RepliconForecast__c fore : forecastsToRollup){
            if(fore.Week_End_Date__c != null){
                forecastsEndDateList.add(fore.Week_End_Date__c); //Get the Weekend Date of Forecasts that need to be rolled up
            }            
        }

        //Aggregate the Estimated Revenue for all Replicon Forecast that are not deleted and fall on the same week as the incoming forecasts
        AggregateResult[] rolledUpForecastRevenue = [SELECT sum(EstimatedRevenue__c), Week_End_Date__c
                                                        FROM RepliconForecast__c
                                                        WHERE Deleted_in_Replicon__c = false AND EstimatedRevenue__c > 0 AND Week_End_Date__c IN :forecastsEndDateList AND Contact__r.Account.Name =: levementumAccountName
                                                        GROUP BY Week_End_Date__c];

        Map<Date, Decimal> forecastWeekEndDateToRevenueMap = new Map<Date, Decimal>();
        for(AggregateResult ar : rolledUpForecastRevenue){
            forecastWeekEndDateToRevenueMap.put((Date)ar.get('Week_End_Date__c'), (Decimal)ar.get('expr0'));
        }

        List<Revenue_Forecast__c> relatedRevForecastsList = new List<Revenue_Forecast__c>();
        relatedRevForecastsList = [SELECT Id, WeekStartDate__c, WeekEndDate__c, FullWeekStartDate__c, FullWeekEndDate__c, WeeklyForecast__c, BusinessDaysInForecastRange__c
                                    FROM Revenue_Forecast__c
                                    WHERE FullWeekEndDate__c IN: forecastWeekEndDateToRevenueMap.keySet() AND RecordTypeId =: weeklyTargetRT];

        List<Revenue_Forecast__c> weeklyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c weeklyTarget : relatedRevForecastsList){

            if(forecastWeekEndDateToRevenueMap.containsKey(weeklyTarget.FullWeekEndDate__c)){
                if(weeklyTarget.FullWeekEndDate__c.month() == weeklyTarget.FullWeekStartDate__c.month()){ //Forecast $ will all go to a singular weekly target
                    weeklyTarget.WeeklyForecast__c = forecastWeekEndDateToRevenueMap.get(weeklyTarget.FullWeekEndDate__c);
                    weeklyTargetsToUpdate.add(weeklyTarget);

                }else{ //Forecast $ needs to be split between 2 weekly targets because it is a week that spans 2 months
                    /**
                     * To split forecast amount across two weekly targets we need to get the amount of business days in that week and divide the forecast $ by that number to get the forecast per day amount
                     * Then multiple the daily forecast by the business days in the weekly target to get the forecast $
                     */                    
                    Integer daysInWeek;
                    Decimal forecastDailyAmount;
                    Decimal weekForecastAmount; 
                    daysInWeek = getBusinessDaysBetweenTwoDates(weeklyTarget.FullWeekStartDate__c, weeklyTarget.FullWeekEndDate__c, false);
                    if(daysInWeek > 0){
                        //To account for if there is 0 Working Days in the week avoiding dividing by 0
                        forecastDailyAmount = forecastWeekEndDateToRevenueMap.get(weeklyTarget.FullWeekEndDate__c) / daysInWeek;
                        weekForecastAmount = forecastDailyAmount * weeklyTarget.BusinessDaysInForecastRange__c;
                    }else{
                        weekForecastAmount = 0;
                    }
                    System.debug('******************* RepliconForecastTriggerHelper *************');
                    System.debug('Weekly Target: ' + weeklyTarget);
                    System.debug('daysInWeek: ' + daysInWeek);
                    System.debug('forecast daily amount: ' + forecastDailyAmount);
                    System.debug('week forecast Amount ' + weekForecastAmount);

                    weeklyTarget.WeeklyForecast__c = weekForecastAmount;
                    weeklyTargetsToUpdate.add(weeklyTarget);
                }
            }

        }

        if(weeklyTargetsToUpdate.size() > 0){
            update weeklyTargetsToUpdate;
        }
    }

    public static void rollupForecastsOnRelatedProjects(List<RepliconForecast__c> forecastList){
        //Rollup remaining Forecasted Hours and Revenue from Forecast records to the related Project

        Map<Id, Decimal> projectToRemainingLevForecastHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToTotalRemainingForecastHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToRemainingLevForecastRevenueMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToTotalRemainingForecastRevenueMap = new Map<Id, Decimal>();

        List<Id> relatedProjectIds = new List<Id>();
        for(RepliconForecast__c fore : forecastList){
            if(fore.Project__c != null){
                relatedProjectIds.add(fore.Project__c);
                projectToRemainingLevForecastHoursMap.put(fore.Project__c, 0);
                projectToTotalRemainingForecastHoursMap.put(fore.Project__c, 0);
                projectToRemainingLevForecastRevenueMap.put(fore.Project__c, 0);
                projectToTotalRemainingForecastRevenueMap.put(fore.Project__c, 0);
            }
        }

        AggregateResult[] forecastSum = [SELECT sum(EstimatedHours__c) estHours, sum(EstimatedRevenue__c) estRev, Project__c, Contact__r.AccountId conAcctId, Contact__r.Account.Name conAcctName
                                            FROM RepliconForecast__c
                                            WHERE Week_Start_Date__c >= THIS_WEEK AND Deleted_in_Replicon__C = false AND Project__c IN :relatedProjectIds AND Contact__c != null AND Contact__r.AccountId != null
                                            GROUP BY Project__c, Contact__r.AccountId, Contact__r.Account.Name
                                            ORDER BY Project__c, Contact__r.AccountId];

        for(AggregateResult ar : forecastSum){
            //Loop through Forecast Sums and add them to Maps in order to update the Projects
            Id projectId;
            Decimal remainingForecastHours;
            Decimal remainingForecaseRevenue;
            Id contactAccountId;
            String contactAccountName;

            projectId = (Id)ar.get('Project__c');
            remainingForecastHours = (Decimal)ar.get('estHours');
            remainingForecaseRevenue = (Decimal)ar.get('estRev');
            contactAccountId = (Id)ar.get('conAcctId');
            contactAccountName = (String)ar.get('conAcctName');

            //Set the Levementum Totals
            if(contactAccountName == levementumAccountName){
                //Remaining Lev Forecasted Hours
                Decimal existingRemainingLevForecastedHours = projectToRemainingLevForecastHoursMap.get(projectId);
                existingRemainingLevForecastedHours +=  remainingForecastHours;
                projectToRemainingLevForecastHoursMap.put(projectId, existingRemainingLevForecastedHours);

                //Remaining Lev Forecasted Revenue
                Decimal existingRemainingLevForecastedRevenue = projectToRemainingLevForecastRevenueMap.get(projectId);
                existingRemainingLevForecastedRevenue +=  remainingForecaseRevenue;
                projectToRemainingLevForecastRevenueMap.put(projectId, existingRemainingLevForecastedRevenue);
            }

            //Set the All inclusive Totals
            //Remaining TOTAL Forecasted Hours
            Decimal existingRemainingTotalForecastedHours = projectToTotalRemainingForecastHoursMap.get(projectId);
            existingRemainingTotalForecastedHours +=  remainingForecastHours;
            projectToTotalRemainingForecastHoursMap.put(projectId, existingRemainingTotalForecastedHours);

            //Remaining TOTAL Forecasted Revenue
            Decimal existingRemainingTotalForecastedRevenue = projectToTotalRemainingForecastRevenueMap.get(projectId);
            existingRemainingTotalForecastedRevenue +=  remainingForecastHours;
            projectToTotalRemainingForecastRevenueMap.put(projectId, existingRemainingTotalForecastedRevenue);
        }

        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c, Total_Remaining_Forecasted_Hours__c, ForecastDataLastSyncedOn__c
                                FROM Project__c
                                WHERE Id IN :relatedProjectIds];

        List<Project__c> projectsToUpdateList = new List<Project__c>();                
        for(Project__c proj : relatedProjectsList){

            //Creating a flag for the changes in order to not add the project to the update list twice
            Boolean remainingLevForecastedHoursChanged = false;
            Boolean remainingLevForecastedRevenueChanged = false;
            Boolean remainingTotalForecastedHoursChanged = false;

            //If rolled up sum of the project's remaining Forecasted Hours has changed then flag it to go into the update list
            if(projectToRemainingLevForecastHoursMap.containsKey(proj.Id) && projectToRemainingLevForecastHoursMap.get(proj.Id) != proj.Remaining_Forecasted_Hrs__c){
                proj.Remaining_Forecasted_Hrs__c = projectToRemainingLevForecastHoursMap.get(proj.Id);
                remainingLevForecastedHoursChanged = true;

            }
            //If rolled up sum of the project's remaining Forecasted Revenue has changed then flag it to go into the update list
            if(projectToRemainingLevForecastRevenueMap.containsKey(proj.Id) && projectToRemainingLevForecastRevenueMap.get(proj.Id) != proj.Remaining_Forecasted_Rev__c){
                proj.Remaining_Forecasted_Rev__c = projectToRemainingLevForecastRevenueMap.get(proj.Id);
                remainingLevForecastedRevenueChanged = true;
            }
            
            //If rolled up sum of the projects remaining TOTAL Forecasted Hours has changed then flag it to go into Update list
            if(projectToTotalRemainingForecastHoursMap.containsKey(proj.Id) && projectToTotalRemainingForecastHoursMap.get(proj.Id) != proj.Remaining_Forecasted_Rev__c){
                proj.Total_Remaining_Forecasted_Hours__c = projectToTotalRemainingForecastHoursMap.get(proj.Id);
                remainingTotalForecastedHoursChanged = true;
            }

            if(remainingLevForecastedHoursChanged || remainingLevForecastedRevenueChanged || remainingTotalForecastedHoursChanged){
                Datetime currentDT = datetime.now();
                proj.ForecastDataLastSyncedOn__c = currentDT;
                projectsToUpdateList.add(proj);
            }
        }

        if(projectsToUpdateList.size() > 0){
            update projectsToUpdateList;
        }
    }
    

    @future(callout=false)
    public static void rollupForecastsOnRelatedProjectsFuture(List<Id> projectIdList){
        //Rollup remaining Forecasted Hours and Revenue from Forecast records to the related Project
        System.debug('Future Method HERE');
        System.debug('Rolling Up Project Ids: ' + projectIdList);

        Map<Id, Decimal> projectToRemainingForecastHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToRemainingForecastRevenueMap = new Map<Id, Decimal>();

        List<Id> relatedProjectIds = new List<Id>();
        for(Id projId : projectIdList){
            relatedProjectIds.add(projId);
            projectToRemainingForecastHoursMap.put(projId, 0);
            projectToRemainingForecastRevenueMap.put(projId, 0);
        }

        AggregateResult[] forecastSum = [SELECT sum(EstimatedHours__c) estHours, sum(EstimatedRevenue__c) estRev, Project__c
                                            FROM RepliconForecast__c
                                            WHERE Week_Start_Date__c >= THIS_WEEK AND Deleted_in_Replicon__C = false AND Project__c IN :relatedProjectIds AND Contact__c != null AND Contact__r.AccountId != null AND Contact__r.Account.Name = 'Levementum LLC'
                                            GROUP BY Project__c];

        

        for(AggregateResult ar : forecastSum){
            //Loop through Forecast Sums and add them to Maps in order to update the Projects
            Id projectId;
            Decimal remainingForecastHours;
            Decimal remainingForecaseRevenue;

            projectId = (Id)ar.get('Project__c');
            remainingForecastHours = (Decimal)ar.get('estHours');
            remainingForecaseRevenue = (Decimal)ar.get('estRev');

            projectToRemainingForecastHoursMap.put(projectId, remainingForecastHours);
            projectToRemainingForecastRevenueMap.put(projectId, remainingForecaseRevenue);

        }

        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c, ForecastDataLastSyncedOn__c
                                FROM Project__c
                                WHERE Id IN :relatedProjectIds];

        List<Project__c> projectsToUpdateList = new List<Project__c>();                
        for(Project__c proj : relatedProjectsList){

            //Creating a flag for the changes in order to not add the project to the update list twice
            Boolean remainingForecastedHoursChanged = false;
            Boolean remainingForecastedRevenueChanged = false;
            //If rolled up sum of the project's remaining Forecasted Hours has changed then flag it to go into the update list
            if(projectToRemainingForecastHoursMap.containsKey(proj.Id) && projectToRemainingForecastHoursMap.get(proj.Id) != proj.Remaining_Forecasted_Hrs__c){
                proj.Remaining_Forecasted_Hrs__c = projectToRemainingForecastHoursMap.get(proj.Id);
                remainingForecastedHoursChanged = true;

            }
            //If rolled up sum of the project's remaining Forecasted Revenue has changed then flag it to go into the update list
            if(projectToRemainingForecastRevenueMap.containsKey(proj.Id) && projectToRemainingForecastRevenueMap.get(proj.Id) != proj.Remaining_Forecasted_Rev__c){
                proj.Remaining_Forecasted_Rev__c = projectToRemainingForecastRevenueMap.get(proj.Id);
                remainingForecastedRevenueChanged = true;
            }

            if(remainingForecastedHoursChanged || remainingForecastedRevenueChanged ){
                Datetime currentDT = datetime.now();
                proj.ForecastDataLastSyncedOn__c = currentDT;
                projectsToUpdateList.add(proj);
            }
        }

        if(projectsToUpdateList.size() > 0){
            System.debug('Pre-Updating ' + projectsToUpdateList.size() + ' Projects from Forecasts');
            update projectsToUpdateList;
            System.debug('Post-Updating ' + projectsToUpdateList.size() + ' Projects from Forecasts');
        }
    }

    public static Integer getBusinessDaysBetweenTwoDates(Date startDate, Date endDate, Boolean checkForSameMonth){

        List<Holiday> holidays =[SELECT StartTimeInMinutes, Name, ActivityDate FROM Holiday];

        Integer allDaysBetween = startDate.daysBetween(endDate);
        Integer allWorkingDays = 0;
        for(Integer k = 0; k < allDaysBetween; k++ ){
            if(checkifItisWorkingDay(startDate.addDays(k),holidays)){
                if(checkForSameMonth){ //Marked true if you only want business days within same month as the start date
                    if(startDate.month() == startDate.addDays(k).month()){ //Added to ensure it only checks the working days of days in the same month as the startDate
                        allWorkingDays++;
                    }
                }else{
                    allWorkingDays++;
                }
            } 
        }
        return allWorkingDays;
    }

    private static boolean checkifItisWorkingDay(Date currentDate,List<Holiday> holidays){
        Date weekStart  = currentDate.toStartofWeek();
        for(Holiday hDay:holidays){
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

    public static void linkForecastsToProjectRoleRecord(List<RepliconForecast__c> forecastList, Boolean needsUpdate, Boolean forNonLevEmployee){
        /**
         * Purpose: Match Time Entries to Project Role records via matching ProjectTeamMemberBillingRate__c name to the Project Role Name, and Rates
         * 
         * Functionality: 
         *  1.) Loop through the Forecasts (that are Billable and have a ProjectTeamMemberBillingRate__c populated) and get the Project and ProjectTeamMemberBillingRate__c Name to a map Key
         *  2.)     
         */
        System.debug('linkForecastsToProjectRoleRecord');

        List<Id> relatedProjectIdList = new List<Id>();
        List<Id> relatedBillingRateIdList = new List<Id>();
        List<RepliconForecast__c> forecastWithBillRateList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.Project__c != null){
                relatedProjectIdList.add(forecast.Project__c);
                relatedBillingRateIdList.add(forecast.ProjectTeamMemberBillingRate__c);
                forecastWithBillRateList.add(forecast);
            }
        }
        List<ProjectRole__c> relatedProjectRoleRecordsList = new List<ProjectRole__c>();
        if(forNonLevEmployee){
            relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c, Resource_Delivery_Group__c
            FROM ProjectRole__c
            WHERE Project__c IN :relatedProjectIdList AND Resource_Delivery_Group__c IN ('ATG')];
        }else{
            relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c, Resource_Delivery_Group__c
            FROM ProjectRole__c
            WHERE Project__c IN :relatedProjectIdList AND Resource_Delivery_Group__c IN ('Lev')];
        }
        System.debug('relatedProjectRoleRecordsList: ' + relatedProjectRoleRecordsList.size());
        System.debug('************** relatedProjectRoleRecordsList: ' + relatedProjectRoleRecordsList);
        /*relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c
            FROM ProjectRole__c
            WHERE Project__c IN :relatedProjectIdList];*/

        Map<Id, Map<String, ProjectRole__c>> projectIdToProjectRoleMap = new Map<Id, Map<String, ProjectRole__c>>();
        Map<String, Set<Integer>> projIdAndProjRoleNameToDuplicateCountMap = new Map<String, Set<Integer>>(); //Map to store the Project Id + Project Role Name as a Unique Key

        for(ProjectRole__c projectRole : relatedProjectRoleRecordsList){
            if(projectIdToProjectRoleMap.containsKey(projectRole.Project__c)){
                Map<String, ProjectRole__c> projectRoleNameToRecordMap = projectIdToProjectRoleMap.get(projectRole.Project__c);
                projectRoleNameToRecordMap.put(projectRole.Name, projectRole);
                projectIdToProjectRoleMap.put(projectRole.Project__c, projectRoleNameToRecordMap);
            }else{
                Map<String, ProjectRole__c> projectRoleNameToRecordMap = new Map<String, ProjectRole__c>();
                projectRoleNameToRecordMap.put(projectRole.Name, projectRole);
                projectIdToProjectRoleMap.put(projectRole.Project__c, projectRoleNameToRecordMap);
            }

            //Storing the count of how many duplicate Project Role Name there are that have the 1, 2, 3, 4, etc... after the Project Role Name (Ex. MC Solution Architect 2)
            String projRoleNameTrailingNumberString = projectRole.Name.normalizeSpace().substringAfterLast(' '); //Get the trailing if there is one
            Integer projectRoleTrailingNumber = projRoleNameTrailingNumberString.isNumeric() ? Integer.valueOf(projRoleNameTrailingNumberString) : 0; //If there is no trailing Number then add a 0 to the set, if there is a trailing number then add that number
            //Unique Name we only want the base Name of the Project Role Name so we need to strip the number at the end of the Name before putting it in the map
            String projIdAndProjRoleNameUniqueId = projRoleNameTrailingNumberString.isNumeric() ? String.valueOf(projectRole.Project__c) + '-' + projectRole.Name.normalizeSpace().substringBeforeLast(' ') : String.valueOf(projectRole.Project__c) + '-' + projectRole.Name.normalizeSpace();
            
            if(projIdAndProjRoleNameToDuplicateCountMap.containsKey(projIdAndProjRoleNameUniqueId)){

                Set<Integer> projRateNameTrailingNumbersSet = projIdAndProjRoleNameToDuplicateCountMap.get(projIdAndProjRoleNameUniqueId); //Get existing set of numbers
                projRateNameTrailingNumbersSet.add(projectRoleTrailingNumber); //Add the trailing number to the Set
                projIdAndProjRoleNameToDuplicateCountMap.put(projIdAndProjRoleNameUniqueId, projRateNameTrailingNumbersSet); //Put the set back into the Map

            }else{
                Set<Integer> projRateNameTrailingNumbersSet = new Set<Integer>{projectRoleTrailingNumber}; //Create new Set with trailing number in it
                projIdAndProjRoleNameToDuplicateCountMap.put(projIdAndProjRoleNameUniqueId, projRateNameTrailingNumbersSet); //Put the set back into the Map

            }
        }

        List<Project_Team_Member_Billing_Rate__c> relatedBillingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        relatedBillingRateList = [SELECT Id, Name, Hourly_Rate__c, Project__c
                                    FROM Project_Team_Member_Billing_Rate__c
                                    WHERE Id IN :relatedBillingRateIdList];

        Map<Id, Project_Team_Member_Billing_Rate__c> billingRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c billRate : relatedBillingRateList){
            billingRateIdToRecordMap.put(billRate.Id, billRate);
        }

        List<RepliconForecast__c> forecastsToUpdateWithProjectRolesList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastWithBillRateList){
            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.Project__c != null){
                if(billingRateIdToRecordMap.containsKey(forecast.ProjectTeamMemberBillingRate__c)){
                    String billingRateName = billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Name;
                    if(projectIdToProjectRoleMap.containsKey(forecast.Project__c)){
                        Map<String, ProjectRole__c> projectRoleNameToRecordMap = projectIdToProjectRoleMap.get(forecast.Project__c);
                        if(projectRoleNameToRecordMap.containsKey(billingRateName)){
                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billingRateName).Id){
                                System.debug('HERE IS THE FORECAST BEING MATCHED TO PROJECT ROLE');
                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billingRateName).Id;
                                forecastsToUpdateWithProjectRolesList.add(forecast);
                            }
                        }else{
                            //We check to see if it has numbers to attempt to match the Billing Rate to a similar Rate that possibly has a different number
                            Integer billRateTrailingNumber = billingRateName.normalizeSpace().substringAfterLast(' ').isNumeric() ? Integer.valueOf(billingRateName.normalizeSpace().substringAfterLast(' ')) : 0; //Get the trailing if there is one
                            String baseBillingRateName = billRateTrailingNumber == 0 ? billingRateName.normalizeSpace() : billingRateName.normalizeSpace().substringBeforeLast(' '); //Get the base Bill Rate name with no Trailing number if there is one
                            System.debug(' ********************** billRateTrailingNumber: ' + billRateTrailingNumber);
                            System.debug(' ********************** baseBillingRateName: ' + baseBillingRateName);
                            String projIdAndProjRoleNameUniqueId = String.valueOf(forecast.Project__c) + '-' + baseBillingRateName;
                            System.debug(' ********************** projIdAndProjRoleNameUniqueId: ' + projIdAndProjRoleNameUniqueId);

                            System.debug(' ********************** projIdAndProjRoleNameToDuplicateCountMap: ' + projIdAndProjRoleNameToDuplicateCountMap);

                            Boolean foundMatch = false; //Boolean to ensure that the forecast doesn't get updated twice
                            if(projIdAndProjRoleNameToDuplicateCountMap.containsKey(projIdAndProjRoleNameUniqueId)){ //If the base name of the billing rate is in the map then look for other Project Role records that might match this Billing Rate
                                Set<Integer> projectRoleTrailingNumbersSet = projIdAndProjRoleNameToDuplicateCountMap.get(projIdAndProjRoleNameUniqueId);
                                //If the bill rate trailing number is already in the set then remove because we don't need to check if that has a match since we already did
                                System.debug(' ********************** projectRoleTrailingNumbersSet: ' + projectRoleTrailingNumbersSet);
                                if(projectRoleTrailingNumbersSet.contains(billRateTrailingNumber)){
                                    projectRoleTrailingNumbersSet.remove(billRateTrailingNumber);
                                }
                                //Loop through the trailing numbers set and attempt to find a matching Project Role Name and ensure that the rates match as well.                                
                                ProjectRole__c potentialMatch = new ProjectRole__c();
                                for(Integer i : projectRoleTrailingNumbersSet){
                                    String billRateName;
                                    if(i == 0){
                                        billRateName = baseBillingRateName;
                                    }else{
                                        billRateName = baseBillingRateName + ' ' + String.valueOf(i);
                                    }

                                    System.debug(' ********************** projectRoleNameToRecordMap: ' + projectRoleNameToRecordMap);
                                    if(!foundMatch && projectRoleNameToRecordMap.containsKey(billRateName)){
                                        //If the Name has a match, we then check to see if the rates align before assigning it to the forecast record.
                                        System.debug(' ********************** projectRoleNameToRecordMap.get(billRateName).Rate__c: ' + projectRoleNameToRecordMap.get(billRateName).Rate__c);
                                        System.debug(' ********************** billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c: ' + billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c);
                                        if(projectRoleNameToRecordMap.get(billRateName).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billRateName).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billRateName).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }else{
                                            //If the rate is not an exact match, store it as a potential match
                                            if(potentialMatch.Id == null){
                                                potentialMatch = projectRoleNameToRecordMap.get(billRateName);
                                            }else{
                                                //If second rate comes in thats not a perfect match, compare the difference of the Project Team Member Billing Rate - Project Role Rate and see which is closer to get the potential match
                                                Decimal billRateToProjRateDiffold = Math.abs(billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c - potentialMatch.Rate__c);
                                                Decimal billRateToProjRateDiffnew = Math.abs(billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c - projectRoleNameToRecordMap.get(billRateName).Rate__c);
                                                if(billRateToProjRateDiffnew < billRateToProjRateDiffold){
                                                    potentialMatch = projectRoleNameToRecordMap.get(billRateName);
                                                }
                                            }
                                        }
                                    }         
                                }
                                //If no exact match was found, populate the Project Role field with the closest match
                                if(!foundMatch && potentialMatch.Id != null){
                                    if(forecast.ProjectRole__c != potentialMatch.Id){
                                        forecast.ProjectRole__c = potentialMatch.Id;
                                        forecastsToUpdateWithProjectRolesList.add(forecast);
                                        foundMatch = true;
                                    }
                                }
                            }
                            /*else if(!projectRolePrefixList.contains(baseBillingRateName.substringBefore(' '))){ //Only check the prefixes if the billing Rate does NOT already have a prefix on it
                                //If the Billing Rate name is not in the project Role Map, then try to add one of the pre-fixes to the name like CORE, MC, DTR, etc...and see if that has a match

                                //Check if the base name is also has the same rate but with a pre-fix attached. Check the list of products from each bundle that could have the billing Rate base name in it.
                                System.debug('inside Prefix Check');
                                String billNameWithPrefix;
                                if(cdpProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'CDP - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(coreProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'CORE - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(dmpProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'DMP - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(dtrProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'DTR - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(interactionStudioProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'Interaction Studio - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(mcProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'MC - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                                if(pardotProductsList.contains(baseBillingRateName)){
                                    billNameWithPrefix = 'Pardot - ' + billingRateName;
                                    if(projectRoleNameToRecordMap.containsKey(billNameWithPrefix)){
                                        if(projectRoleNameToRecordMap.get(billNameWithPrefix).Rate__c == billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Hourly_Rate__c){
                                            if(forecast.ProjectRole__c != projectRoleNameToRecordMap.get(billNameWithPrefix).Id){
                                                forecast.ProjectRole__c = projectRoleNameToRecordMap.get(billNameWithPrefix).Id;
                                                forecastsToUpdateWithProjectRolesList.add(forecast);
                                                foundMatch = true;
                                            }
                                        }
                                    }
                                }
                            }*/                           
                        }
                    }
                }
            }
        }

        if(needsUpdate && forecastsToUpdateWithProjectRolesList.size() > 0){
            System.debug('********************** Forecasts Getting Updated with Project Roles: ' + forecastsToUpdateWithProjectRolesList.size() + ' **********************');
            update forecastsToUpdateWithProjectRolesList;
        }
    }

    public static void calculateProjectRoleRollups(List<RepliconForecast__c> forecastList){
        /**
         * Purpose: Rollup the Forecasted_Hours__c and Total_Hours_Billed__c on the related Project Role Records
         * 
         * Functionality:
         *  1.) Get List of all the Related Project Role Record Ids
         *  2.) Aggregate Query the Forecasted Hours and Amounts of all related Project Roles
         *  3.) Put the aggregate Hours and Amounts into a map with the Project Role Id as the Key
         *  4.) Query the related Project Role records
         *  5.) Assign the Total Hours and Amount Forecasted to the records
         *  6.) Update the records if there is a change
         */

        Map<Id, ProjectRole__c> projectRoleIdToUpdateRecordMap = new Map<Id, ProjectRole__c>();  //Initialize Project Role Id to a Project Role record with initialized 0 Total Billed Hours and 0 Total Billed Amount
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.ProjectRole__c != null){
                ProjectRole__c updateProjectRoleRecord = new ProjectRole__c(Id = forecast.ProjectRole__c, Forecasted_Hours__c = 0, Forecasted_Revenue__c = 0, Remaining_Forecasted_Hours__c = 0, Remaining_Forecasted_Revenue__c = 0);
                projectRoleIdToUpdateRecordMap.put(updateProjectRoleRecord.Id, updateProjectRoleRecord);

            }
        }

        if(projectRoleIdToUpdateRecordMap.size() > 0){

            //Aggregate Query of Billable Hours and Billable Amount of all Time Entries that are related to the Project Role of the incoming Time Entries
            AggregateResult[] forecastAggregate = [SELECT sum(EstimatedHours__c) forecastedHours, sum(EstimatedRevenue__c) forecastedAmount, ProjectRole__c
                                                    FROM RepliconForecast__c
                                                    WHERE ProjectRole__c IN :projectRoleIdToUpdateRecordMap.keySet() AND EstimatedHours__c > 0 AND Deleted_in_Replicon__c = false
                                                    GROUP BY ProjectRole__c];
                                     
            for(AggregateResult ar : forecastAggregate){
                Id projectRoleId;
                Decimal totalForecastedHours;
                Decimal totalForecastedAmount;

                projectRoleId = (Id)ar.get('ProjectRole__c');

                if(projectRoleIdToUpdateRecordMap.containsKey(projectRoleId)){
                    ProjectRole__c updateProjectRoleRecord = projectRoleIdToUpdateRecordMap.get(projectRoleId);

                    totalForecastedHours = (Decimal)ar.get('forecastedHours') != null ? (Decimal)ar.get('forecastedHours') : 0;
                    totalForecastedAmount = (Decimal)ar.get('forecastedAmount') != null ? (Decimal)ar.get('forecastedAmount') : 0;

                    updateProjectRoleRecord.Forecasted_Hours__c = totalForecastedHours;
                    updateProjectRoleRecord.Forecasted_Revenue__c = totalForecastedAmount;

                    projectRoleIdToUpdateRecordMap.put(updateProjectRoleRecord.Id, updateProjectRoleRecord); //Put the Aggregated Hours and Amount into the update Project Rate that we will use to compare the new value and the existing value of that Project Rate
                }
            }

            Date currentWeekStartDate = Date.today().toStartofWeek();

            //Aggregate Query for the Remaining Forecasted Hours/Revenue
            AggregateResult[] currentAndFutureForecastAgg = [SELECT SUM(EstimatedHours__c) remainingForecastedHours, SUM(EstimatedRevenue__c) remainingForecastedRevenue, ProjectRole__c
                                                                FROM RepliconForecast__c
                                                                WHERE ProjectRole__c IN :projectRoleIdToUpdateRecordMap.keySet() AND EstimatedHours__c > 0 AND Deleted_in_Replicon__c = false AND Week_End_Date__c > :currentWeekStartDate
                                                                GROUP BY ProjectRole__c];
            
            for(AggregateResult ar : currentAndFutureForecastAgg){
                Id projectRoleId;
                Decimal totalRemainingForecastedHours;
                Decimal totalRemainingForecastedAmount;

                projectRoleId = (Id)ar.get('ProjectRole__c');

                if(projectRoleIdToUpdateRecordMap.containsKey(projectRoleId)){
                    ProjectRole__c updateProjectRoleRecord = projectRoleIdToUpdateRecordMap.get(projectRoleId);

                    totalRemainingForecastedHours = (Decimal)ar.get('remainingForecastedHours') != null ? (Decimal)ar.get('remainingForecastedHours') : 0;
                    totalRemainingForecastedAmount = (Decimal)ar.get('remainingForecastedRevenue') != null ? (Decimal)ar.get('remainingForecastedRevenue') : 0;

                    updateProjectRoleRecord.Remaining_Forecasted_Hours__c = totalRemainingForecastedHours;
                    updateProjectRoleRecord.Remaining_Forecasted_Revenue__c = totalRemainingForecastedAmount;

                    projectRoleIdToUpdateRecordMap.put(updateProjectRoleRecord.Id, updateProjectRoleRecord); //Put the Aggregated Hours and Amount into the update Project Rate that we will use to compare the new value and the existing value of that Project Rate
                }
            }

            List<ProjectRole__c> relatedProjectRoleRecordsList = new List<ProjectRole__c>();
            relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Product__c, Forecasted_Hours__c, Forecasted_Revenue__c, Remaining_Forecasted_Hours__c, Remaining_Forecasted_Revenue__c
                                                FROM ProjectRole__c
                                                WHERE Id IN :projectRoleIdToUpdateRecordMap.keySet()];

            List<ProjectRole__c> projectRoleToUpdateList = new List<ProjectRole__c>();
            for(ProjectRole__c pr : relatedProjectRoleRecordsList){
                //Check Map with Update Record in it, then compare new values to Existing Values
                if(projectRoleIdToUpdateRecordMap.containsKey(pr.Id)){
                    ProjectRole__c newProjectRoleRollups = projectRoleIdToUpdateRecordMap.get(pr.Id);

                    //If values are different then add to the update list
                    if(pr.Forecasted_Hours__c != newProjectRoleRollups.Forecasted_Hours__c || pr.Forecasted_Revenue__c != newProjectRoleRollups.Forecasted_Revenue__c || pr.Remaining_Forecasted_Hours__c != newProjectRoleRollups.Remaining_Forecasted_Hours__c || pr.Remaining_Forecasted_Revenue__c != newProjectRoleRollups.Remaining_Forecasted_Revenue__c){
                        pr.Forecasted_Hours__c = newProjectRoleRollups.Forecasted_Hours__c;
                        pr.Forecasted_Revenue__c = newProjectRoleRollups.Forecasted_Revenue__c;
                        pr.Remaining_Forecasted_Hours__c = newProjectRoleRollups.Remaining_Forecasted_Hours__c;
                        pr.Remaining_Forecasted_Revenue__c = newProjectRoleRollups.Remaining_Forecasted_Revenue__c;
                        projectRoleToUpdateList.add(pr);
                    }
                    
                }                
            }

            if(projectRoleToUpdateList.size() > 0){
                System.debug('*********************************************************** Updating ' + projectRoleToUpdateList.size() + ' Project Role Records ***********************************************************');
                update projectRoleToUpdateList;
            }

        }

    }

    //Created for Placeholder Forecasts 6/3/2022
    public static void checkForPlaceholdersToDelete(Set<Id> projectIdSet){
        //Purpose: Check to see if the Project the incoming forecast is on has any kick off placeholder forecasts, if so then delete them.
        /**
         *  Functionality: 
         *  1.) Get the project Ids of the incoming forecasts that are from Replicon (i.e. have NotForecasted__c = false)
         *  2.) Query any existing Kickoff Placeholder Forecasts that are associated with those project
         *  3.) If there are any then delete them.
         */
        try{

            if(projectIdSet.size() > 0){
                List<RepliconForecast__c> kickoffPlaceholderForecastList = new List<RepliconForecast__c>();
                kickoffPlaceholderForecastList = [SELECT Id, Name, Kickoff_Placeholder_Forecast__c, Project__c, Project__r.Name FROM RepliconForecast__c WHERE Kickoff_Placeholder_Forecast__c = true AND Project__c IN :projectIdSet];

                if(kickoffPlaceholderForecastList.size() > 0){
                    System.debug('*********************************************************** Deleting ' + kickoffPlaceholderForecastList.size() + ' PKickoff Placeholder Forecast Records ***********************************************************');
                    delete kickoffPlaceholderForecastList;
                }
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e.getMessage() + ', Project IDs: ' + projectIdSet , e.getLineNumber(), 'RepliconForecastTriggerHelper', 'checkForPlaceholdersToDelete', NULL);
        }
    }

    //Created to determine if Forecast is for Lev Employee or not
    public static void checkIfLevForecast(List<RepliconForecast__c> forecastList){

        List<Id> contactIdList = new List<Id>();
        for(RepliconForecast__c forecast : forecastList){
            //Loop throught Forecasts and put Contact Id into list to query
            contactIdList.add(forecast.Contact__c);
        }

        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>();
        if(contactIdList.size() > 0){
            //Query the related Contacts only if they are associated with the Levementum LLC Account
            List<Contact> relatedContactList = new List<Contact>();
            relatedContactList = [SELECT Id, Name, AccountId, Account.Name FROM Contact WHERE Id IN :contactIdList];

            for(Contact con : relatedContactList){
                contactIdToContactMap.put(con.Id, con);
            }

        }

        List<RepliconForecast__c> updateForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            if(contactIdToContactMap.containsKey(forecast.Contact__c) && forecast.Week_End_Date__c != null){
                Contact forecastEmployee = contactIdToContactMap.get(forecast.Contact__c);

                if(((forecast.Week_End_Date__c < switchToATGTimeWeekEndDate && forecastEmployee.Name != atgConsultantContactName) 
                    || (forecast.Week_End_Date__c >= switchToATGTimeWeekEndDate && forecastEmployee.Name != atgConsultantContactName && forecastEmployee.Account.Name == levementumAccountName)) && forecast.Is_Lev_Forecast__c != true){

                    //If Forecast needs to be set or updated to a Lev Forecast then set it
                    forecast.Is_Lev_Forecast__c = true;

                }else if(forecast.Is_Lev_Forecast__c){ //If Forecast is set as a Lev Forecast but should not be, then change it and add to update list
                    forecast.Is_Lev_Forecast__c = true;
                }
            }
        }

        //OLD - Used to have a needsUpdate paramater to handle if this method was wanted to be used to update instead of just before triggers
        /*if(needsUpdate && updateForecastList.size() > 0){
            System.debug('********************************************************************* Updating ' + updateForecastList.size() + ' Forecasts for Is Lev Forecast Field *********************************************************************');
            update updateForecastList;
        }*/
    }

    public static void linkForecastsToStaffingAssignments(List<RepliconForecast__c> forecastList, Boolean needsUpdate){

        List<Id> relatedProjectIdList = new List<Id>();
        List<Id> relatedContactIdList = new List<Id>();
        List<Id> relatedBillingRateIdList = new List<Id>();
        List<RepliconForecast__c> forecastWithBillRateList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> forecastsToUpdateWithStaffingAssignmentsList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.Project__c != null){
                relatedProjectIdList.add(forecast.Project__c);
                relatedContactIdList.add(forecast.Contact__c);
                relatedBillingRateIdList.add(forecast.ProjectTeamMemberBillingRate__c);
                forecastWithBillRateList.add(forecast);
            }
        }

        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Opportunity__c FROM Project__c WHERE Id IN :relatedProjectIdList];

        Map<Id, Id> projectIdToOpportunityIdMap = new Map<Id, Id>();
        for(Project__c proj : relatedProjectsList){
            projectIdToOpportunityIdMap.put(proj.Id, proj.Opportunity__c);
        }

        List<Staffing_Assignment__c> relatedStaffingAssignmentsRecordsList = new List<Staffing_Assignment__c>();
        relatedStaffingAssignmentsRecordsList = [SELECT Id, Name, Resource_Assigned__c, Opportunity__c, Product__c, Product__r.Name, Product_Name__r.TotalPrice
                                                FROM Staffing_Assignment__c
                                                WHERE Opportunity__c IN :projectIdToOpportunityIdMap.values() AND Resource_Assigned__c IN :relatedContactIdList];

        if(relatedStaffingAssignmentsRecordsList.size() > 0){
            Map<String, Staffing_Assignment__c> uniqueStaffingAssignmentIdToStaffingAssignmentRecordMap = new Map<String, Staffing_Assignment__c>();
            for(Staffing_Assignment__c staffingAssignment : relatedStaffingAssignmentsRecordsList){

                String uniqueStaffingAssignmentId = String.valueOf(staffingAssignment.Opportunity__c) + '|' + String.valueOf(staffingAssignment.Resource_Assigned__c) + '|' + String.valueOf(staffingAssignment.Product__r.Name);
                uniqueStaffingAssignmentIdToStaffingAssignmentRecordMap.put(uniqueStaffingAssignmentId, staffingAssignment);
            }

            List<Project_Team_Member_Billing_Rate__c> relatedBillingRateList = new List<Project_Team_Member_Billing_Rate__c>();
            relatedBillingRateList = [SELECT Id, Name, Hourly_Rate__c, Project__c
                                        FROM Project_Team_Member_Billing_Rate__c
                                        WHERE Id IN :relatedBillingRateIdList];

            Map<Id, Project_Team_Member_Billing_Rate__c> billingRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
            for(Project_Team_Member_Billing_Rate__c billRate : relatedBillingRateList){
                billingRateIdToRecordMap.put(billRate.Id, billRate);
            }

            for(RepliconForecast__c forecast : forecastWithBillRateList){
                if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.Project__c != null && forecast.Contact__c != null){
                    if(billingRateIdToRecordMap.containsKey(forecast.ProjectTeamMemberBillingRate__c)){
                        String billingRateName = billingRateIdToRecordMap.get(forecast.ProjectTeamMemberBillingRate__c).Name;
                        String uniqueId = String.valueOf(projectIdToOpportunityIdMap.get(forecast.Project__c)) + '|' + String.valueOf(forecast.Contact__c) + '|' + billingRateName;
                        if(uniqueStaffingAssignmentIdToStaffingAssignmentRecordMap.containsKey(uniqueId)){
                            if(forecast.StaffingAssignment__c != uniqueStaffingAssignmentIdToStaffingAssignmentRecordMap.get(uniqueId).Id){
                                forecast.StaffingAssignment__c = uniqueStaffingAssignmentIdToStaffingAssignmentRecordMap.get(uniqueId).Id;
                                forecastsToUpdateWithStaffingAssignmentsList.add(forecast);
                            }
                        }
                    }
                }
            }
        }

        if(needsUpdate && forecastsToUpdateWithStaffingAssignmentsList.size() > 0){
            System.debug('********************** Forecasts Getting Updated with Staffing Assignments: ' + forecastsToUpdateWithStaffingAssignmentsList.size() + ' **********************');
            update forecastsToUpdateWithStaffingAssignmentsList;
        }

    }


    public static void populateForecastBillingRate(List<RepliconForecast__c> forecastList, Boolean needsUpdate){
        System.debug('START populateForecastBillingRate');
        Set<Id> relatedEmployeeIdSet = new Set<Id>();
        Set<Id> relatedProjectIdSet = new Set<Id>();
        Set<Id> projTeamMemberIdSet = new Set<Id>();
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Contact__c != null && forecast.Project__c != null){
                relatedEmployeeIdSet.add(forecast.Contact__c);
                relatedProjectIdSet.add(forecast.Project__c);
            }

            if(forecast.Internal_Project_Team_Member__c != null){
                projTeamMemberIdSet.add(forecast.Internal_Project_Team_Member__c);
            }
        }

        List<Client_Contact__c> relatedProjTeamMembersList = new List<Client_Contact__c>();
        relatedProjTeamMembersList = [SELECT Id, Name, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Project__c, Client_Contact__c, 
                                            Active_Effective_Billing_Rate__c, Active_Effective_Billing_Rate__r.Project_Billing_Rate__c, Active_Effective_Billing_Rate__r.Effective_Date__c, 
                                            (SELECT Id, Name, Internal_Project_Team_Member__c, Project_Billing_Rate__c, Effective_Date__c FROM Project_Team_Member_Effective_Rates__r)
                                        FROM Client_Contact__c
                                        WHERE Project__c IN :relatedProjectIdSet AND Client_Contact__c IN :relatedEmployeeIdSet AND Client_Contact__r.Name != 'Place Holder'
                                        ORDER BY Project__c];

        Map<String, Client_Contact__c> uniqueIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
        for(Client_Contact__c ptm : relatedProjTeamMembersList){
            String uniqueProjTeamMemberId = String.valueOf(ptm.Project__c) + '|' + String.valueOf(ptm.Client_Contact__c);
            uniqueIdToProjTeamMemberMap.put(uniqueProjTeamMemberId, ptm);
        }

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> checkEffectiveRatesForecastList = new List<RepliconForecast__c>();

        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Contact__c != null && forecast.Project__c != null){
                String uniqueForecastId = String.valueOf(forecast.Project__c) + '|' + String.valueOf(forecast.Contact__c);

                if(uniqueIdToProjTeamMemberMap.containsKey(uniqueForecastId)){
                    Client_Contact__c relatedProjTeamMember = uniqueIdToProjTeamMemberMap.get(uniqueForecastId);
                    if( forecast.Internal_Project_Team_Member__c == null){
                        forecast.Internal_Project_Team_Member__c = uniqueIdToProjTeamMemberMap.get(uniqueForecastId).Id;
                    }

                    if(relatedProjTeamMember.Assigned_Billing_Rate__c != null){
                        if(relatedProjTeamMember.Project_Team_Member_Effective_Rates__r.size() > 0){
                            //If Active Effective Billing Rate is populated AND the currently ACTIVE Effective Billing Rate Effective Date is Past the Entries entry Date 
                            //then we need to check the effective rates for this Entry in order to make sure it is assigned to correct Bill Rate based on any Effective Bill Rates that the project team member has
                            System.debug('Check Effective Rates Forecast Name: ' + forecast.Name);
                            checkEffectiveRatesForecastList.add(forecast);

                        }else if(forecast.ProjectTeamMemberBillingRate__c != relatedProjTeamMember.Assigned_Billing_Rate__c){
                            forecast.ProjectTeamMemberBillingRate__c = relatedProjTeamMember.Assigned_Billing_Rate__c;
                            System.debug('Update Non Effective Rate Forecast Name: ' + forecast.Name);
                            forecastUpdateList.add(forecast);
                        }
                    }         
                }
            }
        }

        if(checkEffectiveRatesForecastList.size() > 0){
            System.debug('************************ Checking the Effective Rates of ' + checkEffectiveRatesForecastList.size() + ' Forecast(s) for Billing Rate Population ******************************');
            List<RepliconForecast__c> effectiveRateForecastToUpdateList = new List<RepliconForecast__c>();
            effectiveRateForecastToUpdateList = checkEffectiveRatesForForecastBillingRatePopulation(checkEffectiveRatesForecastList);
            System.debug('************************ Returned ' + effectiveRateForecastToUpdateList.size() + ' from checking Effective Rates for Forecast(s) for Billing Rate Population ******************************');
            if(effectiveRateForecastToUpdateList.size() > 0){
                forecastUpdateList.addAll(effectiveRateForecastToUpdateList);
            }
        }

        if(needsUpdate && forecastUpdateList.size() > 0){
            System.debug('**************** Updating ' + forecastUpdateList.size() + ' Forecast(s) with Billing Rates ****************** ');
            update forecastUpdateList;
        }
        System.debug('END populateForecastBillingRate');
    }

    public static List<RepliconForecast__c> checkEffectiveRatesForForecastBillingRatePopulation(List<RepliconForecast__c> forecastList){

        System.debug('Check Effective Forecast Rates START');

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();

        Set<Id> internalProjTeamMemberIdSet = new Set<Id>();
        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Internal_Project_Team_Member__c != null){
                internalProjTeamMemberIdSet.add(forecast.Internal_Project_Team_Member__c);
            }
        }

        List<Project_Team_Member_Effective_Rate__c> effectiveRateList = new List<Project_Team_Member_Effective_Rate__c>();
        effectiveRateList = [SELECT Id, Name, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Internal_Project_Team_Member_Name__c, Effective_Date__c
                                FROM Project_Team_Member_Effective_Rate__c
                                WHERE Internal_Project_Team_Member__c IN :internalProjTeamMemberIdSet AND Project_Billing_Rate__c != null
                                ORDER BY Internal_Project_Team_Member__c, Effective_Date__c ASC];

        Map<Id, List<Project_Team_Member_Effective_Rate__c>> teamMemberIdToEffectiveRatesListMap = new Map<Id, List<Project_Team_Member_Effective_Rate__c>>();
        for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){
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
        for(RepliconForecast__c forecast : forecastList){
            //System.debug('Entry Name: ' + entry.Name);
            Id effectiveRateToAssignBillRateId;
            Boolean billingRateFound = false;
            if(forecast.Internal_Project_Team_Member__c != null && teamMemberIdToEffectiveRatesListMap.containsKey(forecast.Internal_Project_Team_Member__c)){

                //get list of effective dates for all effective rates
                List<Project_Team_Member_Effective_Rate__c> projTeamMemberEffectiveRateList = teamMemberIdToEffectiveRatesListMap.get(forecast.Internal_Project_Team_Member__c);
                
                //loop through all effective dates, find one that is less than the entry date, if more than one then find the one that is closest to entry's entry date
                for(Project_Team_Member_Effective_Rate__c effectiveRate : projTeamMemberEffectiveRateList){
                    //System.debug('*****************Effective Rate Loop Start: ' + effectiveRate.Project_Billing_Rate__r.Name + ' Effective Date: ' + effectiveRate.Effective_Date__c);
                    if(effectiveRate.Effective_Date__c == null || forecast.Week_End_Date__c >= effectiveRate.Effective_Date__c){  
                        if(effectiveRate.Effective_Date__c != null){

                            //If the Forecast's End Date is past the effective rate then set it as the bill rate to assign to the forecast
                            //This will continue to set it as the bill rate to assign until there is either 1.) No more effective rates to iterate through. OR 2.)There Forecast's End Date is EARLIER than the effective date.
                            //Since the Effective Rates are ordered by Effective Date ASC, it will iterate through the earliest date first and will continue until there is an effective rate that is past the forecast's week end date.
                            effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                        }else{
                            //Null values will come through first, so we store the rate that has null value to continue to loop through
                            //New feature 6.13.2023 No Effective Rates will come in with Null Effective Rates anymore.                          
                            effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                        }
                    }else{
                        if(effectiveRateToAssignBillRateId == null){
                            effectiveRateToAssignBillRateId = effectiveRate.Project_Billing_Rate__c;
                        }
                        break;
                    }
                }

                //If it looped through all Effective Rates and none of them had an Effective Rate that was smaller than the Entry's entry date, then use the effective rate that had NO Effective Date that was stored as the bill rate
                if(effectiveRateToAssignBillRateId != null && forecast.ProjectTeamMemberBillingRate__c != effectiveRateToAssignBillRateId){
                    forecast.ProjectTeamMemberBillingRate__c = effectiveRateToAssignBillRateId;
                    //System.debug('Adding Entry to Update From Effective Rate WITHOUT Effective DATE populated Population');
                    forecastUpdateList.add(forecast);
                }
            }
        }

        System.debug('Check Effective Rates Forecasts END');

        return forecastUpdateList;

    }

    public static void populateForecastTimesheet(List<RepliconForecast__c> forecastList,  Boolean needsUpdate){
        System.debug('START populateForecastTimesheet');
        List<RepliconForecast__c> forecastsToCreateNewTimesheetsForList = new List<RepliconForecast__c>();

        Set<Id> contactIdSet = new Set<Id>();
        Set<Date> weekStartDateSet = new Set<Date>();
        Set<Id> forecastIdSet = new Set<Id>();

        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Contact__c != null && forecast.Week_Start_Date__c != null){
                contactIdSet.add(forecast.Contact__c);
                weekStartDateSet.add((forecast.Week_Start_Date__c));
                if(needsUpdate){
                    forecastIdSet.add(forecast.Id);
                }
            }
        }

        List<Replicon_Timesheet__c> relatedTimesheetList = new List<Replicon_Timesheet__c>();
        relatedTimesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c FROM Replicon_Timesheet__c WHERE Employee__c IN :contactIdSet AND Start_Date__c IN :weekStartDateSet];

        Map<String, Replicon_Timesheet__c> uniqueTimesheetIdMap = new Map<String, Replicon_Timesheet__c>();
        for(Replicon_Timesheet__c sheet : relatedTimesheetList){
            String uniqueTimesheetId = String.valueOf(sheet.Employee__c) + '|' + String.valueOf(sheet.Start_Date__c);
            uniqueTimesheetIdMap.put(uniqueTimesheetId, sheet);

        }
        if(needsUpdate){
            forecastList = [SELECT Id, Name, Contact__c, Project__c, Week_Start_Date__c, Week_End_Date__c, Timesheet__c FROM RepliconForecast__c WHERE Id IN :forecastIdSet];
        }
        
        List<RepliconForecast__c> updateForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){

            if(forecast.Contact__c != null && forecast.Week_Start_Date__c != null){
                String uniqueTimesheetId = String.valueOf(forecast.Contact__c) + '|' + String.valueOf((forecast.Week_Start_Date__c));

                if(uniqueTimesheetIdMap.containsKey(uniqueTimesheetId)){
                    Replicon_Timesheet__c relatedTimesheet = uniqueTimesheetIdMap.get(uniqueTimesheetId);
                    if(forecast.Timesheet__c != relatedTimesheet.Id){
                        forecast.Timesheet__c = relatedTimesheet.Id;
                        updateForecastList.add(forecast);
                    }
                }else{
                    forecastsToCreateNewTimesheetsForList.add(forecast);
                }
            }
        }

        if(needsUpdate && updateForecastList.size() > 0){
            System.debug('************************************* Updating ' + updateForecastList.size() + ' Forecasts with Existing Timesheet Lookups *************************************');
            update updateForecastList;
        }

        if(forecastsToCreateNewTimesheetsForList.size() > 0){
            System.debug('************************************* BEFORE Creating timesheets for' + forecastsToCreateNewTimesheetsForList.size() + ' Forecasts with No Existing Timesheet Lookups *************************************');
            createNewTimesheet(forecastsToCreateNewTimesheetsForList, false);
        }
        System.debug('END populateForecastTimesheet');
    }

    public static void createNewTimesheet(List<RepliconForecast__c> forecastList,  Boolean needsUpdate){
        System.debug('START createNewTimesheet for Forecasts');
        Map<String, Replicon_Timesheet__c> uniqueTimesheetIdToTimesheetMap = new Map<String, Replicon_Timesheet__c>();
        Set<Id> relatedContactIdSet = new Set<Id>();

        for(RepliconForecast__c forecast : forecastList){
            if(forecast.Contact__c != null && forecast.Week_Start_Date__c != null){
                String uniqueTimesheetId = String.valueOf(forecast.Contact__c) + '|' + String.valueOf(forecast.Week_Start_Date__c);

                if(!uniqueTimesheetIdToTimesheetMap.containsKey(uniqueTimesheetId)){ 
                    //Make map of unique TImesheet Id to Timesheet for creation of each timesheet that does not create duplicates since each week of timesheets will have the same unique timesheet Id of Employee Cognizant ID + the start of the week the time entry is for
                    Replicon_Timesheet__c newTimesheet = new Replicon_Timesheet__c(Employee__c = forecast.Contact__c, Start_Date__c = (forecast.Week_Start_Date__c));
                    uniqueTimesheetIdToTimesheetMap.put(uniqueTimesheetId, newTimesheet);
                }

                if(!contactIdToRecordPublicMap.containsKey(forecast.Contact__c)){
                    relatedContactIdSet.add(forecast.Contact__c);
                }
            }
        }

        List<Contact> relatedEmployeesList = new List<Contact>();
        if(relatedContactIdSet.size() > 0){
            relatedEmployeesList = [SELECT Id, Name, Title, Department, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, 
                                        RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId, Cognizant_Employee_ID__c
                                    FROM Contact 
                                    WHERE Id IN :relatedContactIdSet];

            for(Contact c : relatedEmployeesList){
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

        List<RepliconForecast__c> updateForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__c forecast : forecastList){
            String uniqueTimesheetId = String.valueOf(forecast.Contact__c) + '|' + String.valueOf(forecast.Week_Start_Date__c);

            if(uniqueTimesheetIdToTimesheetMap.containsKey(uniqueTimesheetId)){
                forecast.Timesheet__c = uniqueTimesheetIdToTimesheetMap.get(uniqueTimesheetId).Id;
                updateForecastList.add(forecast);
            }
        }

        if(needsUpdate && updateForecastList.size() > 0){
            System.debug('************************************* Updating ' + updateForecastList.size() + ' Forecast(s) with NEWLY CREATED Timesheet Lookups *************************************');
            update updateForecastList;
        }

        System.debug('END createNewTimesheet');
    }
}