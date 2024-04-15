public class AccountCalculations {
/*
** Created by: Levementum
** Created Date: 10/30/2012
*/	
	public static void FirstYearBooking(Set<Id> accounts){ 
		/*
		** Created by: Levementum
		** Created Date: 10/30/2012
		** Called from OpportunityAfter trigger to do the following
		** recalc the accounts closed/won opps whenever an opp is deleted
		** recalc the accounts closed/won opps whenever an opp is inserted, or if an existing opp has a change of stage, amount or closedate
		*/
		System.debug('First Year Booking: ' + accounts);
		
		Map<Id, Account> aMap = new Map<Id, Account>([SELECT Id, First_Anniversary__c, Customer_Since__c, CustomerSince__c FROM Account WHERE Id IN :accounts]);
		
		//loop through opps for these accounts
		Map<Id, Decimal> aSum = new Map<Id, Decimal>();
		//for(Opportunity o:[Select Id, AccountId, Amount, CloseDate from Opportunity where StageName = 'Closed Won' and AccountId in :accounts])
		for(Opportunity o : [SELECT Id, AccountId, Amount, CloseDate, IsWon FROM Opportunity WHERE ForecastCategory = 'Closed' AND AccountId IN :accounts]){
			Decimal sumThis = 0;
			if(aSum.get(o.AccountId) != null){
				sumThis = aSum.get(o.AccountId);
			}
			
            Boolean useCloseDate = String.isBlank(String.valueOf(aMap.get(o.AccountId).CustomerSince__c)) && o.IsWon;
			Date customerSince = (useCloseDate) ? o.CloseDate : aMap.get(o.AccountId).CustomerSince__c;
            Date firstAnniversary  = (useCloseDate) ? o.CloseDate.addYears(1) : aMap.get(o.AccountId).First_Anniversary__c;
			if(o.Amount != null && o.CloseDate >= customerSince && o.CloseDate <= firstAnniversary){
				sumThis +=  o.Amount;
				aSum.put(o.AccountId, sumThis);
			}
		}
		
		//loop through accounts, set First Year Booking to zero initially, then set aggregate
		//can't use an actual aggregate function because of date restrictions change per account
		Account[] updateAccount = new Account[0];
		for(Account a:[Select Id, First_Year_Booking__c from Account where Id in :accounts]){
			if(aSum.get(a.Id) != null){
				if(a.First_Year_Booking__c != aSum.get(a.Id)){
					a.First_Year_Booking__c = aSum.get(a.Id);
					updateAccount.add(a);
				}
			}else{
				a.First_Year_Booking__c = 0;
				updateAccount.add(a);
			}	
		}
		
		if(updateAccount.size() > 0){
			update updateAccount;
		}
		
	}
	
	public static void SetMSA(Set<Id> accountIdSet){ 
		/*
		** Created by: Levementum
		** Created Date: 12/5/2012
		** Called from OpportunityBeforeInsertUdate trigger to do the following
		** Set the MSA on the account if it is blank - only gets set if an opportunity reaches Solution Validation stage		
		*/

		/*System.debug('SetMSA: ' + accounts);

		AggregateResult[] maxMSA  = [SELECT Max(MSA_Number__c) msan
	      	FROM Account
	      	WHERE MSA_Number__c != null and MSA_Number__c like 'MSA-%'];
	      	
	    String msaNO; 
	    Integer msaNum; 	
		for (AggregateResult ar : maxMSA){		   
		    msaNO = String.valueOf(ar.get('msan'));	    
		}		
		
		if(msaNO != null){
			msaNO = msaNO.substring(9, 13);
			System.debug(msaNO);
			msaNum = Integer.valueOf(msaNO);
		}
		
		Account[] accUpdate = new Account[0];
		for(Account a:[Select Id, MSA_Number__c from Account where Id in :accounts]){						
			if(a.MSA_Number__c == null) {
				msaNum = (msaNum == null ? 4000 : msaNum + 1);
				a.MSA_Number__c = 'MSA-' + String.valueOf(system.today().year()) + '-' + String.valueOf(msaNum);
				accUpdate.add(a);
			}
		}
		if(accUpdate.size() > 0){
			update accUpdate;
		}*/

		List<Account> accountUpdateList = new List<Account>();

		List<Account> accountList = new List<Account>();
		accountList = [SELECT Id, MSA_Number__c FROM Account WHERE Id IN :accountIdSet AND MSA_Number__c = null];

		if(accountList.size() > 0){
			List<Account> maxMsaNumberAccountList = new List<Account>();
			maxMsaNumberAccountList = [SELECT Id, Name, MSA_Number__c FROM Account WHERE MSA_Number__c != null AND MSA_Number__c LIKE 'MSA-%' ORDER BY MSA_Number__c DESC LIMIT 1];

			Integer msaNumber;
			if(maxMsaNumberAccountList.size() > 0){
				String maxMSANumberString = maxMsaNumberAccountList[0].MSA_Number__c.substring(9, 13);
				msaNumber = Integer.valueOf(maxMSANumberString);
			}

			for(Account acct : accountList){
				if(acct.MSA_Number__c == null){
					msaNumber = msaNumber == null ? 4000 : msaNumber + 1;
					acct.MSA_Number__c = 'MSA-' + String.valueOf(System.today().year()) + '-' + String.valueOf(msaNumber);
					accountUpdateList.add(acct);
				}
			}
		}

		if(accountUpdateList.size() > 0){
			System.debug('******************************* Updating ' + accountUpdateList.size() + ' Accounts with MSA Number *******************************');
			update accountUpdateList;
		}
	}
			
}