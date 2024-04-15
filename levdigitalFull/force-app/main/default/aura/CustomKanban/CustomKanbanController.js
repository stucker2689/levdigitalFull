({

    handleRefresh: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    doInit : function(component, event, helper) {
        let todaysDate = new Date();
        let days = 86400000; //number of milliseconds in a day
        let today = helper.formatDate(new Date(todaysDate - (7*days)));
        let defaultToDate = helper.formatDate(new Date(todaysDate - (-15*days))); //Add days with miliseconds
        component.set('v.fromDate', today);
        component.set('v.toDate', defaultToDate);
        component.set('v.defaultFromDate', today);
        component.set('v.defaultToDate', defaultToDate);
        helper.changeViewHelper(component, event, helper, 'Status Kanban');

    },

    getFromDate : function(component, event, helper){   
        //component.set('v.openRecordEdit', false);    
        let selectedView = component.get('v.KanbanViewSelected');
        helper.filterDates(component, event, selectedView);
    },

    getToDate : function(component, event, helper){
        //component.set('v.openRecordEdit', false);
        let selectedView = component.get('v.KanbanViewSelected');
        helper.filterDates(component, event, selectedView);
    },

    handleCaseOwnerFilter : function(component,event, helper){
        //component.set('v.openRecordEdit', false);
        helper.filterRecords(component, event);
    },

    handleCaseStatusFilter : function(component, event, helper){
        //component.set('v.openRecordEdit', false);
        let selectedView = component.get('v.KanbanViewSelected');
        helper.filterStatus(component, event, selectedView);
    },
    handleCaseDepartmentFilter : function(component,event, helper){
        //component.set('v.openRecordEdit', false);
        helper.filterRecords(component, event);
    },

    clearFilters : function(component, event, helper){
        //component.set('v.openRecordEdit', false);
        let selectedView = component.get('v.KanbanViewSelected');
        helper.changeViewHelper(component, event, helper, selectedView);
    },

    changeView : function(component, event, helper){
        component.set('v.openRecordEdit', false);
        component.set('v.kanbanBodyWidth', 'slds-size_3-of-3');
        helper.changeViewHelper(component, event, helper, null);
    },

    childChanged : function(component, event, helper) {
        //This event sends whole object that is being changed
        let selectedView = component.get('v.KanbanViewSelected');
        if(selectedView == 'Status Kanban'){
            let data = event.getParam('KanbanChildChange');
            if(data.from != data.to){
                let records = component.get('v.KanbanRecords');
                let recordsBackup = component.get('v.KanbanRecordsBackup');
                let recordToUpdate = records[data.from][data.pos];
                let recordToUpdateBackup = recordsBackup[data.from][data.pos];
                let nameInToast = recordToUpdate.Subject;
                
                //Update Kanban Records that are displayed
                recordToUpdate["Status"] = data.to;
                recordToUpdate["ColumnHeader"] = data.to;
                if(!records[data.to]){
                    let emptyColumnToUpdate = [];
                    emptyColumnToUpdate.push(recordToUpdate);
                    records[data.to] = emptyColumnToUpdate;
                }else{
                    try{
                        records[data.to].unshift(recordToUpdate);
                    }catch(error){
                        console.error(error);
                    }
                }
                if(data.to == 'In Process'){
                    if(recordToUpdate["QaStatus"] != 'N/A'){
                        recordToUpdate["QaStatus"] = 'Work in Progress';
                    }
                    let currentMondaySprintWeek = helper.getCurrentMondaySprintWeek();
                    if(!recordToUpdate["SprintWeeks"]){
                        //editedRec.SprintWeeks = currentMonday;
                        if(recordToUpdate.DueDate){
                            console.log('Due Date Exists');
                            recordToUpdate.StartDate = currentMondaySprintWeek;
                            recordToUpdate.SprintWeeks = helper.createSprintWeeks(currentMondaySprintWeek, recordToUpdate.DueDate);
                        }else{
                            console.log('Due Date DOESNT Exists');
                            recordToUpdate.StartDate = currentMondaySprintWeek;
                            recordToUpdate["SprintWeeks"] = currentMondaySprintWeek;
                        }
                    }else{
                        if(recordToUpdate.DueDate){
                            console.log('Sprint Weeks & Due Date Exists');
                            recordToUpdate.StartDate = currentMondaySprintWeek;
                            recordToUpdate.SprintWeeks = helper.createSprintWeeks(currentMondaySprintWeek, recordToUpdate.DueDate);
                        }else{
                            console.log('Sprint Weeks & Due Date DOESNT Exists');
                            recordToUpdate.StartDate = currentMondaySprintWeek;
                            recordToUpdate["SprintWeeks"] = currentMondaySprintWeek;
                        }
                    }
                    records[data.to].sort(function(a, b){
                        return a.diffFromTodayToDueDate - b.diffFromTodayToDueDate
                    });
                }else{
                    records[data.to].sort(function(a, b){
                        return new Date(a.SubmittedDate) - new Date(b.SubmittedDate)
                    });
                }
                records[data.from].splice(data.pos, 1);
                component.set('v.KanbanRecords',records);

                //Update Kanban Record Backups         
                recordToUpdateBackup["Status"] = data.to;
                recordToUpdateBackup["ColumnHeader"] = data.to;
                if(!recordsBackup[data.to]){
                    let emptyColumnToUpdateBackup = [];
                    emptyColumnToUpdateBackup.push(recordToUpdateBackup);
                    recordsBackup[data.to] = emptyColumnToUpdateBackup;
                }else{
                    try{
                        recordsBackup[data.to].unshift(recordToUpdateBackup);
                    }catch(error){
                        console.error(error);
                    }
                }
                if(data.to == 'In Process'){
                    if(recordToUpdateBackup["QaStatus"] != 'N/A'){
                        recordToUpdateBackup["QaStatus"] = 'Work in Progress';
                    }
                    recordsBackup[data.to].sort(function(a, b){
                        return a.diffFromTodayToDueDate - b.diffFromTodayToDueDate
                    });
                }else{
                    recordsBackup[data.to].sort(function(a, b){
                        return new Date(a.SubmittedDate) - new Date(b.SubmittedDate)
                    });
                }
                recordsBackup[data.from].splice(data.pos, 1);
                component.set('v.KanbanRecordsBackup',recordsBackup);

                let toastEvent = $A.get("e.force:showToast");
                let action = component.get('c.updateRec');
                action.setParams({
                    'recordId' : recordToUpdate.CaseId,
                    'recordField' : 'Status',
                    'newValue' : data.to
                });
                action.setCallback(this, function(res){
                    //helper.spinnerHelper(component, false);
                    if(res.getState() === 'SUCCESS' && res.getReturnValue() === 'true'){
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : "success",
                            "duration" : 400,
                            "message": nameInToast+' moved to '+ data.to
                        });
                        toastEvent.fire();
                    }else{
                        let em = 'An Unknown Error Occured';
                        if(res.getState() === 'SUCCESS' && res.getReturnValue() != 'true'){
                            em = res.getReturnValue();
                        }else if(res.getState() === 'ERROR'){
                            let errors = res.getError();
                            if (errors) {
                                if (errors[0] && errors[0].message) {
                                    em = errors[0].message;
                                }
                            } else {
                                em = 'An Unknown Error Occured';
                            }
                        }
                        toastEvent.setParams({
                            "title": "Error",
                            "type" : "error",
                            "duration" : 400,
                            "message": em
                        });
                        toastEvent.fire();
                        let record = records[data.to][0];
                        record["Status"] = data.from;
                        records[data.to].splice(0, 1);
                        records[data.from].splice(data.pos, 0, record);
                        component.set('v.KanbanRecords',records);
                    }
                });
                $A.enqueueAction(action);
            }
        }else{
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot move Cards on this View",
                "type": 'error'
            });
            toastEvent.fire();
        }
    },
    initiateNewRecordCreation : function(component, event, helper) {
        let recordTypeId = component.get('v.recordTypeIdForNew');
        if(recordTypeId){
            let createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": 'Case',
                "recordTypeId": recordTypeId
            });
            createRecordEvent.fire();
        }
    },

    handleEditRecord : function(component, event, helper){
        let recordToEdit = event.getParam('RecordToEdit');
        let recordToEditPos = event.getParam('KanbanRecordPosition');
        component.set('v.editRecord', recordToEdit);
        component.set('v.editRecordPosition', recordToEditPos);
        component.set('v.openRecordEdit', true);
        component.set('v.kanbanBodyWidth', 'slds-size_2-of-3');
    },
    submitEditForm : function(component,event, helper){
        component.find("recordEditForm").submit();
        component.set('v.editRecordLoading', true);
    },
    onEditRecordLoad : function(component, event, helper){
        component.set('v.editRecordLoading', false);
    },
    onEditRecordSuccess : function(component, event, helper){
        let parsedEvent = JSON.parse(JSON.stringify(event));
        console.log('EVENT: ', parsedEvent);

        /**Changed from RecordForm to Record Edit Form and moved submit button to outside the form **/
        helper.handleEditRecordOnKanban(component, event, parsedEvent._params.response.fields.Internal_Ops_Estimated_Hours__c.value, 
                                                            parsedEvent._params.response.fields.Due_Date_Internal__c.value, 
                                                            parsedEvent._params.response.fields.Start_Date__c.value,
                                                            parsedEvent._params.response.fields.Primary_Department__c.value, 
                                                            parsedEvent._params.response.fields.Sprint_Week__c.value, 
                                                            parsedEvent._params.response.fields.Status.value,
                                                            parsedEvent._params.response.fields.Requirements_Status__c.value,
                                                            parsedEvent._params.response.fields.QA_Status__c.value,
                                                            parsedEvent._params.response.fields.QA_Owner__c.value,
                                                            parsedEvent._params.response.fields.QA_Owner__r.displayValue,
                                                            parsedEvent._params.response.fields.Estimated_QA_Hours__c.value);
        component.set('v.editRecordLoading', true);
        component.set('v.openRecordEdit', false);
        component.set('v.kanbanBodyWidth', 'slds-size_3-of-3');
    },
    closeEditRecord : function(component, event, helper){
        let highlightCase = $A.get("e.c:highlightEditCase");
        highlightCase.setParams({
            "editViewClosed" : true
        });
        highlightCase.fire();
        component.set('v.editRecordLoading', true);
        component.set('v.openRecordEdit', false);
        component.set('v.kanbanBodyWidth', 'slds-size_3-of-3');
    },

    /** Edit Case Owner Controller Functions **/
    handleEditCaseOwner : function(component, event){
        let recordOwnerToEdit = event.getParam('RecordToEdit');
        let recordOwnerToEditPos = event.getParam('KanbanRecordPosition');
        component.set('v.editCaseOwnerRecord', recordOwnerToEdit);
        component.set('v.editCaseOwnerRecordPosition', recordOwnerToEditPos);
        component.set('v.editCaseOwnerIsOpen', true);
    },
    closeModel : function(component){
        component.set('v.editCaseOwnerIsOpen', false);
        component.set('v.editQAStatusIsOpen', false);
        component.set('v.editCaseStatusIsOpen', false);
        component.set('v.editQAOwnerIsOpen', false);
    },
    handleEditCaseOwnerSuccess : function(component, event, helper){
        let editedRec = component.get('v.editCaseOwnerRecord');
        let parsedEvent = JSON.parse(JSON.stringify(event));
        console.log('handleEditCaseOwnerSuccess Parsed Event: ', parsedEvent);
        let newName;
        let newOwnerId; 
        for(let prop in parsedEvent){
            if(Object.hasOwn(parsedEvent[prop], 'fields')){
                newName =  parsedEvent[prop].fields.Owner.displayValue;
                newOwnerId = parsedEvent[prop].fields.Owner.value.id;
                break;
            }
        }
        helper.handleEditCaseOwnerEditOnKanban(component, newName, newOwnerId);
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": editedRec.Subject + " has been updated successfully.",
            "type": 'Success'
        });
        toastEvent.fire();
        component.set('v.editCaseOwnerIsOpen', false);
    },

    /** Edit QA Status Controller Functions **/
    handleEditCaseQAStatus : function(component, event){
        let recordQAStatusToEdit = event.getParam('RecordToEdit');
        let recordQAStatusToEditPos = event.getParam('KanbanRecordPosition');
        component.set('v.editQAStatusRecord', recordQAStatusToEdit);
        component.set('v.editQAStatusRecordPosition', recordQAStatusToEditPos);
        component.set('v.editQAStatusIsOpen', true);
    },
    handleEditQAStatusSuccess : function(component, event, helper){
        let editedRec = component.get('v.editQAStatusRecord');
        let parsedEvent = JSON.parse(JSON.stringify(event));
        console.log('handleEditQAStatusSuccess Parsed Event: ', parsedEvent)
        /***** Made Dynamic way to handle these fields FINALLY *****/
        let newName;
        let newOwnerId;
        let newQAStatus;
        
        for(let prop in parsedEvent){
            if(Object.hasOwn(parsedEvent[prop], 'fields')){
                newName =  parsedEvent[prop].fields.Owner.displayValue;
                newOwnerId = parsedEvent[prop].fields.Owner.value.id;
                newQAStatus =  parsedEvent[prop].fields.QA_Status__c.displayValue;
                break;
            }
        }

        helper.handleEditQAStatusEditOnKanban(component, newQAStatus);
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": editedRec.Subject + " has been updated successfully.",
            "type": 'Success'
        });
        toastEvent.fire();
        component.set('v.editQAStatusIsOpen', false);
    },

    /*** Edit Case Status from Dropdown button 12/29/21***/
    handleEditCaseStatus : function(component, event){
    let recordOwnerToEdit = event.getParam('RecordToEdit');
        let recordOwnerToEditPos = event.getParam('KanbanRecordPosition');
        component.set('v.editCaseStatusRecord', recordOwnerToEdit);
        component.set('v.editCaseStatusRecordPosition', recordOwnerToEditPos);
        component.set('v.editCaseStatusIsOpen', true);
    },
    handleEditCaseStatusSuccess : function(component, event, helper){
        let editedRec = component.get('v.editCaseStatusRecord');
        let parsedEvent = JSON.parse(JSON.stringify(event));
        console.log('handleEditCaseStatusSuccess Parsed Event: ', parsedEvent)

        let newCaseStatus;
        for(let prop in parsedEvent){
            if(Object.hasOwn(parsedEvent[prop], 'fields')){
                newCaseStatus =  parsedEvent[prop].fields.Status.displayValue;
                break;
            }
        }


        helper.handleEditCaseOnKanban(component, newCaseStatus);
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": editedRec.Subject + " has been updated to " + newCaseStatus,
            "type": 'Success'
        });
        toastEvent.fire();
        component.set('v.editCaseStatusIsOpen', false);
    

    },
    /** Edit Case QA Owner Controller Functions **/
    handleEditQAOwner : function(component, event){
        let recordOwnerToEdit = event.getParam('RecordToEdit');
        let recordOwnerToEditPos = event.getParam('KanbanRecordPosition');
        component.set('v.editQAOwnerRecord', recordOwnerToEdit);
        component.set('v.editQAOwnerRecordPosition', recordOwnerToEditPos);
        component.set('v.editQAOwnerIsOpen', true);
    },

    handleEditQAOwnerSuccess : function(component, event, helper){
        let editedRec = component.get('v.editQAOwnerRecord');
        let parsedEvent = JSON.parse(JSON.stringify(event));
        console.log('handleEditQAOwnerSuccess Parsed Event: ', parsedEvent);
        let newQAOwnerName;
        let newQAOwnerId;
        for(let prop in parsedEvent){
            if(Object.hasOwn(parsedEvent[prop], 'fields')){
                newQAOwnerName =  parsedEvent[prop].fields.QA_Owner__r.displayValue;
                newQAOwnerId = parsedEvent[prop].fields.QA_Owner__c.value;
                break;
            }
        }

        helper.handleEditQAOwnerEditOnKanban(component, newQAOwnerName, newQAOwnerId);
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": editedRec.Subject + " has been updated successfully.",
            "type": 'Success'
        });
        toastEvent.fire();
        component.set('v.editQAOwnerIsOpen', false);
    },

})