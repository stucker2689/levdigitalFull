/**
 * Created by jmahapatra on 11/13/17.
 */

public with sharing class AccountTriggerHandler {

    private static String clientAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();

    //=========================================================================
    //PUBLIC METHODS
    //=========================================================================
    public static void beforeInsert(List<Account> accountList) {

        List<Account> populateCustomerNumberAccountList = new List<Account>();
        List<Account> populateWorkLogAccountList = new List<Account>();
        List<Account> populateLatestUpdatesLogAccountList = new List<Account>();

        for(Account acct : accountList){

            if(acct.MSA_Number__c != null && acct.Customer_Number__c == null && acct.RecordTypeId == clientAccountRT){//Populate Customer Number Field
                populateCustomerNumberAccountList.add(acct);
            }

            if(acct.Latest_Work_Log__c != null){ //Populate Work Log
                populateWorkLogAccountList.add(acct);
            }

            if(acct.Acct_Latest_Updt__c != null){ //Populate Account Latest Updates
                populateLatestUpdatesLogAccountList.add(acct);
            }
        }

        if(populateCustomerNumberAccountList.size() > 0){
            AccountTriggerHelper.populateCustomerNumberOnAccount(populateCustomerNumberAccountList);
        }

        if(populateWorkLogAccountList.size() > 0){
            AccountTriggerHelper.populateAccountWorkLog(populateWorkLogAccountList, null, true);
        }

        if(populateLatestUpdatesLogAccountList.size() > 0){
            AccountTriggerHelper.populateAccountLatestUpdatesLog(populateLatestUpdatesLogAccountList, true);
        }
    }
    //public static void afterInsert(List<Account> accountList) {
        //for(SObject obj : records) {
            //Account a = (Account)obj;

            // doesnt run during unit testing to avoid callouts during test data setup
            //if(!Test.isRunningTest()) this.upsertRepliconClient(a);
        //}
    //}
    public static void beforeUpdate(List<Account> accountList, Map<Id, Account> oldMap) {

        List<Account> riskCounterAccountList = new List<Account>();
        List<Account> populateCustomerNumberAccountList = new List<Account>();
        List<Account> populateWorkLogAccountList = new List<Account>();
        List<Account> populateLatestUpdatesLogAccountList = new List<Account>();
        //If Internal Lev At Risk field changes to Yellow, Orange, or Red add to the counter
        for(Account acct : accountList){ 
            Account oldAccount = oldMap.get(acct.Id);

            if(acct.MSA_Number__c != null && acct.Customer_Number__c == null && acct.RecordTypeId == clientAccountRT){ //Populate Account Customer Number
                populateCustomerNumberAccountList.add(acct);
            }

            if(acct.InternalLevAtRisk__c != oldAccount.InternalLevAtRisk__c){ //Add to Account Risk Level Counters
                riskCounterAccountList.add(acct);
            }

            if(acct.Latest_Work_Log__c != null && acct.Latest_Work_Log__c != oldMap.get(acct.Id).Latest_Work_Log__c){//Populate Account Work Log
                populateWorkLogAccountList.add(acct);
            }

            if(acct.Acct_Latest_Updt__c != null && acct.Acct_Latest_Updt__c != oldMap.get(acct.Id).Acct_Latest_Updt__c){//Update Account Latest Updates
                populateLatestUpdatesLogAccountList.add(acct);
            }
        }

        if(populateCustomerNumberAccountList.size() > 0){
            AccountTriggerHelper.populateCustomerNumberOnAccount(populateCustomerNumberAccountList);
        }

        if(riskCounterAccountList.size() > 0){//If Internal Lev At Risk field changes to Yellow, Orange, or Red add to the counter
            AccountTriggerHelper.updateAccountAtRiskLevelCounters(riskCounterAccountList);
        }

        if(populateWorkLogAccountList.size() > 0){
            AccountTriggerHelper.populateAccountWorkLog(populateWorkLogAccountList, oldMap, false);
        }

        if(populateLatestUpdatesLogAccountList.size() > 0){
            AccountTriggerHelper.populateAccountLatestUpdatesLog(populateLatestUpdatesLogAccountList, false);
        }
    }
    public static void afterUpdate(List<Account> accountList, Map<Id, Account> oldMap) {

        List<Account> accountDirectorChangedList = new List<Account>();
        List<Account> levSupportEmailChangedAccList = new List<Account>();
        Map<Id, Account> cspUpdatedAccountMap = new Map<Id, Account>();
        //iterate over updated records
        for(Account acct : accountList){
            Account oldAccount = oldMap.get(acct.Id);

            // check if required fields have changed
            //if(isRepliconFieldsChanged(a, a_old)) {
                // doesnt run during unit testing to avoid callouts during test data setup
                //if(!Test.isRunningTest()) this.upsertRepliconClient(a);
            //}

            //Check if Account Director Changes
            if(acct.Delivery_Account_Lead__c != oldAccount.Delivery_Account_Lead__c){
                accountDirectorChangedList.add(acct);
                cspUpdatedAccountMap.put(acct.Id, acct);
            }

            //Check if Lev Support Email Address Changes
            if(acct.Lev_Support_Email_Address__c != oldAccount.Lev_Support_Email_Address__c){
                levSupportEmailChangedAccList.add(acct);
            }
        }

        if(accountDirectorChangedList.size() > 0){
            System.debug('AccountDirectorChangedList');
            AccountTriggerHelper.updateRelatedOoOCases(accountDirectorChangedList);
            AccountTriggerHelper.updateCSPEmailOnRelatedStaffingAssignments(cspUpdatedAccountMap);
        }

        if(levSupportEmailChangedAccList.size() > 0){
            System.debug('LevSupportEmailChangedAccList');
            AccountTriggerHelper.updateRelatedProjectSupportEmails(levSupportEmailChangedAccList);
        }

    }
    /*public static void beforeDelete(List<Account> accountList, Map<Id, Account> oldMap) {
    }
    public static void afterDelete(List<Account> accountList, Map<Id, Account> oldMap) {
    }
    public static void afterUndelete(List<Account> accountList) {
    }*/

    //=========================================================================
    //PRIVATE METHODS
    //=========================================================================
    /**
     * Checks if the fields used in the Replicon integration have changed so that updates
     * can be sent to Replicon if they have.
     *
     * @param account The new account record value from the trigger
     * @param oldAccount The old account record value from the trigger
     */
    /*private Boolean isRepliconFieldsChanged(Account account, Account oldAccount) {
        if(account.Name != oldAccount.Name) return true;
        if(account.Phone != oldAccount.Phone) return true;
        if(account.Fax != oldAccount.Fax) return true;
        if(account.Website != oldAccount.Website) return true;
        if(account.Description != oldAccount.Description) return true;

        if(account.BillingStreet != oldAccount.BillingStreet) return true;
        if(account.BillingCity != oldAccount.BillingCity) return true;
        if(account.BillingState != oldAccount.BillingState) return true;
        if(account.BillingPostalCode != oldAccount.BillingPostalCode) return true;

        return false;
    }*/

    /**
     * Enqueues a background job to push the Client (Account) data from Salesforce to Replicon.
     *
     * @param account The account record to sync with Replicon
     */
    //@TestVisible
    //private void upsertRepliconClient(Account account)
    //{
        //RepliconClientUpsert clientUpsert = new RepliconClientUpsert(account.Id);
        //system.enqueueJob(clientUpsert);
    //}

}