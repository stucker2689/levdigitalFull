public with sharing class RepliconForecastTriggerHandler {

    //List of Ids we don't want to rollup for or try to attach a Project Role to the Forecast
    private static List<Id> nonRollupProjectIdList = new List<Id>{'a1q6T000003v2K0QAI', 'a1q6T000003v4mFQAQ'}; //(Lev - Internal Placeholder, Lev - PTO)
    private static String atgContactId = '0030W00003n00V7QAI';

    public static void onBeforeInsert(List<RepliconForecast__c> newList){

        System.debug('*************************************************** RepliconForecastTriggerHandler Before Insert *********************************************************');

        List<RepliconForecast__c> checkForLevForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__C fore : newList){
            if(fore.Contact__c != null){
                checkForLevForecastList.add(fore);
            }
        }
        //Check if Forecast is Lev Employee or Not
        if(checkForLevForecastList.size() > 0){
            RepliconForecastTriggerHelper.checkIfLevForecast(checkForLevForecastList);
        }

        List<RepliconForecast__c> linkLevForecastToProjectRoleList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> linkNonLevForecastToProjectRoleList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> linkForecastToStaffingAssignmentList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> populateLookUpFieldsForecastList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> populateForecastTimesheetList = new List<RepliconForecast__c>();
        for(RepliconForecast__C fore : newList){
            if(fore.ProjectTeamMemberBillingRate__c != null && fore.Deleted_in_Replicon__c != true && fore.Project__c != null && (!nonRollupProjectIdList.contains(fore.Project__c)) ){
                //linkForecastToProjectRoleList.add(fore);
                if(fore.Is_Lev_Forecast__c){
                    System.debug('Before Insert Forecast Is Lev Forecast');
                    linkLevForecastToProjectRoleList.add(fore);
                }else{
                    linkNonLevForecastToProjectRoleList.add(fore);
                }

                linkForecastToStaffingAssignmentList.add(fore);
            }

            if(fore.Contact__c != null && fore.Week_Start_Date__c != null){
                populateForecastTimesheetList.add(fore);
            }

            if(fore.Internal_Project_Team_Member__c != null){
                populateLookUpFieldsForecastList.add(fore);
            }
        }

        //Link Forecast to a Project Role Record
        if(linkLevForecastToProjectRoleList.size() > 0){
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(linkLevForecastToProjectRoleList, false, false);
        }
        if(linkNonLevForecastToProjectRoleList.size() > 0){
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(linkNonLevForecastToProjectRoleList, false, true);
        }
        if(linkForecastToStaffingAssignmentList.size() > 0){
            RepliconForecastTriggerHelper.linkForecastsToStaffingAssignments(linkForecastToStaffingAssignmentList, false);
        }
        if(populateLookUpFieldsForecastList.size() > 0){//Horizon addition 6.13.2023 ST
            RepliconForecastTriggerHelper.populateForecastBillingRate(populateLookUpFieldsForecastList, false);
        }
        if(populateForecastTimesheetList.size() > 0){//Populate Timesheet on Forecasts - 8.2.2023 ST
            RepliconForecastTriggerHelper.populateForecastTimesheet(populateForecastTimesheetList, false);
        }
    }

    public static void onAfterInsert(List<RepliconForecast__c> newList){
        //If it has Estimated Revenue EstimatedRevenue__c then find the related Weekly Revenue Forecast and rollup the Weekly Forecast $

        List<RepliconForecast__c> insertedForecastsToRollupList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> insertedProjectForecastsToRollupList = new List<RepliconForecast__c>();
        List<Id> insertedProjectIdsToRollupList = new List<Id>(); //Added 7/29 ST
        List<RepliconForecast__c> insertedProjectRoleForecastsToRollupList = new List<RepliconForecast__c>();
        Set<Id> checkForKickOffPlaceholdersProjectIdSet = new Set<Id>();
        
        for(RepliconForecast__C fore : newList){
            if(fore.EstimatedRevenue__c > 0 && fore.Deleted_in_Replicon__c != true && (!nonRollupProjectIdList.contains(fore.Project__c))){
                insertedForecastsToRollupList.add(fore);
            }

            if(fore.Project__c != null && (fore.EstimatedRevenue__c != 0 || fore.EstimatedHours__c != 0) && (!nonRollupProjectIdList.contains(fore.Project__c))){
                insertedProjectForecastsToRollupList.add(fore);
                insertedProjectIdsToRollupList.add(fore.Project__c); //Added 7/29 ST
                insertedProjectRoleForecastsToRollupList.add(fore);
            }

            if(fore.Project__c != null && fore.EstimatedHours__c != 0 && fore.EstimatedHours__c != null && fore.NotForecasted__c == false && fore.Kickoff_Placeholder_Forecast__c == false){
                checkForKickOffPlaceholdersProjectIdSet.add(fore.Project__c);
            }


        }

        if(insertedForecastsToRollupList.size() > 0){
            //Rollup forecasts for the weeks the forecasts are related to
            RepliconForecastTriggerHelper.rollupForecastRevenueOnRevenueForecasts(insertedForecastsToRollupList);
        }

        if(insertedProjectForecastsToRollupList.size() > 0){
            if(System.isBatch()){
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(insertedProjectForecastsToRollupList);
            }else{
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(insertedProjectForecastsToRollupList);
                //RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjectsFuture(insertedProjectIdsToRollupList); //Commented out on 8.30.2023 ST
            }
        }

        if(insertedProjectRoleForecastsToRollupList.size() > 0){
            RepliconForecastTriggerHelper.calculateProjectRoleRollups(insertedProjectRoleForecastsToRollupList);
        }

        if(checkForKickOffPlaceholdersProjectIdSet.size() > 0){
            RepliconForecastTriggerHelper.checkForPlaceholdersToDelete(checkForKickOffPlaceholdersProjectIdSet);
        }
    }

    public static void onBeforeUpdate(List<RepliconForecast__c> newList, Map<Id, RepliconForecast__c> oldMap){

        System.debug('*************************************************** RepliconForecastTriggerHandler Before Update *********************************************************');

        List<RepliconForecast__c> checkForLevForecastList = new List<RepliconForecast__c>();
        for(RepliconForecast__C fore : newList){
            if(fore.Contact__c != null){
                checkForLevForecastList.add(fore);
            }
        }
        //Check if Forecast is Lev Employee or Not
        if(checkForLevForecastList.size() > 0){
            RepliconForecastTriggerHelper.checkIfLevForecast(checkForLevForecastList);
        }

        List<RepliconForecast__c> linkLevForecastToProjectRoleList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> linkNonLevForecastToProjectRoleList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> linkForecastToStaffingAssignmentList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> populateLookUpFieldsForecastList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> deletedForecastList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> populateForecastTimesheetList = new List<RepliconForecast__c>();
        for(RepliconForecast__C fore : newList){
            RepliconForecast__c oldForecast = oldMap.get(fore.Id);

            //If a Forecast is marked as deleted, then set the estimated hours and Bill Rate Avg to 0
            if(fore.Deleted_in_Replicon__c != oldForecast.Deleted_in_Replicon__c && fore.Deleted_in_Replicon__c == true && fore.EstimatedHours__c > 0 && fore.Kickoff_Placeholder_Forecast__c == false){
                fore.EstimatedHours__c = 0;
                fore.Bill_Rate_Avg__c = 0;
            }

            //If a deleted Forecast has its Estimated Hours change, then undelete the forecast
            if(fore.EstimatedHours__c != oldForecast.EstimatedHours__c && (oldForecast.EstimatedHours__c == 0 || oldForecast.EstimatedHours__c == null)  && fore.Deleted_in_Replicon__c == true){
                fore.Deleted_in_Replicon__c = false;
            }

            if(fore.Contact__c != oldForecast.Contact__c || fore.Week_Start_Date__c != oldForecast.Week_Start_Date__c){
                populateForecastTimesheetList.add(fore);
            }

            
            if((!nonRollupProjectIdList.contains(fore.Project__c)) && fore.Project__c != null && fore.ProjectTeamMemberBillingRate__c != null && fore.Deleted_in_Replicon__c == false &&
                ((fore.Deleted_in_Replicon__c != oldForecast.Deleted_in_Replicon__c) || (fore.ProjectTeamMemberBillingRate__c != oldForecast.ProjectTeamMemberBillingRate__c) || (fore.Project__c != oldForecast.Project__c))){

                if(fore.Is_Lev_Forecast__c){
                    linkLevForecastToProjectRoleList.add(fore);
                }else{
                    linkNonLevForecastToProjectRoleList.add(fore);
                }

                linkForecastToStaffingAssignmentList.add(fore);
            }
        }

        //Link Forecast to a Project Role Record
        if(linkLevForecastToProjectRoleList.size() > 0){
            //System.debug('Link Lev Forecast to Project Role');
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(linkLevForecastToProjectRoleList, false, false);
        }

        if(linkNonLevForecastToProjectRoleList.size() > 0){
            //System.debug('Link NON Lev Forecast to Project Role');
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(linkNonLevForecastToProjectRoleList, false, true);
        }

        if(linkForecastToStaffingAssignmentList.size() > 0){
            RepliconForecastTriggerHelper.linkForecastsToStaffingAssignments(linkForecastToStaffingAssignmentList, false);
        }

        if(populateForecastTimesheetList.size() > 0){//Populate Timesheet on Forecasts - 8.2.2023 ST
            RepliconForecastTriggerHelper.populateForecastTimesheet(populateForecastTimesheetList, false);
        }

    }

    public static void onAfterUpdate(List<RepliconForecast__c> newList, Map<Id, RepliconForecast__c> oldMap){

        //If it has Estimated Revenue EstimatedRevenue__c changed then find the related Weekly Revenue Forecast and rollup the Weekly Forecast $

        List<RepliconForecast__c> updatedForecastsToRollupList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> updatedProjectForecastsToRollupList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> forecastsToRollupProjectRolesList = new List<RepliconForecast__c>();
        List<Id> updatedProjectIdsToRollupList = new List<Id>(); //Added 7/29 ST
        for(RepliconForecast__C fore : newList){
            //If Estimated Revenue or Deleted in Replicon changes the re-rollup the Revenue Forecast related to that week
            //Or if Week_End_Date, ProjectTeamMemberBillingRate__c, EstimatedHours__c changes, 
            if(oldMap.containsKey(fore.Id) && (fore.EstimatedRevenue__c != oldMap.get(fore.Id).EstimatedRevenue__c || fore.Deleted_in_Replicon__c != oldMap.get(fore.Id).Deleted_in_Replicon__c
                || fore.Week_End_Date__c != oldMap.get(fore.Id).Week_End_Date__c || fore.ProjectTeamMemberBillingRate__c != oldMap.get(fore.Id).ProjectTeamMemberBillingRate__c || fore.EstimatedHours__c != oldMap.get(fore.Id).EstimatedHours__c)
                && (!nonRollupProjectIdList.contains(fore.Project__c))){

                updatedForecastsToRollupList.add(fore);
            }

            //Check to see if Forecast changed at all, if so then it needs to recalculate the remaining forecasted hours of the project
            if(oldMap.containsKey(fore.Id) && (fore.EstimatedRevenue__c != oldMap.get(fore.Id).EstimatedRevenue__c || fore.Deleted_in_Replicon__c != oldMap.get(fore.Id).Deleted_in_Replicon__c || fore.Week_Start_Date__c != oldMap.get(fore.Id).Week_Start_Date__c
                || fore.Week_End_Date__c != oldMap.get(fore.Id).Week_End_Date__c || fore.EstimatedHours__c != oldMap.get(fore.Id).EstimatedHours__c || fore.Project__c != oldMap.get(fore.Id).Project__c)
                && (!nonRollupProjectIdList.contains(fore.Project__c))){ 

                    updatedProjectForecastsToRollupList.add(fore);
                    updatedProjectIdsToRollupList.add(fore.Project__c);

                if(fore.Project__c != oldMap.get(fore.Id).Project__c && oldMap.get(fore.Id).Project__c != null){
                    //If Project of Forecast changes, then old forecast needs added to the list as well in order to update previous project.
                    updatedProjectForecastsToRollupList.add(oldMap.get(fore.Id));
                    updatedProjectIdsToRollupList.add(oldMap.get(fore.Id).Project__c);
                }
            }

            //Check to see if the Forecast record change results in the related Project Role record needing an update to the Forecasted Rollup fields on Project Role
            if(oldMap.containsKey(fore.Id) && ((fore.ProjectRole__c != oldMap.get(fore.Id).ProjectRole__c && fore.ProjectRole__c != null) || fore.EstimatedRevenue__c != oldMap.get(fore.Id).EstimatedRevenue__c 
                || fore.EstimatedHours__c != oldMap.get(fore.Id).EstimatedHours__c || fore.Deleted_in_Replicon__c != oldMap.get(fore.Id).Deleted_in_Replicon__c )
                && (!nonRollupProjectIdList.contains(fore.Project__c))){

                    forecastsToRollupProjectRolesList.add(fore);

                //If the Project Role changed on the Forecast then we need to add the old Forecast as well to update the Project Role rollups that were previously on that forecast
                if(fore.ProjectRole__c != oldMap.get(fore.Id).ProjectRole__c && oldMap.get(fore.Id).ProjectRole__c != null){
                    forecastsToRollupProjectRolesList.add(oldMap.get(fore.Id));
                }
            }
        }

        if(updatedForecastsToRollupList.size() > 0){
            //Rollup forecasts for the weeks the forecasts are related to
            RepliconForecastTriggerHelper.rollupForecastRevenueOnRevenueForecasts(updatedForecastsToRollupList);
        }

        if(updatedProjectForecastsToRollupList.size() > 0){
            if(System.isBatch()){
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(updatedProjectForecastsToRollupList);
            }else{
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(updatedProjectForecastsToRollupList);
                //RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjectsFuture(updatedProjectIdsToRollupList); //Commented out 8.30.2023 ST 
            }
        }

        if(forecastsToRollupProjectRolesList.size() > 0){
            RepliconForecastTriggerHelper.calculateProjectRoleRollups(forecastsToRollupProjectRolesList);
        }
    }

    public static void onAfterDelete(List<RepliconForecast__c> deletedForecastList){
        //Rollup fields on Revenue Forecasts and Projects when Forecast Records are deleted
        
        List<RepliconForecast__c> daletedForecastsToRollupList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> deletedProjectForecastsToRollupList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> forecastsToRollupProjectRolesList = new List<RepliconForecast__c>();
        List<Id> deletedProjectIdsToRollupList = new List<Id>(); //Added 7/29 ST
        for(RepliconForecast__C fore : deletedForecastList){
            if(fore.EstimatedRevenue__c > 0 && fore.Deleted_in_Replicon__c != true){
                daletedForecastsToRollupList.add(fore);
            }

            if(fore.Project__c != null && (fore.EstimatedRevenue__c != 0 || fore.EstimatedHours__c != 0)){
                deletedProjectForecastsToRollupList.add(fore);
                deletedProjectIdsToRollupList.add(fore.Project__c);
            }

            if(fore.Project__c != null && (fore.EstimatedRevenue__c != 0 || fore.EstimatedHours__c != 0) && fore.Deleted_in_Replicon__c == false){
                forecastsToRollupProjectRolesList.add(fore);
            }
        }

        if(daletedForecastsToRollupList.size() > 0){
            //Rollup forecasts for the weeks the forecasts are related to
            RepliconForecastTriggerHelper.rollupForecastRevenueOnRevenueForecasts(daletedForecastsToRollupList);
        }

        if(deletedProjectForecastsToRollupList.size() > 0){
            if(System.isBatch()){
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(deletedProjectForecastsToRollupList);
            }else{
                RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjects(deletedProjectForecastsToRollupList);
                //RepliconForecastTriggerHelper.rollupForecastsOnRelatedProjectsFuture(deletedProjectIdsToRollupList); //Commented out on 8.30.2023 ST
            }
        }

        if(forecastsToRollupProjectRolesList.size() > 0){
            RepliconForecastTriggerHelper.calculateProjectRoleRollups(forecastsToRollupProjectRolesList);
        }

    }
}