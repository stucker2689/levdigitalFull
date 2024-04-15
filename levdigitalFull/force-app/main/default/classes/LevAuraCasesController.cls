/**
* @author LevDigital
* @date 2019
*
* @group Cases
* @group-content ../../ApexDocContent/Cases.htm
*
* @description LevAuraCasesController retrieves all record types for a specific sobject, used for LevAuraCase Aura component
*/

public with sharing class LevAuraCasesController {
    /*******************************************************************************************************
    * @description retrieves record types for a specific sobject with the descriptions
    * @param objectName name of sobject
    * @param projectId - Id of the project
    * @param recordTypeNames - List of Recordtype names to return with the descriptions
    * @return Returns List<PickListOptions> wrapper class
    */
    @AuraEnabled
    public static CasesWrapper fetchRecordTypeValuesPick(String objectName,string projectId,String type ){
        CasesWrapper caseWrap = new CasesWrapper();
         List<String> allowedCaseRecordTypes = new List<String>();
        List<NewCaseButtonRecordType__mdt> newCaseButonRecordTypes = [SELECT Id,Label FROM NewCaseButtonRecordType__mdt WHERE Active__c = true AND Type__c =:type];
        for(NewCaseButtonRecordType__mdt newCaseButonRecordType:newCaseButonRecordTypes){
            allowedCaseRecordTypes.add(newCaseButonRecordType.Label);
        }
        List<PickListOptions> pickList = new List<PickListOptions>();
        if(String.isBlank(objectName) && !newCaseButonRecordTypes.isEmpty()){
            objectName = newCaseButonRecordTypes[0].ObjectName__c;
        }
        List<RecordType> recordTypes = [SELECT Id,Name,Description FROM RecordType where sobjecttype =:objectName AND Name IN:allowedCaseRecordTypes];
        Integer rtSize = recordTypes.size();
        if(rtSize> 0){
            pickList.add(new PickListOptions(recordTypes[rtSize -1].Name, String.valueOf(recordTypes[rtSize-1].Id),recordTypes[rtSize-1].Description));
            for(RecordType rt : recordTypes){
                if(rt.Name != 'Master' && rt.Name.Trim() != '' && rt.Name !=recordTypes[rtSize -1].Name) {
                    pickList.add(new PickListOptions(rt.Name, String.valueOf(rt.Id),rt.Description));
                }
            }
        }
        //add Campaign Services seperately since its not a record type and it will invoke a flow
        if(allowedCaseRecordTypes.contains('Campaign Services')){
            pickList.add(new PickListOptions('Campaign Services', 'Campaign Services','Use when requesting Campaign Services'));
        }
        caseWrap.pickListOptions = pickList;
        Project__c proj = new Project__c();
        if(String.isNotBlank(projectId)){
            List<Project__c> projects = [SELECT Id,Name, Account__c, Project_Manager__c,Project_Manager__r.Name,Account__r.Delivery_Account_Lead__c,Account__r.ManagingDirector__c FROM Project__c WHERE Id=:projectId];
            if(projects.size()> 0){
                proj = projects[0];
                List<Contact> pmContacts = [SELECT Id,Name FROM Contact WHERE Name =:proj.Project_Manager__r.Name LIMIT 1];
                if(pmContacts.size() == 1){
                    caseWrap.projectManagerID = pmContacts[0].Id;
                }
                List<RecordType> caseRecordTypes = [SELECT Id,Name FROM RecordType WHERE sObjectType = 'Case' AND Name IN:allowedCaseRecordTypes];
                caseWrap.caseRecordTypes = caseRecordTypes;
            }
        }
        

        caseWrap.proj = proj;
        return caseWrap;
    }
     /*******************************************************************************************************
    * @description Calls the campaign services flow in salesforce and passes parameters to flow
    * @param projectId - Id of the project
    * @param recordTypeId - recordtype of case
    * @param contactId - contactId of the project manager
    * @param projectName - Name of the project
    * @return Returns error string if exception occurs
    */
    @AuraEnabled
    public static String callCampaignFlow(string projectId,string recordTypeId, string contactId,string projectName ){
        string retVal;
        try{
            // Call the Flow
            Map<String, Object> params = new Map<String, Object>();
            params.put('projectID', projectId);
            params.put('contactID', contactId);
            params.put('projectName', projectName);
            params.put('recordTypeID', recordTypeId);

            Flow.Interview.Campaign_Services_Cases campFlow = new Flow.Interview.Campaign_Services_Cases(params);
            campFlow.start();
            Boolean isParentCaseCreated = (Boolean) campFlow.getVariableValue('IsParentCaseCreated');
            if(isParentCaseCreated == false){
                throw new custException('Can not create Parent Case');
            }
        }
        Catch(Exception e){
            retVal = 'Error: ' + e.getLineNumber() + ' : ' + e.getMessage();
        }
        return retVal;
    }    
      /*******************************************************************************************************
    * @description retrieves record types for a specific sobject with the descriptions
    * @param type- List of Recordtype names to return with the descriptions
    * @return Returns List<PickListOptions> wrapper class
    */
    @AuraEnabled
    public static  ChildWrapper fetchRecordTypeValuesPickChild(string projectId,String type ){
        ChildWrapper childWrap = new ChildWrapper();
         List<String> allowedCaseRecordTypes = new List<String>();
        List<NewCaseButtonRecordType__mdt> newCaseButonRecordTypes = [SELECT Id,Label,ObjectName__c FROM NewCaseButtonRecordType__mdt WHERE Active__c = true AND Type__c =:type];
        for(NewCaseButtonRecordType__mdt newCaseButonRecordType:newCaseButonRecordTypes){
            allowedCaseRecordTypes.add(newCaseButonRecordType.Label);
        }
        String objectName;
        List<PickListOptions> pickList = new List<PickListOptions>();
        if(!newCaseButonRecordTypes.isEmpty()){
            objectName = newCaseButonRecordTypes[0].ObjectName__c;
            childWrap.objectName = objectName;
            if(String.isNotBlank(objectName)){
                String objectLabel = Schema.describeSObjects(new List<String>{objectName})[0].getLabel();
                childWrap.objectLabel = objectLabel;
            }
        }
        List<RecordType> recordTypes = [SELECT Id,Name,Description FROM RecordType where sobjecttype =:objectName AND Name IN:allowedCaseRecordTypes];
        Integer rtSize = recordTypes.size();
        if(rtSize> 0){
            pickList.add(new PickListOptions(recordTypes[rtSize -1].Name, String.valueOf(recordTypes[rtSize-1].Id),recordTypes[rtSize-1].Description));
            for(RecordType rt : recordTypes){
                if(rt.Name != 'Master' && rt.Name.Trim() != '' && rt.Name !=recordTypes[rtSize -1].Name) {
                    pickList.add(new PickListOptions(rt.Name, String.valueOf(rt.Id),rt.Description));
                }
            }
        }
        //add Campaign Services seperately since its not a record type and it will invoke a flow
        if(allowedCaseRecordTypes.contains('Campaign Services')){
            pickList.add(new PickListOptions('Campaign Services', 'Campaign Services','Use when requesting Campaign Services'));
        }
        childWrap.pickListOptions = pickList;
        Project__c proj = new Project__c();
        if(String.isNotBlank(projectId)){
            List<Project__c> projects = [SELECT Id,Name, Account__c, Project_Manager__c,Project_Manager__r.Name,Account__r.Delivery_Account_Lead__c,Account__r.ManagingDirector__c FROM Project__c WHERE Id=:projectId];
            if(projects.size()> 0){
                proj = projects[0];
                List<Contact> pmContacts = [SELECT Id,Name FROM Contact WHERE Name =:proj.Project_Manager__r.Name LIMIT 1];
                if(pmContacts.size() == 1){
                    childWrap.projectManagerID = pmContacts[0].Id;
                }
                List<RecordType> caseRecordTypes = [SELECT Id,Name FROM RecordType WHERE sObjectType = 'Case' AND Name IN:allowedCaseRecordTypes];
                childWrap.caseRecordTypes = caseRecordTypes;
            }
        }
        

        childWrap.proj = proj;
        return childWrap;
    }
    public class CasesWrapper{
        @AuraEnabled
        public List<PickListOptions> pickListOptions{get;set;}
        @AuraEnabled
        public Project__c proj{get;set;}
        @AuraEnabled
        public String projectManagerID{get;set;}
        @AuraEnabled
        public List<RecordType> caseRecordTypes{get;set;}
    }
    public class ChildWrapper{
        @AuraEnabled
        public List<PickListOptions> pickListOptions{get;set;}
        @AuraEnabled
        public Project__c proj{get;set;}
        @AuraEnabled
        public String projectManagerID{get;set;}
        @AuraEnabled
        public String objectName{get;set;}
        @AuraEnabled
        public String objectLabel{get;set;}
        @AuraEnabled
        public List<RecordType> caseRecordTypes{get;set;}
    }
    public class PickListOptions{
        @AuraEnabled
        public String label{get;set;}
        @AuraEnabled
        public String value{get;set;}
        @AuraEnabled
        public String description{get;set;}
        public PickListOptions(String lbl,String vle,string desript){
            this.label = lbl;
            this.value = vle;
            this.description = desript;
        }
    }
    private class custException extends Exception {}
}