public with sharing class ProjTeamMemEffectiveRateTriggerHelper {

    public static void checkTimeEntryBillingRatePopulation(Set<Id> projTeamMemberIdSet){

        List<Replicon_Time_Entry__c> relatedTimeEntryList = new List<Replicon_Time_Entry__c>();
        relatedTimeEntryList = [SELECT Id, Name, Account__c, ActivityName__c, Associated_Billing_Rate__c, Associated_Billing_Rate_Text__c, Billable_Amount__c, 
                                    Billing_Action__c, Billing_Rate__c, Cognizant_Employee_Id__c, Comments__c, Deleted_in_Replicon__c, Employee__c, Employee__r.Cognizant_Employee_Id__c, 
                                    EntryDate__c, ForceUpdateCheckbox__c, Internal_Project_Team_Member__c, Is_Billable__c, Is_Concession__c, Is_Lev_Time__c, Opportunity__c, 
                                    Peoplesoft_Project_Id__c, Project__c, Project__r.Peoplesoft_Project_Id__c, ProjectRole__c, RelatedNonbillOrConcessionCase__c, Replicon_Forecast__c,
                                    Replicon_Timesheet__c, Submission_Date__c, Time_Off__c, Time_Off_Description__c, Timesheet_Status__c, TotalHrs__c, Type__c, Unique_Time_Entry_Id__c, 
                                    WeekEndDate__c, WeeklyTarget__c, WorkDay__c, Replicon_Billing_Rate_URI__c 
                                FROM Replicon_Time_Entry__c
                                WHERE Internal_Project_Team_Member__c IN :projTeamMemberIdSet AND Billing_Action__c = 'B'
                                ORDER BY Project__c, Employee__c, EntryDate__c];

        if(relatedTimeEntryList.size() > 0){
            System.debug('************************* Checking Time Entry Billing Rates after Effective Rate Trigger for ' + relatedTimeEntryList.size() + ' Time Entries ********************************');
            System.debug('Populating Time Entry Billing Rate in Effective Rate Trigger Helper: ' + relatedTimeEntryList);
            TimeEntryService.populateTimeEntryBillingRate(relatedTimeEntryList, true);
        }


    }

    public static void checkForecastBillingRatePopulation(Set<Id> projTeamMemberIdSet){

        List<RepliconForecast__c> relatedForecastList = new List<RepliconForecast__c>();
        relatedForecastList = [SELECT Id, Actual_Revenue__c, ActualHours__c, Cognizant_Employee_Id__c, Contact__c, Deleted_in_Replicon__c, EstimatedHours__c, EstimatedRevenue__c, 
                                            Internal_Project_Team_Member__c, Is_Lev_Forecast__c, Kickoff_Placeholder_Forecast__c, Name, NotForecasted__c, Peoplesoft_Project_Id__c, 
                                            Project__c, ProjectTeamMemberBillingRate__c, Week_End_Date__c, Week_Start_Date__c
                                FROM RepliconForecast__c
                                WHERE Deleted_in_Replicon__c = false AND Internal_Project_Team_Member__c IN :projTeamMemberIdSet
                                ORDER BY Project__c, Contact__c, Week_Start_Date__c];

        if(relatedForecastList.size() > 0){
            System.debug('************************* Checking Forecast Billing Rates after Effective Rate Trigger for ' + relatedForecastList.size() + ' Forecast(s) ********************************');
            System.debug('Populating Forecast(s) Billing Rate in Effective Rate Trigger Helper: ' + relatedForecastList);
            RepliconForecastTriggerHelper.populateForecastBillingRate(relatedForecastList, true);
        }

    }

    public static void checkEffectiveRateToAssignForTeamMember(Set<Id> teamMemberIdList){

        List<Project_Team_Member_Effective_Rate__c> effectiveRateList = new List<Project_Team_Member_Effective_Rate__c>();
        effectiveRateList = [SELECT Id, Name, Effective_Date__c, Internal_Project_Team_Member__c, Project_Billing_Rate__c, 
                                Internal_Project_Team_Member__r.Assigned_Billing_Rate__c, Internal_Project_Team_Member__r.Active_Effective_Billing_Rate__c
                            FROM Project_Team_Member_Effective_Rate__c
                            WHERE Internal_Project_Team_Member__c IN :teamMemberIdList
                            ORDER BY Internal_Project_Team_Member__c, Effective_Date__c ASC ];

        Map<Id, Id> teamMemberToAssignedBillRateMap = new Map<Id, Id>();
        Map<Id, Id> teamMemberToActiveEffectiveBillRateMap = new Map<Id, Id>();
        for(Project_Team_Member_Effective_Rate__c effRate : effectiveRateList){
            
            if(effRate.Effective_Date__c <= Date.today()){
                teamMemberToAssignedBillRateMap.put(effRate.Internal_Project_Team_Member__c, effRate.Project_Billing_Rate__c);
                teamMemberToActiveEffectiveBillRateMap.put(effRate.Internal_Project_Team_Member__c, effRate.Id);
            }
        }

        List<Client_Contact__c> teamMemberList = new List<Client_Contact__c>();
        List<Client_Contact__c> teamMemberUpdateList = new List<Client_Contact__c>();
        teamMemberList = [SELECT Id, Name, Client_Contact__r.Name, Project__r.Name, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c
                            FROM Client_Contact__c
                            WHERE Id IN :teamMemberToAssignedBillRateMap.keySet()];

        for(Client_Contact__c tm : teamMemberList){
            Boolean needsUpdate = false;
            if(tm.Assigned_Billing_Rate__c != teamMemberToAssignedBillRateMap.get(tm.Id)){
                tm.Assigned_Billing_Rate__c = teamMemberToAssignedBillRateMap.get(tm.Id);
                needsUpdate = true;
            }
            
            if(tm.Active_Effective_Billing_Rate__c != teamMemberToActiveEffectiveBillRateMap.get(tm.Id)){
                tm.Active_Effective_Billing_Rate__c = teamMemberToActiveEffectiveBillRateMap.get(tm.Id);
                needsUpdate = true;
            }
            
            if(needsUpdate){
                System.debug('Need Update for: ' + tm.Client_Contact__r.Name + ' On Project: ' + tm.Project__r.Name);
                teamMemberUpdateList.add(tm);
            }
        }

        if(teamMemberUpdateList.size() > 0){
            System.debug('Update Size: ' + teamMemberUpdateList.size());
            update teamMemberUpdateList;
        }


    }
}