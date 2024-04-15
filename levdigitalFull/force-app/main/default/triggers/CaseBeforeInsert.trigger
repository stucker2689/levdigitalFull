trigger CaseBeforeInsert on Case (before insert) {
	
	Set<Id> accts = new Set<Id>();
	for(Case c:Trigger.new)
	{
		accts.add(c.AccountId);		
	}
      	
	Map<Id, Id> oppMap = new Map<Id,Id>();	
	for (Opportunity o:[Select AccountId, Id from Opportunity where AccountId in :accts and StageName = 'Closed Won' and Has_ASC_Product__c = true 
	order by CloseDate asc])  
	{		   
	    oppMap.put(o.AccountId, o.Id);	    
	}	
	
	for(Case c1:Trigger.new)
	{
		if(oppMap.get(c1.AccountId) != null)
		{
			c1.In_Force_Service_Contract__c = oppMap.get(c1.AccountId);
		}
	}
	
}