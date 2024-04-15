/**
 * Created by Sam Tucker 5/11/2022
 * Purpose: To Associate Forecasts with their respective Project Role record
 *          Also will rollup the Total Hours/Amount Forecasted for the Project Role when the Forecast gets updated
 * 
 * How to Run:
 * 
 * 
 * Apex:
 * //Calls this function to populate all Forecasts with Billing Rates that don't already have the ProjectRole field populated
        ProjectRoleForecastLinkBatch forecastLinkBatch = new ProjectRoleForecastLinkBatch(true, null);
        Database.executeBatch(forecastLinkBatch, 250);
 * 
 * 
 */

public with sharing class ProjectRoleForecastLinkBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    //private static String levementumAccountId = '001d000000JGuQaAAL';
    public List<Id> projectsWithProjectRolesIdList = new List<Id>();
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeWeekEndDate = Date.newInstance(2022, 6, 4);
    public List<Id> projIdList = new List<Id>();

    public void execute(SchedulableContext sc) {
        System.debug('ProjectRoleForecastLinkBatch SCHEDULE');
        ProjectRoleForecastLinkBatch batch = new ProjectRoleForecastLinkBatch(true, null);
        Database.executeBatch(batch, 250);
    }
    
    //Allows this batch to run for all unmatched Time Entries or for only run it for a specific list of projects
    public ProjectRoleForecastLinkBatch(Boolean runForAllTimeEntries, List<Id> projectIdList) {
        System.debug('**** ProjectRoleForecastLinkBatch ****');

        if(runForAllTimeEntries){
            AggregateResult[] projectRoleAgg = [SELECT count(Id), Project__c
                                                FROM ProjectRole__c 
                                                WHERE Project__c != null 
                                                GROUP BY Project__c, Project__r.Name];
            
            for(AggregateResult ar : projectRoleAgg){
                projectsWithProjectRolesIdList.add((Id)ar.get('Project__c'));
            }
            
            QueryString = 'SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c, Deleted_in_Replicon__c, Project__c, Contact__c, Contact__r.Name, Contact__r.Account.Name, EstimatedHours__c, EstimatedRevenue__c, ProjectTeamMemberBillingRate__c, ProjectRole__c, Contact__r.Replicon_User_Number__c, Contact__r.AccountId, Is_Lev_Forecast__c'
                            + ' FROM RepliconForecast__c'
                            + ' WHERE Deleted_in_Replicon__c = false AND Project__c != null AND ProjectTeamMemberBillingRate__c != null AND ProjectRole__c = null AND Project__c IN :projectsWithProjectRolesIdList'
                            + ' ORDER BY Project__c'; 
        }else{

            projIdList.addAll(projectIdList);

            QueryString = 'SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c, Deleted_in_Replicon__c, Project__c, Contact__c, Contact__r.Name, Contact__r.Account.Name, EstimatedHours__c, EstimatedRevenue__c, ProjectTeamMemberBillingRate__c, ProjectRole__c, Contact__r.Replicon_User_Number__c, Contact__r.AccountId, Is_Lev_Forecast__c'
                            + ' FROM RepliconForecast__c'
                            + ' WHERE Deleted_in_Replicon__c = false AND Project__c != null AND ProjectTeamMemberBillingRate__c != null AND ProjectRole__c = null AND Project__c IN :projIdList'
                            + ' ORDER BY Project__c'; 
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** ProjectRoleForecastLinkBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<RepliconForecast__c> forecastList){
        System.debug('**** ProjectRoleForecastLinkBatch EXECUTE ****');
        /**
         * Function Purpose: Execute the process of finding the proper Project Role to associate with the Forecast and populate the ProjectRole__c field on the Forecast
         */
        List<RepliconForecast__c> nonLevForecastList = new List<RepliconForecast__c>();
        List<RepliconForecast__c> levForecastList = new List<RepliconForecast__c>();

        for(RepliconForecast__c forecast : forecastList){
            if(((forecast.Week_End_Date__c < switchToATGTimeWeekEndDate && forecast.Contact__r.Name != atgConsultantContactName) 
                    || (forecast.Week_End_Date__c >= switchToATGTimeWeekEndDate && forecast.Contact__r.Name != atgConsultantContactName && forecast.Contact__r.Account.Name == levementumAccountName))){
                levForecastList.add(forecast);
            }else{
                nonLevForecastList.add(forecast);
            }

            /*
            if(forecast.Is_Lev_Forecast__c){
                levForecastList.add(forecast);
            }else{
                nonLevForecastList.add(forecast);
            }
            */
        }

        if(levForecastList.size() > 0){
            System.debug('Lev Forecast List Size: ' + levForecastList.size());
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(levForecastList, true, false);
        }

        if(nonLevForecastList.size() > 0){
            System.debug('Non Lev Forecast List Size: ' + nonLevForecastList.size());
            RepliconForecastTriggerHelper.linkForecastsToProjectRoleRecord(nonLevForecastList, true, true);
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** ProjectRoleForecastLinkBatch FINISH ****');

    }
}