({
    convertToKanBanObject : function(responseList, isSprintPlan, sprintPlanType){
        let kanBanObjList = [];
        if(isSprintPlan){
            for(let obj in responseList){
                let newObj = new Object();
                newObj.Id = responseList[obj].Id;
                newObj.SprintPlanName = responseList[obj].Name;
                newObj.CaseId = responseList[obj].Case__r.Id;
                newObj.CaseNumber = responseList[obj].Case__r.CaseNumber;
                newObj.Status = responseList[obj].Case__r.Status;
                newObj.Subject = responseList[obj].Case__r.Subject;
                newObj.SubmittedDate = responseList[obj].Case__r.CreatedDate;
                newObj.DaysCaseOpen = responseList[obj].Case__r.Days_Case_Open__c;
                newObj.Contact = responseList[obj].Case__r.Contact;
                newObj.ContactId = responseList[obj].Case__r.ContactId;
                newObj.Owner = responseList[obj].Case__r.Owner;
                newObj.OwnerId = responseList[obj].Case__r.OwnerId;
                if(responseList[obj].Case__r.QA_Owner__c){
                    newObj.QAOwnerId = responseList[obj].Case__r.QA_Owner__c; //Added 8/11 ST
                    newObj.QAOwner = responseList[obj].Case__r.QA_Owner__r.Name; //Added 8/11 ST
                }

                newObj.DueDate = responseList[obj].Case__r.Due_Date_Internal__c;
                newObj.sortDueDate = newObj.DueDate ? Number(new Date(newObj.DueDate)) : 999999999999900;
                newObj.diffFromTodayToDueDate = newObj.DueDate ? this.getDistanceFromToday(newObj.DueDate) : 100000;
                newObj.RequestType = responseList[obj].Case__r.Internal_Request_Type__c;
                newObj.SprintWeeks = responseList[obj].Case__r.Sprint_Week__c;
                newObj.SprintMonths = responseList[obj].Case__r.Sprint_Month__c;
                newObj.SprintQuarters = responseList[obj].Case__r.Sprint_Quarter__c;
                newObj.StartDate = responseList[obj].Case__r.Start_Date__c;
                newObj.PrimaryDepartment = responseList[obj].Case__r.Primary_Department__c;
                newObj.Type = responseList[obj].Case__r.Type;
                newObj.FullEstimatedHours = responseList[obj].Case__r.TotalEstimatedHours__c; //Change from Internal_Ops_Estimated_Hours__c to TotalEstimatedHours__c
                newObj.EstimatedConfigHours = responseList[obj].Case__r.Internal_Ops_Estimated_Hours__c;
                newObj.RequirementsStatus = responseList[obj].Case__r.Requirements_Status__c; //Not in Ops Kanban
                newObj.QaStatus = responseList[obj].Case__r.QA_Status__c; //Not in Ops Kanban
                newObj.DateRequirementsCompleted = responseList[obj].Case__r.Date_Requirements_Completed__c; //Not in Ops Kanban
                newObj.FullEstimatedQAHours = responseList[obj].Case__r.Estimated_QA_Hours__c;
                switch (sprintPlanType) {
                    case 'Sprint Week':
                        newObj.ColumnHeader = responseList[obj].Sprint_Week_Date__c;
                        newObj.EstimatedConfigHours = responseList[obj].Estimated_Hours_per_Week__c;
                        newObj.SprintDate = responseList[obj].Sprint_Week_Date__c;
                        newObj.EstimatedQAHours = responseList[obj].EstimatedQAHours__c ? responseList[obj].EstimatedQAHours__c : 0;
                        newObj.EstimatedHours = newObj.EstimatedConfigHours + newObj.EstimatedQAHours;
                        break;
                    case 'Sprint Month':
                        newObj.ColumnHeader = responseList[obj].Sprint_Month__c;
                        newObj.SprintDate = responseList[obj].Sprint_Month_Date__c;
                        newObj.EstimatedConfigHours = responseList[obj].Estimated_Hours_for_Month__c;
                        newObj.EstimatedQAHours = responseList[obj].EstimatedQAHours__c ? responseList[obj].EstimatedQAHours__c : 0;
                        newObj.EstimatedHours = newObj.EstimatedConfigHours + newObj.EstimatedQAHours;
                        break;
                    case 'Sprint Quarter':
                        newObj.ColumnHeader = responseList[obj].Sprint_Quarter__c;
                        newObj.SprintDate = responseList[obj].Sprint_Quarter__c;
                        newObj.EstimatedConfigHours = responseList[obj].Estimated_Hours_for_Quarter__c;
                        newObj.EstimatedQAHours = responseList[obj].EstimatedQAHours__c ? responseList[obj].EstimatedQAHours__c : 0;
                        newObj.EstimatedHours = newObj.EstimatedConfigHours + newObj.EstimatedQAHours;
                        break;
                }
                kanBanObjList.push(newObj);
            }
        }else{
            for(let obj in responseList){
                let newObj = new Object();
                newObj.CaseId = responseList[obj].Id;
                newObj.CaseNumber = responseList[obj].CaseNumber;
                newObj.Status = responseList[obj].Status;
                newObj.ColumnHeader = responseList[obj].Status;
                newObj.Subject = responseList[obj].Subject;
                newObj.SubmittedDate = responseList[obj].CreatedDate;
                newObj.DaysCaseOpen = responseList[obj].Days_Case_Open__c;
                newObj.Contact = responseList[obj].Contact;
                newObj.ContactId = responseList[obj].ContactId;
                newObj.Owner = responseList[obj].Owner;
                newObj.OwnerId = responseList[obj].OwnerId;
                if(responseList[obj].QA_Owner__c){
                    newObj.QAOwnerId = responseList[obj].QA_Owner__c; //Added 8/11 ST
                    newObj.QAOwner = responseList[obj].QA_Owner__r.Name; //Added 8/11 ST
                }
                newObj.EstimatedQAHours = responseList[obj].Estimated_QA_Hours__c ? responseList[obj].Estimated_QA_Hours__c : 0;

                newObj.DueDate = responseList[obj].Due_Date_Internal__c;
                newObj.sortDueDate = newObj.DueDate ? Number(new Date(newObj.DueDate)) : 0;
                newObj.diffFromTodayToDueDate = newObj.DueDate ? this.getDistanceFromToday(newObj.DueDate) : 100000;
                newObj.RequestType = responseList[obj].Internal_Request_Type__c;
                newObj.SprintWeeks = responseList[obj].Sprint_Week__c;
                newObj.SprintMonths = responseList[obj].Sprint_Month__c;
                newObj.SprintQuarters = responseList[obj].Sprint_Quarter__c;
                newObj.StartDate = responseList[obj].Start_Date__c;
                newObj.EstimatedHours = responseList[obj].TotalEstimatedHours__c; //Change from Internal_Ops_Estimated_Hours__c to TotalEstimatedHours__c
                newObj.EstimatedConfigHours = responseList[obj].Internal_Ops_Estimated_Hours__c;
                newObj.PrimaryDepartment = responseList[obj].Primary_Department__c;
                newObj.Type = responseList[obj].Type;
                newObj.RequirementsStatus = responseList[obj].Requirements_Status__c; //Not in Ops Kanban
                newObj.QaStatus = responseList[obj].QA_Status__c; //Not in Ops Kanban
                newObj.DateRequirementsCompleted = responseList[obj].Date_Requirements_Completed__c; //Not in Ops Kanban
                kanBanObjList.push(newObj);
            }
        }

        return kanBanObjList;
    },

    getDistanceFromToday : function(dueDate){
        let oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
        let todays = new Date();
        let dueDateWeek = new Date(dueDate);

        let diffDays = Math.round((dueDateWeek - todays) / oneDay);
        return diffDays;
    },

    setKanbanRecords : function(component, kanbanRecords, kanbanView){
        let sprintView = component.get('v.SprintView');
        let kanbanAllCaseRecords = {};
        let kanbanAllCaseRecordsMap = new Map();
        let kanbanAllCaseRollups = {};
        let kanbanAllCaseRecordsRollupMap = new Map();

        let allCaseOwnerList = [];
        let allCaseOwnerIdList = [];
        let allCaseOwnerNameList = [];
        let weekSprintPlanStatusList = [];
        let allCaseDeptList = [];

        let ownerIdToOwnerNameMap = new Map(); //Added 8.18.22 ST

        for(let kanbanObj of kanbanRecords){
            const exists = allCaseOwnerList.some(el => el.Name === kanbanObj.Owner["Name"]);
            if(!exists){
                allCaseOwnerList.push(kanbanObj.Owner);
                allCaseOwnerIdList.push(kanbanObj.OwnerId);
                allCaseOwnerNameList.push(kanbanObj.Owner["Name"]);

                ownerIdToOwnerNameMap.set(kanbanObj.OwnerId, kanbanObj.Owner["Name"]); //Added 8.18.22 ST
            }
            //Added 8.19.22 ST To also add QA Owners to the Owner Filter selection list
            if(kanbanObj.QAOwner != null){
                const qaOwnerExists = allCaseOwnerList.some(el => el.Name === kanbanObj.QAOwner);
                if(!qaOwnerExists){
                    let Owner = new Object();
                    Owner.Id = kanbanObj.QAOwnerId;
                    Owner.Name = kanbanObj.QAOwner;
                    allCaseOwnerList.push(Owner);
                    allCaseOwnerIdList.push(kanbanObj.QAOwnerId);
                    allCaseOwnerNameList.push(kanbanObj.QAOwner);

                    ownerIdToOwnerNameMap.set(kanbanObj.QAOwnerId, kanbanObj.QAOwner); //Added 8.18.22 ST
                }
            }


            if(!weekSprintPlanStatusList.includes(kanbanObj.Status)){
                weekSprintPlanStatusList.push(kanbanObj.Status);
            }
            if(kanbanObj.PrimaryDepartment != null && !allCaseDeptList.includes(kanbanObj.PrimaryDepartment)){
                allCaseDeptList.push(kanbanObj.PrimaryDepartment);
            }
            //Check if key has already been created
            if(kanbanAllCaseRecordsMap.has(kanbanObj.ColumnHeader)){
                //If key is already in map then add the object to the list for the key
                let addToList = [];
                addToList = kanbanAllCaseRecordsMap.get(kanbanObj.ColumnHeader);
                addToList.push(kanbanObj);
                kanbanAllCaseRecordsMap.set(kanbanObj.ColumnHeader, addToList);
                //Add to Rollup Map
                    let rollupValue = kanbanAllCaseRecordsRollupMap.get(kanbanObj.ColumnHeader) + (kanbanObj.EstimatedConfigHours ? Math.round(kanbanObj.EstimatedConfigHours) : 0);
                    kanbanAllCaseRecordsRollupMap.set(kanbanObj.ColumnHeader, rollupValue);
            }else{
                //Create map and assign object list to map
                let newList = [];
                newList.push(kanbanObj);
                kanbanAllCaseRecordsMap.set(kanbanObj.ColumnHeader, newList);
                //Set Rollup Map
                    kanbanAllCaseRecordsRollupMap.set(kanbanObj.ColumnHeader,
                         (kanbanObj.EstimatedConfigHours ? Math.round(kanbanObj.EstimatedConfigHours) : 0));
            }
        }
        //Loop through Map and create properties for each Sprint Week and assign the entries of that key to object
        let columnHeadersForSort = [];
        for (let [key, value] of kanbanAllCaseRecordsMap) {
            columnHeadersForSort.push(key);
            kanbanAllCaseRecords[key] = value;
        }

        for (let [key, value] of kanbanAllCaseRecordsRollupMap) {
            kanbanAllCaseRollups[key] = Math.round(value);
        }
        if(sprintView){
            for(let headers of columnHeadersForSort){
                kanbanAllCaseRecords[headers].sort(function(a, b){
                    return a.diffFromTodayToDueDate - b.diffFromTodayToDueDate
                });
            }
        }else{
            if(kanbanAllCaseRecords['In Process']){
                kanbanAllCaseRecords['In Process'].sort(function(a, b){
                    return a.diffFromTodayToDueDate - b.diffFromTodayToDueDate
                });
            }
        }

        component.set('v.userIdToNameMap', ownerIdToOwnerNameMap); //Added 8.18.22 ST
        component.set('v.KanbanRollups', kanbanAllCaseRollups);
        component.set('v.allCaseOwnerIdList', allCaseOwnerIdList);
        component.set('v.allCaseOwnerNameList', allCaseOwnerNameList);
        component.set('v.caseOwnerList', allCaseOwnerList);
        component.set('v.KanbanRecords', kanbanAllCaseRecords);
        component.set('v.KanbanRecordsBackup', JSON.parse(JSON.stringify(kanbanAllCaseRecords)));
        component.set('v.caseStatusList', weekSprintPlanStatusList);
        component.set('v.allCaseDeptList', allCaseDeptList.sort());
        component.set('v.allColumnHeaders', columnHeadersForSort);

        if(kanbanView == 'Status'){
        let defaultStatusHeaders = ['Pending', 'New', 'Upcoming', 'In Process', 'On Hold'];
            component.set('v.defaultStatusHeaders', defaultStatusHeaders);
            component.set('v.columnHeaders', defaultStatusHeaders);
        }else if(kanbanView == 'Quarter'){
            let defaultQuarterHeaders = ['Q1', 'Q2', 'Q3', 'Q4'];
            component.set('v.columnHeaders', defaultQuarterHeaders);
        }else{
            component.set('v.columnHeaders', JSON.parse(JSON.stringify(component.get('v.columnHeadersStandby'))));
        }
        component.set('v.kanbanDataLoaded', true);
    },


    getAllCases : function(component, event, helper) {
        component.set('v.kanbanDataLoaded', false);
        console.log('@@@@@   getAllCases   @@@@@@@@@');
        let allInternalCases;
        let getAllCases = component.get('c.getInternalCasesForStatusKanban');
        getAllCases.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                allInternalCases = response.getReturnValue();
                let kanbanObjList = [];
                kanbanObjList = this.convertToKanBanObject(allInternalCases, false, null);

                this.setKanbanRecords(component, kanbanObjList, 'Status');

            }else{
                console.error('ERROR');
            }
        });
        $A.enqueueAction(getAllCases);
    },

    getAllSprintPlanWeeks : function(component, event){    
        component.set('v.kanbanDataLoaded', false);
        console.log('@@@@@   getAllSprintPlanWeeks   @@@@@@@@@');
        let allWeekPlans;
        let getAllWeekPlans = component.get('c.getSprintWeekPlansForWeekKanban');
        getAllWeekPlans.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                allWeekPlans = response.getReturnValue();
                let kanbanObjList = [];
                kanbanObjList = this.convertToKanBanObject(allWeekPlans, true, 'Sprint Week');

                this.setKanbanRecords(component, kanbanObjList, null);

            }else{
                console.error('ERROR');
            }
        });
        $A.enqueueAction(getAllWeekPlans);
    },

    getAllSprintPlanMonths : function(component, event){    
        component.set('v.kanbanDataLoaded', false);
        console.log('@@@@@   getAllSprintPlanMonths   @@@@@@@@@');
        let allMonthPlans;
        let getAllMonthPlans = component.get('c.getSprintMonthPlansForMonthKanban');
        getAllMonthPlans.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                allMonthPlans = response.getReturnValue();

                let kanbanObjList = [];
                kanbanObjList = this.convertToKanBanObject(allMonthPlans, true, 'Sprint Month');

                this.setKanbanRecords(component, kanbanObjList, null);

            }else{
                console.error('ERROR');
            }
        });
        $A.enqueueAction(getAllMonthPlans);
    },

    getAllSprintPlanQuarters : function(component, event){    
        component.set('v.kanbanDataLoaded', false);
        console.log('@@@@@   getAllSprintPlanQuarters   @@@@@@@@@');
        let allQuarterPlans;
        let getAllQuarterPlans = component.get('c.getSprintQuarterPlansForQuarterKanban');
        getAllQuarterPlans.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                allQuarterPlans = response.getReturnValue();

                let kanbanObjList = [];
                kanbanObjList = this.convertToKanBanObject(allQuarterPlans, true, 'Sprint Quarter');

                this.setKanbanRecords(component, kanbanObjList, 'Quarter');

            }else{
                console.error('ERROR');
            }
        });
        $A.enqueueAction(getAllQuarterPlans);
    },

    formatDate : function(dateToFormat){
        let dd = String(dateToFormat.getDate()).padStart(2, '0');
        let mm = String(dateToFormat.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = dateToFormat.getFullYear();

        dateToFormat = yyyy + '-' + mm + '-' + dd;
        return dateToFormat;
    },
    
    formatMonthDate : function(dateToFormat){
        //let dd = String(dateToFormat.getDate()).padStart(2, '0');
        let mm = String(dateToFormat.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = dateToFormat.getFullYear();

        dateToFormat = yyyy + '-' + mm + '-02';
        return dateToFormat;
    },

    filterRecords : function(component, event){
        let casePrimaryDepts = component.get('v.caseDept')
        let caseStatus = component.get('v.caseStatus');
        let caseOwners = component.get('v.caseOwners');
        let caseOwnerNames = component.get('v.caseOwners'); //Added 8.18.22 ST
        let toDateLimit = component.get('v.toDate');
        let fromDateLimit = component.get('v.fromDate');
        let sprintView = component.get('v.SprintView');
        let allRecords = JSON.parse(JSON.stringify(component.get('v.KanbanRecordsBackup')));
        let columnHeaders = component.get('v.columnHeaders');

        let endDate;
        let startDate;
        let caseOwnersList = [];
        let caseOwnerNamesList = []; //Added 8.18.22 ST
        let caseStatusList = [];
        let caseDeptList = [];

        toDateLimit ? endDate = Date.parse(toDateLimit) : endDate = Date.parse('2200-12-31');  
        fromDateLimit ? startDate = Date.parse(fromDateLimit) : startDate = Date.parse('1950-01-01');
        
        caseOwners ? caseOwnersList = caseOwners.split(';') : caseOwnersList = component.get('v.allCaseOwnerIdList');
        caseOwnerNames ? caseOwnerNamesList = caseOwnerNames.split(';') : caseOwnerNamesList = component.get('v.allCaseOwnerNameList'); //Added 8.18.22 ST
        caseStatus ? caseStatusList = caseStatus.split(';') : caseStatusList = component.get('v.allCaseStatusList');
        casePrimaryDepts ? caseDeptList = casePrimaryDepts.split(';') : caseDeptList = component.get('v.allCaseDeptList');

        //If the Department Filter is empty then add null to the list to allow cases with Primary Department field empty to show.
        console.log('casePrimaryDepts: ', casePrimaryDepts);
        console.log('caseDeptList: ', caseDeptList);
        if(casePrimaryDepts){
            console.log('Inside of populated Case Primary Departments');
            //caseDeptList.push('');
            //caseDeptList.push(null);      
        }else{
            if(!caseDeptList.includes('None')){
                caseDeptList.push('None');
            }
            //caseDeptList.push(null);  
            console.log('Outside of populated Case Primary Departments');
        }
        
        if(endDate != null && startDate != null){
            for(let header of columnHeaders){
                try{
                    let length = allRecords[header].length;
                    let removedList = [];
                    if(sprintView){
                        //Sort for Sprint Week/Month/Quarter
                        for(let i=0; i < length; i++){
                            let showLogs = false;
                            //console.log('Case: ', allRecords[header][i]);
                            try{
                                if(!allRecords[header][i].hasOwnProperty('PrimaryDepartment')){
                                    allRecords[header][i].PrimaryDepartment = 'None';
                                }
                                if((!caseOwnerNamesList.includes(allRecords[header][i]["Owner"]["Name"]) && !caseOwnerNamesList.includes(allRecords[header][i]["QAOwner"])) || !caseStatusList.includes(allRecords[header][i]["Status"]) || !caseDeptList.includes(allRecords[header][i].PrimaryDepartment)){

                                    if(!allRecords[header][i].hasOwnProperty('PrimaryDepartment')){
                                        //If Case doesn't have the Primary Department then only remove it if there is a Case Department filter
                                        console.log('111111111111111111 ');
                                        if(casePrimaryDepts != null){
                                            console.log('222222222222222222222');
                                            removedList.push(i);
                                        }
                                        
                                    }else{
                                        removedList.push(i);  
                                    }          
                                }else{
                                    //Added 8.19.22 ST To remove Sprint Plans from Sprint Views if the Sprint Week/Month/Quarter is only showing because the QA Owner is being filtered by BUT the Week/Month/Quarter has 0 Estimated QA Hours for that span
                                    //If Case Owner is not in the case Owner Filter BUT the QA Owner IS in the filter AND Estimated QA Hours is 0 or is null then also remove it from the kanban since we only want to show the sprint plans if the filtered user(s) are working on it for that span
                                    if(!caseOwnerNamesList.includes(allRecords[header][i]["Owner"]["Name"]) && caseOwnerNamesList.includes(allRecords[header][i]["QAOwner"]) && (allRecords[header][i]["EstimatedQAHours"] == 0 || allRecords[header][i]["EstimatedQAHours"] == null)){
                                        
                                        removedList.push(i);
                                    }
                                }

                                if(allRecords[header][i].PrimaryDepartment == 'None'){
                                    delete allRecords[header][i].PrimaryDepartment;
                                }
                            }catch(error){
                                console.error('*************** Filter Error ***************', error);
                            }
                        }

                    }else{
                        //Sort for Case Status
                        for(let i=0; i < length; i++){
                            let recordDate = Date.parse(allRecords[header][i].SubmittedDate);
                            try{
                                if(recordDate > endDate || recordDate < startDate || (!caseOwnerNamesList.includes(allRecords[header][i].Owner["Name"]) && !caseOwnerNamesList.includes(allRecords[header][i].QAOwner)) || !casePrimaryDepts.includes(allRecords[header][i].PrimaryDepartment)){
                                    removedList.push(i);           
                                }
                            }catch(error){
                                console.error(error);
                            }
                        }
                    }    
                    if(removedList != null && removedList.length > 0){
                        let splicedCount = 0;
                        for(let pos of removedList){
                            pos = pos - splicedCount;
                            allRecords[header].splice(pos, 1);
                            splicedCount = splicedCount + 1;
                        }   
                    }                
                }catch(error){
                    console.error(error);
                }
            }                
            component.set('v.KanbanRecords', allRecords);
        }else{
            let backupRecords = JSON.parse(JSON.stringify(component.get('v.KanbanRecordsBackup')));
            component.set('v.KanbanRecords', backupRecords);
        }
    },

    filterDates: function(component, event, selectedView){
        
        let days = 86400000; //number of milliseconds in a day

        let defaultStartDate = component.get('v.defaultFromDate');
        let defaultEndDate = component.get('v.defaultToDate');

        let fromDateLimit = component.get('v.fromDate');
        let toDateLimit = component.get('v.toDate');
        let startDate;
        let endDate;
        fromDateLimit ? startDate = new Date(fromDateLimit) : startDate = new Date(defaultStartDate);
        toDateLimit ? endDate = new Date(toDateLimit) : endDate = new Date(defaultEndDate);
        switch(selectedView) {
            case 'Status Kanban':
                this.filterRecords(component, event);
                break;

            case 'Sprint Week Kanban':
                let daysBack = 0;
                let dayOfWeekForFromWeek = startDate.getDay();
                if(dayOfWeekForFromWeek == 0 && startDate.getUTCDay() == 1 ){
                    startDate = new Date(startDate  - (-1 * days));
                }
                let mondayDate;
                do{
                    mondayDate = new Date(startDate  - (daysBack * days));
                    dayOfWeekForFromWeek = mondayDate.getDay();
                    daysBack++;
                    if(daysBack > 6){
                        break;
                    }
                }while(dayOfWeekForFromWeek != 1);
    
                let iterateDate = mondayDate;
                let sprintMondayList = [];
                let columnLimiter = 0;
                
                do{
                    sprintMondayList.push(this.formatDate(iterateDate));
                    iterateDate = new Date(iterateDate  - (-7 * days));
                    columnLimiter++;
                    if(columnLimiter > 25){
                        break;
                    }
                }while(iterateDate <= endDate);

                component.set('v.columnHeaders', sprintMondayList);
                this.filterRecords(component, event);
                break;

            case 'Sprint Month Kanban':
                 
                let newColHeaderList = [];
                let startMonth = startDate.getMonth();
                newColHeaderList.push(this.getMonthFromNumber(startMonth));
                let endMonth = endDate.getMonth();
                let inputMonth = startMonth;
                while(inputMonth != endMonth){
                    inputMonth++;
                    if(inputMonth > 11){
                        inputMonth = 0;
                    }
                    newColHeaderList.push(this.getMonthFromNumber(inputMonth));
                }
                component.set('v.columnHeaders', newColHeaderList);
                this.filterRecords(component, event);
                break;
            case 'Sprint Quarter Kanban':
                this.filterRecords(component, event);
                break;
            }
    },

    getMonthFromNumber: function(monthNumber){
        let month = new Array();
        month[0] = "January";
        month[1] = "February";
        month[2] = "March";
        month[3] = "April";
        month[4] = "May";
        month[5] = "June";
        month[6] = "July";
        month[7] = "August";
        month[8] = "September";
        month[9] = "October";
        month[10] = "November";
        month[11] = "December";
        return month[monthNumber];
    },

    filterStatus : function(component, event, selectedView){
        switch(selectedView) {
            case 'Status Kanban': 
                let selectedCaseStatus = component.get('v.caseStatus');                
                let defaultStatusHeaders = component.get('v.defaultStatusHeaders');
                let columnHeaders = [];
                if(selectedCaseStatus){
                    columnHeaders = selectedCaseStatus.split(';');
                }else{
                    columnHeaders = defaultStatusHeaders;
                }

                component.set('v.columnHeaders', columnHeaders);
                break;
            case 'Sprint Week Kanban':
                this.filterRecords(component, event);
            case 'Sprint Month Kanban':
                this.filterRecords(component, event);
            case 'Sprint Quarter Kanban':
                this.filterRecords(component, event);
                break;
            }
    },

    changeViewHelper : function(component, event, helper, view){
        let groupBy;
        let todaysDate = new Date();
        let days = 86400000; //number of milliseconds in a day
        let today = this.formatMonthDate(todaysDate);
        let defaultToDate = new Date(todaysDate - (-100*days)); //Add days with miliseconds
        let defaultToDateFormatted = this.formatMonthDate(new Date(todaysDate - (-100*days))); //Add days with miliseconds and format
        let selectedMenuItem;
        if(view){
            selectedMenuItem = view;
        }else{
            selectedMenuItem = event.getParam("value");
            component.set('v.KanbanViewSelected', selectedMenuItem);
        }

        if(selectedMenuItem == 'Sprint Month Kanban'){
            groupBy = 'Sprint Month';
            component.set('v.sprintWeekView', false);
            component.set('v.disableDateFilters', false);

            let fromDateMonth = todaysDate.getMonth() - 1;
            let fromDateYear = todaysDate.getFullYear();
            if(fromDateMonth < 0){
                fromDateMonth = 11;
                fromDateYear = todaysDate.getFullYear() - 1;
            }


           let toDateMonth = todaysDate.getMonth() + 2;
           let toDateYear = todaysDate.getFullYear();
            if(toDateMonth > 11){
                toDateMonth = toDateMonth - 12;
                toDateYear = toDateYear + 1;
            }

            //Month View
            let defaultFromDate = new Date(fromDateYear, fromDateMonth, 2);
            let defaultFromDateFormatted = this.formatMonthDate(defaultFromDate);
            defaultToDate = new Date(toDateYear, toDateMonth, 1);
            defaultToDateFormatted = this.formatMonthDate(defaultToDate);
            component.set('v.fromDate', defaultFromDateFormatted);
            component.set('v.toDate', defaultToDateFormatted);
            component.set('v.defaultFromDate', defaultFromDateFormatted);
            component.set('v.defaultToDate', defaultToDateFormatted);
            component.set('v.caseOwners', null);
            component.set('v.caseStatus', null);
            component.set('v.caseDept', null);
            component.set('v.SprintView', true);

            let todayMonth = defaultFromDate.getMonth();
            let sprintMonthList = [];
            let sprintMonthNumber = todayMonth;
            for (let i=0; i<4; i++){
                sprintMonthList.push(this.getMonthFromNumber(sprintMonthNumber));
                sprintMonthNumber++;
                if(sprintMonthNumber > 11){
                    sprintMonthNumber = 0;
                }
            }
            component.set('v.columnHeadersStandby', sprintMonthList);

            this.getAllSprintPlanMonths(component, event, helper);

        }else if(selectedMenuItem == 'Sprint Quarter Kanban'){
            //Quarter View
            groupBy = 'Sprint Quarter';
            component.set('v.sprintWeekView', false);
            component.set('v.disableDateFilters', true);
            component.set('v.SprintView', true);
            component.set('v.fromDate', null);
            component.set('v.toDate', null);
            component.set('v.defaultFromDate', null);
            component.set('v.defaultToDate', null);
            component.set('v.caseOwners', null);
            component.set('v.caseStatus', null);
            component.set('v.caseDept', null);
            this.getAllSprintPlanQuarters(component, event, helper);

        }else if(selectedMenuItem == 'Status Kanban'){
            groupBy = 'Case Status';
            component.set('v.sprintWeekView', false);
            component.set('v.disableDateFilters', false);
            component.set('v.SprintView', false);  
            component.set('v.fromDate', null);
            component.set('v.toDate', null);
            component.set('v.caseOwners', null);
            component.set('v.caseStatus', null);
            component.set('v.caseDept', null);
            this.getAllCases(component, event, helper);                     

        }else if(selectedMenuItem == 'Sprint Week Kanban'){
            groupBy = 'Sprint Week';
            component.set('v.sprintWeekView', true);
            component.set('v.disableDateFilters', false);
            todaysDate = new Date(todaysDate - (7*days));
            today = this.formatDate(new Date(todaysDate - (7*days)));
            defaultToDateFormatted = this.formatDate(new Date(todaysDate - (-22*days))); //Add days with miliseconds and format
            component.set('v.toDate', defaultToDateFormatted);
            component.set('v.defaultFromDate', today);
            component.set('v.defaultToDate', defaultToDateFormatted);
            component.set('v.caseOwners', null);
            component.set('v.caseStatus', null);
            component.set('v.caseDept', null);
            component.set('v.SprintView', true);

            //Loop to get sprint Week monday of entered dates on Kanban date input fields
            let daysBack = 0;
            let dayOfWeekForFromWeek = todaysDate.getDay();
            let mondayDate;
            do{
                mondayDate = new Date(todaysDate  - (daysBack * days));
                dayOfWeekForFromWeek = mondayDate.getDay();
                daysBack++;
                if(daysBack > 6){
                    break;
                }
            }while(dayOfWeekForFromWeek != 1);

            component.set('v.fromDate', this.formatDate(mondayDate));
            let iterateDate = mondayDate;
            let sprintMondayList = [];
            let columnLimiter = 0;
            let endDate = new Date(Date.parse(defaultToDateFormatted));            
            do{
                sprintMondayList.push(this.formatDate(iterateDate));
                iterateDate = new Date(iterateDate  - (-7 * days));
                columnLimiter++;
                if(columnLimiter > 25){
                    break;
                }
            }while(iterateDate < endDate);

            component.set('v.columnHeadersStandby', sprintMondayList);
            this.getAllSprintPlanWeeks(component, event, helper);
        }
        component.set('v.groupBy', groupBy);
    },

    handleEditCaseOwnerEditOnKanban : function(component, newName, newOwnerId){
        let sprintView = component.get('v.SprintView');
        let allKanbanRecs = JSON.parse(JSON.stringify(component.get('v.KanbanRecords')));
        //let allKanbanRecsBackup = JSON.parse(JSON.stringify(component.get('v.KanbanRecordsBackup')));
        let allKanbanRecsBackup = component.get('v.KanbanRecordsBackup');
        //let columnHeaders = JSON.parse(JSON.stringify(component.get('v.columnHeaders')));
        let columnHeaders = component.get('v.columnHeaders');
        let editedRec = JSON.parse(JSON.stringify(component.get('v.editCaseOwnerRecord')));
        let editedRecPos = component.get('v.editCaseOwnerRecordPosition');
        let Owner = new Object();
        Owner.Id = newOwnerId;
        Owner.Name = newName;

        let currentMonday = this.getCurrentMondaySprintWeek();

        if(editedRec.ColumnHeader != 'In Process' && sprintView == false){
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].Owner = Owner;
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].OwnerId = newOwnerId;
            for(let header of columnHeaders){
                if(allKanbanRecsBackup[header]){
                    for(let rec of allKanbanRecsBackup[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.Owner = Owner;
                            rec.OwnerId = newOwnerId;
                        }
                    }
                }
            }
            
            /************ Comment Out functionality that moves Case to 'In Process' when Case Owner is assigned (This is only logic for this to be reflected in the Kanban not actually changing SF fields)
            editedRec.Owner = Owner;
            //editedRec.OwnerId = newOwnerId;
            let oldColumnHeader = editedRec.ColumnHeader
            //editedRec.ColumnHeader = 'In Process';
            //editedRec.Status = 'In Process';
            //editedRec.QaStatus = 'Work in Progress';
            if(!editedRec.SprintWeeks){
                //editedRec.SprintWeeks = currentMonday;
            }
            if(!allKanbanRecs['In Process']){
                let emptyColumnToUpdate = [];
                //emptyColumnToUpdate.push(editedRec);
                //allKanbanRecs['In Process'] = emptyColumnToUpdate;
            }else{
                try{
                    //allKanbanRecs['In Process'].unshift(editedRec);
                }catch(error){
                    console.error(error);
                }
            }
            //allKanbanRecs['In Process'].sort(function(a, b){
                //return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
            //});
            allKanbanRecs[oldColumnHeader].splice(editedRecPos, 1);

            //Update BackupKanban Records
            if(!allKanbanRecsBackup['In Process']){
                let emptyColumnToUpdateBackup = [];
                //emptyColumnToUpdateBackup.push(editedRec);
                //allKanbanRecsBackup['In Process'] = emptyColumnToUpdateBackup;
            }else{
                try{
                    //allKanbanRecsBackup['In Process'].unshift(editedRec);
                }catch(error){
                    console.error(error);
                }
            }
            //allKanbanRecsBackup['In Process'].sort(function(a, b){
                //return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
            //});
            //allKanbanRecsBackup[oldColumnHeader].splice(editedRecPos, 1);
            **************************************************************************************************************************/
        }else{
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].Owner = Owner;
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].OwnerId = newOwnerId;
            for(let header of columnHeaders){
                if(allKanbanRecsBackup[header]){
                    for(let rec of allKanbanRecsBackup[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.Owner = Owner;
                            rec.OwnerId = newOwnerId;
                        }
                    }
                }
            }
        }
        component.set('v.KanbanRecords', allKanbanRecs);
        component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);

        //let allCaseOwnerList = JSON.parse(JSON.stringify(component.get('v.allCaseOwnerIdList')));
        let allCaseOwnerList = component.get('v.allCaseOwnerIdList');
        //let caseOwnerList = JSON.parse(JSON.stringify(component.get('v.caseOwnerList')));
        let caseOwnerList = component.get('v.caseOwnerList');
        if(!allCaseOwnerList.includes(newOwnerId)){
            allCaseOwnerList.push(newOwnerId);
            caseOwnerList.push(Owner);
            component.set('v.allCaseOwnerIdList', allCaseOwnerList);
            component.set('v.caseOwnerList', caseOwnerList);
        }
    },

    handleEditQAStatusEditOnKanban : function(component, newQAStatus){
        let allKanbanRecs = JSON.parse(JSON.stringify(component.get('v.KanbanRecords')));
        let allKanbanRecsBackup = component.get('v.KanbanRecordsBackup');
        let editedRec = JSON.parse(JSON.stringify(component.get('v.editQAStatusRecord')));
        let editedRecPos = component.get('v.editQAStatusRecordPosition');
        let columnHeaders = component.get('v.columnHeaders');
        if(component.get('v.SprintView')){
            for(let header of columnHeaders){
                if(allKanbanRecs[header]){
                    for(let rec of allKanbanRecs[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.QaStatus = newQAStatus;
                        }
                    }
                }
            
                if(allKanbanRecsBackup[header]){
                    for(let rec of allKanbanRecsBackup[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.QaStatus = newQAStatus;
                        }
                    }
                }
            }
        }else{
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].QaStatus = newQAStatus;
            if(allKanbanRecsBackup['In Process']){
                for(let rec of allKanbanRecsBackup['In Process']){
                    if(rec.CaseId == editedRec.CaseId){
                        rec.QaStatus = newQAStatus;
                    }
                }
            }
        }
            
            component.set('v.KanbanRecords', allKanbanRecs);
            component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);
    },

    handleEditCaseOnKanban : function(component, newCaseStatus){
        let sprintView = component.get('v.SprintView');
        let allKanbanRecs = JSON.parse(JSON.stringify(component.get('v.KanbanRecords')));
        let allKanbanRecsBackup = component.get('v.KanbanRecordsBackup');
        let editedRec = JSON.parse(JSON.stringify(component.get('v.editCaseStatusRecord')));
        let editedRecPos = component.get('v.editCaseStatusRecordPosition');

        let currentMonday = this.getCurrentMondaySprintWeek();
          
        if(sprintView == false && newCaseStatus != editedRec.Status){           
            
            editedRec.Status = newCaseStatus;
            let oldColumnHeader = editedRec.ColumnHeader
            editedRec.ColumnHeader = newCaseStatus;
            if(editedRec.QaStatus != 'N/A'){
                editedRec.QaStatus = 'Work in Progress';
            }
            if(newCaseStatus == 'In Process' && !editedRec.SprintWeeks){
                if(editedRec.DueDate && editedRec.StartDate){
                    editedRec.SprintWeeks = this.createSprintWeeks(editedRec.StartDate, editedRec.DueDate);
                }else if(editedRec.DueDate){
                    editedRec.SprintWeeks = this.createSprintWeeks(currentMonday, editedRec.DueDate);
                }else{
                    editedRec.SprintWeeks = currentMonday;
                }
            }
            if(!allKanbanRecs[newCaseStatus]){
                let emptyColumnToUpdate = [];
                emptyColumnToUpdate.push(editedRec);
                allKanbanRecs[newCaseStatus] = emptyColumnToUpdate;
            }else{
                try{
                    allKanbanRecs[newCaseStatus].unshift(editedRec);
                }catch(error){
                    console.error(error);
                }
            }
            allKanbanRecs[newCaseStatus].sort(function(a, b){
                return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
            });
            allKanbanRecs[oldColumnHeader].splice(editedRecPos, 1);

            //Update BackupKanban Records
            if(!allKanbanRecsBackup[newCaseStatus]){
                let emptyColumnToUpdateBackup = [];
                emptyColumnToUpdateBackup.push(editedRec);
                allKanbanRecsBackup[newCaseStatus] = emptyColumnToUpdateBackup;
            }else{
                try{
                    allKanbanRecsBackup[newCaseStatus].unshift(editedRec);
                }catch(error){
                    console.error(error);
                }
            }
            allKanbanRecsBackup[newCaseStatus].sort(function(a, b){
                return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
            });
            allKanbanRecsBackup[oldColumnHeader].splice(editedRecPos, 1);

            component.set('v.KanbanRecords', allKanbanRecs);
            component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);
        }

    },

    handleEditQAOwnerEditOnKanban : function(component, newQAOwnerName, newQAOwnerId){
        let sprintView = component.get('v.SprintView');
        let allKanbanRecs = JSON.parse(JSON.stringify(component.get('v.KanbanRecords')));
        //let allKanbanRecsBackup = JSON.parse(JSON.stringify(component.get('v.KanbanRecordsBackup')));
        let allKanbanRecsBackup = component.get('v.KanbanRecordsBackup');
        //let columnHeaders = JSON.parse(JSON.stringify(component.get('v.columnHeaders')));
        let columnHeaders = component.get('v.columnHeaders');
        let editedRec = JSON.parse(JSON.stringify(component.get('v.editQAOwnerRecord')));
        let editedRecPos = component.get('v.editQAOwnerRecordPosition');
        let Owner = new Object();
        Owner.Id = newQAOwnerId;
        Owner.Name = newQAOwnerName;

        if(editedRec.ColumnHeader != 'In Process' && sprintView == false){
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].QAOwner = newQAOwnerName;
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].QAOwnerId = newQAOwnerId;
            for(let header of columnHeaders){
                if(allKanbanRecsBackup[header]){
                    for(let rec of allKanbanRecsBackup[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.QAOwner = newQAOwnerName;
                            rec.QAOwnerId = newQAOwnerId;
                        }
                    }
                }
            }
        }else{
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].QAOwner = newQAOwnerName;
            allKanbanRecs[editedRec.ColumnHeader][editedRecPos].QAOwnerId = newQAOwnerId;
            for(let header of columnHeaders){
                if(allKanbanRecsBackup[header]){
                    for(let rec of allKanbanRecsBackup[header]){
                        if(rec.CaseId == editedRec.CaseId){
                            rec.QAOwner = newQAOwnerName;
                            rec.QAOwnerId = newQAOwnerId;
                        }
                    }
                }
            }
        }
        component.set('v.KanbanRecords', allKanbanRecs);
        component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);

        //let allCaseOwnerList = JSON.parse(JSON.stringify(component.get('v.allCaseOwnerIdList')));
        let allCaseOwnerList = component.get('v.allCaseOwnerIdList');
        //let caseOwnerList = JSON.parse(JSON.stringify(component.get('v.caseOwnerList')));
        let caseOwnerList = component.get('v.caseOwnerList');
        if(!allCaseOwnerList.includes(newQAOwnerId)){
            allCaseOwnerList.push(newQAOwnerId);
            caseOwnerList.push(Owner);
            component.set('v.allCaseOwnerIdList', allCaseOwnerList);
            component.set('v.caseOwnerList', caseOwnerList);
        }
    },

    getCurrentMondaySprintWeek : function(){
        let days = 86400000; //number of milliseconds in a day
        let todaysDate = new Date();
        let daysBack = 0;
        let todayDayOfWeek
        let mondayDate;
        do{
            mondayDate = new Date(todaysDate  - (daysBack * days));
            todayDayOfWeek = mondayDate.getDay();
            daysBack++;
            if(daysBack > 6){
                break;
            }
        }while(todayDayOfWeek != 1);
        let dd = String(mondayDate.getDate());
        let mm = String(mondayDate.getMonth() + 1);
        let yyyy = mondayDate.getFullYear();
        let currentMonday =  mm + '/' + dd + '/' + yyyy;
        return currentMonday;
    },

    formatDateForSprintWeek: function(dateToFormat){
        let dd = String(dateToFormat.getDate());
        let mm = String(dateToFormat.getMonth() + 1);
        let yyyy = dateToFormat.getFullYear();
        let formattedDate =  mm + '/' + dd + '/' + yyyy;
        return formattedDate;
    },

    handleEditRecordOnKanban : function(component, event, newEstimatedHours, newDueDate, newStartDate, newPrimDept, newSprintWeeks, newStatus, newRequirementsStatus, newQAStatus, newQAOwnerId, newQAOwnerName, newEstimatedQAHours){
        let days = 86400000; //number of milliseconds in a day
        let isChanged = false;
        let sortNeeded = false;
        let oldSprintMonths;
        let newSprintMonths;
        let unchangedRecord = true;
        let newSprintQuarters;
        let sprintMonthMap = new Map();
        let sprintMonthSet = new Set();
        let roundedSprintWeekEstHours;
        let allColumnHeaders = component.get('v.allColumnHeaders');
        let sprintView = component.get('v.SprintView');
        let allKanbanRecs = JSON.parse(JSON.stringify(component.get('v.KanbanRecords')));
        let allKanbanRecsBackup = component.get('v.KanbanRecordsBackup');
        let columnHeaders = component.get('v.columnHeaders');
        let parsedEditRecord = JSON.parse(JSON.stringify(component.get('v.editRecord')));
        let editRecPos = component.get('v.editRecordPosition');
        let currentMonday = this.getCurrentMondaySprintWeek();
        try{
            if(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos]){
                if(!sprintView){
                    //Not in Ops Kanban
                    if(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].CaseId == parsedEditRecord.CaseId && (parsedEditRecord.EstimatedConfigHours != newEstimatedHours || parsedEditRecord.DueDate != newDueDate || parsedEditRecord.StartDate != newStartDate ||
                        parsedEditRecord.PrimaryDepartment != newPrimDept || parsedEditRecord.SprintWeeks != newSprintWeeks || parsedEditRecord.Status != newStatus || parsedEditRecord.RequirementsStatus != newRequirementsStatus || 
                        parsedEditRecord.QaStatus != newQAStatus || parsedEditRecord.QAOwnerId != newQAOwnerId || parsedEditRecord.EstimatedQAHours != newEstimatedQAHours)){
                        isChanged = true;
                        if(parsedEditRecord.EstimatedConfigHours != newEstimatedHours){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].EstimatedConfigHours = newEstimatedHours;
                        }
                        if(parsedEditRecord.DueDate != newDueDate){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].DueDate = newDueDate;
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].diffFromTodayToDueDate = allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].DueDate ? this.getDistanceFromToday(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].DueDate) : 100000;

                        }
                        if(parsedEditRecord.StartDate != newStartDate){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].StartDate = newStartDate;
                        }
                        if(parsedEditRecord.PrimaryDepartment != newPrimDept){
                            let currentDepartmentList = component.get('v.allCaseDeptList');
                            if(!currentDepartmentList.includes(newPrimDept)){
                                currentDepartmentList.push(newPrimDept);
                                component.set('v.allCaseDeptList', currentDepartmentList.sort());
                            }
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].PrimaryDepartment = newPrimDept;
                        }
                        //Not in Ops Kanban
                        if(parsedEditRecord.RequirementsStatus != newRequirementsStatus){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].RequirementsStatus = newRequirementsStatus;
                        }
                        if(parsedEditRecord.SprintWeeks != newSprintWeeks){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].SprintWeeks = newSprintWeeks;
                        }
                        if(parsedEditRecord.QaStatus != newQAStatus){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].QaStatus = newQAStatus;
                        }
                        if(parsedEditRecord.QAOwnerId != newQAOwnerId){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].QAOwnerId = newQAOwnerId;
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].QAOwner = newQAOwnerName;
                        }
                        if(parsedEditRecord.EstimatedQAHours != newEstimatedQAHours){
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].EstimatedQAHours = newEstimatedQAHours;
                        }
                        /************************************************** Change to make Status edit from Edit Pop out reflect on the Kanban Card *****************************************************************************/
                        if(parsedEditRecord.Status != newStatus){
                            let newColumn = newStatus;
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].Status = newStatus;
                            allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].ColumnHeader = newStatus;
                            if(newStatus == 'In Process'){
                                if(!allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].SprintWeeks){
                                    allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].SprintWeeks = currentMonday;
                                }
                            }
                            if(!allKanbanRecs[newColumn]){
                                let emptyColumnToUpdate = [];
                                emptyColumnToUpdate.push(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos]);
                                allKanbanRecs[newColumn] = emptyColumnToUpdate;
                            }else{
                                try{
                                    allKanbanRecs[newColumn].unshift(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos]);
                                }catch(error){
                                    console.error(error);
                                }
                            }
                            if(newStatus == 'In Process'){
                                allKanbanRecs[newColumn].sort(function(a, b){
                                    return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                });
                            }else{
                                if(allKanbanRecs[newColumn]){
                                    allKanbanRecs[newColumn].sort(function(a, b){
                                        return new Date(a.SubmittedDate) - new Date(b.SubmittedDate)
                                    });
                                }
                            }
                            
                            allKanbanRecs[parsedEditRecord.ColumnHeader].splice(editRecPos, 1);

                            //Update BackupKanban Records
                            if(!allKanbanRecsBackup[parsedEditRecord.ColumnHeader]){
                                let emptyColumnToUpdateBackup = [];
                                emptyColumnToUpdateBackup.push(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos]);
                                allKanbanRecsBackup[parsedEditRecord.ColumnHeader] = emptyColumnToUpdateBackup;
                            }else{
                                try{
                                    allKanbanRecsBackup[parsedEditRecord.ColumnHeader].unshift(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos]);
                                }catch(error){
                                    console.error(error);
                                }
                            }
                            if(newStatus == 'In Process'){
                                allKanbanRecsBackup[newColumn].sort(function(a, b){
                                    return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                });
                            }else{
                                if(allKanbanRecsBackup[newColumn]){
                                    allKanbanRecsBackup[newColumn].sort(function(a, b){
                                        return new Date(a.SubmittedDate) - new Date(b.SubmittedDate)
                                    });
                                }
                            }
                            allKanbanRecsBackup[parsedEditRecord.ColumnHeader].splice(editRecPos, 1);
                        }
                        /*******************************************************************************************************************************/
                        
                        for(let header of columnHeaders){
                            if(allKanbanRecsBackup[header]){
                                for(let backupRec of allKanbanRecsBackup[header]){
                                    if(backupRec){
                                        if(backupRec.CaseId == parsedEditRecord.CaseId){
                                            if(parsedEditRecord.EstimatedConfigHours != newEstimatedHours){
                                                backupRec.EstimatedConfigHours = newEstimatedHours;
                                            }
                                            if(parsedEditRecord.DueDate != newDueDate){
                                                backupRec.DueDate = newDueDate;
                                                backupRec.diffFromTodayToDueDate = backupRec.DueDate ? this.getDistanceFromToday(backupRec.DueDate) : 100000;
                                            }
                                            if(parsedEditRecord.StartDate != newStartDate){
                                                backupRec.StartDate = newStartDate;
                                            }
                                            if(parsedEditRecord.PrimaryDepartment != newPrimDept){
                                                backupRec.PrimaryDepartment = newPrimDept;
                                            }
                                            //Not in Ops Kanban
                                            if(parsedEditRecord.RequirementsStatus != newRequirementsStatus){
                                                backupRec.RequirementsStatus = newRequirementsStatus;
                                            }
                                            if(parsedEditRecord.SprintWeeks != newSprintWeeks){
                                                backupRec.SprintWeeks = newSprintWeeks;
                                            }
                                            if(parsedEditRecord.QaStatus != newQAStatus){
                                                backupRec.QaStatus = newQAStatus;
                                            }
                                            if(parsedEditRecord.QAOwnerId != newQAOwnerId){
                                                backupRec.QAOwnerId = newQAOwnerId;
                                                backupRec.QAOwner = newQAOwnerName;
                                            }
                                            if(parsedEditRecord.EstimatedQAHours != newEstimatedQAHours){
                                                backupRec.EstimatedQAHours = newEstimatedQAHours;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(isChanged){
                        if(newStatus == 'In Process'){
                                allKanbanRecs[parsedEditRecord.ColumnHeader].sort(function(a, b){
                                    return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                });
                        }
                        component.set('v.KanbanRecords', allKanbanRecs);
                        component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);
                    }
                }else{
                    //For Sprint Views
                    let selectedView = component.get('v.KanbanViewSelected');
                    if(allKanbanRecs[parsedEditRecord.ColumnHeader][editRecPos].CaseId == parsedEditRecord.CaseId && (parsedEditRecord.EstimatedConfigHours != newEstimatedHours || parsedEditRecord.DueDate != newDueDate || parsedEditRecord.StartDate != newStartDate ||
                        parsedEditRecord.PrimaryDepartment != newPrimDept || parsedEditRecord.SprintWeeks != newSprintWeeks || parsedEditRecord.RequirementsStatus != newRequirementsStatus || parsedEditRecord.QaStatus != newQAStatus || 
                        parsedEditRecord.QAOwnerId != newQAOwnerId || parsedEditRecord.EstimatedQAHours != newEstimatedQAHours || parsedEditRecord.Status != newStatus )){

                        isChanged = true;
                        for(let header of allColumnHeaders){
                            if(allKanbanRecs[header]){
                                for(let rec of allKanbanRecs[header]){
                                    if(rec.CaseId == parsedEditRecord.CaseId){
                                        let sprintWeeksSplit;
                                        sprintWeeksSplit = newSprintWeeks.split(';');
                                        let lastSprintWeek = sprintWeeksSplit[sprintWeeksSplit.length - 1];
                                        if(newSprintWeeks){
                                            if(parsedEditRecord.SprintWeeks != newSprintWeeks){
                                                if(rec.SprintMonths){
                                                    if(unchangedRecord){
                                                        oldSprintMonths = rec.SprintMonths;
                                                        unchangedRecord = false;
                                                    }
                                                }
                                                //let sprintWeeksSplit;
                                                //sprintWeeksSplit = newSprintWeeks.split(';');
                                                //Delete Cards that are no longer in the sprint weeks after Edit
                                                if(selectedView == 'Sprint Week Kanban'){
                                                    let headerDate = new Date(rec.ColumnHeader);
                                                    headerDate = new Date(headerDate - (-1 * days));                                                
                                                    if(!newSprintWeeks.includes(this.formatDateForSprintWeek(headerDate).toString())){
                                                        let index = allKanbanRecs[header].indexOf(rec);
                                                        allKanbanRecs[header].splice(index, 1);
                                                        continue;
                                                    }
                                                    rec.SprintWeeks = newSprintWeeks;
                                                    let numberOfSprintWeeks = sprintWeeksSplit.length;
                                                    rec.EstimatedConfigHours = newEstimatedHours / numberOfSprintWeeks;
                                                }
                                                //Delete Cards that are no longer in the Sprint Months after Edit
                                                if(selectedView == 'Sprint Month Kanban'){

                                                    //To round it to nearest .00, .25, .50, .75
                                                    roundedSprintWeekEstHours = this.roundToNearestFourth(newEstimatedHours / sprintWeeksSplit.length);
                                                    sprintMonthMap.clear();
                                                    for(let sprintWeek of sprintWeeksSplit){
                                                        let sprintMonthName = this.getMonthFromNumber(parseInt(sprintWeek.split('/')[0]) - 1);
                                                        sprintMonthSet.add(sprintMonthName);

                                                        if(sprintMonthMap.has(sprintMonthName)){
                                                        //If month already exists then add to the counter to count weeks in month
                                                            let monthAmount = 0;
                                                            monthAmount = sprintMonthMap.get(sprintMonthName) + roundedSprintWeekEstHours;
                                                            sprintMonthMap.set(sprintMonthName, monthAmount);
                                                        }else{
                                                            
                                                            //If month doesn't exist then add to map and initialize it in map with 1
                                                            sprintMonthMap.set(sprintMonthName, roundedSprintWeekEstHours);   
                                                        }
                                                    }

                                                    if(!sprintMonthSet.has(rec.ColumnHeader)){
                                                        let monthRecIndex = allKanbanRecs[header].indexOf(rec);
                                                        allKanbanRecs[header].splice(monthRecIndex, 1);
                                                        continue;
                                                    }                               

                                                    rec.EstimatedConfigHours = sprintMonthMap.get(header);
                                                    newSprintMonths = (Array.from(sprintMonthSet)).join(";");
                                                    rec.SprintMonths = newSprintMonths;

                                                }
                                                //Delete Cards that are no longer in the Sprint Quarters after Edit
                                                if(selectedView == 'Sprint Quarter Kanban'){
                                                    


                                                }
                                            }
                                        }

                                        if(newSprintWeeks){
                                            if(parsedEditRecord.EstimatedConfigHours != newEstimatedHours && parsedEditRecord.SprintWeeks == newSprintWeeks){
                                                //Set Estimated Hours for Sprint Week Cards
                                                if(selectedView == 'Sprint Week Kanban'){
                                                    if(newSprintWeeks){
                                                        let splitSprints = newSprintWeeks.split(';');
                                                        let numberOfSprintWeeks = splitSprints.length;
                                                        rec.EstimatedConfigHours = newEstimatedHours / numberOfSprintWeeks;
                                                    }
                                                }

                                                //Set Estimated Hours for Sprint Month Cards
                                                if(selectedView == 'Sprint Month Kanban'){ 

                                                    let sprintWeeksSplit;
                                                    sprintWeeksSplit = newSprintWeeks.split(';');

                                                    //To round it to nearest .00, .25, .50, .75
                                                    roundedSprintWeekEstHours = this.roundToNearestFourth(newEstimatedHours / sprintWeeksSplit.length);
                                                    sprintMonthMap.clear();
                                                    for(let sprintWeek of sprintWeeksSplit){
                                                        let sprintMonthName = this.getMonthFromNumber(parseInt(sprintWeek.split('/')[0]) - 1);
                                                        sprintMonthSet.add(sprintMonthName);

                                                        if(sprintMonthMap.has(sprintMonthName)){
                                                        //If month already exists then add to the counter to count weeks in month
                                                            let monthAmount = 0;
                                                            monthAmount = sprintMonthMap.get(sprintMonthName) + roundedSprintWeekEstHours;
                                                            sprintMonthMap.set(sprintMonthName, monthAmount);
                                                        }else{
                                                            
                                                            //If month doesn't exist then add to map and initialize it in map with 1
                                                            sprintMonthMap.set(sprintMonthName, roundedSprintWeekEstHours);   
                                                        }
                                                    }

                                                    if(!sprintMonthSet.has(rec.ColumnHeader)){
                                                        let monthRecIndex = allKanbanRecs[header].indexOf(rec);
                                                        allKanbanRecs[header].splice(monthRecIndex, 1);
                                                        continue;
                                                    }

                                                    rec.EstimatedConfigHours = sprintMonthMap.get(header);
                                                    newSprintMonths = (Array.from(sprintMonthSet)).join(";");
                                                    rec.SprintMonths = newSprintMonths;
                                                
                                                }
                                                //Set Estimated Hours for Sprint Quarter Cards
                                                if(selectedView == 'Sprint Quarter Kanban'){
                                                    
                                                }
                                            }
                                        }

                                        if(parsedEditRecord.DueDate != newDueDate){
                                            rec.DueDate = newDueDate;
                                            rec.diffFromTodayToDueDate = rec.DueDate ? this.getDistanceFromToday(rec.DueDate) : 100000;
                                            sortNeeded = true;
                                            allKanbanRecs[header].sort(function(a, b){
                                                return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                            });
                                        }
                                        if(parsedEditRecord.PrimaryDepartment != newPrimDept){
                                            let currentDepartmentList = component.get('v.allCaseDeptList');
                                            if(!currentDepartmentList.includes(newPrimDept)){
                                                currentDepartmentList.push(newPrimDept);
                                                component.set('v.allCaseDeptList', currentDepartmentList.sort());
                                            }
                                            rec.PrimaryDepartment = newPrimDept;
                                        }
                                        if(parsedEditRecord.RequirementsStatus != newRequirementsStatus){
                                            rec.RequirementsStatus = newRequirementsStatus;
                                        }
                                        if(parsedEditRecord.QaStatus != newQAStatus){
                                            rec.QaStatus = newQAStatus;
                                        }
                                        if(parsedEditRecord.QAOwnerId != newQAOwnerId){
                                            rec.QAOwnerId = newQAOwnerId;
                                            rec.QAOwner = newQAOwnerName;
                                        }
                                        if(parsedEditRecord.EstimatedQAHours != newEstimatedQAHours){
                                            if(selectedView == 'Sprint Week Kanban'){
                                                let sprintDateAsDate = new Date(rec.SprintDate);
                                                let parsedSprintDate = (sprintDateAsDate.getMonth() + 1).toString() + '/' + (sprintDateAsDate.getDate() + 1).toString() + '/' +  (sprintDateAsDate.getFullYear()).toString();
                                                
                                                if(parsedSprintDate == lastSprintWeek){
                                                    rec.EstimatedQAHours = newEstimatedQAHours;
                                                }
                                            }else if(selectedView == 'Sprint Month Kanban'){
                                                let lastSprintMonth = lastSprintWeek.split('/');
                                                let parsedSprintMonthString = lastSprintMonth[2] + '-' + lastSprintMonth[0].padStart(2, '0') + '-01';
                                                if(rec.SprintDate == parsedSprintMonthString){
                                                    rec.EstimatedQAHours = newEstimatedQAHours;
                                                }

                                            }else if(selectedView == 'Sprint Quarter Kanban'){
                                                let lastSprintWeekSplit = lastSprintWeek.split('/');
                                                let lastSprintQuarterName = this.getQuarterFromMonth(lastSprintWeekSplit[0]);
                                                if(rec.SprintDate == lastSprintQuarterName){
                                                    rec.EstimatedQAHours = newEstimatedQAHours;
                                                }

                                            }
                                        }
                                            
                                    }
                                }
                            }
                        }

                    /************************************************* Create cards for new Sprint Weeks *****************************************************/
                        if(newSprintWeeks && parsedEditRecord.SprintWeeks != newSprintWeeks && selectedView == 'Sprint Week Kanban'){
                            
                            let sprintWeeksSplit;
                            sprintWeeksSplit = newSprintWeeks.split(';');
                            for(let sprintWeek of sprintWeeksSplit){
                                if(!parsedEditRecord.SprintWeeks.includes(sprintWeek)){
                                    let sprintDate = new Date(sprintWeek);
                                    sprintDate = this.formatDate(sprintDate);
                                    let newCard = this.copyNewKanbanObj(parsedEditRecord);
                                    newCard.SprintWeeks = newSprintWeeks;
                                    newCard.ColumnHeader = sprintDate;
                                    newCard.EstimatedConfigHours = newEstimatedHours / sprintWeeksSplit.length;
                                    newCard.DueDate = newDueDate;
                                    newCard.diffFromTodayToDueDate = newCard.DueDate ? this.getDistanceFromToday(newCard.DueDate) : 100000;
                                    //Logic to check if column is empty
                                    if(!allKanbanRecs[sprintDate]){
                                        let emptyColumnToUpdate = [];
                                        emptyColumnToUpdate.push(newCard);
                                        allKanbanRecs[sprintDate] = emptyColumnToUpdate;
                                    }else{
                                        allKanbanRecs[sprintDate].unshift(newCard);
                                    }
                                    if(!allKanbanRecsBackup[sprintDate]){
                                        let emptyColumnToUpdateBackup = [];
                                        emptyColumnToUpdateBackup.push(newCard);
                                        allKanbanRecsBackup[sprintDate] = emptyColumnToUpdateBackup;
                                    }else{
                                        allKanbanRecsBackup[sprintDate].unshift(newCard);
                                    }
                                    allKanbanRecs[sprintDate].sort(function(a, b){
                                        return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                    });
                                }
                            }
                        }

                        /************************************************* Create cards for new Sprint Months *****************************************************/
                        
                        if(newSprintMonths && oldSprintMonths && oldSprintMonths != newSprintMonths && selectedView == 'Sprint Month Kanban'){
                            let sprintMonthsSplit;
                            sprintMonthsSplit = newSprintMonths.split(';');
                            for(let sprintMonth of sprintMonthsSplit){
                                if(oldSprintMonths && !oldSprintMonths.includes(sprintMonth)){
                                    let newCard = this.copyNewKanbanObj(parsedEditRecord);
                                    newCard.SprintWeeks = newSprintWeeks;
                                    newCard.SprintMonths = newSprintMonths
                                    newCard.ColumnHeader = sprintMonth;
                                    newCard.EstimatedConfigHours = sprintMonthMap.get(sprintMonth);
                                    newCard.DueDate = newDueDate;
                                    newCard.diffFromTodayToDueDate = newCard.DueDate ? this.getDistanceFromToday(newCard.DueDate) : 100000;
                                    if(!allKanbanRecs[sprintMonth]){
                                        let emptyColumnToUpdate = [];
                                        emptyColumnToUpdate.push(newCard);
                                        allKanbanRecs[sprintMonth] = emptyColumnToUpdate;
                                    }else{
                                        allKanbanRecs[sprintMonth].unshift(newCard);
                                    }
                                    if(!allKanbanRecsBackup[sprintMonth]){
                                        let emptyColumnToUpdateBackup = [];
                                        emptyColumnToUpdateBackup.push(newCard);
                                        allKanbanRecsBackup[sprintMonth] = emptyColumnToUpdateBackup;
                                    }else{
                                        allKanbanRecsBackup[sprintMonth].unshift(newCard);
                                    }
                                    allKanbanRecs[sprintMonth].sort(function(a, b){
                                        return new Date(a.diffFromTodayToDueDate) - new Date(b.diffFromTodayToDueDate)
                                    });
                                }
                            }

                        }

                        /************************************************* Create cards for new Sprint Quarters *****************************************************/
                        if(parsedEditRecord.SprintWeeks != newSprintWeeks && selectedView == 'Sprint Quarter Kanban'){

                        }

                        /*********************************************************************** UPDATE BACKUP KANBAN RECORDS ***************************************************************************/
                        for(let header of allColumnHeaders){
                            if(header){
                                if(allKanbanRecsBackup[header]){
                                    for(let backupRec of allKanbanRecsBackup[header]){
                                        if(backupRec){
                                            if(backupRec.CaseId == parsedEditRecord.CaseId){
                                                let sprintWeeksSplit;
                                                sprintWeeksSplit = newSprintWeeks.split(';');
                                                let lastSprintWeek = sprintWeeksSplit[sprintWeeksSplit.length - 1];
                                                if(newSprintWeeks){    
                                                    //let sprintWeeksSplit;
                                                    //sprintWeeksSplit = newSprintWeeks.split(';');
                                                    if(parsedEditRecord.SprintWeeks != newSprintWeeks){
                                                        if(selectedView == 'Sprint Week Kanban'){
                                                            let backupHeaderDate = new Date(backupRec.ColumnHeader);
                                                            backupHeaderDate = new Date(backupHeaderDate - (-1 * days));
                                                            //Delete existing Cards that are no longer in the New Edited Sprint Weeks
                                                            if(!newSprintWeeks.includes(this.formatDateForSprintWeek(backupHeaderDate).toString()) && parsedEditRecord.SprintWeeks.includes(this.formatDateForSprintWeek(backupHeaderDate).toString())){
                                                                let backupIndex = allKanbanRecsBackup[header].indexOf(backupRec);
                                                                allKanbanRecsBackup[header].splice(backupIndex, 1);
                                                                continue;
                                                            }
                                                            backupRec.SprintWeeks = newSprintWeeks;
                                                            let numberOfSprintWeeks = sprintWeeksSplit.length;
                                                            backupRec.EstimatedConfigHours = newEstimatedHours / numberOfSprintWeeks;
                                                        }
                                                        if(selectedView == 'Sprint Month Kanban'){

                                                            if(!sprintMonthSet.has(backupRec.ColumnHeader)){
                                                                let monthRecIndex = allKanbanRecsBackup[header].indexOf(backupRec);
                                                                allKanbanRecsBackup[header].splice(monthRecIndex, 1);
                                                                continue;
                                                            }                               

                                                            backupRec.EstimatedConfigHours = sprintMonthMap.get(header);
                                                            newSprintMonths = (Array.from(sprintMonthSet)).join(";");
                                                            backupRec.SprintMonths = newSprintMonths;
                                                        }
                                                    }
                                                }
                                                if(parsedEditRecord.EstimatedConfigHours != newEstimatedHours && parsedEditRecord.SprintWeeks == newSprintWeeks){
                                                    if(selectedView == 'Sprint Week Kanban'){
                                                        if(newSprintWeeks){
                                                            let splitSprints = newSprintWeeks.split(';');
                                                            let numberOfSprintWeeks = splitSprints.length;
                                                            backupRec.EstimatedConfigHours = newEstimatedHours / numberOfSprintWeeks;
                                                        }
                                                    }
                                                    if(selectedView == 'Sprint Month Kanban'){ 
    
                                                        backupRec.EstimatedConfigHours = sprintMonthMap.get(header);
                                                        newSprintMonths = (Array.from(sprintMonthSet)).join(";");
                                                        backupRec.SprintMonths = newSprintMonths;
                                                    }
                                                    
                                                }
                                                if(parsedEditRecord.DueDate != newDueDate){
                                                    backupRec.DueDate = newDueDate;
                                                    backupRec.diffFromTodayToDueDate = backupRec.DueDate ? this.getDistanceFromToday(backupRec.DueDate) : 100000;
                                                }
                                                if(parsedEditRecord.PrimaryDepartment != newPrimDept){
                                                    backupRec.PrimaryDepartment = newPrimDept;
                                                }
                                                if(parsedEditRecord.RequirementsStatus != newRequirementsStatus){
                                                    backupRec.RequirementsStatus = newRequirementsStatus;
                                                }
                                                if(parsedEditRecord.QaStatus != newQAStatus){
                                                    backupRec.QaStatus = newQAStatus;
                                                }
                                                if(parsedEditRecord.QAOwnerId != newQAOwnerId){
                                                    backupRec.QAOwnerId = newQAOwnerId;
                                                    backupRec.QAOwner = newQAOwnerName;
                                                }
                                                if(parsedEditRecord.EstimatedQAHours != newEstimatedQAHours){

                                                    if(selectedView == 'Sprint Month Kanban'){
                                                        let sprintDateAsDate = new Date(backupRec.SprintDate);
                                                        let parsedSprintDate = (sprintDateAsDate.getMonth() + 1).toString() + '/' + (sprintDateAsDate.getDate() + 1).toString() + '/' +  (sprintDateAsDate.getFullYear()).toString();
                                                        if(parsedSprintDate == lastSprintWeek){
                                                            backupRec.EstimatedQAHours = newEstimatedQAHours;
                                                        }

                                                    }else if(selectedView == 'Sprint Month Kanban'){
                                                        let lastSprintMonth = lastSprintWeek.split('/');
                                                        let parsedSprintMonthString = lastSprintMonth[2] + '-' + lastSprintMonth[0].padStart(2, '0') + '-01';
                                                        if(backupRec.SprintDate == parsedSprintMonthString){
                                                            backupRec.EstimatedQAHours = newEstimatedQAHours;
                                                        }
        
                                                    }else if(selectedView == 'Sprint Quarter Kanban'){
                                                        let lastSprintWeekSplit = lastSprintWeek.split('/');
                                                        let lastSprintQuarterName = this.getQuarterFromMonth(lastSprintWeekSplit[0]);
                                                        if(backupRec.SprintDate == lastSprintQuarterName){
                                                            backupRec.EstimatedQAHours = newEstimatedQAHours;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if(isChanged){
                        component.set('v.KanbanRecords', allKanbanRecs);
                        component.set('v.KanbanRecordsBackup', allKanbanRecsBackup);
                    }


                }
            }else{
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                "title": "Error!",
                "message": "No Case is selected",
                "type": 'Error'
                });
                toastEvent.fire();
            }
        }catch(error){
            console.error('Handle Edit Error: ', error);
        }
    },

    roundToNearestFourth: function(numberToRound){
        let roundedNumber;
        //To round it to nearest .00, .25, .50, .75
        if(numberToRound){
            let floorNumber = Math.floor(numberToRound)
            let remainder = numberToRound - floorNumber;
            if(remainder < 0.125){
                roundedNumber = floorNumber;
            }else if(remainder < 0.375){
                roundedNumber = floorNumber + 0.25;
            }else if(remainder < 0.625){
                roundedNumber = floorNumber + 0.50;
            }else if(remainder < 0.825){
                roundedNumber = floorNumber + 0.75;
            }else{
                roundedNumber = floorNumber + 1;
            }
        }else{
            roundedNumber = 0;
        }
        return roundedNumber;
    },    

    copyNewKanbanObj: function(kanbanData){
        let newObj = new Object();
        newObj.CaseId = kanbanData.CaseId;
        newObj.CaseNumber = kanbanData.CaseNumber;
        newObj.Status = kanbanData.Status;
        newObj.Subject = kanbanData.Subject;
        newObj.SubmittedDate = kanbanData.SubmittedDate;
        newObj.DaysCaseOpen = kanbanData.DaysCaseOpen;
        newObj.Contact = kanbanData.Contact;
        newObj.ContactId = kanbanData.ContactId;
        newObj.Owner = kanbanData.Owner;
        newObj.OwnerId = kanbanData.OwnerId;
        newObj.sortDueDate = kanbanData.sortDueDate;
        newObj.RequestType = kanbanData.RequestType;
        newObj.SprintWeeks = kanbanData.SprintWeeks;
        newObj.StartDate = kanbanData.StartDate;
        newObj.PrimaryDepartment = kanbanData.PrimaryDepartment;
        newObj.Type = kanbanData.Type;
        if(kanbanData.SprintDate){
            newObj.SprintDate = kanbanData.SprintDate;
        }
        return newObj;
    },

    createSprintWeeks: function(newStartDate, newDueDate){
        let sprintWeeks;
        let days = 86400000;
        
        if(newStartDate){
            //get first sprint week
            let startDate = new Date(newStartDate);
            let daysBack = 0;
            let dayOfTheWeek;
            let firstSprintWeekMonday;
            do{
                firstSprintWeekMonday = new Date(startDate - (daysBack * days));
                dayOfTheWeek = firstSprintWeekMonday.getDay();
                daysBack++;
                if(daysBack > 6){
                    break;
                }
            }while(dayOfTheWeek != 1){
                let dd = String(firstSprintWeekMonday.getDate());
                let mm = String(firstSprintWeekMonday.getMonth() + 1);
                let yyyy = firstSprintWeekMonday.getFullYear();
                sprintWeeks =  mm + '/' + dd + '/' + yyyy;
            }

        }

        let sprintWeekString;
        let entireSprintWeekString = '';

        if(newStartDate && newDueDate){
            //loop weeks 
            let iterableSprintWeek = new Date(sprintWeeks);
            let dueDate = new Date(newDueDate);
            let counter = 0;
            while(iterableSprintWeek < dueDate){
                sprintWeekString = this.formatDateForSprintWeek(iterableSprintWeek);
                entireSprintWeekString += sprintWeekString + ';';
                iterableSprintWeek = new Date(iterableSprintWeek - (-7 * days));
                counter++;
                if(counter == 20){
                    break;
                }
            }

            if(entireSprintWeekString.length > 0){
                entireSprintWeekString = entireSprintWeekString.substring(0, entireSprintWeekString.length - 1);
                sprintWeeks = entireSprintWeekString;
            }
        }

        return sprintWeeks;

    },

    getQuarterFromMonth: function(monthNumber){

        let quarterName;
        switch(monthNumber){
            case '1':
            case '2':
            case '3':
                quarterName = 'Q1';
                break;
            case '4':
            case '5':
            case '6':
                quarterName = 'Q2';
                break;

            case '7':
            case '8':
            case '9':
                quarterName = 'Q3';
                break;

            case '10':
            case '11':
            case '12':
                quarterName = 'Q4';
                break;

            default: 
                quarterName = 'N/A';
        }


        return quarterName;
    }
})