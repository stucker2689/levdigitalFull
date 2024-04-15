/**
 * Sam Update 1/21/2022 checkOpptyProductsResourceAllocationOnOpptyCW to throw Error on Oppty when moved to CW and Products do not meet validations
 */

public with sharing class OpportunityTriggerHandler {
    //=========================================================================
    //  VARIABLES
    //=========================================================================
    private Map<Id, Schema.RecordTypeInfo> recordTypeMap;
    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();
    private static String sowStages = OpportunitySettings__c.getInstance().SOWStages__c;
    private static String changeOrderStages = OpportunitySettings__c.getInstance().ChangeOrderStages__c;

    public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};

    private static Id abcLevTestAccountId = '001d000000VPPgeAAH';

    private static List<String> productResourceAlloReqProjTermsList = new List<String>{'Fixed Utilization', 'Fixed Capacity'};
    private static List<String> professionalServicesProductFamilyTypeList = new List<String>{'Professional Services'};
    private static List<String> productResourceAlloBypassList = new List<String>{'Legacy', 'Other'};

    //=========================================================================
    //  CONSTRUCTOR
    //=========================================================================
    public OpportunityTriggerHandler() {
        System.debug('@@@@OpportunityTriggerHandler');
        recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        
    }

    //=========================================================================
    //  PUBLIC METHODS
    //=========================================================================

    public static void beforeInsert(List<Opportunity> opportunityList) {

        List<Opportunity> changeOrderOpptyList = new List<Opportunity>();
        List<Opportunity> populateSOWNumberOpptyList = new List<Opportunity>();
        List<Opportunity> populateCONumberOpptyList = new List<Opportunity>();

        List<Opportunity> updateLogsOpptyList = new List<Opportunity>();

        for(Opportunity oppty : opportunityList) {

            if(oppty.RecordTypeId == salesforceOpptyRT){
                //Populate SOW Number on Parent Opportunity -- Moved from OpportunityBeforeInsertUpdate trigger
                if(oppty.SOW_Number__c == null && sowStages != null && sowStages.contains(oppty.StageName) ){
                    populateSOWNumberOpptyList.add(oppty);
                }

            }else if(oppty.RecordTypeId == changeOrderOpptyRT){
                changeOrderOpptyList.add(oppty);

                //Populate CO Number on Change Order -- Moved from OpportunityBeforeInsertUpdate trigger
                if(oppty.CO_Number__c == null && changeOrderStages != null && changeOrderStages.contains(oppty.StageName)){
                    populateCONumberOpptyList.add(oppty);
                }
            }

            //Populate Work Logs, Next Steps, Manager Notes Logs-- Moved from OpportunityBeforeInsertUpdate trigger
            if(oppty.Latest_Work_Log__c != null || oppty.Next_Steps__c != null || oppty.Managers_Notes__c != null){
                updateLogsOpptyList.add(oppty);
            }
        }

        if(changeOrderOpptyList.size() > 0){
            populatePMonCOInsert(changeOrderOpptyList);
        }

        if(populateSOWNumberOpptyList.size() > 0 || populateCONumberOpptyList.size() > 0){
            OpportunityTriggerHelper.populateSOWorCONumberOnOppty(populateSOWNumberOpptyList, populateCONumberOpptyList);
        }

        if(updateLogsOpptyList.size() > 0){
            OpportunityTriggerHelper.populateOpptyLogs(updateLogsOpptyList, null);
        }
        
    }

    public static void afterInsert(List<Opportunity> opportunityList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> closedWonAccountIds = new Set<Id>();
        Set<Id> relOppReCalc = new Set<Id>();
        List<Opportunity> changeOrderOpptyList = new List<Opportunity>();
        List<Opportunity> closedWonParentOpptyList = new List<Opportunity>();
        List<Opportunity> createProjectsOpportunityList = new List<Opportunity>();
        for(Opportunity oppty : opportunityList) {

            if(oppty.RecordTypeId == changeOrderOpptyRT){
                changeOrderOpptyList.add(oppty);

                if(oppty.Change_Orders__c != null){
                    relOppReCalc.add(oppty.Id);
                }
            }
            if(oppty.RecordTypeId == salesforceOpptyRT){
                closedWonParentOpptyList.add(oppty);
            }
            if(oppty.IsWon){
                closedWonAccountIds.add(oppty.AccountId);
            }

            if((oppty.Create_Project__c || opportunityClosedWonStageNames.contains(oppty.StageName)) && !oppty.Do_Not_Create_Project__c) { //Added from Opportunity After Trigger
				createProjectsOpportunityList.add(oppty);                        
			} 
            

            accountIds.add(oppty.AccountId);
        }

        if(createProjectsOpportunityList.size() > 0){
            //if(CheckRecursive.runCreateProjectsOnce()){
				CreateProject.CreateProject(createProjectsOpportunityList);
			//}
        }

        if(accountIds.size() > 0) {
            updateAccountLowestProjectBudgetRemaining(accountIds);
            updateAccountFirstYearBooking(accountIds);
            rollupTotalOpptyCountOnAccount(accountIds); //Total Opportunities DLRS Replacement - ST 1/9/2023
        }

        if(closedWonAccountIds.size() > 0){
            AccountCalculations.FirstYearBooking(closedWonAccountIds);
        }

        if(changeOrderOpptyList.size() > 0){
            totalProjDurationOfCOAfterInsert(changeOrderOpptyList);
        }

        if(closedWonParentOpptyList.size() > 0){
            OpportunityTriggerHelper.createPlaceholderForecastsOnCW(closedWonParentOpptyList);
        }

        if(relOppReCalc.size() > 0){
            OpportunityCalculations.relOppReCalc(relOppReCalc);
        }
    }

    public static void beforeUpdate(List<Opportunity> opportunityList, Map<Id, Opportunity> oldMap) {

        List<Opportunity> changedRTOpptyList = new List<Opportunity>();
        List<Opportunity> cwOpptyList = new List<Opportunity>();
        List<Opportunity> populateSOWNumberOpptyList = new List<Opportunity>();
        List<Opportunity> populateCONumberOpptyList = new List<Opportunity>();

        List<Opportunity> updateLogsOpptyList = new List<Opportunity>();
        for(Opportunity oppty : opportunityList) {
            Opportunity oldOppty = oldMap.get(oppty.Id);

            //Check if the Close Date is updated to be pushed out to the next month or further
            // check if the new close date was pushed out to the next month or further
            if(oppty.CloseDate != oldOppty.CloseDate && oldOppty.CloseDate.monthsBetween(oppty.CloseDate) > 0) { //Tracks the number of times an Opportunity records Close Date has been pushed out.
                if(oppty.PushCount__c == null) {
                    oppty.PushCount__c = 1;
                }else if(oppty.PushCount__c == oldOppty.PushCount__c) { // prevent multiple iterations with recursive triggers
                    oppty.PushCount__c++;
                }
            }

            //Populate Work Logs, Next Steps, Manager Notes Logs-- Moved from OpportunityBeforeInsertUpdate trigger
            if((oppty.Latest_Work_Log__c != null && oppty.Latest_Work_Log__c != oldOppty.Latest_Work_Log__c) || (oppty.Next_Steps__c != null && oppty.Next_Steps__c != oldOppty.Next_Steps__c) || (oppty.Managers_Notes__c != null && oppty.Managers_Notes__c != oldOppty.Managers_Notes__c)){
                updateLogsOpptyList.add(oppty);
            }

            //Moved from OpportunityBeforeInsertUpdate trigger
            if(oppty.Probability < 90){
                if(oppty.Total_Hours_Finalize_Contracts__c != oppty.Total_Hours__c){
                    oppty.Total_Hours_Finalize_Contracts__c = oppty.Total_Hours__c;
                }
                if(oppty.Invoice_Payment_Terms_Finalize_Contracts__c != oppty.Payment_Terms__c){
                    oppty.Invoice_Payment_Terms_Finalize_Contracts__c = oppty.Payment_Terms__c;
                }
                if(oppty.Opportunity_Amount_Finalize_Contract__c != oppty.Amount){
                    oppty.Opportunity_Amount_Finalize_Contract__c = oppty.Amount;
                }

                if(oppty.Probability < 75){
                    if(oppty.Total_Hours_Verbal__c != oppty.Total_Hours__c){
                        oppty.Total_Hours_Verbal__c = oppty.Total_Hours__c;
                    }
                    if(oppty.Invoice_Payment_Terms_Verbal__c != oppty.Payment_Terms__c){
                        oppty.Invoice_Payment_Terms_Verbal__c = oppty.Payment_Terms__c;
                    }
                    if(oppty.Opportunity_Amount_Verbal__c != oppty.Amount){
                        oppty.Opportunity_Amount_Verbal__c = oppty.Amount;
                    }
                }
            }

            //Moved from OpportunityBeforeInsertUpdate trigger
            if((opportunityClosedWonStageNames.contains(oppty.StageName)) && oppty.Do_Not_Create_Project__c == false){
                oppty.Create_Project__c = true;
            }

            if(oppty.RecordTypeId == salesforceOpptyRT){

                //Populate SOW Number on Parent Oppty -- Moved from OpportunityBeforeInsertUpdate trigger
                if(oppty.SOW_Number__c == null && sowStages != null && sowStages.contains(oppty.StageName)){
                    populateSOWNumberOpptyList.add(oppty);
                }

                //Clear CO Number on Parent Oppty if changed from Change Order-- Moved from OpportunityBeforeInsertUpdate trigger
                if(oldOppty.RecordTypeId == changeOrderOpptyRT){
                    if(oppty.CO_Number__c != null){
                        oppty.CO_Number__c = '';
                    }
                    //If Changing from CO to SF RT then clear related Opportunity Lookup Field
                    if(oppty.Change_Orders__c != null){
                        oppty.Change_Orders__c = null;
                    }
                }

            }else if(oppty.RecordTypeId == changeOrderOpptyRT){

                if(oldOppty.RecordTypeId == salesforceOpptyRT){//Check if changing Record Types (From CO to SF)

                    //Clear SOW Number on Change Order Oppty if changed from Parent Oppty -- Moved from OpportunityBeforeInsertUpdate trigger
                    if(oppty.SOW_Number__c != null || oppty.Unique_SOW_Number__c != null){
                        oppty.SOW_Number__c = '';
                        oppty.Unique_SOW_Number__c = '';
                    }
                }

                //Populate CO Number on Change Order -- Moved from OpportunityBeforeInsertUpdate trigger
                if(oppty.CO_Number__c == null && changeOrderStages != null && changeOrderStages.contains(oppty.StageName)){
                    populateCONumberOpptyList.add(oppty);
                }
            }

            //Check if Opportunity is moved TO Closed Won
            if((oppty.RecordTypeId == salesforceOpptyRT || oppty.RecordTypeId == changeOrderOpptyRT) && (oppty.StageName != oldOppty.StageName) && (opportunityClosedWonStageNames.contains(oppty.StageName))){
                cwOpptyList.add(oppty);
            }
        }

        if(cwOpptyList.size() > 0){
            checkOpptyProductsResourceAllocationOnOpptyCW(cwOpptyList);
        }

        if(populateSOWNumberOpptyList.size() > 0 || populateCONumberOpptyList.size() > 0){
            OpportunityTriggerHelper.populateSOWorCONumberOnOppty(populateSOWNumberOpptyList, populateCONumberOpptyList);
        }

        if(updateLogsOpptyList.size() > 0){
            OpportunityTriggerHelper.populateOpptyLogs(updateLogsOpptyList, oldMap);
        }
    }

    public static void afterUpdate(List<Opportunity> opportunityList, Map<Id, Opportunity> oldMap) {
        Map<Id, Opportunity> clonedOppMap = new Map<Id, Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> firstYearAccountIds = new Set<Id>();
        Set<Id> repliconOpportunityIds = new Set<Id>();
        List<Opportunity> changeOrderOpptyList = new List<Opportunity>();
        Map<Id, Opportunity> changeOrderOpptyMap = new Map<Id, Opportunity>();
        Set<Id> closedWonCOOpptySet = new Set<Id>();
        Map<Id, Opportunity> parentOpptyToMostRecentClosedWonCOOpptyMap = new Map<Id, Opportunity>();
        List<Opportunity> closedWonOpptyListForWeeklyTargetBookings = new List<Opportunity>(); //Added 3.4.22 ST
        List<Opportunity> closedWonParentOpptyList = new List<Opportunity>(); //Added 6.2.22 ST
        List<Opportunity> closedWonParentOpptyCloseDateChangeList = new List<Opportunity>(); //Added 6.8.22 ST

        Set<Id> relOppReCalc = new Set<Id>(); //Added from Opportunity After trigger
        List<Opportunity> createProjectsOpportunityList = new List<Opportunity>(); //Added from Opportunity After trigger

        Map<Id, Opportunity> esaProjectIdChangedOpptyMap = new Map<Id, Opportunity>();// Added 7.12.2023 ST
        Map<String, String> newEsaProjectIdToOldEsaProjectIdMap = new Map<String, String>();

        List<Opportunity> changeOrderToClosedWonList = new List<Opportunity>();
        List<Opportunity> oldChangeOrderFromClosedWonList = new List<Opportunity>();

        Map<Id, Opportunity> opptyIdToOpptyInvoiceChangeMap = new Map<Id, Opportunity>();

        Set<Id> checkForLowRateNAOpptyProdOpptyIdSet = new Set<Id>();

        Set<Id> changeOrdersReassignedParentOpptyIdSet = new Set<Id>(); //1.18.2024 ST For recalcing Project Billing Rates and Project Roles when a Change Order is changed.

        for(Opportunity oppty : opportunityList) {
            Opportunity oldOppty = oldMap.get(oppty.Id);

            /*************** NEW TRIGGER CONSOLIDATION ST 7.13.2023 ********************/

            // check if values for opp budget have changed for non-closed opptys or if Oppty is gone closed
            if((!oppty.IsClosed && (oppty.Opportunity_Amount_COs__c != oldOppty.Opportunity_Amount_COs__c || oppty.Total_Amount_Invoiced_to_Date__c != oldOppty.Total_Amount_Invoiced_to_Date__c)) || (oppty.IsClosed != oldOppty.IsClosed)) {
                accountIds.add(oppty.AccountId);
            }

            // check if the closed won state has changed or if a currently closed won
            // opportunity has its amount or close date changed in order to roll up
            // first year bookings
            if(oppty.IsWon != oldOppty.IsWon || (oppty.IsWon && (oppty.Amount != oldOppty.Amount || oppty.CloseDate != oldOppty.CloseDate))) {
                firstYearAccountIds.add(oppty.AccountId);
                //Added 3.4.22 ST
                if(oppty.AccountId != abcLevTestAccountId){
                    closedWonOpptyListForWeeklyTargetBookings.add(oppty);
                    if(oppty.IsWon == oldOppty.IsWon && oppty.CloseDate != oldOppty.CloseDate){ //Add old Oppty when Oppty Close Date Changes to adjust Bookings on Weekly Target for previous Close Date
                        closedWonOpptyListForWeeklyTargetBookings.add(oldOppty);
                    }
                }
            }

            if(((oppty.Create_Project__c && oppty.Create_Project__c != oldOppty.Create_Project__c) || (opportunityClosedWonStageNames.contains(oppty.StageName) && !opportunityClosedWonStageNames.contains(oldOppty.StageName)) || (oppty.RecordTypeId != oldOppty.RecordTypeId && oppty.RecordTypeId == salesforceOpptyRT && oppty.IsWon)) && !oppty.Do_Not_Create_Project__c) {
				createProjectsOpportunityList.add(oppty);                        
			}

            System.debug('Oppty Trigger Handler --- Oppty: ' + oppty.IsWon + ' Old Oppty: ' + oldOppty.IsWon ); 
            if(oppty.IsWon != oldOppty.IsWon && oppty.IsWon == true){
                System.debug('Adding To Check Low Rate');
                checkForLowRateNAOpptyProdOpptyIdSet.add(oppty.Id);
            }
            
            if(oppty.IsWon && oppty.Change_Orders__c != oldOppty.Change_Orders__c){
                if(oppty.Change_Orders__c != null){
                    changeOrdersReassignedParentOpptyIdSet.add(oppty.Change_Orders__c);
                }
                if(oldOppty.Change_Orders__c != null){
                    changeOrdersReassignedParentOpptyIdSet.add(oldOppty.Change_Orders__c);
                }
            }
            
            if(oppty.RecordTypeId == salesforceOpptyRT){
            /************************************* After Update Logic for Parent Opportunities ************************************************/

                if(oppty.isWon){
                    if((oppty.IsWon != oldOppty.IsWon) || (oppty.Create_Project__c != oldOppty.Create_Project__c && oppty.Create_Project__c) ||  (oldOppty.RecordTypeId != oppty.RecordTypeId && oppty.IsWon)){ //Create Placeholder Forecasts for Closed Won Opportunities - 6/2/2022 ST
                        closedWonParentOpptyList.add(oppty);
                    }

                    if(oldOppty.IsWon && oppty.CloseDate != oldOppty.CloseDate){ //Check if Oppty remained Closed Won but the Close Date Changed
                        closedWonParentOpptyCloseDateChangeList.add(oppty);
                    }
                }

                //New 10/20/2022 ST Recalcs Oppty if CO is changed from CO //From Opportunity After Trigger
				if(oppty.RecordTypeId != oldOppty.RecordTypeId && oldOppty.RecordTypeId == changeOrderOpptyRT && oldOppty.Change_Orders__c != null){
					relOppReCalc.add(oldOppty.Change_Orders__c);
				}

                //Check if Oppty remained Closed Won but the Close Date Changed
                if(oppty.IsWon && oldOppty.IsWon && (oppty.CloseDate != oldOppty.CloseDate)){
                    closedWonParentOpptyCloseDateChangeList.add(oppty);
                }

                //Check if ESA Project Id is changed ST 7.12.2023
                if(oppty.Peoplesoft_Project_Id__c != oldOppty.Peoplesoft_Project_Id__c){
                    esaProjectIdChangedOpptyMap.put(oppty.Id, oppty);
                    newEsaProjectIdToOldEsaProjectIdMap.put(oppty.Peoplesoft_Project_Id__c, oldOppty.Peoplesoft_Project_Id__c);
                }

                //From ProjectHandler ST 7.20.2023
                if((oppty.IsWon || oppty.IsWon != oldOppty.IsWon) && oppty.Total_Hours_Invoiced_to_Date__c != null && ((oppty.Total_Hours_Invoiced_to_Date__c != oldOppty.Total_Hours_Invoiced_to_Date__c) || oppty.Total_Amount_Invoiced_to_Date__c != oldOppty.Total_Amount_Invoiced_to_Date__c)){
                    opptyIdToOpptyInvoiceChangeMap.put(oppty.Id, oppty);
                }	


            /************************************* END of Parent Opportunity Logic ************************************************************/
            }else if(oppty.RecordTypeId == changeOrderOpptyRT){
            /************************************* After Update Logic for Change Order Opportunities ******************************************/

                if(oppty.ExpectedPro_DurationinWeeks__c != oldOppty.ExpectedPro_DurationinWeeks__c && CheckRecursive.runafterUpdateOnce()){ //If Change Order is updated and Expected Proj Duration in Weeks has changed
                    changeOrderOpptyList.add(oppty);
                    changeOrderOpptyMap.put(oppty.Id, oldOppty);
                }

                if(oppty.StageName != oldOppty.StageName && (opportunityClosedWonStageNames.contains(oppty.StageName) || opportunityClosedWonStageNames.contains(oldOppty.StageName))){

                    if(CheckRecursive.runafterUpdateOnce2()){
                        closedWonCOOpptySet.add(oppty.Change_Orders__c);
                        if(opportunityClosedWonStageNames.contains(oppty.StageName)){
                            if(parentOpptyToMostRecentClosedWonCOOpptyMap.containsKey(oppty.Change_Orders__c)){
                                if(oppty.CloseDate > parentOpptyToMostRecentClosedWonCOOpptyMap.get(oppty.Change_Orders__c).CloseDate){
                                    parentOpptyToMostRecentClosedWonCOOpptyMap.put(oppty.Change_Orders__c, oppty);
                                }
                            }else{
                                parentOpptyToMostRecentClosedWonCOOpptyMap.put(oppty.Change_Orders__c, oppty);
                            }
                        }
                    }

                    if(CheckRecursive.runafterUpdateOnce3()){
                        if(opportunityClosedWonStageNames.contains(oppty.StageName)){
                            changeOrderToClosedWonList.add(oppty);
                        }else if(opportunityClosedWonStageNames.contains(oldOppty.StageName)){
                            changeOrderToClosedWonList.add(oldOppty);
                        }
                    }
                }

                if((oppty.Amount != oldOppty.Amount || oppty.StageName != oldOppty.StageName || oppty.AllOtherNonLevResourceAmount__c != oldOppty.AllOtherNonLevResourceAmount__c) && (oppty.IsWon || oldOppty.IsWon)
                     && oppty.Change_Orders__c != null){//Added from Opportunity After Trigger
                    relOppReCalc.add(oppty.Change_Orders__c);
                }

                if(oppty.Change_Orders__c != oldOppty.Change_Orders__c && oppty.RecordTypeId == changeOrderOpptyRT){//Added from Opportunity After Trigger
                    relOppReCalc.add(oppty.Change_Orders__c);
                    relOppReCalc.add(oldOppty.Change_Orders__c);
                }
                /************************************************** END of Change Order Logic ******************************************************/
            }
        }

        //If Opportunity has Do Not Create Project checked, the create project class will be overlooked.
		if(createProjectsOpportunityList.size() > 0){
			//if(CheckRecursive.runCreateProjectsOnce()){
				CreateProject.CreateProject(createProjectsOpportunityList);
			//}
		}

        if(CheckRecursive.runUpdateAccountFirstYearBookingOnce() || Test.isRunningTest()){
            if(firstYearAccountIds.size() > 0){
                updateAccountFirstYearBooking(firstYearAccountIds);
            }
        }
        //if(CheckRecursive.runUpdateAcctLowestBudgetRemainingOnce()){
            if(accountIds.size() > 0){
                updateAccountLowestProjectBudgetRemaining(accountIds);
            }
        //}

        if(changeOrderOpptyList.size() > 0){
            totalProjDurationOfCOAfterUpdate(changeOrderOpptyList, changeOrderOpptyMap);
        }

        if(closedWonCOOpptySet.size() > 0){
            checkOverallProductRate(closedWonCOOpptySet, parentOpptyToMostRecentClosedWonCOOpptyMap);
        }

        //Rollup Closed Won Opptys to the related Revenue Forecast Weekly Target Record
        if(closedWonOpptyListForWeeklyTargetBookings.size() > 0){
            calculateRevenueForecastWeeklyTargetBookings(closedWonOpptyListForWeeklyTargetBookings);
        }

        //Create Project Roles and Billing Rates for Change Order gone to or From Closed Won
        if(changeOrderToClosedWonList.size() > 0){
            System.debug('Change Order to Closed Won List: ' + changeOrderToClosedWonList);
            ProjectRoleManager.ProjectRoleManager_Handler(changeOrderToClosedWonList);
            ProjectBillingRateManager.ProjectBillingRateManager_Handler(changeOrderToClosedWonList);
        }

        if(closedWonParentOpptyCloseDateChangeList.size() > 0){
            OpportunityTriggerHelper.closedWonParentOpptyCloseDateChange(closedWonParentOpptyCloseDateChangeList);
        }

        if(closedWonParentOpptyList.size() > 0){
            OpportunityTriggerHelper.createPlaceholderForecastsOnCW(closedWonParentOpptyList);
            ProjectRoleManager.ProjectRoleManager_Handler(closedWonParentOpptyList);
            StaffingAssignmentTriggerHelper.createProjTeamMembersFromOpptyCW(closedWonParentOpptyList);
            ProjectBillingRateManager.ProjectBillingRateManager_Handler(closedWonParentOpptyList);
        }

        if(esaProjectIdChangedOpptyMap.size() > 0){
            OpportunityTriggerHelper.updateTimeEntriesOnESAProjectIdUpdate(esaProjectIdChangedOpptyMap, newEsaProjectIdToOldEsaProjectIdMap);
        }

        if(CheckFirst.calculateOpp == true) { //Added from Opportunity After Trigger
			if(relOppReCalc.size() > 0){
				OpportunityCalculations.relOppReCalc(relOppReCalc);
			}
		}

        //From ProjectHandler
        if(opptyIdToOpptyInvoiceChangeMap.size() > 0){
            OpportunityTriggerHelper.updateInvoicedTotalsOnRelatedProject(opptyIdToOpptyInvoiceChangeMap);
        }

        //ST 9.26.2023 Check for Low Rate Oppty Product Alert
        if(checkForLowRateNAOpptyProdOpptyIdSet.size() > 0){
            System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$ sendLowRateOpptyProductAlert $$$$$$$$$$$$$$$$$$$$$@@@@@@@@@@@@@@@@@@@@');
            OpportunityTriggerHelper.sendLowRateOpptyProductAlert(checkForLowRateNAOpptyProdOpptyIdSet);
        }
        
        if(changeOrdersReassignedParentOpptyIdSet.size() > 0){ //Update Opportunity Before and After
            ProjectBillingRateManager.updateParentOpptyWhenChangeOrdersAreReassigned(changeOrdersReassignedParentOpptyIdSet);
            ProjectRoleManager.createProjectRolesOnChangeOrderReassignment(changeOrdersReassignedParentOpptyIdSet);
        }
    }

    /*public static void beforeDelete(List<Opportunity> opportunityList) {
    }*/

    public static void afterDelete(List<Opportunity> opportunityList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> relOppReCalc = new Set<Id>();
        List<Opportunity> changeOrderOpptyList = new List<Opportunity>();
        for(Opportunity oppty : opportunityList) {

            if(oppty.RecordTypeId == changeOrderOpptyRT){
                changeOrderOpptyList.add(oppty);
                if(oppty.Change_Orders__c != null){ //From OpportunityAfter Trigger
                    relOppReCalc.add(oppty.Change_Orders__c);
                }
            }   

            accountIds.add(oppty.AccountId);
        }

        if(accountIds.size() > 0){
            updateAccountFirstYearBooking(accountIds);
            rollupTotalOpptyCountOnAccount(accountIds); //Total Opportunities DLRS Replacement - ST 1/9/2023
        }

        if(changeOrderOpptyList.size() > 0){
            totalProjDurationOfCOAfterDelete(changeOrderOpptyList);
        }

        //From OpportunityAfter Trigger
        if(CheckFirst.calculateOpp == true) {
			if(relOppReCalc.size() > 0){
				OpportunityCalculations.relOppReCalc(relOppReCalc);
			}
		}
    }

    public static void afterUndelete(List<Opportunity> opportunityList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> relOppReCalc = new Set<Id>();

        for(Opportunity oppty : opportunityList) {

            accountIds.add(oppty.AccountId);

            if(oppty.RecordTypeId == changeOrderOpptyRT && oppty.Change_Orders__c != null){
                relOppReCalc.add(oppty.Id);
            }
        }

        if(accountIds.size() > 0){
            updateAccountFirstYearBooking(accountIds);
            rollupTotalOpptyCountOnAccount(accountIds); //Total Opportunities DLRS Replacement - ST 1/9/2023
        }

        if(CheckFirst.calculateOpp == true) {
			if(relOppReCalc.size() > 0){
				OpportunityCalculations.relOppReCalc(relOppReCalc);
			}
		}
    }


    /**
     * <p>Updates a list of Accounts Lowest Project Budget Remaining value to the
     * value of an open child Opportunity's Budget Remaining Percentage.</p>
     *
     * This method is also fired from the OpportunityLineItem object which is why
     * it is public.
     */

     //TODO
    public static void updateAccountLowestProjectBudgetRemaining(Set<Id> accountIds) {
        if(accountIds.size()>0) {
            Opportunity[] opportunities = [SELECT Id, AccountId, Percent_Of_Budget_Remaining__c, Account.Lowest_Project_Budget_Remaining_Percent__c, Account.Name
                                            FROM Opportunity 
                                            WHERE AccountId IN :accountIds AND IsClosed = false];
            if(opportunities.size() > 0) {
                Account[] updatedAccounts = updateAccountLowestProjectBudgetRemaining(opportunities);
                if(updatedAccounts.size()>0)
                {
                    update updatedAccounts;
                }
            }
        }
    }

    //=========================================================================
    //  PRIVATE METHODS
    //=========================================================================
    /**
     * Updates the First_Year_Booking__c field to the sum of Amount of all child
     * opportunities that are Closed/Won.
     *
     * IMPORTANT:
     * Right now the total only properly aggregates if one child record of an account
     * has a DML operation in batch operations.
     *
     * @param accountIds The set of Account Ids to aggregate
     */
    private static void updateAccountFirstYearBooking(Set<Id> accountIds) {
        System.debug('****************************---------------------------------------- Opportunity Trigger Handler: Update Account First Year Booking ---------------------------------------**************************************');
        // retrieve current accounts to compare anniversary dates
        Map<Id, Opportunity> accountIdToOpptyWithAcctDetails = new Map<Id, Opportunity>();
        Map<Id, Decimal> updatedAccountIdToFirstYearBookingAmountMap = new Map<Id, Decimal>();
        List<Account> accountsToUpdateList = new List<Account>();

        // retireve opportunities to aggregate even deleted ones so an account can be
        // zeroed out if neccessary
        for(Opportunity o : [SELECT Id, Name, StageName, AccountId, Account.First_Year_Booking__c, Account.First_Anniversary__c, Account.Customer_Since__c, Amount, CloseDate, IsDeleted, IsWon FROM Opportunity WHERE AccountId IN :accountIds ALL ROWS]) {
            // initialize account sum to 0
            if(!accountIdToOpptyWithAcctDetails.containsKey(o.AccountId)) {
                accountIdToOpptyWithAcctDetails.put(o.AccountId, o);
                updatedAccountIdToFirstYearBookingAmountMap.put(o.AccountId, 0);
            }

            // only iterate through accounts that havent been deleted
            if(!o.IsDeleted && o.IsWon) {
                Opportunity opptyWithAccountDetails = accountIdToOpptyWithAcctDetails.get(o.AccountId);

                // verify the amount has a value and that the opportunity close date falls between
                // the account customer since date and the first year anniversary
                if(o.Amount != null && o.CloseDate >= opptyWithAccountDetails.Account.Customer_Since__c && o.CloseDate <= opptyWithAccountDetails.Account.First_Anniversary__c) {
                    Decimal firstYearBookingAmount = updatedAccountIdToFirstYearBookingAmountMap.get(o.AccountId);
                    firstYearBookingAmount += o.Amount;
                    updatedAccountIdToFirstYearBookingAmountMap.put(o.AccountId, firstYearBookingAmount);
                }
                // update first year booking when a customers first deal goes closed won
                else if(o.IsWon && opptyWithAccountDetails.Account.Customer_Since__c == null) {
                    updatedAccountIdToFirstYearBookingAmountMap.put(o.AccountId, o.Amount);
                }
            }
        }

        //Loop through the map of accounts to see if there is a update needed, if so add to the update list
        for(Opportunity opp : accountIdToOpptyWithAcctDetails.values()){
            if(updatedAccountIdToFirstYearBookingAmountMap.containsKey(opp.AccountId)){
                if(opp.Account.First_Year_Booking__c != updatedAccountIdToFirstYearBookingAmountMap.get(opp.AccountId)){
                    Account updateAccount = new Account(Id = opp.AccountId);
                    updateAccount.First_Year_Booking__c = updatedAccountIdToFirstYearBookingAmountMap.get(opp.AccountId);
                    accountsToUpdateList.add(updateAccount);
                }
            }
        }

        if(accountsToUpdateList.size() > 0){
            update accountsToUpdateList;
        } 
    }

    private static List<Account> updateAccountLowestProjectBudgetRemaining(List<Opportunity> opportunities) {
        Map<Id, Decimal> accountBudgetMap = new Map<Id, Decimal>();
        Map<Id, Account> accountMap = new Map<Id, Account>();

        // query all related opportunities to the accounts
        for(Opportunity o : opportunities) {
            System.debug('Account Name: ' + o.Account.Name + ' Account ID: ' + o.AccountId);
            System.debug('o.Percent_Of_Budget_Remaining__c: ' + o.Percent_Of_Budget_Remaining__c);
            System.debug('o.Account.Lowest_Project_Budget_Remaining_Percent__c: ' + o.Account.Lowest_Project_Budget_Remaining_Percent__c);
            if(accountMap.containsKey(o.AccountId)) {
                // get the current budget record to compare values
                Account a = accountMap.get(o.AccountId);
                if(o.Percent_Of_Budget_Remaining__c < o.Account.Lowest_Project_Budget_Remaining_Percent__c){ //Only add it to the update map if the value needs to change -- Update 5/18/2022
                    a.Lowest_Project_Budget_Remaining_Percent__c = o.Percent_Of_Budget_Remaining__c;
                    accountMap.put(o.AccountId, a);
                }
            } else {

                if(o.Account.Lowest_Project_Budget_Remaining_Percent__c == null || o.Percent_Of_Budget_Remaining__c < o.Account.Lowest_Project_Budget_Remaining_Percent__c){ //Only add it to the update map if the value needs to change -- Update 5/18/2022
                    Account a = new Account(Id = o.AccountId);
                    a.Lowest_Project_Budget_Remaining_Percent__c = o.Percent_Of_Budget_Remaining__c;
                    accountMap.put(o.AccountId, a);
                }
            }
        }
        System.debug('Account Map: ' + accountMap);
        return accountMap.values();
    }

    /**
     * Enqueues a background apex job to update corresponding replicon projects when the
     * associated fields on the Opportunity record are changed
     */

    private static void upsertRepliconProjects(Set<Id> opportunityIds) {
        // retrieve project to update
        //System.debug('CheckFirst.IfRun: '+ CheckFirst.IfRun);
        System.debug('opportunityIds: '+ opportunityIds);

        if(CheckFirst.IfRun==true){
            for(Project__c project : [SELECT Id FROM Project__c WHERE Opportunity__c IN :opportunityIds]) {

                System.debug('project debug: '+project);

                RepliconProjectUpsert projectUpsert = new RepliconProjectUpsert(project.Id,true);
                system.enqueueJob(projectUpsert);
            }
        }
        CheckFirst.IfRun =  false;
    }

    /**
     * Checks if the fields relevant to the Replicon integration have changed
     */
    private static Boolean isRepliconFieldsChanged(Opportunity opportunity, Opportunity oldOpportunity) {
        if(opportunity.IsWon || opportunity.Create_Project__c==true) {
            if(opportunity.Amount != oldOpportunity.Amount) return true;
            if(opportunity.SOW_Number__c != oldOpportunity.SOW_Number__c) return true;
            if(opportunity.Total_Hours__c != oldOpportunity.Total_Hours__c) return true;
            if(opportunity.Project_Terms__c != oldOpportunity.Project_Terms__c) return true;
            if(opportunity.Payment_Terms__c != oldOpportunity.Payment_Terms__c) return true;
            if(opportunity.Interested_In__c != oldOpportunity.Interested_In__c) return true;
            if(opportunity.LevementumVertical__c != oldOpportunity.LevementumVertical__c) return true;
            if(opportunity.SubPractice__c != oldOpportunity.SubPractice__c) return true;
            if(opportunity.Payment_Schedule__c != oldOpportunity.Payment_Schedule__c) return true;
            if(opportunity.CloseDate != oldOpportunity.CloseDate) return true;
        }
        return false;
    }

    /******** Added functionality for Total Expected Proj Duration in Weeks of COs - 8/30/2021 - Sam Tucker ********/

    //onAfter Insert for Change Orders
    private static void totalProjDurationOfCOAfterInsert(List<Opportunity> newChangeOrderOpptyList){
        //Expected_Duration_in_Weeks_of_COs__c
        //1.) Put Parent Ids into a List
        //2.) Create Map of <Parent Oppty Id, ExpectProj Duration in Weeks>
        Map<Id, Decimal> parentOpptyToCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();
        parentOpptyToCOExpProjDurationInWeeksMap = getParentOpptyToProjectDurationInWeeksMap(newChangeOrderOpptyList, false, null);

        //Query for all Parent Ids
        List<Opportunity> parentOpptyList = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c, Expected_Duration_in_Weeks_of_COs__c FROM Opportunity WHERE Id IN :parentOpptyToCOExpProjDurationInWeeksMap.keySet()];
        
        //Add Duration map value to the existing Expected_Duration_in_Weeks_of_COs__c
        List<Opportunity> parentOpptyToUpdate = new List<Opportunity>();
        List<Opportunity> nullCODurationParentOpptyToUpdate = new List<Opportunity>();
        for(Opportunity parentOppty : parentOpptyList){

            if(parentOpptyToCOExpProjDurationInWeeksMap.containsKey(parentOppty.Id)){
                if(parentOppty.Expected_Duration_in_Weeks_of_COs__c != null){

                    parentOppty.Expected_Duration_in_Weeks_of_COs__c += parentOpptyToCOExpProjDurationInWeeksMap.get(parentOppty.Id);
                    parentOpptyToUpdate.add(parentOppty);                    
                }else{  
                    nullCODurationParentOpptyToUpdate.add(parentOppty);
                }
            }

        }

        if(nullCODurationParentOpptyToUpdate.size() > 0){
            populateNullExpectedProjDurationInWeeksOfCOs(nullCODurationParentOpptyToUpdate);
        }

        if(parentOpptyToUpdate.size() > 0){
            update parentOpptyToUpdate;
        }

    }

    //onAfter Update for Change Orders
    private static void totalProjDurationOfCOAfterUpdate(List<Opportunity> updatedChangeOrderOpptyList, Map<Id, Opportunity> oldOpptyMap){
        Map<Id, Decimal> parentOpptyToNEWCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();
        Map<Id, Decimal> parentOpptyToOLDCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();

        parentOpptyToNEWCOExpProjDurationInWeeksMap = getParentOpptyToProjectDurationInWeeksMap(updatedChangeOrderOpptyList, false, null);
        parentOpptyToOLDCOExpProjDurationInWeeksMap = getParentOpptyToProjectDurationInWeeksMap(updatedChangeOrderOpptyList, true, oldOpptyMap);

        //Query for all Parent Ids
        List<Opportunity> parentOpptyList = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c, Expected_Duration_in_Weeks_of_COs__c FROM Opportunity WHERE Id IN :parentOpptyToNEWCOExpProjDurationInWeeksMap.keySet()];
        
        //Add Duration map value to the existing Expected_Duration_in_Weeks_of_COs__c
        //List<Opportunity> parentOpptyToUpdate = new List<Opportunity>();
        List<Opportunity> nullCODurationParentOpptyToUpdate = new List<Opportunity>();
        for(Opportunity parentOppty : parentOpptyList){

            if(parentOpptyToNEWCOExpProjDurationInWeeksMap.containsKey(parentOppty.Id)){
                /*if(parentOppty.Expected_Duration_in_Weeks_of_COs__c == null){
                    parentOppty.Expected_Duration_in_Weeks_of_COs__c -= parentOpptyToOLDCOExpProjDurationInWeeksMap.get(parentOppty.Id);
                    parentOppty.Expected_Duration_in_Weeks_of_COs__c += parentOpptyToNEWCOExpProjDurationInWeeksMap.get(parentOppty.Id);
                    parentOpptyToUpdate.add(parentOppty);                    
                }else{  
                    nullCODurationParentOpptyToUpdate.add(parentOppty);
                }*/
                nullCODurationParentOpptyToUpdate.add(parentOppty);
            }

        }

        if(nullCODurationParentOpptyToUpdate.size() > 0){
            populateNullExpectedProjDurationInWeeksOfCOs(nullCODurationParentOpptyToUpdate);
        }

        /*if(parentOpptyToUpdate.size() > 0){
            update parentOpptyToUpdate;
        }*/
    }

    //onAfter Delete for Change Orders
    private static void totalProjDurationOfCOAfterDelete(List<Opportunity> deletedChangeOrderOpptyList){
        
        Map<Id, Decimal> parentOpptyToCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();
        parentOpptyToCOExpProjDurationInWeeksMap = getParentOpptyToProjectDurationInWeeksMap(deletedChangeOrderOpptyList, false, null);

        //Query for all Parent Ids
        List<Opportunity> parentOpptyList = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c, Expected_Duration_in_Weeks_of_COs__c FROM Opportunity WHERE Id IN :parentOpptyToCOExpProjDurationInWeeksMap.keySet()];
        
        //Add Duration map value to the existing Expected_Duration_in_Weeks_of_COs__c
        List<Opportunity> parentOpptyToUpdate = new List<Opportunity>();
        List<Opportunity> nullCODurationParentOpptyToUpdate = new List<Opportunity>();
        for(Opportunity parentOppty : parentOpptyList){

            if(parentOpptyToCOExpProjDurationInWeeksMap.containsKey(parentOppty.Id)){
                if(parentOppty.Expected_Duration_in_Weeks_of_COs__c != null){

                    parentOppty.Expected_Duration_in_Weeks_of_COs__c -= parentOpptyToCOExpProjDurationInWeeksMap.get(parentOppty.Id);
                    parentOpptyToUpdate.add(parentOppty);                    
                }else{  
                    nullCODurationParentOpptyToUpdate.add(parentOppty);
                }
            }
        }

        if(nullCODurationParentOpptyToUpdate.size() > 0){
            populateNullExpectedProjDurationInWeeksOfCOs(nullCODurationParentOpptyToUpdate);
        }

        if(parentOpptyToUpdate.size() > 0){
            update parentOpptyToUpdate;
        }

    }

    private static void populateNullExpectedProjDurationInWeeksOfCOs(List<Opportunity> opptysToPopulate){
        System.debug('############### populateNullExpectedProjDurationInWeeksOfCOs');
        
        List<Id> opptyIdList = new List<Id>();
        for(Opportunity opp : opptysToPopulate){
            opptyIdList.add(opp.Id);
        }       
        
        List<Opportunity> salesforceOpptyList = new List<Opportunity>();
        salesforceOpptyList = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c, Expected_Duration_in_Weeks_of_COs__c
                                FROM Opportunity
                                WHERE RecordTypeId =: salesforceOpptyRT AND Id IN :opptyIdList];

        Map<Id, Opportunity> parentOpptyIdToOpptyMap = new Map<Id, Opportunity>();
        for(Opportunity sfOpp : salesforceOpptyList){
            
            parentOpptyIdToOpptyMap.put(sfOpp.Id, sfOpp);
        }

        //Create Map of Parent Oppty to the Expected proj Duration in weeks of all Change Orders
        List<Opportunity> changeOrderOpptyList = new List<Opportunity>();
        changeOrderOpptyList = [SELECT Id, Name, ExpectedPro_DurationinWeeks__c, Change_Orders__c
                                FROM Opportunity
                                WHERE RecordTypeId =: changeOrderOpptyRT AND ExpectedPro_DurationinWeeks__c != null AND ExpectedPro_DurationinWeeks__c != 0 AND Change_Orders__c IN :parentOpptyIdToOpptyMap.keySet()];

        Map<Id, Decimal> parentOpptyToDurationInWeeksforCOsMap = new Map<Id, Decimal>();
        for(Opportunity coOppty : changeOrderOpptyList){
            if(parentOpptyToDurationInWeeksforCOsMap.containsKey(coOppty.Change_Orders__c)){
                //For if there are multiple Change Orders for the same parent oppty
                Decimal addToDurationInWeeksOfCO = coOppty.ExpectedPro_DurationinWeeks__c + parentOpptyToDurationInWeeksforCOsMap.get(coOppty.Change_Orders__c);
                parentOpptyToDurationInWeeksforCOsMap.put(coOppty.Change_Orders__c, addToDurationInWeeksOfCO);
            }else{
                parentOpptyToDurationInWeeksforCOsMap.put(coOppty.Change_Orders__c, coOppty.ExpectedPro_DurationinWeeks__c);
            }
        }


        //Loop Through Parent Opptys and Assign Expected_Duration_in_Weeks_of_COs__c value from rollup up Change Order Duration
        List<Opportunity> opptysToUpdateList = new List<Opportunity>();
        for (Opportunity opp : parentOpptyIdToOpptyMap.values()){
            
            if(parentOpptyToDurationInWeeksforCOsMap.containsKey(opp.Id)){
                opp.Expected_Duration_in_Weeks_of_COs__c = parentOpptyToDurationInWeeksforCOsMap.get(opp.Id);        
            }else{
                opp.Expected_Duration_in_Weeks_of_COs__c = 0;        
            }
            opptysToUpdateList.add(opp);
        }

        if(opptysToUpdateList.size() > 0){
            update opptysToUpdateList;
        }
    }

    private static Map<Id, Decimal> getParentOpptyToProjectDurationInWeeksMap(List<Opportunity> opptysToPopulate, Boolean isOnUpdate, Map<Id, Opportunity> oldOpptyMap){
        Map<Id, Decimal> parentOpptyToCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();
        Map<Id, Decimal> parentOpptyToOLDCOExpProjDurationInWeeksMap = new Map<Id, Decimal>();

        for(Opportunity opp : opptysToPopulate){

            if(opp.Change_Orders__c != null){
                if(parentOpptyToCOExpProjDurationInWeeksMap.containsKey(opp.Change_Orders__c)){
                    //If already in Map add Duration to already existing Map value
                    Decimal additionalExpectedProjDurationInWeeks = opp.ExpectedPro_DurationinWeeks__c != null ? opp.ExpectedPro_DurationinWeeks__c + parentOpptyToCOExpProjDurationInWeeksMap.get(opp.Change_Orders__c) : parentOpptyToCOExpProjDurationInWeeksMap.get(opp.Change_Orders__c);
                    parentOpptyToCOExpProjDurationInWeeksMap.put(opp.Change_Orders__c, additionalExpectedProjDurationInWeeks);

                    if(isOnUpdate){
                        //Create Map for Old Duration
                        Decimal additionalOldExpectedProjDurationInWeeks = oldOpptyMap.get(opp.Id).ExpectedPro_DurationinWeeks__c != null ? oldOpptyMap.get(opp.Id).ExpectedPro_DurationinWeeks__c + parentOpptyToOLDCOExpProjDurationInWeeksMap.get(opp.Change_Orders__c) : parentOpptyToOLDCOExpProjDurationInWeeksMap.get(opp.Change_Orders__c);
                        parentOpptyToOLDCOExpProjDurationInWeeksMap.put(opp.Change_Orders__c, additionalOldExpectedProjDurationInWeeks);
                    }
                }else{
                    //If not in the Map already then put
                    Decimal expectedProjDurationInWeeks = opp.ExpectedPro_DurationinWeeks__c != null ? opp.ExpectedPro_DurationinWeeks__c : 0;
                    parentOpptyToCOExpProjDurationInWeeksMap.put(opp.Change_Orders__c, expectedProjDurationInWeeks);

                    if(isOnUpdate){
                        //Create Map for Old Duration
                        Decimal oldExpectedProjDurationInWeeks = oldOpptyMap.get(opp.Id).ExpectedPro_DurationinWeeks__c != null ? oldOpptyMap.get(opp.Id).ExpectedPro_DurationinWeeks__c : 0;
                        parentOpptyToOLDCOExpProjDurationInWeeksMap.put(opp.Change_Orders__c, oldExpectedProjDurationInWeeks);
                    }
                }
            }
        }
        if(isOnUpdate){
            return parentOpptyToOLDCOExpProjDurationInWeeksMap;
        }else{
            return parentOpptyToCOExpProjDurationInWeeksMap;
        }
    }

    private static void checkOverallProductRate(Set<Id> opptyIdList, Map<Id, Opportunity> parentOpptyToMostRecentClosedWonCOOpptyMap){
        //OppLineTriggerHelper.checkOverallProductRateType(opptyIdList);

        List<Opportunity> parentOpptyToUpdateList = new List<Opportunity>();
        Boolean updateParentOppty = false;
        if(parentOpptyToMostRecentClosedWonCOOpptyMap.size() > 0){
            List<Opportunity> parentOpptyList = new List<Opportunity>();
            parentOpptyList = [SELECT Id, Name, Most_Recent_Closed_Won_CO__c, Most_Recent_CO_Product_Type__c
                                FROM Opportunity 
                                WHERE Id IN :parentOpptyToMostRecentClosedWonCOOpptyMap.keySet()];

            for(Opportunity opp : parentOpptyList){
                if(opp.Most_Recent_Closed_Won_CO__c != parentOpptyToMostRecentClosedWonCOOpptyMap.get(opp.Id).Id){
                    opp.Most_Recent_Closed_Won_CO__c = parentOpptyToMostRecentClosedWonCOOpptyMap.get(opp.Id).Id;
                    updateParentOppty = true;
                }
                if(opp.Most_Recent_CO_Product_Type__c != parentOpptyToMostRecentClosedWonCOOpptyMap.get(opp.Id).CO_Product_Rate_Type__c){
                    opp.Most_Recent_CO_Product_Type__c = parentOpptyToMostRecentClosedWonCOOpptyMap.get(opp.Id).CO_Product_Rate_Type__c;
                    updateParentOppty = true;
                }

                if(updateParentOppty){
                    parentOpptyToUpdateList.add(opp);
                }
            }

            if(parentOpptyToUpdateList.size() > 0){
                update parentOpptyToUpdateList;
            }
        }

    }

    private static void populatePMonCOInsert(List<Opportunity> coOpptyList){

        //Get Parent Opportunity
        //Map Parent Oppty Id to PM Id
        //Loop through Change Order Oppty and check Parent Oppty Map for PM Id

        List<Id> parentOpptyIdList = new List<Id>();
        for(Opportunity opp : coOpptyList){
            if(opp.Change_Orders__c != null){
                parentOpptyIdList.add(opp.Change_Orders__c);
            }
        }

        List<Opportunity> parentOpptyList = new List<Opportunity>();
        parentOpptyList = [SELECT Id, Project_ManagerLookup__c, Change_Orders__c, RecordTypeId 
                            FROM Opportunity
                            WHERE Id IN :parentOpptyIdList AND Project_ManagerLookup__c != null ];

        Map<Id, Id> parentOppToPMIdMap = new Map<Id, Id>();
        for(Opportunity parentOpp : parentOpptyList){
            parentOppToPMIdMap.put(parentOpp.Id, parentOpp.Project_ManagerLookup__c);
        }

        for(Opportunity opp : coOpptyList){
            if(parentOppToPMIdMap.containsKey(opp.Change_Orders__c)){
                opp.Project_ManagerLookup__c = parentOppToPMIdMap.get(opp.Change_Orders__c);
            }
        }
    }

    private static void checkOpptyProductsResourceAllocationOnOpptyCW(List<Opportunity> opptyList){

        //Query for Oppty Products
        //If Project Terms = Fixed Utilization or Fixed Capacity then make sure Resource Allocation is filled out on all Products
        //If not filled out addError() to Opportunity
        Map<Id, Opportunity> opptyIdMap = new Map<Id, Opportunity>();
        for(Opportunity opp : opptyList){
            opptyIdMap.put(opp.Id, opp);
        }

        List<OpportunityLineItem> relatedOpptyLineItems = new List<OpportunityLineItem>();
        relatedOpptyLineItems = [SELECT Id, Name, Resource_Allocation_Type__c, OpportunityId, Opportunity.Project_Terms__c, Opportunity_Product_Family__c 
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId IN :opptyIdMap.keySet() AND Product2.Name != 'Adobe Consulting'];

        for(OpportunityLineItem oli : relatedOpptyLineItems){
            
            //if(professionalServicesProductFamilyTypeList.contains(oli.Product_Family_Hidden__c)){ //Add 2/3/2022 to only run validations for Products that are 'Professional Services' Or 'Services' for the Product Family Hidden field
            if(professionalServicesProductFamilyTypeList.contains(oli.Opportunity_Product_Family__c)){ //Added 2/24/2022 to only run validations for Products that are 'Professional Services' Or 'Services' for the Opportunity Product Family field
                
                if(productResourceAlloReqProjTermsList.contains(oli.Opportunity.Project_Terms__c) && String.isBlank(oli.Resource_Allocation_Type__c)){ //If Project Terms = 'Fixed Utility' OR 'Fixed Capacity' and Resource Allocation IS NOT populated then throw error
                //Commented out 8.23.2023 ST For Winzone Integration
                //opptyIdMap.get(oli.OpportunityId).addError('When the Oppty\'s Project Terms are either Fixed Utilization or Fixed Capacity, ALL Products (except "Adobe Consulting") need to have the “Resource Allocation Type” field filled out. Please go into each applicable Product to make this update.');
                    //opptyIdMap.get(oli.OpportunityId).addError('Project_Terms__c', 'When Project Terms is Fixed Utilitization or Fixed Capacity all Opportunity Products must have Resource Allocation Populated');
                }else if(!productResourceAlloReqProjTermsList.contains(oli.Opportunity.Project_Terms__c) && !String.isBlank(oli.Resource_Allocation_Type__c)){ //If Project Terms DOES NOT EQUAL 'Fixed Utility' OR 'Fixed Capacity' and Resource Allocation IS populated then throw error

                    //opptyIdMap.get(oli.OpportunityId).addError('When the Oppty\'s Project Terms are NOT Fixed Utilization or Fixed Capacity, ALL Products should not have a value listed in the “Resource Allocation Type” field filled out. Please go into each Product to remove your previous selections.');
                }
            }
        }
    }

    private static void calculateRevenueForecastWeeklyTargetBookings(List<Opportunity> oppList){
        /**
         * Purpose: 
         * Calculate the Bookings for the Revenue Forecast Weekly Target
         * This function will run when an Opportunity moves to Closed Won and will rollup the Opportunity Amounts from all Opportunities Closed Won on that week and populate the Bookings__c field on the respective Revenue Forecast Weekly Target record
         * 
         * Functionality: 
         * Get passed in the Opportunities from Trigger when updating to StageName = 'Closed Won' 
         * Loop through the Opportunities and get List of the CloseDate field that is updated to the current date when Oppty gets moved to Closed Won
         * 
         * Sum all of the Opportunities that are Closed Won and CloseDate are within the same week as the Oppty/Opptys that are passed in
         * Get the Week End Date of the current date (Closed Won CloseDate)
         * Query for the Revenue Forecast Weekly Targets that it should be totaled on to. (i.e. The Revenue Forecast Weekly Target that is representative of the Week that the Oppty moved to Closed Won)
         * Populate the Bookings__c field for the respective Weekly Target 
         * Update the Weekly Target
         * 
         */

        Date closeDateStartOfWeekDate;
        List<Date> opptyCloseDateWeekDatesList = new List<Date>();
        Map<Date, Opportunity> incomingOpptysMap = new Map<Date, Opportunity>();

        for(Opportunity opp : oppList){
            //Get the Start And End Dates of the Week that the newly Closed Won oppty Moved to Closed Won
            if(opp.CloseDate != null){
                closeDateStartOfWeekDate = opp.CloseDate.toStartOfWeek(); //Get the Start of the Week of the Close Date (Sunday of that week)
                opptyCloseDateWeekDatesList.add(closeDateStartOfWeekDate); //Add Sunday to the list of close dates to 
                if(opp.CloseDate.month() != closeDateStartOfWeekDate.month()){ //If the start of the week is not the same week as the close date then instead use the end of the week.
                    incomingOpptysMap.put(closeDateStartOfWeekDate.addDays(6), opp); //This will make it so the booking will get associated with the specific weekly target record even if it happens on a week that spans 2 months.
                }else{
                    incomingOpptysMap.put(closeDateStartOfWeekDate, opp);
                }

                Date nextDayOfWeek;
                for(Integer i = 1; i <= 6; i++){ //Iterate 6 times to add each day of the week to the list (Monday - Saturday)
                    nextDayOfWeek = closeDateStartOfWeekDate.addDays(i);
                    opptyCloseDateWeekDatesList.add(nextDayOfWeek); 
                }
            }
        }

        List<Opportunity> closedWonOpptysList = new List<Opportunity>();
        //Query for all the Closed Won Opptys that were closed on the same week as any Oppty passed to this function
        closedWonOpptysList = [SELECT Id, Name, Amount, CloseDate, StageName
                                FROM Opportunity
                                WHERE CloseDate IN :opptyCloseDateWeekDatesList AND StageName IN :opportunityClosedWonStageNames];

        Date weekStartDate;
        Map<Date, Decimal> closeDateWeeklyTargetToBookingsAmountMap = new Map<Date, Decimal>();
        if(closedWonOpptysList.size() > 0){
            for(Opportunity opp : closedWonOpptysList){
                //Loop through Opptys and Create Map of Start of CloseDate Week to the sum of all Amounts for that Closed Date
                /**
                 * In case we only want to associate the bookings amount with the specific Weekly Target the Opptys closed date falls under
                 * we need to check to see if the start of week date of the close date is the same month as the Closed date
                 * If the Sunday of that week is not the same month as the Close Date then get the saturday of that week and map the amount to that day instead
                 * In this scenario we would also query the Weekly Targets by the Week Start Date and Week End Date instead of just the Full Week Start Date
                 */
                if(opp.CloseDate != null){
                    Date weeklyTargetDate;
                    weekStartDate = opp.CloseDate.toStartOfWeek();
                    if(opp.CloseDate.month() != weekStartDate.month()){ //If the start of the week is not the same week as the close date then instead use the end of the week.
                        weeklyTargetDate = weekStartDate.addDays(6);    //This will make it so the booking will get associated with the specific weekly target record even if it happens on a week that spans 2 months.
                    }else{
                        weeklyTargetDate = weekStartDate;
                    }
                    if(closeDateWeeklyTargetToBookingsAmountMap.containsKey(weeklyTargetDate)){
                        //If the Week Start date is already in the map then add to the existing amount
                        Decimal bookingsAmount = closeDateWeeklyTargetToBookingsAmountMap.get(weeklyTargetDate);
                        Decimal addToBookingsAmount = opp.Amount != null ? opp.Amount : 0;
                        bookingsAmount += addTobookingsAmount;
                        closeDateWeeklyTargetToBookingsAmountMap.put(weeklyTargetDate, bookingsAmount);
                    }else{
                        //If the Week Start date is not yet in the map then initialize it in the map with the amount
                        Decimal bookingsAmount = opp.Amount != null ? opp.Amount : 0;
                        closeDateWeeklyTargetToBookingsAmountMap.put(weeklyTargetDate, bookingsAmount);
                    }
                }     
            }
        }else{
            //If the change to the Oppty results in 0 Opptys closed Won related to the same week then set the Bookings to 0 for that Weekly Target
            for(Opportunity opp : incomingOpptysMap.values()){
                if(opp.CloseDate != null){
                    Date weeklyTargetDate;
                    weekStartDate = opp.CloseDate.toStartOfWeek();
                    if(opp.CloseDate.month() != weekStartDate.month()){
                        weeklyTargetDate = weekStartDate.addDays(6);
                    }else{
                        weeklyTargetDate = weekStartDate;
                    }
                    closeDateWeeklyTargetToBookingsAmountMap.put(weeklyTargetDate, 0);
                }
            }
        }
        //To ensure that all Opptys Week Dates are included
        //Ensures that if Closed Won Oppty remains Closed Won but the Close Date changes
        for(Date opptyCloseDate : incomingOpptysMap.keySet()){
            if(!closeDateWeeklyTargetToBookingsAmountMap.containsKey(opptyCloseDate)){
                closeDateWeeklyTargetToBookingsAmountMap.put(opptyCloseDate, 0);
            }
        }        

        List<Revenue_Forecast__c> weeklyTargetList = new List<Revenue_Forecast__c>();
        weeklyTargetList = [SELECT Id, Bookings__c, FullWeekStartDate__c, WeekStartDate__c, WeekEndDate__c
                            FROM Revenue_Forecast__c
                            WHERE (WeekStartDate__c IN :closeDateWeeklyTargetToBookingsAmountMap.keySet() OR WeekEndDate__c IN :closeDateWeeklyTargetToBookingsAmountMap.keySet()) AND RecordTypeId =: weeklyTargetRT];


        List<Revenue_Forecast__c> weeklyTargetToUpdateList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : weeklyTargetList){

            if(closeDateWeeklyTargetToBookingsAmountMap.containsKey(rf.WeekStartDate__c)){
                if(rf.Bookings__c != closeDateWeeklyTargetToBookingsAmountMap.get(rf.WeekStartDate__c)){ //If the Date is a Start Date
                    rf.Bookings__c = closeDateWeeklyTargetToBookingsAmountMap.get(rf.WeekStartDate__c); //Only update the Bookings amount on the Weekly Target if it changes 
                    weeklyTargetToUpdateList.add(rf);
                }
            }else if(closeDateWeeklyTargetToBookingsAmountMap.containsKey(rf.WeekEndDate__c)){ //If the Date is a End Date then update that Weekly Target
                if(rf.Bookings__c != closeDateWeeklyTargetToBookingsAmountMap.get(rf.WeekEndDate__c)){ 
                    rf.Bookings__c = closeDateWeeklyTargetToBookingsAmountMap.get(rf.WeekEndDate__c);
                    weeklyTargetToUpdateList.add(rf);
                }
            }
        }

        if(weeklyTargetToUpdateList.size() > 0){
            update weeklyTargetToUpdateList;
        }
    }

    public static void rollupTotalOpptyCountOnAccount(Set<Id> accountIdSet){

        Map<Id, Integer> accountToOpptyCountMap = new Map<Id, Integer>();
        for(Id accountId : accountIdSet){
            accountToOpptyCountMap.put(accountId, 0);
        }

        AggregateResult[] opptyAgg = [SELECT COUNT(Id), AccountId
                                        FROM Opportunity
                                        WHERE AccountId IN :accountIdSet
                                        GROUP BY AccountId];

        for(AggregateResult ar : opptyAgg){

            Integer opptyCount = (Integer)ar.get('expr0');
            Id relatedAccountId = (Id)ar.get('AccountId');

            accountToOpptyCountMap.put(relatedAccountId, opptyCount);
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, Total_Opps__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){

            if(accountToOpptyCountMap.containsKey(acc.Id)){
                Integer opptyCount = accountToOpptyCountMap.get(acc.Id);
                if(acc.Total_Opps__c != opptyCount){
                    acc.Total_Opps__c = opptyCount;
                    updateAccountList.add(acc);
                }
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating Total Opportunities Count on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }

    }
}