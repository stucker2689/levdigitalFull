trigger CaseCommentAfterInsert on CaseComment (after insert) {
/*
** Created by: Levementum
** Created Date: 11/26/2012
** This trigger sets the Status of a case to In Process where it was previously Waiting on customer if the case comment is made by a customer portal user
*/	

	User u = [Select Id, IsPortalEnabled from User where Id = :UserInfo.getUserId()];
	
	if(u.IsPortalEnabled)
	{
		//status null upon insert using relationship field of cc.Parent.Status, so need to do another loop
		Set<Id> parentIds = new Set<Id>();
		for(CaseComment ccPreLoop: Trigger.New)
		{
			parentIds.add(ccPreLoop.ParentId);
		}
	
		Map<Id, Case> mapCase = new Map<Id, Case>([Select Id, Status from Case where Id in :parentIds]);
		
		Set<Id> cases = new Set<Id>();
		for(CaseComment cc:Trigger.new)
		{
			if(mapCase.get(cc.ParentId) != null && mapCase.get(cc.ParentId).Status == 'Waiting on Customer')
			{
				//this case needs to be updated!
				cases.add(cc.ParentId);		
			}
		}
		
		//update the cases
		Case[] caseUpdate = new Case[0];
		for(Case c:[Select Id, Status from Case where Id in :cases])
		{
			c.Status = 'In Process';
			caseUpdate.add(c);
		}
		
		update caseUpdate;	
	}
}