({
     fetchListOfRecordTypes: function(component, event, helper) {
        let recId = component.get("v.recordId");
        //console.log('record Id ' + recId);
        let action = component.get("c.fetchRecordTypeValuesPick");
        action.setParams({
            "objectName" : "Case",
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
        if(!$A.util.isEmpty(project)) {
            projectManager = project.Project_Manager__c;
            accountDirector= project.Account__r.ManagingDirector__c;
            deliveryAccountLead = project.Account__r.Delivery_Account_Lead__c;
            accountId = project.AccountId;
            if(selectedRecordTypeId != ""){
               let createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": 'Case',
                    "recordTypeId": selectedRecordTypeId,
                    "defaultFieldValues": {
                        "Project__c": component.get("v.recordId"),
                        "ProjectManager__c": projectManager,
                        "AccountId":accountId,
                        "Delivery_Account_Lead__c":deliveryAccountLead,
                        "Account_Director__c":accountDirector

                    }
                });
                createRecordEvent.fire();
               /*setTimeout(function() {
                    location.reload();
                }, 500);*/
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
    },
    callCaseFlow : function(component, event, helper){
        component.set('v.loaded', true);
        let recId = component.get("v.recordId");
        //console.log(' case flow record Id ' + recId);
        //console.log('record Id ' + recId);
        let recTypes =  component.get("v.caseRecordTypes");
        const result = recTypes.filter(recType => recType.Name === 'Lev Project Task');
        let recordTypeId;
        if(result.length === 1){
            recordTypeId = result[0].Id;
        }
        let projectName;
        let project = component.get("v.proj");
        if(!$A.util.isEmpty(project)) {
            projectName = project.Name;
        }
        let action = component.get("c.callCampaignFlow");
        action.setParams({
            "projectId" :  recId,
            "recordTypeId": recordTypeId,
            "contactId" :  component.get("v.contactId"),
            "projectName" : projectName 

        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            component.set('v.loaded', false);
            let toastEvent = $A.get("e.force:showToast");
            if (state === "SUCCESS") {
                let resp = response.getReturnValue();                
                if(!$A.util.isEmpty(resp)) {
                    toastEvent.setParams({
                        "title": "Error!",
                        "message":  resp,
                        "type": "Error"
                    });
                    toastEvent.fire();   
                }else{
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The cases have been created successfully.",
                        "type": "Success"
                    });
                    toastEvent.fire();
                    this.closeModal(component,event);
                }
               
            }else{
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Error creating cases.",
                    "type": "Error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    callAutoWorkFlow : function (component, event, helper) {
        component.set('v.loaded', true);
        if (component.get("v.proj").Project_Manager__c) {
        	const flow = component.find("autoWorkFlow");
            const inputVariables = [
                {
                    name: "Project",
                    type: "SObject",
                    value: component.get("v.proj")
                }
            ];
            flow.startFlow("Campaign_Services_Milestone_and_Work_Auto_Creation", inputVariables);   
        } else {
            const toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message":  "Project Manager is required before creating Milestones and Work records. Please enter a Project Manager on the Project record.",
                "type": "Error"
            });
            toastEvent.fire();
            helper.closeModal(component, event);
        }
    },
    handleAutoWorkFlowStatus : function (component, event, helper) {
        if (event.getParam("status") === "FINISHED_SCREEN") {
            const outputVariables = event.getParam("outputVariables");
            const toastEvent = $A.get("e.force:showToast");
            outputVariables.forEach(outputVar => {
                if (outputVar.name === "IsMilestoneCreated") {
                    if (outputVar.value) {
                    	toastEvent.setParams({
                            "title": "Success!",
                            "message": "Milestone and Work Items have been created successfully.",
                            "type": "Success"
                        });
                        toastEvent.fire();
                    } else {
                        toastEvent.setParams({
                            "title": "Error!",
                            "message":  "There was a problem creating Milestone and Work records. Please contact your administrator.",
                            "type": "Error"
                        });
                        toastEvent.fire();
                    }
            	}
            });
			helper.closeModal(component, event);
			component.set('v.loaded', false);
        } else if (event.getParam("status") === "ERROR") {
            const toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message":  "There was a problem creating Milestone and Work records. Please contact your administrator.",
                "type": "Error"
            });
            toastEvent.fire();
            helper.closeModal(component, event);
            component.set('v.loaded', false);
        }
    }
})