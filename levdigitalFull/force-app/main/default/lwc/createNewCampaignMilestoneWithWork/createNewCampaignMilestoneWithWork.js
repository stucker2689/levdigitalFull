import { LightningElement, wire, track, api} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import checkForUniqueMilestoneName from '@salesforce/apex/CreateNewCMWithWorkController.checkIfMilestoneNameIsUnique';
import createMilestoneAndWorkRecords from '@salesforce/apex/CreateNewCMWithWorkController.createMilestoneAndWorkRecordsFromLWC';

const columns = [
    { label: 'Work Order', fieldName: 'workIndex', type:'text', cellAttributes: {alignment: 'center'} },
    { label: 'Work Name', fieldName: 'workName', type: 'text' }
];

export default class CreateNewCampaignMilestoneWithWork extends NavigationMixin(LightningElement) {
    @api recordId;
    selectedWorkTemplateValue;
    @track newMilestoneName;
    @track updatedWorkOrderRecords = [];
    selectedWorkRecordsToBeCreated = [];
    openInitialCreationScreen = true;
    openConfirmWorkRecordScreen = false;
    openOrderWorkItemsScreen = false;
    openFinalConfirmationScreen = false;
    loadingMilestoneAndWorkCreation = false;
    disableButtons = false;
    @track customWorkName;
    disableAddWorkItemButton = true;
    customWorkNameRequired = false;
    @track loadingWorkRecordCheckBoxGroup = false;
    noWorkSelected = false;
    initialCreationScreenLoading = false;

    columns = columns;

    workTemplatesList = [{ label : 'Deployment Only (6 Work Records)', value: 'deploymentOnly'},
                        { label : 'One Round (8 Work Records)', value: 'oneRound' }, 
                        { label : 'Two Rounds (12 Work Records)', value: 'twoRounds'}, 
                        { label : 'Three Rounds (16 Work Records)', value: 'threeRounds'}, 
                        { label : 'Build with SA Audience Creation (13 Work Records)', value: 'buildWithSAAudience Creation'}, 
                        { label : 'Templated Landing Page (11 Work Records)', value: 'tamplatedLandingPage'}, 
                        { label : 'Email Deployment with SMS (16 Work Records)', value: 'emailDeploymentWithSMS'}, 
                        { label : 'Two Rounds with Journey Build + Tech QA (12 Work Records)', value: 'twoRoundswithJourneyBuildAndTechQA'}, 
                        { label : 'Custom', value: 'custom'}];

    workRecordNamesList = [{ label : 'Audience Creation', value: 'Audience Creation'},
                            { label : 'Back End Landing Page Development', value: 'Back End Landing Page Development'},
                            { label : 'Back End Landing Page Tech QA', value: 'Back End Landing Page Tech QA'},
                            { label : 'Build Round 1', value: 'Build Round 1'},
                            { label : 'Build Round 2', value: 'Build Round 2'},
                            { label : 'Build Round 3', value: 'Build Round 3'},
                            { label : 'Client Approval', value: 'Client Approval'},
                            { label : 'Client Approval for Deployment Setup', value: 'Client Approval for Deployment Setup' }, 
                            { label : 'Client Revisions', value: 'Client Revisions'},
                            { label : 'Client Revisions 2', value: 'Client Revisions 2'},
                            { label : 'Client Revisions 3', value: 'Client Revisions 3'},
                            { label : 'Day 0 Assets', value: 'Day 0 Assets'},
                            { label : 'Day 0 Assets / Deployment Details', value: 'Day 0 Assets / Deployment Details'},
                            { label : 'Deployment QA', value: 'Deployment QA'}, 
                            { label : 'Deployment Setup', value: 'Deployment Setup'}, 
                            { label : 'Front End Landing Page Build Round 1', value: 'Front End Landing Page Build Round 1'}, 
                            { label : 'Front End Landing Page Build Round 2', value: 'Front End Landing Page Build Round 2'}, 
                            { label : 'Front End Landing Page Client Approval', value: 'Front End Landing Page Client Approval'}, 
                            { label : 'Front End Landing Page Client Revisions', value: 'Front End Landing Page Client Revisions'}, 
                            { label : 'Front End Landing Page Creative QA Round 1', value: 'Front End Landing Page Creative QA Round 1'}, 
                            { label : 'Front End Landing Page Proof Round 1', value: 'Front End Landing Page Proof Round 1'}, 
                            { label : 'Front End Landing Page Proof Round 2', value: 'Front End Landing Page Proof Round 2'}, 
                            { label : 'Front End Landing Page QA Round 2', value: 'Front End Landing Page QA Round 2'}, 
                            { label : 'Journey Build', value: 'Journey Build'},
                            { label : 'Monitoring', value: 'Monitoring'},
                            { label : 'Proof Round 1', value: 'Proof Round 1'},
                            { label : 'Proof Round 2', value: 'Proof Round 2'},
                            { label : 'Proof Round 3', value: 'Proof Round 3'},
                            { label : 'QA Round 1', value: 'QA Round 1'},
                            { label : 'QA Round 2', value: 'QA Round 2'},
                            { label : 'QA Round 3', value: 'QA Round 3'},
                            { label : 'SMS Client Approval', value: 'SMS Client Approval'},
                            { label : 'SMS Creation', value: 'SMS Creation'},
                            { label : 'SMS Proof', value: 'SMS Proof'},
                            { label : 'SMS QA', value: 'SMS QA'},
                            { label : 'Tech QA', value: 'Tech QA'}];


    handleWorkTemplateChange(event) {
        this.selectedWorkTemplateValue = event.detail.value;
        console.log('Work Template Selected: ', this.selectedWorkTemplateValue);

        switch(this.selectedWorkTemplateValue){
            case 'deploymentOnly':
                //set Deploy Only Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets / Deployment Details', 'Client Approval for Deployment Setup', 'Audience Creation', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'oneRound':
                //set One Round Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Approval', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'twoRounds':
                //set Two Rounds Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Revisions', 'Build Round 2', 'QA Round 2', 'Proof Round 2', 'Client Approval', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'threeRounds':
                //set Three Rounds Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Revisions 2', 'Build Round 2', 'QA Round 2', 'Proof Round 2', 'Client Revisions 3', 
                                                    'Build Round 3', 'QA Round 3', 'Proof Round 3', 'Client Approval', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'buildWithSAAudience Creation':
                //set Build with SA Audience Creation Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Revisions', 'Build Round 2', 'QA Round 2', 'Proof Round 2', 'Client Approval', 'Audience Creation', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'tamplatedLandingPage':
                //set Templated Landing Page Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Front End Landing Page Build Round 1', 'Front End Landing Page Creative QA Round 1', 'Front End Landing Page Proof Round 1', 'Front End Landing Page Client Revisions', 
                                                    'Front End Landing Page Build Round 2', 'Front End Landing Page QA Round 2', 'Front End Landing Page Proof Round 2', 'Front End Landing Page Client Approval', 'Back End Landing Page Development', 'Back End Landing Page Tech QA'];
                break;
            case 'emailDeploymentWithSMS':
                //set Email Deployment with SMS Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Revisions', 'Build Round 2', 'QA Round 2', 'Proof Round 2', 'Client Approval',
                                                     'SMS Creation', 'SMS QA', 'SMS Proof', 'SMS Client Approval', 'Deployment Setup', 'Deployment QA', 'Monitoring'];
                break;
            case 'twoRoundswithJourneyBuildAndTechQA':
                //set Two Rounds with Journey Build + Tech QA Pre-set from Template
                this.selectedWorkRecordsToBeCreated = ['Day 0 Assets', 'Build Round 1', 'QA Round 1', 'Proof Round 1', 'Client Revisions', 'Build Round 2', 'QA Round 2', 'Proof Round 2', 'Client Approval', 'Journey Build', 'Tech QA', 'Monitoring'];
                break;
            default:
                //Set Custom Pre-set from template (i.e. Blank)
                this.selectedWorkRecordsToBeCreated = [];

        }
    }

    modifySelectedWorkRecords(event){

        this.selectedWorkRecordsToBeCreated = event.detail.value;
        console.log('Selected Work Records: ' + this.selectedWorkRecordsToBeCreated);
    }

    handleWorkOrderChange(event) {
        this.updatedWorkOrderRecords = event.detail;
    }

    addCustomWorkItem(event){
        this.customWorkNameRequired = true;
        let customWorkNameInput = this.template.querySelector(".customWorkNameInput");
        if(this.customWorkName){
            let customWorkNameAlreadyExists = false;
            let newWorkItem = {label: this.customWorkName, value: this.customWorkName};
            for(let workRecord of this.workRecordNamesList){
                if(workRecord.label == newWorkItem.label){
                    customWorkNameAlreadyExists = true;
                    break;
                }
            }

            if(customWorkNameAlreadyExists){
                customWorkNameInput.setCustomValidity("Enter a Unique Custom Work Name");
                customWorkNameInput.reportValidity();
            }else{
                customWorkNameInput.setCustomValidity("");
                this.workRecordNamesList.push(newWorkItem);
                this.selectedWorkRecordsToBeCreated.push(newWorkItem.value);
                this.customWorkName = "";
                this.customWorkNameRequired = false;
                this.disableAddWorkItemButton = true;
                this.loadingWorkRecordCheckBoxGroup = true;
                setTimeout(function() {
                    //Reload after set time (in Milliseconds 1000 milliseconds = 1 second)
                    this.loadingWorkRecordCheckBoxGroup = false;
                }.bind(this), 500);
            }
        }else{
            this.customWorkNameRequired = true;
            customWorkNameInput.setCustomValidity("Enter a Custom Work Name");
            customWorkNameInput.reportValidity();
        }
    }

    handleCustomWorkNameChange(event){
        this.customWorkName = event.detail.value;
        if(this.customWorkName.length > 0){
            this.disableAddWorkItemButton = false;
        }else{
            this.disableAddWorkItemButton = true;
        }
    }


    /******************************************************************************************** Navigation Button Handlers ********************************************************************************************/
    /******************************************************************************************** Next Button Handlers ********************************************************************************************/
    nextFromFirstToSecondScreen(){
        //Go from Initial Campaign Name and Work Template Selection Screen to Confirm/Add/Remove Work Records screen
        let milestoneNameInput = this.template.querySelector(".milestoneName");
        milestoneNameInput.setCustomValidity("");
        let milestoneNameIsValid = milestoneNameInput.reportValidity();//Check If Milestone is filled Out

        let workTemplateInput = this.template.querySelector(".workTemplateSelection"); 
        let workTemplateSelectionIsValid = workTemplateInput.reportValidity(); //Check if Template is selected

        let validToMoveToSecondScreen = false;

        if(milestoneNameIsValid && workTemplateSelectionIsValid){
            this.initialCreationScreenLoading = true;
            this.newMilestoneName = milestoneNameInput.value;
            checkForUniqueMilestoneName({newMilestoneName: this.newMilestoneName, projectId: this.recordId})
                .then(result =>{
                    validToMoveToSecondScreen = result;
                    if(validToMoveToSecondScreen){
                        this.openInitialCreationScreen = false;
                        this.openConfirmWorkRecordScreen = true;
                        this.openOrderWorkItemsScreen = false;
                        this.openFinalConfirmationScreen = false;
                        this.initialCreationScreenLoading = false;
                    }else{
                        //Milestone Name is not Unique for this project
                        this.initialCreationScreenLoading = false;
                        setTimeout(function() {
                            //Reload after set time (in Milliseconds 1000 milliseconds = 1 second)
                            let milestoneNameInput2 = this.template.querySelector(".milestoneName");
                            milestoneNameInput2.setCustomValidity("Campaign Milestone names must be unique across all existing Projects in our instance and this name has already been used. Please change the Milestone name to make it unique across all of Salesforce before proceeding.");
                            milestoneNameInput2.reportValidity();
                        }.bind(this), 250);
                    }
                })
                .catch(error =>{
                    this.initialCreationScreenLoading = false;
                    console.error('Check for Unique Milestone Name Callout Error: ', error);
                })
        }else{
            milestoneNameInput.showHelpMessageIfInvalid();
            workTemplateInput.showHelpMessageIfInvalid();
        }
    }

    nextFromSecondToThirdScreen(){
        //Go from Confirm/Add/Remove Work Records screen to Order Work Records Screen
        this.updatedWorkOrderRecords = [];
        let workNumber = 1;
        for(let selectedWorkItem of this.selectedWorkRecordsToBeCreated){

            let record = {Id: selectedWorkItem + workNumber.toString(), workName: selectedWorkItem, workIndex: workNumber};
            this.updatedWorkOrderRecords.push(record);
            workNumber++;
        }

        if(this.updatedWorkOrderRecords.length == 0){
            this.noWorkSelected = true;
        }else{
            this.noWorkSelected = false;
        }
    
        this.openInitialCreationScreen = false;
        this.openConfirmWorkRecordScreen = false;
        this.openOrderWorkItemsScreen = true;
        this.openFinalConfirmationScreen = false;
    }

    nextFromThirdToFourthScreen(){
        //Go from Order Work Records screen to Final Confirmation Screen
        this.openInitialCreationScreen = false;
        this.openConfirmWorkRecordScreen = false;
        this.openOrderWorkItemsScreen = false;
        this.openFinalConfirmationScreen = true;
    }
    /*******************************************************************************************************************************************************************************************************************/

    /******************************************************************************************** Previous Button Handlers ********************************************************************************************/
    previousFromSecondToFirstScreen(){
        //Go from Confirm/Add/Remove Work Records screen BACK to Initial Campaign Name and Work Template Selection Screen
        this.openInitialCreationScreen = true;
        this.openConfirmWorkRecordScreen = false;
        this.openOrderWorkItemsScreen = false;
        this.openFinalConfirmationScreen = false;
    }

    previousFromThirdToSecondScreen(){
        //Go from Order Work Records Screen BACK to Confirm/Add/Remove Work Records screen
        this.openInitialCreationScreen = false;
        this.openConfirmWorkRecordScreen = true;
        this.openOrderWorkItemsScreen = false;
        this.openFinalConfirmationScreen = false;
    }

    previousFromFourthToThirdScreen(){
        //Go from Final Confirm Screen BACK to Confirm Work Records Order screen
        this.openInitialCreationScreen = false;
        this.openConfirmWorkRecordScreen = false;
        this.openOrderWorkItemsScreen = true;
        this.openFinalConfirmationScreen = false;
    }
    /*******************************************************************************************************************************************************************************************************************/
    
    
    finishCampaignCreation(event){
        this.disableButtons = true;
        this.loadingMilestoneAndWorkCreation = true;
        createMilestoneAndWorkRecords({milestoneName: this.newMilestoneName, wrapperList:JSON.stringify(this.updatedWorkOrderRecords), projectId: this.recordId})
        .then(result => {
            console.log('Data: ' + JSON.stringify(result));

            this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: result,
                actionName: 'view',
            },
            }).then((url) => {
            const evt = new ShowToastEvent({
                title: 'Success!',
                message: 'Milestone record sucessfully created! See it here: {1}',
                messageData: [
                    'Salesforce',
                    {
                        url,
                        label: this.newMilestoneName,
                    },
                ],
                variant: "success"
            });
                this.dispatchEvent(evt);
            });

            this.disableButtons = false;
            this.loadingMilestoneAndWorkCreation = false;
            this.closeModal();
        }) .catch(error => {
            console.log('ERROR: ', error);
            this.disableButtons = false;
            this.loadingMilestoneAndWorkCreation = false;
        })
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}