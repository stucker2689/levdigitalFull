/**
 * Created on 5/20/2022 ST
 * 
 * Purpose: To calculate the Remaining Forecasted Hours and Revenue on the Project Role records
 *          To be scheduled to run each monday to calculate when the Week Passes so if a project role has no forecasts that have been updated in the current week it will exclude the forecasts that have passed for the REMAINING Forecasted Hours/Revenue fields on Project Role
 * 
 * To run this on a scheduled basis: 
ProjectRoleRemainingForecastsBatch newBatchRun = new ProjectRoleRemainingForecastsBatch();
System.schedule('Project Role Remaining Forecast Batch Run', '0 35 7 ? * MON', newBatchRun);
 * 
 */

public with sharing class ProjectRoleRemainingForecastsBatch implements Database.Batchable<sObject>, Schedulable{

    public final String QueryString;

    public void execute(SchedulableContext sc) {
        ProjectRoleRemainingForecastsBatch batch = new ProjectRoleRemainingForecastsBatch();
        Database.executeBatch(batch, 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('ProjectRoleRemainingForecastsBatch START');
        String QueryString = 'SELECT Id, Name, Project__c, Product__c, Forecasted_Hours__c, Forecasted_Revenue__c, Remaining_Forecasted_Hours__c, Remaining_Forecasted_Revenue__c FROM ProjectRole__c' +
			                    ' ORDER BY Project__c';

        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<ProjectRole__c> projectRoleList){
        System.debug('ProjectRoleRemainingForecastsBatch EXECUTE with Batch Size: ' + projectRoleList.size());
        /**
         * Purpose: recalculate the remaining Forecasted Hours/Revenue on Projects Roles to account for Project Roles with no updated Forecasts and the week passes so old Forecasts need to be excluded from that calculation.
         * 
         * Functionality: 
         *  1.) Get Ids of incoming Project Roles
         *  2.) Aggregate Query EstimatedHours and EstimatedRevenue group by Project Role
         *  3.) Create Map of Project Role Id to Remaining Forecasted Hours/Revenue
         *  4.) If those fields changed then add to update list and update
         */

         Map<Id, ProjectRole__c> projectRoleIdToForecastSumsMap = new Map<Id, ProjectRole__c>();
         for(ProjectRole__c pr : projectRoleList){
            ProjectRole__c updateProjectRole = new ProjectRole__c(Id = pr.Id, Remaining_Forecasted_Hours__c = 0, Remaining_Forecasted_Revenue__c = 0);
            projectRoleIdToForecastSumsMap.put(pr.Id, updateProjectRole);
         }

         Date currentWeekStartDate = Date.today().toStartOfWeek();

         AggregateResult[] projectRoleForecastAggregate = [SELECT SUM(EstimatedHours__c) forecastedHoursSum, SUM(EstimatedRevenue__c) forecastedRevenueSum, ProjectRole__c
                                                            FROM RepliconForecast__c
                                                            WHERE ProjectRole__c IN :projectRoleIdToForecastSumsMap.keySet() AND Deleted_in_Replicon__c = false AND EstimatedHours__c != 0 AND Week_End_Date__c > :currentWeekStartDate
                                                            GROUP BY ProjectRole__c];

        for(AggregateResult ar : projectRoleForecastAggregate){
            Id projectRoleId = (Id)ar.get('ProjectRole__c');

            if(projectRoleIdToForecastSumsMap.containsKey(projectRoleId)){
                
                Decimal remainingForecastedHours = (Decimal)ar.get('forecastedHoursSum') != null ? (Decimal)ar.get('forecastedHoursSum') : 0;
                Decimal remainingForecastedRevenue = (Decimal)ar.get('forecastedRevenueSum') != null ? (Decimal)ar.get('forecastedRevenueSum') : 0;

                ProjectRole__c updatedProjectRole = projectRoleIdToForecastSumsMap.get(projectRoleId);
                updatedProjectRole.Remaining_Forecasted_Hours__c = remainingForecastedHours;
                updatedProjectRole.Remaining_Forecasted_Revenue__c = remainingForecastedRevenue;
                projectRoleIdToForecastSumsMap.put(updatedProjectRole.Id, updatedProjectRole);
            }
        }

        List<ProjectRole__c> projectRolesToUpdateList = new List<ProjectRole__c>();
        for(ProjectRole__c pr : projectRoleList){
            if(projectRoleIdToForecastSumsMap.containsKey(pr.Id)){
                ProjectRole__c updatedProjectRole = projectRoleIdToForecastSumsMap.get(pr.Id);
                if(pr.Remaining_Forecasted_Hours__c != updatedProjectRole.Remaining_Forecasted_Hours__c || pr.Remaining_Forecasted_Revenue__c != updatedProjectRole.Remaining_Forecasted_Revenue__c ){ //If there is a change then add it to the update list, otherwise do nothing
                    pr.Remaining_Forecasted_Hours__c = updatedProjectRole.Remaining_Forecasted_Hours__c;
                    pr.Remaining_Forecasted_Revenue__c = updatedProjectRole.Remaining_Forecasted_Revenue__c;
                    projectRolesToUpdateList.add(pr);
                }
            }
        }
        

        if(projectRolesToUpdateList.size() > 0){
            System.debug('************************************************* ProjectRoleRemainingForecastsBatch - Project Roles Updating Size: ' + projectRolesToUpdateList.size() + ' *************************************************');
            update projectRolesToUpdateList;
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('ProjectRoleRemainingForecastsBatch FINISH');

    }
}