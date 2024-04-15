import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';

import hasCreateProjTeamMemberPermission from '@salesforce/customPermission/Create_Internal_Project_Team_Member_Custom_Permission';

import getProjectTeamMemberWrappers from '@salesforce/apex/InternalProjTeamMemberLWCController.getProjectTeamMembersWrapper';
import getProjBillRates from '@salesforce/apex/InternalProjTeamMemberLWCController.getProjectBillingRatesForAssignment';
import getCreatedProjectTeamMemberName  from '@salesforce/apex/InternalProjTeamMemberLWCController.createProjectTeamMemberName';
import deleteProjTeamMember from '@salesforce/apex/InternalProjTeamMemberLWCController.deleteProjectTeamMember';
import createEffectiveRate from '@salesforce/apex/InternalProjTeamMemberLWCController.createEffectiveRate';
import updatePlaceholderBillRate from '@salesforce/apex/InternalProjTeamMemberLWCController.updatePlaceholderBillRate';

import createPlaceholder from '@salesforce/apex/ProjectForecastingTableController.createPlaceholder';
import getPlaceholderRoles from '@salesforce/apex/ProjectForecastingTableController.getPlaceholderRoles';
import swapPlaceholderForUser from '@salesforce/apex/ProjectForecastingTableController.replacePlaceholderWithUser';


import PROJECT_TEAM_MEMBER_ID_FIELD from '@salesforce/schema/Client_Contact__c.Id';
import PROJECT_TEAM_MEMBER_ASSIGNED_BILLING_RATE_FIELD from '@salesforce/schema/Client_Contact__c.Assigned_Billing_Rate__c';

import PROJECT_NAME from '@salesforce/schema/Project__c.Name';
import PEOPLESOFT_PROJ_ID from '@salesforce/schema/Project__c.PeopleSoft_Project_ID__c';
import PROJECT_CREATED_DATE from '@salesforce/schema/Project__c.CreatedDate';
import PROJECT_ACCOUNT from '@salesforce/schema/Project__c.Account__c';


export default class InternalProjectTeamMemberLWC extends LightningElement {
//Create_Internal_Project_Team_Member_Permission
    items = [];
    internalProjectTeamMembers = [];

    @api recordId;
    internalProjectTeamMemberCount = 0;
    isCreateNewTeamMemberModalOpen = false;
    errorMessage;
    displayTeamMemberTable = false;
    showCreateProjTeamMemberForm = true;
    showRefreshOnProjectTeamMembersForm = false;

    projectNameValue;
    projectPeoplesoftId;
    projectCreatedDate;
    projectAccountId;

    get isCreateNewTeamMemberEnabled(){
        return hasCreateProjTeamMemberPermission;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [PROJECT_NAME, PROJECT_CREATED_DATE], optionalFields: [PEOPLESOFT_PROJ_ID, PROJECT_ACCOUNT]})
    project({error, data}){
        if(error){
            console.log('ERROR: ', error);
        }else if(data){
            console.log('data: ', data);
            this.projectNameValue = data.fields.Name.value;
            this.projectPeoplesoftId = data.fields.PeopleSoft_Project_ID__c.value;
            this.projectCreatedDate = data.fields.CreatedDate.value;
            this.projectAccountId = data.fields.Account__c.value;
        }
    }

    @wire(getProjectTeamMemberWrappers, {projectId: '$recordId'})
    relatedProjectTeamMembers;

    renderedCallback(){
        if(this.relatedProjectTeamMembers.data){
            this.internalProjectTeamMemberCount = (this.relatedProjectTeamMembers.data).length;
        }
        this.displayTeamMemberTable = true;
    }

    @wire(getProjBillRates,{projectId: '$recordId'})
    wiredProjBillRates({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            for(var i=0; i<data.length; i++)  {
                this.items = [...this.items ,{value: data[i].Id , label: data[i].Name + ' - $' + data[i].Hourly_Rate__c} ];                                   
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.items = undefined;
        }
    }

    get billingRates() {
        return this.items;
    }

    openCreateTeamMemberModal() {
        this.isCreateNewTeamMemberModalOpen = true;
    }
    closeCreateTeamMemberModal() {
        this.isCreateNewTeamMemberModalOpen = false;
    }


    createNewProjectTeamMember(){
        this.errorMessage = '';
        this.chosenValue = '';
        this.isCreateNewTeamMemberModalOpen = true;
    }

    onSubmitNewProjectTeamMember(event){
        event.preventDefault();
        //this.showCreateProjTeamMemberForm = false;
        this.showRefreshOnProjectTeamMembersForm = true;
        if(this.chosenValue != '' && this.chosenValue != null && this.chosenValue != undefined){
            console.log('Chosen Value: ', this.chosenValue);
            const fields = event.detail.fields;
            fields.Project__c = this.recordId;
            fields.Assigned_Billing_Rate__c = this.chosenValue;
            console.log('New Project Team Member Contact Id: ', fields.Client_Contact__c);
            console.log('New Project Team Member Proj Id: ', this.recordId);
            getCreatedProjectTeamMemberName({
                contactId : fields.Client_Contact__c,
                projectId : this.recordId})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                this.projectTeamMemberName = result;
                fields.Internal_Project_Team_Member_Name__c = String(this.projectTeamMemberName);
                fields.Account__c = this.projectAccountId;
                //this.template.querySelector('lightning-record-form').submit(fields);
                this.template.querySelector('lightning-record-edit-form').submit(fields);
                this.showCreateProjTeamMemberForm = true;
                this.isCreateNewTeamMemberModalOpen = false;
                this.showRefreshOnProjectTeamMembersForm = false;
                
            })
            .catch(error =>{
                this.showRefreshOnProjectTeamMembersForm = false;
                this.errorMessage = error.body.message;
                console.error(error);
            })
        }else{
            this.showRefreshOnProjectTeamMembersForm = false;
            this.showCreateProjTeamMemberForm = true;
            this.errorMessage = 'Must Assign a Billing Rate to Create Project Team Member';
            console.error('Must Assign a Billing Rate to Create Project Team Member');
        }
    }

    onSuccessfulCreateNewTeamMember(event){
        const evt = new ShowToastEvent({
            title: "Record Created",
            message: "Internal Project Team Member Created",
            variant: "success"
        });
        this.dispatchEvent(evt);

        refreshApex(this.relatedProjectTeamMembers);
        
    }

    handleNewInternalProjectTeamMemberChange(){
        this.errorMessage = '';
    }

    handleBillRateChange(event){
        this.errorMessage = undefined;
        const selectedOption = event.detail.value;
        this.chosenValue = selectedOption;
    }

    async refresh(){
        await refreshApex(this.relatedProjectTeamMembers);
    }

    refreshTableDate(){
        refreshApex(this.relatedProjectTeamMembers);
    }

    /************ Update Bill Rate Functionality ************************/
    updateBillRateIsLoading = false;
    isUpdateBillingRateModalOpen = false;
    updateBillingRateError = false;
    updateBillingRateErrorMessage = '';
    displaySetEffectiveRateCheckbox = false;
    showEffectiveDateSelection = false;
    selectedEffectiveDate = undefined;
    teamMemberNeedsRateAssigned;
    assignedBillingRate;
    assignedBillingRateTeamMemberName;
    selectedTeamMemberForBillRateUpdate;
    selectedTeamMemberIdForBillRateUpdate;
    setRateEffectiveDate = false;

    updateBillRateClickHandle(event){
        this.chosenValue = undefined;
        this.assignedBillingRate = undefined;
        this.assignedBillingRateTeamMemberName = undefined;
        this.selectedTeamMemberForBillRateUpdate = undefined;
        this.selectedTeamMemberIdForBillRateUpdate = undefined;

        let itemIndex = event.currentTarget.dataset.index;
        let needsRate = event.currentTarget.dataset.needsRate;
        this.teamMemberNeedsRateAssigned = needsRate;
        let rowData = this.relatedProjectTeamMembers.data[itemIndex];
        
        // eslint-disable-next-line no-console
        console.log(rowData);

        this.selectedTeamMemberForBillRateUpdate = rowData;
        this.selectedTeamMemberIdForBillRateUpdate = rowData.ptmId;
        this.assignedBillingRate = rowData.billingRateId;
        this.assignedBillingRateTeamMemberName = rowData.employeeeName;
        if(hasCreateProjTeamMemberPermission){

            this.isUpdateBillingRateModalOpen = true;
        }
    }

    handleSetEffectiveDateChange(event){
        this.setRateEffectiveDate = event.target.checked;
        console.log('Set Effective Date Change: ', this.setRateEffectiveDate);
        this.showEffectiveDateSelection = !this.showEffectiveDateSelection;        
        if(this.showEffectiveDateSelection == false){
            this.selectedEffectiveDate = undefined;
        }
    }

    handleBillRateUpdateChange(event){

        this.updateBillingRateError = false;
        let selectedOption = event.detail.value;
        this.chosenValue = selectedOption;

        if(this.teamMemberNeedsRateAssigned == 'false' && this.chosenValue != null && this.chosenValue != undefined && this.chosenValue != this.assignedBillingRate){ //If Team Member already has a rate assigned and the original rate is changed within the Update Bill Rate Modal, then display option to set effective Date
            this.displaySetEffectiveRateCheckbox = true;
        }else{
            this.displaySetEffectiveRateCheckbox = false;  
            this.selectedEffectiveDate = undefined;
        }

    }

    effectiveDateSelectionChange(event){

        this.selectedEffectiveDate = event.target.value;
        this.updateBillingRateError = false;
    }

    
    submitAssignedBillRateUpdate(event){
        this.updateBillRateIsLoading = true;
        //If No Effective Date was selected then just update the Project Team Member
        if(this.setRateEffectiveDate == false){
            // Create the recordInput object

            let assignedBillRateId;

            if(this.selectedTeamMemberForBillRateUpdate.isPlaceholderEmployee == true){
                console.log('Submit Assigned Bill Rate For Placeholder');
                this.updatePlaceholderBillRateFromTable(this.recordId, this.selectedPlaceholderRole, this.selectedTeamMemberForBillRateUpdate.ptmId);
                return;

            }else{
                assignedBillRateId = this.chosenValue;
            }
            const fields = {};
            fields[PROJECT_TEAM_MEMBER_ID_FIELD.fieldApiName] = this.selectedTeamMemberForBillRateUpdate.ptmId;
            fields[PROJECT_TEAM_MEMBER_ASSIGNED_BILLING_RATE_FIELD.fieldApiName] = this.chosenValue;

            const recordInput = { fields };

            updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Project Team Member Assigned Billing Rate Successfully Updated',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                this.closeModal();
                return refreshApex(this.relatedProjectTeamMembers);
                
            })
            .catch(error => {
                this.updateBillRateIsLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });        
        }else if(this.setRateEffectiveDate == true){
            //If effective date is populated then create a Effective Rate record, and depending on the date that was selected update the Project Team Member as well.
            if(this.selectedEffectiveDate != '' && this.selectedEffectiveDate != null && this.selectedEffectiveDate != undefined){

                console.log('PTM Data: ', this.selectedTeamMemberForBillRateUpdate);
                console.log('PTM Id: ', this.selectedTeamMemberForBillRateUpdate.ptmId);
                console.log('this.assignedBillingRate: ', this.assignedBillingRate);
                console.log('this.chosenValue: ', this.chosenValue);
                console.log('this.selectedEffectiveDate: ', this.selectedEffectiveDate);
                createEffectiveRate({
                    projectTeamMemberId : this.selectedTeamMemberForBillRateUpdate.ptmId,
                    priorBillingRateId : this.assignedBillingRate,
                    newBillingRateId: this.chosenValue,
                    effectiveDate: this.selectedEffectiveDate,
                    projectCreatedDate : this.projectCreatedDate})
                .then(result =>{
                    //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                    console.log('Successful Effective Rate Creation');
                    this.updateBillingRateError = false;
                    this.updateBillRateIsLoading = false;
                    this.closeModal();

                    return refreshApex(this.relatedProjectTeamMembers);
                    
                })
                .catch(error =>{
                    this.updateBillingRateError = true;
                    this.updateBillRateIsLoading = false;
                    this.updateBillingRateErrorMessage = error.body.message;
                    console.error(error);
                })
            }else{
                this.updateBillingRateError = true;
                this.updateBillingRateErrorMessage = 'ERROR: Must Enter an Effective Date in order to create a rate that is active as of a specific date, or uncheck Effective Date checkbox to just swap billing rates for Team Member.';
                this.updateBillRateIsLoading = false;
                console.error('Must Enter an Effective Date in order to create a rate that is active as of a specific date.');
            }

        }
    }

    updatePlaceholderBillRateFromTable(projectId, productId, ptmId){
        console.log('Project Id: ', projectId);
        console.log('Product Id: ', productId);
        console.log('PTM Id: ', ptmId);
        updatePlaceholderBillRate({
            projectId : projectId,
            productId : productId,
            placeholderRoleName: this.placeholderRoleMap.get(productId),
            projectTeamMemberId: ptmId})
        .then(result =>{
            //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
            console.log('Successful Placeholder Bill Rate Update');
            this.updateBillingRateError = false;
            this.updateBillRateIsLoading = false;
            this.closeModal();

            return refreshApex(this.relatedProjectTeamMembers);
            
        })
        .catch(error =>{
            this.updateBillingRateError = true;
            this.updateBillRateIsLoading = false;
            this.updateBillingRateErrorMessage = error.body.message;
            console.error(error);
        })
    }

    openUpdateBillingRateModal() {
        this.isUpdateBillingRateModalOpen = false;
    }

    /********************** Create New Placeholder Team Member Logic **************************/
    openAddPlaceholderModal = false;
    createPlaceholderIsLoading = false;
    addPlaceholderError = false;
    addPlaceholderErrorMessage = '';
    placeholderRoleItems = [];
    selectedPlaceholderRole;
    placeholderRoleMap = new Map();

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
                fields.Account__c = this.projectAccountId;
                fields.Is_Placeholder_Team_Member__c = true;
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
        return refreshApex(this.relatedProjectTeamMembers);
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

    /****************************** Swap Placeholder for User Modal *****************************/
    openSwapPlaceholderForUserModal = false;
    placeholderToSwapIdSelected = '';
    selectedPlaceholderToSwapBillRateId = '';
    swapPlaceholderForUserIsLoading = false;
    swapPlaceholderForUserError = false;
    swapPlaceholderForUserErrorMessage = '';
    swapPlaceholderForUserReplacementBillRateId = null;
    showPlaceholderReplacementBillRateInput = false;

    swapPlaceholderForUser(event){

        if(hasCreateProjTeamMemberPermission){
            let rowIndex = event.currentTarget.dataset.index;
            this.placeholderToSwapIdSelected = this.relatedProjectTeamMembers.data[rowIndex].ptmId;
            this.selectedPlaceholderToSwapBillRateId = this.relatedProjectTeamMembers.data[rowIndex].billingRateId;
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
            console.log('placeholderTeamMemberId: ', this.placeholderToSwapIdSelected);
            console.log('contactId: ', fields.Client_Contact__c);
            console.log('peoplesoftProjectId: ', this.projectPeoplesoftId);
            console.log('ProjectId: ', this.recordId);
            console.log('Project Name: ', this.projectNameValue);
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

                return refreshApex(this.relatedProjectTeamMembers);
                
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


    /******************************** Delete Project Team Member Functionality ***********************************/

    openDeleteProjectTeamMemberConfirmationModal = false;
    deleteProjectTeamMemberError = false;
    deleteProjectTeamMemberErrorMessage = '';
    deleteProjTeamMemberIsLoading = false;
    projectTeamMemberToDeleteIndex;
    deleteProjectTeamMemberName;

    deleteProjTeamMember(event){
        this.projectTeamMemberToDeleteIndex = event.currentTarget.dataset.index;
        this.deleteProjectTeamMemberName = this.relatedProjectTeamMembers.data[this.projectTeamMemberToDeleteIndex].name;
        console.log('Delete Project Team Member: ', this.relatedProjectTeamMembers.data[this.projectTeamMemberToDeleteIndex]);
        this.openDeleteProjectTeamMemberConfirmationModal = true;
    }

    confirmDeleteProjTeamMember(event){
        
        this.deleteProjTeamMemberIsLoading = true;
        deleteProjTeamMember({
            projectTeamMemberId : this.relatedProjectTeamMembers.data[this.projectTeamMemberToDeleteIndex].ptmId})
        .then(result =>{

            this.closeModal();

            return refreshApex(this.relatedProjectTeamMembers);
            
        })
        .catch(error =>{
            this.deleteProjTeamMemberIsLoading = false;
            this.deleteProjectTeamMemberError = true;
            this.deleteProjectTeamMemberErrorMessage = error.body.message;
            console.error(error);
        })
    }


    /*************************** Effective Rate Popup **********************************/   

    hideEffectiveRatePopup(event){
        let uniqueId = event.currentTarget.dataset.ptmId;
        let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
        allocationInputField.classList.remove('slds-rise-from-ground');
        allocationInputField.classList.add('slds-fall-into-ground');
        allocationInputField.classList.add('slds-hide');
    }

    showEffectiveRatePopup(event){
        let uniqueId = event.currentTarget.dataset.ptmId;
        let allocationInputField = this.template.querySelector(`[data-unique-id="${uniqueId}"]`);
        allocationInputField.classList.remove('slds-fall-into-ground');
        allocationInputField.classList.remove('slds-hide');
        allocationInputField.classList.add('slds-rise-from-ground');
    }


    closeModal(){
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
        this.showPlaceholderReplacementBillRateInput = false;

        /****** Delete Project Team Member Modal Logic ******/
        this.openDeleteProjectTeamMemberConfirmationModal = false;
        this.deleteProjectTeamMemberError = false;
        this.deleteProjectTeamMemberErrorMessage = '';
        this.swapPlaceholderForUserReplacementBillRateId = null;
        this.deleteProjTeamMemberIsLoading = false;

        /****** Update Billing Rate on Existing Proj Team Member *******/
        this.isUpdateBillingRateModalOpen = false;
        this.updateBillRateIsLoading = false;
        this.updateBillingRateError = false;
        this.updateBillingRateErrorMessage = '';
        this.displaySetEffectiveRateCheckbox = false;
        this.showEffectiveDateSelection = false;
        this.selectedEffectiveDate = undefined;
        this.assignedBillingRate = undefined;
        this.selectedTeamMemberForBillRateUpdate = undefined;
        this.setRateEffectiveDate = false;
    }
}