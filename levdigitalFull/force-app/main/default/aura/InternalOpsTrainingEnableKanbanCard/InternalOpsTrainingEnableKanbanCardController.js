({
    doInit : function(component, event, helper){
        let stopper = false;
        let record = component.get('v.rec');
        let parsedRecord = JSON.parse(JSON.stringify(record));
        component.set('v.rec', parsedRecord);         
        let sprintView = component.get('v.SprintView'); 
        let ownerColor;       
        let ownerInitials;
        let ownerInitialsSplit;
        if(parsedRecord.hasOwnProperty('Owner')){
            if(parsedRecord.Owner["Name"] == 'Lev - HelpDesk' || parsedRecord.Owner["Name"] == 'Lev - Training & Enablement'){
                ownerColor = '#b2beb5';
            }else{
                ownerColor = helper.getColorFromText(helper.reverseString(parsedRecord.Owner["Name"]));
            }
            component.set('v.OwnerColor', ownerColor);
            ownerInitialsSplit = parsedRecord.Owner["Name"].split(' ');
            ownerInitials = ownerInitialsSplit[0].substring(0, 1) + ownerInitialsSplit[1].substring(0, 1);
            component.set('v.ContactInitials', ownerInitials);
        }
        if(!sprintView){  
            if(parsedRecord.hasOwnProperty('SprintWeeks')){
                let sprintWeeksList = [];
                let sprintWeek;
                let sprintWeeksSplit;
                if(parsedRecord.SprintWeeks){
                    sprintWeeksSplit = parsedRecord.SprintWeeks.split(';');  
                    let hasOctFourth = false;
                    let indexOfTenth;
                    let indexOFEleventh;
                    let hasOctEleventh = false;

                    /** Start of logic to show ALL sprint weeks */
                    for(sprintWeek of sprintWeeksSplit){
                        let sprintWeekObj = new Object();
                        sprintWeekObj.color =  helper.getDistanceFromToday(sprintWeek);
                        sprintWeekObj.sprintWeekName = sprintWeek.substring(0, sprintWeek.lastIndexOf('/'));
                        sprintWeeksList.push(sprintWeekObj);

                        /** 10/4 Bug fix **/
                        if(sprintWeekObj.sprintWeekName == '10/4'){
                            hasOctFourth = true
                            indexOfTenth = sprintWeeksList.length - 1;
                        }
                        if(sprintWeekObj.sprintWeekName == '10/11'){
                            hasOctEleventh = true
                            indexOFEleventh = sprintWeeksList.length - 1;
                        }
                        /** 10/4 Bug fix **/

                    }                    
                    /** End of logic to show ALL sprint weeks */

                    /** Start of logic to fix the 10/4 showing up in the wrong order bug */
                    if(hasOctFourth && hasOctEleventh ){
                        sprintWeeksList = helper.moveItemInArray(sprintWeeksList, indexOfTenth, indexOFEleventh);
                    }

                    /** End of logic to fix the 10/4 showing up in the wrong order bug */
                    component.set('v.numberOfIndexesInSprintWeeks', sprintWeeksList.length - 1);
                    component.set('v.sprintWeeks', sprintWeeksList);
                }
            }
            if(!component.get('v.IsOpsView')){
                if(parsedRecord.hasOwnProperty('RequirementsStatus')){
                    component.set('v.SprintViewSize', '11');    
                    if(parsedRecord.RequirementsStatus == 'Complete' || parsedRecord.RequirementsStatus == 'N/A'){
                        component.set('v.RequirementsIconColor', 'green');
                        component.set('v.RequirementIcon', 'utility:check');
                    }else if(parsedRecord.RequirementsStatus == 'In Progress'){
                        component.set('v.RequirementsIconColor', 'yellow');
                        component.set('v.RequirementIcon', 'utility:retweet');
                    }else{
                        component.set('v.RequirementsIconColor', 'red');
                        component.set('v.RequirementIcon', 'utility:close');
                    }
                }else{
                    component.set('v.SprintViewSize', '11');   
                    component.set('v.RequirementsIconColor', 'red');
                    component.set('v.RequirementIcon', 'utility:close');
                }
                //Set isInProgress status boolean for QA Status display
                if(parsedRecord.hasOwnProperty('Status')){
                    if(parsedRecord.Status == 'In Process'){

                        if(parsedRecord.QaStatus == 'Work in Progress'){
                            component.set('v.QaStatusColor', 'red');
                        }else if(parsedRecord.QaStatus == 'Ready for QA'){
                            //component.set('v.QaStatusColor', 'rgb(255, 185, 0)');
                            component.set('v.QaStatusColor', 'rgb(255, 140, 0)');
                        }else if(parsedRecord.QaStatus == 'Feedback from QA'){
                            //component.set('v.QaStatusColor', 'rgb(255, 238, 49)');
                            component.set('v.QaStatusColor', 'gold');
                        }else if(parsedRecord.QaStatus == 'Passed QA'){
                            component.set('v.QaStatusColor', 'green');
                        }else if(parsedRecord.QaStatus == 'N/A'){
                            component.set('v.QaStatusColor', 'grey');
                        }
                        
                        component.set('v.isInProgressStatus', true);
                    }
                }
            }else{
                component.set('v.SprintViewSize', '11');
            }
        }else{
            if(!component.get('v.IsOpsView')){
                if(parsedRecord.hasOwnProperty('RequirementsStatus')){
                    component.set('v.SprintViewSize', '10');    
                    if(parsedRecord.RequirementsStatus == 'Complete' || parsedRecord.RequirementsStatus == 'N/A'){
                        component.set('v.RequirementsIconColor', 'green');
                        component.set('v.RequirementIcon', 'utility:check');
                    }else if(parsedRecord.RequirementsStatus == 'In Progress'){
                        component.set('v.RequirementsIconColor', 'yellow');
                        component.set('v.RequirementIcon', 'utility:retweet');
                    }else{
                        component.set('v.RequirementsIconColor', 'red');
                        component.set('v.RequirementIcon', 'utility:close');
                    }
                }else{
                    component.set('v.SprintViewSize', '10');   
                    component.set('v.RequirementsIconColor', 'red');
                    component.set('v.RequirementIcon', 'utility:close');
                }
                //Set isInProgress status boolean for QA Status display
                if(parsedRecord.hasOwnProperty('Status')){
                    if(parsedRecord.Status == 'In Process'){

                        if(parsedRecord.QaStatus == 'Work in Progress'){
                            component.set('v.QaStatusColor', 'red');
                        }else if(parsedRecord.QaStatus == 'Ready for QA'){
                            component.set('v.QaStatusColor', 'rgb(255, 140, 0)');
                        }else if(parsedRecord.QaStatus == 'Feedback from QA'){
                            //component.set('v.QaStatusColor', 'rgb(255, 238, 49)');
                            component.set('v.QaStatusColor', 'gold');
                        }else if(parsedRecord.QaStatus == 'Passed QA'){
                            component.set('v.QaStatusColor', 'green');
                        }else if(parsedRecord.QaStatus == 'N/A'){
                            component.set('v.QaStatusColor', 'grey');
                        }
                        
                        component.set('v.isInProgressStatus', true);
                    }
                }
            }
            component.set('v.SprintViewSize', '11');            
        }
    },

    getSprintWeeks: function(component, event, helper){

    },

    navToRec : function(component, event, helper) {
        let record = component.get('v.rec');
        let recId = record.CaseId;
        if(recId && recId != ''){
            window.open('/' + recId);
        }
    },
    recActionSelected : function(component, event, helper) {
        let cardPosition = component.get('v.recPos');
        let label = event.getParam("value");
        let record = component.get('v.rec');
        if(label == "Edit"){
            let editEvt = component.getEvent("editRecordSelected");
            editEvt.setParams({
                "RecordToEdit" : record,
                "KanbanRecordPosition": cardPosition
            });
            editEvt.fire();

            let highlightCase = $A.get("e.c:highlightEditCase");
            highlightCase.setParams({
                "RecordToEdit" : record
            });
            highlightCase.fire();
            let elem = component.find('KanbanCard');
            //let elem = component.find('KanbanHeader');
        	$A.util.addClass(elem,'newCardColor');

        }else if(label == 'EditCaseOwner'){
            let editEvt = component.getEvent("editCaseOwner");
            editEvt.setParams({
                "RecordToEdit" : record,
                "KanbanRecordPosition": cardPosition
            });
            editEvt.fire();
        }else if(label == 'ChangeQAStatus'){
            let editEvt = component.getEvent("editCaseQAStatus");
            editEvt.setParams({
                "RecordToEdit" : record,
                "KanbanRecordPosition": cardPosition
            });
            editEvt.fire();
        }else if(label == 'EditCaseStatus'){
            let editEvt = component.getEvent("editKanbanCaseStatus");
            editEvt.setParams({
                "RecordToEdit" : record,
                "KanbanRecordPosition": cardPosition
            });
            editEvt.fire();
        }
    },

    handleEditRecord : function(component, event, helper){
        let selectedRecordToEdit = event.getParam('RecordToEdit');
        let editViewisClosed = event.getParam('editViewClosed');
        let record = component.get('v.rec');
        let recId = record.CaseId;
        let editRecId = selectedRecordToEdit ? selectedRecordToEdit.CaseId : '0000000000';
        if(editRecId != recId || editViewisClosed == true){            
            let elem = component.find('KanbanCard');
            //let elem = component.find('KanbanHeader');
            $A.util.removeClass(elem,'newCardColor');
        }
    },
})