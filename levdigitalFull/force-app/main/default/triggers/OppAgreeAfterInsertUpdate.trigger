trigger OppAgreeAfterInsertUpdate on echosign_dev1__SIGN_Agreement__c (after insert, after update) {

	Set<Id> opps = new Set<Id>();
	for(echosign_dev1__SIGN_Agreement__c a:Trigger.new)
	{
		if((a.Agreement_Type__c == 'Statement Of Work' || a.Agreement_Type__c == 'Change Order') && a.echosign_dev1__Status__c == 'Signed' && (trigger.isInsert || (trigger.isUpdate && trigger.oldMap.get(a.Id).echosign_dev1__Status__c != 'Signed')))
		{
			opps.add(a.echosign_dev1__Opportunity__c);
		}
	}

	Opportunity[] oppUpdate = new Opportunity[0];
	for(Opportunity o:[Select Id, Date_SOW_Signed__c from Opportunity where id in :opps])
	{
		o.Date_SOW_Signed__c = system.today();
		oppUpdate.add(o);
	}
	
	update oppUpdate;
}