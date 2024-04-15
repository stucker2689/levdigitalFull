import { LightningElement, api, track, wire  } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import Case from '@salesforce/schema/Case';
import getLevStaffingQueue from '@salesforce/apex/SubmitOoOCoverageRequestButtonController.getLevStaffingQueue';

export default class SubmitOoOCoverageRequestButton extends NavigationMixin(LightningElement) {

    @api recordId;

    @track OoORequestRecordId;
    @track error;

    customErrors =[];

    @track isLoading = false;
    isError = false;

    sfdcBaseURL;
    subjectName;

    @wire(getLevStaffingQueue, {projectId: '$recordId'})
    levStaffingQueueId;

    @wire(getObjectInfo, {objectApiName:Case})
    getObjectdata({data,error}){
        if(data){
            let rtInfo= Object.keys(data.recordTypeInfos).find(rti => data.recordTypeInfos[rti].name === 'OoO Coverage Request');
            this.OoORequestRecordId = rtInfo;

        }else if(error){
            this.error = error;
        }
    }

    renderedCallback() {
        this.sfdcBaseURL = window.location.origin;
    }

    onSubmit(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess(event){
        
        this.isLoading = false;
        /*** Displays Popup with Link DOES NOT TAKE TO PAGE ***/
        const evt1 = new ShowToastEvent({
            title: 'Success!',
            message: 'Record {0} successfully created!',
            messageData: [
                {
                    url: this.sfdcBaseURL + '/' + event.detail.id,
                    label: this.subjectName,
                },
            ],
            variant: "success"
        });
        this.dispatchEvent(evt1);
        /*****************************************************/

        /***Takes user to case page ***/
        /*this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                actionName: 'view',
            },
        }).then((url) => {
            const evt = new ShowToastEvent({
                title: 'Success!',
                message: 'Record {0} created! See it {1}!',
                messageData: [
                    'Salesforce',
                    {
                        url,
                        label: 'here',
                    },
                ],
                variant: "success"
            });
            this.dispatchEvent(evt);
        });*/
        /***************************/

        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(){
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: "Error",
            message: "OoO Coverage Request Case Not Created",
            variant: "error"
        });
        this.dispatchEvent(evt);
        
    }

    
    submitCase(){
        this.isError = false;
        this.customErrors = [];
        let isValid = [...this.template.querySelectorAll('lightning-input-field')].reduce( (val, inp) => {
            //Check Required Logic
            if(inp.required == true && inp.value == null && inp.fieldName != 'CaseNumber'){
                this.isError = true;
            }
            if(inp.value != null && inp.fieldName == 'Subject'){
                this.subjectName = inp.value;
            }
            
        }, true);
    
        if (this.isError == false) {
            this.template.querySelector('lightning-record-edit-form').submit();
            this.isLoading = true;
        }else{
            //Invalid Logic
            this.template.querySelector('.parentDiv').scrollTop=0;

        }


    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}