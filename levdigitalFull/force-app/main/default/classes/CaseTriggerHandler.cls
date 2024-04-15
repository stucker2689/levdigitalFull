/**
 * Name: CaseTriggerHandler
 * Author: Jonathan Broquist
 * Date:
 * Description: Handles the trigger logic for the Cases object.
 */
public class CaseTriggerHandler extends SObjects{
	//VARIABLES
  	//=========================================================================
  	private Set<Id> projectIds = new Set<Id>();
  	private static String LevSOWCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lev SOW').getRecordTypeId();
  	private static String LevCOSOWCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('LEV CO SOW').getRecordTypeId();
  	private static String LevSwapResourceRequestRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lev Swap Resource Request').getRecordTypeId();
	private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();
	private static String trainingAndEnablementRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Training & Enablement').getRecordTypeId();
	private static String nonbillOrConcessionRequestRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Nonbill Request').getRecordTypeId();

	//CONSTRUCTOR
	//=========================================================================
	public CaseTriggerHandler() {
		
	}

	//PUBLIC METHODS
	//=========================================================================
	public override void beforeInsert(SObject[] records){
		List<Case> newCases = new List<Case>();
		Map<Id, Case> casesToSetSprintWeeksMap = new Map<Id, Case>();
		Map<Id, Case> casesToSetSprintMonthsAndQuartersMap = new Map<Id, Case>();
		List<Case> caseToSetCaseOwnerList = new List<Case>();
		for(SObject obj : records) {
			Case c = (Case)obj;
			newCases.add(c);

			if(c.RecordTypeId == internalCaseRT || c.RecordTypeId == trainingAndEnablementRT){
				if(c.Sprint_Week__c == null){
					casesToSetSprintWeeksMap.put(c.Id, c);
				}else{
					casesToSetSprintMonthsAndQuartersMap.put(c.Id, c);
				}
				caseToSetCaseOwnerList.add(c);
			}

			if(c.RecordTypeId == internalCaseRT && c.QA_Owner__c == null && c.QA_Status__c != 'N/A' && c.Type == 'Internal SF Support'){
				c.QA_Owner__c = '0030W00003erGQ1QAM'; //Set QA Owner to Alysia on Insert
			}	
		}

		if(newCases.size() > 0){
			CaseTriggerHelper.assignDealDeskLookupField(newCases, 'beforeInsert');
		}

		if(casesToSetSprintWeeksMap.size() > 0){
			CaseTriggerHelper.setCaseSprintWeeks(casesToSetSprintWeeksMap);
		}

		if(casesToSetSprintMonthsAndQuartersMap.size() > 0){
			CaseTriggerHelper.setCaseSprintMonthsAndQuarters(casesToSetSprintMonthsAndQuartersMap);
		}

		if(caseToSetCaseOwnerList.size() > 0){
			CaseTriggerHelper.updateCaseOwnerForKanban(caseToSetCaseOwnerList, null, false);
		}
	}

	public override void afterInsert(SObject[] records){
		Set<Id> sowOpptyIdSet = new Set<Id>();
		Map<Id, Case> newCasesMap = new Map<Id, Case>();
		Map<Id, Case> casesToCreateSprintPlansMap = new Map<Id, Case>();
		List<Case> levSwapResourceCaseList = new List<Case>();
		Set<Id> rollupNonbillOrConcessionRequestProjectIdSet = new Set<Id>();

		for(SObject obj : records) {
			Case c = (Case)obj;
			newCasesMap.put(c.Id, c);

			if(c.Project__c != null){
				projectIds.add(c.Project__c);
			}

			if(c.RecordTypeId == LevSOWCaseRT || c.RecordTypeId == LevCOSOWCaseRT){
				if(c.Case_Opportunity__c != null){
					sowOpptyIdSet.add(c.Case_Opportunity__c);
				}
			}

			if(c.RecordTypeId == LevSwapResourceRequestRT){
				levSwapResourceCaseList.add(c);
			}

			if(c.RecordTypeId == internalCaseRT || c.RecordTypeId == trainingAndEnablementRT){
				if(c.Sprint_Week__c != null){
					casesToCreateSprintPlansMap.put(c.Id, c);
				}
			}

			if(c.RecordTypeId == nonbillOrConcessionRequestRT && c.Project__c != null){
				rollupNonbillOrConcessionRequestProjectIdSet.add(c.Project__c);
			}
		}

		if(newCasesMap.size() > 0){
			//CaseTriggerHelper.updateCaseSprintWeek(newCasesMap, null, true);
		}

		if(sowOpptyIdSet.size() > 0){
			CaseTriggerHelper.countRelatedSOWCasesOnOppty(sowOpptyIdSet);
		}

		if(levSwapResourceCaseList.size() > 0){
			CaseTriggerHelper.updateStaffTransitionsAmountOnAccount(levSwapResourceCaseList);
		}

		if(casesToCreateSprintPlansMap.size() > 0){
			CaseTriggerHelper.createCaseSprintPlans(casesToCreateSprintPlansMap);
		}

		if(rollupNonbillOrConcessionRequestProjectIdSet.size() > 0){
			CaseTriggerHelper.rollupNonBillOrConcessionRequestsOnProjects(rollupNonbillOrConcessionRequestProjectIdSet);
		}

		updateProjectSummary();
	}

  	public override void beforeUpdate(SObject[] records, SObject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap){
		List<Case> newCases = new List<Case>();
		Map<Id, Case> oldCaseMap = new Map<Id, Case>();
		Map<Id, Case> casesToSetSprintWeeksMap = new Map<Id, Case>();
		Map<Id, Case> casesToSetSprintMonthsAndQuartersMap = new Map<Id, Case>();
		List<Case> caseToSetCaseOwnerList = new List<Case>();
		for(SObject obj : records) {
			Case c = (Case)obj;
			Case c_old = (Case)oldRecordMap.get(c.Id);
			oldCaseMap.put(c.Id, c_old);
			newCases.add(c);

			if((c.RecordTypeId == internalCaseRT || c.RecordTypeId == trainingAndEnablementRT)){
				
				if((c.Start_Date__c != c_old.Start_Date__c || c.Due_Date_Internal__c != c_old.Due_Date_Internal__c)){
					/*Set Sprint Weeks on Case IF ALL these are true:
					* 1.) Is Internal Or Training & Enablement Record Type
					* 2.) Start Date or Due Date has changed
					* 3.) Sprint Week field was not manually changed (this is because we want to be able to have it not reset if the Sprint Week is manually set)
					*/
					if((c.Sprint_Week__c == c_old.Sprint_Week__c)){
						casesToSetSprintWeeksMap.put(c.Id, c);
					}else{
						//If 1 & 2 above are true, then set the Sprint Months & Sprint Quarters from the manually set Sprint Weeks
						casesToSetSprintMonthsAndQuartersMap.put(c.Id, c);

					}
				}else{
					if((c.Sprint_Week__c != c_old.Sprint_Week__c)){
						casesToSetSprintMonthsAndQuartersMap.put(c.Id, c);
					}
				}

				//If the Owner Changes then update the Case Owner for the Kanban
				if(c.OwnerId != c_old.OwnerId || c.Case_Owner__c != c_old.Case_Owner__c){
					caseToSetCaseOwnerList.add(c);
				}

				if(c.Rollout_Needed__c != c_old.Rollout_Needed__c && c.Rollout_Needed__c != 'Yes'){
					c.ChangeManagementDueDate__c = null;
					c.CaseCompletionDueDate__c = null;
				}

				if(c.QA_Status__c != c_old.QA_Status__c && c.QA_Status__c == 'N/A' && c.QA_Owner__c != null){
					c.QA_Owner__c = null;
				}

				if(c.RecordTypeId == internalCaseRT && c.QA_Owner__c == null && c.QA_Status__c != 'N/A' && c.Type == 'Internal SF Support' && c.Type  != c_old.Type){
					c.QA_Owner__c = '0030W00003erGQ1QAM'; //Set QA Owner to Alysia on Insert
				}

				if(c.RecordTypeId == internalCaseRT && c.QA_Owner__c != null &&  c_old.Type == 'Internal SF Support' && c.Type  != c_old.Type){
					c.QA_Owner__c = null; //Clear QA Owner when Type is changed from Internal SF Support
				}

				//Clear Requirements Completed Date field
				if(c.RecordTypeId == internalCaseRT && c.Requirements_Status__c != 'Complete' && c.Requirements_Status__c != 'N/A' && c.Date_Requirements_Completed__c != null){
					c.Date_Requirements_Completed__c = null;
				}

				//Clear Requirements Gathering Started Date field
				if(c.RecordTypeId == internalCaseRT && (c.Requirements_Status__c == 'Need' || c.Requirements_Status__c == null ) && c.Date_Requirements_Gathering_Started__c != null){
					c.Date_Requirements_Gathering_Started__c = null;
				}
			}
		}

		if(newCases.size() > 0){
			CaseTriggerHelper.assignDealDeskLookupField(newCases, 'beforeUpdate');
		}

		if(casesToSetSprintWeeksMap.size() > 0){
			CaseTriggerHelper.setCaseSprintWeeks(casesToSetSprintWeeksMap);
		}

		if(casesToSetSprintMonthsAndQuartersMap.size() > 0){
			CaseTriggerHelper.setCaseSprintMonthsAndQuarters(casesToSetSprintMonthsAndQuartersMap);
		}

		if(caseToSetCaseOwnerList.size() > 0){
			CaseTriggerHelper.updateCaseOwnerForKanban(caseToSetCaseOwnerList, oldCaseMap, true);
		}
	}

	public override void afterUpdate(SObject[] records, SOBject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap){
		Map<Id, Case> newCasesMap = new Map<Id, Case>();
		Map<Id, Case> oldCasesMap = new Map<Id, Case>();
		Set<Id> sowOpptyIdSet = new Set<Id>();
		List<Case> levSwapResourceCaseList = new List<Case>();
		Map<Id, Case> casesToCreateSprintPlansMap = new Map<Id, Case>();
		Set<Id> rollupNonbillOrConcessionRequestProjectIdSet = new Set<Id>();

		for(SObject obj : records) {
			Case c = (Case)obj;
			newCasesMap.put(c.Id, c);
			Case c_old = (Case)oldRecordMap.get(c.Id);

			if((c.RecordTypeId == LevSOWCaseRT || c.RecordTypeId == LevCOSOWCaseRT) && ((c_old.RecordTypeId != LevSOWCaseRT && c_old.RecordTypeId != LevCOSOWCaseRT) || (c.Case_Opportunity__c != c_old.Case_Opportunity__c))){
				if(c.Case_Opportunity__c != null){
					sowOpptyIdSet.add(c.Case_Opportunity__c);
				}
				if(c.Case_Opportunity__c != c_old.Case_Opportunity__c && c_old.Case_Opportunity__c != null){
					sowOpptyIdSet.add(c_old.Case_Opportunity__c);
				}
			}

			if(c.Project__c != null){
				projectIds.add(c.Project__c);
			}

			//Recalculate Account Transition Amount Count for Lev Resource Swap cases
			if( ((c.RecordTypeId != c_old.RecordTypeId) && (c.RecordTypeId == LevSwapResourceRequestRT || c_old.RecordTypeId == LevSwapResourceRequestRT)) || (c.Project__c != c_old.Project__c) || ((c.Status != c_old.Status) && (c.Status == 'Completed' || c_old.Status == 'Completed'))){

				levSwapResourceCaseList.add(c);
				levSwapResourceCaseList.add(c_old);
			}

			if(c.RecordTypeId == internalCaseRT || c.RecordTypeId == trainingAndEnablementRT){
				if(c.Sprint_Week__c != c_old.Sprint_Week__c || c.Sprint_Month__c != c_old.Sprint_Month__c || c.Sprint_Quarter__c != c_old.Sprint_Quarter__c || c.Internal_Ops_Estimated_Hours__c != c_old.Internal_Ops_Estimated_Hours__c || c.Estimated_QA_Hours__c != c_old.Estimated_QA_Hours__c){
					casesToCreateSprintPlansMap.put(c.Id, c);
				}
			}

			if((c.RecordTypeId != c_old.RecordTypeId && (c.RecordTypeId == nonbillOrConcessionRequestRT || c_old.RecordTypeId == nonbillOrConcessionRequestRT))
				|| c.RecordTypeId == nonbillOrConcessionRequestRT && c.Project__c != c_old.Project__c){
				rollupNonbillOrConcessionRequestProjectIdSet.add(c.Project__c);
				if(c.Project__c != c_old.Project__c && c_old.Project__c != null && c_old.RecordTypeId == nonbillOrConcessionRequestRT ){
					rollupNonbillOrConcessionRequestProjectIdSet.add(c_old.Project__c);
				}
			}
		}

		for(sObject oldObj : oldRecordMap.values()){
			Case c = (Case)oldObj;
			oldCasesMap.put(c.Id, c);
		}

		if(sowOpptyIdSet.size() > 0){
			CaseTriggerHelper.countRelatedSOWCasesOnOppty(sowOpptyIdSet);
		}

		if(levSwapResourceCaseList.size() > 0){
			CaseTriggerHelper.updateStaffTransitionsAmountOnAccount(levSwapResourceCaseList);
		}

		if(casesToCreateSprintPlansMap.size() > 0){
			CaseTriggerHelper.createCaseSprintPlans(casesToCreateSprintPlansMap);
		}

		if(rollupNonbillOrConcessionRequestProjectIdSet.size() > 0){
			CaseTriggerHelper.rollupNonBillOrConcessionRequestsOnProjects(rollupNonbillOrConcessionRequestProjectIdSet);
		}

		//CaseTriggerHelper.updateCaseSprintWeek(newCasesMap, oldCasesMap, false);
		//CaseTriggerHelper.updateCaseSprintMonthAndQuarter(newCasesMap, oldCasesMap);

		updateProjectSummary();
	}

	public override void beforeDelete(SObject[] records, Map<Id, SObject> recordMap){}

	public override void afterDelete(SObject[] records, Map<Id, SObject> recordMap){
		Set<Id> sowOpptyIdSet = new Set<Id>();
		List<Case> levSwapResourceCaseList = new List<Case>();
		Set<Id> rollupNonbillOrConcessionRequestProjectIdSet = new Set<Id>();

		for(SObject obj : records) {
			Case c = (Case)obj;
			if(c.Project__c != null){
				projectIds.add(c.Project__c);
			} 

			if(c.RecordTypeId == LevSOWCaseRT || c.RecordTypeId == LevCOSOWCaseRT){
				if(c.Case_Opportunity__c != null){
					sowOpptyIdSet.add(c.Case_Opportunity__c);
				}
			}

			if(c.RecordTypeId == LevSwapResourceRequestRT){
				levSwapResourceCaseList.add(c);
			}

			if(c.RecordTypeId == nonbillOrConcessionRequestRT && c.Project__c != null){
				rollupNonbillOrConcessionRequestProjectIdSet.add(c.Project__c);
			}
		}

		if(sowOpptyIdSet.size() > 0){
			CaseTriggerHelper.countRelatedSOWCasesOnOppty(sowOpptyIdSet);
		}

		if(levSwapResourceCaseList.size() > 0){
			CaseTriggerHelper.updateStaffTransitionsAmountOnAccount(levSwapResourceCaseList);
		}

		if(rollupNonbillOrConcessionRequestProjectIdSet.size() > 0){
			CaseTriggerHelper.rollupNonBillOrConcessionRequestsOnProjects(rollupNonbillOrConcessionRequestProjectIdSet);
		}

		updateProjectSummary();
	}

	public override void afterUndelete(SObject[] records){}

	//PRIVATE METHODS
	//=========================================================================
	/**
	 * Recalculates the project summary.
	 */
	private void updateProjectSummary() {
		// verify there are projects to update
		if(projectIds.size() > 0) {
		// create map of projects to update
		Map<Id, Project__c> projectMap = new Map<Id, Project__c>([SELECT Id, TotalNumberofCases__c, TotalCasesOpen__c, TotalsCasesClosed__c, Total_Actual_Hours__c, TotalEstimatedHours__c FROM Project__c WHERE Id IN :projectIds]);
		// create a project summary map
		Map<Id, CaseProjectSummary> projectSummaryMap = new Map<Id, CaseProjectSummary>();
		for(Case c : [SELECT Id, Project__c, Status, Actual_Hours_Billable__c, Estimated_Hours__c FROM Case WHERE Project__c IN :projectIds]) {
			// create summary record for case project if it doesn't already exist
			if(!projectSummaryMap.containsKey(c.Project__c)) projectSummaryMap.put(c.Project__c, new CaseProjectSummary());

			// update summary with case information
			CaseProjectSummary summary = projectSummaryMap.get(c.Project__c);
			summary.totalCases++;
			if(c.Status != 'Completed' && c.Status != 'Cancelled') summary.totalOpenCases++;
			if(c.Status == 'Completed') summary.totalClosedCases++;
			if(c.Actual_Hours_Billable__c != null) summary.totalActualHours += c.Actual_Hours_Billable__c;
			if(c.Estimated_Hours__c != null) summary.totalEstimatedHours += c.Estimated_Hours__c;
			projectSummaryMap.put(c.Project__c, summary);
		}

		// iterate through projects and update the summary fields
		for(Project__c p : projectMap.values()) {
			if(projectSummaryMap.containsKey(p.Id)) {
				CaseProjectSummary summary = projectSummaryMap.get(p.Id);
				p.TotalNumberofCases__c = summary.totalCases;
				p.TotalCasesOpen__c = summary.totalOpenCases;
				p.TotalsCasesClosed__c = summary.totalClosedCases;
				p.Total_Actual_Hours__c = summary.totalActualHours;
				p.TotalEstimatedHours__c = summary.totalEstimatedHours;
			}
		}

			update projectMap.values();
		}
	}

	private class CaseProjectSummary {
		public Decimal totalCases;
		public Decimal totalOpenCases;
		public Decimal totalClosedCases;
		public Decimal totalActualHours;
		public Decimal totalEstimatedHours;

		public CaseProjectSummary() {
		totalCases = 0;
		totalOpenCases = 0;
		totalClosedCases = 0;
		totalActualHours = 0;
		totalEstimatedHours = 0;
		}
	}
}