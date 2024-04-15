({
    doInit : function(component, event, helper) {
        let action = component.get("c.getChangeOrderRecordId");  
        action.setParams({
            "opportunityId": component.get('v.recordId'),
        });  
        action.setCallback(this, function(response) {
            let resp = response.getReturnValue();
            if(!$A.util.isEmpty(resp)) {
                let createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": 'Opportunity',
                    "recordTypeId": resp.recordTypeId,
                    "defaultFieldValues": {
                        'Change_Orders__c' : component.get('v.recordId'),
                        'AccountId' :resp.accountId,
                        'Project_Terms__c': resp.projectTerms,
                        'Payment_Terms__c': resp.invoicePaymentTerms,
                        'Payment_Schedule__c': resp.invoiceSchedule
                    }
                });
                createRecordEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    }
})