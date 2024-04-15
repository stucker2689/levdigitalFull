@isTest
public class SetupTestDataFactory {
    

    public static Opportunity createParentOpportunity(Boolean isInsert, Id acctId) {
        Id recordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp123';
        opp.StageName = 'Identifying an Opportunity';
        opp.AccountId = acctId;
        opp.RecordTypeId = recordTypeId;
        opp.CloseDate = System.today().addDays(7);
        opp.Start_Date__c = System.today().addDays(-7);
        opp.End_Date__c = System.today().addDays(7);
        opp.Do_Not_Create_Project__c = true;
        opp.Service__c = 'Program';
        opp.Program_Type__c = 'Campaign';
        opp.Interested_In__c = 'Salesforce';
        opp.Change_Order_Revenue__c = 1000;
        opp.Total_Amount_Invoiced_to_Date__c = 100;
        opp.Payment_Terms__c = 'Time and Materials';
        opp.Payment_Schedule__c = 'Standard T&M Monthly';
        opp.Project_Terms__c = 'Time and Materials';
        opp.Date_SOW_Signed__c = Date.valueOf('2020-03-25');  
        opp.SOW_Hyperlink__c = 'google.com';
        opp.Next_Steps__c = 'Take the next steps on the opportunity';
        opp.Signatures_Completed__c = true;
        opp.Opportunity_Accuracy_Validated__c = true;
        opp.Team_Retirement__c = 'Allyson Reagan';
        opp.Existing_or_New_Business__c = 'Existing Business - Salesforce';
        opp.Existing_Business_Type__c = 'Existing Business - BU Expansion';
        opp.RFP_Proposal__c = 'Yes';
        opp.DeliveryMethodology__c = 'Agile';
        opp.Number_of_Products__c = 1;
        opp.Number_of_Contact_Rolls_Added__c = 1;
        opp.Forecast_Status__c = 'Most Likely';
        opp.Onboarding_Requirements__c = 'Onboarding Requirements here!';
        opp.SOW_Signed__c = 'Yes';

        if (isInsert){
             insert opp;
        }
        return opp;
    }

/*
    public static OpportunityLineItem createOpportunityLineItemWithPriceBookEntries(Id opptyId, String productName ){

        Product2 prod = new Product2(Name = productName);
        insert product;

        PricebookEntry developerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = developerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry mcSolutionArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = mcSolutionArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry projectManagerPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = projectManagerProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        PricebookEntry coreTechnicalArchitectPriceBookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = coreTechnicalArchitectProduct.Id, UnitPrice = 100, UseStandardPrice = false, IsActive = true);
        List<PricebookEntry> testPriceBookEntryList = new List<PricebookEntry>{developerPriceBookEntry, mcSolutionArchitectPriceBookEntry, projectManagerPriceBookEntry, coreTechnicalArchitectPriceBookEntry};
        insert testPriceBookEntryList;

        OpportunityLineItem developerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = developerPriceBookEntry.Id, Quantity = 10, UnitPrice = 100, Resource_Delivery_Group__c = 'ATG');
        OpportunityLineItem mcSolutionArchitectOppty1OpportunityLineItem= new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = mcSolutionArchitectPriceBookEntry.Id, Quantity = 15, UnitPrice = 150, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem projectManagerOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 
        OpportunityLineItem coreTechnicalArchitectOppty1OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = coreTechnicalArchitectPriceBookEntry.Id, Quantity = 25, UnitPrice = 250, Resource_Delivery_Group__c = 'Lev - UK'); 
        OpportunityLineItem projectManagerOppty2OpportunityLineItem = new OpportunityLineItem(OpportunityId = testOppty1.Id, PricebookEntryId = projectManagerPriceBookEntry.Id, Quantity = 20, UnitPrice = 200, Resource_Delivery_Group__c = 'Lev - NA'); 

        List<OpportunityLineItem> testOpportunityLineItemList = new List<OpportunityLineItem>{projectManagerOppty1OpportunityLineItem, mcSolutionArchitectOppty1OpportunityLineItem};
        insert testOpportunityLineItemList;
    }

    public class opportunityLineItem{

    }*/

    public static Client_Contact__c createInternalProjectTeamMember(Boolean isInsert, Id projectId, Id contactId, Id billingRateId, String contactRole, Boolean isPlaceholder){

        Client_Contact__c projTeamMember = new Client_Contact__c();
        projTeamMember.Project__c = projectId;
        projTeamMember.Client_Contact__c = contactId;
        projTeamMember.Is_Placeholder_Team_Member__c = isPlaceholder == null ? false : isPlaceholder;
        projTeamMember.Assigned_Billing_Rate__c = billingRateId == null ? null : billingRateId;
        projTeamMember.Contact_Role__c = contactRole == null ? null : contactRole;

        if(isInsert){
            insert projTeamMember;
        }
     
        return projTeamMember;

    }

    public static Project_Team_Member_Billing_Rate__c createProjectBillingRate(Boolean isInsert, Id projectId, String billRateName, Decimal hourlyRate){
        Project_Team_Member_Billing_Rate__c testBillRate = new Project_Team_Member_Billing_Rate__c();
        testBillRate.Name = billRateName == null ? 'Test Bill Rate' : billRateName;
        testBillRate.Hourly_Rate__c = hourlyRate == null ? 200 : hourlyRate;
        testBillRate.Project__c = projectId;
        testBillRate.Created_in_Salesforce__c = true;

        if (isInsert) {
            insert testBillRate;
        }
        return testBillRate;
    }


}