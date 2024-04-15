/**
* @author LevDigital
* @date 2019
*
* @group Opportunities
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description CreateNewCOController - Controller for CreateNewCO for Lightning component
*/

public with sharing class CreateNewCOController {

    /*******************************************************************************************************
    * @description Gets Id of the change Order RecordType for Lightning component
    * @return recordTypeId
    */
    @AuraEnabled(cacheable=true)
    public static ChangeOrder getChangeOrderRecordId(String opportunityId){
        ChangeOrder newCO = new ChangeOrder();
        if(String.isNotBlank(opportunityId)){            
            newCO.recordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Change_Order').getRecordTypeId();     
            Opportunity opp = [SELECT Id,AccountId, Project_Terms__c, Payment_Terms__c, Payment_Schedule__c  FROM Opportunity WHERE Id=:opportunityId][0];
            if(opp != null){
                if(String.isNotBlank(opp.AccountId)){
                    newCO.accountId = opp.AccountId;
                    newCO.projectTerms = opp.Project_Terms__c;
                    newCO.invoicePaymentTerms = opp.Payment_Terms__c;
                    newCO.invoiceSchedule = opp.Payment_Schedule__c;
                }
            }
        }
        return newCO;
    }
    public class ChangeOrder{
        @AuraEnabled
        public String accountId{get;set;}
        @AuraEnabled
        public String projectTerms{get;set;}
        @AuraEnabled
        public String invoicePaymentTerms{get;set;}
        @AuraEnabled
        public String invoiceSchedule{get;set;}
        @AuraEnabled
        public String recordTypeId{get;set;}
    }
}