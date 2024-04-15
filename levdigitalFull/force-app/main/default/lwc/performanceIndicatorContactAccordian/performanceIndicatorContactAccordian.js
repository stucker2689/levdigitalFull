import { LightningElement, wire, api } from 'lwc';
import HIRE_DATE_FIELD from '@salesforce/schema/Contact.Hire_Date__c';
import RAMP_TIME_FIELD from '@salesforce/schema/Contact.RampTime__c';
import RAMP_END_DATE_FIELD from '@salesforce/schema/Contact.Ramp_End_Date__c';
import CURRENT_UTILIZATION_TARGET_FIELD from '@salesforce/schema/Contact.Current_Utilization_Target__c';
import QUARTERLY_TARGET_FIELD from '@salesforce/schema/Contact.Quarterly_Target__c';
import BILLED_HOURS_THIS_QUARTER from '@salesforce/schema/Contact.Billed_Hours_this_Quarter__c';
import BILLED_HOURS_LAST_QUARTER from '@salesforce/schema/Contact.Billed_Hours_Last_Quarter__c';
import QTD_TARGET_ATTAINMENT from '@salesforce/schema/Contact.QTD_Target_Attainment__c';
import HPW_NEEDED_TO_HIT_QT from '@salesforce/schema/Contact.HPW_Needed_to_Hit_Quarter_Target__c';
import WEEKLY_TARGET_FIELD from '@salesforce/schema/Contact.Weekly_Target__c';


import CERTIFICATION_COUNT_FIELD from '@salesforce/schema/Contact.SFDC_Certification_Count__c';
import CERTIFIED_CONSULTANT_FIELD from '@salesforce/schema/Contact.Certified_Consultant__c';

export default class PerformanceIndicatorContactAccordian extends LightningElement {
    @api recordId;
    error;
    contactTargetAndUtilFields = [RAMP_TIME_FIELD, RAMP_END_DATE_FIELD, WEEKLY_TARGET_FIELD, QUARTERLY_TARGET_FIELD, BILLED_HOURS_THIS_QUARTER, BILLED_HOURS_LAST_QUARTER, QTD_TARGET_ATTAINMENT, HPW_NEEDED_TO_HIT_QT];

    contactCertificationFields = [CERTIFICATION_COUNT_FIELD, CERTIFIED_CONSULTANT_FIELD];
}