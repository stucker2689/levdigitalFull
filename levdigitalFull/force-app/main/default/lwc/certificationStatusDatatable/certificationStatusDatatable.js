import { LightningElement, wire, track, api} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCertifications from '@salesforce/apex/PerformanceIndicatorLWCController.geCertificationsForContact';

export default class CertificationStatusDatatable extends LightningElement {

    @api recordId;

    @track columns = [
        {label: 'Type', fieldName: 'certUrl', type: 'url', typeAttributes: {label: { fieldName: 'certType' }, target: '_blank'}, sortable: true},
        {label: 'Status', fieldName: 'certStatus', type: 'text', sortable: true},
        {label: 'Date Certified', fieldName: 'certDateCertified', type: 'Date', sortable: true},
    ];

    @track certRecordTypeOptions = [
        {label: 'SFDC: Salesforce Certifications', value: '012d0000000kdfMAAQ'},
        {label: 'Magento', value: '012d0000000klE9AAI'},
        {label: 'SurgarCRM: SugarCRM Certifications', value: '012d0000000klETAAY'}
    ]

    certRecordTypeId = '012d0000000kdfMAAQ'; //Select SFDC as default

    wiredCertsRefresh;

    isMagnetoCert = false;
    isSFDCCert = true;
    isSugarCRM = false;

    @track error;
    @track certs = [];
    @track isCreateNewCertOpen = false;
    @track isRecordTypeSelectionDone = false;
    @track errorMessage;
    @track isError;
    @track isLoading = true;
    loadingSubmition = false;
    disableSave = false;


    allowScroll = false;


    /*@wire(getCertifications, {contactRecordId: '$recordId'})
    wiredCerts({error,data}) {
        if (data) {
            this.certs = data;
            this.error = undefined;
            this.isLoading = false;
            if(data.length > 6){
                this.allowScroll = true;
            }
        } else if (error) {
            this.error = error;
            this.certs = undefined;
            refreshApex(this.wiredCerts);
        }
    }*/

    /** Attempt to make Table Refreshable **/
    @wire(getCertifications, {contactRecordId: '$recordId'})
    wiredCertsTwo(result) {
        if (result.data) {
            this.wiredCertsRefresh = result;
            this.certs = result.data;
            this.error = undefined;
            this.isLoading = false;
            if(result.data.length > 6){
                this.allowScroll = true;
            }
        } else if (result.error) {
            this.error = result.error;
            this.certs = undefined;
            refreshApex(this.wiredCertsTwo);
        }
    }

    createnewCert(){
        this.isCreateNewCertOpen = true;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isCreateNewCertOpen = false;
        this.errorMessage = null;
    }

    closeCertCreationModal(){
        this.isRecordTypeSelectionDone = false;
    }

    submitCert(){
        this.loadingSubmition = true;
        this.disableSave = true;
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

    handleSuccess(event){
        this.disableSave = false;
        this.loadingSubmition = false;
        this.isLoading = false;
        //refreshApex(this.wiredCerts);
        this.closeModal();
        this.closeCertCreationModal();

        const evt = new ShowToastEvent({
            title: "Success",
            message: "Certification Successfully Created",
            variant: "success"
        });
        this.dispatchEvent(evt);

        return refreshApex(this.wiredCertsRefresh);
    }

    refreshTable(){
        return refreshApex(this.wiredCertsRefresh);
    }

    async refresh(){
        //await refreshApex(this.wiredCerts);
        await refreshApex(this.wiredCertsRefresh);
    }

    certRecordTypeSelected(){
        console.log('Record Type Selected: ' + this.certRecordTypeId);
        this.isCreateNewCertOpen = false;
        this.isRecordTypeSelectionDone = true;
    }

    handleRecordTypeSelectionChange(event) {
        this.certRecordTypeId = event.detail.value;
        if(this.certRecordTypeId == '012d0000000klE9AAI'){
            this.isMagnetoCert = true;
            this.isSFDCCert = false;
            this.isSugarCRM = false;
        }else if(this.certRecordTypeId == '012d0000000kdfMAAQ'){
            this.isMagnetoCert = false;
            this.isSFDCCert = true;
            this.isSugarCRM = false;
        }else if(this.certRecordTypeId == '012d0000000klETAAY'){
            this.isMagnetoCert = false;
            this.isSFDCCert = false;
            this.isSugarCRM = true;
        }
        console.log('Event: ', event.detail);
        console.log('Option selected with value: ' + this.certRecordTypeId);
    }

}