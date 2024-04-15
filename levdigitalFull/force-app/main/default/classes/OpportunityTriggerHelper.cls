/**
 * Created 6/2/2022 ST
 * 
 * Functionalities:
 *  Create Placeholder Forecasts when an Oppty goes Closed Won
 */

public with sharing class OpportunityTriggerHelper {
    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    public static void createPlaceholderForecastsOnCW(List<Opportunity> opptyList){
        /**
         *  When a Salesforce Opportunity (non-Change Order) goes Closed Won we want to create placeholder forecasts
         *  Forecast 8 weeks with the first starting at 30 days after the Oppty goes Closed Won
         *      To calculate the hours for each forcast it is based off of the size of the Oppty Amount:
         *          0-200,000 = 16 weeks average project duration
         *          200,001 - 500,000 = 24 weeks average project duration
         *          500,000+ = 30 weeks average project duration
         *      Then you take that average project duration and get the average weekly burn rate for the project
         *          Average Burn Rate = Total Oppty Hours / Average Project duration
         *      Then for each week of the 8 placeholder forecast there is a percent of that Average burn Rate that is the hours for that weeks forecasted hours
         *          Week 1: 0.1 * Avg Burn Rate
         *          Week 2: 0.25 * Avg Burn Rate
         *          Week 3: 0.3 * Avg Burn Rate
         *          Week 4: 0.5 * Avg Burn Rate
         *          Week 5: 0.75 * Avg Burn Rate
         *          Week 6: 1 * Avg Burn Rate
         *          Week 7: 1 * Avg Burn Rate
         *          Week 8: 1 * Avg Burn Rate
         * 
         *      For the Billing Rate for these Forecasts we will make a Project Team Member Billing Rate that will have the same rate as the average amount of all the Opportunity Products on the parent Opportunity
         *          Potentially take the total Oppty Amount and divide it by the Oppty Hours
         */

        Map<Id, Opportunity> opptyIdToOpptyMap = new Map<Id, Opportunity>();
        for(Opportunity opp : opptyList){
            opptyIdToOpptyMap.put(opp.Id, opp);
        }

        //Get Forecasts that are on Projects related to Opptys that are coming in.
        List<RepliconForecast__c> existingForecastList = new List<RepliconForecast__c>();
        existingForecastList = [SELECT Id, Name, NotForecasted__c, Kickoff_Placeholder_Forecast__c, EstimatedHours__c, Project__c FROM RepliconForecast__c WHERE Project__r.Opportunity__c IN :opptyIdToOpptyMap.keySet()];

        //Make list of projects with existing Forecasts, in order to exclude these projects from having placeholder forecasts created for them when they already have forecasts for them.
        Set<Id> projectIdWithExistingForecastsSet = new Set<Id>();
        for(RepliconForecast__c forecast : existingForecastList){
            projectIdWithExistingForecastsSet.add(forecast.Project__c);
        }

        List<Project__c> projectList = new List<Project__c>();
        projectList = [SELECT Id, Name, Opportunity__c, Account__r.Name FROM Project__c WHERE Opportunity__c IN :opptyIdToOpptyMap.keySet() AND Opportunity__r.Lev_Opportunity_CO_Hours__c > 0 AND Id NOT IN :projectIdWithExistingForecastsSet AND Account__r.Name != 'ABC Lev Test'];

        Id placeholderContactId = null;
        List<Contact> placeholderContact = new List<Contact>();
        placeholderContact = [SELECT Id, Name, RepliconLoginName__c FROM Contact WHERE RepliconLoginName__c = 'place.holder'];
        if(placeholderContact.size() > 0){
            placeholderContactId = placeholderContact[0].Id;
        }
        
        List<RepliconForecast__c> placeholderForecastsToInsertList = new List<RepliconForecast__c>();
        for(Project__c proj : projectList){
            //Create the 8 Forecasts for each project
            
            //Get Project Average Burn Rate
            Decimal averageProjectDurationInWeeks;
            if(opptyIdToOpptyMap.get(proj.Opportunity__c).Lev_Opportunity_CO_Revenue__c <= 200000){
                //If Opportunity Amount <= $200,000 then Average Project Duration = 16 Weeks
                averageProjectDurationInWeeks = 16;
            }else if(opptyIdToOpptyMap.get(proj.Opportunity__c).Lev_Opportunity_CO_Revenue__c > 500000){
                //If Opportunity Amount > $500,000 then Average Project Duration = 30 Weeks
                averageProjectDurationInWeeks = 30;
            }else{
                //If Opportunity Amount between $200,000 - $500,000 then Average Project Duration = 24 Weeks
                averageProjectDurationInWeeks = 24;
            }
            Decimal averageWeeklyProjectBurnRate = opptyIdToOpptyMap.get(proj.Opportunity__c).Lev_Opportunity_CO_Hours__c / averageProjectDurationInWeeks;

            //Get Date for first Week of PLaceholder Forecasts
            Date thirtyDaysAfterClosedWon = (opptyIdToOpptyMap.get(proj.Opportunity__c).CloseDate).addDays(30);
            Date thirtyDaysAfterCWSunday = thirtyDaysAfterClosedWon.toStartOfWeek();
            
            //Get Average Billing Rate of the Project
            Decimal projectAverageBillingRate = (opptyIdToOpptyMap.get(proj.Opportunity__c).Lev_Opportunity_CO_Revenue__c / opptyIdToOpptyMap.get(proj.Opportunity__c).Lev_Opportunity_CO_Hours__c).setScale(2);
            
            //Create Project Team Member for Placeholder Contact for the Project to associate with the Project Team Member Billing Rate
            /*Project_Team_Member__c placeholderTeamMember = new Project_Team_Member__c(Name = 'Placeholder - ' + (proj.Name).left(60), Employee__c = placeholderContactId);
            insert placeholderTeamMember;*/

            //Create Project Team Member Billing Rate with Average Rate of Oppty Products
            Project_Team_Member_Billing_Rate__c placeholderProjBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Average Project Bill Rate', Currency__c = 'USD', Project__c = proj.Id,
                                                                                                                        Replicon_URI__c = 'Average Project Bill Rate - ' + proj.Name, Hourly_Rate__c = projectAverageBillingRate);
            insert placeholderProjBillRate;

            //Create Project Team Member for Placeholder Contact for the Project to associate with the Project Team Member Billing Rate Horizon Update ST 6.6.23
            /*Client_Contact__c placeholderTeamMemberCC = new Client_Contact__c(Internal_Project_Team_Member_Name__c = 'Placeholder - ' + (proj.Name).left(225), Client_Contact__c = placeholderContactId, Assigned_Billing_Rate__c = placeholderProjBillRate.Id, Project__c = proj.Id);
            insert placeholderTeamMemberCC;*/

            for(Integer i = 0; i < 8; i++){
                Decimal forecastedHours;
                Integer daysToAdd = 7 * i;
                Date weekStartDate = thirtyDaysAfterCWSunday.addDays(daysToAdd);
                String placeholderForecastName = ('Placeholder Forecast Week #' + String.valueOf(i+1) + ' ' + proj.Name).left(80);

                switch on i {
                    when 0 {
                        forecastedHours = (averageWeeklyProjectBurnRate * 0.1).setScale(2);
                    } 
                    when 1 {
                        forecastedHours = (averageWeeklyProjectBurnRate * 0.25).setScale(2);
                    } 
                    when 2 {
                        forecastedHours = (averageWeeklyProjectBurnRate * 0.3).setScale(2);
                    } 
                    when 3 {
                        forecastedHours = (averageWeeklyProjectBurnRate * 0.5).setScale(2);
                    } 
                    when 4{
                        forecastedHours = (averageWeeklyProjectBurnRate * 0.75).setScale(2);
                    } 
                    when else{
                        forecastedHours = averageWeeklyProjectBurnRate;
                    }
                }

                RepliconForecast__c newPlaceholderForecast = new RepliconForecast__c(Name = placeholderForecastName, Project__c = proj.Id, Contact__c = placeholderContactId, ProjectTeamMemberBillingRate__c = placeholderProjBillRate.Id,
                                                                                Kickoff_Placeholder_Forecast__c = true, Week_Start_Date__c = weekStartDate, Week_End_Date__c = weekStartDate.addDays(6), EstimatedHours__c = forecastedHours);
                placeholderForecastsToInsertList.add(newPlaceholderForecast);
            }
        }

        if(placeholderForecastsToInsertList.size() > 0){
            System.debug('***************************************** Inserting ' + placeholderForecastsToInsertList.size() + ' Kickoff Placeholder Forecasts *****************************************');
            insert placeholderForecastsToInsertList;
        }
    }

    public static void closedWonParentOpptyCloseDateChange(List<Opportunity> opptyList){

        Map<Id, Opportunity> opptyIdToOpptyMap = new Map<Id, Opportunity>();
        for(Opportunity opp : opptyList){
            opptyIdToOpptyMap.put(opp.Id, opp);
        }

        Set<Opportunity> recreateKickOffPlaceholderForecastOpptySet = new Set<Opportunity>();
        if(opptyIdToOpptyMap.size() > 0){
            List<RepliconForecast__c> existingKickoffPlaceholderList = new List<RepliconForecast__c>();
            existingKickoffPlaceholderList = [SELECT Id, Project__c, Project__r.Opportunity__c, Kickoff_Placeholder_Forecast__c FROM RepliconForecast__c WHERE Kickoff_Placeholder_Forecast__c = true AND Project__r.Opportunity__c IN :opptyIdToOpptyMap.keySet()];

            if(existingKickoffPlaceholderList.size() > 0){
                for(RepliconForecast__c forecast : existingKickoffPlaceholderList){
                    if(opptyIdToOpptyMap.containsKey(forecast.Project__r.Opportunity__c)){
                        recreateKickOffPlaceholderForecastOpptySet.add(opptyIdToOpptyMap.get(forecast.Project__r.Opportunity__c));
                    }
                }

                delete existingKickoffPlaceholderList;
            }

            if(recreateKickOffPlaceholderForecastOpptySet.size() > 0){
                List<Opportunity> recreateKickOffPlaceholderForecastOpptyList = new List<Opportunity>();
                recreateKickOffPlaceholderForecastOpptyList.addAll(recreateKickOffPlaceholderForecastOpptySet);
                createPlaceholderForecastsOnCW(recreateKickOffPlaceholderForecastOpptyList);
            }
        }
    }

    public static void updateTimeEntriesOnESAProjectIdUpdate(Map<Id, Opportunity> opptyIdToOpptyRecordMap, Map<String, String> newESAProjectIdToOldProjectIdMap){

        List<Replicon_Time_Entry__c> relatedTimeEntryList = new List<Replicon_Time_Entry__c>();
        List<RepliconForecast__c> relatedForecastList = new List<RepliconForecast__c>();
        List<Replicon_Time_Entry__c> entryUpdateList = new List<Replicon_Time_Entry__c>();
        List<RepliconForecast__c> forecastUpdateList = new List<RepliconForecast__c>();

        List<Project__c> projectList = new List<Project__c>();
        projectList = [SELECT Id, Name, Opportunity__c, Peoplesoft_Project_Id__c, (SELECT Id, Peoplesoft_Project_Id__c, Project__c FROM Timesheet__r), 
                        (SELECT Id, Name, Peoplesoft_Project_Id__c, Week_Start_Date__c, Week_End_Date__c, Project__c FROM Replicon_Forecast__r)
                        FROM Project__c 
                        WHERE Opportunity__c IN :opptyIdToOpptyRecordMap.keySet()];

        Map<Id, String> projectIdToESAProjectIdMap = new Map<Id, String>();
        for(Project__c proj : projectList){

            if(opptyIdToOpptyRecordMap.containsKey(proj.Opportunity__C) && proj.Timesheet__r.size() > 0 && opptyIdToOpptyRecordMap.get(proj.Opportunity__C).Peoplesoft_Project_Id__c != null){
                projectIdToESAProjectIdMap.put(proj.Id, opptyIdToOpptyRecordMap.get(proj.Opportunity__C).Peoplesoft_Project_Id__c);
                if(proj.Timesheet__r != null && proj.Timesheet__r.size() > 0){
                    relatedTimeEntryList.addAll(proj.Timesheet__r);
                }
                if(proj.Replicon_Forecast__r != null && proj.Replicon_Forecast__r.size() > 0){
                    relatedForecastList.addAll(proj.Replicon_Forecast__r);
                }
            }
        }


        for(Replicon_Time_Entry__c entry : relatedTimeEntryList){
            if(projectIdToESAProjectIdMap.containsKey(entry.Project__c) && entry.Peoplesoft_Project_Id__c != projectIdToESAProjectIdMap.get(entry.Project__c)){
                entry.Peoplesoft_Project_Id__c = projectIdToESAProjectIdMap.get(entry.Project__c);
                entryUpdateList.add(entry);
            }
        }

        for(RepliconForecast__c forecast : relatedForecastList){
            if(projectIdToESAProjectIdMap.containsKey(forecast.Project__c) && forecast.Peoplesoft_Project_Id__c != projectIdToESAProjectIdMap.get(forecast.Project__c)){

                forecast.Peoplesoft_Project_Id__c = projectIdToESAProjectIdMap.get(forecast.Project__c);
                if(forecast.Name.contains('-') && forecast.Name.split('-').size() == 4){
                    String forecastNameStart = forecast.Name.substringBeforeLast('-');
                    String forecastProjectIdPart = forecast.Name.substringAfterLast('-');
                    if(newESAProjectIdToOldProjectIdMap.containsKey(projectIdToESAProjectIdMap.get(forecast.Project__c))){
                        String oldESAProjectId = newESAProjectIdToOldProjectIdMap.get(projectIdToESAProjectIdMap.get(forecast.Project__c));
                        if(oldESAProjectId != null && forecastProjectIdPart == oldESAProjectId){
                            forecast.Name = forecastNameStart + '-' + projectIdToESAProjectIdMap.get(forecast.Project__c);
                        }
                    }
                }
        
                forecastUpdateList.add(forecast);
            }
        }

        if(entryUpdateList.size() > 0){
            System.debug('****************** Updating ' + entryUpdateList.size() + ' Time Entries with new ESA Project Ids ************************');
            update entryUpdateList;
        }

        if(forecastUpdateList.size() > 0){
            System.debug('****************** Updating ' + forecastUpdateList.size() + ' Forecast(s) with new ESA Project Ids ************************');
            update forecastUpdateList;
        }
    
    }

    public static void updateInvoicedTotalsOnRelatedProject(Map<Id, Opportunity> opptyIdToOpptyRecordMap){

        List<Project__c> projUpdateList = new List<Project__c>();
	 	if(opptyIdToOpptyRecordMap.size() > 0){
			
            List<Project__c> projList = new List<Project__c>();
			projList = [SELECT Id, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, Opportunity__c
                        FROM Project__c 
                        WHERE Opportunity__c IN :opptyIdToOpptyRecordMap.keySet()];

			for(Project__c proj : projList){

				if(opptyIdToOpptyRecordMap.containsKey(proj.Opportunity__c)){
                    Boolean needsUpdate = false;

                    if(proj.Total_Hours_Invoiced_to_Date__c != opptyIdToOpptyRecordMap.get(proj.Opportunity__c).Total_Hours_Invoiced_to_Date__c){
                        proj.Total_Hours_Invoiced_to_Date__c = opptyIdToOpptyRecordMap.get(proj.Opportunity__c).Total_Hours_Invoiced_to_Date__c;
                        needsUpdate = true;
                    }

                    if(proj.Total_Amount_Invoiced_to_Date__c != opptyIdToOpptyRecordMap.get(proj.Opportunity__c).Total_Amount_Invoiced_to_Date__c){
                        proj.Total_Amount_Invoiced_to_Date__c = opptyIdToOpptyRecordMap.get(proj.Opportunity__c).Total_Amount_Invoiced_to_Date__c;
                        needsUpdate = true;
                    }

                    if(needsUpdate){
                        projUpdateList.add(proj);
                    }
				}
			}

            if(projUpdateList.size() > 0){
                System.debug('******************* Updating Total Invoice Totals on ' + projUpdateList.size() + ' Projects **************************');
                update projUpdateList;
            }
		}
    }

    public static void populateSOWorCONumberOnOppty(List<Opportunity> parentOpptyList, List<Opportunity> changeOrderOpptyList){

        Set<Id> msaAccounts = new Set<Id>();

        if(parentOpptyList != null && parentOpptyList.size() > 0){
            String maxSOWNumberString;
            Integer sowNumber;

            List<Opportunity> maxSOWNumberOpportunityList = new List<Opportunity>();
            maxSOWNumberOpportunityList = [SELECT Id, Name, SOW_Number__c 
                                            FROM Opportunity 
                                            WHERE SOW_Number__c != null AND SOW_Number__c LIKE 'SOW-%' AND RecordTypeId =: salesforceOpptyRT  
                                            ORDER BY SOW_Number__c DESC 
                                            LIMIT 1];

            if(maxSOWNumberOpportunityList.size() > 0){                
                maxSOWNumberString = maxSOWNumberOpportunityList[0].SOW_Number__c;
                maxSOWNumberString = maxSOWNumberString.substringAfterLast('-');
                //maxSOWNumberString = maxSOWNumberString.substring(9, 14);
                System.debug('Populate SOW OR CO Number on Oppty sowNO: ' + maxSOWNumberString);
                sowNumber = Integer.valueOf(maxSOWNumberString);
            }

            for(Opportunity parentOppty : parentOpptyList){
                sowNumber = (sowNumber == null ? 40000 : sowNumber + 1);
                parentOppty.SOW_Number__c = 'SOW-' + String.valueOf(System.today().year()) + '-' + String.valueOf(sowNumber);
                parentOppty.Unique_SOW_Number__c = parentOppty.SOW_Number__c;
                msaAccounts.add(parentOppty.AccountId);
            }
        }

        if(changeOrderOpptyList != null && changeOrderOpptyList.size() > 0){
            String maxCONumberString;
            Integer coNumber;

            List<Opportunity> maxCONumberOpportunityList = new List<Opportunity>();
            maxCONumberOpportunityList = [SELECT Id, Name, CO_Number__c 
                                            FROM Opportunity 
                                            WHERE CO_Number__c != null AND CO_Number__c LIKE 'CO-%' AND RecordTypeId =: changeOrderOpptyRT  
                                            ORDER BY CO_Number__c DESC 
                                            LIMIT 1];

            if(maxCONumberOpportunityList.size() > 0){                
                maxCONumberString = maxCONumberOpportunityList[0].CO_Number__c;
                maxCONumberString = maxCONumberString.substringAfterLast('-');
                //maxCONumberString = maxCONumberString.substring(9, 14);
                System.debug('coNo: ' + maxCONumberString);
                coNumber = Integer.valueOf(maxCONumberString);
            }

            for(Opportunity coOppty : changeOrderOpptyList){
                coNumber = (coNumber == null ? 40000 : coNumber + 1);
                coOppty.CO_Number__c = 'CO-' + String.valueOf(System.today().year()) + '-' + String.valueOf(coNumber);
            }
        }

        if(msaAccounts.size() > 0){
            AccountCalculations.SetMSA(msaAccounts);
        }
    }

    public static void populateOpptyLogs(List<Opportunity> updateLogsOpptyList, Map<Id, Opportunity> oldMap){

        String userFirstName = UserInfo.getFirstName();
        userFirstName = (userFirstName == null ? '' : userFirstName.substring(0,1));
        String userName = userFirstName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
        Datetime todayDateTime = Datetime.now(); //td
        String todayMonthAndDayString = todayDateTime.Format('MM/dd'); //today

        for(Opportunity oppty : updateLogsOpptyList){

            if(oldMap == null){
                //Coming in from before Insert

                //Update Latest Work Log Before Insert
                if(oppty.Latest_Work_Log__c != null){
                    oppty.Work_Logs__c = userName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + oppty.Latest_Work_Log__c;
                }

                //Update Next Steps Log Before Insert
                if(oppty.Next_Steps__c != null){
                    oppty.Next_Steps__c = todayMonthAndDayString + ' : ' + oppty.Next_Steps__c;
                    oppty.Next_Steps_Log__c   = userName + ' ' + oppty.Next_Steps__c;
                    oppty.Next_Steps_Timestamp__c = todayDateTime;
                }

                //Update Manager's Notes Log Before Insert
                if(oppty.Managers_Notes__c != null){
                    oppty.Managers_Notes__c = todayMonthAndDayString + ' : ' + oppty.Managers_Notes__c;
                    oppty.Managers_Notes_Log__c   = userName + ' ' + oppty.Managers_Notes__c;
        
                    String managersNote;
                    if(!oppty.Managers_Notes__c.contains('<li>')){
                        managersNote = '<p>' + todayMonthAndDayString + ' : ' + oppty.Managers_Notes__c.substring(3, oppty.Managers_Notes__c.length());
                    }else{
                        managersNote = '<p>' + todayMonthAndDayString + ' : ' + oppty.Managers_Notes__c;
                    }
                    oppty.Managers_Notes__c = managersNote;
                    oppty.Managers_Notes_Log__c = '<p>' + userName + ' ' + oppty.Managers_Notes__c.substring(3, oppty.Managers_Notes__c.length())  + '<p/>' + (oppty.Managers_Notes_Log__c == null ? '' : oppty.Managers_Notes_Log__c);
                }

            }else{
                //Coming in from before Update
                if(oldMap.containsKey(oppty.Id)){
                    Opportunity oldOppty = oldMap.get(oppty.Id);

                    //Update Latest Work Log Before Update
                    if(oppty.Latest_Work_Log__c != null && oppty.Latest_Work_Log__c != oldOppty.Latest_Work_Log__c){
                        oppty.Work_Logs__c = (oppty.Work_Logs__c == null ? '' : oppty.Work_Logs__c) + '\n' + userName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + oppty.Latest_Work_Log__c;
                    }

                    //Update Next Steps Log Before Update
                    if(oppty.Next_Steps__c != null && oppty.Next_Steps__c != oldOppty.Next_Steps__c){
                        oppty.Next_Steps__c = todayMonthAndDayString + ' : ' + oppty.Next_Steps__c;
                        String nextStepsLog;
                        nextStepsLog = userName + ' ' + oppty.Next_Steps__c + '\n' + (oppty.Next_Steps_Log__c == null ? '' : oppty.Next_Steps_Log__c);
                        //nextStepsLog = userName + + ' ' + todayMonthAndDayString + ' : ' + o.Next_Steps__c+ '\n' + (o.Next_Steps_Log__c == null ? '' : o.Next_Steps_Log__c);
                        if(nextStepsLog.length() > 32768) {
                            oppty.Next_Steps_Log__c = ' ' + nextStepsLog.left(32768);
                        } else {
                            oppty.Next_Steps_Log__c  = nextStepsLog;
                        }
                        //Moved Next Steps Field Timestamp Workflow Rule into trigger to avoid recursive Opp triggers.
                        //Update Next Steps timestamp
                        oppty.Next_Steps_Timestamp__c = todayDateTime;
                    }

                    //Update Managers Notes Before Update
                    if(oppty.Managers_Notes__c != null && oppty.Managers_Notes__c != oldOppty.Managers_Notes__c){
                        String managersNote;
                        String managersNotesLog;
                        if(!oppty.Managers_Notes__c.contains('<li>')){
                            managersNote = '<p>' + todayMonthAndDayString + ' : ' + oppty.Managers_Notes__c.substring(3, oppty.Managers_Notes__c.length());
                        }else{
                            managersNote = '<p>' + todayMonthAndDayString + ' : ' + oppty.Managers_Notes__c;
                        }
            
                        oppty.Managers_Notes__c = managersNote;
                        managersNotesLog = '<p>' + userName + ' ' + oppty.Managers_Notes__c.substring(3, oppty.Managers_Notes__c.length())  + '<p/>' + (oppty.Managers_Notes_Log__c == null ? '' : oppty.Managers_Notes_Log__c);
            
                        if(managersNotesLog.length()>131072) {
                            oppty.Managers_Notes_Log__c = ' ' + managersNotesLog.left(131072);
                        } else {
                            oppty.Managers_Notes_Log__c  = managersNotesLog;
                        }
                    }
                }
            }

        }


    }

    public static void sendLowRateOpptyProductAlert(Set<Id> opptyIdSet){

        List<OpportunityLineItem> lowRateOpptyProductList = new List<OpportunityLineItem>();
        lowRateOpptyProductList = [SELECT Id, Name, Product2.Name, UnitPrice, Resource_Delivery_Group__c, OpportunityId, Opportunity.CloseDate, Opportunity.Name, Opportunity.IsWon
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId IN :opptyIdSet AND UnitPrice <= 75 AND Resource_Delivery_Group__c = 'Lev - NA' AND Opportunity.IsWon = true
                                    ORDER BY OpportunityId, UnitPrice];

                                    System.debug('lowRateOpptyProductList: ' + lowRateOpptyProductList.size());

        if(lowRateOpptyProductList.size() > 0){
            Map<Id, List<OpportunityLineItem>> opptyIdToOpptyProdListMap = new Map<Id, List<OpportunityLineItem>>();
            Map<Id, Opportunity> opptyIdToOpptyMap = new Map<Id, Opportunity>();
            for(OpportunityLineItem oli : lowRateOpptyProductList){

                //Create Map of Opportunity Id in order to get Oppty details later
                if(!opptyIdToOpptyMap.containsKey(oli.OpportunityId)){
                    Opportunity oppty = new Opportunity(Id = oli.OpportunityId, Name = oli.Opportunity.Name, CloseDate = oli.Opportunity.CloseDate);
                    opptyIdToOpptyMap.put(oli.OpportunityId, oppty);
                }

                //Create Map for Each Opportunity to all of its relevant Opportunity Products
                if(opptyIdToOpptyProdListMap.containsKey(oli.OpportunityId)){
                    List<OpportunityLineItem> opptyLineItemList = opptyIdToOpptyProdListMap.get(oli.OpportunityId);
                    opptyLineItemList.add(oli);
                    opptyIdToOpptyProdListMap.put(oli.OpportunityId, opptyLineItemList);
                }else{
                    List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();
                    opptyLineItemList.add(oli);
                    opptyIdToOpptyProdListMap.put(oli.OpportunityId, opptyLineItemList);
                }
            }

            System.debug('opptyIdToOpptyProdListMap: ' + opptyIdToOpptyProdListMap);

            //Build the email
            List<Messaging.SingleEmailMessage> emailToSendList = new List<Messaging.SingleEmailMessage>();

            for(Id opptyId : opptyIdToOpptyProdListMap.keySet()){

                Messaging.SingleEmailMessage lowRateOpptyProdEmailAlert = new Messaging.SingleEmailMessage();  
                lowRateOpptyProdEmailAlert.setSubject('New Won Opportunity with Product(s) Below or at $75 Rate');

                Datetime closeDatedt = Datetime.newInstance(opptyIdToOpptyMap.get(opptyId).CloseDate.year(), opptyIdToOpptyMap.get(opptyId).CloseDate.month(), opptyIdToOpptyMap.get(opptyId).CloseDate.day());
                String closeDateFormatted = closeDatedt.format('MMMM d, y');

                
                String emailBody = 'Hello,';
                emailBody += '<br/>';
                emailBody += 'A new Opportunity has just went won and has one or more Products/roles that are at or below a $75 rate per hour.';
                emailBody += '<br/>';

                emailBody += '<ul>';
                emailBody += '<li><b>Opportunity Name:</b>  ' + '<b><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Opportunity/' + opptyId + '/view">' + opptyIdToOpptyMap.get(opptyId).Name +' </a></b></li>';
                emailBody += '<li><b>Close Date:</b> ' + closeDateFormatted + '</li>';
                emailBody += '</ul>';
                emailBody += 'The below Products have a rate at or below $75 per hour:';
                emailBody += '<br/>';

                for(OpportunityLineItem oli : opptyIdToOpptyProdListMap.get(opptyId)){
                    emailBody += '<ul>';
                    emailBody += '<li><b>Product Name:</b>  ' + oli.Product2.Name + '</li>';
                    emailBody += '<li><b>Rate:</b> $  ' + String.valueOf(oli.UnitPrice) + '</li>';
                    emailBody += '<li><b>Resource Delivery Group:</b>  ' + oli.Resource_Delivery_Group__c + '</li>';
                    emailBody += '</ul>';
                    //emailBody += '<br/>';


                    /*emailBody += '<b>Product Name:</b>  ' + oli.Product2.Name;
                    emailBody += '<br/>';
                    emailBody += '<b>Rate:</b> $' + String.valueOf(oli.UnitPrice);
                    emailBody += '<br/>';
                    emailBody += '<b>Resource Delivery Group:</b>  ' + oli.Resource_Delivery_Group__c;
                    emailBody += '<br/>' + '<br/>';*/
                }

                emailBody += 'Please note there may be more Products associated to this Opportunity above this rate.';
                emailBody += '<br/>' + '<br/>';
                emailBody += '<i>This is an automated notification.</i>';

                lowRateOpptyProdEmailAlert.setHtmlBody(emailBody);

                //Set who the Email will be sent to
                Set<String> emailRecipientSet = new Set<String>();

                List<User> ccUsersList = new List<User>();
                ccUsersList = [SELECT Id, Name, Email FROM User WHERE Name IN ('Raul Ventura', 'Lori Davis', 'Jamie Lindley') AND IsActive = true AND UserType = 'Standard'];
                //ccUsersList = [SELECT Id, Name, Email FROM User WHERE Name IN ('Sam Tucker') AND IsActive = true AND UserType = 'Standard'];
                for(User u : ccUsersList){
                    if(u.Email != null){
                        emailRecipientSet.add(u.Email);
                    }
                }

                List<String> emailRecipientsList = new List<String>();
                if(emailRecipientSet.size() > 0){
                    emailRecipientsList.addAll(emailRecipientSet);
                    lowRateOpptyProdEmailAlert.setToAddresses(emailRecipientsList);
                    System.debug('Email Recipients List: ' + emailRecipientsList);
                }

                if(!Test.isRunningTest()){
                    lowRateOpptyProdEmailAlert.setOrgWideEmailAddressId('0D26T000001gtm3SAA');
                }

                //Add Email to list to send
                if(emailRecipientsList.size() > 0){ //Only add it to send list, if there are recipients that are listed to send the email to.
                    emailToSendList.add(lowRateOpptyProdEmailAlert); 
                }
            }

            //Send Email
            if(!emailToSendList.isEmpty()){
                if(CheckRecursive.runLowRateOpptyProductAlertOnce()){
                    System.debug('Low Rate NA Oppty Product Alert SEND EMAIL LIST: ' + emailToSendList);
                    Messaging.sendEmail(emailToSendList); 
                }
            }
        }
    }
}