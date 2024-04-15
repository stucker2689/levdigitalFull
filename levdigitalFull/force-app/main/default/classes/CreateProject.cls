/*
Created By: Naren Pillai
Date: 6/8/2015
Description: This class is used to create a new project, and the methods are called from the Opportunity Trigger 'OpportunityAfter.trigger'
Assumptions: Using Upsert action, with 'Name' as the keyword for search and update. Thus the key assumption is that Opportunity Name is a unique identifier.
Also, we can have a workaround in place to keep the Opportunity name unique in the system.
*/

public without sharing class CreateProject {

	public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};
	public static List<String> opportunityCloseLostStageNames = new List<String>{'Client Withdraw', 'Cognizant Withdraw', 'Duplicate', 'Lost', 'Closed Lost'};
	
	public static List<String> opportunityRTList = new List<String>{'Salesforce', 'SugarCRM', 'PSS', 'Service_Contract'};

	/* Method to create new project*/
	public static void CreateProject(List<Opportunity> triggerNew){
		List<Project__c> updateProjectList = new List<Project__c>();
		List<Project__c> insertProjectList = new List<Project__c>();

		List<Project__C> existingProj = new List<Project__c>();
		List<Project__c> projectList = new List<Project__c>();
		Set<String> opptyIds = new Set<String>();

		for (Opportunity opp : triggerNew){
			opptyIds.add(opp.Id);
		}

		if(opptyIds.size() > 0){
			existingProj = [SELECT Id,Name, Account__c, Opportunity__c, Opportunity__r.Opportunity_RecordType_Name__c, Opportunity__r.StageName, Project_Status__c 
							FROM Project__c 
							WHERE Opportunity__c in: opptyIds];
		}
		
		Map<String,Id> projectTypes = LevUtility.GetRecordTypeIdsByDeveloperName(Project__c.SobjectType);

		for(Opportunity opp : triggerNew){

			Boolean addProjectToUpsertList = false;

			System.debug('OppRecType: '+opp.Opportunity_RecordType_Name__c);
			System.debug('OppStage: ' + opp.StageName);
			System.debug('opp.Create_Project__c: ' + opp.Create_Project__c);
			System.debug('opp.Do_Not_Create_Project__c: ' + opp.Do_Not_Create_Project__c);

			if(opp.Do_Not_Create_Project__c != TRUE){

				if(existingProj.size() == 0){
					Project__c project = new Project__c();

					//If the stage is in 'Verbal Approval' or 'Finalize Contract', Create Project flag need to be set to TRUE to create project
					if((opportunityRTList.contains(opp.Opportunity_RecordType_Name__c)) && ((opportunityClosedWonStageNames.contains(opp.StageName) || opp.Create_Project__c))){

						project.Name = opp.Name;
						project.Account__c = opp.AccountId;
						project.Opportunity__c = opp.Id;
						project.Project_Status__c = 'Not Started';
						project.Project_Phase__c = 'Initiate';

						if(opp.Opportunity_RecordType_Name__c == 'Salesforce'){
							project.RecordTypeId = projectTypes.get('Salesforce_Project');

						}
						/*else if(opp.Opportunity_RecordType_Name__c =='SugarCRM'){
							project.RecordTypeId = projectTypes.get('SugarCRM_Project');

						}
						else if (opp.Opportunity_RecordType_Name__c =='Service_Contract'){
							project.RecordTypeId = projectTypes.get('ASC_Project');

						}
						else if (opp.Opportunity_RecordType_Name__c =='PSS'){
							project.RecordTypeId = projectTypes.get('PSS');

						}*/
						//projectList.add(project);
						addProjectToUpsertList = true;
					}

					//If Opp stage is set to Closed Won, we dont need to check for the Create Project flag.
					if((opportunityRTList.contains(opp.Opportunity_RecordType_Name__c))	&& ((opportunityClosedWonStageNames.contains(opp.StageName)))){
						project.Name = opp.Name;

						project.Account__c = opp.AccountId;
						project.Opportunity__c = opp.Id;
						if(project.Project_Background_Objectives__c==NULL){
							project.Project_Background_Objectives__c = opp.Project_Background_Objectives__c;
						}
						if(project.Key_Project_Success_Metrics__c ==NULL){
							project.Key_Project_Success_Metrics__c = opp.Key_Project_Success_Metrics__c;
						}
						if(project.Promised_Start_Date__c ==NULL) {
							project.Promised_Start_Date__c = opp.Promised_Start_Date__c;
						}
						if(project.Opp_Date_SOW_Signed__c==NULL) {
							project.Opp_Date_SOW_Signed__c = opp.Date_SOW_Signed__c;
						}
						if(project.Project_Status__c == NULL){ 
							project.Project_Status__c = 'Not Started';
						}
						if(project.Project_Phase__c ==NULL){
							project.Project_Phase__c = 'Initiate';
						}
						if(opp.Opportunity_RecordType_Name__c == 'Salesforce'){
							project.RecordTypeId = projectTypes.get('Salesforce_Project');
						}
						/*else if(opp.Opportunity_RecordType_Name__c =='SugarCRM'){
							project.RecordTypeId = projectTypes.get('SugarCRM_Project');
						}
						else if (opp.Opportunity_RecordType_Name__c =='Service_Contract'){
							project.RecordTypeId = projectTypes.get('ASC_Project');
						}
						else if (opp.Opportunity_RecordType_Name__c =='PSS'){
							project.RecordTypeId = projectTypes.get('PSS');
						}*/
						System.debug('project.RecordTypeId ' + project.RecordTypeId);
						//projectList.add(project);
						addProjectToUpsertList = true;

					}
					if(addProjectToUpsertList){
						projectList.add(project);
					}
				}
			}

			
		}

		//If the opp is CLosed/Lost, and if any project had already been created, set the status to 'Canceled - Opportunity Lost'
		if(existingProj.size() > 0){
			for(Project__c proj : existingProj){
				String relatedOpptyRTName;
				relatedOpptyRTName = proj.Opportunity__r.Opportunity_RecordType_Name__c;

				if((relatedOpptyRTName == 'Salesforce'|| relatedOpptyRTName == 'SugarCRM' || relatedOpptyRTName == 'Service_Contract' ) && ((opportunityCloseLostStageNames.contains(proj.Opportunity__r.StageName)))){
					if(proj.Project_Status__c != 'Terminated - Opportunity Lost'){
						proj.Project_Status__c = 'Terminated - Opportunity Lost';
						updateProjectList.add(proj);
					}
				}
			}
		}

		try{
			System.debug('CreateProject Project List: ' + projectList);
			for(Project__c project : projectList){
				System.debug('Project Name: ' + project.Name);
				System.debug('Project Id: ' + project.Id);
			}
			if(existingProj.size() == 0 && projectList.size() > 0){
				Upsert projectList Name;
			}
			
			if (existingProj.size() != 0 && updateProjectList.size() > 0){
				//Upsert existingProj Name;
				update updateProjectList;
			}
		}catch(Exception e){
            System.debug('CreateProject ERROR: ' + e.getmessage());
        }


	}

	

}