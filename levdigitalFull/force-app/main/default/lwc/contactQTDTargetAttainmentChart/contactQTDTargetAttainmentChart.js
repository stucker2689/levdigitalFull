import { LightningElement, api, track, wire } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import chartjs from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getContact from '@salesforce/apex/PerformanceIndicatorLWCController.getRelatedContact';

import QTD_EXPECTED_HOURS_FIELD from '@salesforce/schema/Contact.QTD_Expected_Hours__c';
import QTD_TARGET_ATTAINMENT_FIELD from '@salesforce/schema/Contact.QTD_Target_Attainment__c';
import BILLED_HOURS_THIS_QUARTER_FIELD from '@salesforce/schema/Contact.Billed_Hours_this_Quarter__c';
import QUARTERLY_BUDGET_FIELD from '@salesforce/schema/Contact.Quarterly_Target__c';

const FIELDS = [QTD_EXPECTED_HOURS_FIELD, BILLED_HOURS_THIS_QUARTER_FIELD, QTD_TARGET_ATTAINMENT_FIELD, QUARTERLY_BUDGET_FIELD];

export default class ContactQTDTargetAttainmentChart extends LightningElement {
    @api recordId;

    chartConfiguration;
 
    @wire(getContact, { contactRecordId: '$recordId'})
    getContact({error, data}) {
        if (error) {
            this.error = error;
            this.chartConfiguration = undefined;
        } else if (data) {
            let expectedHours = [];
            let billedHours = [];
            let chartLabel = [];
            data.forEach(con => {
                expectedHours.push(con.QTD_Expected_Hours__c);
                billedHours.push(con.Billed_Hours_this_Quarter__c);
                chartLabel.push(con.Name);
            });
 
            this.chartConfiguration = {
                type: 'bar',
                data: {
                    datasets: [    
                        {
                            label: 'Billed Hours this Quarter',
                            backgroundColor: [
                                'rgba(88, 114, 193, 1)'
                            ],
                            pointBackgroundColor: 'rgba(255, 255, 255, 0.2)',
                            pointBorderColor: 'rgba(255, 255, 255, 1)',
                            data: billedHours,
                        },{
                            label: 'QTD Expected Hours',
                            backgroundColor: [
                                'rgba(176, 196, 253, 1)'
                            ],
                            data: expectedHours,
                        },
                    ],
                    labels: chartLabel,
                },
                options: {
                    title: {
                        display: true,
                        text: 'QTD Target Attainment'
                    },
                    scales: {
                        yAxes: [{
                            ticks: {
                                beginAtZero: true
                            }
                        }]
                      }
                },
            };
            this.error = undefined;
        }else{
            refreshApex(this.getContact);
        }
    }
}