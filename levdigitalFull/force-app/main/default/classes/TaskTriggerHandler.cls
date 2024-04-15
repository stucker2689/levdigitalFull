/*
Created By: Naren Pillai
Date: 8/26/2015
Description: This class is used to handle the processes after a task is created/updated		
*/
public with sharing class TaskTriggerHandler 
{
	
	/*
	Created By: Naren Pillai
	Date: 8/26/2015
	Description: This method updates the 'Next Touch' date in Lead, when a new Task is created. 
	Need logic to update the Next Touch date during task update,task delete as well.	
	When a new lead is created, we still need to check most latest due date across the lead, 

	*/
	public static void UodateNextTouchDate(Set<Id>LeadIds)

	 {

	 	List<Lead> leadlist = [Select Id,Name,Next_Touch__c from Lead where ID =: LeadIds]; 
	 	List<Task> openTasks = [Select Id, WhoId, ActivityDate,Description from Task where WhoID =: LeadIds AND isClosed =False ];
	 	for(Lead lead: leadlist)
	 	{
	 		Date latestDueDate;
	 		for (Task tsk : openTasks)
	 		{

	 			if(tsk.WhoId == lead.Id)
	 			{
	 				if(latestDueDate== NULL || tsk.ActivityDate< latestDueDate)
	 				{
	 					latestDueDate=tsk.ActivityDate;
	 				}

	 			}

	 		}
	 		lead.Next_Touch__c = latestDueDate;

	 	}
	 	update leadlist;
		

	 }
}