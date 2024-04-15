trigger OppLineAfterInsertUpdate on OpportunityLineItem (after insert, after update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** This trigger sets the Discovery Session? checkbox on an opportunity if there is at least one product added to the 
** opportunity that has a name that contains Discovery Only
** This trigger sets the Renewal? checkbox on an opportunity if there is at least one product added to the 
** opportunity that has a name that contains Renewal
** This trigger sets the Account service level agreement if the opportunity has a support product that contains Gold,Silver or Platinum
*/
	Set<Id> pbeIds = new Set<Id>();		
	for(OpportunityLineItem oli:Trigger.new)
	{
		pbeIds.add(oli.PricebookEntryId);		
	}
	
	Map<Id,Boolean> pbeMap = new Map<Id, Boolean>();
	Map<Id,Boolean> pbeRenewalMap = new Map<Id, Boolean>();	
	Map<Id, String> serviceLevelMap = new Map<Id, String>();
	for(PricebookEntry pbe:[Select Id, Name from PricebookEntry where id in :pbeIds])
	{
		if(pbe.Name.Contains('Discovery Only'))
		{
			pbeMap.put(pbe.Id,true);
		}	
		if(pbe.Name.Contains('Renewal'))
		{
			pbeRenewalMap.put(pbe.Id,true);
		}
		
		if(pbe.Name.Contains('Silver'))
		{
			serviceLevelMap.put(pbe.Id,'Silver');
		}
		if(pbe.Name.Contains('Gold'))
		{
			serviceLevelMap.put(pbe.Id,'Gold');
		}
		if(pbe.Name.Contains('Platinum'))
		{
			serviceLevelMap.put(pbe.Id,'Platinum');
		}				
					
	}
			
	Set<Id> oppIds = new Set<Id>();	
	Map<Id,Boolean> oppMap = new Map<Id, Boolean>();
	Map<Id,Boolean> oppRenewalMap = new Map<Id, Boolean>();	
	Map<Id,String> accountSLA = new Map<Id,String>();
	for(OpportunityLineItem oli:Trigger.new)
	{
		if(pbeMap.get(oli.PricebookEntryId) != null)
		{			
			oppIds.add(oli.OpportunityId);
			oppMap.put(oli.OpportunityId, true);
		}	
		if(pbeRenewalMap.get(oli.PricebookEntryId) != null)
		{			
			oppIds.add(oli.OpportunityId);
			oppRenewalMap.put(oli.OpportunityId, true);
		}	
		
		if(oli.Opportunity_Product_Family__c == 'Support' && serviceLevelMap.get(oli.PriceBookEntryId) != null)	
		{
			oppIds.add(oli.OpportunityId);
			accountSLA.put(oli.OpportunityId, serviceLevelMap.get(oli.PriceBookEntryId));
		}	
	}
	
	Opportunity[] oUpdate = new Opportunity[0];
	for(Opportunity o:[Select id, Discovery_Session__c, Renewal__c, AccountId from Opportunity where Id in :oppIds])
	{
		if(oppMap.get(o.Id) != null)
		{
			o.Discovery_Session__c = true;
		}
		if(oppRenewalMap.get(o.Id) != null)
		{
			o.Renewal__c = true;
		}
		if(accountSLA.get(o.Id) != null)
		{
			accountSLA.put(o.AccountId, accountSLA.get(o.Id));
		}
		oUpdate.add(o);
	}
	
	update oUpdate;
	
	Account[] aUpdate = new Account[0];
	for(Account a:[Select Id, Service_Level__c from Account where Id in :accountSLA.keySet()])
	{
		if(accountSLA.get(a.Id) != null)
		{
			a.Service_Level__c = accountSLA.get(a.Id);
			aUpdate.add(a);
		}
	}
	
	update aUpdate;
}