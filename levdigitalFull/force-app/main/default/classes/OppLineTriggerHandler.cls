public with sharing class OppLineTriggerHandler {

    private static List<String> offshoreResourceDeliveryGroupNamesList = new List<String>{'Offshore', 'Lev - India', 'Lev - Central Europe', 'Lev - Sub', 'Lev-Sub', 'Lev-CE'};
    private static List<String> levResourceDeliveryGroupNamesList = new List<String>{'Lev-NA', 'Lev-UK', 'Lev - NA', 'Lev - UK', 'Lev-Onshore'};
    
    
    public static void onBeforeInsert(List<OpportunityLineItem> newList){
    }

    public static void onAfterInsert(List<OpportunityLineItem> newList) {

        Set<Id> offshoreOLIOpptyIdSet = new Set<Id>();
        Set<Id> opptyIdsForHybridStaffCheckSet = new Set<Id>();
        Set<Id> lowRateProductOpptyIdSet = new Set<Id>();
        Set<Id> rollupOpptyProductCountOpptyIdSet = new Set<Id>();

        List<OpportunityLineItem> newProfServicesOpptyProductList = returnProfessionalServicesProducts(newList);
        if(newProfServicesOpptyProductList.size() > 0){
            OppLineTriggerHelper.checkOpptyProductRate(newProfServicesOpptyProductList);
        }

        //Create Replicon Info and Products for Change Order gone to or From new Opporuntity Line Items
        if(newProfServicesOpptyProductList.size() > 0){
            System.debug('New Opportunity Product List: ' + newProfServicesOpptyProductList);
            ProjectRoleManager.ProjectRoleManager_Handler(newProfServicesOpptyProductList);
        }


        for(OpportunityLineItem oli : newList){
            //Added check 2/1/2023 To automate checking of Offshore Resource Checkbox on Opportunity
            if(oli.OpportunityId != null){
                
                if(offshoreResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c)){ //To Populate Offshore Resources field on Opportunity
                    offshoreOLIOpptyIdSet.add(oli.OpportunityId);
                }
                 //Added logic to check Hybrid Staff on Project if an Oppty Product is created with a global or offshore RDG ST 4.4.2023
                if(!levResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c)){ //To Populate Hybrid Staff field on Project
                    opptyIdsForHybridStaffCheckSet.add(oli.OpportunityId);
                }

                //Added 9.27.2023 ST Check for Low Rate Oppty Products on Won Oppty for Email Alert
                if(oli.Discounted_Price__c <= 75 && oli.Resource_Delivery_Group__c == 'Lev - NA' && oli.Is_Opportunity_Won__c == true ){
                    lowRateProductOpptyIdSet.add(oli.OpportunityId);
                }

                rollupOpptyProductCountOpptyIdSet.add(oli.OpportunityId);
            }
        }

        if(offshoreOLIOpptyIdSet.size() > 0){
            OppLineTriggerHelper.setOffshoreResourcesOnRelatedOppty(offshoreOLIOpptyIdSet);
        }

        if(opptyIdsForHybridStaffCheckSet.size() > 0){
            OppLineTriggerHelper.getProjectsForHybridStaffCheck(opptyIdsForHybridStaffCheckSet);
        }

        //Added as part of Horizon Project Billing Rate Creation ST 4.19.2023
        if(newList.size() > 0){
            ProjectBillingRateManager.manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate(newList);
        }

        if(lowRateProductOpptyIdSet.size() > 0){
            OpportunityTriggerHelper.sendLowRateOpptyProductAlert(lowRateProductOpptyIdSet);
        }

        if(rollupOpptyProductCountOpptyIdSet.size() > 0){
            OppLineTriggerHelper.countProductsOnOpportunity(rollupOpptyProductCountOpptyIdSet);
        }

    }

    public static void onBeforeUpdate(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap){

        
    }

    public static void onAfterUpdate(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap){

        List<OpportunityLineItem> changedOpptyProductForRepliconInfoAndProdList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> updateOpptyProductForProjectBillingRateSync = new List<OpportunityLineItem>();
        Set<Id> offshoreOLIOpptyIdSet = new Set<Id>();
        Set<Id> checkHybridStaffOpptyIdSet = new Set<Id>();
        Set<Id> lowRateProductOpptyIdSet = new Set<Id>();
        
        //Only if Discounted Price OR Product Family has changed 
        List<OpportunityLineItem> changedOpptyProductList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : newList){

            OpportunityLineItem oldOli = oldMap.get(oli.Id);

            if((oli.Discounted_Price__c != oldOli.Discounted_Price__c) && (oli.Opportunity_Product_Family__c == 'Professional Services' || oldOli.Opportunity_Product_Family__c == 'Professional Services') ){
                changedOpptyProductList.add(oli);
            }

            if(((oli.Discounted_Price__c != oldOli.Discounted_Price__c) || (oli.Quantity != oldOli.Quantity) || (oli.TotalPrice != oldOli.TotalPrice) || (oli.Resource_Delivery_Group__c != oldOli.Resource_Delivery_Group__c)) && (oli.Opportunity_Product_Family__c == 'Professional Services' || oldOli.Opportunity_Product_Family__c == 'Professional Services') ){
                changedOpptyProductForRepliconInfoAndProdList.add(oli);
            }

            //Added check 2/1/2023 To automate checking of Offshore Resource Checkbox on Opportunity
            if(oli.OpportunityId != null && oli.Resource_Delivery_Group__c != oldOli.Resource_Delivery_Group__c && (offshoreResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c) || offshoreResourceDeliveryGroupNamesList.contains(oldOli.Resource_Delivery_Group__c))){
                offshoreOLIOpptyIdSet.add(oli.OpportunityId);
            }

            //Added logic to check Hybrid Staff on Project if an Oppty Product is updated to or from internal Lev RDG to a RDG that is no internal Lev
            if((!levResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c) && levResourceDeliveryGroupNamesList.contains(oldOli.Resource_Delivery_Group__c)) || (!levResourceDeliveryGroupNamesList.contains(oldOli.Resource_Delivery_Group__c) && levResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c))){
                checkHybridStaffOpptyIdSet.add(oli.OpportunityId);
            }

            //Added as part of Horizon Project Billing Rate Creation ST 4.19.2023
            if((oli.Discounted_Price__c != oldOli.Discounted_Price__c) || (oli.Quantity != oldOli.Quantity) || (oli.TotalPrice != oldOli.TotalPrice)){
                updateOpptyProductForProjectBillingRateSync.add(oli);
            }

            //Added 9.27.2023 ST Check for Low Rate Oppty Products on Won Oppty for Email Alert
            if((oli.Discounted_Price__c <= 75 && oli.Resource_Delivery_Group__c == 'Lev - NA' && oli.Is_Opportunity_Won__c == true) && (oldOli.Discounted_Price__c > 75 || oldOli.Resource_Delivery_Group__c != 'Lev - NA')){
                lowRateProductOpptyIdSet.add(oli.OpportunityId);
            }
        }

        if(changedOpptyProductList.size() > 0){
            OppLineTriggerHelper.checkOpptyProductRate(changedOpptyProductList);
        }

        //Create Replicon Info and Products for Change Order gone to or From new Opporuntity Line Items
        if(changedOpptyProductForRepliconInfoAndProdList.size() > 0){
            System.debug('Changed Opportunity Product List: ' + changedOpptyProductForRepliconInfoAndProdList);
            ProjectRoleManager.ProjectRoleManager_Handler(changedOpptyProductForRepliconInfoAndProdList);
        }

        if(offshoreOLIOpptyIdSet.size() > 0){
            OppLineTriggerHelper.setOffshoreResourcesOnRelatedOppty(offshoreOLIOpptyIdSet);
        }

        if(checkHybridStaffOpptyIdSet.size() > 0){
            OppLineTriggerHelper.getProjectsForHybridStaffCheck(checkHybridStaffOpptyIdSet);
        }

        if(updateOpptyProductForProjectBillingRateSync.size() > 0){
            ProjectBillingRateManager.manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate(updateOpptyProductForProjectBillingRateSync);
        }

        if(lowRateProductOpptyIdSet.size() > 0){
            OpportunityTriggerHelper.sendLowRateOpptyProductAlert(lowRateProductOpptyIdSet);
        }

    }

    public static void onBeforeDelete(List<OpportunityLineItem> oldList, Map<Id, OpportunityLineItem> oldMap){

    }

    public static void onAfterDelete(List<OpportunityLineItem> oldList, Map<Id, OpportunityLineItem> oldMap){

        Set<Id> offshoreOLIOpptyIdSet = new Set<Id>();
        Set<Id> checkHybridStaffOpptyIdSet = new Set<Id>();
        Set<Id> rollupOpptyProductCountOpptyIdSet = new Set<Id>();

        for(OpportunityLineItem oli : oldList){

            //Added check 2/1/2023 To automate checking of Offshore Resource Checkbox on Opportunity
            if(oli.OpportunityId != null && offshoreResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c)){
                offshoreOLIOpptyIdSet.add(oli.OpportunityId);
            }

            //Added logic to check Hybrid Staff on Project if an Oppty Product is deleted and was a global or offshore RDG ST 4.4.2023
            if(!levResourceDeliveryGroupNamesList.contains(oli.Resource_Delivery_Group__c)){
                checkHybridStaffOpptyIdSet.add(oli.OpportunityId);
            }

            if(oli.OpportunityId != null){
                rollupOpptyProductCountOpptyIdSet.add(oli.OpportunityId);
            }

        }
        
        List<OpportunityLineItem> deletedProfServicesOpptyProductList = returnProfessionalServicesProducts(oldList);
        if(deletedProfServicesOpptyProductList.size() > 0){
            OppLineTriggerHelper.checkOpptyProductRate(deletedProfServicesOpptyProductList);
        }

        //Edit Replicon Info and Products for Change Order gone to or From deleted Opporuntity Line Items
        if(deletedProfServicesOpptyProductList.size() > 0){
            System.debug('Deleted Opportunity Product List: ' + deletedProfServicesOpptyProductList);
            ProjectRoleManager.ProjectRoleManager_Handler(deletedProfServicesOpptyProductList);
            ProjectBillingRateManager.ProjectBillingRateManager_Handler(deletedProfServicesOpptyProductList);
        }

        if(offshoreOLIOpptyIdSet.size() > 0){
            OppLineTriggerHelper.setOffshoreResourcesOnRelatedOppty(offshoreOLIOpptyIdSet);
        }

        if(checkHybridStaffOpptyIdSet.size() > 0){
            OppLineTriggerHelper.getProjectsForHybridStaffCheck(checkHybridStaffOpptyIdSet);
        }

        //Added Horizon Logic for Syncing Project Billing Rates 4.19.2023 ST
        //Added as part of Horizon Project Billing Rate Creation ST 4.19.2023
        if(oldList.size() > 0){
            ProjectBillingRateManager.manageProjectBillingRatesFromOpportunityLineItemInsertOrUpdate(oldList);
        }

        if(rollupOpptyProductCountOpptyIdSet.size() > 0){
            OppLineTriggerHelper.countProductsOnOpportunity(rollupOpptyProductCountOpptyIdSet);
        }
    }

    private static List<OpportunityLineItem> returnProfessionalServicesProducts(List<OpportunityLineItem> opptyLineList){

        //Filter out other Opportuntiy Products to only pass Opportunity Products with a Product Family of 'Professional Services'
        List<OpportunityLineItem> professionalServicesOpptyProductList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : opptyLineList){
            if(oli.Opportunity_Product_Family__c == 'Professional Services'){
                professionalServicesOpptyProductList.add(oli);
            }
        }

        return professionalServicesOpptyProductList;
    }

}