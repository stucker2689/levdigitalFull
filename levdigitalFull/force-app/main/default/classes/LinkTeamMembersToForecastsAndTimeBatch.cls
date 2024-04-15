/**
 * Created 6.21.2023 ST
 * 
Set<Id> projectIdSet = new Set<Id>();
Set<Id> contactIdSet = new Set<Id>();
LinkTeamMembersToForecastsAndTimeBatch teamMemberLinkBatch = new LinkTeamMembersToForecastsAndTimeBatch('Forecast', projectIdSet, contactIdSet);
Database.executeBatch(teamMemberLinkBatch, 500);
 * 
 */

public with sharing class LinkTeamMembersToForecastsAndTimeBatch implements Database.Batchable<sObject>{
    
    public final String QueryString;
    public final String objectToLink;
    public final Set<Id> projIdSet;
    public final Set<Id> conIdSet;
    
    public LinkTeamMembersToForecastsAndTimeBatch(String objectToLinkParam, Set<Id> projectIdSet, Set<Id> contactIdSet) {

        objectToLink = objectToLinkParam;
        projIdSet = projectIdSet;
        conIdSet = contactIdSet;
        if(objectToLink == 'Forecast'){

            QueryString = 'SELECT Id, Name, Contact__c, Contact__r.Name, Project__c, Project__r.Name, EstimatedHours__c, Week_Start_Date__c, Week_End_Date__c, ' 
                        + 'ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c, Internal_Project_Team_Member__c '
                        + 'FROM RepliconForecast__c '
                        + 'WHERE Internal_Project_Team_Member__c = null AND Project__c IN :projIdSet AND Project__c != null AND Contact__c IN :conIdSet AND Contact__c != null '
                        + 'ORDER BY Project__c, Contact__c, Week_Start_Date__c';

        }else if(objectToLink == 'Time Entry'){

            QueryString = 'SELECT Id, Name, Employee__c, Employee__r.Name, Project__c, Project__r.Name, TotalHrs__c, EntryDate__c, WeekEndDate__c, ' 
                        + 'Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c, Internal_Project_Team_Member__c '
                        + 'FROM Replicon_Time_Entry__c '
                        + 'WHERE Internal_Project_Team_Member__c = null AND Project__c IN :projIdSet AND Project__c != null AND Employee__c IN :conIdSet AND Employee__c != null '
                        + 'ORDER BY Project__c, Employee__c, EntryDate__c';
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('*************** LinkTeamMembersToForecastsAndTimeBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext bc, List<sObject> objectList){
        System.debug('*************** LinkTeamMembersToForecastsAndTimeBatch EXECUTE ***************');
        List<RepliconForecast__c> batchForecastList = new List<RepliconForecast__c>();
        List<Replicon_Time_Entry__c> batchEntryList = new List<Replicon_Time_Entry__c>();

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
        List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();

        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();

        if(objectToLink == 'Forecast'){
            for(sObject obj : objectList){
                RepliconForecast__c forecast = (RepliconForecast__c)obj;
                batchForecastList.add(forecast);

                projectIdSet.add(forecast.Project__c);
                contactIdSet.add(forecast.Contact__c);

            }

        }else if(objectToLink == 'Time Entry'){
            for(sObject obj : objectList){
                Replicon_Time_Entry__c entry = (Replicon_Time_Entry__c)obj;
                batchEntryList.add(entry);

                projectIdSet.add(entry.Project__c);
                contactIdSet.add(entry.Employee__c);

            }
        }

        /***************************************** Query related Team Members to Link *******************************************/
        List<Client_Contact__c> relatedProjectTeamMemberList = new List<Client_Contact__c>();
        relatedProjectTeamMemberList = [SELECT Id, Name, Contact_Role__c, Client_Contact__c, Client_Contact__r.Name, Project__c, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c
                                        FROM Client_Contact__c
                                        WHERE Project__c IN :projectIdSet AND Client_Contact__c IN :contactIdSet
                                        ORDER BY Project__c, Client_Contact__c];

        Map<String, Client_Contact__c> uniqueTeamMemberStringToRecordMap = new Map<String, Client_Contact__c>();
        for(Client_Contact__c projTeamMember : relatedProjectTeamMemberList){

            String uniqueString;

            if(projTeamMember.Client_Contact__r.Name == 'Place Holder'){
                uniqueString = String.valueOf(projTeamMember.Project__c) + '@' + String.valueOf(projTeamMember.Client_Contact__c) + '@' + projTeamMember.Assigned_Billing_Rate__r.Name + '@' + String.valueOf(projTeamMember.Assigned_Billing_Rate__r.Hourly_Rate__c);
            }else{
                uniqueString = String.valueOf(projTeamMember.Project__c) + '@' + String.valueOf(projTeamMember.Client_Contact__c);
            }

            uniqueTeamMemberStringToRecordMap.put(uniqueString, projTeamMember);
        }


        /***************************************** Link Existing Time Entries or Forecasts to the Team Members ********************/
        if(objectToLink == 'Forecast'){
            for(repliconForecast__c forecast : batchForecastList){
                String uniqueString;
                
                if(forecast.Contact__r.Name == 'Place Holder'){
                    if(forecast.ProjectTeamMemberBillingRate__c != null){
                        uniqueString = String.valueOf(forecast.Project__c) + '@' + String.valueOf(forecast.Contact__c) + '@' + forecast.ProjectTeamMemberBillingRate__r.Name + '@' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                    }
                }else{
                    uniqueString = String.valueOf(forecast.Project__c) + '@' + String.valueOf(forecast.Contact__c);
                }

                if(uniqueTeamMemberStringToRecordMap.containsKey(uniqueString)){
                    if(forecast.Internal_Project_Team_Member__c != uniqueTeamMemberStringToRecordMap.get(uniqueString).Id){
                        forecast.Internal_Project_Team_Member__c = uniqueTeamMemberStringToRecordMap.get(uniqueString).Id;
                        forecastUpdateList.add(forecast);
                    }
                }
            }

        }else if(objectToLink == 'Time Entry'){
            for(Replicon_Time_Entry__c entry : batchEntryList){
                String uniqueString;
                
                if(entry.Employee__r.Name == 'Place Holder'){
                    if(entry.Associated_Billing_Rate__c != null){
                        uniqueString = String.valueOf(entry.Project__c) + '@' + String.valueOf(entry.Employee__c) + '@' + entry.Associated_Billing_Rate__r.Name + '@' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                    }
                }else{
                    uniqueString = String.valueOf(entry.Project__c) + '@' + String.valueOf(entry.Employee__c);
                }

                if(uniqueTeamMemberStringToRecordMap.containsKey(uniqueString)){
                    if(entry.Internal_Project_Team_Member__c != uniqueTeamMemberStringToRecordMap.get(uniqueString).Id){
                        entry.Internal_Project_Team_Member__c = uniqueTeamMemberStringToRecordMap.get(uniqueString).Id;
                        entryUpdateList.add(entry);
                    }
                }
            }
        }

        /**************************************** DML to update Forecasts/Time Entries with Internal Project Team Member Lookups ***********************************/
        if(forecastUpdateList.size() > 0){
            System.debug('********************************** Updating ' + forecastUpdateList.size() + ' Forecasts with Internal Project Team Member Lookups **********************************');
            update forecastUpdateList;
        }

        if(entryUpdateList.size() > 0){
            System.debug('********************************** Updating ' + entryUpdateList.size() + ' Time Entries with Internal Project Team Member Lookups **********************************');
            update entryUpdateList;
        }

    }

    public void finish(Database.BatchableContext bc){
        System.debug('*************** LinkTeamMembersToForecastsAndTimeBatch FINISH ***************');

    }
}