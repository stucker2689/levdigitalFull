/*********************************************
 * Created By: Sam Tucker 5/11/2021
 */

public with sharing class DeleteRepliconTimeEntries {

    public static void getTimeEntriesToDelete(Date dateToDelete, List<Id> deletedEntryList){

        Integer monthToDelete;
        monthToDelete = dateToDelete.month();

        Integer yearToDelete;
        yearToDelete = dateToDelete.year();

        List<Replicon_Time_Entry__c> timeEntriesToDelete = new List<Replicon_Time_Entry__c>();
        
        timeEntriesToDelete = [SELECT Id, Deleted_in_Replicon__c, EntryDate__c, WeekEndDate__c
                                    FROM Replicon_Time_Entry__c
                                    WHERE Deleted_in_Replicon__c = true AND CALENDAR_MONTH(WeekEndDate__c) =: monthToDelete AND CALENDAR_YEAR(WeekEndDate__c) =: yearToDelete 
                                        AND Id IN :deletedEntryList];

        if(timeEntriesToDelete.size() > 0){
            delete timeEntriesToDelete;            
            System.debug('************************************* Deleting ' + timeEntriesToDelete.size() + ' Time Entries *************************************');
            System.debug(timeEntriesToDelete);
        }

    }
}