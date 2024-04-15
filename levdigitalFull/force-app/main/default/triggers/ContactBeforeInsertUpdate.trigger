trigger ContactBeforeInsertUpdate on Contact (before insert, before update, after insert, after update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** Last Modifid: Michelle McLane 11/2/2021
** If NPS Context is updated on a contact, the NPS Context Log is appended to tracking who made the change and when
*/	
    /*private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();
	Id employee = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
	String fName = UserInfo.getFirstName();
    String npsContextLog;
    Datetime td = Datetime.now();
    String today = td.Format('MM/dd');
	fName = (fName == null ? '' : fName.substring(0,1));	
	String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
    List<Contact> employees = new List<Contact>();
    List<Contact> managerChangedContactsList = new List<Contact>();
    Id lev = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1].Id;*/

	for(Contact c:Trigger.new) {	
        
		/*if(trigger.isInsert && trigger.isBefore && c.Latest_Work_Log__c != null)
		{
			c.Work_Logs__c = uName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + c.Latest_Work_Log__c;
		}
		else if (trigger.isUpdate && trigger.isBefore && c.Latest_Work_Log__c != null && c.Latest_Work_Log__c != trigger.oldMap.get(c.Id).Latest_Work_Log__c)
		{
			c.Work_Logs__c = (c.Work_Logs__c == null ? '' : c.Work_Logs__c) + '\n' + uName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + c.Latest_Work_Log__c;
		}*/

        /******************* Sam NPS Context Log Logic 11/2/2021 **************************/
        /*if(trigger.isInsert && trigger.isBefore && c.NPS_Context__c != null){
            c.NPS_Context__c = today + ' : ' + c.NPS_Context__c;
            c.NPS_Context_Log__c   = uName + ' ' + c.NPS_Context__c;
        }
        else if (trigger.isUpdate && trigger.isBefore && c.NPS_Context__c != null && c.NPS_Context__c != trigger.oldMap.get(c.Id).NPS_Context__c){
            c.NPS_Context__c = today + ' : ' + c.NPS_Context__c;
            npsContextLog = uName + ' ' + c.NPS_Context__c+ '\n' + (c.NPS_Context_Log__c == null ? '' : c.NPS_Context_Log__c);
            if(npsContextLog.length()>131072) {
                c.NPS_Context_Log__c = ' ' + npsContextLog.left(131072);
            } else {
                c.NPS_Context_Log__c  = npsContextLog;
            }
        }*/
        /**********************************************************************************/


/*
		ContactTriggerHandler.createSurvey(c);
        
        //After Insert trigger for Employee Processing
        if(Trigger.isAfter && Trigger.isInsert) {
            if(c.Active__c && c.RecordTypeId == employee && c.AccountId == lev && c.Department == Label.Employee_Department && c.Division_New__c != Label.Division_Op_Management) {
                employees.add(c);
            }

            //After Employees are inserted, create related Skills Matrix records
            if(employees.size() > 0) {
                SkillsMatrixService.insertEmployeeSkills(employees);
            }
        }
        
        //After Update trigger for Employee Processing
        if(Trigger.isAfter && Trigger.isUpdate) {
            if(!c.Active__c && c.RecordTypeId == employee && c.AccountId == lev) {
                employees.add(c);
            }

            if(c.Active__c && c.ReportsToId != Trigger.oldMap.get(c.Id).ReportsToId){
                managerChangedContactsList.add(c);
            }
            
            //After Employees are updated, delete related Skills Matrix records
            if(employees.size() > 0) {
                SkillsMatrixService.deleteEmployeeSkills(employees);
            }
            
            if(managerChangedContactsList.size() > 0){
                updateRelatedOoOCases(managerChangedContactsList);
            }
        }*/
	}

    /*public static void updateRelatedOoOCases(List<Contact> contactList){
        
        Map<Id, Id> contactToManagerId = new Map<Id, Id>();
        for(Contact c : contactList){
            contactToManagerId.put(c.Id, c.ReportsToId);
        }

        List<Case> relatedOoOCaseList = new List<Case>();
        relatedOoOCaseList = [SELECT Id, ContactId, Manager_of_Resource__c, Out_of_Office_Coverage_Resource__c, Out_of_Office_Coverage_Resource_Manager__c, Status
                            FROM Case
                            WHERE RecordTypeId =: OoOCoverageRequestCaseRT AND (ContactId IN :contactToManagerId.keySet() OR Out_of_Office_Coverage_Resource__c IN :contactToManagerId.keySet()) AND Status != 'Completed' AND Status != 'Cancelled'];

        List<Case> updateCaseList = new List<Case>();
        for(Case c : relatedOoOCaseList){
            Boolean needsUpdate = false;
            if(contactToManagerId.containsKey(c.ContactId)){
                c.Manager_of_Resource__c = contactToManagerId.get(c.ContactId);
                needsUpdate = true;
            }
            if(contactToManagerId.containsKey(c.Out_of_Office_Coverage_Resource__c)){
                c.Out_of_Office_Coverage_Resource_Manager__c = contactToManagerId.get(c.Out_of_Office_Coverage_Resource__c);
                needsUpdate = true;
            }
            
            if(needsUpdate == true){
                updateCaseList.add(c);
            }
        }

        if(updateCaseList.size() > 0){
            update updateCaseList;
        }
    }*/
}