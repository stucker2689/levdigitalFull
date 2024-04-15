public class ContactTriggerHandler {

    private static String employeeContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    private static String placeholderContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Placeholder Employee').getRecordTypeId();


    public static void onBeforeInsert(List<Contact> newList){

        List<Contact> updateContactWorkLogList = new List<Contact>();
        List<Contact> updateContactNPSContexttLogList = new List<Contact>();

        for(Contact c : newList){

            //Check if Work Log needs to be set
            if(c.Latest_Work_Log__c != null){
                updateContactWorkLogList.add(c);
            }

            //Check if NPS Context is populated and NPS Context Log needs to be set
            if(c.NPS_Context__c != null){
                updateContactNPSContexttLogList.add(c);
            }

            //createSurvey(c);
        }

        if(updateContactWorkLogList.size() > 0){
            ContactTriggerHelper.setContactWorkLog(updateContactWorkLogList, null, 'Before Insert');
        }

        if(updateContactNPSContexttLogList.size() > 0){
            ContactTriggerHelper.setContactNPSContextLog(updateContactNPSContexttLogList, null, 'Before Insert');
        }

    }

    public static void onAfterInsert(List<Contact> newList){

        List<Contact> contactsToCreateSkillsForList = new List<Contact>();

        Map<Id, Contact> placeholderContactMap = new Map<Id, Contact>();

        for(Contact c : newList){
            if(c.Active__c && c.RecordTypeId == employeeContactRT && c.Department == Label.Employee_Department && c.Division_New__c != Label.Division_Op_Management) {
                Id levAccountId = getLevementumAccountId();
                System.debug('levAccountId: ' + levAccountId);
                if(levAccountId != null && c.AccountId == levAccountId){
                    contactsToCreateSkillsForList.add(c);
                }
            }

            if(c.RecordTypeId == placeholderContactRT && c.Quarterly_Target__c != null && c.RampTime__c != null && c.Hire_Date__c != null){
                placeholderContactMap.put(c.Id, c);
            }

            //createSurvey(c);
        }

        if(contactsToCreateSkillsForList.size() > 0) {
            SkillsMatrixService.insertEmployeeSkills(contactsToCreateSkillsForList);
        }

        if(placeholderContactMap.size() > 0){
            ContactTriggerHelper.createPlaceholderTimesheets(placeholderContactMap);
        }

    }

    public static void onBeforeUpdate(List<Contact> newList, Map<Id, Contact> oldMap){
        System.debug('Contact Trigger Handler On Before Update');

        List<Contact> updateContactWorkLogList = new List<Contact>();
        List<Contact> updateContactNPSContexttLogList = new List<Contact>();

        for(Contact c : newList){

            Contact oldContact = oldMap.get(c.Id);

            //Check if Work Log needs to be updated
            if(c.Latest_Work_Log__c != null && c.Latest_Work_Log__c != oldContact.Latest_Work_Log__c){
                updateContactWorkLogList.add(c);
            }

            //Check if NPS Contact Log needs to be updated
            if(c.NPS_Context__c != null && c.NPS_Context__c != oldContact.NPS_Context__c){
                updateContactNPSContexttLogList.add(c);
            }

            //createSurvey(c);
        }

        if(updateContactWorkLogList.size() > 0){
            ContactTriggerHelper.setContactWorkLog(updateContactWorkLogList, oldMap, 'Before Update');
        }

        if(updateContactNPSContexttLogList.size() > 0){
            ContactTriggerHelper.setContactNPSContextLog(updateContactNPSContexttLogList, oldMap, 'Before Update');
        }
    }

    public static void onAfterUpdate(List<Contact> newList, Map<Id, Contact> oldMap){
        System.debug('Contact Trigger Handler On After Update');

        List<Contact> managerChangedContactsList = new List<Contact>();
        List<Contact> deleteContactSkillsList = new List<Contact>();
        Map<Id, Contact> quarterlyTargetUpdatedContactMap = new Map<Id, Contact>();

        Map<Id, Contact> inactiveContactMap = new Map<Id, Contact>();
        Map<Id, Contact> deleteCertsContactMap = new Map<Id, Contact>();

        Map<Id, Contact> titleChangedContactMap = new Map<Id, Contact>();
        Map<Id, Contact> divisionChangedContactMap = new Map<Id, Contact>();
        Map<Id, Contact> managerChangedContactMap = new Map<Id, Contact>();
        Map<Id, Contact> departmentChangedContactMap = new Map<Id, Contact>();

        Map<Id, Contact> employeeDetailsChangedForWorkDayMap = new Map<Id, Contact>();
        Map<Id, Contact> employeeIdToRecordForRampTimeUpdateMap = new Map<Id, Contact>();
        Map<Id, Contact> employeeIdToRecordForTermDateUpdateMap = new Map<Id, Contact>();
        Map<Id, Contact> employeeIdToRecordForQuarterlyTargetUpdateMap = new Map<Id, Contact>();

        Map<Id, Contact> placeholderContactChangedMap = new Map<Id, Contact>();

        for(Contact c : newList){

            Contact oldContact = oldMap.get(c.Id);

            //Check if Related Out of Office Cases need to be re-assigned if Reports To field is changed.
            if(c.Active__c && c.ReportsToId != oldMap.get(c.Id).ReportsToId){
                managerChangedContactsList.add(c);
            }

            //Check if Employee has been moved to inactive to delete Contact Skills
            if(!c.Active__c && oldContact.Active__c && c.RecordTypeId == employeeContactRT) {
                Id levAccountId = getLevementumAccountId();
                if(levAccountId != null && c.AccountId == levAccountId){
                    deleteContactSkillsList.add(c);
                }
            }

             //When Contact is changed to Inactive and Replicon User Number AND Record Type is Employee then delete the future timesheets to get rid of future PTO time for People that are no longer with the company.	
             if(!c.Active__c && oldContact.Active__c && c.RecordTypeId == employeeContactRT){
                deleteCertsContactMap.put(c.Id, c);	
                 if(c.Replicon_User_Number__c != null){
                    inactiveContactMap.put(c.Id, c);
                 }
             }

            //If Quarterly Target Changes then update the Week Target on all their related Timesheets (only current and future timesheets though)
            if(c.Quarterly_Target__c != oldContact.Quarterly_Target__c){
                quarterlyTargetUpdatedContactMap.put(c.Id, c);
                employeeIdToRecordForQuarterlyTargetUpdateMap.put(c.Id, c);
            }

            //If Ramp Time or Ramp Date ends then check the expected hours of any existing Timesheets for the dates that would be affected by the change

            /************************** Uppdate Employee Detail Fields on Timesheet **********************************/
            if(c.Title != null && c.Title != oldContact.Title && c.RecordTypeId == employeeContactRT){
                titleChangedContactMap.put(c.Id, c);
            }

            if(c.Division_New__c != null && c.Division_New__c != oldContact.Division_New__c && c.RecordTypeId == employeeContactRT){
                divisionChangedContactMap.put(c.Id, c);
                employeeDetailsChangedForWorkDayMap.put(c.Id, c);
            }

            if(c.ReportsToId != null && c.ReportsToId != oldContact.ReportsToId && c.RecordTypeId == employeeContactRT){
                managerChangedContactMap.put(c.Id, c);
                employeeDetailsChangedForWorkDayMap.put(c.Id, c);
            }

            if(c.Department != null && c.Department != oldContact.Department && c.RecordTypeId == employeeContactRT){
                departmentChangedContactMap.put(c.Id, c);
            }
            /**********************************************************************************************************/

            if(c.RecordTypeId == placeholderContactRT && (c.Quarterly_Target__c != oldContact.Quarterly_Target__c || c.RampTime__c != oldContact.RampTime__c || c.Hire_Date__c != oldContact.Hire_Date__c)){
                placeholderContactChangedMap.put(c.Id, c);
            }

            if(oldContact.RecordTypeId == placeholderContactRT && c.RecordTypeId != oldContact.RecordTypeId){
                placeholderContactChangedMap.put(c.Id, c);
            }

            /************************** Uppdate Employee Work Days Working Hours from Updates to Ramp Time or Termination Date **********************************/
            if(c.Hire_Date__c != oldContact.Hire_Date__c || c.RampTime__c != oldContact.RampTime__c){
                employeeIdToRecordForRampTimeUpdateMap.put(c.Id, c);
            }

            if(c.Term_Date__c != oldContact.Term_Date__c){
                employeeIdToRecordForTermDateUpdateMap.put(c.Id, c);
            }
            /**********************************************************************************************************/

            //createSurvey(c);
        }

        if(managerChangedContactsList.size() > 0){
            ContactTriggerHelper.updateRelatedOoOCases(managerChangedContactsList);
        }

        if(deleteContactSkillsList.size() > 0) {
            SkillsMatrixService.deleteEmployeeSkills(deleteContactSkillsList);
        }

        if(inactiveContactMap.size() > 0){
            ContactTriggerHelper.removeFutureTimesheetsAndEntriesForInactiveContacts(inactiveContactMap);
        }

        if(deleteCertsContactMap.size() > 0){
            ContactTriggerHelper.deleteInactiveContactCertifications(deleteCertsContactMap);
        }

        if(quarterlyTargetUpdatedContactMap.size() > 0){
            ContactTriggerHelper.updateContactTimesheetWeekTargets(quarterlyTargetUpdatedContactMap);
        }

        if(titleChangedContactMap.size() > 0 || divisionChangedContactMap.size() > 0  || managerChangedContactMap.size() > 0){
            ContactTriggerHelper.updateTimesheetContactDetails(titleChangedContactMap, divisionChangedContactMap, managerChangedContactMap, departmentChangedContactMap);
        }

        if(employeeDetailsChangedForWorkDayMap.size() > 0){
            ContactTriggerHelper.updateWorkDayEmployeeDetails(employeeDetailsChangedForWorkDayMap);
        }

        if(placeholderContactChangedMap.size() > 0){
            ContactTriggerHelper.createPlaceholderTimesheets(placeholderContactChangedMap);
        }
        
        if(employeeIdToRecordForRampTimeUpdateMap.size() > 0){
            ContactTriggerHelper.updateWorkDayWorkingHours(employeeIdToRecordForRampTimeUpdateMap, oldMap, true, false, false);
        }

        if(employeeIdToRecordForTermDateUpdateMap.size() > 0){
            ContactTriggerHelper.updateWorkDayWorkingHours(employeeIdToRecordForTermDateUpdateMap, oldMap, false, true, false);
        }
        
        if(employeeIdToRecordForQuarterlyTargetUpdateMap.size() > 0){
            ContactTriggerHelper.updateWorkDayWorkingHours(employeeIdToRecordForQuarterlyTargetUpdateMap, oldMap, false, false, true);
        }

    }

    public static void onAfterDelete(List<Contact> newList){

    }


    private static Id getLevementumAccountId(){
        Id levAccountId;
        List<Account> levAccountList = new List<Account>();
        levAccountList = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1];
        if(levAccountList.size() > 0){
            levAccountId = levAccountList[0].Id;
        }

        return levAccountId;
    }

    /*
    public static void createSurvey(Contact ct) {
        try {
            if(ct.Is_Survey_Completed__c) {
                Map<Id, Survey__c> surveys = new Map<Id, Survey__c>();
                List<Survey__c> surveysToInsert = new List<Survey__c>();
                Map<Id, Project__c> projectsMap = new Map<Id, Project__c>();
                for(Project__c proj : [Select Id, (Select Id from Surveys__r), Client_Project_Lead__c  From Project__c where Client_Project_Lead__c  =: ct.Id and Project_Status__c = 'Completed']) {
                    if(proj.surveys__r.size() <= 0) {
                        Survey__c survey = new Survey__c();
                    	survey.Project__c = proj.Id;
                    	survey.Name = ct.FirstName + ' ' + ct.LastName + ' ' + system.today();
                    	surveysToInsert.add(survey);
                    }
                }
                insert surveysToInsert;
                
                for(Survey__c surv : surveysToInsert) {
                    surveys.put(surv.Id, surv);
                }
                
                List<Survey_Question__c> surveyQuestionsToInsert = new List<Survey_Question__c>();
                for(Id survId : surveys.KeySet()) {
                 	Survey_Question__c surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Likelihood_you_ll_recommend_Lev_to_anoth__c;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Will you recommend Lev to another company?';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.How_your_participation__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'How your actual participation in the project matched your expectations?';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_Communication_with_you__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s communication with you';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_Knowledge_of_Salesforce_Prods__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s knowledge of Salesforce products?';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_Project__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s project scoping accuracy for price and timeline?';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_adherence__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s adherence to project timeline';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_implementation_skills__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s implementation skills (requirements generation, design, and testing)';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Score__c = ct.Lev_s_process_for_project_completion__c ;
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.Name = 'Lev\'s process for project completion';
                    surveyQuestionsToInsert.add(surveyQuestion);
                    
                    surveyQuestion = new Survey_Question__c();
                    surveyQuestion.Survey__c = survId;
                    surveyQuestion.comments__c = ct.What_you_d_tell__c; 
                    surveyQuestion.Name = 'What you\'d tell other companies about Lev?';
                    surveyQuestionsToInsert.add(surveyQuestion);
                }
                insert surveyQuestionsToInsert;
            }
        } catch(Exception ex) {
            system.debug(ex.getStackTraceString());
        }
    }
    */
}