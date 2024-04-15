trigger AccountBeforeInsertUpdate on Account (before insert, before update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** This trigger sets the Customer Number when an Account's MSA number is populated. Customer Number is a sequential number set only
** for client record type accounts.  
** If Latest Work Log is updated on an account, the work log is appended to tracking who made the change and when
*/	
	//private static String clientAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();


	//get the current users fName (first digit) + lName
	String fName = UserInfo.getFirstName();
	fName = (fName == null ? '' : fName.substring(0,1));	
	String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
	Datetime td = Datetime.now();
	String today = td.Format('MM/dd');
	String acclog;
	String latestUpdate;
	Integer custNo;  
	//Boolean needCustNo = false;
	//get the max customer number - will be needed if cust num is being set on any of these accounts
	/*for(Account a: Trigger.new) {
        if(a.Customer_Number__c == null)
            needCustNo = true;
    }
    if(needCustNo == true){
		List<Account> accountMaxCNList = new List<Account>();
    	accountMaxCNList  = [SELECT Id, Name, Customer_Number__c
								FROM Account	
								WHERE Customer_Number__c != null
								ORDER BY Customer_Number__c DESC
								LIMIT 1];

		for (Account acc : accountMaxCNList){
			if(acc.Customer_Number__c != null){		   
	   			custNo = Integer.valueOf(acc.Customer_Number__c);	    
			}
		}	
	}*/
		
	//get the rec type for Client accounts
	//Id rt = [Select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Client' limit 1].Id;
	
	//for(Account a:Trigger.new){		
		/*if(trigger.isInsert && a.Latest_Work_Log__c != null){
			a.Work_Logs__c = uName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + a.Latest_Work_Log__c;

		}else if (trigger.isUpdate && a.Latest_Work_Log__c != null && a.Latest_Work_Log__c != trigger.oldMap.get(a.Id).Latest_Work_Log__c){
			a.Work_Logs__c = (a.Work_Logs__c == null ? '' : a.Work_Logs__c) + '\n' + uName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + a.Latest_Work_Log__c;
		}*/
		
		
		/*if(trigger.isInsert && a.Acct_Latest_Updt__c != null){
			latestUpdate = today + ' : ' + a.Acct_Latest_Updt__c;
			if(latestUpdate.length()>255){
				a.Acct_Latest_Updt__c.adderror('Please enter less than 245 characters for "Acct Latest Update" field');
			}
			a.Acct_Latest_Updt__c = latestUpdate;
			a.Account_Updates_Log__c = uName + ' ' + a.Acct_Latest_Updt__c;

		}else if (trigger.isUpdate && a.Acct_Latest_Updt__c != null && a.Acct_Latest_Updt__c != trigger.oldMap.get(a.Id).Acct_Latest_Updt__c){
			latestUpdate = today + ' : ' + a.Acct_Latest_Updt__c;
			if(latestUpdate.length()>255){
				a.Acct_Latest_Updt__c.adderror('Please enter less than 245 characters for "Acct Latest Update" field');
			}
			a.Acct_Latest_Updt__c = latestUpdate;
			acclog = uName + ' ' + a.Acct_Latest_Updt__c+ '\n' + (a.Account_Updates_Log__c == null ? '' : a.Account_Updates_Log__c);

			if(acclog.length() > 32768){
				a.Account_Updates_Log__c = acclog.left(32768);
			}else{
				a.Account_Updates_Log__c  = acclog;
			} 

		}*/
		
		
		/*if(a.MSA_Number__c != null && a.Customer_Number__c == null && a.RecordTypeId == clientAccountRT)
		{
			a.Customer_Number__c = (custNo == null ? 4000 : custNo + 1);
		}*/
	
	//}	
}