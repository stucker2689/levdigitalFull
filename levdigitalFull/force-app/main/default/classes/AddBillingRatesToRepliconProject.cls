public with sharing class AddBillingRatesToRepliconProject implements Queueable, Database.AllowsCallouts{
    
    private static String COMPANY_KEY = 'levementum';
    private static String AUTH_USERNAME = 'u2014';
    private static String AUTH_PASSWORD = 'aNP3UWeawu7c';
    private static String BASE_URL = 'https://na3.replicon.com/levementum/services/';
    private static Map<String, RepliconBillingRateResponse.d> repliconProjectNameToDeserializedBillRateMap = new Map<String, RepliconBillingRateResponse.d>();
    private static Map<String, String> repliconBillingRateNameToURIMap = new Map<String, String>();

    private String projectId;
    
    public AddBillingRatesToRepliconProject(String newProjectId) {
        this.projectId = newProjectId;
    }

    public void execute(QueueableContext qc) {

        try{
            addOpportunityProductsAsRepliconBillRates(this.projectId);

        }catch(Exception e) {
            System.debug('Creating Billing Rates in Replicon Error caught HERE!!: ' + e);
            LevExceptionHandler.logError(e.getMessage() + ', Billing Rates added to Replicon failed for Project Id: ' + String.valueOf(projectId), e.getLineNumber(), 'AddBillingRatesToRepliconProject', 'execute on AddBillingRatesToRepliconProject', NULL);
        }
    }

    public static void addOpportunityProductsAsRepliconBillRates(Id projectId){

        /**
         * 1.) Project gets created and populated with RepliconURI (either is run when project is created and has Replicon URI or once the Project is populated with a Replicon URI)
         * 2.) Lookup Opportunity Products on the related Opportunity
         * 3.) Get the URI of the products by matching the name to the Replicon Billing Rates via the getAllBillingRates Replicon Services callout.
         * 4.) Create the Billing Rate for the project
         * 5.) Update the Billing Rate in Replicon with the Amount matching the Discounted Price on the Opportunity Product.
         */

        try{

            Project__c billRateCreationProject = [SELECT Id, Name, Opportunity__c, RepliconURI__c 
                                                    FROM Project__c 
                                                    WHERE Id =: projectId LIMIT 1];

            if(billRateCreationProject.RepliconURI__c != null){ //Must have a Replicon URI to add Billing Rates to the Project in Replicon
                List<OpportunityLineItem> relatedOpportunityProductsList = new List<OpportunityLineItem>();
                relatedOpportunityProductsList = [SELECT Id, Name, Product2Id, Product2.Name, Discounted_Price__c, Opportunity_Product_Family__c
                                                    FROM OpportunityLineItem 
                                                    WHERE OpportunityId =:  billRateCreationProject.Opportunity__c
                                                    ORDER BY Discounted_Price__c ASC];
                                                    
                if(relatedOpportunityProductsList.size() > 0){ //Check that there are Opportunity Products before making callouts to create them in Replicon.

                    System.debug('******************************** Before get All Billing Rates ********************************');
                    getAllRepliconBillingRates(billRateCreationProject.RepliconURI__c); //Run the getAllBillingRates callout to get repliconProjectNameToDeserializedBillRateMap Map of Billing Rate Name to Billling Rate Replicon URI 
                    System.debug('******************************** After get All Billing Rates ********************************');
                    for(OpportunityLineItem opptyProduct : relatedOpportunityProductsList){

                        if(repliconBillingRateNameToURIMap.containsKey(opptyProduct.Product2.Name)){
                            String billingRateRepliconURI = repliconBillingRateNameToURIMap.get(opptyProduct.Product2.Name);
                            System.debug('******************************** Before Add Billing Rates to Replicon ********************************');
                            addBillingRateToRepliconProject(billRateCreationProject.RepliconURI__c, billingRateRepliconURI); //Add the Billing Rate in Replicon on the Project
                            System.debug('******************************** After Add Billing Rates to Replicon ********************************');
                            System.debug('******************************** Before Updating Billing Rates to Replicon ********************************');
                            updateRepliconBillRateAmount(billRateCreationProject.RepliconURI__c, billingRateRepliconURI, opptyProduct.Discounted_Price__c); //Update the Billing Rate Amount in Replicon from the default rate to match the Discounted Price that is in SF
                            System.debug('******************************** After Updating Billing Rates to Replicon ********************************');
                        }
                    }
                }
            }
        }catch(Exception e) {
            System.debug('Creating Billing Rates in Replicon Error caught HERE!!: ' + e);
            LevExceptionHandler.logError(e.getMessage() + ', Billing Rates added to Replicon failed for Project Id: ' + String.valueOf(projectId), e.getLineNumber(), 'CreateRepliconBillingRates', 'addOpportunityProductsAsRepliconBillRates', NULL);
        }
    }

    //Create Billing Rates on a specified Project in Replicon
    public static void addBillingRateToRepliconProject(String projectRepliconURI, String billingRateRepliconURI){

        //projectRepliconURI = 'urn:replicon-tenant:levementum:project:29891';
        //billingRateRepliconURI = 'urn:replicon-tenant:levementum:company-billing-rate:26d0b384-2e3a-4d99-a408-8dabdff61df5';

        //Create the JSON String for Callout to Replicon
        String createBillRateJSONString = '{ "projectUri": "' + projectRepliconURI + '", ';
        createBillRateJSONString += '"billingRateUri": "' + billingRateRepliconURI + '", ';
        createBillRateJSONString += '"billingRateAvailableForAssignmentOptionUri": "urn:replicon:billing-rate-available-for-assignment-option:available"}';

        //Build HTTP Request to make Callout to Replicon to Create the Replicon Billing Rate
        HttpRequest req = getRequest('TimeAndMaterialsProjectService1.svc/UpdateBillingRateIsAvailableForAssignmentToTeamMembers');
        req.setBody(createBillRateJSONString);

        Http h = new Http();
        HttpResponse response = h.send(req); //Make the Callout

    }

    //Update the Rate of Existing Billing Rates in Replicon that already exist on the specified project.
    public static void updateRepliconBillRateAmount(String projectRepliconURI, String billingRateRepliconURI, Decimal billingRateAmount){

        //projectRepliconURI = 'urn:replicon-tenant:levementum:project:29891';
        //billingRateRepliconURI = 'urn:replicon-tenant:levementum:company-billing-rate:26d0b384-2e3a-4d99-a408-8dabdff61df5';
        String billingRateAmountString = String.valueOf(billingRateAmount);

        //Create JSON String for Callout to Replicon
        String jsonString = '{ "projectUri": "' + projectRepliconURI +'",';
        jsonString += '"billingRateUri": "' + billingRateRepliconURI +'",';
        jsonString += '"dateRange": null,';
        jsonString += '"rate": { "amount": "' + billingRateAmount +'", "currencyUri": "urn:replicon-tenant:levementum:currency:1"}}';

        //Build HTTP Request to make Callout to Replicon to Update the Replicon Billing Rate
        HttpRequest req = getRequest('TimeAndMaterialsProjectService1.svc/UpdateProjectBillingRateScheduleOverDateRange');
        req.setBody(jsonString);

        Http h = new Http();
        HttpResponse response = h.send(req); //Make the Callout

    }


    public static void getAllRepliconBillingRates(String projectRepliconURI){

        //String projectRepliconURI = 'urn:replicon-tenant:levementum:project:29891';

        //Create JSON String for Callout to Replicon 
        String jsonString = '{"projectUri": "' + projectRepliconURI + '", "asOfDate": null}';

        //Build HTTP Request to make Callout to Replicon to Update the Replicon Billing Rate
        //HttpRequest req = getRequest('TimeAndMaterialsProjectService1.svc/GetBillingRates'); //Gets all Billing Rates for entire Replicon Org
        HttpRequest req = getRequest('TimeAndMaterialsProjectService1.svc/GetCouldBeEnabledBillingRates'); //Gets all Billing Rates that are not already added to the project
        req.setBody(jsonString);
        Http h = new Http();
        HttpResponse response = h.send(req); //Make the Callout    

        RepliconBillingRateResponse deserializedBillingRateDetails = RepliconBillingRateResponse.parse(response.getBody());

        for(RepliconBillingRateResponse.d currentDeserializedBillRate : deserializedBillingRateDetails.d) {
            //System.debug('Bill Rate Name: ' + currentDeserializedBillRate.billingRate.name + '   URI: ' + currentDeserializedBillRate.billingRate.uri + '   Amount: ' + currentDeserializedBillRate.effectiveBillingRate.value.amount);            
            repliconProjectNameToDeserializedBillRateMap.put(currentDeserializedBillRate.billingRate.name, currentDeserializedBillRate); //Put all Billing Rates into a map in order to access the Replicon URIs
            repliconBillingRateNameToURIMap.put(currentDeserializedBillRate.billingRate.name, currentDeserializedBillRate.billingRate.uri);
        }
    }

    //Utility Method to create the HTTP Request to callout to Replicon
    private static HttpRequest getRequest(String endpoint) {

        Blob headerValue = Blob.valueOf(COMPANY_KEY + '\\' + AUTH_USERNAME + ':' + AUTH_PASSWORD);
        String authHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }
}