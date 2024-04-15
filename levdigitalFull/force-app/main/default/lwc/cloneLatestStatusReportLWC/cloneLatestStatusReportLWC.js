import { LightningElement, wire, api, track} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import StatusReport from '@salesforce/schema/Status_Report__c';
import getLatestStatusReportToClone from '@salesforce/apex/CloneLatestStatusReportLWCController.getLatestStatusReportToClone';

export default class CloneLatestStatusReportLWC extends NavigationMixin(LightningElement) {
    @api recordId;

    @track statusReportRTId;
    @track error;

    loadingSubmition = false;

    customErrors =[];

    @track isLoading = false;
    isError = false;

    sfdcBaseURL;
    subjectName;

    @wire(getLatestStatusReportToClone, {projectId: '$recordId'})
    latestStatusReport;

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
        if(this.latestStatusReport.data){
            console.log('DATA!: ', this.latestStatusReport.data);
            refreshApex(this.latestStatusReport);

        }else{
            console.log('NOPE NO DATA :(');
            refreshApex(this.latestStatusReport);

        }
        
        this.sfdcBaseURL = window.location.origin;
    }

    onSubmit(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess(event){
        
        this.loadingSubmition = false;
        this.isLoading = false;
        /*** Displays Popup with Link DOES NOT TAKE TO PAGE ***/
        /*const evt1 = new ShowToastEvent({
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
        this.dispatchEvent(evt1);*/
        /*****************************************************/

        /***Show Popup that has link to record page ***/
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

        /*** Navigate to Record Page ***/
        let config = {
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: "Status_Report__c",
                actionName: 'view',
            }
        };
        this[NavigationMixin.Navigate](config);
        /***************************/

        //this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(){
        this.loadingSubmition = false;
        this.isLoading = false;
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
        this.customErrors = [];
        let isValid = [...this.template.querySelectorAll('lightning-input-field')].reduce( (val, inp) => {
            //Check Required Logic
            if(inp.required == true && inp.value == null){
                this.isError = true;
            }
            
        }, true);
    
        if (this.isError == false) {
            this.template.querySelector('lightning-record-edit-form').submit();
        }else{
            //Invalid Logic
            this.template.querySelector('.parentDiv').scrollTop=0;

        }


    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async refresh(){
        await refreshApex(this.relatedBillingRates);
    }

}