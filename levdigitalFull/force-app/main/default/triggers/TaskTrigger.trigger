trigger TaskTrigger on Task (after insert, after update) {

	Set<Id> LeadIds = new Set<Id>();
	if((trigger.isInsert||trigger.isUpdate))
	{
		for(Task task: trigger.new)
		{
			if(task.WhoId!=NULL && task.whoId.getsobjecttype() == Lead.sobjecttype && task.ActivityDate!=NULL)
			{
				LeadIds.add(task.WhoId);

			}
		}

		TaskTriggerHandler.UodateNextTouchDate(LeadIds);

	}


}