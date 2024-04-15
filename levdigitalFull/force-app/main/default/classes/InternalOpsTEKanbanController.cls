public with sharing class InternalOpsTEKanbanController {
    
    private static String trainingAndEnablementRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Training & Enablement').getRecordTypeId();

    private static String sprintPlanWeekRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Week').getRecordTypeId();
    private static String sprintPlanMonthRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Month').getRecordTypeId();
    private static String sprintPlanQuarterRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Quarter').getRecordTypeId();

    //private static List<String> sprintViewShownStatusList = new List<String>{'New', 'Assigned', 'In Process', 'On Hold'};    //New Values for Sprint Views  
    private static List<String> sprintViewShownStatusList = new List<String>{ 'Assigned', 'In Process'};    //New Values for Sprint Views  


    //Get All Internal Cases for Status Kanban View
    @AuraEnabled
    public static List<Case> getInternalCasesForStatusKanban(){
    //public static List<Case> getInternalCasesForStatusKanban(String monthsBack){
        
        List<Case> allInProcessCases = new List<Case>();
        List<Case> internalCasesNotInProcess = new List<Case>();
        List<Case> allKanbanCases = new List<Case>();    

        internalCasesNotInProcess = [SELECT Id, Subject, Status, Internal_Request_Type__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c, CreatedDate, 
                                        Days_Case_Open__c, OwnerId, Owner.Name, ContactId, Contact.Name, CaseNumber, Sprint_Week__c, Type, Primary_Department__c, Requirements_Status__c, QA_Status__c, Date_Requirements_Completed__c
                                    FROM Case
                                    WHERE RecordTypeId =: trainingAndEnablementRT AND (CreatedDate = LAST_N_MONTHS:12 OR CreatedDate = THIS_MONTH)  
                                            AND Status != 'Completed' AND Status != 'Cancelled' AND Status != 'In Process'
                                    ORDER BY CreatedDate ASC];

        allInProcessCases = [SELECT Id, Subject, Status, Internal_Request_Type__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c, CreatedDate, 
                                    Days_Case_Open__c, OwnerId, Owner.Name, ContactId, Contact.Name, CaseNumber, Sprint_Week__c, Type, Primary_Department__c, Requirements_Status__c, QA_Status__c, Date_Requirements_Completed__c
                                FROM Case
                                WHERE RecordTypeId =: trainingAndEnablementRT AND Status = 'In Process'
                                ORDER BY CreatedDate ASC];

        allKanbanCases.addAll(internalCasesNotInProcess);
        allKanbanCases.addAll(allInProcessCases);

        return allKanbanCases;

    }
    //Get Sprint Plan Weeks
    @AuraEnabled
    public static List<Sprint_Plan__c> getSprintWeekPlansForWeekKanban(){

        List<Sprint_Plan__c> sprintWeekPlans = new List<Sprint_Plan__c>();

        sprintWeekPlans = [SELECT Id, Name, Sprint_Week__c, Sprint_Week_Date__c, Estimated_Hours_per_Week__c, Case__c, Case__r.Subject, Case__r.Status, Case__r.Internal_Request_Type__c, Case__r.Start_Date__c, Case__r.Due_Date_Internal__c, 
                                Case__r.Internal_Ops_Estimated_Hours__c, Case__r.CreatedDate, Case__r.Days_Case_Open__c, Case__r.OwnerId, Case__r.Owner.Name, Case__r.ContactId, 
                                Case__r.Contact.Name, Case__r.CaseNumber, Case__r.Sprint_Week__c, Case__r.Type, Case__r.Primary_Department__c, Case__r.Requirements_Status__c, Case__r.QA_Status__c, Case__r.Date_Requirements_Completed__c,
                                Case__r.Owner.Type
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanWeekRT AND Case__r.RecordTypeId = :trainingAndEnablementRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Owner.Type = 'User' 
                                AND (Case__r.CreatedDate = LAST_N_MONTHS:12 OR Case__r.CreatedDate = THIS_MONTH)  
                            ORDER BY Case__r.Due_Date_Internal__c DESC];

        return sprintWeekPlans;
            
    }


    //Get Sprint Plan Months
    @AuraEnabled
    public static List<Sprint_Plan__c> getSprintMonthPlansForMonthKanban(){

        List<Sprint_Plan__c> sprintMonthPlans = new List<Sprint_Plan__c>();

        sprintMonthPlans = [SELECT Id, Name, Sprint_Month__c, Sprint_Month_Date__c, Estimated_Hours_for_Month__c, Case__c, Case__r.Subject, Case__r.Status, Case__r.Internal_Request_Type__c, Case__r.Start_Date__c, Case__r.Due_Date_Internal__c, 
                                Case__r.Internal_Ops_Estimated_Hours__c, Case__r.CreatedDate, Case__r.Days_Case_Open__c, Case__r.OwnerId, Case__r.Owner.Name, Case__r.ContactId, 
                                Case__r.Contact.Name, Case__r.CaseNumber, Case__r.Sprint_Week__c, Case__r.Type, Case__r.Primary_Department__c, Case__r.Requirements_Status__c, Case__r.QA_Status__c, Case__r.Date_Requirements_Completed__c,
                                Case__r.Owner.Type
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanMonthRT AND Case__r.RecordTypeId = :trainingAndEnablementRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Owner.Type = 'User'
                            AND (Case__r.CreatedDate = LAST_N_MONTHS:12 OR Case__r.CreatedDate = THIS_MONTH)  
                            ORDER BY Case__r.Due_Date_Internal__c DESC, Sprint_Month_Date__c ASC];

        return sprintMonthPlans;
            
    }

    //Get Sprint Plan Quarters
    @AuraEnabled
    public static List<Sprint_Plan__c> getSprintQuarterPlansForQuarterKanban(){

        List<Sprint_Plan__c> sprintQuarterPlans = new List<Sprint_Plan__c>();

        sprintQuarterPlans = [SELECT Id, Name, Sprint_Quarter__c, Estimated_Hours_for_Quarter__c, Case__c, Case__r.Subject, Case__r.Status, Case__r.Internal_Request_Type__c, Case__r.Start_Date__c, Case__r.Due_Date_Internal__c, 
                                Case__r.Internal_Ops_Estimated_Hours__c, Case__r.CreatedDate, Case__r.Days_Case_Open__c, Case__r.OwnerId, Case__r.Owner.Name, Case__r.ContactId, 
                                Case__r.Contact.Name, Case__r.CaseNumber, Case__r.Sprint_Week__c, Case__r.Type, Case__r.Primary_Department__c, Case__r.Requirements_Status__c, Case__r.QA_Status__c, Case__r.Date_Requirements_Completed__c,
                                Case__r.Owner.Type
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanQuarterRT AND Case__r.RecordTypeId = :trainingAndEnablementRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Owner.Type = 'User'
                                AND (Case__r.CreatedDate = LAST_N_MONTHS:12 OR Case__r.CreatedDate = THIS_MONTH)  
                            ORDER BY Case__r.Due_Date_Internal__c DESC];

        return sprintQuarterPlans;
            
    }

    

    @AuraEnabled
    public static string updateRec(string recordId, string recordField, string newValue){
        try{
            Schema.DescribeSObjectResult sObjRes = Id.valueOf(recordId).getSObjectType().getDescribe();
            //Schema.DescribeFieldResult fldRes = sObjRes.fields.getMap().get(recField).getDescribe();
            //if(sObjRes.isAccessible() && sObjRes.isUpdateable() && fldRes.isUpdateable()){
                String sObjName = sObjRes.getName();
                sObject s = Schema.getGlobalDescribe().get(sObjName).newSObject() ;
                s.Id = recordId;
                s.put(recordField, newValue);
                update s;
                return 'true';
            
        }
        catch(exception e){
            return e.getMessage();
        }
    }
}