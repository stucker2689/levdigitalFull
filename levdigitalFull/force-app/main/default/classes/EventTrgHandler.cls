public with sharing class EventTrgHandler {

	public static void EventAccountReview(Event[] trgNew,Map<Id,Event> oldMap){
		
		Set<Id> eventAccountIds = new Set<Id>();
        //collect the account ids that are going to be used
        for(Event event :trgNew){
            if(event.Account_Review__c == true && event.WhatId != null){
                eventAccountIds.add(event.WhatId);
            }	
        }
        
        //Map to store all of the accounts that meet the criteria
        Map<Id,Account> eventAccounts = new Map<Id,Account>([SELECT Id, Next_Account_Review__c FROM Account WHERE Id IN :eventAccountIds]);
        
		for(Event event :trgNew){
            if(event.Account_Review__c == true && event.WhatId != null){
                if(eventAccounts.get(event.WhatId) != null){
                	//account Next_Account_Review__c field should be equal to event.StartDateTime.date field
                    eventAccounts.get(event.WhatId).Next_Account_Review__c = event.StartDateTime.date();
                    //if Meeting_Status__c == 'Held' then account.Last_Account_Review__c = event.EndDateTime.date
                    if(event.Meeting_Status__c == 'Held'){
                    	eventAccounts.get(event.WhatId).Last_Account_Review__c = event.EndDateTime.date();
                    }//if
                } //if
            } //if
		} //for
		
        update eventAccounts.values();
			
	}
}