import { LightningElement, wire, api, track} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import StatusReport from '@salesforce/schema/Status_Report__c';
import getRelatedProject from '@salesforce/apex/CloneLatestStatusReportLWCController.getProjectDetailsForNewStatusReport';

export default class CreateNewStatusReportLWC extends NavigationMixin(LightningElement) {
    @api recordId;

    @track statusReportRTId;
    @track error;

    loadingSubmition = false;

    isError = false;

    sfdcBaseURL;
    
    @wire(getRelatedProject, {projectId: '$recordId'})
    relatedProject;
    //latestStatusReport

    @wire(getObjectInfo, {objectApiName:StatusReport})
    getObjectdata({data,error}){
        if(data){
            let rtInfo= Object.keys(data.recordTypeInfos).find(rti => data.recordTypeInfos[rti].name === 'New Status Report');
            this.statusReportRTId = rtInfo;


        }else if(error){
            this.error = error;
        }
    }

    renderedCallback() {
        if(this.relatedProject.data){
            console.log('Related Project DATA!!!');
            console.log('Related Project DATA!!!: ', this.relatedProject.data);
            refreshApex(this.relatedProject);

        }else{
            console.log('No Data :(');
            refreshApex(this.relatedProject);
        }
        
        this.sfdcBaseURL = window.location.origin;
    }

    onSubmit(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess(event){
        
        this.loadingSubmition = false;

        /*** Navigate to Record Page ***/
        let config = {
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: "Status_Report__c",
                actionName: 'view',
            }
        };
        console.log('BEFORE Navigate to new Status Report');
        this[NavigationMixin.Navigate](config);
        console.log('AFTER Navigate to new Status Report');
        /***************************/

        //this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(){
        this.loadingSubmition = false;

        const evt = new ShowToastEvent({
            title: "Error",
            message: "Status Report Not Created",
            variant: "error"
        });
        this.dispatchEvent(evt);
        
    }

    
    submitStatusReport(){
        this.loadingSubmition = true;
        this.isError = false;

        let isValid = [...this.template.querySelectorAll('lightning-input-field')].reduce( (val, inp) => {
            //Check Required Logic
            if(inp.required == true && inp.value == null){
                this.isError = true;
            }
            
        }, true);
    
        if (this.isError == false) {
            console.log('Submitting Status Report');
            this.template.querySelector('lightning-record-edit-form').submit();
        }else{
            console.log('NOT Submitting Status Report');
            //Invalid Logic
            //this.template.querySelector('.parentDiv').scrollTop=0;

        }


    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async refresh(){
        await refreshApex(this.relatedBillingRates);
    }

}