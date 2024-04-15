public with sharing class InternalProjectTeamMemberTriggerHelper {

    private static Map<Id, Project_Team_Member_Billing_Rate__c> projBillRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();

    public static void linkProjectTeamMemberToBillRate(List<Client_Contact__c> newInternalProjTeamMembersList, Boolean needsUpdate){

        Set<Id> projectIdSet = new Set<Id>();

        for(Client_Contact__c cc : newInternalProjTeamMembersList){
            if(cc.Project__c != null){
                projectIdSet.add(cc.Project__c);
            }
        }
        
        List<Project_Team_Member_Billing_Rate__c> relatedBillingRates = new List<Project_Team_Member_Billing_Rate__c>();
        relatedBillingRates = [SELECT Id, Name, Created_in_Salesforce__c, Hourly_Rate__c, Project__c, Is_Temporary_Rate__c, Is_Concession_Rate__c
                                FROM Project_Team_Member_Billing_Rate__c
                                WHERE Created_in_Salesforce__c = true AND Is_Temporary_Rate__c = false AND Is_Concession_Rate__c = false AND Project__c IN :projectIdSet];

        Map<Id, Map<String, Project_Team_Member_Billing_Rate__c>> projectIdToBillRateNameToBillRateMap = new Map<Id, Map<String, Project_Team_Member_Billing_Rate__c>>();
        for(Project_Team_Member_Billing_Rate__c rate : relatedBillingRates){
            
            if(projectIdToBillRateNameToBillRateMap.containsKey(rate.Project__c)){
                Map<String, Project_Team_Member_Billing_Rate__c> billRateNameToBillRateMap = projectIdToBillRateNameToBillRateMap.get(rate.Project__c);
                billRateNameToBillRateMap.put(rate.Name, rate);
                projectIdToBillRateNameToBillRateMap.put(rate.Project__c, billRateNameToBillRateMap);
            }else{
                Map<String, Project_Team_Member_Billing_Rate__c> billRateNameToBillRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
                billRateNameToBillRateMap.put(rate.Name, rate);
                projectIdToBillRateNameToBillRateMap.put(rate.Project__c, billRateNameToBillRateMap);

            }
        }

        List<Client_Contact__c> projectTeamMemberUpdateList = new List<Client_Contact__c>();
        for(Client_Contact__c cc : newInternalProjTeamMembersList){
            if(projectIdToBillRateNameToBillRateMap.containsKey(cc.Project__c)){

                Map<String, Project_Team_Member_Billing_Rate__c> billRateNameToBillRateMap = projectIdToBillRateNameToBillRateMap.get(cc.Project__c);

                if(billRateNameToBillRateMap.containsKey(cc.Contact_Role__c)){
                    if(cc.Assigned_Billing_Rate__c != billRateNameToBillRateMap.get(cc.Contact_Role__c).Id){
                        cc.Assigned_Billing_Rate__c = billRateNameToBillRateMap.get(cc.Contact_Role__c).Id;
                        projectTeamMemberUpdateList.add(cc);
                    }
                }
            }
        }
        
        if(needsUpdate && projectTeamMemberUpdateList.size() > 0){
            System.debug('************************ Populating ' + projectTeamMemberUpdateList.size() + ' Internal Project Team Members with Billing Rates ******************************');
            update projectTeamMemberUpdateList;
        }

    }


    public static void flipTempRateEntries(List<Client_Contact__c> teamMemberList, Map<Id, Client_Contact__c> oldMap){

        Set<Id> assignedBillingRateIdSet = new Set<Id>();
        for(Client_Contact__c cc : teamMemberList){

            if(oldMap.containsKey(cc.Id) && oldMap.get(cc.Id).Assigned_Billing_Rate__c != null){
                assignedBillingRateIdSet.add(oldMap.get(cc.Id).Assigned_Billing_Rate__c);
            }
        }

        Map<Id, Project_Team_Member_Billing_Rate__c> tempRateIdToRateMap;
        if(assignedBillingRateIdSet.size() > 0){
            tempRateIdToRateMap = new Map<Id, Project_Team_Member_Billing_Rate__c>([SELECT Id, Name, Project__c, Is_Temporary_Rate__c 
                                                                                    FROM Project_Team_Member_Billing_Rate__c 
                                                                                    WHERE Id IN :assignedBillingRateIdSet AND Is_Temporary_Rate__c = true]);
        }

        Set<Id> employeeTempRateSwitchIdSet = new Set<Id>();
        Set<Id> projectTempRateSwitchIdSet = new Set<Id>();
        Set<Id> projectTeamMemberTempRateSwitchIdSet = new Set<Id>();
        Map<String, Client_Contact__c> employeeAndProjectUniqueIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
        Map<Id, Client_Contact__c> projectTeamMemberIdToProjTeamMemberMap = new Map<Id, Client_Contact__c>();
        for(Client_Contact__c cc : teamMemberList){

            if(oldMap.containsKey(cc.Id) && oldMap.get(cc.Id).Assigned_Billing_Rate__c != null && tempRateIdToRateMap.containsKey(oldMap.get(cc.Id).Assigned_Billing_Rate__c) && !tempRateIdToRateMap.containsKey(cc.Assigned_Billing_Rate__c)){
                //If the team member was changed from a Temp rate to something else then update any existing time entries/forecasts
                employeeTempRateSwitchIdSet.add(cc.Client_Contact__c);
                projectTempRateSwitchIdSet.add(cc.Project__c);
                projectTeamMemberTempRateSwitchIdSet.add(cc.Id);

                String uniqueEmployeeAndProjectId = String.valueOf(cc.Client_Contact__c) + ' | ' + String.valueOf(cc.Project__c);
                employeeAndProjectUniqueIdToProjTeamMemberMap.put(uniqueEmployeeAndProjectId, cc);

                projectTeamMemberIdToProjTeamMemberMap.put(cc.Id, cc);
            }
        }

        if((employeeTempRateSwitchIdSet.size() > 0 && projectTempRateSwitchIdSet.size() > 0) || projectTeamMemberTempRateSwitchIdSet.size() > 0){

            List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
            entryList =  [SELECT Id, Name, Project__c, Employee__c, Internal_Project_Team_Member__c, EntryDate__c, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Is_Temporary_Rate__c
                            FROM Replicon_Time_Entry__c
                            WHERE Associated_Billing_Rate__r.Is_Temporary_Rate__c = true AND ((Employee__c IN :employeeTempRateSwitchIdSet AND Project__c IN :projectTempRateSwitchIdSet) OR (Internal_Project_Team_Member__c IN :projectTeamMemberTempRateSwitchIdSet))];


            List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                

                if(entry.Internal_Project_Team_Member__c == null){
                    String uniqueEmployeeAndProjectId = String.valueOf(String.valueOf(entry.Employee__c) + ' | ' + String.valueOf(entry.Project__c));

                    if(employeeAndProjectUniqueIdToProjTeamMemberMap.containsKey(uniqueEmployeeAndProjectId)){
                        if(entry.Associated_Billing_Rate__c != employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c && employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c != null){
                            entry.Associated_Billing_Rate__c = employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c;
                            entryUpdateList.add(entry);
                        }
                    }
                }else{
                    
                    if(projectTeamMemberIdToProjTeamMemberMap.containsKey(entry.Internal_Project_Team_Member__c)){
                        if(entry.Associated_Billing_Rate__c != projectTeamMemberIdToProjTeamMemberMap.get(entry.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c && projectTeamMemberIdToProjTeamMemberMap.get(entry.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c != null){
                            entry.Associated_Billing_Rate__c = projectTeamMemberIdToProjTeamMemberMap.get(entry.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c;
                            entryUpdateList.add(entry);
                        }
                    }
                }
            }

            if(entryUpdateList.size() > 0){
                System.debug('******************************* Updating ' + entryUpdateList.size() + ' Time Entries with new Bill Rates after related Team Member switched from Temporary Rate ******************************');
                update entryUpdateList;
            }

            List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
            forecastList =  [SELECT Id, Name, Project__c, Contact__c, Internal_Project_Team_Member__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Is_Temporary_Rate__c
                                FROM RepliconForecast__c
                                WHERE ProjectTeamMemberBillingRate__r.Is_Temporary_Rate__c = true AND ((Contact__c IN :employeeTempRateSwitchIdSet AND Project__c IN :projectTempRateSwitchIdSet) OR (Internal_Project_Team_Member__c IN :projectTeamMemberTempRateSwitchIdSet))];

            List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();
            for(RepliconForecast__c forecast : forecastList){
                

                if(forecast.Internal_Project_Team_Member__c == null){
                    String uniqueEmployeeAndProjectId = String.valueOf(String.valueOf(forecast.Contact__c) + ' | ' + String.valueOf(forecast.Project__c));

                    if(employeeAndProjectUniqueIdToProjTeamMemberMap.containsKey(uniqueEmployeeAndProjectId)){
                        if(forecast.ProjectTeamMemberBillingRate__c != employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c && employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c != null){
                            forecast.ProjectTeamMemberBillingRate__c = employeeAndProjectUniqueIdToProjTeamMemberMap.get(uniqueEmployeeAndProjectId).Assigned_Billing_Rate__c;
                            forecastUpdateList.add(forecast);
                        }
                    }
                }else{
                    
                    if(projectTeamMemberIdToProjTeamMemberMap.containsKey(forecast.Internal_Project_Team_Member__c)){
                        if(forecast.ProjectTeamMemberBillingRate__c != projectTeamMemberIdToProjTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c && projectTeamMemberIdToProjTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c != null){
                            forecast.ProjectTeamMemberBillingRate__c = projectTeamMemberIdToProjTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c;
                            forecastUpdateList.add(forecast);
                        }
                    }
                }
            }

            if(forecastUpdateList.size() > 0){
                System.debug('******************************* Updating ' + forecastUpdateList.size() + ' Forecasts with new Bill Rates after related Team Member switched from Temporary Rate ******************************');
                update forecastUpdateList;
            }
        }


    }


    public static void billingRateChanged(List<Client_Contact__c> teamMemberList, Map<Id, Client_Contact__c> oldMap){

        System.debug('Billing Rate Changed');
        Set<Id> billRateIdSet = new Set<Id>();
        Set<Id> oldBillRateIdSet = new Set<Id>();
        for(Client_Contact__c projTeamMember : teamMemberList){

            if(projTeamMember.Assigned_Billing_Rate__c != oldMap.get(projTeamMember.Id).Assigned_Billing_Rate__c){
                billRateIdSet.add(projTeamMember.Assigned_Billing_Rate__c);
                billRateIdSet.add(oldMap.get(projTeamMember.Id).Assigned_Billing_Rate__c);
            }


        }

        List<Project_Team_Member_Billing_Rate__c> projBillRates = new List<Project_Team_Member_Billing_Rate__c>();
        projBillRates = [SELECT Id, Name, Hourly_Rate__c, Is_Temporary_Rate__c, Is_Concession_Rate__c, Outdated_Rate__c, Project__c
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Id IN :billRateIdSet
                            ORDER BY Project__c];

        Map<Id, Project_Team_Member_Billing_Rate__c> billRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
        Map<Id, Project_Team_Member_Billing_Rate__c> tempRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c rate : projBillRates){
            billRateIdToRecordMap.put(rate.Id, rate);
            projBillRateIdToRecordMap.put(rate.Id, rate);
            if(rate.Is_Temporary_Rate__c){
                tempRateIdToRecordMap.put(rate.Id, rate);
            }
        }

        Set<Id> projectTeamMemberForBillRateChangeIdSet = new Set<Id>();
        Map<Id, Client_Contact__c> internalProjTeamMemberIdToRecordMap = new Map<Id, Client_Contact__c>();
        Map<Id, Client_Contact__c> internalProjTeamMemberIdToRecordForOutdatedRateChangeMap = new Map<Id, Client_Contact__c>();
        for(Client_Contact__c projTeamMember : teamMemberList){

            //If the Bill Rate switched to OR from Temp Rate then do not update any time entries
            if(!tempRateIdToRecordMap.containsKey(projTeamMember.Assigned_Billing_Rate__c) && !tempRateIdToRecordMap.containsKey(oldMap.get(projTeamMember.Id).Assigned_Billing_Rate__c) && projTeamMember.Active_Effective_Billing_Rate__c == null){

                if(projTeamMember.Is_Placeholder_Team_Member__c){
                    //If Placeholder then update all forecasts for the placeholder
                    internalProjTeamMemberIdToRecordMap.put(projTeamMember.Id, projTeamMember);
                }else{
                    //If NOT Placeholder then update all time entries for the updated Project Team Member
                    projectTeamMemberForBillRateChangeIdSet.add(projTeamMember.Id);
                    System.debug('Billing Rate Changed For NON PLACEHOLDER');

                    if(billRateIdToRecordMap.containsKey(oldMap.get(projTeamMember.Id).Assigned_Billing_Rate__c) && billRateIdToRecordMap.get(oldMap.get(projTeamMember.Id).Assigned_Billing_Rate__c).Outdated_Rate__c == true ){
                        System.debug('Billing Rate Changed For Outdated Rate');
                        internalProjTeamMemberIdToRecordForOutdatedRateChangeMap.put(projTeamMember.Id, projTeamMember);
                    }
                }
                
            }
        }                  

        if(projectTeamMemberForBillRateChangeIdSet.size() > 0){

            List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
            entryList = [SELECT Id, Name, Employee__c, Project__c, Internal_Project_Team_Member__c, Billing_Action__c, Time_Off__c, Is_Concession__c, Associated_Billing_Rate__c
                            FROM Replicon_Time_Entry__c
                            WHERE Internal_Project_Team_Member__c IN :projectTeamMemberForBillRateChangeIdSet AND Is_Concession__c = false AND Is_Billable__c = true AND Deleted_in_Replicon__c = false];

            TimeEntryService.populateTimeEntryBillingRate(entryList, true);
        }

        if(internalProjTeamMemberIdToRecordMap.size() > 0){
            updateProjectTeamMemberForecastsBillRate(internalProjTeamMemberIdToRecordMap, true);
        }

        if(internalProjTeamMemberIdToRecordForOutdatedRateChangeMap.size() > 0){
            updateProjectTeamMemberForecastsBillRate(internalProjTeamMemberIdToRecordForOutdatedRateChangeMap, false);
        }
    }

    public static void updateProjectTeamMemberContactRole(List<Client_Contact__c> teamMemberList, Set<Id> billRateIdSet, Boolean needsUpdate){

        System.debug('Update Projec Team Member Contact Role: ' + teamMemberList);
        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billingRateList = [SELECT Id, Name, Product__c, Product__r.Name, Hourly_Rate__c
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Id IN :billRateIdSet];

        Map<Id, Project_Team_Member_Billing_Rate__c> billRateIdToRecordMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c rate : billingRateList){

            billRateIdToRecordMap.put(rate.Id, rate);
            
        }

        List<Client_Contact__c> projTeamMemberUpdateList = new List<Client_Contact__c>();
        for(Client_Contact__c teamMember : teamMemberList){

            if(billRateIdToRecordMap.containsKey(teamMember.Assigned_Billing_Rate__c)){

                Project_Team_Member_Billing_Rate__c billingRate = billRateIdToRecordMap.get(teamMember.Assigned_Billing_Rate__c);
                if(teamMember.Contact_Role__c != billingRate.Product__r.Name){
                    teamMember.Contact_Role__c = billingRate.Product__r.Name;
                    projTeamMemberUpdateList.add(teamMember);
                }
            }
        }

        if(projTeamMemberUpdateList.size() > 0){
            System.debug('*********************************** Updating Contact Role on ' + projTeamMemberUpdateList.size() + ' Internal Project Team Members. Updated: ' + needsUpdate + ' ***********************************');
            if(needsUpdate){
                update projTeamMemberUpdateList;
            }
        }

    }

    public static void updateProjectTeamMemberForecastsBillRate(Map<Id, Client_Contact__c> projTeamMemberMap, Boolean placeholdersOnly){

        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>(); 

        if(placeholdersOnly){
            List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
            forecastList = [SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Assigned_Billing_Rate__c, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, Project__c,
                                Project__r.Peoplesoft_Project_Id__c
                            FROM RepliconForecast__c
                            WHERE Internal_Project_Team_Member__c IN :projTeamMemberMap.keySet()];

            for(RepliconForecast__c forecast : forecastList){
                if(forecast.Internal_Project_Team_Member__c != null && projTeamMemberMap.containsKey(forecast.Internal_Project_Team_Member__c) && projTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c != null){
                    if(forecast.ProjectTeamMemberBillingRate__c != projTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c){
                        forecast.ProjectTeamMemberBillingRate__c = projTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c;

                        String timesheetStartString = DateTime.newInstance(forecast.Week_Start_Date__c.year(), forecast.Week_Start_Date__c.month(), forecast.Week_Start_Date__c.day()).format('MM/dd/YYYY');
                        String timesheetEndString = DateTime.newInstance(forecast.Week_End_Date__c.year(), forecast.Week_End_Date__c.month(), forecast.Week_End_Date__c.day()).format('MM/dd/YYYY');

                        String peoplesoftProjectId = '';
                        if(forecast.Project__c != null && forecast.Project__r.Peoplesoft_Project_Id__c != null){
                            peoplesoftProjectId = forecast.Project__r.Peoplesoft_Project_Id__c;
                        }

                        String billRateName = '';
                        if(projBillRateIdToRecordMap.containsKey(projTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c)){
                            billRateName = projBillRateIdToRecordMap.get(projTeamMemberMap.get(forecast.Internal_Project_Team_Member__c).Assigned_Billing_Rate__c).Name;
                        }

                        forecast.Name = timesheetStartString + '-' + timesheetEndString + '-' + '0' + '-' + billRateName + '-' + peoplesoftProjectId;
                        forecastUpdateList.add(forecast);
                    }
                }
            }
        }else{
            System.debug('Repopulate Forecasts for Billing Rates');
            ProjTeamMemEffectiveRateTriggerHelper.checkForecastBillingRatePopulation(projTeamMemberMap.keySet());
        }

        if(forecastUpdateList.size() > 0){
            System.debug('**************************** Updating ' + forecastUpdateList.size() + ' Forecasts with new Billing Rates after Team Member Rate Change ************************************');
            update forecastUpdateList;
        }

    }
}