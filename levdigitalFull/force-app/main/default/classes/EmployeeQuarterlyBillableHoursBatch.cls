/**
 * Created 5/24/2022 ST
 * 
 * Purpose: To be run at the start of each quarter in order to reset Employee Billable Hours this Quarter field to 0 for the quarter and populate the Billable hours Last Month with the previous value
 * 
 * Functionality: 
 * (In case I cant run it at the start of every quarter, I will run it every month and just check before it starts that it is the first day of a quarter)
 * Query Employee RT Contacts
 * Set the Billable Hours this Month field to 0 and move the previous value to the Billable Hours Last Month field, (Might recalculate the previous quarter field to ensure the correct amount is being populated)
 * Update the contact record(s) 
 * 
 * Schedule this batch job for the 1st of each Quarter (January, April, July, October)
EmployeeQuarterlyBillableHoursBatch newBatchRun = new EmployeeQuarterlyBillableHoursBatch();
System.schedule('Employee Quarterly Billed Hours Batch Run', '0 15 1 ? JAN,APR,JUL,OCT *', newBatchRun);

 */
public with sharing class EmployeeQuarterlyBillableHoursBatch implements Database.Batchable<sObject>, Schedulable{

    public final String QueryString;

    public void execute(SchedulableContext sc) {
        EmployeeQuarterlyBillableHoursBatch batch = new EmployeeQuarterlyBillableHoursBatch();
        Database.executeBatch(batch, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('EmployeeQuarterlyBillableHoursBatch START');
        String QueryString = 'SELECT Id, Name, Billed_Hours_this_Quarter__c, Billed_Hours_Last_Quarter__c FROM Contact' +
			                    ' WHERE RecordType.Name = \'Employee\' AND Active__c = true AND Replicon_User_Number__c != null';

        System.debug('QueryString: ' + QueryString);
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Contact> contactList){
        System.debug('EmployeeQuarterlyBillableHoursBatch EXECUTE');

        Date currentQuarterStartDate = getStartDateOfQuarterFromDate(Date.today());
        Date previousQuarterStartDate = currentQuarterStartDate.addMonths(-3);
        Date nextQuarterStartDate = currentQuarterStartDate.addMonths(3);

        Map<Id, Contact> employeeIdToUpdateContactMap = new Map<Id, Contact>();
        
        for(Contact c : contactList){
            Contact updateContact = new Contact(Id = c.Id, Billed_Hours_this_Quarter__c = 0, Billed_Hours_Last_Quarter__c = 0);
            employeeIdToUpdateContactMap.put(c.Id, updateContact);
        }

        AggregateResult[] currentQuarterAggregate = [SELECT sum(TotalHrs__c) currentQuarterHoursSum, Employee__c
                                                        FROM Replicon_Time_Entry__c
                                                        WHERE Employee__c IN :employeeIdToUpdateContactMap.keySet() AND EntryDate__c >= :currentQuarterStartDate AND EntryDate__c < :nextQuarterStartDate
                                                            AND Associated_Billing_Rate__c != null AND Deleted_in_Replicon__c = false AND Time_Off__c = false AND TotalHrs__c != 0
                                                        GROUP BY Employee__c];

        for(AggregateResult ar : currentQuarterAggregate){
            Id employeeId = (Id)ar.get('Employee__c');

            if(employeeIdToUpdateContactMap.containsKey(employeeId)){

                Contact updateContact = employeeIdToUpdateContactMap.get(employeeId);
                updateContact.Billed_Hours_this_Quarter__c = (Decimal)ar.get('currentQuarterHoursSum');
                employeeIdToUpdateContactMap.put(employeeId, updateContact);
            }
        }

        AggregateResult[] previousQuarterAggregate = [SELECT sum(TotalHrs__c) previousQuarterHoursSum, Employee__c
                                                        FROM Replicon_Time_Entry__c
                                                        WHERE Employee__c IN :employeeIdToUpdateContactMap.keySet() AND EntryDate__c >= :previousQuarterStartDate AND EntryDate__c < :currentQuarterStartDate
                                                            AND Associated_Billing_Rate__c != null AND Deleted_in_Replicon__c = false AND Time_Off__c = false AND TotalHrs__c != 0
                                                        GROUP BY Employee__c];

        for(AggregateResult ar : previousQuarterAggregate){
            Id employeeId = (Id)ar.get('Employee__c');

            if(employeeIdToUpdateContactMap.containsKey(employeeId)){

                Contact updateContact = employeeIdToUpdateContactMap.get(employeeId);
                updateContact.Billed_Hours_Last_Quarter__c = (Decimal)ar.get('previousQuarterHoursSum');
                employeeIdToUpdateContactMap.put(employeeId, updateContact);
            }
        }

        List<Contact> updateContactList = new List<Contact>();
        for(Contact existingContact : contactList){
            if(employeeIdToUpdateContactMap.containsKey(existingContact.Id)){
                Contact updateContact = employeeIdToUpdateContactMap.get(existingContact.Id);
                if(existingContact.Billed_Hours_this_Quarter__c != updateContact.Billed_Hours_this_Quarter__c || existingContact.Billed_Hours_Last_Quarter__c != updateContact.Billed_Hours_Last_Quarter__c){
                    updateContactList.add(updateContact);
                }
            }
        }

        if(updateContactList.size() > 0){
            System.debug('****************************************** Contacts being Updated: ' + updateContactList.size() + ' ******************************************');
            update updateContactList;
        }

    }

    public void finish(Database.BatchableContext BC){
        System.debug('EmployeeQuarterlyBillableHoursBatch FINISH');

    }

    public static Date getStartDateOfQuarterFromDate(Date d){
        
        Integer dateMonth = d.month();
        Date quarterStartDate;

        switch on dateMonth {
            when 1, 2, 3{
                quarterStartDate = Date.newInstance(d.year(), 1, 1); //Q1
            }
            when 4, 5, 6{
                quarterStartDate = Date.newInstance(d.year(), 4, 1); //Q2
            }
            when 7, 8, 9{
                quarterStartDate = Date.newInstance(d.year(), 7, 1); //Q3
            }
            when 10, 11, 12{
                quarterStartDate = Date.newInstance(d.year(), 10, 1); //Q4
            }
          }

          return quarterStartDate;

    }
}