public with sharing class CustomKanbanController {
    
    private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();

    private static String sprintPlanWeekRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Week').getRecordTypeId();
    private static String sprintPlanMonthRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Month').getRecordTypeId();
    private static String sprintPlanQuarterRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Quarter').getRecordTypeId();

    private static List<String> sprintViewShownStatusList = new List<String>{'New', 'In Process', 'Upcoming', 'Pending'};    //New Values for Sprint Views  
    
    public CustomKanbanController() {

    }

    //Get All Internal Cases for Status Kanban View
    @AuraEnabled
    public static List<Case> getInternalCasesForStatusKanban(){
    //public static List<Case> getInternalCasesForStatusKanban(String monthsBack){
        
        List<Case> allInProcessCases = new List<Case>();
        List<Case> internalCasesNotInProcess = new List<Case>();
        List<Case> allKanbanCases = new List<Case>();    

        internalCasesNotInProcess = [SELECT Id, Subject, Status, Internal_Request_Type__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c, CreatedDate, 
                                        Days_Case_Open__c, OwnerId, Owner.Name, ContactId, Contact.Name, CaseNumber, Sprint_Week__c, Type, Primary_Department__c, Requirements_Status__c, QA_Status__c, Date_Requirements_Completed__c, 
                                        Estimated_QA_Hours__c, QA_Owner__c, QA_Owner__r.Name, TotalEstimatedHours__c, TotalActualHoursWorked__c, TotalQAHoursWorked__c
                                    FROM Case
                                    WHERE RecordTypeId =: internalCaseRT AND (CreatedDate = LAST_N_MONTHS:24 OR CreatedDate = THIS_MONTH)  
                                            AND Status != 'Completed' AND Status != 'Cancelled' AND Status != 'In Process' AND Type = 'Internal SF Support'
                                    ORDER BY CreatedDate ASC];

        allInProcessCases = [SELECT Id, Subject, Status, Internal_Request_Type__c, Start_Date__c, Due_Date_Internal__c, Internal_Ops_Estimated_Hours__c, CreatedDate, 
                                    Days_Case_Open__c, OwnerId, Owner.Name, ContactId, Contact.Name, CaseNumber, Sprint_Week__c, Type, Primary_Department__c, Requirements_Status__c, QA_Status__c, Date_Requirements_Completed__c,
                                    Estimated_QA_Hours__c, QA_Owner__c, QA_Owner__r.Name, TotalEstimatedHours__c, TotalActualHoursWorked__c, TotalQAHoursWorked__c
                                FROM Case
                                WHERE RecordTypeId =: internalCaseRT AND Status = 'In Process' AND Type = 'Internal SF Support'
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
                                Case__r.Owner.Type, Case__r.Estimated_QA_Hours__c, Case__r.QA_Owner__c, Case__r.QA_Owner__r.Name, EstimatedQAHours__c, Case__r.TotalEstimatedHours__c, Case__r.TotalActualHoursWorked__c, Case__r.TotalQAHoursWorked__c
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanWeekRT AND Case__r.RecordTypeId =: internalCaseRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Type = 'Internal SF Support' AND Case__r.Owner.Type = 'User'
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
                                Case__r.Owner.Type, Case__r.Estimated_QA_Hours__c, Case__r.QA_Owner__c, Case__r.QA_Owner__r.Name, Case__r.TotalEstimatedHours__c, Case__r.TotalActualHoursWorked__c, Case__r.TotalQAHoursWorked__c, EstimatedQAHours__c
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanMonthRT AND Case__r.RecordTypeId =: internalCaseRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Type = 'Internal SF Support' AND Case__r.Owner.Type = 'User'
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
                                Case__r.Owner.Type, Case__r.Estimated_QA_Hours__c, Case__r.QA_Owner__c, Case__r.QA_Owner__r.Name, Case__r.TotalEstimatedHours__c, Case__r.TotalActualHoursWorked__c, Case__r.TotalQAHoursWorked__c, EstimatedQAHours__c
                            FROM Sprint_Plan__c
                            WHERE RecordTypeId =: sprintPlanQuarterRT AND Case__r.RecordTypeId =: internalCaseRT AND Case__r.Status IN :sprintViewShownStatusList AND Case__r.Type = 'Internal SF Support' AND Case__r.Owner.Type = 'User'
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