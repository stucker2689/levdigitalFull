import { LightningElement, wire, track, api} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getNonBillOrConcessionCases from '@salesforce/apex/PerformanceIndicatorLWCController.getConccessionAndNonBillCases';

export default class NonbillOrConcessionContactDatatable extends LightningElement {

    @api recordId;

    @track columns = [
        {label: 'Project Name', fieldName: 'caseProjectUrl', type: 'url', typeAttributes: {label: { fieldName: 'caseProjectName' }, target: '_blank'}, sortable: true},
        {label: 'Case Subject', fieldName: 'caseUrl', type: 'url', typeAttributes: {label: { fieldName: 'caseSubject' }, target: '_blank'}, sortable: true},
        {label: 'Approved or Denied', fieldName: 'approvedOrDenied', type: 'text', sortable: true},
        {label: 'Total Hours Requested', fieldName: 'totalHoursRequested', type: 'Number', sortable: true},
        {label: 'Final Hours Logged', fieldName: 'finalHoursLogged', type: 'Number', sortable: true},
    ];

    @track error;
    @track nonbillOrConcessionCases = [];

    allowScroll = false;


    @wire(getNonBillOrConcessionCases, {contactRecordId: '$recordId'})
    wiredCases({error,data}) {
        if (data) {
            this.nonbillOrConcessionCases = data;
            this.error = undefined;
            console.log('DATA IS GOOD!! ', data);
            if(data.length > 6){
                this.allowScroll = true;
            }
        } else if (error) {
            this.error = error;
            this.nonbillOrConcessionCases = undefined;
            console.log('DATA IS BAD :( ', error);
            refreshApex(this.wiredCases);
        }
    }

}