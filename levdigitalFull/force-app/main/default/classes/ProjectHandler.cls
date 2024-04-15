/*
Created By: Naren Pillai
Date: 6/20/2015
Description: This class is used to update replicon data in Opportunity to Project/ Account. 

Edit By: Sam Tucker
Date: 3/18/2022
Cleaned up nested For Loops
*/

public with sharing class ProjectHandler {
	
	//This method will update RepliconData in project from Opportunity
	//This method can be updated once the replicon/talend jobs are modified to update these fields directly at project object, instead of updating in opp. 
	public static void updateReplionDatainProject(Map<id,Opportunity> oldMap, Map<id,Opportunity> newMap){

		Map<Id, Opportunity> opptyIdToOpptyMap = new Map<Id, Opportunity>();
		//Getting the Opp Ids for those whose Total Hours have been updated. 
		for(Opportunity oppNew : newMap.values()){
			Opportunity oldOppValue = oldMap.get(oppNew.Id);

			if(oppNew.Total_Hours_Invoiced_to_Date__c!= NULL && ((oppNew.Total_Hours_Invoiced_to_Date__c != oldOppValue.Total_Hours_Invoiced_to_Date__c)||oppNew.Total_Amount_Invoiced_to_Date__c!=oldOppValue.Total_Amount_Invoiced_to_Date__c)){
				opptyIdToOpptyMap.put(oppNew.Id, oppNew);
			}	
		}

		List<Project__c> projList = new List<Project__c>();
	 	if(opptyIdToOpptyMap.size() > 0){
			
			projList = [SELECT Id, Total_Hours_Invoiced_to_Date__c, Total_Amount_Invoiced_to_Date__c, Opportunity__c FROM Project__c WHERE Opportunity__c IN :opptyIdToOpptyMap.keySet()];
			for(Project__c prj : projList){

				if(opptyIdToOpptyMap.containsKey(prj.Opportunity__c)){
					prj.Total_Hours_Invoiced_to_Date__c = opptyIdToOpptyMap.get(prj.Opportunity__c).Total_Hours_Invoiced_to_Date__c;
					prj.Total_Amount_Invoiced_to_Date__c = opptyIdToOpptyMap.get(prj.Opportunity__c).Total_Amount_Invoiced_to_Date__c;
				}
			}
		}

		try{

			if(projList.size() > 0){
				update projList; 
			}

		}catch(Exception e){
			System.debug('ProjectHandler Error: ' + e);
		}
	}
	//New method to update the Remaining hOurs/ Remaining amount to the account level. 
	// Need to get only those projects that are active, and having a positive Remaining hours/ Remaining amount (On account, we don't need to see the negative)
	//If any/all projects went negative, update value as 0
	/*public static void updateProjectDetailsInAccount(Map<id,Project__c>oldMap, Map<id,Project__c>newMap)
	{
		List<Account> acclist = new List<Account>();
		List<Project__c> projList = new List<Project__c>();
		Set<String> prjAccIds = new Set<String>();
		List<Project__c> negativeBalanceHrs = new List<Project__c>();
		List<Project__c> negativeBalanceAmnt = new List<Project__c>();
		//List<Project__c> projlistFromTrigger = new List<Project__c>();

		for(Project__c newproj: newMap.values())
		{
			Project__c oldProj = oldMap.get(newproj.ID);
			if(newproj.Total_Hours_Invoiced_to_Date__c != oldProj.Total_Hours_Invoiced_to_Date__c ||
			   newproj.Total_Amount_Invoiced_to_Date__c!=oldProj.Total_Amount_Invoiced_to_Date__c ||
			   newProj.SR_Overall_Health_Value__c != oldProj.SR_Overall_Health_Value__c ||
			   newProj.Percent_Of_Budget_Remaining__c != oldProj.Percent_Of_Budget_Remaining__c || 
			   oldProj.Project_Status__c!= newproj.Project_Status__c
			  )
			{
				//projlistFromTrigger.add(newproj); 
				prjAccIds.add(newProj.Account__c);
			}

		}
		if(prjAccIds.size()!=0)
		{

		acclist = [Select Id,Porftolio_Available_Hours__c,Porftolio_Available_Dollars__c,Lowest_Overall_PHI_Indicator_Value__c,Lowest_Project_Budget_Remaining_Percent__c 
				   from Account where Id in: prjAccIds];
		system.debug('Acc List'+acclist);
		Set<String> accIds = new Set<String>();
		For(Account acc: acclist)
		{
			accIds.add(acc.Id);
		}

		projList=[Select Id,Account__c,Project_Status__c,Remaining_Hours__c,Remaining_Amount__c,Percent_Of_Budget_Remaining__c,SR_Overall_Health_Value__c from Project__c where  Account__c in: accIds]; 
		system.debug('Proj List' + projList);
		For(Account acc: acclist)
		{
			Decimal remainingHours = 0;
			Decimal remainingAmount=0;
			String  lowestPHI;
			Decimal lowestbudgetpercent;

			For(Project__c prj : projList)
			{ 
				if(acc.Id == prj.Account__c)
				{
					if(prj.Remaining_Hours__c>=0)
					{
						system.debug('prj.Remaining_Hours__c'+prj.Remaining_Hours__c);
						remainingHours =remainingHours+prj.Remaining_Hours__c;
						system.debug('Remaining Hours'+remainingHours);
					}
					if(prj.Remaining_Amount__c>=0)
					{
						remainingAmount=remainingAmount+prj.Remaining_Amount__c;
						system.debug('Remaining Amount'+remainingAmount);
					}

					//Logic to check if all projects have negative balances in remaminging hours/ remainging amount. 
					if(prj.Remaining_Hours__c < 0)
					{
						negativeBalanceHrs.add(prj);
					}
					if(prj.Remaining_Amount__c < 0)
					{
						negativeBalanceAmnt.add(prj);
					}
					if(prj.Project_Status__c == 'Active')
					{

					if(lowestbudgetpercent==NULL || lowestbudgetpercent >= prj.Percent_Of_Budget_Remaining__c)

					{
						lowestbudgetpercent = prj.Percent_Of_Budget_Remaining__c;
					}
					system.debug('OVERALL HEALTH'+prj.SR_Overall_Health_Value__c);
					system.debug('lowestPHI'+lowestPHI);
					if(prj.SR_Overall_Health_Value__c =='Red')

					{
						lowestPHI = 'Red';

					}
					else if (lowestPHI!= 'Red' && prj.SR_Overall_Health_Value__c =='Yellow')
					{
						lowestPHI = 'Yellow';

					}
					}

				}

			}
			if(negativeBalanceHrs.size()==projList.size())
			{
				acc.Porftolio_Available_Hours__c =0;	

			}
			if(negativeBalanceAmnt.size()==projList.size())
			{
				acc.Porftolio_Available_Dollars__c=0;
			}
			acc.Porftolio_Available_Hours__c = remainingHours;
			acc.Porftolio_Available_Dollars__c = remainingAmount; 
			system.debug('lowestPHI'+lowestPHI);
			acc.Lowest_Overall_PHI_Indicator_Value__c = lowestPHI;
			system.debug('Lowest_Overall_PHI_Indicator_Value__c'+acc.Lowest_Overall_PHI_Indicator_Value__c);
			acc.Lowest_Project_Budget_Remaining_Percent__c = lowestbudgetpercent;


		}
		try
		{		
			system.debug('ACC LIST TO UPDATE #########'+ acclist);
			update acclist;
		}
		catch(Exception e)
		{
			system.debug('Error'+ e);
		}
		}


	}*/
}