trigger OpportunityAfter on Opportunity (after delete, after insert, after update, after undelete) {

	private static Id changeOrderOpptyRT = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
	public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};

/*
** Created by: Levementum
** Created Date: 10/30/2012
** This trigger calls a recalculation of closed/won opps on opp delete/insert/update(change of amount, closedate, stage)
** The class AccountCalculations.FirstYearBooking is called to do the calculation and update of the account
*/
	Set<Id> accountIds = new Set<Id>();
	Set<Id> relOppReCalc = new Set<Id>();
	Set<Id> repliconOppId = new Set<Id>();
	//recalc the accounts closed/won opps whenever an opp is deleted
	/*if(Trigger.isDelete) 
	{
		for(Opportunity oDel:Trigger.old)
		{
			accountIds.add(oDel.AccountId);
			System.debug('OPP: ' + oDel.Change_Orders__c);
			if(oDel.Change_Orders__c != null)
			{
				relOppReCalc.add(oDel.Change_Orders__c);
			}
		}
	}*/

	//recalc the accounts closed/won opps whenever an opp is inserted, or if an existing opp has a change of stage, amount or closedate
	if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete)
	{
		List<Opportunity> createProjects = new List<Opportunity>();
		for(Opportunity oNew : Trigger.new) {

	//			if((Trigger.IsInsert && oNew.ForecastCategory == 'Closed')|| (Trigger.IsUpdate &&
	//			//(oNew.StageName != Trigger.oldMap.get(oNew.Id).StageName
	//			(oNew.ForecastCategory != Trigger.oldMap.get(oNew.Id).ForecastCategory && oNew.ForecastCategory == 'Closed'
	//			|| oNew.Amount != Trigger.oldMap.get(oNew.Id).Amount
	//			|| oNew.CloseDate != Trigger.oldMap.get(oNew.Id).CloseDate)))
	//			{
	//				//accountIds.add(oNew.AccountId);
	//			}

			//If it is moved to or from Closed Won OR It is Closed won and Amount Changes or Close Date Changes
			if(Trigger.isInsert){
				/*if(oNew.IsWon){
					accountIds.add(oNew.AccountId);
				}*/
				
			}else if(Trigger.isUpdate){
				/*Opportunity oldOppty = Trigger.oldMap.get(oNew.Id);
				if((oNew.IsWon != oldOppty.IsWon) || (oNew.IsWon && (oNew.Amount != oldOppty.Amount || oNew.CloseDate != oldOppty.CloseDate))){
					accountIds.add(oNew.AccountId);
				}

				//New 10/20/2022 ST Recalcs Oppty if CO is changed from CO
				if(oNew.RecordTypeId != oldOppty.RecordTypeId && oldOppty.RecordTypeId == changeOrderOpptyRT && oldOppty.Change_Orders__c != null){
					relOppReCalc.add(oldOppty.Change_Orders__c);
				}*/
				
			}else if(Trigger.isUndelete){
				/*if(oNew.IsWon){
					accountIds.add(oNew.AccountId);
				}*/
			}

			if(!Trigger.isUndelete && 
				((Trigger.IsInsert || 
				oNew.Amount != Trigger.oldMap.get(oNew.Id).Amount || oNew.StageName != Trigger.oldMap.get(oNew.Id).StageName || oNew.AllOtherNonLevResourceAmount__c != Trigger.oldMap.get(oNew.Id).AllOtherNonLevResourceAmount__c)
				&& oNew.Change_Orders__c != null && oNew.RecordTypeId == changeOrderOpptyRT) 
				|| ((Trigger.isUpdate || Trigger.isUndelete) && oNew.Change_Orders__c != null &&  oNew.RecordTypeId == changeOrderOpptyRT))
			{
				//relOppReCalc.add(oNew.Change_Orders__c);

			}







			//Create Task on insert
			//No longer creating Replicon Tasks 3.18.22
			if(Trigger.isInsert   && oNew.Change_Orders__c != null &&  oNew.RecordTypeId == changeOrderOpptyRT && opportunityClosedWonStageNames.contains(oNew.StageName)){

				/*if(!repliconOppId.contains(oNew.Id)){
					repliconOppId.add(oNew.Id);
				}*/
			}
			if(Trigger.isUpdate   && oNew.Change_Orders__c != null &&  oNew.RecordTypeId == changeOrderOpptyRT){

				/*if(oNew.StageName=='Closed Won' || oNew.Create_Project__c==true) {
					
					if(!repliconOppId.contains(oNew.Id)){
						repliconOppId.add(oNew.Id);
					}
				}*/
			}
			
			if(Trigger.isUpdate && oNew.Change_Orders__c!= Trigger.oldMap.get(oNew.Id).Change_Orders__c && oNew.RecordTypeId == changeOrderOpptyRT){
				//relOppReCalc.add(Trigger.oldMap.get(oNew.Id).Change_Orders__c);
			}

			if(oNew.Create_Project__c && !oNew.Do_Not_Create_Project__c && (oNew.StageName == 'Verbal Approval (Negotiation)' || oNew.StageName == 'Finalize Contracts' || opportunityClosedWonStageNames.contains(oNew.StageName))) {
				//createProjects.add(oNew);                        
			}
		}
		
		//If Opportunity has Do Not Create Project checked, the create project class will be overlooked.
		/*if(createProjects.size() > 0){
			if(CheckRecursive.runCreateProjectsOnce()){
				CreateProject.CreateProject(createProjects);
			}
		}*/

		if(Trigger.IsUpdate){
			//ProjectHandler.updateReplionDatainProject(Trigger.oldMap, Trigger.newMap);
		}
	}
	//if(!Test.isRunningTest()){
		//if(CheckRecursive.runCalculateAccountOnce()){
			if(accountIds.size() > 0){
				AccountCalculations.FirstYearBooking(accountIds);
			}
		//}
		/*if(CheckFirst.calculateOpp == true) {
			if(relOppReCalc.size() > 0){
				OpportunityCalculations.relOppReCalc(relOppReCalc);
			}
		}*/
		//if(CheckFirst.IfTaskRun==true) {
			//if(repliconOppId.size() > 0){
				//OpportunityCalculations.createRepliconTask(repliconOppId);
			//}
		//}
	//}
	/*if(Test.isRunningTest()){
		//OpportunityCalculations.relOppReCalc(relOppReCalc);
		OpportunityCalculations.createRepliconTask(repliconOppId);
	}*/

}