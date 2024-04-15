import { LightningElement, wire, api } from 'lwc';
import CERTIFICATION_COUNT_FIELD from '@salesforce/schema/Contact.SFDC_Certification_Count__c';
import CERTIFIED_CONSULTANT_FIELD from '@salesforce/schema/Contact.Certified_Consultant__c';

export default class CertificationContactFieldsForm extends LightningElement {

    @api recordId;
    error;
    contactCertificationFields = [CERTIFICATION_COUNT_FIELD, CERTIFIED_CONSULTANT_FIELD];
}