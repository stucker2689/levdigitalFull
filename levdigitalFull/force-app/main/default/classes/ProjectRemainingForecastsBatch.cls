/**
 * Created 5/9/2022 ST
 * 
 * Purpose: Rollup the remaining Forecasted Hours and Revenue
 * This is needed because if no forecast is updated or created on a project that is out of forecasts then the DLRS that calculates these fields does not get triggered and the remaining Forecasted fields on Project are not recalculated.
 * 
  * To run this on a scheduled basis: 
ProjectRemainingForecastsBatch newBatchRun = new ProjectRemainingForecastsBatch();
System.schedule('Project Remaining Forecast Batch Rollup', '0 35 3 ? * MON', newBatchRun);
 */

public with sharing class ProjectRemainingForecastsBatch implements Database.Batchable<sObject>, Schedulable{

    List<Project__c> inputList;

    public ProjectRemainingForecastsBatch() {

        inputList = [SELECT Id, Name, Remaining_Forecasted_Hrs__c, Remaining_Forecasted_Rev__c, Total_Remaining_Forecasted_Hours__c, ForecastDataLastSyncedOn__c
                       FROM Project__c
                       WHERE Remaining_Forecasted_Hrs__c > 0 AND LastModifiedDate >= LAST_YEAR];

    }

    public void execute (SchedulableContext ctx) {   

        ProjectRemainingForecastsBatch newBatchRun = new ProjectRemainingForecastsBatch();
        Database.executeBatch(newBatchRun, 10); 
    }

    public List<Project__c> start(Database.BatchableContext bc) {
        System.debug('ProjectRemainingForecastsBatch START');
        return inputList;
    }

    public void execute(Database.BatchableContext BC, List<Project__c> projectList){
        System.debug('ProjectRemainingForecastsBatch EXECUTE with Batch Size: ' + projectList.size());
        

        Map<Id, Decimal> projectToRemainingLevForecastHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToTotalRemainingForecastHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToRemainingLevForecastRevenueMap = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToTotalRemainingForecastRevenueMap = new Map<Id, Decimal>();

        List<Id> relatedProjectIds = new List<Id>();
        for(Project__c proj : projectList){
            relatedProjectIds.add(proj.Id);

            projectToRemainingLevForecastHoursMap.put(proj.Id, 0);
            projectToTotalRemainingForecastHoursMap.put(proj.Id, 0);
            projectToRemainingLevForecastRevenueMap.put(proj.Id, 0);
            projectToTotalRemainingForecastRevenueMap.put(proj.Id, 0);
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
            System.debug('Remaining Forecasted Hours: ' + remainingForecastHours);
            System.debug('Remaining Forecasted Revenue: ' + remainingForecaseRevenue);
            System.debug('Contact Account Name: ' + contactAccountName);

            //Set the Levementum Totals
            if(contactAccountName == 'Levementum LLC'){
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

    public void finish(Database.BatchableContext BC){
        System.debug('ProjectRemainingForecastsBatch FINISH');

    }  
}