/**
 * Created 4/12/2022 ST
 * Purpose: Rollup Time Entry Actual Hours and Revenue to the related Forecasts
 * 
 * Class is to help keep some functionality of Time Entry processes out of RepliconService Class
 */

public with sharing class RepliconTimeEntryTriggerHelper {

    private static String atgContactId = '0030W00003n00V7QAI';
    
    public static void RepliconTimeEntryTriggerHelper_Manager(List<Replicon_Time_Entry__c> entryList, Map<Id, Replicon_Time_Entry__c> oldMap, String triggerEntry){

        System.debug('RepliconTimeEntryTriggerHelper_Manager');

        List<Replicon_Time_Entry__c> ptoEntryList = new List<Replicon_Time_Entry__c>();
        //List<Replicon_Time_Entry__c> billableEntryList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> billableNonLevEntryList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> billableLevEntryList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupProjectRoleEntryList = new List<Replicon_Time_Entry__c>();
        List<Replicon_Time_Entry__c> rollupQuarterBilledHoursEntryList = new List<Replicon_Time_Entry__c>();

        for(Replicon_Time_Entry__c entry : entryList){
            if(triggerEntry == 'onAfterUpdate' || triggerEntry == 'onBeforeUpdate'){
                Replicon_Time_Entry__c oldEntry = oldMap.get(entry.Id);

                if(triggerEntry == 'onAfterUpdate'){
                    //Check After Update if it has Hours/Rate/Forecast/TimeOff/Deleted Changed to calculate Forecasted Hours Rollup for PTO Related Forecasts
                    if(((entry.Time_Off__c == true || oldEntry.Time_Off__c == true) && entry.Replicon_Forecast__c != null) && (entry.Time_Off__c != oldEntry.Time_Off__c || entry.TotalHrs__c != oldEntry.TotalHrs__c || 
                            entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Replicon_Forecast__c != oldEntry.Replicon_Forecast__c)){
                        ptoEntryList.add(entry);
                    }

                    //Check if fields have changed that would require the values at the related Project Role record to need to be recalculated
                    if(entry.ProjectRole__c != null && (entry.ProjectRole__c != oldEntry.ProjectRole__c || entry.TotalHrs__c != oldEntry.TotalHrs__c || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c)){
                        rollupProjectRoleEntryList.add(entry);
                        if(entry.ProjectRole__c != oldEntry.ProjectRole__c ){
                            rollupProjectRoleEntryList.add(oldEntry);
                        }
                    }

                    if((entry.TotalHrs__c != oldEntry.TotalHrs__c || entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || (entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c && (entry.Associated_Billing_Rate__c == null || oldEntry.Associated_Billing_Rate__c == null)) || 
                         entry.Employee__c != oldEntry.Employee__c) && entry.Employee__c != null && entry.EntryDate__c != null){
                        rollupQuarterBilledHoursEntryList.add(entry);
                        if(entry.Employee__c != oldEntry.Employee__c && oldEntry.Employee__c != null && oldEntry.EntryDate__c != null){
                            rollupQuarterBilledHoursEntryList.add(oldEntry);
                        }
                    }
                    
                }else if(triggerEntry == 'onBeforeUpdate'){
                    //Check if Updated Record has been edited to be undeleted/Billing Rate Changed/Hours Changed to relate it to a Project Role Record
                    if(entry.Deleted_in_Replicon__c != oldEntry.Deleted_in_Replicon__c || entry.Associated_Billing_Rate__c != oldEntry.Associated_Billing_Rate__c || entry.TotalHrs__c != oldEntry.TotalHrs__c){
                        //billableEntryList.add(entry);
                        if(entry.Is_Lev_Time__c){ 
                            billableLevEntryList.add(entry);
                        }else{
                            billableNonLevEntryList.add(entry);
                        }
                    }
                }

            }else if(triggerEntry == 'onAfterInsert'){
                //Check After Insert if it is a Time Off Record and has a forecasted to calculate Forecasted Hours Rollup for PTO Related Forecasts
                if(entry.Time_Off__c == true && entry.Replicon_Forecast__c != null){
                    ptoEntryList.add(entry);
                }

                //Check if newly inserted field has a Project Role value to be recalculated
                if(entry.ProjectRole__c != null && entry.Deleted_in_Replicon__c == false){
                    rollupProjectRoleEntryList.add(entry);
                }

                if(entry.Employee__c != null && entry.TotalHrs__c != null && entry.TotalHrs__c != 0 && entry.Associated_Billing_Rate__c != null && entry.EntryDate__c != null && entry.Deleted_in_Replicon__c == false && entry.Time_Off__c == false){
                    rollupQuarterBilledHoursEntryList.add(entry);
                }

            }else if(triggerEntry == 'onBeforeInsert'){
                //Relate record to a Project Role Record
                //billableEntryList.add(entry);
                if(entry.Is_Lev_Time__c){
                    billableLevEntryList.add(entry);
                }else{
                    billableNonLevEntryList.add(entry);
                }
            }
        }

        if(ptoEntryList.size() > 0){
            rollupPTOForecastHours(ptoEntryList);
        }

        if(billableLevEntryList.size() > 0){
            linkTimeEntryToProjectRoleRecord(billableLevEntryList, false, false);
        }

        if(billableNonLevEntryList.size() > 0){
            linkTimeEntryToProjectRoleRecord(billableNonLevEntryList, false, true);
        }

        if(rollupProjectRoleEntryList.size() > 0){
            calculateProjectRoleRollups(rollupProjectRoleEntryList);
        }

        if(rollupQuarterBilledHoursEntryList.size() > 0){
            rollupEmployeeQuarterlyAmountBilled(rollupQuarterBilledHoursEntryList);
        }
    }



    public static void rollupActualsToRelatedForecast(List<Replicon_Time_Entry__c> entryList){

    }

    //Future methods will run in the background asyncronously.
    //Future methods have a higher SOQL query limit and heap size for processing
    //Future methods do not accept sObjects as parameters
    @future
    public static void previousWeeksBillableHoursForContact(List<Id> entryList){


    }

    public static void linkTimeEntryToProjectRoleRecord(List<Replicon_Time_Entry__c> billableEntryList, Boolean needsUpdate, Boolean forNonLevEmployees){
        /**
         * Purpose: Match Time Entries to Project Role records via matching Associated_Billing_Rate__c name to the Project Role Name, and Rates  
         */
        /*System.debug('linkTimeEntryToProjectRoleRecord');

        /********************************** Loop through entries to get Ids of Projects and Billing Rates **********************************/
        List<Id> relatedProjectIdList = new List<Id>();
        List<Id> relatedBillingRateIdList = new List<Id>();
        List<Replicon_Time_Entry__c> entriesToProcessList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : billableEntryList){
            if(entry.Associated_Billing_Rate__c != null && entry.Project__c != null){
                relatedProjectIdList.add(entry.Project__c);
                relatedBillingRateIdList.add(entry.Associated_Billing_Rate__c);
                entriesToProcessList.add(entry);
            }
        }

        /********************************** Query the Existing Project Roles on the Projects related to the incoming Time Entries **********************************/
        List<ProjectRole__c> relatedProjectRoleRecordsList = new List<ProjectRole__c>();
        if(forNonLevEmployees){
        relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c, Resource_Delivery_Group__c
                                            FROM ProjectRole__c
                                            WHERE Project__c IN :relatedProjectIdList AND Resource_Delivery_Group__c IN ('ATG')];
        }else{
            relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c, Resource_Delivery_Group__c
                                            FROM ProjectRole__c
                                            WHERE Project__c IN :relatedProjectIdList AND Resource_Delivery_Group__c IN ('Lev')];
        }
        /*relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Project__r.Name, Product__c, Product__r.Name, Total_Amount_Billed__c, Total_Hours_Billed__c, Rate__c
                                            FROM ProjectRole__c
                                            WHERE Project__c IN :relatedProjectIdList];*/

        Map<Id, Map<String, ProjectRole__c>> projectIdToProjectRoleMap = new Map<Id, Map<String, ProjectRole__c>>(); //Map to store the Project Id --> Map with Project Role Name --> Project Role Record
        Map<String, Set<Integer>> projIdAndProjRoleNameToDuplicateCountMap = new Map<String, Set<Integer>>(); //Map to store the Project Id + Project Role Name as a Unique Key

        /********************************** Loop through the existing Project Roles to set the above Maps **********************************/
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

        /********************************** Query Existing Project Team Member Billing Rates related to the incoming Time Entries to get the existing and Billing Rates Ids, Name, Rates **********************************/
        List<Project_Team_Member_Billing_Rate__c> relatedBillingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        relatedBillingRateList = [SELECT Id, Name, Hourly_Rate__c, Project__c
                                    FROM Project_Team_Member_Billing_Rate__c
                                    WHERE Id IN :relatedBillingRateIdList];

        /********************************** Loop through Project Team Member Billing Rates related to the incoming Time Entries to set Map of Billing Rate Id to the Record **********************************/
        Map<Id, Project_Team_Member_Billing_Rate__c> billingRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c billRate : relatedBillingRateList){
            billingRateIdToRecordMap.put(billRate.Id, billRate);
        }

        /********************************** Loop through the Incoming Billable Time Entries to assign the appropriate Project Role Record **********************************/
        List<Replicon_Time_Entry__c> entriesToUpdateWithProjectRolesList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entriesToProcessList){
            if(entry.Associated_Billing_Rate__c != null && entry.Project__c != null){
                if(billingRateIdToRecordMap.containsKey(entry.Associated_Billing_Rate__c)){ //Look for Project Team Member Billing Rate
                    String billingRateName = billingRateIdToRecordMap.get(entry.Associated_Billing_Rate__c).Name; //Set the billingRateName as the related Project Team Member Billing Rate Name

                    if(projectIdToProjectRoleMap.containsKey(entry.Project__c)){
                        Map<String, ProjectRole__c> projectRoleNameToRecordMap = projectIdToProjectRoleMap.get(entry.Project__c); //Get Map of BillingRate Name to Project Role Record from the Project Id Map

                        /********************************** Look for exact match of Project Team Member Billing Rate name to Project Role Name **********************************/
                        if(projectRoleNameToRecordMap.containsKey(billingRateName)){ 
                            //If Billing Rate Name on the Time Entry matches exactly with a Name in the Map of Project Role Names then match the records
                            if(entry.ProjectRole__c != projectRoleNameToRecordMap.get(billingRateName).Id){
                                entry.ProjectRole__c = projectRoleNameToRecordMap.get(billingRateName).Id;
                                entriesToUpdateWithProjectRolesList.add(entry);
                            }
                        /********************************** If no exact match of Project Team Member Billing Rate name to Project Role Name then look to see if there is a similar one with same base name but a different trailing number **********************************/
                        }else{ 
                            //We check to see if it has numbers to attempt to match the Billing Rate to a similar Rate that possibly has a different number
                            Integer billRateTrailingNumber = billingRateName.normalizeSpace().substringAfterLast(' ').isNumeric() ? Integer.valueOf(billingRateName.normalizeSpace().substringAfterLast(' ')) : 0; //Get the trailing if there is one
                            String baseBillingRateName = billRateTrailingNumber == 0 ? billingRateName.normalizeSpace() : billingRateName.normalizeSpace().substringBeforeLast(' '); //Get the base Bill Rate name with no Trailing number if there is one
                            String projIdAndProjRoleNameUniqueId = String.valueOf(entry.Project__c) + '-' + baseBillingRateName;

                            if(projIdAndProjRoleNameToDuplicateCountMap.containsKey(projIdAndProjRoleNameUniqueId)){ //If the base name of the billing rate is in the map then look for other Project Role records that might match this Billing Rate
                                Set<Integer> projectRoleTrailingNumbersSet = projIdAndProjRoleNameToDuplicateCountMap.get(projIdAndProjRoleNameUniqueId);
                                //If the bill rate trailing number is already in the set then remove because we don't need to check if that has a match since we already did
                                if(projectRoleTrailingNumbersSet.contains(billRateTrailingNumber)){
                                    projectRoleTrailingNumbersSet.remove(billRateTrailingNumber);
                                }
                                //Loop through the trailing numbers set and attempt to find a matching Project Role Name and ensure that the rates match as well.
                                Boolean foundMatch = false; //Boolean to ensure that the entry doesn't get updated twice
                                ProjectRole__c potentialMatch = new ProjectRole__c();
                                for(Integer i : projectRoleTrailingNumbersSet){
                                    String billRateName;
                                    if(i == 0){
                                        billRateName = baseBillingRateName;
                                    }else{
                                        billRateName = baseBillingRateName + ' ' + String.valueOf(i);
                                    }
                                    if(!foundMatch && projectRoleNameToRecordMap.containsKey(billRateName)){
                                        //If the Name has a match, we then check to see if the rates align before assigning it to the entry record.
                                        if(projectRoleNameToRecordMap.get(billRateName).Rate__c == billingRateIdToRecordMap.get(entry.Associated_Billing_Rate__c).Hourly_Rate__c){
                                            if(entry.ProjectRole__c != projectRoleNameToRecordMap.get(billRateName).Id){
                                                entry.ProjectRole__c = projectRoleNameToRecordMap.get(billRateName).Id;
                                                entriesToUpdateWithProjectRolesList.add(entry);
                                                foundMatch = true;
                                            }
                                        }else{
                                            //If the rate is not an exact match, store it as a potential match
                                            if(potentialMatch.Id == null){
                                                potentialMatch = projectRoleNameToRecordMap.get(billRateName);
                                            }else{
                                                //If second rate comes in thats not a perfect match, compare the difference of the Project Team Member Billing Rate - Project Role Rate and see which is closer to get the potential match
                                                Decimal billRateToProjRateDiffold = Math.abs(billingRateIdToRecordMap.get(entry.Associated_Billing_Rate__c).Hourly_Rate__c - potentialMatch.Rate__c);
                                                Decimal billRateToProjRateDiffnew = Math.abs(billingRateIdToRecordMap.get(entry.Associated_Billing_Rate__c).Hourly_Rate__c - projectRoleNameToRecordMap.get(billRateName).Rate__c);
                                                if(billRateToProjRateDiffnew < billRateToProjRateDiffold){
                                                    potentialMatch = projectRoleNameToRecordMap.get(billRateName);
                                                }
                                            }
                                        }
                                    }                                    
                                }

                                //If no exact match was found, populate the Project Role field with the closest match
                                if(!foundMatch && potentialMatch.Id != null){
                                    if(entry.ProjectRole__c != potentialMatch.Id){
                                        entry.ProjectRole__c = potentialMatch.Id;
                                        entriesToUpdateWithProjectRolesList.add(entry);
                                        foundMatch = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        /********************************** Only update the Time Entry List if the needsUpdate parameter = true **********************************/
        //This is because this method is called on the Before Insert/Update triggers and no update statement is needed there, but Batch runs use this to update existing Time Entry records)
        if(needsUpdate && entriesToUpdateWithProjectRolesList.size() > 0){
            System.debug('***************** Number of Time Entries being updated with Project Role Lookups: ' + entriesToUpdateWithProjectRolesList.size() + ' *****************');
            update entriesToUpdateWithProjectRolesList;
        }
    }

    public static void calculateProjectRoleRollups(List<Replicon_Time_Entry__c> entryList){
        /**
         * Purpose: Rollup the Total_Amount_Billed__c and Total_Hours_Billed__c on the related Project Role Records
         * 
         * Functionality:
         *  1.) Get List of all the Related Project Role Record Ids
         *  2.) Aggregate Query the Hours and Billable Amounts of all related Project Roles
         *  3.) Put the aggregate Hours and Amounts into a map with the Project Role Id as the Key
         *  4.) Query the related Project Role records
         *  5.) Assign the Total Hours and Amount Billed to the records
         *  6.) Update the records if there is a change
         */

        Map<Id, ProjectRole__c> projectRoleIdToUpdateRecordMap = new Map<Id, ProjectRole__c>();  //Initialize Project Role Id to a Project Role record with initialized 0 Total Billed Hours and 0 Total Billed Amount
        for(Replicon_Time_Entry__c entry : entryList){
            if(entry.ProjectRole__c != null){
                ProjectRole__c updateProjectRoleRecord = new ProjectRole__c(Id = entry.ProjectRole__c, Total_Hours_Billed__c = 0, Total_Amount_Billed__c = 0);
                projectRoleIdToUpdateRecordMap.put(updateProjectRoleRecord.Id, updateProjectRoleRecord);

            }
        }

        if(projectRoleIdToUpdateRecordMap.size() > 0){

            //Aggregate Query of Billable Hours and Billable Amount of all Time Entries that are related to the Project Role of the incoming Time Entries
            AggregateResult[] timeEntryAggregate = [SELECT sum(TotalHrs__c) billableHours, sum(Billable_Amount__c) billableAmount, ProjectRole__c
                                                    FROM Replicon_Time_Entry__c
                                                    WHERE ProjectRole__c IN :projectRoleIdToUpdateRecordMap.keySet() AND Is_Billable__c = true AND Billing_Rate__c > 0 AND Deleted_in_Replicon__c = false
                                                    GROUP BY ProjectRole__c];
                                     
            for(AggregateResult ar : timeEntryAggregate){
                Id projectRoleId;
                Decimal totalBillableHours;
                Decimal totalBillableAmount;

                projectRoleId = (Id)ar.get('ProjectRole__c');

                if(projectRoleIdToUpdateRecordMap.containsKey(projectRoleId)){
                    ProjectRole__c updateProjectRoleRecord = projectRoleIdToUpdateRecordMap.get(projectRoleId);

                    totalBillableHours = (Decimal)ar.get('billableHours') != null ? (Decimal)ar.get('billableHours') : 0;
                    totalBillableAmount = (Decimal)ar.get('billableAmount') != null ? (Decimal)ar.get('billableAmount') : 0;

                    updateProjectRoleRecord.Total_Hours_Billed__c = totalBillableHours;
                    updateProjectRoleRecord.Total_Amount_Billed__c = totalBillableAmount;

                    projectRoleIdToUpdateRecordMap.put(updateProjectRoleRecord.Id, updateProjectRoleRecord); //Put the Aggregated Hours and Amount into the update Project Rate that we will use to compare the new value and the existing value of that Project Rate
                }
            }

            List<ProjectRole__c> relatedProjectRoleRecordsList = new List<ProjectRole__c>();
            relatedProjectRoleRecordsList = [SELECT Id, Name, Project__c, Product__c, Total_Hours_Billed__c, Total_Amount_Billed__c
                                                FROM ProjectRole__c
                                                WHERE Id IN :projectRoleIdToUpdateRecordMap.keySet()];

            List<ProjectRole__c> projectRoleToUpdateList = new List<ProjectRole__c>();
            for(ProjectRole__c pr : relatedProjectRoleRecordsList){
                //Check Map with Update Record in it, then compare new values to Existing Values
                if(projectRoleIdToUpdateRecordMap.containsKey(pr.Id)){
                    ProjectRole__c newProjectRoleRollups = projectRoleIdToUpdateRecordMap.get(pr.Id);

                    //If values are different then add to the update list
                    if(pr.Total_Hours_Billed__c != newProjectRoleRollups.Total_Hours_Billed__c || pr.Total_Amount_Billed__c != newProjectRoleRollups.Total_Amount_Billed__c){
                        pr.Total_Hours_Billed__c = newProjectRoleRollups.Total_Hours_Billed__c;
                        pr.Total_Amount_Billed__c = newProjectRoleRollups.Total_Amount_Billed__c;
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



    public static void rollupPTOForecastHours(List<Replicon_Time_Entry__c> ptoEntryList){
        /**
         * Functionality: Rolls up the PTO time into Forecasted Hours on PTO Forecasts to populate the PTO Time Off on the related Forecast records.
         */

        List<Id> ptoForecastIdList = new List<Id>();
        for(Replicon_Time_Entry__c ptoEntry : ptoEntryList){
            ptoForecastIdList.add(ptoEntry.Replicon_Forecast__c);
        }

        if(ptoForecastIdList.size() > 0){

            AggregateResult[] ptoTimeOffEntryAgg = [SELECT sum(TotalHrs__c), Replicon_Forecast__c
                                                    FROM Replicon_Time_Entry__c
                                                    WHERE Time_Off__c = true AND Deleted_in_Replicon__c = false AND TotalHrs__c > 0 AND Replicon_Forecast__c IN :ptoForecastIdList
                                                    GROUP BY Replicon_Forecast__c];

            Map<Id, Decimal> forecastIdToHoursMap = new Map<Id, Decimal>();
            for(AggregateResult ar : ptoTimeOffEntryAgg){
                Decimal totalHours = (Decimal)ar.get('expr0');
                Id forecastId = (Id)ar.get('Replicon_Forecast__c');
                if(totalHours != null && forecastId != null){
                    forecastIdToHoursMap.put(forecastId, totalHours);
                }
            }

            for(Replicon_Time_Entry__c ptoEntry : ptoEntryList){
                if(!forecastIdToHoursMap.containsKey(ptoEntry.Replicon_Forecast__c)){
                    //If the Updated replicon Forecast does not have any active hours assigned to it then give it 0 Forecasted hours to account for PTO Entries that were marked as deleted and need the forecasted hours of their forecast reset to 0
                    forecastIdToHoursMap.put(ptoEntry.Replicon_Forecast__c, 0);

                }
            }

            List<RepliconForecast__c> ptoForecastList = new List<RepliconForecast__c>();
            ptoForecastList = [SELECT Id, Name, EstimatedHours__c
                                FROM RepliconForecast__c 
                                WHERE Id IN :forecastIdToHoursMap.keySet()];

            List<RepliconForecast__c> ptoForecastToUpdateList = new List<RepliconForecast__c>();
            for(RepliconForecast__c ptoForecast : ptoForecastList){
                if(forecastIdToHoursMap.containsKey(ptoForecast.Id)){
                    if(ptoForecast.EstimatedHours__c != forecastIdToHoursMap.get(ptoForecast.Id)){
                        ptoForecast.EstimatedHours__c = forecastIdToHoursMap.get(ptoForecast.Id); 
                        ptoForecastToUpdateList.add(ptoForecast);
                    }
                }
            }

            if(ptoForecastToUpdateList.size() > 0){
                System.debug('**************************** Updating Forecasted Hours on ' + ptoForecastToUpdateList.size() + ' PTO Forecasts *********************************');
                update ptoForecastToUpdateList;
            }
        }    
    
    }

    public static void rollupEmployeeQuarterlyAmountBilled(List<Replicon_Time_Entry__c> entryList){
        System.debug('%%%%%%%%%%%%%%%% rollupEmployeeQuarterlyAmountBilled');
        //Roll up the current Quarter's Billable Hours + Concession hours to the Employee
        /**
         * Functionality: 
         * As time entries come in we check to see if the time entry is for the current quarter 
         * If so then we calculate the sum of the Billable Or Concession hours for the current quarter (where entry date is >= to the first day of the quarter or > the first day of the next quarter)
         * Make a map of Employee Ids to BillableOrConcessionHours for the current quarter
         * Then query the related Employee and populate the Billable Hours This Quarter field
         */

        Date startOfCurrentQuarter = getStartDateOfQuarterFromDate(Date.today());
        Date startOfPreviousQuarter = startOfCurrentQuarter.addMonths(-3);
        Date startOfNextQuarter = startOfCurrentQuarter.addMonths(3);

        Map<Id, Contact> employeeIdToUpdateContactMap = new Map<Id, Contact>();

        for(Replicon_Time_Entry__c entry : entryList){

            //If time entry is in previous or current quarter then add employee id to list to recalculate current and previous quarter hours billed
            if((entry.EntryDate__c >= startOfPreviousQuarter && entry.EntryDate__c < startOfNextQuarter) && entry.Employee__c != null){ 
                if(!employeeIdToUpdateContactMap.containsKey(entry.Employee__c)){
                    Contact updateContact = new Contact(Id = entry.Employee__c, Billed_Hours_this_Quarter__c = 0, Billed_Hours_Last_Quarter__c = 0);
                    employeeIdToUpdateContactMap.put(updateContact.Id, updateContact);
                }
            }
        }

        if(employeeIdToUpdateContactMap.size() > 0){
            List<Replicon_Time_Entry__c> currentOrPreviousQuarterEntryList = [SELECT Id, Name, EntryDate__c, TotalHrs__c, Employee__c, Employee__r.Billed_Hours_this_Quarter__c, Employee__r.Billed_Hours_Last_Quarter__c
                                                                                FROM Replicon_Time_Entry__c
                                                                                WHERE Employee__c IN :employeeIdToUpdateContactMap.keySet() AND TotalHrs__c != 0 AND TotalHrs__c != null AND (EntryDate__c >= :startOfPreviousQuarter AND EntryDate__c < :startOfNextQuarter)
                                                                                    AND Associated_Billing_Rate__c != null AND Deleted_in_Replicon__c = false AND Time_Off__c = false 
                                                                                ORDER BY Employee__c];

            for(Replicon_Time_Entry__c entry : currentOrPreviousQuarterEntryList){

                if(entry.EntryDate__c >= startOfCurrentQuarter && entry.EntryDate__c < startOfNextQuarter){
                    //Rollup amount for Current Quarter Billable Hours
                    if(employeeIdToUpdateContactMap.containsKey(entry.Employee__c)){
                        Contact updateContact = employeeIdToUpdateContactMap.get(entry.Employee__c);
                        if(entry.TotalHrs__c != null){
                            updateContact.Billed_Hours_this_Quarter__c += entry.TotalHrs__c;
                        }
                        employeeIdToUpdateContactMap.put(updateContact.Id, updateContact);
                    }


                }else if(entry.EntryDate__c >= startOfPreviousQuarter && entry.EntryDate__c < startOfCurrentQuarter){
                    //Rollup amount for Last Quarters Billable Hours
                    if(employeeIdToUpdateContactMap.containsKey(entry.Employee__c)){
                        Contact updateContact = employeeIdToUpdateContactMap.get(entry.Employee__c);
                        if(entry.TotalHrs__c != null){
                            updateContact.Billed_Hours_Last_Quarter__c += entry.TotalHrs__c;
                        }
                        employeeIdToUpdateContactMap.put(updateContact.Id, updateContact);
                    }
                }
            }

            List<Contact> relatedContactList = new List<Contact>();
            relatedContactList = [SELECT Id, Name, Billed_Hours_this_Quarter__c, Billed_Hours_Last_Quarter__c
                                    FROM Contact
                                    WHERE Id IN :employeeIdToUpdateContactMap.keySet() AND RecordType.Name = 'Employee'];

            List<Contact> contactUpdateList = new List<Contact>();
            for(Contact existingContact : relatedContactList){
                if(employeeIdToUpdateContactMap.containsKey(existingContact.Id)){
                    Contact updateContact = employeeIdToUpdateContactMap.get(existingContact.Id);
                    if(existingContact.Billed_Hours_this_Quarter__c != updateContact.Billed_Hours_this_Quarter__c || existingContact.Billed_Hours_Last_Quarter__c != updateContact.Billed_Hours_Last_Quarter__c){
                        existingContact.Billed_Hours_this_Quarter__c = updateContact.Billed_Hours_this_Quarter__c;
                        existingContact.Billed_Hours_Last_Quarter__c = updateContact.Billed_Hours_Last_Quarter__c;
                        contactUpdateList.add(existingContact);
                    }
                }
            }

            if(contactUpdateList.size() > 0){
                System.debug('******************************************** Updating Billed Hours this/last Quarter for ' + contactUpdateList.size() + ' Contact Records ********************************************');
                update contactUpdateList;
            }
        }
    }

    private static Date getStartDateOfQuarterFromDate(Date d){
        
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

    public static void linkEntryToNonBillOrConcessionCase(List<Replicon_Time_Entry__c> nonBillEntryList){
        //This method will be passed Time Entry records that:
        // 1.) Are marked as non-bill (Is_Billable__c = false OR Associated_Billing_Rate__c = null since this should be a before Insert process) OR
        // 2.) Are Concession Entries (TBD on determining if the time entries are Concession)
        // AND
        // 3.) Has a comment with Case prefix Record Id of '5006T' in it anywhere in the comments field.

        //Functionality
        // 1.) Loop through the Cases get their Case Id in the comments by looking for the '5006T' and getting its connected characters excluding any exclamation.
        // 2.) Don't add the Case Id from the Comment to the list if the Time Entry already has the RelatedNonbillOrConcessionCase__c as that Id

        List<Id> caseIdsToRollupList = new List<Id>();
        Map<String, List<Replicon_Time_Entry__c>> caseIdToEntryMap = new Map<String, List<Replicon_Time_Entry__c>>();
        for(Replicon_Time_Entry__c entry : nonBillEntryList){

            if(entry.Comments__c != null && (entry.Comments__c).contains('500') &&  entry.ActivityName__c != 'BCP'){ //Check if the Entry has comments and if 
                String caseIdInComments = (entry.Comments__c).substring((entry.Comments__c).indexOf('500'), (entry.Comments__c).indexOf('500') + 15);
                //Check if Entry already has this as the related Nonbill Case, if so then don't update, if not then assign the Id to the field
                if(caseIdInComments.containsNone(' ')){
                    if(entry.RelatedNonbillOrConcessionCase__c != caseIdInComments){
                        try{
                            //System.debug('Nonbill Case: ' + caseIdInComments);
                            //entry.RelatedNonbillOrConcessionCase__c = caseId;

                            if(caseIdToEntryMap.containsKey(caseIdInComments)){
                                List<Replicon_Time_Entry__c> entryList = caseIdToEntryMap.get(caseIdInComments);
                                entryList.add(entry);
                                caseIdToEntryMap.put(caseIdInComments, entryList);
                            }else{
                                List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
                                entryList.add(entry);
                                caseIdToEntryMap.put(caseIdInComments, entryList);
                            }

                        }catch(Exception e){
                            System.debug('Failed to link Case Id to Time Entry Record');
                        }
                    }
                }
            }else{
                if(entry.RelatedNonbillOrConcessionCase__c != null){
                    entry.RelatedNonbillOrConcessionCase__c = null;
                }
            }
        }

        if(caseIdToEntryMap.size() > 0){
            List<Case> nonbillConcessionCaseList = new List<Case>();
            nonbillConcessionCaseList = [SELECT Id, Subject, RecordType.Name FROM Case WHERE Id IN :caseIdToEntryMap.keySet()];
            for(Case c : nonbillConcessionCaseList){
                String shortenedCaseId = ((String)c.Id).substring(0,15);
                if(caseIdToEntryMap.containsKey(shortenedCaseId)){
                    for(Replicon_Time_Entry__c entry : caseIdToEntryMap.get(shortenedCaseId)){
                        entry.RelatedNonbillOrConcessionCase__c = c.Id;
                    }
                }
            }
        }
    }

    public static void rollupNonBillOrConcessionHoursOnCase(List<Replicon_Time_Entry__c> nonBillEntryList){
        //Rollup the Nonbill Case Hours Logged and Concession Case Hours Logged for any Cases that 

        List<Case> updateCaseList = new List<Case>();

        Map<Id, Case> relatedCaseIdToRollupCaseMap = new Map<Id, Case>();
        for(Replicon_Time_Entry__c entry : nonBillEntryList){

            if(entry.RelatedNonbillOrConcessionCase__c != null && !relatedCaseIdToRollupCaseMap.containsKey(entry.RelatedNonbillOrConcessionCase__c)){

                Case newRollupCase = new Case(Id = entry.RelatedNonbillOrConcessionCase__c, ConcessionCaseHoursLogged__c = 0, NonbillCaseHoursLogged__c = 0);
                relatedCaseIdToRollupCaseMap.put(entry.RelatedNonbillOrConcessionCase__c, newRollupCase);
            }
        }

        if(relatedCaseIdToRollupCaseMap.size() > 0){
            //5/19/2023 Horizon Update - Changed Replicon_Billing_Rate_URI__c to Associated Billing Rate 
            AggregateResult[] nonbillOrConcessionCaseRollup = [SELECT SUM(TotalHrs__c), RelatedNonbillOrConcessionCase__c, Associated_Billing_Rate__c
                                                                FROM Replicon_Time_Entry__c
                                                                WHERE RelatedNonbillOrConcessionCase__c IN :relatedCaseIdToRollupCaseMap.keySet() AND Deleted_in_Replicon__c = false AND TotalHrs__c != 0 AND ActivityName__c != 'BCP'
                                                                GROUP BY RelatedNonbillOrConcessionCase__c, Associated_Billing_Rate__c];

            //Loop through Aggregates and assign roll up hours to the rollup case map
            for(AggregateResult ar : nonbillOrConcessionCaseRollup){

                Id nonbillCaseId = (Id)ar.get('RelatedNonbillOrConcessionCase__c');
                if(relatedCaseIdToRollupCaseMap.containsKey(nonbillCaseId)){
                    Case rollupCase = relatedCaseIdToRollupCaseMap.get(nonbillCaseId);

                    String billRate = (String)ar.get('Associated_Billing_Rate__c');
                    if(billRate == null){
                        //If Billing Rate is null then it should be rolled up to NonbillCaseHoursLogged__c
                        rollupCase.NonbillCaseHoursLogged__c = (Decimal)ar.get('expr0') != null ?  (Decimal)ar.get('expr0') : 0;
                        
                    }else{
                        //Otherwise it is concession and should rollup to ConcessionCaseHoursLogged__c
                        rollupCase.ConcessionCaseHoursLogged__c = (Decimal)ar.get('expr0') != null ?  (Decimal)ar.get('expr0') : 0;
                    }

                    relatedCaseIdToRollupCaseMap.put(rollupCase.Id, rollupCase);
                }

            }

            //Query for Cases and check if Update is needed, if so then add to update list, if not then do nothing.
            List<Case> relatedNonBillOrConcessionCaseList = new List<Case>();
            relatedNonBillOrConcessionCaseList = [SELECT Id, Subject, ConcessionCaseHoursLogged__c, NonbillCaseHoursLogged__c
                                                    FROM Case
                                                    WHERE Id IN :relatedCaseIdToRollupCaseMap.keySet()];

            for(Case c : relatedNonBillOrConcessionCaseList){

                if(relatedCaseIdToRollupCaseMap.containsKey(c.Id)){
                    Case rollupCase = relatedCaseIdToRollupCaseMap.get(c.Id);
                    if(c.ConcessionCaseHoursLogged__c != rollupCase.ConcessionCaseHoursLogged__c || c.NonbillCaseHoursLogged__c != rollupCase.NonbillCaseHoursLogged__c){
                        c.ConcessionCaseHoursLogged__c = rollupCase.ConcessionCaseHoursLogged__c;
                        c.NonbillCaseHoursLogged__c = rollupCase.NonbillCaseHoursLogged__c;
                        updateCaseList.add(c);
                    }

                }
            }

        }

        if(updateCaseList.size() > 0){
            System.debug('******************************************** Updating ' + updateCaseList.size() + ' Nonbill Hours Logged ********************************************');
            update updateCaseList;
        }

    }

    public static void rollupWorkDayValues(Set<Id> workDayIdSet){
        
    try{
        List<WorkDay__c> workDayUpdateList = new List<WorkDay__c>();
        Map<Id, WorkDay__c> workDayUpdateMap = new Map<Id, WorkDay__c>();
        Map<Id, Map<Id, Replicon_Time_Entry__c>> workDayIdToRelatedEntriesListMap = new Map<Id, Map<Id, Replicon_Time_Entry__c>>();
        Map<Id, WorkDay__c> workdayIdToExistingWorkDayDetailsMap = new Map<Id, WorkDay__c>();

        for(Id workDayId : workDayIdSet) {

            workDayIdToRelatedEntriesListMap.put(workDayId, new Map<Id, Replicon_Time_Entry__c>()); 

            WorkDay__c updateWorkDay = new WorkDay__c(Id = workDayId, TotalBillableHours__c = 0, TotalInternalNonbillHours__c = 0, TotalProjectNonbillHours__c = 0, TotalInternalConcessionHours__c = 0,
                                                            TotalProjectConcessionHours__c = 0, TotalTimeOffHours__c = 0, TotalLOAHours__c = 0);
            workdayIdToExistingWorkDayDetailsMap.put(workDayId, updateWorkDay);
        }
        
        if(workDayIdToRelatedEntriesListMap.keyset().size() > 0) {
            List<Replicon_Time_Entry__c> relatedTimeEntryList = [SELECT Id, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Billing_Rate__c, Billable_Amount__c, Replicon_Billing_Rate_URI__c, Override_Billing_Rate__c, TotalHrs__c, Time_Off__c, Deleted_in_Replicon__c, Time_Off_Description__c,
                                                                        Project__c, Project__r.Name, Project__r.RepliconURI__c, Project__r.Peoplesoft_Project_Id__c, Project__r.Account__c, Project__r.Account__r.Name, WorkDay__c, WorkDay__r.TotalBillableHours__c, Replicon_Project_URI__c,
                                                                        WorkDay__r.TotalInternalConcessionHours__c, WorkDay__r.TotalInternalNonbillHours__c, WorkDay__r.TotalProjectNonbillHours__c, WorkDay__r.TotalProjectConcessionHours__c, WorkDay__r.TotalTimeOffHours__c, WorkDay__r.TotalLOAHours__c,
                                                                        Is_Concession__c
                                                                    FROM Replicon_Time_Entry__c 
                                                                    WHERE WorkDay__c IN :workDayIdToRelatedEntriesListMap.keyset() AND Deleted_in_Replicon__c = false];

            for(Replicon_Time_Entry__c queriedTimeEntry : relatedTimeEntryList){
                Map<Id, Replicon_Time_Entry__c> timesheetTimeEntryMap = workDayIdToRelatedEntriesListMap.get(queriedTimeEntry.WorkDay__c);
                timesheetTimeEntryMap.put(queriedTimeEntry.Id, queriedTimeEntry);
                workDayIdToRelatedEntriesListMap.put(queriedTimeEntry.WorkDay__c, timesheetTimeEntryMap); 

                Decimal existingBillableHours = queriedTimeEntry.WorkDay__r.TotalBillableHours__c != null ? queriedTimeEntry.WorkDay__r.TotalBillableHours__c : 0;
                Decimal existingInternalConcessionHours = queriedTimeEntry.WorkDay__r.TotalInternalConcessionHours__c != null ? queriedTimeEntry.WorkDay__r.TotalInternalConcessionHours__c : 0;
                Decimal existingProjectConcessionHours = queriedTimeEntry.WorkDay__r.TotalProjectConcessionHours__c != null ? queriedTimeEntry.WorkDay__r.TotalProjectConcessionHours__c : 0;
                Decimal existingInternalNonbillHours = queriedTimeEntry.WorkDay__r.TotalInternalNonbillHours__c != null ? queriedTimeEntry.WorkDay__r.TotalInternalNonbillHours__c : 0;
                Decimal existingProjectNonbillHours = queriedTimeEntry.WorkDay__r.TotalInternalNonbillHours__c != null ? queriedTimeEntry.WorkDay__r.TotalInternalNonbillHours__c : 0;
                Decimal existingTimeOffHours = queriedTimeEntry.WorkDay__r.TotalTimeOffHours__c != null ? queriedTimeEntry.WorkDay__r.TotalTimeOffHours__c : 0;
                Decimal existingLOAHours = queriedTimeEntry.WorkDay__r.TotalLOAHours__c != null ? queriedTimeEntry.WorkDay__r.TotalLOAHours__c : 0;

                WorkDay__c updateWorkDay = new WorkDay__c(Id = queriedTimeEntry.WorkDay__c, TotalBillableHours__c = existingBillableHours, TotalInternalConcessionHours__c = existingInternalConcessionHours, TotalInternalNonbillHours__c = existingInternalNonbillHours, 
                                                            TotalProjectNonbillHours__c = existingProjectNonbillHours, TotalProjectConcessionHours__c = existingProjectConcessionHours, TotalTimeOffHours__c = existingTimeOffHours, TotalLOAHours__c = existingLOAHours);

                workdayIdToExistingWorkDayDetailsMap.put(updateWorkDay.Id, updateWorkDay);
                workDayIdSet.remove(updateWorkDay.Id);

            }

            if(workDayIdSet.size() > 0){

                List<WorkDay__c> workDaysWithNoEntriesList = new List<WorkDay__c>();
                workDaysWithNoEntriesList = [SELECT Id, Name, TotalBillableHours__c, TotalInternalConcessionHours__c, TotalInternalNonbillHours__c, TotalProjectNonbillHours__c, TotalProjectConcessionHours__c, TotalTimeOffHours__c, TotalLOAHours__c
                                                FROM WorkDay__c
                                                WHERE Id IN :workDayIdSet];

                for(WorkDay__c wd : workDaysWithNoEntriesList){
                    workdayIdToExistingWorkDayDetailsMap.put(wd.Id, wd);
                }
            }
        }

        //Loop through structure to calculate rollup values
        for(Id workDayId : workDayIdToRelatedEntriesListMap.keyset()) {
            
            //New Rollup Calculation Step 1 - Declaration
            Decimal rollupTotalWorkingHours = 8; //8 Hours
            Decimal rollupTotalBillableHours = 0;
            Decimal rollupTotalInternalNonBillHours = 0;
            Decimal rollupTotalProjectNonBillHours = 0;
            Decimal rollupTotalProjectConcessionHours = 0;
            Decimal rollupTotalInternalConcessionHours = 0;
            Decimal rollupTotalTimeOffHours = 0;
            Decimal rollupTotalLOAHours = 0;
            
            for(Id timeEntryId : workDayIdToRelatedEntriesListMap.get(workDayId).keyset()) {
                Replicon_Time_Entry__c currentEntry = workDayIdToRelatedEntriesListMap.get(workDayId).get(timeEntryId);
                
                if(currentEntry.Deleted_in_Replicon__c != true && currentEntry.TotalHrs__c != null){
                    //New Rollup Calculation Step 2 - Criteria
                    if(currentEntry.Time_Off__c) {
                        /**Check if TIme Off is LOA ***/
                        if(currentEntry.Time_Off_Description__c == 'LOA'){
                            rollupTotalLOAHours += currentEntry.TotalHrs__c;
                        }
                        rollupTotalTimeOffHours += currentEntry.TotalHrs__c;

                    }else if((currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL) && currentEntry.Billing_Rate__c > 0) {
                        rollupTotalBillableHours += currentEntry.TotalHrs__c;

                    }else if(currentEntry.Override_Billing_Rate__c != NULL || currentEntry.Associated_Billing_Rate__c != NULL || currentEntry.Replicon_Project_URI__c == 'urn:replicon-tenant:levementum:project:3689' || currentEntry.Project__r.Name == 'Internal Concession' || currentEntry.Is_Concession__c == true) {

                        //if(currentEntry.Project__r.RepliconURI__c == 'urn:replicon-tenant:levementum:project:3689'){
                        //Horizon Update 5/19/2023 - Changed from referencing the Project URI to the Project Name
                        if(currentEntry.Project__r.RepliconURI__c == 'urn:replicon-tenant:levementum:project:3689' || currentEntry.Project__r.Name == 'Internal Concession'){ //If the Concession Time is logged on the Internal Concession Project, then it is internal Concession. If not then it is project Concession
                            rollupTotalInternalConcessionHours += currentEntry.TotalHrs__c;
                        }else{
                            rollupTotalProjectConcessionHours += currentEntry.TotalHrs__c;
                        }

                    }else{
                        //Differentiate between internal and project non bill hours
                        if(currentEntry.Project__c == null || (currentEntry.Project__r.Account__c != null && currentEntry.Project__r.Account__r.Name != null && currentEntry.Project__r.Account__r.Name == 'Levementum LLC')){
                            rollupTotalInternalNonBillHours += currentEntry.TotalHrs__c;
                        }else{
                            rollupTotalProjectNonBillHours += currentEntry.TotalHrs__c;
                        }
                    }
                }
            }

            //Compare Work Day Rollups to existing Work Day Details to determine if the Work Day needs to be updated or not.
            if(workdayIdToExistingWorkDayDetailsMap.containsKey(workDayId)){
                WorkDay__c existingWorkDay = workdayIdToExistingWorkDayDetailsMap.get(workDayId);

                if(existingWorkDay.TotalBillableHours__c != rollupTotalBillableHours || existingWorkDay.TotalInternalConcessionHours__c != rollupTotalInternalConcessionHours || existingWorkDay.TotalInternalNonbillHours__c != rollupTotalInternalNonBillHours ||
                    existingWorkDay.TotalProjectConcessionHours__c != rollupTotalProjectConcessionHours || existingWorkDay.TotalTimeOffHours__c != rollupTotalTimeOffHours || existingWorkDay.TotalProjectNonbillHours__c != rollupTotalProjectNonBillHours ||
                    existingWorkDay.TotalLOAHours__c != rollupTotalLOAHours){

                    WorkDay__c updateWorkDay = new WorkDay__c(Id = workDayId, TotalBillableHours__c = rollupTotalBillableHours, TotalInternalConcessionHours__c = rollupTotalInternalConcessionHours, TotalInternalNonbillHours__c = rollupTotalInternalNonBillHours,
                                                                TotalProjectNonbillHours__c = rollupTotalProjectNonBillHours, TotalProjectConcessionHours__c = rollupTotalProjectConcessionHours, TotalTimeOffHours__c = rollupTotalTimeOffHours, TotalLOAHours__c = rollupTotalLOAHours);

                    workDayUpdateMap.put(updateWorkDay.Id, updateWorkDay);
                }
            }
        }
        if(workDayUpdateMap.size() > 0) {
            System.debug('***************************** Updating ' + workDayUpdateMap.size() + ' Work Day Roll-ups *****************************');
            update workDayUpdateMap.values();
        }

    }catch(Exception e){
        System.debug('Error in calculating rollup values for Working Days');
        System.debug('Error Exception Message: ' + e.getMessage());
        System.debug('Error Exception Line #: ' + e.getLineNumber());
        System.debug('Error Exception: ' + e);
        Error_Log_Lev__c newErrorLog = new Error_Log_Lev__c();
        newErrorLog.Error_Message__c = e.getMessage() + '    *****Work Day Id Set: ' + workDayIdSet;
        newErrorLog.Line_Number__c = e.getLineNumber();
        newErrorLog.Method_Name__c = 'rollupWorkDayValues';
        newErrorLog.Class_Name__c = 'RepliconTimeEntryTriggerHelper';
        insert newErrorLog;
        System.debug('*************Unexpected Error*************');
        System.debug(newErrorLog);
    }

    }

}