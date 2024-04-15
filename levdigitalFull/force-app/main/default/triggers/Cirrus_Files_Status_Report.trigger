trigger Cirrus_Files_Status_Report on Status_Report__c(before insert, after insert, after undelete, after update) { 
    IGD.SyncBatcher.syncFiles(); 
}