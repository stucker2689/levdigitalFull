({
    fetchListOfRecordTypes: function(component, event, helper) {
       let recId = component.get("v.recordId");
       let action = component.get("c.fetchRecordTypeValuesPickChild");
       action.setParams({
           "projectId" :  recId,
            "type" :component.get("v.type")
       });
       action.setCallback(this, function(response) {
           let resp = response.getReturnValue();

           if(!$A.util.isEmpty(resp)) {
               if(!$A.util.isEmpty(resp.pickListOptions)) {
                   component.set("v.lstOfRecordType", resp.pickListOptions);
                   if (resp.pickListOptions.length > 0) {
                       component.set('v.recordTypePickListValue',resp.pickListOptions[0].value);                       
                   }
               }
               if(!$A.util.isEmpty(resp.proj)) {
                   component.set("v.proj",resp.proj);
               } 
               if(!$A.util.isEmpty(resp.projectManagerID)){
                   component.set("v.contactId",resp.projectManagerID);
               }    
               if(!$A.util.isEmpty(resp.caseRecordTypes)){
                   component.set("v.caseRecordTypes",resp.caseRecordTypes);                   
               }
               if(!$A.util.isEmpty(resp.objectName)){
                component.set("v.objectName",resp.objectName);       
               }
               if(!$A.util.isEmpty(resp.objectLabel)){
                component.set("v.objectLabel",resp.objectLabel);       
               }
           }
       });
       $A.enqueueAction(action);
   },
   createRecord: function(component, event, helper, sObjectRecord) {
       let selectedRecordTypeId = component.get('v.recordTypePickListValue');
       let projectManager;
       let accountId;
       let deliveryAccountLead;
       let accountDirector;
       let project = component.get("v.proj");
       let objectName = component.get("v.objectName");
       if(!$A.util.isEmpty(project)) {
           projectManager = project.Project_Manager__c;
           accountDirector= project.Account__r.ManagingDirector__c;
           deliveryAccountLead = project.Account__r.Delivery_Account_Lead__c;
           accountId = project.AccountId;
           if(selectedRecordTypeId != ""){
                let createRecordEvent = $A.get("e.force:createRecord");
                let defaultFields = {};
                if(component.get("v.objectName") ==='Work__c'){
                    defaultFields = {
                        "lkp_Project__c": component.get("v.recordId")                   
                    }  
                }else{
                   defaultFields = {
                    "Project__c": component.get("v.recordId")                   
                    }   
                }
                createRecordEvent.setParams({
                    "entityApiName":  objectName,
                    "recordTypeId": selectedRecordTypeId,
                    "defaultFieldValues": defaultFields
                });
               
               createRecordEvent.fire();              
           }
       }
   },
   closeModal : function(component, event, helper){
       $A.get("e.force:closeQuickAction").fire();
   },
   getRecordTypePickListValue: function (component, event, helper) {
       let idx = event.target;
       if (event != null && ! $A.util.isEmpty(event) && idx != null) {
           let val = event.target.value;
           component.set('v.recordTypePickListValue', val);
       }
   }
   
})