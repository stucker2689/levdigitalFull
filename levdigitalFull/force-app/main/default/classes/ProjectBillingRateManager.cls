/**
 * Created 4.19.2023 ST
 * Purpose: To handle the Project Billing Rates creation and updates
 */

public with sharing class ProjectBillingRateManager {

    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};

    private static List<Project_Team_Member_Billing_Rate__c> newBillRatesList = new List<Project_Team_Member_Billing_Rate__c>();
    private static Map<Id, Project__c> projectIdToProjectMap = new Map<Id, Project__c>();


    public static void ProjectBillingRateManager_Handler(List<sObject> objList){
        System.debug('*********************** ProjectBillingRateManager_Handler ************************');

        List<Project__c> projList = new List<Project__c>();
        List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
        List<Opportunity> opptyList = new List<Opportunity>();
        List<Opportunity> changeOrderToCWList = new List<Opportunity>();
        List<Opportunity> changeOrderFromCWList = new List<Opportunity>();
        List<Opportunity> closedWonOpptyList = new List<Opportunity>();

        for(sObject obj : objList){

            String objectName = String.valueOf(obj.getSObjectType());
            if(objectName == 'Project__c'){
                projList.add((Project__c)obj);

            }else if(objectName == 'Opportunity'){
                Opportunity oppty = (Opportunity)obj;
                if(oppty.RecordTypeId == changeOrderOpptyRT && opportunityClosedWonStageNames.contains(oppty.StageName)){
                    changeOrderToCWList.add(oppty);
                }
                if(oppty.RecordTypeId == salesforceOpptyRT && ((opportunityClosedWonStageNames.contains(oppty.StageName) && oppty.HasActiveProject__c > 0) || (oppty.HasActiveProject__c > 0 && oppty.Create_Project__c))){
                    closedWonOpptyList.add(oppty);
                }

            }else if(objectName == 'OpportunityLineItem'){
                oppLineItemList.add((OpportunityLineItem)obj);
            }
        }

        if(projList.size() > 0){
            createBillingRatesOnProjectInsert(projList);
        }

        if(changeOrderToCWList.size() > 0){
            System.debug('Change Order to CW List: ' + changeOrderToCWList.size());
            createProjectBillingRatesOnCWOppty(changeOrderToCWList, true);
            System.debug('changeOrderToCWList ****************************************************');
            if(newBillRatesList != null && newBillRatesList.size() > 0){
                sendNewBillRateEmailOnCOCW(newBillRatesList);
            }
        }

        if(closedWonOpptyList.size() > 0){
            createProjectBillingRatesOnCWOppty(closedWonOpptyList, false);
        }

        if(oppLineItemList.size() > 0){
            manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate(oppLineItemList);
        }
    }

    public static void updateParentOpptyWhenChangeOrdersAreReassigned(Set<Id> opptyIdSet){

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, RecordTypeId, RecordType.Name, StageName, Change_Orders__c, Change_Orders__r.StageName, Change_Orders__r.RecordTypeId, Create_Project__c, HasActiveProject__c
                        FROM Opportunity
                        WHERE Id IN :opptyIdSet];

        if(opptyList.size() > 0){
            ProjectBillingRateManager_Handler(opptyList);
        }
    }

    public static void createBillingRatesOnProjectInsert(List<Project__c> projList){

        //Call dynamic function to create Project Role Records from Projects
        syncProjectBillingRates(projList);
        
    }
    
    public static void createProjectBillingRatesOnCWOppty(List<Opportunity> opptyList, Boolean forChangeOrder){
        /**
         * Functionality:
         * When a Change Order goes Closed Won it looks for a project related to the Parent Oppty
         *      If Project exists then it looks for existing ProjectRole__c and if one exist with matchin Products then it updates the Quantity and Amount Sold, if doesn't already exist then create the ProjectRole__c record
         *      If Project doesn't exist then do nothing
         *              
         */

        System.debug('************************* Create Project Billing Rates On CW Oppty **********************************');
        List<Id> parentOpptyIdList = new List<Id>();
        for(Opportunity opp : opptyList){
            if(forChangeOrder){
                if(opp.Change_Orders__c != null){
                    parentOpptyIdList.add(opp.Change_Orders__c);
                }
            }else{
                parentOpptyIdList.add(opp.Id);
            }
        }
        
        System.debug('YADAYADAYADAYADAYADA');
        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName, Project_Manager__c, Project_Manager__r.Name, Project_Manager__r.Email
                                FROM Project__c
                                WHERE Opportunity__c IN :parentOpptyIdList];

        for(Project__c proj : relatedProjectsList){
            System.debug('Project List Name: ' + proj.Name);
            projectIdToProjectMap.put(proj.Id, proj);
        }

        if(relatedProjectsList.size() > 0){
            syncProjectBillingRates(relatedProjectsList);
        }

    }
    
    public static void manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate(List<OpportunityLineItem> opportunityLineItemList){
        /**
         * Purpose: Create Billing Rates on Project when Opportunity Line Items are created on Closed Won Opportunities or when an Opportunity goes Closed Won
         * Functionality:
         * 1.) Get the OpportunityId of all Opportunity Line Items and query for the related Opportunities of the Opportunity Line Item
         * 2.) Check to see if the Opportunity is Closed Won. If it is Closed Won then continue, otherwise the process stops here
         */

        Set<Id> opptyIdSet = new Set<Id>();
        List<Opportunity> relatedOpptyList = new List<Opportunity>();
        Set<Id> closedWonParentOpptyIdList = new Set<Id>();
        List<Project__c> relatedProjectList = new List<Project__c>();

        for(OpportunityLineItem oli : opportunityLineItemList){
            opptyIdSet.add(oli.OpportunityId);

        }

        //Retrieve Opportunities that are related to the Opportunity Line Items. Only get Closed Won Opportunities since we only want to create Billing Rates for Closed Won Opportunities.
        relatedOpptyList = [SELECT Id, Name, RecordTypeId, RecordType.Name, StageName, Change_Orders__c, Change_Orders__r.StageName, Change_Orders__r.RecordTypeId, Create_Project__c
                            FROM Opportunity 
                            WHERE Id IN :opptyIdSet AND (StageName IN :opportunityClosedWonStageNames OR Create_Project__c = true)];

        for(Opportunity oppty : relatedOpptyList){ //Loop through related Closed Won Opportunities to determine which Projects need to have Billing Rates created
            if(oppty.RecordTypeId == salesforceOpptyRT){
                closedWonParentOpptyIdList.add(oppty.Id);

            }else if(oppty.RecordTypeId == changeOrderOpptyRT && oppty.Change_Orders__c != null){
                if(oppty.Change_Orders__r.RecordTypeId == salesforceOpptyRT && (opportunityClosedWonStageNames.contains(oppty.Change_Orders__r.StageName) || oppty.Create_Project__c)){
                    closedWonParentOpptyIdList.add(oppty.Change_Orders__c);

                }
            }
        }

        if(closedWonParentOpptyIdList.size() > 0){
            relatedProjectList = [SELECT Id, Name, Project_Status__c, Opportunity__c, Opportunity__r.StageName, Project_Manager__c, Project_Manager__r.Name, Project_Manager__r.Email 
                                    FROM Project__c 
                                    WHERE Opportunity__c IN :closedWonParentOpptyIdList];

            for(Project__c proj : relatedProjectList){
                System.debug('Project List Name: ' + proj.Name);
                projectIdToProjectMap.put(proj.Id, proj);
            }
        }

        if(relatedProjectList.size() > 0){
            System.debug('***** manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate');
            syncProjectBillingRates(relatedProjectList);
        }
    }


    public static void syncProjectBillingRates(List<Project__c> projList){
        /**
         * Purpose: To sync the Opportunity Products from a Project's related Parent Opportunity and all Closed Won Change Orders related to that Parent Opportunity.
         * Usage: Called when an Opportunity goes closed Won and when an opportunity Product is created/updated on a Closed Won Opportunity.
         */

        System.debug('************************** Sync Project Billing Rates ****************************');
        Map<Id, Project__c> parentOpptyIdToProjectMap = new Map<Id, Project__c>();
        for(Project__c proj : projList){            
            if(proj.Opportunity__c != null){
                parentOpptyIdToProjectMap.put(proj.Opportunity__c, proj);
            }
        }

        if(parentOpptyIdToProjectMap.size() > 0){

            //Query for Opportunity Line Items that are on the Project's Parent Opportunity or on a Change Order of the Project's Parent Opportunity
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            oliList = [SELECT Id, Name, Product2Id, Product2.Name, Opportunity_Product_Family__c, OpportunityId, Opportunity.Change_Orders__c, Discounted_Price__c, Quantity, TotalPrice, Opportunity.RecordTypeId, Resource_Delivery_Group__c
                        FROM OpportunityLineItem
                        WHERE (OpportunityId IN :parentOpptyIdToProjectMap.keySet() OR Opportunity.Change_Orders__c IN :parentOpptyIdToProjectMap.keySet()) AND (Opportunity.StageName IN :opportunityClosedWonStageNames OR Opportunity.Create_Project__c = true) AND Product2.Name != 'Adobe Consulting' AND Product2.Family = 'Professional Services'
                        ORDER BY CreatedDate];

            Map<String, Decimal> opptyProductIdAndRateToQuantityMap = new Map<String, Decimal>();
            Map<String, Decimal> opptyProductIdAndRateToAmountMap = new Map<String, Decimal>();
            Map<Id, OpportunityLineItem> opptyProductIdToOpptyProductRecordMap = new Map<Id, OpportunityLineItem>();

            Map<String, Map<String, Decimal>> duplicateOpptyAndProductCount = new Map<String, Map<String, Decimal>>();


            for(OpportunityLineItem oli : oliList){

                opptyProductIdToOpptyProductRecordMap.put(oli.Product2Id, oli);

                String opptyIdProductIdAndRateUniqueKey;
                String opptyIdProductIdUniqueKey;

                String parentOpportunityId;
                
                //Get OpportunityId
                if(oli.Opportunity.RecordTypeId == salesforceOpptyRT){
                    parentOpportunityId = oli.OpportunityId;
                }else if(oli.Opportunity.RecordTypeId == changeOrderOpptyRT){
                    parentOpportunityId = oli.Opportunity.Change_Orders__c;
                }

                opptyIdProductIdAndRateUniqueKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c);// oppId1@prodId1@230
                opptyIdProductIdUniqueKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id);// oppId1@prodId1


                /********************* Check to see if a Record needs the 2 appended to the name if there are Opportunity Line Items on the Oppty or COs of that Oppty with same Product but different Rates ***************************/
                if(duplicateOpptyAndProductCount.containsKey(opptyIdProductIdUniqueKey)){
                    //Get the last count # of the inner map (size - 1 will get us the most recent entry to the Map)
                    
                    if(!duplicateOpptyAndProductCount.get(opptyIdProductIdUniqueKey).containsKey(opptyIdProductIdAndRateUniqueKey)){ //Check to ensure the existing OpptyId-ProductId is not the same rate as the existing entry
                        //Only add a 2 to the end of the Billing Rate name if the Rate is different but the Oppty Id - Product Id is the same
                        Decimal duplicateProductCount = duplicateOpptyAndProductCount.get(opptyIdProductIdUniqueKey).values()[duplicateOpptyAndProductCount.get(opptyIdProductIdUniqueKey).size() -1];
                        duplicateProductCount++;
                        Map<String, Decimal> duplicateOpptyAndProductAndRateNumber = duplicateOpptyAndProductCount.get(opptyIdProductIdUniqueKey);
                        duplicateOpptyAndProductAndRateNumber.put(opptyIdProductIdAndRateUniqueKey, duplicateProductCount);
                        duplicateOpptyAndProductCount.put(opptyIdProductIdUniqueKey, duplicateOpptyAndProductAndRateNumber);
                    }

                }else{
                    Map<String, Decimal> duplicateOpptyAndProductAndRateNumber = new Map<String, Decimal>();
                    Decimal duplicateProductCount = 1;
                    duplicateOpptyAndProductAndRateNumber.put(opptyIdProductIdAndRateUniqueKey, duplicateProductCount); // oppId1@prodId1@230 
                    duplicateOpptyAndProductCount.put(opptyIdProductIdUniqueKey, duplicateOpptyAndProductAndRateNumber);
                }
                
                /***********************************************************************************************************************************************************************************************************************/

                /*********************************************************************************** Set Unique key to Quantity and Amount $ *******************************************************************************************/
                //Swappped opptyIdProdIdRateAndResourceDeliveryGroupKey for opptyIdProductIdAndRateUniqueKey
                if(opptyProductIdAndRateToQuantityMap.containsKey(opptyIdProductIdAndRateUniqueKey)){
                    //If Opportuntiy + ProductId + Rate is already in map then add to existing quantity amount
                    Decimal additionalProductQuantity = oli.Quantity != null ? oli.Quantity : 0;
                    Decimal totalProductQuantity = opptyProductIdAndRateToQuantityMap.get(opptyIdProductIdAndRateUniqueKey) + additionalProductQuantity;
                    opptyProductIdAndRateToQuantityMap.put(opptyIdProductIdAndRateUniqueKey, totalProductQuantity);

                    //Do same with Amount map
                    Decimal additionalProductAmount = oli.TotalPrice != null ? oli.TotalPrice : 0;
                    Decimal totalProductAmount = opptyProductIdAndRateToAmountMap.get(opptyIdProductIdAndRateUniqueKey) + additionalProductAmount;
                    opptyProductIdAndRateToAmountMap.put(opptyIdProductIdAndRateUniqueKey, totalProductAmount);


                }else{
                    //If Opportuntiy + ProductId + Rate is not yet in map, initialize it with the Quantity
                    Decimal newProductQuantity = oli.Quantity != null ? oli.Quantity : 0;
                    opptyProductIdAndRateToQuantityMap.put(opptyIdProductIdAndRateUniqueKey, newProductQuantity);

                    //Do same with Amount map
                    Decimal newProductAmount = oli.TotalPrice != null ? oli.TotalPrice : 0;
                    opptyProductIdAndRateToAmountMap.put(opptyIdProductIdAndRateUniqueKey, newProductAmount);
                }
                /***********************************************************************************************************************************************************************************************************************/   
            }

            /*************************************************** Query existing Billing Rate Records to give Id to new records for Upsert *************************************************************************/

            List<Project_Team_Member_Billing_Rate__c> existingBillingRateRecordsList = new List<Project_Team_Member_Billing_Rate__c>();
            existingBillingRateRecordsList = [SELECT Id, Name, Project__c, Product__c, Hourly_Rate__c, Quantity_Sold__c, Total_Amount_Sold__c, Project__r.Opportunity__c, Is_Concession_Rate__c, Is_Temporary_Rate__c, Is_Placeholder_Rate__c, Outdated_Rate__c
                                                FROM Project_Team_Member_Billing_Rate__c
                                                WHERE Project__r.Opportunity__c IN :parentOpptyIdToProjectMap.keySet() ];

            Map<String, Project_Team_Member_Billing_Rate__c> existingBillingRateIdToRecordMap = new Map<String, Project_Team_Member_Billing_Rate__c>();
            Set<Id> existingBillRateIdSet = new Set<Id>();
            for(Project_Team_Member_Billing_Rate__c br : existingBillingRateRecordsList){
                List<String> billingRateKeyList = new List<String>{
                    String.valueOf(br.Project__r.Opportunity__c), 
                    String.valueOf(br.Product__c), 
                    String.valueOf(br.Hourly_Rate__c)
                };
                String existingBillingRateKey = String.join(billingRateKeyList, '@');
                existingBillingRateIdToRecordMap.put(existingBillingRateKey, br);
            }
            /*************************************************************************************************************************************************************************************************************************/ 
            
            /************************************************************* Set Insert/Update/Delete Billing Rates Record Lists ************************************************************************************/
            List<Project_Team_Member_Billing_Rate__c> billingRatesToInsertList = new List<Project_Team_Member_Billing_Rate__c>();
            List<Project_Team_Member_Billing_Rate__c> billingRatesToUpdateList = new List<Project_Team_Member_Billing_Rate__c>();
            Map<Id, Project_Team_Member_Billing_Rate__c> billingRatesToDeleteMap = new Map<Id, Project_Team_Member_Billing_Rate__c>();
            if(opptyProductIdAndRateToQuantityMap.size() > 0 || opptyProductIdAndRateToAmountMap.size() > 0){
                for(String uniqueKey : opptyProductIdAndRateToQuantityMap.keySet()){
                    //Create the Project_Team_Member_Billing_Rate__c records
                    //Id opportunityId = (Id)uniqueKey.substringBefore('@');
                    //Id productId = (Id)((uniqueKey.substringBeforeLast('@')).substringAfter('@'));
                    //String opptyIdAndProductId = uniqueKey.substringBeforeLast('@');
                    //Decimal productRate = Decimal.valueOf(uniqueKey.substringAfterLast('@'));

                    List<String> uniqueKeySplitList = new List<String>();
                    uniqueKeySplitList = uniqueKey.split('@');
                    Id opportunityId = (Id)uniqueKeySplitList[0];
                    Id productId = (Id)uniqueKeySplitList[1];
                    String opptyIdAndProductId = uniqueKeySplitList[0] + '@' + uniqueKeySplitList[1];
                    Decimal productRate = Decimal.valueOf(uniqueKeySplitList[2]);

                    Id projectId = parentOpptyIdToProjectMap.get(opportunityId).Id;

                    //If it is a duplicate Oppty ID + Product Id but with a different rate this will be > 1 otherwise 1 means it is unique for Oppty Id and Product Id
                    //If > 1 then we need to append a number to the Product Name
                    Decimal duplicateCount = duplicateOpptyAndProductCount.get(opptyIdAndProductId).get(uniqueKey);
                    Project_Team_Member_Billing_Rate__c newProjectBillingRateRecord = new Project_Team_Member_Billing_Rate__c();
                    newProjectBillingRateRecord.Project__c = projectId;
                    newProjectBillingRateRecord.Product__c = productId;
                    newProjectBillingRateRecord.Quantity_Sold__c = opptyProductIdAndRateToQuantityMap.get(uniqueKey);
                    newProjectBillingRateRecord.Total_Amount_Sold__c = opptyProductIdAndRateToAmountMap.get(uniqueKey);
                    newProjectBillingRateRecord.Hourly_Rate__c = productRate;
                    newProjectBillingRateRecord.Created_in_Salesforce__c = true;
                    newProjectBillingRateRecord.Outdated_Rate__c = false;

                    if(duplicateCount == 1){
                        newProjectBillingRateRecord.Name = opptyProductIdToOpptyProductRecordMap.get(productId).Product2.Name;
                    }else{
                        newProjectBillingRateRecord.Name = opptyProductIdToOpptyProductRecordMap.get(productId).Product2.Name + ' ' + duplicateCount;
                    }

                    if(existingBillingRateIdToRecordMap.containsKey(uniqueKey)){
                        Project_Team_Member_Billing_Rate__c existingProjectBillingRateRecord = existingBillingRateIdToRecordMap.get(uniqueKey);
                        //Only Update records that need to be updated
                        if(newProjectBillingRateRecord.Quantity_Sold__c != existingProjectBillingRateRecord.Quantity_Sold__c || newProjectBillingRateRecord.Total_Amount_Sold__c != existingProjectBillingRateRecord.Total_Amount_Sold__c || existingProjectBillingRateRecord.Outdated_Rate__c == true ){
                            newProjectBillingRateRecord.Id = existingBillingRateIdToRecordMap.get(uniqueKey).Id;
                            billingRatesToUpdateList.add(newProjectBillingRateRecord);
                        }
                        existingBillingRateIdToRecordMap.remove(uniqueKey); //Remove Existing Project Billing Rate record key from Map to leave only records for deletion
                    }else{
                        billingRatesToInsertList.add(newProjectBillingRateRecord);
                    }
                }

                //Delete any existing Project Billing Rate Records that no longer should exist because a OLI is removed or a Change Order is moved from Closed Won and that related record doesn't exist on any other related Oppty
                for(Project_Team_Member_Billing_Rate__c projBillingRateToDelete : existingBillingRateIdToRecordMap.values()){
                    /***
                     * TODO: Concern on deleting Billing Rates if they are already used by Time Entries.
                     ***/
                    billingRatesToDeleteMap.put(projBillingRateToDelete.Id, projBillingRateToDelete);
                }
            }
            /*************************************************************************************************************************************************************************************************************************/ 

            /************************************************************************* Insert/Update/Delete Project Billing Rate Records  **********************************************************************************************/
            if(billingRatesToInsertList.size() > 0){
                System.debug('******************* Project Team Member Billing Rate(s) being Inserted: ' + billingRatesToInsertList.size() + '************************');
                insert billingRatesToInsertList;
                newBillRatesList.addAll(billingRatesToInsertList);
            }
            if(billingRatesToUpdateList.size() > 0){
                System.debug('******************* Project Team Member Billing Rate(s) being Updated: ' + billingRatesToUpdateList.size() + '************************');
                update billingRatesToUpdateList;
            }
            if(billingRatesToDeleteMap.size() > 0){

            /************************ Check to see if Existing Bill Rates are populated on any Time Entries or Proj Team Members so we don't delete Bill Rates in use  ********************************************/
                /*List<Client_Contact__c> relatedProjectTeamMembersList = new List<Client_Contact__c>();
                relatedProjectTeamMembersList = [SELECT Id, Name, Project__c, Project__r.Name, Client_Contact__c, Client_Contact__r.Name, Assigned_Billing_Rate__c
                                                    FROM Client_Contact__c
                                                    WHERE Assigned_Billing_Rate__c IN :billingRatesToDeleteMap.keySet()];

                for(Client_Contact__c projTeamMember : relatedProjectTeamMembersList){
                    if(billingRatesToDeleteMap.containsKey(projTeamMember.Assigned_Billing_Rate__c)){
                        billingRatesToDeleteMap.remove(projTeamMember.Assigned_Billing_Rate__c);
                    }
                }

                if(billingRatesToDeleteMap.size() > 0){
                    List<Replicon_Time_Entry__c> timeEntriesWithBillRateToDeleteList = new List<Replicon_Time_Entry__c>();
                    timeEntriesWithBillRateToDeleteList = [SELECT Id, Name, Associated_Billing_Rate__c, Project__c, Project__r.Name, Employee__c, Employee__r.Name
                                                            FROM Replicon_Time_Entry__c
                                                            WHERE Associated_Billing_Rate__c IN :billingRatesToDeleteMap.keySet() AND Deleted_in_Replicon__c = false
                                                            ORDER BY Associated_Billing_Rate__c];

                    for(Replicon_Time_Entry__c entry : timeEntriesWithBillRateToDeleteList){
                        if(billingRatesToDeleteMap.containsKey(entry.Associated_Billing_Rate__c)){
                            billingRatesToDeleteMap.remove(entry.Associated_Billing_Rate__c);
                        }
                    }

                    if(billingRatesToDeleteMap.size() > 0){
                        System.debug('******************* Project Team Member Billing Rate(s) being Deleted: ' + billingRatesToDeleteMap.size() + '************************');
                        delete billingRatesToDeleteMap.values();
                    }
                }*/

                List<Project_Team_Member_Billing_Rate__c> ratesToCheckList = new List<Project_Team_Member_Billing_Rate__c>();
                ratesToCheckList = [SELECT Id, Name, Hourly_Rate__c, Project__c, Created_in_Salesforce__c, Outdated_Rate__c, Project__r.Project_Manager__c, Project__r.Project_Manager__r.Name, Project__r.Project_Manager__r.Email,
                                        (SELECT Id, Name, Associated_Billing_Rate__c, Project__c FROM Replicon_Time_Entries__r LIMIT 1),
                                        (SELECT Id, Name, ProjectTeamMemberBIllingRate__c, Project__c, Contact__c, Contact__r.Name FROM Replicon_Forecast__r LIMIT 1),
                                        (SELECT Id, Name, Assigned_Billing_Rate__c, Project__c, Client_Contact__c, Client_Contact__r.Name FROM Internal_Project_Team_Members__r)
                                    FROM Project_Team_Member_Billing_Rate__c
                                    WHERE Id IN :billingRatesToDeleteMap.keySet()];

                List<Project_Team_Member_Billing_Rate__c> outdatedRatesToUpdateList = new List<Project_Team_Member_Billing_Rate__c>();
                List<Project_Team_Member_Billing_Rate__c> assignedOutdatedRatesToSendEmailForList = new List<Project_Team_Member_Billing_Rate__c>();
                for(Project_Team_Member_Billing_Rate__c billRate : ratesToCheckList){
                        if(billRate.Internal_Project_Team_Members__r.size() > 0 || billRate.Replicon_Time_Entries__r.size() > 0 || billRate.Replicon_Forecast__r.size() > 0){
                            billingRatesToDeleteMap.remove(billRate.Id);
                            billRate.Outdated_Rate__c = true;
                            outdatedRatesToUpdateList.add(billRate);

                            if(billRate.Internal_Project_Team_Members__r.size() > 0){
                                assignedOutdatedRatesToSendEmailForList.add(billRate);
                            }
                        }
                }

                if(billingRatesToDeleteMap.size() > 0){
                    System.debug('******************* Project Team Member Billing Rate(s) being Deleted: ' + billingRatesToDeleteMap.size() + '************************');
                    delete billingRatesToDeleteMap.values();
                }

                if(outdatedRatesToUpdateList.size() > 0){
                    System.debug('******************* Project Team Member Billing Rate(s) being marked as outdated: ' + outdatedRatesToUpdateList.size() + ' ************************');
                    update outdatedRatesToUpdateList;
                }

                if(assignedOutdatedRatesToSendEmailForList.size() > 0){
                    sendOutdatedAssignedEmailAlert(assignedOutdatedRatesToSendEmailForList);
                }
            }
            /*************************************************************************************************************************************************************************************************************************/ 
        }
    }

    //FF for Horizon, created by ST 7.17.2023 
    public static void sendNewBillRateEmailOnCOCW(List<Project_Team_Member_Billing_Rate__c> newRatesList){
        try{
            System.debug('sendNewBillRateEmailOnCOCW ****************************************************');
            Map<Id, List<Project_Team_Member_Billing_Rate__c>> projectIdToNewBillRatesListMap = new Map<Id, List<Project_Team_Member_Billing_Rate__c>>();
            for(Project_Team_Member_Billing_Rate__c billRate : newRatesList){
                if(billRate.Project__c != null){

                    if(projectIdToNewBillRatesListMap.containsKey(billRate.Project__c)){
                        List<Project_Team_Member_Billing_Rate__c> billRateList = projectIdToNewBillRatesListMap.get(billRate.Project__c);
                        billRateList.add(billRate);
                        projectIdToNewBillRatesListMap.put(billRate.Project__c, billRateList);
                    }else{
                        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>();
                        billRateList.add(billRate);
                        projectIdToNewBillRatesListMap.put(billRate.Project__c, billRateList);

                    }
                }
            }

            //User samUser = [SELECT Id, Name, Email FROM User WHERE Email = 'samuel.tucker@cognizant.com' LIMIT 1]; 

            List<Messaging.SingleEmailMessage> emailToSendList = new List<Messaging.SingleEmailMessage>();

            for(Id projId : projectIdToNewBillRatesListMap.keySet()){

                Messaging.SingleEmailMessage newBillRateEmail = new Messaging.SingleEmailMessage();  
                newBillRateEmail.setSubject('New Rate(s) to be Assigned on ' + projectIdToProjectMap.get(projId).Name);

                String emailBody = 'The following new rate(s) has/have been added to ';
                emailBody += '<b><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Project__c/' + projId + '/view">' + projectIdToProjectMap.get(projId).Name +' </a></b>';
                emailBody +=  ' due to a new change order and need to be assigned to project team members:';
                emailBody += '<br/>' + '<br/>';


                String htmlTableBody;
                htmlTableBody = '<table border="1" style="border-collapse: collapse"><title>New Billling Rates</title>';
                htmlTableBody += '<tr style="background-color: #abc6ed"><th>Billing Rate Name</th><th>Hourly Rate</th></tr>';
                Integer counter = 0;
                for(Project_Team_Member_Billing_Rate__c billRate : projectIdToNewBillRatesListMap.get(projId)){
                    counter++;

                    //Create Zebra Stripe Affect
                    if(Math.mod(counter, 2) != 0){ //If Counter is odd
                        htmlTableBody += '<tr style="background-color: #cce1ff; padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;"><td>' + billRate.Name + '</td><td>' + billRate.Hourly_Rate__c + '</td>';
                    }else{
                        htmlTableBody += '<tr style="padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;"><td>' + billRate.Name + '</td><td>' + billRate.Hourly_Rate__c + '</td>';
                    }
                }

                htmlTableBody += '</table>';
                emailBody += htmlTableBody;

                emailBody += '<br/>' + '<br/>';
                emailBody +=  'Please go into this Project and assign the new rate(s) to applicable project team members <b>ASAP</b>, ensuring you also set the date the rate(s) should be effective.';
                emailBody += '<br/>' + '<br/>';
                emailBody += '<i>This is an automated notification.</i>';

                newBillRateEmail.setHtmlBody(emailBody);


                //Set who the Email will be sent to
                List<String> emailRecipientsList = new List<String>();
                //emailRecipientsList.add((String)samUser.Email);
                if(projectIdToProjectMap.containsKey(projId) && projectIdToProjectMap.get(projId).Project_Manager__c != null && projectIdToProjectMap.get(projId).Project_Manager__r.Email != null){
                    if(!emailRecipientsList.contains((String)projectIdToProjectMap.get(projId).Project_Manager__r.Email)){
                        emailRecipientsList.add((String)projectIdToProjectMap.get(projId).Project_Manager__r.Email);
                    }
                }
                newBillRateEmail.setToAddresses(emailRecipientsList);

                if(!Test.isRunningTest()){
                    newBillRateEmail.setOrgWideEmailAddressId('0D26T000001gtm3SAA');
                }

                //Add Email to list to send
                if(emailRecipientsList.size() > 0){ //Only add it to send list, if there are recipients that are listed to send the email to.
                    emailToSendList.add(newBillRateEmail); 
                }
            }

            //Send Email
            if(!emailToSendList.isEmpty()){
                Messaging.sendEmail(emailToSendList); 
            }
        }catch(Exception e){
            LevExceptionHandler.logError(e, 'ProjectBillingRateManager', 'sendNewBillRateEmailOnCOCW', null);
        }

    }

    //Send Email alert when a used Billing Rate becomes outdated
    public static void sendOutdatedAssignedEmailAlert(List<Project_Team_Member_Billing_Rate__c> outdatedRatesList){
    
        try{
            System.debug('sendNewBillRateEmailOnCOCW ****************************************************');
            Map<Id, List<Project_Team_Member_Billing_Rate__c>> projectIdToOutdatedBillRatesListMap = new Map<Id, List<Project_Team_Member_Billing_Rate__c>>();
            for(Project_Team_Member_Billing_Rate__c billRate : outdatedRatesList){
                if(billRate.Project__c != null){

                    if(projectIdToOutdatedBillRatesListMap.containsKey(billRate.Project__c)){
                        List<Project_Team_Member_Billing_Rate__c> billRateList = projectIdToOutdatedBillRatesListMap.get(billRate.Project__c);
                        billRateList.add(billRate);
                        projectIdToOutdatedBillRatesListMap.put(billRate.Project__c, billRateList);
                    }else{
                        List<Project_Team_Member_Billing_Rate__c> billRateList = new List<Project_Team_Member_Billing_Rate__c>();
                        billRateList.add(billRate);
                        projectIdToOutdatedBillRatesListMap.put(billRate.Project__c, billRateList);
                    }
                }
            }

            //Build the email
            List<Messaging.SingleEmailMessage> emailToSendList = new List<Messaging.SingleEmailMessage>();

            for(Id projId : projectIdToOutdatedBillRatesListMap.keySet()){

                Messaging.SingleEmailMessage newOutdatedRateEmail = new Messaging.SingleEmailMessage();  
                newOutdatedRateEmail.setSubject('ACTION NEEDED: Billing Rate Changes or Additions - Update Project\'s Assigned Rates');

                String projectManagerName = 'Project Manager';
                String projectManagerEmail;

                if(projectIdToOutdatedBillRatesListMap.get(projId)[0].Project__r.Project_Manager__c != null){
                    projectManagerName = projectIdToOutdatedBillRatesListMap.get(projId)[0].Project__r.Project_Manager__r.Name;

                    if(projectIdToOutdatedBillRatesListMap.get(projId)[0].Project__r.Project_Manager__r.Email != null){
                        projectManagerEmail = projectIdToOutdatedBillRatesListMap.get(projId)[0].Project__r.Project_Manager__r.Email;
                    }
                }
                
                String emailBody = 'Hello ' + projectManagerName + ',';
                emailBody += '<br/>';
                emailBody += 'As <b><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Project__c/' + projId + '/view">' + projectIdToProjectMap.get(projId).Name +' </a></b>';
                emailBody +=  ' was created before official closure, as approved by leadership, new Products have been either added to your Project or previously existing Products have changed.';
                emailBody += '<br/>' + '<br/>';
                emailBody += '<b>ACTION: Please open this Project and review/update your team\'s assigned billing rates <b style="color:red;">today</b>.</b>';
                emailBody += '<br/>' + '<br/>';
                emailBody += 'If previously existing Products have changed, once billing rate assignment is updated, any impacted time entries already in the system and upcoming forecast projections will automatically be fixed.';
                emailBody += '<br/>' + '<br/>';
                emailBody += '<i>This is an automated notification.</i>';

                newOutdatedRateEmail.setHtmlBody(emailBody);

                //Set who the Email will be sent to
                List<String> emailRecipientsList = new List<String>();
                //emailRecipientsList.add((String)samUser.Email);
                if(projectIdToProjectMap.containsKey(projId) && projectIdToProjectMap.get(projId).Project_Manager__c != null && projectIdToProjectMap.get(projId).Project_Manager__r.Email != null){
                    if(!emailRecipientsList.contains((String)projectIdToProjectMap.get(projId).Project_Manager__r.Email)){
                        emailRecipientsList.add((String)projectIdToProjectMap.get(projId).Project_Manager__r.Email);
                    }
                }
                newOutdatedRateEmail.setToAddresses(emailRecipientsList);
                System.debug('Email Recipients List: ' + emailRecipientsList);

                List<String> ccEmailList = new List<String>();
                List<User> ccUsersList = new List<User>();
                ccUsersList = [SELECT Id, Name, Email FROM User WHERE Name IN ('Michelle Murray', 'Jamie Lindley') AND IsActive = true AND UserType = 'Standard'];
                for(User u : ccUsersList){
                    if(u.Email != null){
                        ccEmailList.add(u.Email);
                    }
                }

                if(ccEmailList.size() > 0){
                    newOutdatedRateEmail.setCcAddresses(ccEmailList);
                }

                if(!Test.isRunningTest()){
                    newOutdatedRateEmail.setOrgWideEmailAddressId('0D26T000001gtm3SAA');
                }

                //Add Email to list to send
                if(emailRecipientsList.size() > 0){ //Only add it to send list, if there are recipients that are listed to send the email to.
                    emailToSendList.add(newOutdatedRateEmail); 
                }
            }

            //Send Email
            if(!emailToSendList.isEmpty()){
                System.debug('SEND EMAIL LIST: ' + emailToSendList);
                Messaging.sendEmail(emailToSendList); 
            }

        }catch(Exception e){
            LevExceptionHandler.logError(e, 'ProjectBillingRateManager', 'sendOutdatedAssignedEmailAlert', null);
        }
    
    }
}