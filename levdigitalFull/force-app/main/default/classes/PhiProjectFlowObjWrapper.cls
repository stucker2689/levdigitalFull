/**
 * Created 2/25/2022
 * Sam Tucker
 * Used in Project PHI Status/History Flow as custom object to hold Project Record and related PHI History Object in single variable
 */
public with sharing class PhiProjectFlowObjWrapper {
    
    @AuraEnabled
    public Project__c phiProject;

    @AuraEnabled
    public PHI_History__c phiHistoryRecord; 

    @AuraEnabled
    public Boolean hasUnResolvedPhiHistoryRec;

    @AuraEnabled
    public Boolean hasTimeEntryInLast14Days;
    
    public PhiProjectFlowObjWrapper() {

    }
}