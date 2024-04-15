import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import hasCreateProjTeamMemberPermission from '@salesforce/customPermission/Create_Internal_Project_Team_Member_Custom_Permission';
import hasEditForecastTablePermission from '@salesforce/customPermission/Edit_Forecasts_On_Forecast_Tables_CP';

import getForecastTableData from '@salesforce/apex/ProjectForecastingTableController.getForecastTableData';
import upsertForecasts from '@salesforce/apex/ProjectForecastingTableController.upsertForecastFromProjectForecastTable';
import getPlaceholderRoles from '@salesforce/apex/ProjectForecastingTableController.getPlaceholderRoles';
import createPlaceholder from '@salesforce/apex/ProjectForecastingTableController.createPlaceholder';
import getWorkingDaysBetweenTwoDates from '@salesforce/apex/ProjectForecastingTableController.calculateWorkingDaysBetweenTwoDates';
import swapPlaceholderForUser from '@salesforce/apex/ProjectForecastingTableController.replacePlaceholderWithUser';
import getCurrentlyAllocatedHoursForDateRange from '@salesforce/apex/ProjectForecastingTableController.getCurrentAllocationForDateRange';

import getProjBillRates from '@salesforce/apex/InternalProjTeamMemberLWCController.getProjectBillingRatesForAssignment';
import getCreatedProjectTeamMemberName  from '@salesforce/apex/InternalProjTeamMemberLWCController.createProjectTeamMemberName';
import { CurrentPageReference } from 'lightning/navigation'

import PROJECT_NAME from '@salesforce/schema/Project__c.Name';
import PROJECT_START_DATE from '@salesforce/schema/Project__c.Start_Date__c';
import PROJECT_END_DATE from '@salesforce/schema/Project__c.Planned_Close_Date__c';
import PEOPLESOFT_PROJ_ID from '@salesforce/schema/Project__c.PeopleSoft_Project_ID__c';
import PROJECT_STATUS from '@salesforce/schema/Project__c.Project_Status__c';
import PROJECT_ACCOUNT_ID from '@salesforce/schema/Project__c.Account__c';
import LEV_REMAINING_FORECASTED_BUDGET from '@salesforce/schema/Project__c.Remaining_Forecasted_Rev__c';
import LEV_REMAINING_FORECASTED_HOURS from '@salesforce/schema/Project__c.Remaining_Forecasted_Hrs__c';
import LEV_BUDGET_REMAINING from '@salesforce/schema/Project__c.Opportunity_Remaining_Amount__c';
import LEV_REMAINING_HOURS from '@salesforce/schema/Project__c.Remaining_Hours__c';

const ALLOCATION_TYPES = [
    { label: 'Hours/Week', value: 'hoursPerWeek' },
    { label: 'Total Hours', value: 'totalHours' }
    
];

const SET_ALLOCATION_TYPES = [
    { label: 'By Date Range', value: 'byDateRange' },
    { label: 'Inline Edit', value: 'inlineEdit' }
];

const TABLE_VIEW_TYPES = [
    { label: 'Weekly', value: 'Weekly' },
    { label: 'Monthly', value: 'Monthly' }
];

export default class ForecastingTable extends NavigationMixin(LightningElement) {

    @api recordId;
    dataIsReady = false;
    projectNameValue;
    projectAllocationTitle;

    projectStartDateValue;
    projectEndDateValue;
    projectPeoplesoftId;
    projectStatus;
    projectAccountId;

    levRemainingForecastedBudget = 0;
    levRemainingForecastedHours = 0;
    levBudgetRemaining = 0;
    levHoursRemaining = 0;

    activeProjectStatusList = ['Active', 'In Progress', 'On Hold', 'Not Started'];

    forecastingChartTitle;

    displayForecastTable = false;
    openForecastEntryModal = false;

    allocationSetTypesList = SET_ALLOCATION_TYPES;
    allocationSetTypeSelected = 'byDateRange';
    disableInlineAllocationEdit = true;

    tableViewTypesList = TABLE_VIEW_TYPES;
    tableViewTypeSelected = 'Weekly';

    allocationTypesList = ALLOCATION_TYPES;
    selectedAllocationType = 'hoursPerWeek';
    setAllocationByHoursPerDay = true;
    setAllocationByTotalHours = false;
    allocationTypeHelpText = 'Hours/Day';
    allocationTableData = {};
    allocationTableDataCOPY = {};
    forecastTableDataResults;

    forecastDataTableStartRange = null;
    forecastDateTableEndRange = null;

    setAllocationFromDate;
    setAllocationToDate;

    clickedRowIndex;
    clickedColumnIndex;

    setAllocationModalHeader;

    setAllocationDayCount = 5;
    allocationByHourNumber = 0;

    placeholderRoleMap = new Map();
    
    scrollLeftPositionStyle = "left:189px";

    get isCreateNewTeamMemberEnabled(){
        return hasCreateProjTeamMemberPermission;
    }

    get isForecastTableEditEnabled(){
        return hasEditForecastTablePermission;
    }
    

    /*************** Wired Methods *************/
    /*@wire(getRecord, { recordId: '$recordId', fields: [PROJECT_NAME], optionalFields: [PROJECT_START_DATE, PROJECT_END_DATE, PEOPLESOFT_PROJ_ID, PROJECT_STATUS, PROJECT_ACCOUNT_ID, 
                                                                                        LEV_REMAINING_FORECASTED_BUDGET, LEV_REMAINING_FORECASTED_HOURS, LEV_BUDGET_REMAINING, LEV_REMAINING_HOURS]})
    project({error, data}){
        if(error){
            console.log('ERROR');
            console.log('Record ID: ', this.recordId);
        }else if(data){
            console.log('data: ', data);
            this.projectNameValue = data.fields.Name.value;
            this.projectAllocationTitle = 'Allocated hours for ' + data.fields.Name.value;
            this.forecastingChartTitle = 'Forecasting for ' + this.projectNameValue;
            this.projectPeoplesoftId = data.fields.PeopleSoft_Project_ID__c.value;
            this.projectStatus = data.fields.Project_Status__c.value;
            this.projectAccountId = data.fields.Account__c.value;

            this.levRemainingForecastedBudget = data.fields.Remaining_Forecasted_Rev__c.value;
            this.levRemainingForecastedHours = data.fields.Remaining_Forecasted_Hrs__c.value;
            this.levBudgetRemaining = data.fields.Opportunity_Remaining_Amount__c.value;
            this.levHoursRemaining = data.fields.Remaining_Hours__c.value;


            if(this.activeProjectStatusList.includes(this.projectStatus)){

                let todaysDate = new Date();
                todaysDate = this.formatDate(todaysDate);
                if(todaysDate >= data.fields.Planned_Close_Date__c.value){
                    //If the current date is past the end date then use the project start date anyways.
                    this.projectStartDateValue = data.fields.Start_Date__c.value;
                    this.forecastDataTableStartRange = data.fields.Start_Date__c.value;
                }else{
                    this.projectStartDateValue = todaysDate;
                    this.forecastDataTableStartRange = todaysDate;
                }
            }else{
                this.projectStartDateValue = data.fields.Start_Date__c.value;
                this.forecastDataTableStartRange = data.fields.Start_Date__c.value;
            }
            this.projectEndDateValue = data.fields.Planned_Close_Date__c.value;
            this.forecastDateTableEndRange = data.fields.Planned_Close_Date__c.value;

            this.dataIsReady = true;
        }
    }*/
    _getProjectDataResponse;

    @wire(getRecord, { recordId: '$recordId', fields: [PROJECT_NAME], optionalFields: [PROJECT_START_DATE, PROJECT_END_DATE, PEOPLESOFT_PROJ_ID, PROJECT_STATUS, PROJECT_ACCOUNT_ID, 
        LEV_REMAINING_FORECASTED_BUDGET, LEV_REMAINING_FORECASTED_HOURS, LEV_BUDGET_REMAINING, LEV_REMAINING_HOURS]})
    project(projectDataResponse){
        this._getProjectDataResponse = projectDataResponse;
        let error = projectDataResponse && projectDataResponse.error;
        let data = projectDataResponse && projectDataResponse.data;
        //console.log('projectDataResponse Error', error);
        //console.log('projectDataResponse Data', data);
        if(projectDataResponse.error){
            console.log('Project Data ResponseERROR');
            console.log('Record ID: ', this.recordId);
        }else if(data){
            console.log('Project Data Response data: ', data);
            this.projectNameValue = data.fields.Name.value;
            this.projectAllocationTitle = 'Allocated hours for ' + data.fields.Name.value;
            this.forecastingChartTitle = 'Forecasting for ' + this.projectNameValue;
            this.projectPeoplesoftId = data.fields.PeopleSoft_Project_ID__c.value;
            this.projectStatus = data.fields.Project_Status__c.value;
            this.projectAccountId = data.fields.Account__c.value;

            this.levRemainingForecastedBudget = data.fields.Remaining_Forecasted_Rev__c.value;
            this.levRemainingForecastedHours = data.fields.Remaining_Forecasted_Hrs__c.value;
            this.levBudgetRemaining = data.fields.Opportunity_Remaining_Amount__c.value;
            this.levHoursRemaining = data.fields.Remaining_Hours__c.value;


            if(this.activeProjectStatusList.includes(this.projectStatus)){

                let todaysDate = new Date();
                todaysDate = this.formatDate(todaysDate);
                if(todaysDate >= data.fields.Planned_Close_Date__c.value){
                    //If the current date is past the end date then use the project start date anyways.
                    this.projectStartDateValue = data.fields.Start_Date__c.value;
                    this.forecastDataTableStartRange = data.fields.Start_Date__c.value;
                }else{
                    this.projectStartDateValue = todaysDate;
                    this.forecastDataTableStartRange = todaysDate;
                }
            }else{
                this.projectStartDateValue = data.fields.Start_Date__c.value;
                this.forecastDataTableStartRange = data.fields.Start_Date__c.value;
            }
            this.projectEndDateValue = data.fields.Planned_Close_Date__c.value;
            this.forecastDateTableEndRange = data.fields.Planned_Close_Date__c.value;

            this.dataIsReady = true;
        }
    }

    @wire(getForecastTableData, {projectId: '$recordId', startDate: '$forecastDataTableStartRange', endDate: '$forecastDateTableEndRange', timePeriodView: '$tableViewTypeSelected'})
    forecastTableData(result){
        this.forecastTableDataResults = result;
        if(result.error){
            console.log('ERROR: ', result.error);
            console.log('Record ID: ', this.recordId);
            this.displayForecastTable = true;
        }else if(result.data){
            console.log('data: ', result.data);
            this.allocationTableData = result.data;

            this.cloneForecastTableDate(this.allocationTableData);
            /*this.allocationTableDataCOPY.levRemainingForecastedHours = this.allocationTableData.levRemainingForecastedHours;
            this.allocationTableDataCOPY.budgetHoursDifference = this.allocationTableData.budgetHoursDifference;
            this.allocationTableDataCOPY.levHoursRemaining = this.allocationTableData.levHoursRemaining;
            this.allocationTableDataCOPY.levBudgetRemaining = this.allocationTableData.levBudgetRemaining;
            this.allocationTableDataCOPY.levRemainingForecastedBudget = this.allocationTableData.levRemainingForecastedBudget;
            this.allocationTableDataCOPY.budgetAmountDiffernce = this.allocationTableData.budgetAmountDiffernce;*/

            this.levRemainingForecastedBudget = result.data.levRemainingForecastedBudget;
            this.levRemainingForecastedHours = result.data.levRemainingForecastedHours;
            this.levBudgetRemaining = result.data.levBudgetRemaining;
            this.levHoursRemaining = result.data.levHoursRemaining;

            this.displayForecastTable = true;
        }else{
            console.log('No Data or Error Returned');
            //this.displayForecastTable = true;
        }
    }

    @wire(getProjBillRates,{projectId: '$recordId'})
    wiredProjBillRates({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            for(var i=0; i<data.length; i++)  {
                this.billingRateItems = [...this.billingRateItems ,{value: data[i].Id , label: data[i].Name + ' - $' + data[i].Hourly_Rate__c} ];                                 
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getPlaceholderRoles)
    wiredPlaceholderRoles({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            for(var i=0; i<data.length; i++)  {
                this.placeholderRoleItems = [...this.placeholderRoleItems ,{value: data[i].Id , label: data[i].Name}];
                this.placeholderRoleMap.set(data[i].Id, data[i].Name);                   
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    renderedCallback() {
        console.log('Rendered Callback');
        try{
            let columnWidth = this.refs.usersColumn.clientWidth;
            this.scrollLeftPositionStyle = "left:" + columnWidth + "px";
        }catch(e){
            console.error('Handled Callback Error', e);
        }
    }

    handleStartDateChange(event){
        this.displayForecastTable = false;
        this.forecastDataTableStartRange = event.target.value;
        refreshApex(this.allocationTableData);
    }

    handleEndDateChange(event){
        this.displayForecastTable = false;
        this.forecastDateTableEndRange = event.target.value;
        refreshApex(this.allocationTableData);
    }

    handleTableColumnClick(event){

        console.log('Clicked on Table');
        let columnIndex = event.currentTarget.dataset.index;
        let rowIndex = event.currentTarget.dataset.rowIndex;
        this.clickedColumnIndex = columnIndex;
        this.clickedRowIndex = rowIndex;

        //Set Allocation To and From Dates from initial click to set it as the single week that the clicked cell represents
        this.setAllocationFromDate = this.allocationTableData.projectWeekStartDateList[columnIndex];

        //Format Start Date
        let startDateArray = this.setAllocationFromDate.split("-");
        let year = startDateArray[0];
        let month = parseInt(startDateArray[1], 10) - 1;
        let day = startDateArray[2];
        let fromDate = new Date(year, month, day);

        //Create To Date to be 6 days from Start Date
        let toDate = new Date(fromDate);
        toDate.setDate(fromDate.getDate() + 6);

        this.setAllocationToDate = this.formatDate(toDate);

        if(this.allocationSetTypeSelected == 'byDateRange'){
            console.log('Clicked Column Index: ', this.clickedColumnIndex + ' Clicked Row Index: ', this.clickedRowIndex);
            this.getCellData(this.clickedColumnIndex, this.clickedRowIndex, 'Open Set Allocation Modal');
        }else if(this.allocationSetTypeSelected == 'inlineEdit'){
            let uniqueId = null;
            uniqueId = event.currentTarget.dataset.uniqueRowId;
            console.log('Event Unique Row Id: ', event.currentTarget.dataset.uniqueRowId);
            if(uniqueId != null){
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.focus();
            }
        }
    }

    getCellData(columnIndex, rowIndex, context){
        console.log('Get Cell Data: ', context);
        if(context == 'Open Set Allocation Modal'){

            this.currentlySelectedAllocationRollupsIndex = columnIndex;
            
            let teamMemberName = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberName;
            this.setAllocationModalHeader = teamMemberName;
            
            let hoursForAllocation = this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData;
            if(hoursForAllocation == null || hoursForAllocation == '' || hoursForAllocation == undefined || hoursForAllocation == 0){
                this.allocationByHourNumber = 0.00;
                this.currentlyAllocatedHours = 0;
            }else{
                this.allocationByHourNumber = this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData;
                this.currentlyAllocatedHours = this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData;
            }
            

            if(this.allocationSetTypeSelected == 'byDateRange' && this.tableViewTypeSelected == 'Weekly' && hasEditForecastTablePermission == true){
                console.log('Selected Project Team Member: ', this.allocationTableData.teamMemberDataWrapperList[rowIndex]);

                if(this.allocationTableData.teamMemberDataWrapperList[rowIndex].contactRecordTypeName != 'Employee'){
                    let evt = new ShowToastEvent({
                        title: "Non Employee Contact Record",
                        message: "Forecasts should only be input for Employee Contacts.. " + this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberName + "\'s Contact Record is a " + this.allocationTableData.teamMemberDataWrapperList[rowIndex].contactRecordTypeName + " Record Type.",
                        variant: "error"
                    });
                    this.dispatchEvent(evt);
                }else{
                    this.openForecastEntryModal = true;
                }
            }
        }
    }

    handleAllocationSetTypeChange(event){
        //By Date Range or Inline editting of forecasts
        this.allocationSetTypeSelected = event.target.value;
        this.disableInlineAllocationEdit = !this.disableInlineAllocationEdit;
        console.log('Allocation Set Type Selected Value: ', this.allocationSetTypeSelected);
    }

    handleViewTypeChange(event){
        this.tableViewTypeSelected = event.target.value;
        console.log('View Type Selected Value: ', this.tableViewTypeSelected);
    }

    forecastHoursChange(event){
        try{

            let rowIndex = this.clickedRowIndex;
            let columnIndex = this.clickedColumnIndex; 
            let projTeamMemberName = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberName;

            let columnDate = this.allocationTableData.projectWeekStartDateList[columnIndex];

            let projectAllocationHours = this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData;  

        }catch(error){
            console.error('Forecast Hours Change from Modal ERROR: ', error);
        }
    }


    projectAllocationFocusHandle(event){
        try{
            if(this.disableInlineAllocationEdit){
                let uniqueId = event.currentTarget.dataset.uniqueId;
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();

                return;
            }
            console.log('Focus Handle');
            let projTeamMember = JSON.parse(JSON.stringify(event.currentTarget.dataset.projTeamMember));
            let allocationWeeklyRollups = JSON.parse(JSON.stringify(event.currentTarget.dataset.allocationWeeklyRollups));
            let projectAllocationHours = event.target.value;

            //this.refs.projAllocationBubble.classList.add('focusedProjectAllocationBubble');
            let uniqueId2 = event.currentTarget.dataset.uniqueId;
            let uniqueParentId = event.currentTarget.dataset.uniqueParentId;
            let allocationInputField2 = this.template.querySelector(`[data-unique-id="${uniqueId2}"]`);
            //allocationInputField2.classList.remove('unfocusedProjectAllocationBubble');
            this.template.querySelector(`[data-unique-id="${uniqueId2}"]`).className = 'focusedProjectAllocationBubble';
            this.template.querySelector(`[data-unique-id="${uniqueId2}"]`).classList.remove('invisibleStyle');
            //allocationInputField2.className = 'focusedProjectAllocationBubble';


            this.template.querySelector(`[data-unique-id="${uniqueParentId}"]`).className = 'focusedProjectAllocationBubble';

            let columnIndex = event.currentTarget.dataset.index;
            let rowIndex = event.currentTarget.dataset.rowIndex;

            /** Check if in the past, if not then blur immediately */
            const jsStartDate = this.getJSDateFromText(this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationWeekStartDate);

            //get first date of week of start of allocation range
            const allocationStartDate = jsStartDate.getDate();
            const allocationStartDay = jsStartDate.getDay();

            const firstDayOfAllocationWeek = new Date(jsStartDate.setDate(allocationStartDate - allocationStartDay));

            // get last date of week
            const lastDayOfAllocationWeek = new Date(firstDayOfAllocationWeek);
            lastDayOfAllocationWeek.setDate(lastDayOfAllocationWeek.getDate() + 6);

            //console.log('First Day of Allocation Week: ', firstDayOfAllocationWeek);
            //console.log('Last Day of Allocation Week: ', lastDayOfAllocationWeek);
            const todaysDate = new Date();
            //console.log('Todays Date: ', todaysDate);

            if(lastDayOfAllocationWeek < todaysDate){
                console.error('Past forecasts cannot be edited in order to preserve historical data.');
                /*let evt = new ShowToastEvent({
                    title: "Forecast Not Updated",
                    message: "Past forecasts cannot be edited in order to preserve historical data.",
                    variant: "error"
                });
                this.dispatchEvent(evt);*/
                let uniqueId = event.currentTarget.dataset.uniqueId;
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();

                return;
            }

            if(this.tableViewTypeSelected == 'Monthly'){
                console.error('Forecasts cannot be editted in the Monthly View.');
                /*let evt = new ShowToastEvent({
                    title: "Forecast Not Updated",
                    message: "Forecasts cannot be editted in the Monthly View.",
                    variant: "error"
                });
                this.dispatchEvent(evt);*/
                let uniqueId = event.currentTarget.dataset.uniqueId;
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();

                return;
            }

            if(this.allocationTableData.teamMemberDataWrapperList[rowIndex].hasOutdatedRateAssigned == true){
                let evt = new ShowToastEvent({
                    title: "Forecast Not Updated",
                    message: "This team member has an outdated billing rate assigned, as the Products have been changed due to early project creation. Update the assigned billing rate before creating or editing forecasts for this team member.",
                    variant: "error"
                });
                this.dispatchEvent(evt);

                let uniqueId = event.currentTarget.dataset.uniqueId;
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();

                return;
            }

            if(this.allocationTableData.teamMemberDataWrapperList[rowIndex].contactRecordTypeName != 'Employee'){
                let evt = new ShowToastEvent({
                    title: "Non Employee Contact Record",
                    message: "Forecasts should only be input for Employee Contacts.. " + this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberName + "\'s Contact Record is a " + this.allocationTableData.teamMemberDataWrapperList[rowIndex].contactRecordTypeName + " Record Type.",
                    variant: "error"
                });
                this.dispatchEvent(evt);

                let uniqueId = event.currentTarget.dataset.uniqueId;
                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();

                return;
            }


        }catch(error){
            console.error('Focus Error: ', error);
        }
    }

    /************************************ Project Forecasting Edits in In Line editting *******************************************/
    budgetInfoClass = 'slds-show';
    showBudgetaryInfo = true;
    projectAllocationBlurHandle(event){
        try{
            let projectAllocationHours = event.target.value;
            if(projectAllocationHours == null || projectAllocationHours == '' || projectAllocationHours == undefined){
                projectAllocationHours = 0;
                //console.log('allocation is null');
            }
            let columnIndex = event.currentTarget.dataset.index;
            let rowIndex = event.currentTarget.dataset.rowIndex;

            let uniqueId2 = event.currentTarget.dataset.uniqueId;
            let uniqueParentId = event.currentTarget.dataset.uniqueParentId;
            let allocationInputField2 = this.template.querySelector(`[data-unique-id="${uniqueId2}"]`);
            //console.log('Allocation InputField: ', allocationInputField2);
            //allocationInputField2.classList.remove('focusedProjectAllocationBubble');
            this.template.querySelector(`[data-unique-id="${uniqueId2}"]`).className = 'inputBackgroundUnfocused';

            if(projectAllocationHours == 0){
                this.template.querySelector(`[data-unique-id="${uniqueId2}"]`).className = 'invisibleStyle';
                this.template.querySelector(`[data-unique-id="${uniqueParentId}"]`).className = 'invisibleStyle';
            }

            //this.refs.budgetInfo.classList.add('slds-hidden');
            this.showBudgetaryInfo = false;
            

            //console.log('After Blur Value: ', projectAllocationHours);
            //console.log('Before Change Hours: ', this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData);

            
            //this.budgetInfoClass = 'slds-hide';
            let oldHours = this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData;
            //console.log('Data: ', this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex]);
            //console.log('Team Member Data: ', this.allocationTableData.teamMemberDataWrapperList[rowIndex]);
            //console.log('ALL Data: ', this.allocationTableData);
            let assignedBillRateHourlyRate = this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].projectTeamMemberAssignedBillingRateHourlyRate;
            let remainingForecastedHours = this.allocationTableDataCOPY.levRemainingForecastedHours; 
            let projectAllocationHoursNumber = Number(projectAllocationHours);
            let tempRemainingForecastedHours = (remainingForecastedHours - oldHours) + projectAllocationHoursNumber;

            /*** Set Lev Remaining Forecasted Hours & Hours Difference ***/
            this.allocationTableDataCOPY.levRemainingForecastedHours = tempRemainingForecastedHours;
            this.allocationTableDataCOPY.budgetHoursDifference = this.allocationTableDataCOPY.levHoursRemaining - tempRemainingForecastedHours;

            /*** Set Lev Remaining Forecasted Budget & $ Difference ***/
            this.allocationTableDataCOPY.levRemainingForecastedBudget = (this.allocationTableDataCOPY.levRemainingForecastedBudget - (oldHours * assignedBillRateHourlyRate)) + (projectAllocationHoursNumber * assignedBillRateHourlyRate);            
            this.allocationTableDataCOPY.budgetAmountDiffernce = this.allocationTableDataCOPY.levBudgetRemaining - this.allocationTableDataCOPY.levRemainingForecastedBudget;

            /*** Set Allocation Hours for Table ***/
            this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData = projectAllocationHoursNumber;

            /*** Set Project Allocation Summary ****/
            this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].projectTeamMemberTotalProjectAllocationHours = (this.allocationTableDataCOPY.teamMemberDataWrapperList[rowIndex].projectTeamMemberTotalProjectAllocationHours - oldHours) + projectAllocationHoursNumber;


            this.showBudgetaryInfo = true;


            //console.log('tempRemainingForecastedHours: ', tempRemainingForecastedHours);

            //console.log('this.allocationTableDataCOPY.levRemainingForecastedHours AFTER: ', this.allocationTableDataCOPY.levRemainingForecastedHours);


            if(this.allocationSetTypeSelected == 'inlineEdit' && projectAllocationHours != this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData){

                /***************** START Check if Editting Past Forecasts *********************/
                const jsStartDate = this.getJSDateFromText(this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationWeekStartDate);

                //get first date of week of start of allocation range
                const allocationStartDate = jsStartDate.getDate();
                const allocationStartDay = jsStartDate.getDay();

                const firstDayOfAllocationWeek = new Date(jsStartDate.setDate(allocationStartDate - allocationStartDay));

                // get last date of week
                const lastDayOfAllocationWeek = new Date(firstDayOfAllocationWeek);
                lastDayOfAllocationWeek.setDate(lastDayOfAllocationWeek.getDate() + 6);

                //console.log('First Day of Allocation Week: ', firstDayOfAllocationWeek);
                //console.log('Last Day of Allocation Week: ', lastDayOfAllocationWeek);
                const todaysDate = new Date();
                //console.log('Todays Date: ', todaysDate);

                if(lastDayOfAllocationWeek < todaysDate){
                    console.error('Past forecasts cannot be edited in order to preserve historical data.');
                    let evt = new ShowToastEvent({
                        title: "Forecast Not Updated",
                        message: "Past forecasts cannot be edited in order to preserve historical data.",
                        variant: "error"
                    });
                    this.dispatchEvent(evt);

                    //refreshApex(this._getProjectDataResponse);
                    return refreshApex(this.forecastTableDataResults);

                }else{

                    let allocationWrapper = {};
                    allocationWrapper.contactId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberContactId;
                    allocationWrapper.contactCognizantEmployeeId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberEmployeeCognizantId;
                    allocationWrapper.isPlaceholderEmployee = this.allocationTableData.teamMemberDataWrapperList[rowIndex].isPlaceholderEmployee;
                    allocationWrapper.projectId = this.recordId;
                    allocationWrapper.projectName = this.projectNameValue;
                    allocationWrapper.projectPeoplesoftId = this.projectPeoplesoftId;
                    allocationWrapper.allocationRangeStartDate = this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationWeekStartDate;
                    allocationWrapper.allocationRangeEndDate = null;
                    allocationWrapper.hoursForAllocation = projectAllocationHours;
                    allocationWrapper.allocationEntryMethod = 'onBlur';
                    allocationWrapper.projectTeamMemberId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberId;
                    allocationWrapper.projectTeamMemberAssignedBillingRateId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberBillRateId;
                    allocationWrapper.projectTeamMemberAssignedBillingRateName = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberAssignedBillingRateName;
                    allocationWrapper.contactIsLevEmployeeBoolean = this.allocationTableData.teamMemberDataWrapperList[rowIndex].IsLevEmployee;
                    upsertForecasts({
                        wrapper: allocationWrapper
                    })
                    .then(result =>{
                        //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
        
                        //refreshApex(this._getProjectDataResponse);
                        return refreshApex(this.forecastTableDataResults);
                        
                    })
                    .catch(error =>{
                        console.error('Upsert Forecast Allocation ERROR: ', error);
                    })
                }

            }else if(projectAllocationHours != this.allocationTableData.teamMemberDataWrapperList[rowIndex].allocationWeeklyRollups[columnIndex].projectAllocationData){
                //refreshApex(this._getProjectDataResponse);
                return refreshApex(this.forecastTableDataResults);
            }

            

            //console.log('Blur Value: ', projectAllocationHours);
        }catch(error){
            console.error('Blur Error: ', error);
            //refreshApex(this._getProjectDataResponse);
            return refreshApex(this.forecastTableDataResults);
        }

    }

    handleEnter(event){
        try{
            console.log('event.currentTarget.dataset.index: ', event.currentTarget.dataset.uniqueId);
            let uniqueId = event.currentTarget.dataset.uniqueId;
            if(event.keyCode === 13){

                let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
                allocationInputField.blur();
                
            }
        }catch(e){
            console.error('ERROR e', e);
        }
    }


    scrollToCurrentDate(event){
        try{
            let weekColumnUniqueId = 'Jul 30, 2023 - Aug 5, 2023';
            let weekDateRangeColumn = this.template.querySelector(`[data-column-unique-id="${weekColumnUniqueId}"]`);
            weekDateRangeColumn.scrollIntoView();
        }catch(e){
            console.error('ERROR e', e);
        }
    }

    scrollRight(event){
        try{
            this.refs.forecastTable.scrollLeft += 100;
        }catch(e){
            console.error('ERROR e', e);
        }
    }

    scrollLeft(event){
        try{
            this.refs.forecastTable.scrollLeft -= 100;
            //console.log('Table Header Ref: ', this.refs.usersColumn.clientWidth);
        }catch(e){
            console.error('ERROR e', e);
        }
    }

    expandTableBoolean = false;

    expandTable(event){

        try{
            console.log('this.refs.forecastTable: ', this.refs.forecastTable);
            if(this.expandTableBoolean == false){
                this.refs.forecastTable.classList.remove('tableContained');

                this.refs.scrollRightButton.classList.remove('scrollRightButtonStyle');
                this.refs.scrollLeftButton.classList.remove('scrollLeftButtonStyle');
                this.refs.scrollRightButton.classList.add('scrollRightExpandedButtonStyle');
                this.refs.scrollLeftButton.classList.add('scrollLeftExpandedButtonStyle');

                this.expandTableBoolean = true;
                console.log('Was false');
            }else{
                this.refs.forecastTable.classList.add('tableContained');

                this.refs.scrollRightButton.classList.remove('scrollRightExpandedButtonStyle');
                this.refs.scrollLeftButton.classList.remove('scrollLeftExpandedButtonStyle');
                this.refs.scrollRightButton.classList.add('scrollRightButtonStyle');
                this.refs.scrollLeftButton.classList.add('scrollLeftButtonStyle');

                this.expandTableBoolean = false;
                console.log('Was true');
            }
            
        }catch(e){
            console.error('ERROR e', e);
        }
    }

    /*********************** Create New Project Team Member Logic **************************/

    /**** Add New Project Team Member variables ****/
    openAddProjectTeamMemberModal = false;
    displayCreateProjTeamMemberForm = true;
    createProjTeamMemberFormIsLoading = false;
    createNewProjectTeamMemberErrorMessage = false;
    billingRateItems = [];
    chosenBillingRate = '';

    clickAddProjectTeamMemberHandle(event){
        this.createProjTeamMemberFormIsLoading = false;
        this.createNewProjectTeamMemberError = false;
        this.createNewProjectTeamMemberErrorMessage = '';
        this.openAddProjectTeamMemberModal = true;
        this.chosenBillingRate != '';
        
    }

    onSubmitNewProjectTeamMember(event){
        event.preventDefault();
        this.createProjTeamMemberFormIsLoading = true;
        //this.showCreateProjTeamMemberForm = false;
        //this.displayCreateProjTeamMemberForm = false;
        if(this.chosenBillingRate != '' && this.chosenBillingRate != null && this.chosenBillingRate != undefined){
            console.log('Chosen Value: ', this.chosenBillingRate);
            const fields = event.detail.fields;
            fields.Project__c = this.recordId;
            fields.Assigned_Billing_Rate__c = this.chosenBillingRate;
            getCreatedProjectTeamMemberName({
                contactId : fields.Client_Contact__c,
                projectId : this.recordId})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                console.log('Get Project Team Member Name: ', result);
                this.projectTeamMemberName = result;
                console.log('Fields: ', fields);
                fields.Internal_Project_Team_Member_Name__c = String(this.projectTeamMemberName);
                fields.Account__c = this.projectAccountId;
                this.template.querySelector("lightning-record-edit-form").submit(fields);
                this.showCreateProjTeamMemberForm = true;
                this.isCreateNewTeamMemberModalOpen = false;
                this.displayCreateProjTeamMemberForm = true;
                this.createProjTeamMemberFormIsLoading = false;
                this.closeModal();
                
            })
            .catch(error =>{
                this.createNewProjectTeamMemberError = true;
                this.displayCreateProjTeamMemberForm = true;
                this.createProjTeamMemberFormIsLoading = false;
                this.createNewProjectTeamMemberErrorMessage = error.body.message;
                console.error(error);
            })
        }else{
            this.createNewProjectTeamMemberError = true;
            this.displayCreateProjTeamMemberForm = true;
            this.showCreateProjTeamMemberForm = true;
            this.createNewProjectTeamMemberErrorMessage = 'Must Assign a Billing Rate to Create Project Team Member';
            this.createProjTeamMemberFormIsLoading = false;
            console.error('Must Assign a Billing Rate to Create Project Team Member');
        }
    }

    onSuccessfulCreateNewProjectTeamMember(event){
        this.closeModal();

        const evt = new ShowToastEvent({
            title: "Record Created",
            message: "Internal Project Team Member Created",
            variant: "success"
        });
        this.dispatchEvent(evt);

        this.displayForecastTable = false;
        return refreshApex(this.forecastTableDataResults);
        
    }

    get billingRates() {
        return this.billingRateItems;
    }

    handleCreateNewProjectTeamMemberBillRateChange(event){
        this.createNewProjectTeamMemberError = false;
        this.createNewProjectTeamMemberErrorMessage = '';
        const selectedOption = event.detail.value;
        this.chosenBillingRate = selectedOption;
    }

    handleNewInternalProjectTeamMemberChange(){
        this.createNewProjectTeamMemberError = false;
        this.createNewProjectTeamMemberErrorMessage = '';
    }

    /********************** Create New Placeholder Team Member Logic **************************/
    openAddPlaceholderModal = false;
    createPlaceholderIsLoading = false;
    addPlaceholderError = false;
    addPlaceholderErrorMessage = '';
    placeholderRoleItems = [];
    selectedPlaceholderRole;

    handleAddPlaceholderClick(event){
        this.openAddPlaceholderModal = true;
    }

    onSubmitPlaceholder(event){
        event.preventDefault();
        this.createPlaceholderIsLoading = true;
        if(this.selectedPlaceholderRole != '' && this.selectedPlaceholderRole != null && this.selectedPlaceholderRole != undefined){
            let fields = event.detail.fields;
            fields.Project__c = this.recordId;
            let roleName = this.placeholderRoleMap.get(this.selectedPlaceholderRole);
            console.log('Role Name: ', roleName);
            createPlaceholder({
                contactId : fields.Client_Contact__c,
                projectId : this.recordId,
                projectName: this.projectNameValue,
                placeholderRoleName: roleName,
                productId: this.selectedPlaceholderRole})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                console.log('Submit Placeholder Result: ', result);
                console.log('Placeholder Fields: ', fields);
                fields.Client_Contact__c = result.Client_Contact__c;
                fields.Internal_Project_Team_Member_Name__c = result.Internal_Project_Team_Member_Name__c;
                fields.Assigned_Billing_Rate__c = result.Assigned_Billing_Rate__c;
                fields.Project__c = result.Project__c;
                fields.Is_Placeholder_Team_Member__c = true;
                fields.Account__c = this.projectAccountId;
                this.template.querySelector("lightning-record-edit-form").submit(fields);
                this.addPlaceholderError = false;
                this.createPlaceholderIsLoading = false;
                this.closeModal();
                
            })
            .catch(error =>{
                this.addPlaceholderError = true;
                this.createPlaceholderIsLoading = false;
                this.addPlaceholderErrorMessage = error.body.message;
                console.error(error);
            })
        }else{
            this.addPlaceholderError = true;
            this.addPlaceholderErrorMessage = 'Must Assign a Role for the Placeholder';
            this.createPlaceholderIsLoading = false;
            console.error('Must Assign a Role for the Placeholder');
        }

    }

    onSuccessfulPlaceholderCreation(event){
        this.createPlaceholderIsLoading = false;
        //refreshApex(this._getProjectDataResponse);
        return refreshApex(this.forecastTableDataResults);
    }

    handlePlaceholderRoleChange(event){
        this.addPlaceholderError = false;
        this.selectedPlaceholderRole = event.target.value;
        console.log('Selected Placeholder Role: ', this.selectedPlaceholderRole);
    }

    get placeholderRoles(){
        console.log('Placeholder Roles: ', this.placeholderRoleItems);
        return this.placeholderRoleItems;
    }


    /****************************** Submit Forecast from Date Range Modal *****************************/
    setAllocationByDateRangeError = false;
    setAllocationByDateRangeErrorMessage = '';
    setAllocationModalIsLoading = false;
    currentlyAllocatedHours;
    currentlySelectedAllocationRollupsIndex;
    
    submitForecastAllocation(event){

        try{
            this.setAllocationModalIsLoading = true;

            if(this.allocationByHourNumber != null && this.allocationByHourNumber != '' && this.allocationByHourNumber != undefined && 
            this.setAllocationFromDate != null && this.setAllocationFromDate != '' && this.setAllocationFromDate != undefined && this.setAllocationToDate != null && this.setAllocationToDate != '' && this.setAllocationToDate != undefined){

                let jsStartDate = this.getJSDateFromText(this.setAllocationFromDate);
                let jsEndDate = this.getJSDateFromText(this.setAllocationToDate);
                
                console.log('TEAM MEMBER DETAILS HHERE: ', this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex ]);

                if(this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex].hasOutdatedRateAssigned == false){

                    if(jsStartDate < jsEndDate){

                        /***************** START Check if Editting Past Forecasts *********************/

                        //get first date of week of start of allocation range
                        const jsStartDateObj = this.getJSDateFromText(this.setAllocationFromDate);
                        const allocationStartDate = jsStartDateObj.getDate();
                        const allocationStartDay = jsStartDateObj.getDay();

                        const firstDayOfAllocationWeek = new Date(jsStartDateObj.setDate(allocationStartDate - allocationStartDay));

                        // get last date of week
                        const lastDayOfAllocationWeek = new Date(firstDayOfAllocationWeek);
                        lastDayOfAllocationWeek.setDate(lastDayOfAllocationWeek.getDate() + 6);

                        console.log('First Day of Allocation Week: ', firstDayOfAllocationWeek);
                        console.log('Last Day of Allocation Week: ', lastDayOfAllocationWeek);
                        const todaysDate = new Date();
                        console.log('Todays Date: ', todaysDate);
                        
                        if(lastDayOfAllocationWeek < todaysDate){
                            //If Trying to edit a past Date forecast
                            console.error('Past forecasts cannot be created or edited in order to preserve historical data.');
                            this.setAllocationModalIsLoading = false;
                            this.setAllocationByDateRangeError = true;
                            //Set Error for End Date being before the start date
                            this.setAllocationByDateRangeErrorMessage = 'Past forecasts cannot be created or edited in order to preserve historical data.';
                        /***************** END Check if Editting Past Forecasts *********************/

                        }else{

                            let columnIndex = this.clickedColumnIndex;
                            let rowIndex = this.clickedRowIndex;

                            console.log('submitForecastAllocation 2');
                            /************************ Create the allocationCreationWrapper Object for the apex callout ************************/
                            let allocationWrapper = {};
                            allocationWrapper.contactId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberContactId;
                            allocationWrapper.contactCognizantEmployeeId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberEmployeeCognizantId;
                            allocationWrapper.isPlaceholderEmployee = this.allocationTableData.teamMemberDataWrapperList[rowIndex].isPlaceholderEmployee;
                            allocationWrapper.projectId = this.recordId;
                            allocationWrapper.projectName = this.projectNameValue;
                            allocationWrapper.projectPeoplesoftId = this.projectPeoplesoftId;
                            allocationWrapper.allocationRangeStartDate = this.setAllocationFromDate;
                            allocationWrapper.allocationRangeEndDate = this.setAllocationToDate;
                            allocationWrapper.hoursForAllocation = this.allocationByHourNumber;
                            allocationWrapper.allocationEntryMethod = this.selectedAllocationType;
                            allocationWrapper.projectTeamMemberId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberId;
                            allocationWrapper.projectTeamMemberAssignedBillingRateId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberBillRateId;
                            allocationWrapper.projectTeamMemberAssignedBillingRateName = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberAssignedBillingRateName;
                            allocationWrapper.contactIsLevEmployeeBoolean = this.allocationTableData.teamMemberDataWrapperList[rowIndex].IsLevEmployee;

                            console.log('Allocation Wrapper: ', allocationWrapper);

                            upsertForecasts({
                                wrapper : allocationWrapper
                            })
                            .then(result =>{
                                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                                console.log('submitForecastAllocation START');
                                console.log('Create Forecast Record Result: ', result);
                                this.setAllocationModalIsLoading = false;
                                this.closeModal();
                                
                                //refreshApex(this._getProjectDataResponse);
                                return refreshApex(this.forecastTableDataResults);
                                
                            })
                            .catch(error =>{
                                console.error('Upsert Forecast Allocation ERROR: ', error);
                                this.setAllocationModalIsLoading = false;
                            }) 
                        }
                    }else{
                        console.error('Some error here for Date Range Difference!!!!!');
                        this.setAllocationModalIsLoading = false;
                        this.setAllocationByDateRangeError = true;
                        //Set Error for End Date being before the start date
                        this.setAllocationByDateRangeErrorMessage = 'To Date must be after the From Date';
                    }
                }else{
                    console.error('Error here for Outdated Rate!!!!');
                        this.setAllocationModalIsLoading = false;
                        this.setAllocationByDateRangeError = true;
                        //Set Error for End Date being before the start date
                        this.setAllocationByDateRangeErrorMessage = 'This team member has an outdated billing rate assigned, as the Products have been changed due to early project creation. Update the assigned billing rate before creating or editing forecasts for this team member.';
                }
            }else{
                console.error('Some error here!!!!!');
                this.setAllocationModalIsLoading = false;
                this.setAllocationByDateRangeError = true;

                if(this.allocationByHourNumber == null || this.allocationByHourNumber == '' || this.allocationByHourNumber == undefined){
                    //Set Error Message for Empty Allocated Hours
                    this.setAllocationByDateRangeErrorMessage = 'Allocation Hours must be populated';

                }else if(this.setAllocationFromDate == null || this.setAllocationFromDate == '' || this.setAllocationFromDate == undefined || this.setAllocationToDate == null || this.setAllocationToDate == '' || this.setAllocationToDate == undefined){
                    //Set Error Message for Empty Start or End Date
                    this.setAllocationByDateRangeErrorMessage = 'From Date and To Date must be populated in order to save the forecast entry.';
                }
            }
        }catch(e){
            this.setAllocationModalIsLoading = false;
            console.error('Submit Allocation ERROR: ', e);
        }
    }

    handleAllocationTypeChange(event){

        this.selectedAllocationType = event.detail.value;
        console.log(this.selectedAllocationType);
        

        if(this.selectedAllocationType == 'hoursPerDay'){
            this.allocationTypeHelpText = 'Hours/Day';
            this.setAllocationByHoursPerDay = true;
            this.setAllocationByTotalHours = false;
        }else if(this.selectedAllocationType == 'totalHours'){
            this.allocationTypeHelpText = 'Total';
            this.setAllocationByHoursPerDay = false;
            this.setAllocationByTotalHours = true;
        }else{
            this.allocationTypeHelpText = 'Hours/Week';
            this.setAllocationByHoursPerDay = false;
            this.setAllocationByTotalHours = true;
        }
    }

    handleGetAllocationByHourNumber(event){
        this.setAllocationByDateRangeError = false;
        this.allocationByHourNumber = event.target.value;
    }

    handleAllocationSetDateStartDateChange(event){
        let differenceInDays = 0;

        this.setAllocationFromDate = event.target.value;
        this.setAllocationByDateRangeError = false;

        if(this.setAllocationFromDate && this.setAllocationToDate){
            differenceInDays = this.getBusinessDatesCount(this.getJSDateFromText(this.setAllocationFromDate), this.getJSDateFromText(this.setAllocationToDate));
        }

        let contactId = this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex].projectTeamMemberContactId;
        let projectTeamMemberId = this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex].projectTeamMemberId;        

        this.getAllocationForDateRange(this.setAllocationFromDate, this.setAllocationToDate, this.recordId, contactId, projectTeamMemberId);
        
        this.setAllocationDayCount = differenceInDays;
        
    }

    handleAllocationSetDateEndDateChange(event){
        let differenceInDays = 0;

        this.setAllocationToDate = event.target.value;
        this.setAllocationByDateRangeError = false;

        if(this.setAllocationFromDate && this.setAllocationToDate){
            differenceInDays = this.getBusinessDatesCount(this.getJSDateFromText(this.setAllocationFromDate), this.getJSDateFromText(this.setAllocationToDate));
        }

        let contactId = this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex].projectTeamMemberContactId;
        let projectTeamMemberId = this.allocationTableData.teamMemberDataWrapperList[this.clickedRowIndex].projectTeamMemberId;

        this.getAllocationForDateRange(this.setAllocationFromDate, this.setAllocationToDate, this.recordId, contactId, projectTeamMemberId);
        
        this.setAllocationDayCount = differenceInDays;
    }

    getAllocationForDateRange(startDate, endDate, projId, conId, projTeamMemberId){
        if(startDate != null && endDate != null && projId != null && conId != null){
            console.log('Start Date: ', startDate);
            console.log('End Date: ', endDate);
            console.log('Project Id: ', projId);
            console.log('Contact Id: ', conId);
            getCurrentlyAllocatedHoursForDateRange({
                fromDate : startDate,
                toDate : endDate,
                projectId: projId,
                contactId: conId,
                projectTeamMemberId: projTeamMemberId})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                console.log('Successful Swap Allocation Hours Query: ', result);
                this.currentlyAllocatedHours = result;
                
            })
            .catch(error =>{
                
                console.error(error);
            })
        }else{
            console.error('Empty Parameters');
        }
    }

    /****************************** Swap Placeholder for User Modal *****************************/
    openSwapPlaceholderForUserModal = false;
    placeholderToSwapIdSelected = '';
    selectedPlaceholderToSwapBillRateId = '';
    swapPlaceholderForUserIsLoading = false;
    swapPlaceholderForUserError = false;
    swapPlaceholderForUserErrorMessage = '';
    swapPlaceholderForUserReplacementBillRateId = null;
    showPlaceholderReplacementBillRateInput = false;

    clickReplacePlaceholder(event){
        if(hasEditForecastTablePermission == true){
            console.log('Click Replace Placeholder');
            console.log('Index: ', event.currentTarget.dataset.index);
            let rowIndex = event.currentTarget.dataset.index;
            this.placeholderToSwapIdSelected = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberId;
            this.selectedPlaceholderToSwapBillRateId = this.allocationTableData.teamMemberDataWrapperList[rowIndex].projectTeamMemberBillRateId;
            this.openSwapPlaceholderForUserModal = true;
        }else{
            console.log('No Permission to replace Placeholder');
        }
    }

    handleSwapPlaceholderForUserChange(event){
        this.swapPlaceholderForUserError = false;
        console.log('Placeholder Swap Contact Id: ', event.target.value);
        console.log('Placeholder Swap Contact Label: ', event.target.displayValue);
        console.log('Placeholder Swap Contact: ', event.target);
    }

    onSubmitSwapPlaceholderForUser(event){
        event.preventDefault();
        this.swapPlaceholderForUserIsLoading = true;
        if(this.placeholderToSwapIdSelected != '' && this.placeholderToSwapIdSelected != null && this.placeholderToSwapIdSelected != undefined){
            let fields = event.detail.fields;
            swapPlaceholderForUser({
                placeholderTeamMemberId : this.placeholderToSwapIdSelected,
                contactId : fields.Client_Contact__c,
                peoplesoftProjectId: this.projectPeoplesoftId,
                projectId: this.recordId,
                projectName: this.projectNameValue,
                replacementBillRateId: this.swapPlaceholderForUserReplacementBillRateId})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                console.log('Successful Swap Placeholder');
                this.swapPlaceholderForUserError = false;
                this.swapPlaceholderForUserIsLoading = false;
                this.closeModal();

                //refreshApex(this._getProjectDataResponse);
                return refreshApex(this.forecastTableDataResults);
                
            })
            .catch(error =>{

                this.swapPlaceholderForUserError = true;
                this.swapPlaceholderForUserIsLoading = false;
                if(error.body.message == 'Placeholder Bill Rate cannot be replaced'){
                    this.showPlaceholderReplacementBillRateInput = true;
                    this.swapPlaceholderForUserErrorMessage = 'This billing rate was for a placeholder use only, and is not included in this Project\'s available billing rates. '+
                    'Only rates represented as Products in this Project\'s related Opportunity or Closed-Won COs are available for team assignment. Select a bill rate that is available from the project billing rate list to continue.';

                }else{
                    this.swapPlaceholderForUserErrorMessage = error.body.message;
                }
                
                console.error(error);
            })
        }else{
            this.swapPlaceholderForUserError = true;
            this.swapPlaceholderForUserErrorMessage = 'Must Assign a Contact to Swap with the Placeholder Team Member';
            this.swapPlaceholderForUserIsLoading = false;
            console.error('Must Assign a Contact to Swap with the Placeholder Team Member');
        }
    }

    handleBillRateChangeForPlaceholderSwapReplacement(event){
        let billRateIdReplacementForPlaceholderSwap = event.detail.value;
        this.swapPlaceholderForUserReplacementBillRateId = billRateIdReplacementForPlaceholderSwap;
    }

    handleOtherAllocationMouseOver(event){
        try{
            let uniqueId = event.currentTarget.dataset.allocationId;
            let otherAllocationField = this.template.querySelector(`[data-other-allocation-unique-id="${uniqueId}"]`);
            otherAllocationField.classList.remove('slds-fall-into-ground');
            otherAllocationField.classList.remove('slds-hide');
            otherAllocationField.classList.add('slds-rise-from-ground');
        }catch(error){
            console.error('Other Allocation Mouse In Error: ', error);
        }
    }

    handleOtherAllocationMouseOut(event){
        try{
            let uniqueId = event.currentTarget.dataset.allocationId;
            let otherAllocationField = this.template.querySelector(`[data-other-allocation-unique-id="${uniqueId}"]`);
            otherAllocationField.classList.remove('slds-rise-from-ground');
            otherAllocationField.classList.add('slds-fall-into-ground');
            otherAllocationField.classList.add('slds-hide');
        }catch(error){
            console.error('Other Allocation Mouse In Error: ', error);
        }
    }


    /****************************** Open and Close Set Allocation Modal ******************************/

    closeModal(){
        this.chosenBillingRate = '';
        this.createProjTeamMemberFormIsLoading = false;
        this.openForecastEntryModal = false;
        this.openAddProjectTeamMemberModal = false;
        this.createNewProjectTeamMemberError = false;

        /** Set Allocation by Date Range fields ****/
        this.setAllocationByDateRangeError = false;
        this.setAllocationByDateRangeErrorMessage = '';
        this.setAllocationModalIsLoading = false;
        this.setAllocationDayCount = 5;


        /***** Add Placeholder Modal Fields *****/
        this.openAddPlaceholderModal = false;
        this.addPlaceholderError = false;
        this.addPlaceholderErrorMessage = '';
        this.createPlaceholderIsLoading = false;
        this.selectedPlaceholderRole = '';


        /***** Swap Placeholder For User Modal Logic ******/
        this.openSwapPlaceholderForUserModal = false;
        this.swapPlaceholderForUserIsLoading = false;
        this.swapPlaceholderForUserErrorMessage = '';
        this.swapPlaceholderForUserError = false;
        this.swapPlaceholderForUserReplacementBillRateId = null;
        this.showPlaceholderReplacementBillRateInput = false;
    }
    /*************************************************************************************************/

    async refresh(){
        await refreshApex(this.forecastTableDataResults);
    }

    refreshApexForTable(){
        console.log('Refresh Apex for Table');
        //refreshApex(this._getProjectDataResponse);
        return refreshApex(this.forecastTableDataResults);
    }


    /****************************** Date Formatting Functions ******************************/
    formatDate(dateToFormat){
        let dd = String(dateToFormat.getDate()).padStart(2, '0');
        let mm = String(dateToFormat.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = dateToFormat.getFullYear();

        dateToFormat = yyyy + '-' + mm + '-' + dd;
        return dateToFormat;
    }

    getDifferenceInDays(startDate, endDate){

        let Difference_In_Time = endDate.getTime() - startDate.getTime();
        let Difference_In_Days = Difference_In_Time / (1000 * 3600 * 24);

        return Difference_In_Days;
    }

    getJSDateFromText(dateText){
        let dateArray = dateText.split("-");
        let year = dateArray[0];
        let month = parseInt(dateArray[1], 10) - 1;
        let day = dateArray[2];
        let jsDate = new Date(year, month, day);

        return jsDate;
    }

    getBusinessDatesCount(startDate, endDate) {
        let count = 0;
        /*let curDate = new Date(new Date(this.formatDate(startDate)).getTime());
        console.log('CurDate Before: ', curDate);*/
        let curDate = startDate;
        while (curDate <= endDate) {
            let dayOfWeek = curDate.getDay();
            if(dayOfWeek !== 0 && dayOfWeek !== 6){
                count++;
            } 
            curDate.setDate(curDate.getDate() + 1);
        }

        return count;
    }
    /**************************************************************************************/


    /**************** Copy Forecast Table data to Copy object for quick updates within UI ******************/

    copyForecastTableData(realData){
        this.allocationTableDataCOPY.budgetAmountDiffernce = this.allocationTableData.budgetAmountDiffernce;
        this.allocationTableDataCOPY.budgetHoursDifference = this.allocationTableData.budgetHoursDifference;
        this.allocationTableDataCOPY.levBudgetRemaining = this.allocationTableData.levBudgetRemaining;
        this.allocationTableDataCOPY.levHoursRemaining = this.allocationTableData.levHoursRemaining;
        this.allocationTableDataCOPY.levRemainingForecastedBudget = this.allocationTableData.levRemainingForecastedBudget;
        this.allocationTableDataCOPY.levRemainingForecastedHours = this.allocationTableData.levRemainingForecastedHours;

        /*** Set projectWeekStartAndEndRangeStringList ***/
        projectWeekStartAndEndRangeStringList = [];
        for(let x in this.allocationTableData.projectWeekStartAndEndRangeStringList){
            projectWeekStartAndEndRangeStringList.push(x);
        }
        this.allocationTableDataCOPY.projectWeekStartAndEndRangeStringList = projectWeekStartAndEndRangeStringList;

        /*** Set projectWeekStartDateList ***/
        projectWeekStartDateList = [];
        for(let x in this.allocationTableData.projectWeekStartDateList){
            projectWeekStartDateList.push(x);
        }
        this.allocationTableDataCOPY.projectWeekStartDateList = projectWeekStartDateList;

        /*** Set projectWeekStartStringList ***/
        projectWeekStartStringList = [];
        for(let x in this.allocationTableData.projectWeekStartStringList){
            projectWeekStartStringList.push(x);
        }
        this.allocationTableDataCOPY.projectWeekStartStringList = projectWeekStartStringList;

        /*** Set teamMemberDataWrapperList ***/




    }

    cloneForecastTableDate(realData){
        this.allocationTableDataCOPY = JSON.parse(JSON.stringify(realData));
    }


    /*******************************************************************************************************/

}