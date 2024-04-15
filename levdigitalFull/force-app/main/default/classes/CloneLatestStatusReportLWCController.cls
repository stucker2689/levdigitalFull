public with sharing class CloneLatestStatusReportLWCController {

    @AuraEnabled(cacheable = true)
    public static Status_Report__c getLatestStatusReportToClone(Id projectId){
        
        Status_Report__c latestStatusReport = new Status_Report__c();
        latestStatusReport = [SELECT Id, Name, Executive_Summary__c, Budget_Comments__c, Customer_Comments__c, Last_Status_Report_E_Mailed_On__c, Latest_Status_Report_Sent_Date__c, Lev_Internal_Help_Needed__c, Project_Manager__c,
                                    Overall_Health_Comments__c, Plans_for_Next_Period__c, Project__c, Reporting_Period_Ending__c, Reporting_Period_From__c, Risk_Comments__c, Schedule_Comments__c, Key_Accomplishments_This_Period__c,
                                    Scope_Comments__c, Status_Report_Notes__c, Account__c, Project__r.SR_Overall_Health_Value__c, Project__r.SR_Schedule_Value__c ,Project__r.SR_Scope_Value__c ,Project__r.SR_Budget_Value__c ,Project__r.SR_Risk_Value__c,
                                    Project__r.SR_Scope_Comments__c, Project__r.SR_Schedule_Comments__c, Project__r.SR_Risk_Comments__c, Project__r.SR_Overall_Health_Comments__c, Project__r.SR_Budget_Comments__c
                                FROM Status_Report__c 
                                WHERE Project__c =: projectId 
                                ORDER BY CreatedDate DESC LIMIT 1];
                                //Changed from Reporting_Period_Ending__c to CreatedDate

        return latestStatusReport;
    }


    @AuraEnabled(cacheable = true)
    public static Project__c getProjectDetailsForNewStatusReport(Id projectId){        

        Project__c proj = [SELECT Id, Name, Account__c, SR_Overall_Health_Value__c, SR_Schedule_Value__c ,SR_Scope_Value__c ,SR_Budget_Value__c ,SR_Risk_Value__c, Project_Manager__c,
                                SR_Scope_Comments__c, SR_Schedule_Comments__c,SR_Risk_Comments__c,SR_Overall_Health_Comments__c, SR_Budget_Comments__c
                            FROM Project__c
                            WHERE Id =: projectId LIMIT 1];

        return proj;
    }
}