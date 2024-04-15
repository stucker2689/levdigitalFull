trigger LeadBeforeInsertUpdate on Lead (before insert, before update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** If Latest Work Log is updated on a lead, the work log is appended to tracking who made the change and when
*/
	
	String fName = UserInfo.getFirstName();
	fName = (fName == null ? '' : fName.substring(0,1));	
	String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
	
	for(Lead l:Trigger.new)
	{		
		if(trigger.isInsert && l.Latest_Work_Log__c != null)
		{
			l.Work_Logs__c = uName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + l.Latest_Work_Log__c;
		}
		else if (trigger.isUpdate && l.Latest_Work_Log__c != null && l.Latest_Work_Log__c != trigger.oldMap.get(l.Id).Latest_Work_Log__c)
		{
			l.Work_Logs__c = (l.Work_Logs__c == null ? '' : l.Work_Logs__c) + '\n' + uName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + l.Latest_Work_Log__c;
		}
	
	}

}