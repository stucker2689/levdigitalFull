public with sharing class ProjectBillingRateDatatableController {

    public class BillingRateWrapper{
        @AuraEnabled
        public Id rateId {get;set;}
        @AuraEnabled
        public String billingRateName {get;set;}
        @AuraEnabled
        public String RateUrl {get;set;}
        @AuraEnabled
        public Decimal rateHourlyRate {get;set;}
        @AuraEnabled
        public Decimal hoursSold {get;set;}
        @AuraEnabled
        public Decimal amountSold {get;set;}
        @AuraEnabled
        public Decimal hoursBilled {get;set;}
        @AuraEnabled
        public Decimal rateHoursLeft {get;set;}
        @AuraEnabled
        public Decimal amountBilled {get;set;}
        @AuraEnabled
        public List<BillingRateWrapper> childrenWrappers {get;set;}
        @AuraEnabled
        public Map<String, BillingRateWrapper> childrenWrapperMap {get;set;}
    }

    public class TimeEntryRollupWrapper{
        @AuraEnabled
        public Decimal totalHoursBilled {get;set;}
        @AuraEnabled
        public Decimal totalAmountBilled {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<BillingRateWrapper> getBillingRateTableData(String projectId){

        List<BillingRateWrapper> billingRateTableDataList = new List<BillingRateWrapper>();

        AggregateResult[] timeEntryAggregate = [SELECT SUM(TotalHrs__c) totalHours, SUM(Billable_Amount__c) totalAmount, Associated_Billing_Rate__c
                                                FROM Replicon_Time_Entry__c
                                                WHERE Deleted_in_Replicon__c = false AND Project__c =: projectId AND Associated_Billing_Rate__c != null AND Associated_Billing_Rate__r.Name != 'Concession' AND Associated_Billing_Rate__r.Outdated_Rate__c = false
                                                GROUP BY Associated_Billing_Rate__c];

        Map<Id, TimeEntryRollupWrapper> billRateIdToTimeRollupMap = new Map<Id, TimeEntryRollupWrapper>();
        for(AggregateResult ar : timeEntryAggregate){

            Id billRateId = (Id)ar.get('Associated_Billing_Rate__c');
            Decimal totalHours = (Decimal)ar.get('totalHours') != null ? (Decimal)ar.get('totalHours') : 0;
            Decimal totalAmount = (Decimal)ar.get('totalAmount') != null ? (Decimal)ar.get('totalAmount') : 0;

            if(billRateIdToTimeRollupMap.containsKey(billRateId)){
                TimeEntryRollupWrapper rollups = billRateIdToTimeRollupMap.get(billRateId);
                rollups.totalHoursBilled += totalHours;
                rollups.totalAmountBilled += totalAmount;
                billRateIdToTimeRollupMap.put(billRateId, rollups);
            }else{
                TimeEntryRollupWrapper rollups = new TimeEntryRollupWrapper();
                rollups.totalHoursBilled = totalHours;
                rollups.totalAmountBilled = totalAmount;
                billRateIdToTimeRollupMap.put(billRateId, rollups);
            }

        }

        List<Project_Team_Member_Billing_Rate__c> billingRateList = new List<Project_Team_Member_Billing_Rate__c>();
        billingRateList = [SELECT Id, Name, Hourly_Rate__c, Created_in_Salesforce__c, Product__c, Product__r.Name, Project__c, Quantity_Sold__c, Total_Amount_Sold__c, Project__r.Opportunity__c, Outdated_Rate__c
                            FROM Project_Team_Member_Billing_Rate__c
                            WHERE Project__c =:projectId AND Is_Temporary_Rate__c = false AND Is_Concession_Rate__c = false AND Is_Placeholder_Rate__c = false AND Name != 'Average Project Bill Rate' AND Outdated_Rate__c = false
                            ORDER BY Name, CreatedDate DESC];

        Set<Id> rateIdSet = new Set<Id>();
        Id opportunityId;

        Map<String, BillingRateWrapper> baseRateNameToParentWrapperMap = new Map<String, BillingRateWrapper>();
        Map<String, BillingRateWrapper> rateNameToParentWrapperMap = new Map<String, BillingRateWrapper>();
        for(Project_Team_Member_Billing_Rate__c rate : billingRateList){
            rateIdSet.add(rate.Id);
            opportunityId = rate.Project__r.Opportunity__c;

            String rateBaseName;
            if(rate.Product__c != null){
                rateBaseName = rate.Product__r.Name;
            }else if(rate.Name.right(1).isNumeric()){ //If it is only letters and spaces
                rateBaseName = rate.Name.left(rate.Name.length() - 1).trim(); //Attempt to get rid of the number that is appended to the bill rate name
            }else{
                rateBaseName = rate.Name;
            }

            if(baseRateNameToParentWrapperMap.containsKey(rateBaseName)){
                //If base rate already exists in map, then add to the rollup values

                //Create or Update Child Wrappers within the existing Parent Wrapper
                BillingRateWrapper baseWrapper = baseRateNameToParentWrapperMap.get(rateBaseName); //Get Parent Wrapper

                String uniqueChildWrapperId = rateBaseName + ' | ' + String.valueOf(rate.Hourly_Rate__c);
                BillingRateWrapper childWrapper;
                if(baseRateNameToParentWrapperMap.get(rateBaseName).childrenWrapperMap.containsKey(uniqueChildWrapperId)){
                    //If child Wrapper is already in the list of the parent wrapper then just update it
                    childWrapper = baseRateNameToParentWrapperMap.get(rateBaseName).childrenWrapperMap.get(uniqueChildWrapperId);
                    childWrapper.hoursSold += rate.Quantity_Sold__c != null ? rate.Quantity_Sold__c : 0;
                    childWrapper.amountSold += rate.Total_Amount_Sold__c != null ? rate.Total_Amount_Sold__c : 0;
                    childWrapper.hoursBilled += billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalHoursBilled : 0;
                    childWrapper.rateHoursLeft = childWrapper.hoursSold - childWrapper.hoursBilled;
                    childWrapper.amountBilled += billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalAmountBilled : 0;

                    
                }else{
                    //If doesn't exist then create it
                    childWrapper = new BillingRateWrapper();
                    childWrapper.rateId = rate.Id;
                    childWrapper.BillingRateName = rate.Name;
                    childWrapper.RateUrl = '/' + rate.Id;
                    childWrapper.rateHourlyRate = rate.Hourly_Rate__c;
                    childWrapper.hoursSold = rate.Quantity_Sold__c != null ? rate.Quantity_Sold__c : 0;
                    childWrapper.amountSold = rate.Total_Amount_Sold__c != null ? rate.Total_Amount_Sold__c : 0;
                    childWrapper.hoursBilled = billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalHoursBilled : 0;
                    childWrapper.rateHoursLeft = childWrapper.hoursSold - childWrapper.hoursBilled;
                    childWrapper.amountBilled = billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalAmountBilled : 0;
                    childWrapper.childrenWrappers = new List<BillingRateWrapper>();

                    List<BillingRateWrapper> childWrapperList = baseWrapper.childrenWrappers;
                    childWrapperList.add(childWrapper);
                    baseWrapper.childrenWrappers = childWrapperList;
                }

                //Update the Parent Wrapper
                baseWrapper.hoursSold += rate.Quantity_Sold__c != null ? rate.Quantity_Sold__c : 0;
                baseWrapper.amountSold += rate.Total_Amount_Sold__c != null ? rate.Total_Amount_Sold__c : 0;
                baseWrapper.hoursBilled += billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalHoursBilled : 0;
                baseWrapper.rateHoursLeft = baseWrapper.hoursSold - baseWrapper.hoursBilled;
                baseWrapper.amountBilled += billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalAmountBilled : 0;

                

                Map<String, BillingRateWrapper> childWrapperMap = baseWrapper.childrenWrapperMap;
                childWrapperMap.put(uniqueChildWrapperId, childWrapper);
                baseWrapper.childrenWrapperMap = childWrapperMap;

                baseRateNameToParentWrapperMap.put(baseWrapper.BillingRateName, baseWrapper);
            }else{
                //If base rate DOES NOT yet exist in the map, then put it into the map
                List<BillingRateWrapper> childWrapperList = new List<BillingRateWrapper>();
                BillingRateWrapper newChildWrapper = new BillingRateWrapper();
                newChildWrapper.rateId = rate.Id;
                newChildWrapper.BillingRateName = rate.Name;
                newChildWrapper.RateUrl = '/' + rate.Id;
                newChildWrapper.rateHourlyRate = rate.Hourly_Rate__c;
                newChildWrapper.hoursSold = rate.Quantity_Sold__c != null ? rate.Quantity_Sold__c : 0;
                newChildWrapper.amountSold = rate.Total_Amount_Sold__c != null ? rate.Total_Amount_Sold__c : 0;
                newChildWrapper.hoursBilled = billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalHoursBilled : 0;
                newChildWrapper.rateHoursLeft = newChildWrapper.hoursSold - newChildWrapper.hoursBilled;
                newChildWrapper.amountBilled = billRateIdToTimeRollupMap.containsKey(rate.Id) ? billRateIdToTimeRollupMap.get(rate.Id).totalAmountBilled : 0;
                newChildWrapper.childrenWrappers = new List<BillingRateWrapper>();
                childWrapperList.add(newChildWrapper);

                Map<String, BillingRateWrapper> childWrapperMap = new Map<String, BillingRateWrapper>();
                String uniqueChildWrapperId = rateBaseName + ' | ' + String.valueOf(rate.Hourly_Rate__c);
                childWrapperMap.put(uniqueChildWrapperId, newChildWrapper);

                //Create the parent Wrapper to host each Child Wrapper
                BillingRateWrapper newBaseWrapper = new BillingRateWrapper();
                newBaseWrapper.BillingRateName = rateBaseName;
                //newBaseWrapper.rateHourlyRate = rate.Hourly_Rate__c;
                newBaseWrapper.hoursSold = rate.Quantity_Sold__c != null ? rate.Quantity_Sold__c : 0;
                newBaseWrapper.amountSold = rate.Total_Amount_Sold__c != null ? rate.Total_Amount_Sold__c : 0;
                newBaseWrapper.hoursBilled = newChildWrapper.hoursBilled;
                newBaseWrapper.rateHoursLeft = newBaseWrapper.hoursSold - newBaseWrapper.hoursBilled;
                newBaseWrapper.amountBilled = newChildWrapper.amountBilled;
                newBaseWrapper.childrenWrappers = childWrapperList;
                newBaseWrapper.childrenWrapperMap = childWrapperMap;

                baseRateNameToParentWrapperMap.put(newBaseWrapper.BillingRateName, newBaseWrapper);
                
            }
        }        

        billingRateTableDataList.addAll(baseRateNameToParentWrapperMap.values());
        return billingRateTableDataList;

    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getNewBillingRateOptions(){
        try {

            List<Product2> placeholderProductRoleList = new List<Product2>();

            List<Product2> productsList = new List<Product2>();
            productsList = [SELECT Id, Name, IsActive
                            FROM Product2
                            WHERE IsActive = true AND (NOT Name LIKE '%Margin User%') 
                            ORDER BY Name];

            for(Product2 p : productsList){
                placeholderProductRoleList.add(p);
            }

            return placeholderProductRoleList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Project_Team_Member_Billing_Rate__c createNewBillingRate(String projectId, String productId, String billRateName, Decimal hourlyRate){
        try {

            String soqlBillRateName = '%' + billRateName + '%';

            List<Project_Team_Member_Billing_Rate__c> billingRatesList = new List<Project_Team_Member_Billing_Rate__c>();
            billingRatesList = [SELECT Id, Name, Project__c, Product__c, Product__r.Name, Hourly_Rate__c
                                FROM Project_Team_Member_Billing_Rate__c
                                WHERE Project__c =: projectId AND Name LIKE :soqlBillRateName
                                ORDER BY Name];

            Integer billRateNumber = 0;
            if(billingRatesList.size() > 0){
                for(Project_Team_Member_Billing_Rate__c rate : billingRatesList){

                    if(rate.Hourly_Rate__c == hourlyRate){
                        String message = 'Billing Rate with same name and rate already exists on this project.';
                        AuraHandledException auraError = new AuraHandledException(message);
                        auraError.setMessage('Billing Rate with same name and rate already exists on this project.');
                        throw auraError;
                    }
                }

                Project_Team_Member_Billing_Rate__c lastRate = billingRatesList[billingRatesList.size() - 1];
                if( lastRate.Name.right(1).isNumeric() ){
                        //If this is true, then the Rate has other rates with numbers appended to their names, thus for this new rate a number is also needed.
                        Integer rateNumber = Integer.valueOf(lastRate.Name.right(1));
                        rateNumber++;
                        billRateNumber = rateNumber;
                }else{
                    billRateNumber = 2;
                }
            }

            Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c();
            newRate.Project__c = (Id)projectId;
            newRate.Product__c = (Id)productId;
            newRate.Hourly_Rate__c = hourlyRate;
            newRate.Created_in_Salesforce__c = true;
            if(billRateNumber == 0){
                //If there are no other rates with the same name, then no number needs to be appended.
                newRate.Name = billRateName;
            }else{
                newRate.Name = billRateName + ' ' + String.valueOf(billRateNumber);
            }

            return newRate;
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}