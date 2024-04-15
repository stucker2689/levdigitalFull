import { LightningElement, wire, track, api} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getHoursPerQuarter from '@salesforce/apex/PerformanceIndicatorLWCController.getHoursPerQuarterForContact';

export default class ContactHoursPerQuarterDatatable extends LightningElement {

    @api recordId;

    @track columns = [
        {label: 'Quarter Name', fieldName: 'quarterName', type: 'text', sortable: true, cellAttributes: { alignment: 'center' }},
        {label: 'Billable Hours', fieldName: 'billableHours', type: 'Number', sortable: true, cellAttributes: { alignment: 'right' }},
        {label: 'Project Concession Hours', fieldName: 'concessionHours', type: 'Number', sortable: true, cellAttributes: { alignment: 'right' }},
        {label: 'Internal Concession Hours', fieldName: 'internalConcessionHours', type: 'Number', sortable: true, cellAttributes: { alignment: 'right' }},
        {label: 'Total Credited Hours', fieldName: 'totalCreditedHours', type: 'Number', sortable: true, cellAttributes: { alignment: 'right' }},
        {label: 'Nonbill Hours', fieldName: 'nonBillHours', type: 'Number', sortable: true, cellAttributes: { alignment: 'right' }}
    ];

    @track error;
    @track hoursByQuarterData = [];

    allowScroll = false;

    @wire(getHoursPerQuarter, {contactRecordId: '$recordId'})
    wiredHours({error,data}) {
        if (data) {
            this.hoursByQuarterData = data;
            this.error = undefined;
            if(data.length > 6){
                this.allowScroll = true;
            }
        } else if (error) {
            this.error = error;
            this.hoursByQuarterData = undefined;
            refreshApex(this.wiredHours);
        }
    }
}