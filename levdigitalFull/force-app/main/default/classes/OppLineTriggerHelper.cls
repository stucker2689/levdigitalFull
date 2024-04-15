public with sharing class OppLineTriggerHelper {
    
    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    private static List<String> levResourceDeliveryGroupNamesList = new List<String>{'Lev-NA', 'Lev-UK', 'Lev - NA', 'Lev - UK', 'Lev-Onshore'};

    public static void checkOpptyProductRate(List<OpportunityLineItem> newList){

        //See if there are multiple discounted rates for a oppty
        //If they are all the same then it is a blended rate
        //If there are multiple then it is a Multi-Rate

        Map<Id, ChangeOrderObj> coIdToCOProductRateTypeMap = new Map<Id, ChangeOrderObj>();

        Set<Id> allRelatedOpptyList = new Set<Id>();

        List<Id> parentOpptyIdList = new List<Id>();
        
        for(OpportunityLineItem oli : newList){
            parentOpptyIdList.add(oli.OpportunityId);
        }

        if(parentOpptyIdList.size() > 0){

            List<OpportunityLineItem> relatedOpptyLineItemList = new List<OpportunityLineItem>();
            relatedOpptyLineItemList = [SELECT Id, Name, OpportunityId, Discounted_Price__c, Opportunity.Original_Product_Rate_Type__c, /*Opportunity.Overall_Product_Rate_Type__c,*/ Opportunity.CO_Product_Rate_Type__c, Opportunity.RecordTypeId, Opportunity.Change_Orders__c, IsDeleted 
                                        FROM OpportunityLineItem 
                                        WHERE OpportunityId IN :parentOpptyIdList AND IsDeleted = false AND Opportunity_Product_Family__c = 'Professional Services'
                                        ORDER BY OpportunityId];

            Map<Id, Set<Decimal>> opptyIdToDiscRateSetMap = new Map<Id, Set<Decimal>>();
            Map<Id, OpportunityLineItem> opptyIdToOppLineDataMap = new Map<Id, OpportunityLineItem>();
            for(OpportunityLineItem oli : relatedOpptyLineItemList){

                if(opptyIdToDiscRateSetMap.containsKey(oli.OpportunityId)){

                    //For Oli's that already have their related Oppty Id in the map
                    Set<Decimal> discountedRateSet = opptyIdToDiscRateSetMap.get(oli.OpportunityId);
                    discountedRateSet.add(oli.Discounted_Price__c);
                    opptyIdToDiscRateSetMap.put(oli.OpportunityId, discountedRateSet);
                }else{
                    allRelatedOpptyList.add(oli.OpportunityId);
                    if(oli.Opportunity.Change_Orders__c != null){
                        allRelatedOpptyList.add(oli.Opportunity.Change_Orders__c);

                        //Most Recent CW CO Product Rate Type
                        changeOrderObj newCOObj = new changeOrderObj();
                        newCOObj.parentOppId = oli.Opportunity.Change_Orders__c;
                        newCOObj.changeOrderProductRateType = oli.Opportunity.CO_Product_Rate_Type__c;
                        coIdToCOProductRateTypeMap.put(oli.OpportunityId, newCOObj);
                    }

                    //Set OpptyIdToOppLineDataMap entry for each Oppty Id
                    opptyIdToOppLineDataMap.put(oli.OpportunityId, oli);

                    //If Oppty Id has not been entered into Map yet then initialize it in Map
                    Set<Decimal> newDiscountedRateSet = new Set<Decimal>();
                    newDiscountedRateSet.add(oli.Discounted_Price__c);
                    opptyIdToDiscRateSetMap.put(oli.OpportunityId, newDiscountedRateSet);
                }
            }

            Map<Id, String> opptyIdToProductRateChangeMap = new Map<Id, String>();
            for(Id parentOpptyId : opptyIdToDiscRateSetMap.keySet()){
                //If Oppty Rate should be Multi-rate
                if(opptyIdToDiscRateSetMap.get(parentOpptyId).size() > 1){
                    //Check if parent Oppty is a change order
                    if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.RecordTypeId == changeOrderOpptyRT){
                        //Check if parent Oppty needs to be set to Multi-rate or if it is already set
                        if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.CO_Product_Rate_Type__c != 'Multi-rate'){

                            opptyIdToProductRateChangeMap.put(parentOpptyId, 'Multi-rate');
                            
                            //Keep Most recent CW CO Product Rate Type in sync with new changes
                            if(coIdToCOProductRateTypeMap.containsKey(parentOpptyId)){
                                coIdToCOProductRateTypeMap.get(parentOpptyId).changeOrderProductRateType =  'Multi-rate';
                            }
                        }

                    }else{
                        if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.Original_Product_Rate_Type__c != 'Multi-rate'){

                            opptyIdToProductRateChangeMap.put(parentOpptyId, 'Multi-rate');
                        }
                    }
                
                }else{
                    //Else Oppty Rate should be Blended Rate
                    //Check if parent Oppty is a change order
                    if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.RecordTypeId == changeOrderOpptyRT){
                        //Check if parent Oppty needs to be set to Blended Rate or if it is already set
                        if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.CO_Product_Rate_Type__c != 'Blended Rate'){

                            opptyIdToProductRateChangeMap.put(parentOpptyId, 'Blended Rate');

                            //Keep Most recent CW CO Product Rate Type in sync with new changes
                            if(coIdToCOProductRateTypeMap.containsKey(parentOpptyId)){
                                coIdToCOProductRateTypeMap.get(parentOpptyId).changeOrderProductRateType =  'Blended Rate';
                            }
                        }
                    }else{
                        if(opptyIdToOppLineDataMap.get(parentOpptyId).Opportunity.Original_Product_Rate_Type__c != 'Blended Rate'){

                            opptyIdToProductRateChangeMap.put(parentOpptyId, 'Blended Rate');
                        }
                    }
                }
            }

            //checkOverallProductRateType(allRelatedOpptyList);

            if(opptyIdToProductRateChangeMap.size() > 0){

                List<Opportunity> opptysToUpdateProductRateTypeList = new List<Opportunity>();
                opptysToUpdateProductRateTypeList = [SELECT Id, Name, RecordTypeId, Original_Product_Rate_Type__c, /*Overall_Product_Rate_Type__c,*/ CO_Product_Rate_Type__c, Change_Orders__c/*, Change_Orders__r.Overall_Product_Rate_Type__c*/
                                                    FROM Opportunity
                                                    WHERE Id IN :opptyIdToProductRateChangeMap.keySet()];

                List<Opportunity> updateList = new List<Opportunity>();
                for(Opportunity opp : opptysToUpdateProductRateTypeList){
                    if(opptyIdToProductRateChangeMap.containsKey(opp.Id)){
                        if(opp.RecordTypeId == changeOrderOpptyRT){
                            opp.CO_Product_Rate_Type__c = opptyIdToProductRateChangeMap.get(opp.Id);
                        }else{
                            opp.Original_Product_Rate_Type__c = opptyIdToProductRateChangeMap.get(opp.Id);
                            //If Original Oppty changes to Multi rate then it should also change OVERALL Product Rate to Multi Rate (if not already done so)
                            /*if(opptyIdToProductRateChangeMap.get(opp.Id) == 'Multi-rate' && opp.Overall_Product_Rate_Type__c != 'Multi-rate'){
                                opp.Overall_Product_Rate_Type__c = 'Multi-rate'; 
                            }*/
                        }
                        updateList.add(opp);                        
                    }
                }

                if(updateList.size() > 0){
                    update updateList;
                    if(coIdToCOProductRateTypeMap.size() > 0){
                        checkRecentCOProductRateType(coIdToCOProductRateTypeMap);
                    }
                }
            }

        }
    }

    /*public static void checkOverallProductRateType(Set<Id> changedOpptyIdList){

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, Change_Orders__c, Overall_Product_Rate_Type__c, RecordTypeId FROM Opportunity WHERE Id IN :changedOpptyIdList OR Change_Orders__c IN :changedOpptyIdList];
        List<Id> opptyIdList = new List<Id>();

        for(Opportunity opp : opptyList){

            if(opp.RecordTypeId == changeOrderOpptyRT){
                opptyIdList.add(opp.Change_Orders__c);
            }else if(opp.RecordTypeId == salesforceOpptyRT){
                opptyIdList.add(opp.Id);
            }
        }

        List<OpportunityLineItem> relatedOpptyLineItemList = new List<OpportunityLineItem>();
        relatedOpptyLineItemList = [SELECT Id, Name, OpportunityId, Discounted_Price__c, Opportunity.Overall_Product_Rate_Type__c, Opportunity.RecordTypeId, Opportunity.Change_Orders__c, IsDeleted, Opportunity.StageName, Product2.Name, Opportunity.Name
                                    FROM OpportunityLineItem 
                                    WHERE (OpportunityId IN :opptyIdList OR Opportunity.Change_Orders__c IN :opptyIdList) AND Opportunity_Product_Family__c = 'Professional Services' AND IsDeleted = false
                                    ORDER BY CreatedDate DESC];

        Map<Id, Set<Decimal>> parentOpptyIdToDiscRateSetMap = new Map<Id, Set<Decimal>>();
        Map<Id, List<String>> parentOpptyIdToProductNameListMap = new Map<Id, List<String>>(); //Pending                                 
        for(OpportunityLineItem oli : relatedOpptyLineItemList){
            //Initialize which Id and rate type to set for Map
            Id parentOpptyId;
            //Sets Parent Oppty Id to Parent Change Order Id if CO AND is Closed Won or regular Id if salesforce oppty
            if(oli.Opportunity.RecordTypeId == changeOrderOpptyRT){
                parentOpptyId = oli.Opportunity.StageName == 'Closed Won' ? oli.Opportunity.Change_Orders__c : null;
            }else{
                parentOpptyId = oli.OpportunityId; 
            }
            
            if(parentOpptyIdToDiscRateSetMap.containsKey(parentOpptyId)){*/

                /**
                 * PENDING IF THIS IS A SOLUTION
                 * Idea to only count newest Discount Rate if there is same product on Oppty twice across Oppty and it related COs
                 * Include another map Map<Id, List<String>> 
                 * Would be parent Oppty Id,  to List of Product Name (NOT NAME since that includes name of oppty, which would be different on CO than parent Oppty)
                 * **************May need to make unique Product Name + OpportuniyId unique string for that list so it does not count products on the same Oppty (i.e. not related CO) 
                 * Need to order by CreatedDate or Closed Won Date for Opportunity Product - so that it would take the most recently created Oppty Products through this for loop FIRST (Most Recently created to Oldest)
                 * Then as it is going through each Oppty Product it will add the Product Name to this map and it would only add the discounted rate to the <Set> if that Product is not already included in that Map's List
                 * This will make it so it only includes the Newest Rates for each product role so if rates change entirely via a change set then it would stay Blended rate
                 */
            
           /*     if(!parentOpptyIdToProductNameListMap.get(parentOpptyId).contains(oli.Product2.Name)){ //Pending

                    List<String> newProductNameList = parentOpptyIdToProductNameListMap.get(parentOpptyId); //Pending
                    newProductNameList.add(oli.Product2.Name); //Pending 
                    parentOpptyIdToProductNameListMap.put(parentOpptyId, newProductNameList); //Pending


                    //For Oli's that already have their related Oppty Id in the map
                    Set<Decimal> newDiscountRateSet = parentOpptyIdToDiscRateSetMap.get(parentOpptyId);
                    newDiscountRateSet.add(oli.Discounted_Price__c);
                    parentOpptyIdToDiscRateSetMap.put(parentOpptyId, newDiscountRateSet);
                }
            }else{

                //To check for newest Product 
                List<String> productNameList = new List<String>(); //Pending
                productNameList.add(oli.Product2.Name); //Pending
                parentOpptyIdToProductNameListMap.put(parentOpptyId, productNameList); //Pending

                //If Oppty Id has not been entered into Map yet then initialize it in Map
                Set<Decimal> discountRateSet = new Set<Decimal>();
                discountRateSet.add(oli.Discounted_Price__c);
                parentOpptyIdToDiscRateSetMap.put(parentOpptyId, discountRateSet);
            }
        }


        List<Opportunity> parentUpdateList = new List<Opportunity>();
        for(Opportunity opp : opptyList){
            if(parentOpptyIdToDiscRateSetMap.containsKey(opp.Id)){
                if(parentOpptyIdToDiscRateSetMap.get(opp.Id).size() > 1){
                    if(opp.Overall_Product_Rate_Type__c !=  'Multi-rate'){
                        opp.Overall_Product_Rate_Type__c = 'Multi-rate';
                        parentUpdateList.add(opp);
                    }
                }else{
                    if(opp.Overall_Product_Rate_Type__c !=  'Blended Rate'){
                        opp.Overall_Product_Rate_Type__c = 'Blended Rate';
                        parentUpdateList.add(opp);
                    }
                }
            }
        }

        if(parentUpdateList.size() > 0){
            update parentUpdateList;
        }
    }*/

    public static void checkRecentCOProductRateType(Map<Id, ChangeOrderObj> coIdToCOProductRateTypeMap){
        //If Oppty is a Change Order check to see if it is the parent oppty's Most Recent CO
        //If it is then check to see if the Most Recent CW CO Product Rate Type needs to be updated
        List<Id> parentOpptyIdList = new List<Id>();
        for(ChangeOrderObj coOpp : coIdToCOProductRateTypeMap.values()){
            parentOpptyIdList.add(coOpp.parentOppId);
        }

        List<Opportunity> parentOpptyList = new List<Opportunity>();
        parentOpptyList = [SELECT Id, Name, Most_Recent_Closed_Won_CO__c, Most_Recent_CO_Product_Type__c
                                FROM Opportunity 
                                WHERE Id IN :parentOpptyIdList];

        List<Opportunity> parentUpdateList = new List<Opportunity>();

        for(Opportunity opp : parentOpptyList){
            if(coIdToCOProductRateTypeMap.containsKey(opp.Most_Recent_Closed_Won_CO__c)){
                if(coIdToCOProductRateTypeMap.get(opp.Most_Recent_Closed_Won_CO__c) != null){
                    if(opp.Most_Recent_CO_Product_Type__c != coIdToCOProductRateTypeMap.get(opp.Most_Recent_Closed_Won_CO__c).changeOrderProductRateType){
                        opp.Most_Recent_CO_Product_Type__c = coIdToCOProductRateTypeMap.get(opp.Most_Recent_Closed_Won_CO__c).changeOrderProductRateType;
                        parentUpdateList.add(opp);
                    }   
                }
            }
        }

        if(parentUpdateList.size() > 0){
            update parentUpdateList;
        }

    }

    private class ChangeOrderObj{
        public Id parentOppId;
        public String changeOrderProductRateType;
    }

    public static void setOffshoreResourcesOnRelatedOppty(Set<Id> opptyIdSet){
        //After Insert, Update, Delete of an Opportunity Product this method automates the checking and unchecking of the Offshore Resources Checkbox on the related Opportunity

        Set<Id> opportunitiesWithOffshoreProductsIdSet = new Set<Id>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        oliList = [SELECT Id, Name, OpportunityId, Opportunity.Offshore_Resources__c, Resource_Delivery_Group__c 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId IN :opptyIdSet AND Resource_Delivery_Group__c IN ('Offshore', 'Lev - India', 'Lev - Central Europe', 'Lev - Sub') 
                    ORDER BY OpportunityId];

        for(OpportunityLineItem oli : oliList){
            opportunitiesWithOffshoreProductsIdSet.add(oli.OpportunityId); //If there are Offshore Oppty Products on the Oppty then add the Id to the set to check later
        }

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, Offshore_Resources__c FROM Opportunity WHERE Id IN :opptyIdSet];

        List<Opportunity> opptyToUpdateList = new List<Opportunity>();
        for(Opportunity opp : opptyList){

            if(opportunitiesWithOffshoreProductsIdSet.contains(opp.Id) && opp.Offshore_Resources__c != true){
                opp.Offshore_Resources__c = true;
                opptyToUpdateList.add(opp);
            }else if(!opportunitiesWithOffshoreProductsIdSet.contains(opp.Id) && opp.Offshore_Resources__c != false){
                opp.Offshore_Resources__c = false;
                opptyToUpdateList.add(opp);
            }
        }

        if(opptyToUpdateList.size() > 0){
            System.debug('******************************** Updating Offshore Resources on ' + opptyToUpdateList.size() + ' Opportunities. ********************************');
            update opptyToUpdateList;
        }
    }

    public static void getProjectsForHybridStaffCheck(Set<Id> opptyIdSet){

        List<Project__c> projList = new List<Project__c>();
        projList = [SELECT Id, Name, Opportunity__c, HybridStaff__c
                    FROM Project__c
                    WHERE Opportunity__c IN :opptyIdSet OR Opportunity__r.Change_Orders__c IN :opptyIdSet];

        if(projList.size() > 0){
            checkForHybridStaffOnProject(projList, true); //This method is only called from the Opportunity Line Item trigger so it always requires an update so set the needsUpdate parameter = true

        }
    }

    public static void checkForHybridStaffOnProject(List<Project__c> projList, Boolean needsUpdate){

        Map<Id, Boolean> opportunityIdToHybridStaffBooleanMap = new Map<Id, Boolean>();
        List<Project__c> updateProjectHybridStaffList = new List<Project__c>();

        for(Project__c proj : projList){
            if(proj.Opportunity__c != null){
                opportunityIdToHybridStaffBooleanMap.put(proj.Opportunity__c, false);
            }
        }

        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        opportunityLineItemList = [SELECT Id, Name, Resource_Delivery_Group__c, OpportunityId, Opportunity.Change_Orders__c, Opportunity.RecordTypeId
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId IN :opportunityIdToHybridStaffBooleanMap.keySet() OR Opportunity.Change_Orders__c IN :opportunityIdToHybridStaffBooleanMap.keySet()];

        for(OpportunityLineItem oli : opportunityLineItemList){

            if(!levResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c)){ //If the Opportunity Line Item has a Resource Delivery Group that IS NOT Lev-NA, Lev-UK, or Lev-Onshore then mark the Project as Hybrid Staff = true
                if(oli.Opportunity.RecordTypeId == changeOrderOpptyRT){ //If it is a change order then set the Hybrid Staff map for the parent Oppty of the Opportunity Product's Oppty
                    opportunityIdToHybridStaffBooleanMap.put(oli.Opportunity.Change_Orders__c, true);

                }else{ //If NOT a change Order then set the Hybrid Staff map for the Oppty of the Opportunity Product
                    opportunityIdToHybridStaffBooleanMap.put(oli.OpportunityId, true);
                }
            }
        }

        for(Project__c proj : projList){
            if(opportunityIdToHybridStaffBooleanMap.containsKey(proj.Opportunity__c)){
                Boolean isProjectHybridStaff = opportunityIdToHybridStaffBooleanMap.get(proj.Opportunity__c);
                
                //Check if Hybrid Staff checkbox needs to be changed
                if(proj.HybridStaff__c != isProjectHybridStaff){
                    proj.HybridStaff__c = isProjectHybridStaff;
                    updateProjectHybridStaffList.add(proj);
                }
            }
        }

        //Check if is before update and can just be set, or if not and needs an update
        if(needsUpdate){
            System.debug('*********************************************** Update Project Hybrid Staff on ' + updateProjectHybridStaffList.size() + ' projects. ***********************************************');
            update updateProjectHybridStaffList;
        }
    }

    public static void countProductsOnOpportunity(Set<Id> opportunityIdSet){

        Map<Id, Decimal> opptyIdToOpptyProductCountMap = new Map<Id, Decimal>();
		for(Id opptyId : opportunityIdSet){
			opptyIdToOpptyProductCountMap.put(opptyId, 0);
		}

		AggregateResult[] opptyProductAgg = [SELECT COUNT(Id), OpportunityId
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId IN :opptyIdToOpptyProductCountMap.keySet()
                                                GROUP BY OpportunityId
                                                ORDER BY COUNT(Id) DESC];

		for(AggregateResult ar : opptyProductAgg){
			Decimal opptyProductCount = (Decimal)ar.get('expr0');
			Id opptyId = (Id)ar.get('OpportunityId');

			opptyIdToOpptyProductCountMap.put(opptyId, opptyProductCount);
		}

		List<Opportunity> relatedOpptyList = new List<Opportunity>();
		relatedOpptyList = [SELECT Id, Name, Number_of_Products__c
								FROM Opportunity
								WHERE Id IN :opptyIdToOpptyProductCountMap.keySet()];

		List<Opportunity> opptyUpdateList = new List<Opportunity>();
		for(Opportunity oppty : relatedOpptyList){
			if(opptyIdToOpptyProductCountMap.containsKey(oppty.Id) && oppty.Number_of_Products__c != opptyIdToOpptyProductCountMap.get(oppty.Id)){
				oppty.Number_of_Products__c = opptyIdToOpptyProductCountMap.get(oppty.Id);
				opptyUpdateList.add(oppty);
			}
		}

		if(opptyUpdateList.size() > 0){
			System.debug('Updating Total Opportunity Product Count on ' + opptyUpdateList.size() + ' Opportunities');
			update opptyUpdateList;
		}
    }
}