import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import getForecastData from '@salesforce/apex/ForecastProjectRelatedListLWCController.getProjectForecastData';

const COLUMNS = [
    { label: 'Forecast Name', fieldName: 'forecastUrl', type: 'url', hideDefaultActions:'true', typeAttributes:{label: { fieldName: 'forecastName' }}}, 
    { label: 'Employee', fieldName: 'employeeUrl', type: 'url', hideDefaultActions:'true', typeAttributes:{label: { fieldName: 'employeeName' }} },
    { label: 'Forecasted Hours', fieldName: 'estimatedHours', type: 'number', hideDefaultActions:'true', initialWidth: 160, cellAttributes: { alignment: 'left' }},
    { label: 'Forecasted Revenue', fieldName: 'estimatedRevenue', type: 'currency', hideDefaultActions:'true', cellAttributes: { alignment: 'left' }}
];

export default class ForecastProjectRelatedListLWC extends NavigationMixin(LightningElement) {

    columns = COLUMNS;
    isForecastTableLoading = false;
    displayForecastTable = true;
    forecastRecordCount = 0;
    forecastTableLoading = true;
    tableheight = 'border:1px #C9C9C9;';
    @api recordId;

    @wire(getForecastData, {projectId: '$recordId'})
    forecastData;

    renderedCallback(){
        if(this.forecastData.data){
            this.forecastRecordCount = (this.forecastData.data).length;
            if(this.forecastRecordCount > 12){
                this.tableheight = 'height: 300px;border:1px #C9C9C9;';
            }
            this.forecastTableLoading = false;
        }else if(this.forecastData.error){
            this.forecastTableLoading = false;
        }else{
            console.log('No Data');
        }
        this.displayTeamMemberTable = true;
    }

    async refresh(){
        await refreshApex(this.forecastData);
    }

    navigateToContactRelatedList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Project__c',
                relationshipApiName: 'Replicon_Forecast__r',
                actionName: 'view'
            },
        });
    }
}