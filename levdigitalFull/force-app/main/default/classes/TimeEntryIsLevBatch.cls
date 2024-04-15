/**
 * Created 6/6/2022 ST
 * 
 * Purpose to populate the Is_Lev_Time__c field on existing Time Entries
 * 
 * 
 * Run with: 
TimeEntryIsLevBatch newBatch = new TimeEntryIsLevBatch();
Database.executeBatch(newBatch, 250);

 */
public with sharing class TimeEntryIsLevBatch implements Database.Batchable<sObject>{
    public final String QueryString;
    //private static String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);
    
    public TimeEntryIsLevBatch() {
        System.debug('**** TimeEntryIsLevBatch ****');
            
        QueryString = 'SELECT Id, Name, EntryDate__c, WeekEndDate__c, Deleted_in_Replicon__c, Project__c, Employee__c, Employee__r.Name, Employee__r.AccountId, Employee__r.Account.Name, Is_Lev_Time__c'
                            + ' FROM Replicon_Time_Entry__c'
                            + ' ORDER BY Project__c'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** TimeEntryIsLevBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Time_Entry__c> entryList){
        System.debug('**** TimeEntryIsLevBatch EXECUTE ****');

        List<Replicon_Time_Entry__c> updateEntryList = new List<Replicon_Time_Entry__c>();
        for(Replicon_Time_Entry__c entry : entryList){
            /** 
             * Is Lev Time IF:
             *  Scenario 1: Entry Date is Before 6/1/2022 and is NOT related to ATG Consultant Contact
             *  Scenario 2: Entry Date is After 6/1/2022 and the Time Entry's related Employee__c is associated with the Levementum LLC Account AND Employee__c is NOT related to ATG Consultant Contact
             */

            //Is Lev Time
            //if(((entry.EntryDate__c < switchToATGTimeDate && entry.Employee__r.Name != atgConsultantContactName) || (entry.EntryDate__c >= switchToATGTimeDate && entry.Employee__r.AccountId == levementumAccountId) ) && entry.Is_Lev_Time__c != true){
            if(((entry.EntryDate__c < switchToATGTimeDate && entry.Employee__r.Name != atgConsultantContactName) || (entry.EntryDate__c >= switchToATGTimeDate && entry.Employee__r.Account.Name == levementumAccountName && entry.Employee__r.Name != atgConsultantContactName)) && entry.Is_Lev_Time__c != true){
                entry.Is_Lev_Time__c = true;
                updateEntryList.add(entry);

            //Is NOT Lev Time
            //}else if(((entry.EntryDate__c < switchToATGTimeDate && entry.Employee__r.Name == atgConsultantContactName) || (entry.EntryDate__c >= switchToATGTimeDate && (entry.Employee__r.Account.Name != levementumAccountName || entry.Employee__r.Name != atgConsultantContactName))) && entry.Is_Lev_Time__c != false){
            }else if(entry.Is_Lev_Time__c){
                entry.Is_Lev_Time__c = false;
                updateEntryList.add(entry);
            }
        }

        if(updateEntryList.size() > 0){
            update updateEntryList;
        }
        
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** TimeEntryIsLevBatch FINISH ****');

    }
}