/**Created 7.12.2023 ST
 * To hold the methods that run from the Account Trigger
 */
public with sharing class AccountTriggerHelper {

    private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();
    private static String clientAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
    
    public static void updateRelatedOoOCases(List<Account> accountList){
        
        Map<Id, Id> accountToADIdMap = new Map<Id, Id>();
        for(Account acc : accountList){
            accountToADIdMap.put(acc.Id, acc.Delivery_Account_Lead__c);
        }

        List<Case> relatedOoOCaseList = new List<Case>();
        relatedOoOCaseList = [SELECT Id, Project__c, Project__r.Account__c, Delivery_Account_Lead__c, Status
                            FROM Case
                            WHERE RecordTypeId =: OoOCoverageRequestCaseRT AND Project__r.Account__c IN :accountToADIdMap.keySet() AND Status != 'Completed' AND Status != 'Cancelled'];

        List<Case> updateCaseList = new List<Case>();
        for(Case c : relatedOoOCaseList){
            if(accountToADIdMap.containsKey(c.Project__r.Account__c)){
                c.Delivery_Account_Lead__c = accountToADIdMap.get(c.Project__r.Account__c);
                updateCaseList.add(c);
            }
        }

        if(updateCaseList.size() > 0){
            update updateCaseList;
        }
    }

    public static void updateRelatedProjectSupportEmails(List<Account> accountList){

        Map<Id, String> accountIdToSupportEmailMap = new Map<Id, String>();
        for(Account acc : accountList){
            accountIdToSupportEmailMap.put(acc.Id, acc.Lev_Support_Email_Address__c);
        }
        
        List<Project__c> relatedProjList = new List<Project__c>();
        relatedProjList = [SELECT Id, Name, Lev_Support_Email_Address__c, Account__c, Account__r.Lev_Support_Email_Address__c
                            FROM Project__c
                            WHERE Account__c IN :accountIdToSupportEmailMap.keySet()];

        List<Project__c> updateProjList = new List<Project__c>();
        for(Project__c proj : relatedProjList){
            if(accountIdToSupportEmailMap.containsKey(proj.Account__c)){
                if(accountIdToSupportEmailMap.get(proj.Account__c) != proj.Lev_Support_Email_Address__c){
                    proj.Lev_Support_Email_Address__c = accountIdToSupportEmailMap.get(proj.Account__c);
                    updateProjList.add(proj);
                }
            }
        }

        if(updateProjList.size() > 0){
            update updateProjList;
        }
    }
    
    public static void updateCSPEmailOnRelatedStaffingAssignments(Map<Id, Account> accountMap){
        /**
         * Purpose: When Client Success Partner (Delivery_Account_Lead__c) is changed on Account then check if there are any open (Status__c != 'Completed') Staffing Assignments on a Opportunity that is related to that Account
         * If there is then update CSP_Email__c on the open Staffing Assignments
         */

        List<Staffing_Assignment__c> relatedStaffingAssignmentList = new List<Staffing_Assignment__c>();
        relatedStaffingAssignmentList = [SELECT Id, Name, CSP_Email__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.AccountId, Opportunity__r.Account.Delivery_Account_Lead__c, Opportunity__r.Account.Delivery_Account_Lead__r.Email
                                        FROM Staffing_Assignment__c
                                        WHERE Opportunity__r.AccountId IN :accountMap.keySet() AND Status__c != 'Completed'
                                        ORDER BY Opportunity__c];

        
        List<Staffing_Assignment__c> staffingAssignmentUpdateList = new List<Staffing_Assignment__c>();
        if(relatedStaffingAssignmentList.size() > 0){
            for(Staffing_Assignment__c sa : relatedStaffingAssignmentList){
                if(sa.CSP_Email__c != sa.Opportunity__r.Account.Delivery_Account_Lead__r.Email){
                    sa.CSP_Email__c = sa.Opportunity__r.Account.Delivery_Account_Lead__r.Email;
                    staffingAssignmentUpdateList.add(sa);
                }
            }
        }

        if(staffingAssignmentUpdateList.size() > 0){
            System.debug('************************************************ Updating ' + staffingAssignmentUpdateList.size() + ' Staffing Assignments with new CSP Emails ************************************************');
            update staffingAssignmentUpdateList;
        }
    }

    public static void updateAccountAtRiskLevelCounters(List<Account> accountAtRiskCounterList){
        //If Internal Lev At Risk field changes to Yellow, Orange, or Red add to the counter
        for(Account acct : accountAtRiskCounterList){
            if(CheckRecursive.runCountAccountRiskLevelOnce()){
                if(acct.InternalLevAtRisk__c == 'Yellow'){
                    acct.Yellow_Risk_Level_Amount__c = acct.Yellow_Risk_Level_Amount__c != null ? acct.Yellow_Risk_Level_Amount__c + 1 : 1;
                }else if(acct.InternalLevAtRisk__c == 'Orange'){
                    acct.Orange_Risk_Level_Amount__c = acct.Orange_Risk_Level_Amount__c != null ? acct.Orange_Risk_Level_Amount__c + 1 : 1;
                }else if(acct.InternalLevAtRisk__c == 'Red'){
                    acct.Red_Risk_Level_Amount__c = acct.Red_Risk_Level_Amount__c != null ? acct.Red_Risk_Level_Amount__c + 1 : 1;
                }
            }
        }
    }

    public static void populateCustomerNumberOnAccount(List<Account> accountList){

        Integer maxCustomerNumber = 4000;

        List<Account> accountMaxCustomerNumberList = new List<Account>();
    	accountMaxCustomerNumberList  = [SELECT Id, Name, Customer_Number__c FROM Account	
								WHERE Customer_Number__c != null
								ORDER BY Customer_Number__c DESC
								LIMIT 1];

        if(accountMaxCustomerNumberList.size() > 0){

            if(accountMaxCustomerNumberList[0].Customer_Number__c != null){		   
                maxCustomerNumber = Integer.valueOf(accountMaxCustomerNumberList[0].Customer_Number__c);	    
            }
        }

		for(Account acct : accountList){
			if(acct.MSA_Number__c != null && acct.Customer_Number__c == null && acct.RecordTypeId == clientAccountRT){
                acct.Customer_Number__c = maxCustomerNumber;
            }	
		}	
    }

    public static void populateAccountWorkLog(List<Account> accountList, Map<Id, Account> oldMap, Boolean onInsert){
        String fName = UserInfo.getFirstName();
        fName = (fName == null ? '' : fName.substring(0,1));	
        String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());

        for(Account acct : accountList){
            if(onInsert){
                if(acct.Latest_Work_Log__c != null){
                    acct.Work_Logs__c = uName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + acct.Latest_Work_Log__c;
                }

            }else{
                if(acct.Latest_Work_Log__c != null && acct.Latest_Work_Log__c != oldMap.get(acct.Id).Latest_Work_Log__c){
                    acct.Work_Logs__c = (acct.Work_Logs__c == null ? '' : acct.Work_Logs__c) + '\n' + uName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + acct.Latest_Work_Log__c;
                }
            }
        }
    }

    public static void populateAccountLatestUpdatesLog(List<Account> accountList, Boolean onInsert){

        String fName = UserInfo.getFirstName();
        fName = (fName == null ? '' : fName.substring(0,1));	
        String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
        String today = Datetime.now().Format('MM/dd');

        for(Account acct : accountList){
            String latestUpdate = today + ' : ' + acct.Acct_Latest_Updt__c;

            if(latestUpdate.length()>255){
                acct.Acct_Latest_Updt__c.adderror('Please enter less than 245 characters for "Acct Latest Update" field');
            }
            acct.Acct_Latest_Updt__c = latestUpdate;

            if(onInsert){
                acct.Account_Updates_Log__c = uName + ' ' + acct.Acct_Latest_Updt__c;

            }else{
                String acclog = uName + ' ' + acct.Acct_Latest_Updt__c+ '\n' + (acct.Account_Updates_Log__c == null ? '' : acct.Account_Updates_Log__c);

                if(acclog.length() > 32768){
                    acct.Account_Updates_Log__c = acclog.left(32768);
                }else{
                    acct.Account_Updates_Log__c  = acclog;
                } 
            }
        }
    }
}