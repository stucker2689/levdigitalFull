import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import hasCreateProjTeamMemberPermission from '@salesforce/customPermission/Create_Internal_Project_Team_Member_Custom_Permission';
import hasCreateBillingRatesPermission from '@salesforce/customPermission/Create_New_Project_Billing_Rate';

import getBillRates from '@salesforce/apex/ProjectBillingRateDatatableController.getBillingRateTableData';
import getNewBillingRateOptions from '@salesforce/apex/ProjectBillingRateDatatableController.getNewBillingRateOptions';
import createNewBillingRate from '@salesforce/apex/ProjectBillingRateDatatableController.createNewBillingRate';


const COLUMNS = [
    { label: 'Billing Rate Name', fieldName: 'billingRateName', type: 'text', sortable: "true", initialWidth: 300},
    { label: 'Hourly Rate', fieldName: 'rateHourlyRate', type: 'currency', sortable: "true" },
    { label: 'Hours Sold', fieldName: 'hoursSold', type: 'number', cellAttributes: { alignment: 'right' }, sortable: "true" },
    { label: 'Amount Sold', fieldName: 'amountSold', type: 'currency', sortable: "true" },
    { label: 'Total Hours Billed', fieldName: 'hoursBilled', type: 'number',  cellAttributes: { alignment: 'center' }, sortable: "true"},
    { label: 'Hours Remaining', fieldName: 'rateHoursLeft', type: 'number',  cellAttributes: { alignment: 'center' }, sortable: "true"},
    { label: 'Total Amount Billed', fieldName: 'amountBilled', type: 'currency', cellAttributes: { alignment: 'center' }, sortable: "true"}
];
export default class ProjectBillingRatesTable extends NavigationMixin(LightningElement) {
     
    gridColumns = COLUMNS;
    @api recordId;

    gridData;
    wireData;
    displayProjectBillingRatesTable = true;
    billingRateCount = 0;

    get isCreateNewTeamMemberEnabled(){
        return hasCreateProjTeamMemberPermission;
    }

    get isCreateNewBillRatesEnabled(){
        return hasCreateBillingRatesPermission;
    }



    @wire(getBillRates,{projectId: '$recordId'})
    getBillProjectBillRates( value ) {
        //console.log( 'Inside wire' );
        this.wireData = value;     
        const {data, error} = value;
        if (data){
            this.billingRateCount = 0;
            let tempData = JSON.parse( JSON.stringify( data ));

            for ( let i = 0; i < tempData.length; i++ ) {    
                this.billingRateCount++;
                //console.log('Children Length of: ' + tempData[i].billingRateName + ' length: ', tempData[i].childrenWrappers.length);
                if(tempData[i].childrenWrappers.length > 1){
                    tempData[ i ]._children = tempData[ i ][ 'childrenWrappers' ];
                    delete tempData[ i ].childrenWrappers; 
                }else{
                    //console.log('Children Wrappers: ', tempData[i].childrenWrappers);
                    tempData[i].rateHourlyRate = tempData[i].childrenWrappers[0].rateHourlyRate;
                }   
            }
            this.gridData = tempData;
            this.displayProjectBillingRatesTable = true;
        } else if (error) {                
            if (Array.isArray(error.body)){
                console.error( 'Error is ' + error.body.map( e => e.message ).join( ', ' ) );
            }else if ( typeof error.body.message === 'string' ){
                console.error( 'Error is ' + error.body.message );
            }
        }
    }

    clickToExpandAll(event){
        const grid =  this.template.querySelector( 'lightning-tree-grid' );
        grid.expandAll();
    }

    clickToCollapseAll(event) {
        const grid =  this.template.querySelector( 'lightning-tree-grid' );
        grid.collapseAll();        
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view'
            }
        });
    }

    fetchUpdatedData() {
        refreshApex(this.wireData);
    }

    /********************* Create New Project Billing Rate *********************/
    openCreateNewRateModal = false;
    createNewBillRateIsLoading = false;
    createBillRateError = false;
    createBillRateErrorMessage = '';
    selectedNewBillRateOption = '';
    newBillRateHourlyRate = 210;
    billingRateItems = [];
    productIdToNameMap = new Map();

    @wire(getNewBillingRateOptions)
    billRateOptionsData({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            for(var i=0; i<data.length; i++)  {
                this.billingRateItems = [...this.billingRateItems ,{value: data[i].Id , label: data[i].Name}];
                this.productIdToNameMap.set(data[i].Id, data[i].Name);                   
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    onSubmitBillRate(event){
        event.preventDefault();
        this.createNewBillRateIsLoading = true;
        console.log('Selected Bill Rate Option: ', this.selectedNewBillRateOption);
        console.log('Hourly Rate: ', this.newBillRateHourlyRate);
        if(this.selectedNewBillRateOption != '' && this.selectedNewBillRateOption != null && this.selectedNewBillRateOption != undefined && this.newBillRateHourlyRate != '' && this.newBillRateHourlyRate != null && this.newBillRateHourlyRate != undefined){
            let fields = event.detail.fields;
            fields.Project__c = this.recordId;
            let rateName = this.productIdToNameMap.get(this.selectedNewBillRateOption);
            console.log('Rate Name: ', rateName);
            createNewBillingRate({
                projectId : this.recordId,
                productId: this.selectedNewBillRateOption,
                billRateName: rateName,
                hourlyRate: this.newBillRateHourlyRate})
            .then(result =>{
                //Might need to also check and see if there is already a name that exists that matches this. And if so throw error so we don't duplicate Project Team members
                console.log('Submit Placeholder Result: ', result);
                console.log('Placeholder Fields: ', fields);
                fields.Name = result.Name;
                fields.Product__c = result.Product__c;
                fields.Hourly_Rate__c = result.Hourly_Rate__c;
                fields.Project__c = result.Project__c;
                fields.Created_in_Salesforce = true;
                this.template.querySelector("lightning-record-edit-form").submit(fields);
                this.createBillRateError = false;
                this.createBillRateErrorMessage = '';
                this.createNewBillRateIsLoading = false;
                this.closeModal();
                
            })
            .catch(error =>{
                this.createBillRateError = true;
                this.createNewBillRateIsLoading = false;
                this.createBillRateErrorMessage = error.body.message;
                console.error(error);
            })
        }else{
            this.createBillRateError = true;
            let errorMessage;
            if(this.selectedNewBillRateOption == '' || this.selectedNewBillRateOption == null || this.selectedNewBillRateOption == undefined){
                errorMessage = 'Must Assign a Role for the new Billing Rate';
            }else if(this.newBillRateHourlyRate == '' || this.newBillRateHourlyRate == null || this.newBillRateHourlyRate == undefined){
                errorMessage = 'Hourly Rate must be populated';
            }

            this.createBillRateErrorMessage = errorMessage;
            this.createNewBillRateIsLoading = false;
            console.error('Submit New Bill Rate ERROR: ', errorMessage);
        }

    }

    onSuccessfulBillRateCreation(event){

        const evt = new ShowToastEvent({
            title: "Record Created",
            message: "Project Billing Rate successfully created",
            variant: "success"
        });
        this.dispatchEvent(evt);

        return refreshApex(this.wireData);
    }

    handleBillRateChange(event){
        this.createBillRateError = false;
        console.log('Handle Bill Rate Change Detail Value: ', event.detail.value);
        this.selectedNewBillRateOption = event.detail.value;
    }

    handleHourlyRateChange(event){
        this.createBillRateError = false;
        console.log('Handle Hourly Rate Change Detail Value: ', event.detail.value);
        this.newBillRateHourlyRate = event.detail.value;
    }

    get billRateOptions(){
        return this.billingRateItems;
    }

    createNewBillingRate(event){
        this.openCreateNewRateModal = true;
        this.createNewBillRateIsLoading = false;
        this.createBillRateError = false;
        this.createBillRateErrorMessage = '';
        this.selectedNewBillRateOption = undefined;
        this.newBillRateHourlyRate = undefined;
    }

    closeModal(event){

        /********* Create New Project Billing Rate Modal Closure *********/
        this.openCreateNewRateModal = false;
        this.createNewBillRateIsLoading = false;
        this.createBillRateError = false;
        this.createBillRateErrorMessage = '';
        this.selectedNewBillRateOption = undefined;
        this.newBillRateHourlyRate = undefined;
        /*****************************************************************/
    }
}