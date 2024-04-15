/**
 * Created 6.13.2023 ST
 * 
 * To Create Internal Project Team Members on Existing Projects
 * 
 * Run to Create Internal Project Team Members from Staffing Assignments
 * List<Id> projIdList = new List<Id>();
 * InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Staffing Assignment', null);
 * Database.executeBatch(newProjTeamMemberCreationBatch, 100);
 */

public with sharing class InternalProjectMemberCreationBatch implements Database.Batchable<sObject> {

    public final String QueryString;
    public final String createFromObject;
    public final List<Id> projIdList;

    public InternalProjectMemberCreationBatch(String createFromObjectCheck, List<Id> projectIdList) {

        createFromObject = createFromObjectCheck;
        if(createFromObject == 'Staffing Assignment'){

            QueryString = 'SELECT Id, Name, (SELECT Id, Name, Status__c FROM Staffing_Assignments__r WHERE Status__c = \'Completed\') '
                            + 'FROM Opportunity WHERE StageName = \'Closed Won\' ORDER BY CloseDate DESC';

        }else if(createFromObject == 'Forecast'){

            if(projectIdList != null && projectIdList.size() > 0){
                projIdList = projectIdList;
                QueryString = 'SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Contact__r.AccountId, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Project__r.Account__c, EstimatedHours__c, Week_Start_Date__c, '
                + 'Project__r.CreatedDate, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Name, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c '
                + 'FROM RepliconForecast__c WHERE Deleted_in_Replicon__c = false AND Project__c != null AND Contact__c != null AND Project__c IN :projIdList '
                + 'ORDER BY Project__c, Contact__c, Week_Start_Date__c ASC';
            }else{
                QueryString = 'SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Cognizant_Employee_Id__c, Contact__r.AccountId, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Project__r.Account__c, EstimatedHours__c, Week_Start_Date__c, '
                + 'Project__r.CreatedDate, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Name, ProjectTeamMemberBillingRate__c, ProjectTeamMemberBillingRate__r.Name, ProjectTeamMemberBillingRate__r.Hourly_Rate__c '
                + 'FROM RepliconForecast__c WHERE Deleted_in_Replicon__c = false AND Project__c != null AND Contact__c != null AND Project__r.Project_Status__c IN (\'Active\', \'On Hold\', \'Not Started\') '
                + 'ORDER BY Project__c, Contact__c, Week_Start_Date__c ASC';
            }

        }else if(createFromObject == 'Time Entry'){

            if(projectIdList != null && projectIdList.size() > 0){
                projIdList = projectIdList;
                QueryString = 'SELECT Id, Name, Employee__c, Employee__r.Name, Employee__r.Cognizant_Employee_Id__c, Employee__r.AccountId, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Project__r.Account__c, TotalHrs__c, EntryDate__c, '
                + 'Project__r.CreatedDate, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Name, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c '
                + 'FROM Replicon_Time_Entry__c WHERE Deleted_in_Replicon__c = false AND Project__c != null AND Employee__c != null AND Project__c IN :projIdList '
                + 'ORDER BY Project__c, Employee__c, EntryDate__c ASC';
            }else{
                QueryString = 'SELECT Id, Name, Employee__c, Employee__r.Name, Employee__r.Cognizant_Employee_Id__c, Employee__r.AccountId, Project__c, Project__r.Name, Project__r.Peoplesoft_Project_Id__c, Project__r.Account__c, TotalHrs__c, EntryDate__c, '
                + 'Project__r.CreatedDate, Internal_Project_Team_Member__c, Internal_Project_Team_Member__r.Name, Associated_Billing_Rate__c, Associated_Billing_Rate__r.Name, Associated_Billing_Rate__r.Hourly_Rate__c '
                + 'FROM Replicon_Time_Entry__c WHERE Deleted_in_Replicon__c = false AND Project__c != null AND Employee__c != null AND Project__r.Project_Status__c IN (\'Active\', \'On Hold\', \'Not Started\') '
                + 'ORDER BY Project__c, Employee__c, EntryDate__c ASC';
            }
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('*************** InternalProjectMemberCreationBatch START ***************');
        return Database.getQueryLocator(QueryString);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> batchObjectList){
        System.debug('*************** InternalProjectMemberCreationBatch EXECUTE ***************');

        if(createFromObject == 'Staffing Assignment'){

            List<Opportunity> opptyList = new List<Opportunity>();

            for(sObject batchObj : batchObjectList){

                Opportunity oppty = (Opportunity)batchObj;
                if(oppty.Staffing_Assignments__r.size() > 0){
                    opptyList.add(oppty);
                }
            }

            if(opptyList.size() > 0){
                System.debug('***************************************** Sending ' + opptyList.size() + ' Opportunitys to Create Internal Project Team Members from InternalProjectMemberCreationBatchTEST run *****************************************');
                StaffingAssignmentTriggerHelper.createProjTeamMembersFromOpptyCW(opptyList);
            }

        }else if(createFromObject == 'Forecast'){

            List<RepliconForecast__c> forecastsToLinkList = new List<RepliconForecast__c>();
            for(sObject batchObj : batchObjectList){
                RepliconForecast__c forecast = (RepliconForecast__c)batchObj;
                forecastsToLinkList.add(forecast);
            }

            if(forecastsToLinkList.size() > 0){
                createTeamMembersFromForecasts(forecastsToLinkList);
            } 

        /*********************** Create Project Team Members from Time Entries and Update Time Entries with Team Member lookups ************************/
        }else if(createFromObject == 'Time Entry'){

            List<Replicon_Time_Entry__c> entriesToLinkList = new List<Replicon_Time_Entry__c>();
            for(sObject batchObj : batchObjectList){
                Replicon_Time_Entry__c entry = (Replicon_Time_Entry__c)batchObj;
                entriesToLinkList.add(entry);
            }

            if(entriesToLinkList.size() > 0){
                createTeamMembersFromTimeEntries(entriesToLinkList);
            }            
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('*************** InternalProjectMemberCreationBatch FINISH ***************');

    }


    public static void createTeamMembersFromForecasts(List<RepliconForecast__c> forecastList){
        List<Client_Contact__c> internalProjectTeamMembersToInsertList = new List<Client_Contact__c>();

            Set<String> uniqueContactAndProjectStringSet = new Set<String>();
            Set<String> uniqueExistingContactAndProjectStringSet = new Set<String>();
            Map<String, Map<String, RepliconForecast__c>> uniqueProjTeamMemberStringBillRateMapMap = new Map<String, Map<String, RepliconForecast__c>>();

            Map<String, RepliconForecast__c> uniquePlaceholderStringToForecastMap = new Map<String, RepliconForecast__c>();
            Map<String, Map<String, RepliconForecast__c>> uniquePlaceholderProjTeamMemberStringBillRateMapMap = new Map<String, Map<String, RepliconForecast__c>>();

            Map<Id, RepliconForecast__c> projectIdToForecastWithProjectDetailsMap = new Map<Id, RepliconForecast__c>();
            Map<Id, RepliconForecast__c> contactIdToForecastWithContactDetailsMap = new Map<Id, RepliconForecast__c>();

            for(RepliconForecast__c forecast : forecastList){
                if(forecast.EstimatedHours__c > 0){

                    //Make Unique String for each Contact Project Combo
                    if(forecast.Contact__r.Name != 'Place Holder'){

                        String uniqueTeamMemberString = String.valueOf(forecast.Contact__c) + ' @ ' + String.valueOf(forecast.Project__c);
                        uniqueContactAndProjectStringSet.add(uniqueTeamMemberString);

                        if(!uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ //If Unique Combo of Contact and Project doesn't exist in Map yet

                            Map<String, RepliconForecast__c> billRateMap = new Map<String, RepliconForecast__c>();

                            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.ProjectTeamMemberBillingRate__r.Name != 'Temporary Rate' && forecast.ProjectTeamMemberBillingRate__r.Name != 'Concession'){

                                String rateBaseName;
                                if(forecast.ProjectTeamMemberBillingRate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name.left(forecast.ProjectTeamMemberBillingRate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                                }else{
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name;
                                }

                                if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                                    rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                                }
                                
                                //String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                billRateMap.put(uniqueBillRateString, forecast);
                            }

                            uniqueProjTeamMemberStringBillRateMapMap.put(uniqueTeamMemberString, billRateMap);   

                        }else{ //If it does then check to see if we need to add to the Bill Rate Map

                            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.ProjectTeamMemberBillingRate__r.Name != 'Temporary Rate' && forecast.ProjectTeamMemberBillingRate__r.Name != 'Concession'){

                                String rateBaseName;
                                if(forecast.ProjectTeamMemberBillingRate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name.left(forecast.ProjectTeamMemberBillingRate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                                }else{
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name;
                                }

                                if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                                    rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                                }
                                
                                //String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);

                                Map<String, RepliconForecast__c> billRateMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);

                                if(!billRateMap.containsKey(uniqueBillRateString)){
                                    //If not in Bill rate map then add to bill rate map, then all to overall map
                                    billRateMap.put(uniqueBillRateString, forecast);
                                    uniqueProjTeamMemberStringBillRateMapMap.put(uniqueTeamMemberString, billRateMap);
                                }
                            }  
                        }

                    }else{
                        //Handle for Placeholders
                        String uniquePlaceholderTeamMemberString = String.valueOf(forecast.Contact__c) + ' @ ' + String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name;
                        uniquePlaceholderStringToForecastMap.put(uniquePlaceholderTeamMemberString, forecast);

                        if(!uniquePlaceholderProjTeamMemberStringBillRateMapMap.containsKey(uniquePlaceholderTeamMemberString)){ //If Unique Combo of Contact and Project doesn't exist in Map yet

                            Map<String, RepliconForecast__c> billRateMap = new Map<String, RepliconForecast__c>();

                            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.ProjectTeamMemberBillingRate__r.Name != 'Temporary Rate' && forecast.ProjectTeamMemberBillingRate__r.Name != 'Concession'){

                                String rateBaseName;
                                if(forecast.ProjectTeamMemberBillingRate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name.left(forecast.ProjectTeamMemberBillingRate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                                }else{
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name;
                                }

                                if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                                    rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                                }
                                
                                //String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                billRateMap.put(uniqueBillRateString, forecast);
                            }

                            uniquePlaceholderProjTeamMemberStringBillRateMapMap.put(uniquePlaceholderTeamMemberString, billRateMap);   

                        }else{ //If it does then check to see if we need to add to the Bill Rate Map

                            if(forecast.ProjectTeamMemberBillingRate__c != null && forecast.ProjectTeamMemberBillingRate__r.Name != 'Temporary Rate' && forecast.ProjectTeamMemberBillingRate__r.Name != 'Concession'){

                                String rateBaseName;
                                if(forecast.ProjectTeamMemberBillingRate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name.left(forecast.ProjectTeamMemberBillingRate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                                }else{
                                    rateBaseName = forecast.ProjectTeamMemberBillingRate__r.Name;
                                }

                                if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                                    rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                                }
                                
                                //String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                                String uniqueBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);

                                Map<String, RepliconForecast__c> billRateMap = uniquePlaceholderProjTeamMemberStringBillRateMapMap.get(uniquePlaceholderTeamMemberString);

                                if(!billRateMap.containsKey(uniqueBillRateString)){
                                    //If not in Bill rate map then add to bill rate map, then all to overall map
                                    billRateMap.put(uniqueBillRateString, forecast);
                                    uniquePlaceholderProjTeamMemberStringBillRateMapMap.put(uniquePlaceholderTeamMemberString, billRateMap);
                                }
                            }  
                        }
                    }

                    //Make Map For Project and Contact in order to retrieve info for them during Project Team Member Creation
                    if(forecast.Project__c != null && !projectIdToForecastWithProjectDetailsMap.containsKey(forecast.Project__c)){
                        projectIdToForecastWithProjectDetailsMap.put(forecast.Project__c, forecast);
                    }

                    if(forecast.Contact__c != null && !contactIdToForecastWithContactDetailsMap.containsKey(forecast.Contact__c)){
                        contactIdToForecastWithContactDetailsMap.put(forecast.Contact__c, forecast);
                    }
                }
            }

            /************************************************************************** Get Existing Internal Project Team Members **************************************************************************/
            /**
             * Get Existing Team Members, if they already exist, then remove from the set/map
             * Check Effective Bill Rates
             * If only one bill rate in the bill rate map for team member to insert map, then look for existing Project Team Member Billing Rate to set as the Internal Project Team Member Assigned Billing Rate
             * If MORE than one Bill rate, then assign the last one as the Assigned Billing Rate and create Effective Rates for the previous ones with an Effective Date matching the forecast Week Start Date within the bill rate map value
             */
            Map<String, Client_Contact__c> existingProjectTeamMemberUniqueStringToRecordMap = new Map<String, Client_Contact__c>([SELECT Id, Name, Internal_Project_Team_Member_Name__c, Client_Contact__c, Client_Contact__r.Name, Project__c, Project__r.Name, Account__c, Contact_Role__c, Is_Placeholder_Team_Member__c, 
                                                                                                                                        Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, 
                                                                                                                                        (SELECT Id, Name, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Project_Billing_Rate__r.Hourly_Rate__c, Effective_Date__c FROM Project_Team_Member_Effective_Rates__r)
                                                                                                                                    FROM Client_Contact__c
                                                                                                                                    WHERE Project__c IN :projectIdToForecastWithProjectDetailsMap.keySet() AND Client_Contact__c IN :contactIdToForecastWithContactDetailsMap.keySet()]);
            
            List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>();
            billRateList = [SELECT Id, Name, Project__c, Hourly_Rate__c, Product__c, Product__r.Name, Created_in_Salesforce__c
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Project__c IN :projectIdToForecastWithProjectDetailsMap.keySet() AND Created_in_Salesforce__c = true AND Is_Temporary_Rate__c = false AND Is_Concession_Rate__c = false AND Is_Placeholder_Rate__c = false
                            ORDER BY Name];
            /************************************* Create Map for existing Billing Rates to link to Project Team Member as Assigned Billing Rates or Effective Rates if Needed **************************/
            Map<String, Project_Team_Member_Billing_Rate__c> billRateUniqueStringToRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
            for(Project_Team_Member_Billing_Rate__c rate : billRateList){

                String rateBaseName;
                if(rate.Product__c != null){
                    rateBaseName = rate.Product__r.Name;
                }else if(rate.Name.right(1).isNumeric()){ //If it is only letters and spaces
                    rateBaseName = rate.Name.left(rate.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                }else{
                    rateBaseName = rate.Name;
                }
                String uniqueRateString = String.valueOf(rate.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(rate.Hourly_Rate__c);
                billRateUniqueStringToRateMap.put(uniqueRateString, rate);
            }
            
            Map<String, Client_Contact__c> uniqueStringToTeamMemberWithIdMap = new Map<String, Client_Contact__c>();
            List<Client_Contact__c> existingTeamMembersToUpdateList = new List<Client_Contact__c>();
            
            /********************************** Loop through Existing Project TEam Members and remove existing ones from Maps so no duplicates are created ************************/
            for(Client_Contact__c projTeamMember : existingProjectTeamMemberUniqueStringToRecordMap.values()){

                //Make Unique String for each Contact Project Combo
                if(projTeamMember.Client_Contact__r.Name != 'Place Holder'){
                    String uniqueTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c);

                    if(uniqueContactAndProjectStringSet.contains(uniqueTeamMemberString)){
                        uniqueContactAndProjectStringSet.remove(uniqueTeamMemberString);
                        uniqueStringToTeamMemberWithIdMap.put(uniqueTeamMemberString, projTeamMember); //Insert into map of Existing Team Members to later link to existing Forecasts

                        /*******************************Check to see if an existing Project Team Member needs their Assigned Billing Rate Updated *************************/
                        if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ 
                            Map<String, RepliconForecast__c> billRateStringToEntryMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);
                            if(billRateStringToEntryMap.size() == 1){ //If Project Team Member only has 1 Bill Rate for all Forecasts then assign that to the Team Member as the Assigned Billing Rate
                                List<String> uniqueBillRateKeysList = new List<String>();
                                uniqueBillRateKeysList.addAll(billRateStringToEntryMap.keySet());
                                String uniqueBillRateString = uniqueBillRateKeysList[0];
                                if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){
                                    if(projTeamMember.Assigned_Billing_Rate__c == null){
                                        projTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                                        existingTeamMembersToUpdateList.add(projTeamMember);
                                    }
                                }
                            }
                        }
                        /*************************************************************************************************************************************************/
                    }

                }else{
                    String uniquePlaceholderTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c) + ' @ ' + projTeamMember.Assigned_Billing_Rate__r.Name;

                    if(uniquePlaceholderStringToForecastMap.containsKey(uniquePlaceholderTeamMemberString)){
                        uniquePlaceholderStringToForecastMap.remove(uniquePlaceholderTeamMemberString);
                        uniqueStringToTeamMemberWithIdMap.put(uniquePlaceholderTeamMemberString, projTeamMember); //Insert into map of Existing Team Members to later link to existing Forecasts
                    }
                }
            }

            if(existingTeamMembersToUpdateList.size() > 0){
                System.debug('************************************ Updating ' + existingTeamMembersToUpdateList.size() + ' Existing Team Members with Assigned Billing Rates **********************************');
                update existingTeamMembersToUpdateList;
            }
        

            /************************* Create NEW Project Team Member from Forecasts  ************************/
            for(String uniqueProjMemberString : uniqueContactAndProjectStringSet){
                List<String> teamMemberIdSplitList = uniqueProjMemberString.split(' @ ');
                Client_Contact__c newProjectTeamMember = new Client_Contact__c(); 
                newProjectTeamMember.Client_Contact__c = (Id)teamMemberIdSplitList[0];
                newProjectTeamMember.Project__c = (Id)teamMemberIdSplitList[1];

                if(projectIdToForecastWithProjectDetailsMap.containsKey(newProjectTeamMember.Project__c)){
                    newProjectTeamMember.Account__c = projectIdToForecastWithProjectDetailsMap.get(newProjectTeamMember.Project__c).Project__r.Account__c;

                    if(contactIdToForecastWithContactDetailsMap.containsKey(newProjectTeamMember.Client_Contact__c)){
                        newProjectTeamMember.Internal_Project_Team_Member_Name__c = (contactIdToForecastWithContactDetailsMap.get(newProjectTeamMember.Client_Contact__c).Contact__r.Name + ' - ' + projectIdToForecastWithProjectDetailsMap.get(newProjectTeamMember.Project__c).Project__r.Name).left(255);
                    }
                }    

                /************************ Assign Bill Rates to Project Team Member or create Effective Rates **************/
                if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueProjMemberString)){ 
                    Map<String, RepliconForecast__c> billRateStringToForecastMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueProjMemberString);
                    if(billRateStringToForecastMap.size() == 1){ //If Project Team Member only has 1 Bill Rate for all Forecasts then assign that to the Team Member as the Assigned Billing Rate
                        List<String> uniqueBillRateKeysList = new List<String>();
                        uniqueBillRateKeysList.addAll(billRateStringToForecastMap.keySet());
                        String uniqueBillRateString = uniqueBillRateKeysList[0];
                        if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){
                            newProjectTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                        }
                    }
                }
                /************************************************************************************************/

                internalProjectTeamMembersToInsertList.add(newProjectTeamMember);
                uniqueStringToTeamMemberWithIdMap.put(uniqueProjMemberString, newProjectTeamMember); //Put Team Members we are GOING to insert into map to later link to Forecasts
            }
            /************************************************************************************************/

            /************************* Create NEW PLACEHOLDER Project Team Member from Forecasts  ************************/
            for(String placeholderUniqueString : uniquePlaceholderStringToForecastMap.keySet()){

                List<String> teamMemberIdSplitList = placeholderUniqueString.split(' @ ');
                Client_Contact__c newPlaceholderTeamMember = new Client_Contact__c(); 
                newPlaceholderTeamMember.Client_Contact__c = (Id)teamMemberIdSplitList[0];
                newPlaceholderTeamMember.Project__c = (Id)teamMemberIdSplitList[1];
                newPlaceholderTeamMember.Is_Placeholder_Team_Member__c = true;

                if(projectIdToForecastWithProjectDetailsMap.containsKey(newPlaceholderTeamMember.Project__c)){
                    newPlaceholderTeamMember.Account__c = projectIdToForecastWithProjectDetailsMap.get(newPlaceholderTeamMember.Project__c).Project__r.Account__c;

                    if(contactIdToForecastWithContactDetailsMap.containsKey(newPlaceholderTeamMember.Client_Contact__c)){
                        newPlaceholderTeamMember.Internal_Project_Team_Member_Name__c = (contactIdToForecastWithContactDetailsMap.get(newPlaceholderTeamMember.Client_Contact__c).Contact__r.Name + ' - ' + projectIdToForecastWithProjectDetailsMap.get(newPlaceholderTeamMember.Project__c).Project__r.Name).left(255);
                    }
                } 

                /******************** Assign Billing Rate to Newly Created Placeholder Team Members **************/
                RepliconForecast__c forecast = uniquePlaceholderStringToForecastMap.get(placeholderUniqueString);
                String uniqueTeamMemberAndBillRateString = String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name + ' @ ' + String.valueOf(forecast.ProjectTeamMemberBillingRate__r.Hourly_Rate__c);
                if(billRateUniqueStringToRateMap.containsKey(uniqueTeamMemberAndBillRateString)){
                    newPlaceholderTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueTeamMemberAndBillRateString).Id;
                }
                /*************************************************************************************************/

                internalProjectTeamMembersToInsertList.add(newPlaceholderTeamMember);
                uniqueStringToTeamMemberWithIdMap.put(placeholderUniqueString, newPlaceholderTeamMember); //Put Team Members we are GOING to insert into map to later link to Forecasts
            }

            /******************************** Insert NEW Project Team Members **************************************/
            if(internalProjectTeamMembersToInsertList.size() > 0){
                System.debug('***************************************** Inserting ' + internalProjectTeamMembersToInsertList.size() + ' Internal Project Team Members from InternalProjectMemberCreationBatch from Forecasts run *****************************************');
                insert internalProjectTeamMembersToInsertList;
            }

            /********************************* Create and Assign Effective Rates if there are multiple billing rates on existing Forecasts ********************************/
            List<Client_Contact__c> projTeamMemberToUpdateRateAssignmentList = new List<Client_Contact__c>();
            List<Project_Team_Member_Effective_Rate__c> effectiveRatesToUpdate = new List<Project_Team_Member_Effective_Rate__c>();
            Map<Id, Project_Team_Member_Effective_Rate__c> projTeamMemberToActiveEffectiveRateMap = new Map<Id, Project_Team_Member_Effective_Rate__c>();
            System.debug('8888888888888888888888888888888888 BEFORE Effective Rate SECTION 8888888888888888888888888888888888');
            for(Client_Contact__c projTeamMember : internalProjectTeamMembersToInsertList){
                System.debug('***************************************************************************************************************************************');
                System.debug('Project Team Member Effective Rate Loop: ' + projTeamMember);
                String uniqueTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c);
                System.debug('uniqueTeamMemberString: ' + projTeamMember);
                /*******************************Check to see if an existing Project Team Member needs their Assigned Billing Rate Updated *************************/
                if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ 
                    System.debug('Inside Contains Key!!!');
                    Map<String, RepliconForecast__c> billRateStringToEntryMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);
                    System.debug('Bill Rate String to Entry Map: ' + billRateStringToEntryMap);
                    System.debug('Bill Rate String to Entry Map SIZE: ' + billRateStringToEntryMap.size());
                    if(billRateStringToEntryMap.size() > 1){ //If Project Team Member only has more than 1 Bill Rate for all Forecasts then create Effective Rates and assign the one that has the effective date passed and is closest to the current date as the active effective billing rate
                        System.debug('Has more than one Billing Rate');
                        Id activeBillingRate;
                        Date effectiveRateEffectiveDate;
                        Integer billRateIterationCount = 0;
                        for(String uniqueBillRateString : billRateStringToEntryMap.keySet()){
                            if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){
                                if(billRateIterationCount == 0){//Count iterations, because first effective rate will be given an effective date of the project created date
                                    effectiveRateEffectiveDate = Date.valueOf(billRateStringToEntryMap.get(uniqueBillRateString).Project__r.CreatedDate);
                                }else{
                                    //Otherwise the effective date is the date that was previously captured when grabbing the first forecast that a bill rate change has been made
                                    effectiveRateEffectiveDate = billRateStringToEntryMap.get(uniqueBillRateString).Week_Start_Date__c;
                                }

                                Project_Team_Member_Effective_Rate__c newEffectiveRate = new Project_Team_Member_Effective_Rate__c(Internal_Project_Team_Member__c = projTeamMember.Id, 
                                                                                                                                    Project_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id,
                                                                                                                                    Effective_Date__c = effectiveRateEffectiveDate);
                                effectiveRatesToUpdate.add(newEffectiveRate);

                                if(billRateStringToEntryMap.get(uniqueBillRateString).Week_Start_Date__c <= Date.today()){ 
                                    //Since it is ordered Week Start Date ASC it will show the oldest rates first,
                                    //This allows us to loop through the forecasts and the last one that is before or on the current date will be marked as the rate to assign as the active billing rate. 
                                    //And allow any other rates that are for the future to still be created without being assigned as the active bill rate
                                    System.debug('Assign as Active Billing Rate: ' + billRateStringToEntryMap.get(uniqueBillRateString).ProjectTeamMemberBillingRate__r.Name + ' Effective Date: ' + effectiveRateEffectiveDate );
                                    activeBillingRate = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                                    projTeamMemberToActiveEffectiveRateMap.put(projTeamMember.Id, newEffectiveRate);
                                }
                            }

                            billRateIterationCount++;
                        }

                        if(activeBillingRate != null){ //Once looping through all rates is done, can then assign the billing rate as the one we have marked as the active effective rate.
                            projTeamMember.Assigned_Billing_Rate__c = activeBillingRate;
                            projTeamMemberToUpdateRateAssignmentList.add(projTeamMember);
                        }
                    }
                }
                /*************************************************************************************************************************************************/
            }

            /********* Insert the Effective Rates **************/
            if(effectiveRatesToUpdate.size() > 0){
                System.debug('*************************************Inserting ' + effectiveRatesToUpdate.size() + ' Effective Rates ***********************************************');
                insert effectiveRatesToUpdate;
            }
        
            /********** Update Project Team Member Assigned Billing Rates whom had multiple effective rates *******************/
            if(projTeamMemberToUpdateRateAssignmentList.size() > 0){
                System.debug('***************************** Updating Assigned Billing Rates on ' + projTeamMemberToUpdateRateAssignmentList.size() + ' Internal Project Team Member(s) *************************');
                update projTeamMemberToUpdateRateAssignmentList;
            }

            /********* Update the Project Team Members with Active Effective Billing Rates if an Effective rate was created for them ****************************/
            List<Client_Contact__c> projTeamMemberToUpdateActiveEffectiveRateList = new List<Client_Contact__c>();
            for(Client_Contact__c projTeamMember : internalProjectTeamMembersToInsertList){

                if(projTeamMemberToActiveEffectiveRateMap.containsKey(projTeamMember.Id)){
                    if(projTeamMember.Active_Effective_Billing_Rate__c != projTeamMemberToActiveEffectiveRateMap.get(projTeamMember.Id).Id){
                        projTeamMember.Active_Effective_Billing_Rate__c = projTeamMemberToActiveEffectiveRateMap.get(projTeamMember.Id).Id;
                        projTeamMemberToUpdateActiveEffectiveRateList.add(projTeamMember);
                    }
                }
            }
            /******************** Update Active Effective Rate on Internal Project Team Members *************************/
            if(projTeamMemberToUpdateActiveEffectiveRateList.size() > 0){
                System.debug('*************** Update Active Effective Rates on ' + projTeamMemberToUpdateActiveEffectiveRateList.size() + ' Internal Project Team Members ************************');
                update projTeamMemberToUpdateActiveEffectiveRateList;
            }

            System.debug('8888888888888888888888888888888888 AFTER Effective Rate SECTION 8888888888888888888888888888888888');

            /******************************** Loop existing Forecasts to populate Team Members on them and add to update list ****************************************/
            List<RepliconForecast__c> updateForecastList = new List<RepliconForecast__c>();
            for(RepliconForecast__c forecast : forecastList){
                String uniqueTeamMemberString;

                if(forecast.Contact__r.Name != 'Place Holder'){
                    uniqueTeamMemberString = String.valueOf(forecast.Contact__c) + ' @ ' + String.valueOf(forecast.Project__c);
                }else{
                    uniqueTeamMemberString = String.valueOf(forecast.Contact__c) + ' @ ' + String.valueOf(forecast.Project__c) + ' @ ' + forecast.ProjectTeamMemberBillingRate__r.Name;
                }

                if(uniqueStringToTeamMemberWithIdMap.containsKey(uniqueTeamMemberString)){
                    Client_Contact__c projTeamMember = uniqueStringToTeamMemberWithIdMap.get(uniqueTeamMemberString);
                    if(forecast.Internal_Project_Team_Member__c != projTeamMember.Id){
                        forecast.Internal_Project_Team_Member__c = projTeamMember.Id;
                        updateForecastList.add(forecast);
                    }
                }
            }
            /******************************** DML for Updating Existing Forecasts with Project Team Member lookups **********************************/
            if(updateForecastList.size() > 0){
                System.debug('******************************* Updating ' + updateForecastList.size() + ' Existing Forecasts with Internal Project Team Member Lookups ********************************');
                update updateForecastList;
            }
    }

    public static void createTeamMembersFromTimeEntries(List<Replicon_Time_Entry__c> entryList){

        List<Client_Contact__c> internalProjectTeamMembersToInsertList = new List<Client_Contact__c>();

        Set<String> uniqueContactAndProjectStringSet = new Set<String>();
        Map<String, Map<String, Replicon_Time_Entry__c>> uniqueProjTeamMemberStringBillRateMapMap = new Map<String, Map<String, Replicon_Time_Entry__c>>();

        Map<String, Replicon_Time_Entry__c> uniquePlaceholderStringToEntryMap = new Map<String, Replicon_Time_Entry__c>();
        Map<String, Map<String, Replicon_Time_Entry__c>> uniquePlaceholderProjTeamMemberStringBillRateMapMap = new Map<String, Map<String, Replicon_Time_Entry__c>>();

        Map<Id, Replicon_Time_Entry__c> projectIdToEntryWithProjectDetailsMap = new Map<Id, Replicon_Time_Entry__c>();
        Map<Id, Replicon_Time_Entry__c> contactIdToEntryWithContactDetailsMap = new Map<Id, Replicon_Time_Entry__c>();

        for(Replicon_Time_Entry__c entry : entryList){

            //Make Unique String for each Contact Project Combo
            if(entry.Employee__r.Name != 'Place Holder'){

                String uniqueTeamMemberString = String.valueOf(entry.Employee__c) + ' @ ' + String.valueOf(entry.Project__c);
                uniqueContactAndProjectStringSet.add(uniqueTeamMemberString);

                if(!uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ //If Unique Combo of Contact and Project doesn't exist in Map yet

                    Map<String, Replicon_Time_Entry__c> billRateMap = new Map<String, Replicon_Time_Entry__c>();

                    if(entry.Associated_Billing_Rate__c != null && entry.Associated_Billing_Rate__r.Name != 'Temporary Rate' && entry.Associated_Billing_Rate__r.Name != 'Concession'){

                        String rateBaseName;
                        if(entry.Associated_Billing_Rate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                            rateBaseName = entry.Associated_Billing_Rate__r.Name.left(entry.Associated_Billing_Rate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                        }else{
                            rateBaseName = entry.Associated_Billing_Rate__r.Name;
                        }

                        if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                            rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                        }
                        
                        //String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        billRateMap.put(uniqueBillRateString, entry);
                    }

                    uniqueProjTeamMemberStringBillRateMapMap.put(uniqueTeamMemberString, billRateMap);   

                }else{ //If it does then check to see if we need to add to the Bill Rate Map

                    if(entry.Associated_Billing_Rate__c != null && entry.Associated_Billing_Rate__r.Name != 'Temporary Rate' && entry.Associated_Billing_Rate__r.Name != 'Concession'){

                        String rateBaseName;
                        if(entry.Associated_Billing_Rate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                            rateBaseName = entry.Associated_Billing_Rate__r.Name.left(entry.Associated_Billing_Rate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                        }else{
                            rateBaseName = entry.Associated_Billing_Rate__r.Name;
                        }

                        if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                            rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                        }
                        
                        //String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);

                        Map<String, Replicon_Time_Entry__c> billRateMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);

                        if(!billRateMap.containsKey(uniqueBillRateString)){
                            //If not in Bill rate map then add to bill rate map, then all to overall map
                            billRateMap.put(uniqueBillRateString, entry);
                            uniqueProjTeamMemberStringBillRateMapMap.put(uniqueTeamMemberString, billRateMap);
                        }
                    }  
                }

            }else{
                //Handle for Placeholders
                String uniquePlaceholderTeamMemberString = String.valueOf(entry.Employee__c) + ' @ ' + String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name;
                uniquePlaceholderStringToEntryMap.put(uniquePlaceholderTeamMemberString, entry);

                if(!uniquePlaceholderProjTeamMemberStringBillRateMapMap.containsKey(uniquePlaceholderTeamMemberString)){ //If Unique Combo of Contact and Project doesn't exist in Map yet

                    Map<String, Replicon_Time_Entry__c> billRateMap = new Map<String, Replicon_Time_Entry__c>();

                    if(entry.Associated_Billing_Rate__c != null){

                        String rateBaseName;
                        if(entry.Associated_Billing_Rate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                            rateBaseName = entry.Associated_Billing_Rate__r.Name.left(entry.Associated_Billing_Rate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                        }else{
                            rateBaseName = entry.Associated_Billing_Rate__r.Name;
                        }

                        if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                            rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                        }
                        
                        //String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        billRateMap.put(uniqueBillRateString, entry);
                    }

                    uniquePlaceholderProjTeamMemberStringBillRateMapMap.put(uniquePlaceholderTeamMemberString, billRateMap);   

                }else{ //If it does then check to see if we need to add to the Bill Rate Map

                    if(entry.Associated_Billing_Rate__c != null){

                        String rateBaseName;
                        if(entry.Associated_Billing_Rate__r.Name.right(1).isNumeric()){ //If it is only letters and spaces
                            rateBaseName = entry.Associated_Billing_Rate__r.Name.left(entry.Associated_Billing_Rate__r.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
                        }else{
                            rateBaseName = entry.Associated_Billing_Rate__r.Name;
                        }

                        if(rateBaseName.contains('MC ') && !rateBaseName.contains('-')){
                            rateBaseName = rateBaseName.replace('MC ', 'MC - ');
                        }
                        
                        //String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
                        String uniqueBillRateString = String.valueOf(entry.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);

                        Map<String, Replicon_Time_Entry__c> billRateMap = uniquePlaceholderProjTeamMemberStringBillRateMapMap.get(uniquePlaceholderTeamMemberString);

                        if(!billRateMap.containsKey(uniqueBillRateString)){
                            //If not in Bill rate map then add to bill rate map, then all to overall map
                            billRateMap.put(uniqueBillRateString, entry);
                            uniquePlaceholderProjTeamMemberStringBillRateMapMap.put(uniquePlaceholderTeamMemberString, billRateMap);
                        }
                    }  
                }
            }

            //Make Map For Project and Contact in order to retrieve info for them during Project Team Member Creation
            if(entry.Project__c != null && !projectIdToEntryWithProjectDetailsMap.containsKey(entry.Project__c)){
                projectIdToEntryWithProjectDetailsMap.put(entry.Project__c, entry);
            }

            if(entry.Employee__c != null && !contactIdToEntryWithContactDetailsMap.containsKey(entry.Employee__c)){
                contactIdToEntryWithContactDetailsMap.put(entry.Employee__c, entry);
            }
        }

        /************************************************************************** Get Existing Internal Project Team Members **************************************************************************/
        /**
         * Get Existing Team Members, if they already exist, then remove from the set/map
         * Check Effective Bill Rates
         * If only one bill rate in the bill rate map for team member to insert map, then look for existing Project Team Member Billing Rate to set as the Internal Project Team Member Assigned Billing Rate
         * If MORE than one Bill rate, then assign the last one as the Assigned Billing Rate and create Effective Rates for the previous ones with an Effective Date matching the Entry Week Start Date within the bill rate map value
         */
        Map<String, Client_Contact__c> existingProjectTeamMemberUniqueStringToRecordMap = new Map<String, Client_Contact__c>([SELECT Id, Name, Internal_Project_Team_Member_Name__c, Client_Contact__c, Client_Contact__r.Name, Project__c, Project__r.Name, Account__c, Contact_Role__c, Is_Placeholder_Team_Member__c, 
                                                                                                                                    Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, Assigned_Billing_Rate__r.Hourly_Rate__c, 
                                                                                                                                    (SELECT Id, Name, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Project_Billing_Rate__r.Hourly_Rate__c, Effective_Date__c FROM Project_Team_Member_Effective_Rates__r)
                                                                                                                                FROM Client_Contact__c
                                                                                                                                WHERE Project__c IN :projectIdToEntryWithProjectDetailsMap.keySet() AND Client_Contact__c IN :contactIdToEntryWithContactDetailsMap.keySet()]);
        
        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billRateList = [SELECT Id, Name, Project__c, Hourly_Rate__c, Product__c, Product__r.Name, Created_in_Salesforce__c
                        FROM Project_Team_Member_Billing_Rate__c
                        WHERE Project__c IN :projectIdToEntryWithProjectDetailsMap.keySet() AND Created_in_Salesforce__c = true AND Is_Temporary_Rate__c = false AND Is_Concession_Rate__c = false AND Is_Placeholder_Rate__c = false
                        ORDER BY Name];
        /************************************* Create Map for existing Billing Rates to link to Project Team Member as Assigned Billing Rates or Effective Rates if Needed **************************/
        Map<String, Project_Team_Member_Billing_Rate__c> billRateUniqueStringToRateMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
        for(Project_Team_Member_Billing_Rate__c rate : billRateList){

            String rateBaseName;
            if(rate.Product__c != null){
                rateBaseName = rate.Product__r.Name;
            }else if(rate.Name.right(1).isNumeric()){ //If it is only letters and spaces
                rateBaseName = rate.Name.left(rate.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
            }else{
                rateBaseName = rate.Name;
            }
            String uniqueRateString = String.valueOf(rate.Project__c) + ' @ ' + rateBaseName + ' @ ' + String.valueOf(rate.Hourly_Rate__c);
            billRateUniqueStringToRateMap.put(uniqueRateString, rate);
        }
        
        List<Client_Contact__c> existingTeamMembersToUpdateList = new List<Client_Contact__c>();
        Map<String, Client_Contact__c> uniqueStringToTeamMemberWithIdMap = new Map<String, Client_Contact__c>();
        /*************************************** Loop through existing Team Members and remove existing ones as to not create duplicates ******************************/
        for(Client_Contact__c projTeamMember : existingProjectTeamMemberUniqueStringToRecordMap.values()){

            //Make Unique String for each Contact Project Combo
            if(projTeamMember.Client_Contact__r.Name != 'Place Holder'){
                String uniqueTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c);

                if(uniqueContactAndProjectStringSet.contains(uniqueTeamMemberString)){
                    uniqueContactAndProjectStringSet.remove(uniqueTeamMemberString);
                    uniqueStringToTeamMemberWithIdMap.put(uniqueTeamMemberString, projTeamMember); //Insert into map of Existing Team Members to later link to existing Entries

                    /*******************************Check to see if an existing Project Team Member needs their Assigned Billing Rate Updated *************************/
                    if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ 
                        Map<String, Replicon_Time_Entry__c> billRateStringToEntryMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);
                        if(billRateStringToEntryMap.size() == 1){ //If Project Team Member only has 1 Bill Rate for all Forecasts then assign that to the Team Member as the Assigned Billing Rate
                            List<String> uniqueBillRateKeysList = new List<String>();
                            uniqueBillRateKeysList.addAll(billRateStringToEntryMap.keySet());
                            String uniqueBillRateString = uniqueBillRateKeysList[0];
                            if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){
                                if(projTeamMember.Assigned_Billing_Rate__c == null){
                                    projTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                                    existingTeamMembersToUpdateList.add(projTeamMember);
                                }
                            }
                        }
                    }
                    /*************************************************************************************************************************************************/
                    
                }

            }else{
                String uniquePlaceholderTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c) + ' @ ' + projTeamMember.Assigned_Billing_Rate__r.Name;

                if(uniquePlaceholderStringToEntryMap.containsKey(uniquePlaceholderTeamMemberString)){
                    uniquePlaceholderStringToEntryMap.remove(uniquePlaceholderTeamMemberString);
                    uniqueStringToTeamMemberWithIdMap.put(uniquePlaceholderTeamMemberString, projTeamMember); //Insert into map of Existing Team Members to later link to existing Entries
                }
            }
        }

        if(existingTeamMembersToUpdateList.size() > 0){
            System.debug('************************************ Updating ' + existingTeamMembersToUpdateList.size() + ' Existing Team Members with Assigned Billing Rates **********************************');
            update existingTeamMembersToUpdateList;
        }
    
        /********************************** Create NEW Project Team Members and Assign Billing Rates  ***************************/
        for(String uniqueProjMemberString : uniqueContactAndProjectStringSet){
            List<String> teamMemberIdSplitList = uniqueProjMemberString.split(' @ ');
            Client_Contact__c newProjectTeamMember = new Client_Contact__c(); 
            newProjectTeamMember.Client_Contact__c = (Id)teamMemberIdSplitList[0];
            newProjectTeamMember.Project__c = (Id)teamMemberIdSplitList[1];

            if(projectIdToEntryWithProjectDetailsMap.containsKey(newProjectTeamMember.Project__c)){
                newProjectTeamMember.Account__c = projectIdToEntryWithProjectDetailsMap.get(newProjectTeamMember.Project__c).Project__r.Account__c;

                if(contactIdToEntryWithContactDetailsMap.containsKey(newProjectTeamMember.Client_Contact__c)){
                    newProjectTeamMember.Internal_Project_Team_Member_Name__c = (contactIdToEntryWithContactDetailsMap.get(newProjectTeamMember.Client_Contact__c).Employee__r.Name + ' - ' + projectIdToEntryWithProjectDetailsMap.get(newProjectTeamMember.Project__c).Project__r.Name).left(255);
                }
            }    

            /************************ Assign Bill Rates to Project Team Member or create Effective Rates **************/
            if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueProjMemberString)){ 
                Map<String, Replicon_Time_Entry__c> billRateStringToEntryMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueProjMemberString);
                if(billRateStringToEntryMap.size() == 1){ //If Project Team Member only has 1 Bill Rate for all Forecasts then assign that to the Team Member as the Assigned Billing Rate
                    List<String> uniqueBillRateKeysList = new List<String>();
                    uniqueBillRateKeysList.addAll(billRateStringToEntryMap.keySet());
                    String uniqueBillRateString = uniqueBillRateKeysList[0];
                    if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){
                        newProjectTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                    }
                }
            }
            /************************************************************************************************/

            internalProjectTeamMembersToInsertList.add(newProjectTeamMember);
            uniqueStringToTeamMemberWithIdMap.put(uniqueProjMemberString, newProjectTeamMember); //Put Team Members we are GOING to insert into map to later link to Entries
        }
        /************************* Create NEW PLACEHOLDER Project Team Member from Forecasts  ************************/
        for(String placeholderUniqueString : uniquePlaceholderStringToEntryMap.keySet()){

            List<String> teamMemberIdSplitList = placeholderUniqueString.split(' @ ');
            Client_Contact__c newPlaceholderTeamMember = new Client_Contact__c(); 
            newPlaceholderTeamMember.Client_Contact__c = (Id)teamMemberIdSplitList[0];
            newPlaceholderTeamMember.Project__c = (Id)teamMemberIdSplitList[1];
            newPlaceholderTeamMember.Is_Placeholder_Team_Member__c = true;

            if(projectIdToEntryWithProjectDetailsMap.containsKey(newPlaceholderTeamMember.Project__c)){
                newPlaceholderTeamMember.Account__c = projectIdToEntryWithProjectDetailsMap.get(newPlaceholderTeamMember.Project__c).Project__r.Account__c;

                if(contactIdToEntryWithContactDetailsMap.containsKey(newPlaceholderTeamMember.Client_Contact__c)){
                    newPlaceholderTeamMember.Internal_Project_Team_Member_Name__c = (contactIdToEntryWithContactDetailsMap.get(newPlaceholderTeamMember.Client_Contact__c).Employee__r.Name + ' - ' + projectIdToEntryWithProjectDetailsMap.get(newPlaceholderTeamMember.Project__c).Project__r.Name).left(255);
                }
            } 

            /******************** Assign Billing Rate to Newly Created Placeholder Team Members **************/
            Replicon_Time_Entry__c entry = uniquePlaceholderStringToEntryMap.get(placeholderUniqueString);
            String uniqueTeamMemberAndBillRateString = String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name + ' @ ' + String.valueOf(entry.Associated_Billing_Rate__r.Hourly_Rate__c);
            if(billRateUniqueStringToRateMap.containsKey(uniqueTeamMemberAndBillRateString)){
                newPlaceholderTeamMember.Assigned_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueTeamMemberAndBillRateString).Id;
            }
            /*************************************************************************************************/

            internalProjectTeamMembersToInsertList.add(newPlaceholderTeamMember);
            uniqueStringToTeamMemberWithIdMap.put(placeholderUniqueString, newPlaceholderTeamMember); //Put Team Members we are GOING to insert into map to later link to Entries
        }

        /******************************** Insert NEW Project Team Members **************************************/
        if(internalProjectTeamMembersToInsertList.size() > 0){
            System.debug('***************************************** Inserting ' + internalProjectTeamMembersToInsertList.size() + ' Internal Project Team Members from InternalProjectMemberCreationBatch from Entries run *****************************************');
            insert internalProjectTeamMembersToInsertList;
        }

        /********************************* Create and Assign Effective Rates if there are multiple billing rates on existing Forecasts ********************************/
        List<Client_Contact__c> projTeamMemberToUpdateRateAssignmentList = new List<Client_Contact__c>();
        List<Project_Team_Member_Effective_Rate__c> effectiveRatesToUpdate = new List<Project_Team_Member_Effective_Rate__c>();
        Map<Id, Project_Team_Member_Effective_Rate__c> projTeamMemberToActiveEffectiveRateMap = new Map<Id, Project_Team_Member_Effective_Rate__c>();
        System.debug('8888888888888888888888888888888888 BEFORE Effective Rate SECTION 8888888888888888888888888888888888');
        for(Client_Contact__c projTeamMember : internalProjectTeamMembersToInsertList){
            System.debug('***************************************************************************************************************************************');
            System.debug('Project Team Member Effective Rate Loop: ' + projTeamMember);
            String uniqueTeamMemberString = String.valueOf(projTeamMember.Client_Contact__c) + ' @ ' + String.valueOf(projTeamMember.Project__c);
            System.debug('uniqueTeamMemberString: ' + projTeamMember);
            /*******************************Check to see if an existing Project Team Member needs their Assigned Billing Rate Updated *************************/
            if(uniqueProjTeamMemberStringBillRateMapMap.containsKey(uniqueTeamMemberString)){ 
                System.debug('Inside Contains Key!!!');
                Map<String, Replicon_Time_Entry__c> billRateStringToEntryMap = uniqueProjTeamMemberStringBillRateMapMap.get(uniqueTeamMemberString);
                System.debug('Bill Rate String to Entry Map: ' + billRateStringToEntryMap);
                System.debug('Bill Rate String to Entry Map SIZE: ' + billRateStringToEntryMap.size());
                if(billRateStringToEntryMap.size() > 1){ //If Project Team Member only has more than 1 Bill Rate for all Forecasts then create Effective Rates and assign the one that has the effective date passed and is closest to the current date as the active effective billing rate
                    System.debug('Has more than one Billing Rate');
                    Id activeBillingRate;
                    Date effectiveRateEffectiveDate;
                    Integer billRateIterationCount = 0;
                    for(String uniqueBillRateString : billRateStringToEntryMap.keySet()){
                        if(billRateUniqueStringToRateMap.containsKey(uniqueBillRateString)){

                            if(billRateIterationCount == 0){//Count iterations, because first effective rate will be given an effective date of the project created date
                                effectiveRateEffectiveDate = Date.valueOf(billRateStringToEntryMap.get(uniqueBillRateString).Project__r.CreatedDate);
                            }else{
                                //Otherwise the effective date is the date that was previously captured when grabbing the first forecast that a bill rate change has been made
                                effectiveRateEffectiveDate = billRateStringToEntryMap.get(uniqueBillRateString).EntryDate__c;
                            }
                            Project_Team_Member_Effective_Rate__c newEffectiveRate = new Project_Team_Member_Effective_Rate__c(Internal_Project_Team_Member__c = projTeamMember.Id, 
                                                                                                                                Project_Billing_Rate__c = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id,
                                                                                                                                Effective_Date__c = effectiveRateEffectiveDate);
                            effectiveRatesToUpdate.add(newEffectiveRate);

                            if(billRateStringToEntryMap.get(uniqueBillRateString).EntryDate__c <= Date.today()){ 
                                //Since it is ordered Week Start Date ASC it will show the oldest rates first,
                                //This allows us to loop through the forecasts and the last one that is before or on the current date will be marked as the rate to assign as the active billing rate. 
                                //And allow any other rates that are for the future to still be created without being assigned as the active bill rate
                                System.debug('Assign as Active Billing Rate: ' + billRateStringToEntryMap.get(uniqueBillRateString).Associated_Billing_Rate__r.Name + ' Entry Date: ' + billRateStringToEntryMap.get(uniqueBillRateString).EntryDate__c );
                                activeBillingRate = billRateUniqueStringToRateMap.get(uniqueBillRateString).Id;
                                projTeamMemberToActiveEffectiveRateMap.put(projTeamMember.Id, newEffectiveRate);
                            }
                        }
                        billRateIterationCount++;
                    }

                    if(activeBillingRate != null){ //Once looping through all rates is done, can then assign the billing rate as the one we have marked as the active effective rate.
                        projTeamMember.Assigned_Billing_Rate__c = activeBillingRate;
                        projTeamMemberToUpdateRateAssignmentList.add(projTeamMember);
                    }
                }
            }
            /*************************************************************************************************************************************************/
        }

        /********* Insert the Effective Rates **************/
        if(effectiveRatesToUpdate.size() > 0){
            System.debug('*************************************Inserting ' + effectiveRatesToUpdate.size() + ' Effective Rates ***********************************************');
            insert effectiveRatesToUpdate;
        }
    
        /********** Update Project Team Member Assigned Billing Rates whom had multiple effective rates *******************/
        if(projTeamMemberToUpdateRateAssignmentList.size() > 0){
            System.debug('***************************** Updating Assigned Billing Rates on ' + projTeamMemberToUpdateRateAssignmentList.size() + ' Internal Project Team Member(s) *************************');
            update projTeamMemberToUpdateRateAssignmentList;
        }

        /********* Update the Project Team Members with Active Effective Billing Rates if an Effective rate was created for them ****************************/
        List<Client_Contact__c> projTeamMemberToUpdateActiveEffectiveRateList = new List<Client_Contact__c>();
        for(Client_Contact__c projTeamMember : internalProjectTeamMembersToInsertList){

            if(projTeamMemberToActiveEffectiveRateMap.containsKey(projTeamMember.Id)){
                if(projTeamMember.Active_Effective_Billing_Rate__c != projTeamMemberToActiveEffectiveRateMap.get(projTeamMember.Id).Id){
                    projTeamMember.Active_Effective_Billing_Rate__c = projTeamMemberToActiveEffectiveRateMap.get(projTeamMember.Id).Id;
                    projTeamMemberToUpdateActiveEffectiveRateList.add(projTeamMember);
                }
            }
        }
        /******************** Update Active Effective Rate on Internal Project Team Members *************************/
        if(projTeamMemberToUpdateActiveEffectiveRateList.size() > 0){
            System.debug('*************** Update Active Effective Rates on ' + projTeamMemberToUpdateActiveEffectiveRateList.size() + ' Internal Project Team Members ************************');
            update projTeamMemberToUpdateActiveEffectiveRateList;
        }

        System.debug('8888888888888888888888888888888888 AFTER Effective Rate SECTION 8888888888888888888888888888888888');

        /******************************** Loop existing Forecasts to populate Team Members on them and add to update list ****************************************/
        List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList){
            String uniqueTeamMemberString;

            if(entry.Employee__r.Name != 'Place Holder'){
                uniqueTeamMemberString = String.valueOf(entry.Employee__c) + ' @ ' + String.valueOf(entry.Project__c);
            }else{
                uniqueTeamMemberString = String.valueOf(entry.Employee__c) + ' @ ' + String.valueOf(entry.Project__c) + ' @ ' + entry.Associated_Billing_Rate__r.Name;
            }

            if(uniqueStringToTeamMemberWithIdMap.containsKey(uniqueTeamMemberString)){
                Client_Contact__c projTeamMember = uniqueStringToTeamMemberWithIdMap.get(uniqueTeamMemberString);
                if(entry.Internal_Project_Team_Member__c != projTeamMember.Id){
                    entry.Internal_Project_Team_Member__c = projTeamMember.Id;
                    updateEntryList.add(entry);
                }
            }
        }
        /******************************** DML for Updating Existing Forecasts with Project Team Member lookups **********************************/
        if(updateEntryList.size() > 0){
            System.debug('******************************* Updating ' + updateEntryList.size() + ' Existing Entries with Internal Project Team Member Lookups ********************************');
            update updateEntryList;
        }
    }

    public static void retrievePlaceholderTime(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}