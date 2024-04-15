trigger CampaignMemberInsertUpdate on CampaignMember (after insert, after update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** This trigger sets the first campaign that a lead was ever added too.  
** Upon a lead becoming a campaign member, if the leads Initial Campaign is null, it is set to the current campaign  
*/	
	Map<Id,Id> leadMap = new Map<Id,Id>();
	for(CampaignMember cm:Trigger.new)
	{
		if(cm.LeadId != null && cm.Lead.Initial_Campaign__c == null)
		{
			leadMap.put(cm.LeadId,cm.CampaignId);
		}
	}
	
	Lead[] lUpdate = new Lead[0];
	for(Lead l:[Select Id, Initial_Campaign__c from Lead where Id in :leadMap.keySet()])
	{
		l.Initial_Campaign__c = leadMap.get(l.Id);
		lUpdate.add(l);
	}
	update lUpdate;

}