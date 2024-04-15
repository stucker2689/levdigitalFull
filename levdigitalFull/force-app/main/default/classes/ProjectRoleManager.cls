/**
 * Create by Sam Tucker 4/19/2022
 * Purpose: To manage all functions to create/update ProjectRole__c records from various Object Triggers
 */

public with sharing class ProjectRoleManager {
    /**
     * Functionality: 
     * When an Opportunity goes Closed Won it needs to check if there are existing ProjectRole__c records for that Oppty/Parent Oppty
     *  - If they DO exist check if the Oppty Products on the CW oppty exist already as ProjectRole__c records on the related Project
     *      - If they DO exist then update the Quantity Sold and Price Sold fields 
     *      - If they DON'T exist then create the Oppty Products as ProjectRole__c records on the related Project 
     * 
     *  - If they DON'T exist then create them
     */

    /**
     * (NOT INCLUDING UPDATES FROM REPLICON TIME ENTRY OR FORECAST PROCESSES)
     * 
     * Create Scenarios:
     *      1.) When Project is created. It creates ProjectRole__c records for related Opportunity's Opportunity Products
     *      2.) When Opportunity Product is created on a Closed Won Opportunity, and the product does not already exist on a existing ProjectRole__c record for the related Project
     *      3.) When a Change Order is moved to Closed Won, if the Opportunity Products' related Product (along with the rate) does not already have an existing ProjectRole__c with matching rate
     * 
     * Update Scenarios:
     *      1.) When Opportunity Product on a Closed Won Opportunity has its Quantity or Price Changed.
     *      2.) When Change Order is moved to Closed Won, AND the Opportunity Products on that CW CO already have a matching ProjectRole__c record on the related Project.
     * 
     */
    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    private static List<String> professionalServicesProductFamilyTypeList = new List<String>{'Professional Services'};
    private static List<String> internalResourceDeliveryGroupList = new List<String>{'Lev-Onshore', 'Lev-UK', 'Lev - UK', 'Lev-NA', 'Lev - NA'};
    private static List<String> cognizantResourceDeliveryGroupList = new List<String>{'CTSH-Regional', 'CTSH-Sub'};
    private static List<String> externalResourceDeliveryGroupList = new List<String>{'CTSH-Regional', 'CTSH-Sub', 'Offshore'};

    public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};
    
    public static void ProjectRoleManager_Handler(List<sObject> objList){
        System.debug('*********************** ProjectRoleManager_Handler ************************');

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
            createProjectRolesOnProjectInsert(projList);
        }

        if(changeOrderToCWList.size() > 0){
            CreateProjectRolesOnCWOppty(changeOrderToCWList, true);
        }

        if(closedWonOpptyList.size() > 0){
            CreateProjectRolesOnCWOppty(closedWonOpptyList, false);
        }

        if(oppLineItemList.size() > 0){
            CreateProjectRolesFromOpptyProducts(oppLineItemList);
        }
    }

    public static void CreateProjectRolesOnProjectInsert(List<Project__c> projList){

        //Call dynamic function to create Project Role Records from Projects
        CreateProjectRoleRecords(projList);
        
    }

    public static void createProjectRolesOnChangeOrderReassignment(Set<Id> opptyIdSet){
        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, RecordTypeId, RecordType.Name, StageName, Change_Orders__c, Change_Orders__r.StageName, Change_Orders__r.RecordTypeId, Create_Project__c, HasActiveProject__c
                        FROM Opportunity
                        WHERE Id IN :opptyIdSet];

        if(opptyList.size() > 0){
            ProjectRoleManager_Handler(opptyList);
        }
    }

    public static void CreateProjectRolesOnCWOppty(List<Opportunity> opptyList, Boolean forChangeOrder){
        /**
         * Functionality:
         * When a Change Order goes Closed Won it looks for a project related to the Parent Oppty
         *      If Project exists then it looks for existing ProjectRole__c and if one exist with matchin Products then it updates the Quantity and Amount Sold, if doesn't already exist then create the ProjectRole__c record
         *      If Project doesn't exist then do nothing
         *              
         */

        System.debug('************************* Create Project Roles On CW Oppty **********************************');
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
        

        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName
                                FROM Project__c
                                WHERE Opportunity__c IN :parentOpptyIdList];

        if(relatedProjectsList.size() > 0){
            CreateProjectRoleRecords(relatedProjectsList);
        }

    }

    public static void CreateProjectRolesFromOpptyProducts(List<OpportunityLineItem> opptyProductList){
        /**
         * Functionality: Get Project of Opportunity Products related Opportunity or Parent Opportunity of related Opportunity
         */

        List<Id> relatedOpptyIdList = new List<Id>();
        for(OpportunityLineItem opptyProduct : opptyProductList){
            if(opptyProduct.OpportunityId != null){
                relatedOpptyIdList.add(opptyProduct.OpportunityId);
            }
        }

        List<Opportunity> relatedOpportunityList = new List<Opportunity>();
        relatedOpportunityList = [SELECT Id, Name, RecordTypeId, Change_Orders__c, StageName, Change_Orders__r.StageName
                                    FROM Opportunity
                                    WHERE Id IN :relatedOpptyIdList AND (StageName IN :opportunityClosedWonStageNames OR Create_Project__c = true)];

        List<Id> parentOpptyIdList = new List<Id>();
        for(Opportunity opp : relatedOpportunityList){
            if(opp.RecordTypeId == changeOrderOpptyRT){
                parentOpptyIdList.add(opp.Change_Orders__c);
            }else{
                parentOpptyIdList.add(opp.Id);
            }
        }

        List<Project__c> relatedProjectsList = new List<Project__c>();
        relatedProjectsList = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName
                                FROM Project__c
                                WHERE Opportunity__c IN :parentOpptyIdList];

        if(relatedProjectsList.size() > 0){
            CreateProjectRoleRecords(relatedProjectsList);
        }

    }

    public static void CreateProjectRoleRecords(List<Project__c> projList){
        /**
         * Purpose: Create ProjectRole__c record via Project and all Opportunity line Items related to Parent Oppty and any existing Change Orders for that Parent Oppty
         * Functionality:
         *  1.) Query OpportunityLineItems that are on the Opportunity or have Change_Orders__c = Opportunity of the related Opportunity on the Project
         *  2.) Check to only include Opportunity Line Items that are Professional Services or Services Product Family
         *  3.) Sum Products Quantity and Total Prices of same Product2.Name + Rate (Discounted Price)
         *  4.) Create ProjectRole__c s
         */
        
        System.debug('&&&&&&&& Create Project Role Records');
        Map<Id, Project__c> parentOpptyIdToProjectMap = new Map<Id, Project__c>();
        //Create List of Parent Opportunity Ids to get Opportunity Line Items
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
                        WHERE (OpportunityId IN :parentOpptyIdToProjectMap.keySet() OR Opportunity.Change_Orders__c IN :parentOpptyIdToProjectMap.keySet()) AND (Opportunity.StageName IN :opportunityClosedWonStageNames OR Opportunity.Create_Project__c = true) AND Resource_Delivery_Group__c != null
                            AND Opportunity_Product_Family__c IN :professionalServicesProductFamilyTypeList
                        ORDER BY CreatedDate];

            Map<String, Decimal> opptyProductIdAndRateToQuantityMap = new Map<String, Decimal>();
            Map<String, Decimal> opptyProductIdAndRateToAmountMap = new Map<String, Decimal>();
            Map<Id, OpportunityLineItem> oliIdToOliRecordMap = new Map<Id, OpportunityLineItem>();

            Map<String, Map<String, Decimal>> duplicateOpptyAndProductCount = new Map<String, Map<String, Decimal>>();

            /***** Loop through the Opportunity Line Items to determine the ProjectRole__c records amounts and quantitys *******/
            for(OpportunityLineItem oli : oliList){
                //Put Product2 Id and Oli record in Map
                oliIdToOliRecordMap.put(oli.Product2Id, oli);

                /*********************************************************** Make unique key of OpportunityId + ProductId + DiscountedPrice (joined with a '-') **********************************************************************/
                String opptyIdProdIdRateAndResourceDeliveryGroupKey;
                String opptyIdProductIdAndRateUniqueKey;
                String opptyIdProductIdUniqueKey;
                String opptyIdProductIdResourceDeliveryGroupKey;
                
                String parentOpportunityId;
                String resourceDeliveryGroup;

                //Get Resource Delivery Group, handles both Lev-Onshore and Lev-UK as the same
                if(internalResourceDeliveryGroupList.contains(oli.Resource_Delivery_Group__c)){
                    //resourceDeliveryGroup = 'Lev-Onshore';
                    resourceDeliveryGroup = 'Lev';
                }else if(cognizantResourceDeliveryGroupList.contains(oli.Resource_Delivery_Group__c)){
                    resourceDeliveryGroup = 'CTSH';
                }
                else{
                    resourceDeliveryGroup = oli.Resource_Delivery_Group__c;
                }

                //Get OpportunityId
                if(oli.Opportunity.RecordTypeId == salesforceOpptyRT){
                    parentOpportunityId = oli.OpportunityId;
                }else if(oli.Opportunity.RecordTypeId == changeOrderOpptyRT){
                    parentOpportunityId = oli.Opportunity.Change_Orders__c;
                }

                opptyIdProdIdRateAndResourceDeliveryGroupKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + resourceDeliveryGroup + '@' + String.valueOf(oli.Discounted_Price__c);// oppId1@prodId1@230@Lev-Onshore
                opptyIdProductIdResourceDeliveryGroupKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + resourceDeliveryGroup;// oppId1@prodId1@Lev-Onshore

                opptyIdProductIdAndRateUniqueKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c);// oppId1@prodId1@230
                opptyIdProductIdUniqueKey = String.valueOf(parentOpportunityId) + '@' + String.valueOf(oli.Product2Id);// oppId1@prodId1

                /*if(oli.Opportunity.RecordTypeId == salesforceOpptyRT){
                    opptyIdProdIdRateAndResourceDeliveryGroupKey = String.valueOf(oli.OpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c) + resourceDeliveryGroup;// oppId1@prodId1@230@Lev-Onshore
                    opptyIdProductIdAndRateUniqueKey = String.valueOf(oli.OpportunityId) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c);// oppId1@prodId1@230
                    opptyIdProductIdUniqueKey = String.valueOf(oli.OpportunityId) + '@' + String.valueOf(oli.Product2Id);// oppId1@prodId1

                }else if(oli.Opportunity.RecordTypeId == changeOrderOpptyRT){
                    opptyIdProdIdRateAndResourceDeliveryGroupKey = String.valueOf(oli.Opportunity.Change_Orders__c) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c) + resourceDeliveryGroup;// oppId1@prodId1@230@Lev-Onshore
                    opptyIdProductIdAndRateUniqueKey = String.valueOf(oli.Opportunity.Change_Orders__c) + '@' + String.valueOf(oli.Product2Id) + '@' + String.valueOf(oli.Discounted_Price__c);// oppId1@prodId1@230
                    opptyIdProductIdUniqueKey = String.valueOf(oli.Opportunity.Change_Orders__c) + '@' + String.valueOf(oli.Product2Id);// oppId1@prodId1
                }*/
                /***********************************************************************************************************************************************************************************************************************/



                /********************* Check to see if a Record needs the 2 appended to the name if there are Opportunity Line Items on the Oppty or COs of that Oppty with same Product but different Rates ***************************/
                //Swappped opptyIdProductIdResourceDeliveryGroupKey for opptyIdProductIdUniqueKey
                //Swappped opptyIdProdIdRateAndResourceDeliveryGroupKey for opptyIdProductIdAndRateUniqueKey
                if(duplicateOpptyAndProductCount.containsKey(opptyIdProductIdResourceDeliveryGroupKey)){
                    //Get the last count # of the inner map (size - 1 will get us the most recent entry to the Map)
                    
                    if(!duplicateOpptyAndProductCount.get(opptyIdProductIdResourceDeliveryGroupKey).containsKey(opptyIdProdIdRateAndResourceDeliveryGroupKey)){ //Check to ensure the existing OpptyId-ProductId is not the same rate as the existing entry
                        //Only add a 2 to the end of the Project Roles name if the Rate is different but the Oppty Id - Product Id is the same
                        Decimal duplicateProductCount = duplicateOpptyAndProductCount.get(opptyIdProductIdResourceDeliveryGroupKey).values()[duplicateOpptyAndProductCount.get(opptyIdProductIdResourceDeliveryGroupKey).size() -1];
                        duplicateProductCount ++;
                        Map<String, Decimal> duplicateOpptyAndProductAndRateNumber = duplicateOpptyAndProductCount.get(opptyIdProductIdResourceDeliveryGroupKey);
                        duplicateOpptyAndProductAndRateNumber.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, duplicateProductCount);
                        duplicateOpptyAndProductCount.put(opptyIdProductIdResourceDeliveryGroupKey, duplicateOpptyAndProductAndRateNumber);
                    }

                }else{
                    Map<String, Decimal> duplicateOpptyAndProductAndRateNumber = new Map<String, Decimal>();
                    Decimal duplicateProductCount = 1;
                    duplicateOpptyAndProductAndRateNumber.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, duplicateProductCount); // oppId1@prodId1@230 
                    duplicateOpptyAndProductCount.put(opptyIdProductIdResourceDeliveryGroupKey, duplicateOpptyAndProductAndRateNumber);
                }
                /***********************************************************************************************************************************************************************************************************************/



                /*********************************************************************************** Set Unique key to Quantity and Amount $ *******************************************************************************************/
                //Swappped opptyIdProdIdRateAndResourceDeliveryGroupKey for opptyIdProductIdAndRateUniqueKey
                if(opptyProductIdAndRateToQuantityMap.containsKey(opptyIdProdIdRateAndResourceDeliveryGroupKey)){
                    //If Opportuntiy + ProductId + Rate is already in map then add to existing quantity amount
                    Decimal additionalProductQuantity = oli.Quantity != null ? oli.Quantity : 0;
                    Decimal totalProductQuantity = opptyProductIdAndRateToQuantityMap.get(opptyIdProdIdRateAndResourceDeliveryGroupKey) + additionalProductQuantity;
                    opptyProductIdAndRateToQuantityMap.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, totalProductQuantity);

                    //Do same with Amount map
                    Decimal additionalProductAmount = oli.TotalPrice != null ? oli.TotalPrice : 0;
                    Decimal totalProductAmount = opptyProductIdAndRateToAmountMap.get(opptyIdProdIdRateAndResourceDeliveryGroupKey) + additionalProductAmount;
                    opptyProductIdAndRateToAmountMap.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, totalProductAmount);


                }else{
                    //If Opportuntiy + ProductId + Rate is not yet in map, initialize it with the Quantity
                    Decimal newProductQuantity = oli.Quantity != null ? oli.Quantity : 0;
                    opptyProductIdAndRateToQuantityMap.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, newProductQuantity);

                    //Do same with Amount map
                    Decimal newProductAmount = oli.TotalPrice != null ? oli.TotalPrice : 0;
                    opptyProductIdAndRateToAmountMap.put(opptyIdProdIdRateAndResourceDeliveryGroupKey, newProductAmount);
                }
                /***********************************************************************************************************************************************************************************************************************/       
            }

            /*************************************************** Query existing Project Role Records to give Id to new records for Upsert *************************************************************************/

            List<ProjectRole__c> existingProjectRoleRecordsList = new List<ProjectRole__c>();
            existingProjectRoleRecordsList = [SELECT Id, Name, Project__c, Product__c, Rate__c, Quantity_Sold__c, Total_Amount_Sold__c, Project__r.Opportunity__c, Resource_Delivery_Group__c
                                                            FROM ProjectRole__c
                                                            WHERE Project__r.Opportunity__c IN :parentOpptyIdToProjectMap.keySet()];

            Map<String, ProjectRole__c> existingProductRoleIdToRecordMap = new Map<String, ProjectRole__c>();
            for(ProjectRole__c pr : existingProjectRoleRecordsList){
                List<String> projectRoleKeyList = new List<String>{
                    String.valueOf(pr.Project__r.Opportunity__c), 
                    String.valueOf(pr.Product__c),
                    String.valueOf(pr.Resource_Delivery_Group__c),                     
                    String.valueOf(pr.Rate__c)
                };
                String existingProjectRoleKey = String.join(projectRoleKeyList, '@');
                existingProductRoleIdToRecordMap.put(existingProjectRoleKey, pr);
            }


            /*************************************************************************************************************************************************************************************************************************/   


            /************************************************************* Set Insert/Update/Delete Project Role Record Lists ************************************************************************************/
            List<ProjectRole__c> projectRolesToInsertList = new List<ProjectRole__c>();
            List<ProjectRole__c> projectRolesToUpdateList = new List<ProjectRole__c>();
            List<ProjectRole__c> projectRolesToDeleteList = new List<ProjectRole__c>();
            if(opptyProductIdAndRateToQuantityMap.size() > 0 || opptyProductIdAndRateToAmountMap.size() > 0){
                for(String uniqueKey : opptyProductIdAndRateToQuantityMap.keySet()){
                    //Create the ProjectRole__c records
                    //Id opportunityId = (Id)uniqueKey.substringBefore('@');
                    //Id productId = (Id)((uniqueKey.substringBeforeLast('@')).substringAfter('@'));
                    //String opptyIdAndProductId = uniqueKey.substringBeforeLast('@');
                    //Decimal productRate = Decimal.valueOf(uniqueKey.substringAfterLast('@'));

                    List<String> uniqueKeySplitList = new List<String>();
                    uniqueKeySplitList = uniqueKey.split('@');
                    Id opportunityId = (Id)uniqueKeySplitList[0];
                    Id productId = (Id)uniqueKeySplitList[1];
                    String opptyIdProductIdAndResourceDeliveryGroup = uniqueKeySplitList[0] + '@' + uniqueKeySplitList[1] + '@' + uniqueKeySplitList[2];
                    String resourceDeliveryGroup = uniqueKeySplitList[2];
                    Decimal productRate = Decimal.valueOf(uniqueKeySplitList[3]);

                    Id projectId = parentOpptyIdToProjectMap.get(opportunityId).Id;

                    //If it is a duplicate Oppty ID + Product Id but with a different rate this will be > 1 otherwise 1 means it is unique for Oppty Id and Product Id
                    //If > 1 then we need to append a number to the Product Name
                    Decimal duplicateCount = duplicateOpptyAndProductCount.get(opptyIdProductIdAndResourceDeliveryGroup).get(uniqueKey);
                    ProjectRole__c newProjectRoleRecord = new ProjectRole__c();
                    newProjectRoleRecord.Project__c = projectId;
                    newProjectRoleRecord.Product__c = productId;
                    newProjectRoleRecord.Quantity_Sold__c = opptyProductIdAndRateToQuantityMap.get(uniqueKey);
                    newProjectRoleRecord.Total_Amount_Sold__c = opptyProductIdAndRateToAmountMap.get(uniqueKey);
                    newProjectRoleRecord.Rate__c = productRate;
                    if(resourceDeliveryGroup != 'null' && resourceDeliveryGroup != null){
                        newProjectRoleRecord.Resource_Delivery_Group__c = resourceDeliveryGroup;
                    }

                    if(duplicateCount == 1){
                        newProjectRoleRecord.Name = oliIdToOliRecordMap.get(productId).Product2.Name;
                    }else{
                        newProjectRoleRecord.Name = oliIdToOliRecordMap.get(productId).Product2.Name + ' ' + duplicateCount;
                    }

                    if(existingProductRoleIdToRecordMap.containsKey(uniqueKey)){
                        ProjectRole__c existingRipRecord = existingProductRoleIdToRecordMap.get(uniqueKey);
                        //Only Update records that need to be updated
                        if(newProjectRoleRecord.Quantity_Sold__c != existingRipRecord.Quantity_Sold__c || newProjectRoleRecord.Total_Amount_Sold__c != existingRipRecord.Total_Amount_Sold__c || newProjectRoleRecord.Resource_Delivery_Group__c != existingRipRecord.Resource_Delivery_Group__c){
                            newProjectRoleRecord.Id = existingProductRoleIdToRecordMap.get(uniqueKey).Id;
                            projectRolesToUpdateList.add(newProjectRoleRecord);
                        }
                        existingProductRoleIdToRecordMap.remove(uniqueKey); //Remove Existing RIP record key from Map to leave only records for deletion
                    }else{
                        projectRolesToInsertList.add(newProjectRoleRecord);
                    }
                }

                //Delete any existing Project Role Records that no longer should exist because a OLI is removed or a Change Order is moved from Closed Won and that related record doesn't exist on any other related Oppty
                for(ProjectRole__c ripToDelete : existingProductRoleIdToRecordMap.values()){
                    projectRolesToDeleteList.add(ripToDelete);
                }
            }
            /*************************************************************************************************************************************************************************************************************************/ 


            /************************************************************************* Insert/Update/Delete Project Role Records  **********************************************************************************************/
            if(projectRolesToInsertList.size() > 0){
                System.debug('******************* Project Role(s) being Inserted: ' + projectRolesToInsertList.size() + '************************');
                insert projectRolesToInsertList;
            }
            if(projectRolesToUpdateList.size() > 0){
                System.debug('******************* Project Role(s) being Updated: ' + projectRolesToUpdateList.size() + '************************');
                update projectRolesToUpdateList;
            }
            if(projectRolesToDeleteList.size() > 0){
                System.debug('******************* Project Role(s) being Deleted: ' + projectRolesToDeleteList.size() + '************************');
                delete projectRolesToDeleteList;
            }
            /*************************************************************************************************************************************************************************************************************************/ 
        } 
    }
}