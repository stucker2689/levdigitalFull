/**
 * Created 11/29/2022 ST To link existing Timesheets to new Capacity Records
 * 
 * Called by CreateWorkDaysBatch createWorkDaysBatch = new CreateWorkDaysBatch();
        Database.executeBatch(createWorkDaysBatch, 50);
 */
public with sharing class CreateWorkDaysBatch implements Database.Batchable<sObject>{

    public final String QueryString;
    
    public CreateWorkDaysBatch() {
        System.debug('**** CreateWorkDaysBatch ****');
        
        QueryString = 'SELECT Id, Name, Employee__c, Employee__r.Name, Start_Date__c, End_Date__c, Target__c, Employee__r.Weekly_Target__c, Employee__r.RampTime__c, Employee__r.Ramp_End_Date__c, Employee__r.Active__c,'
                        + ' Employee__r.Term_Date__c, Employee__r.Division_New__c, Employee__r.ReportsToId, Employee__r.ReportsTo.Name, Employee__r.AccountId, Employee__r.Account.Name'
                        + ' FROM Replicon_Timesheet__c'
                        + ' WHERE Start_Date__c != null AND Employee__c != null AND End_Date__c != null AND Employee__r.Title != \'#N/A\' AND Employee__r.RecordType.Name != \'Placeholder Employee\''
                        + ' ORDER BY Employee__c, Start_Date__c DESC'; 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** CreateWorkDaysBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Replicon_Timesheet__c> timesheetList){
        System.debug('**** CreateWorkDaysBatch EXECUTE ****');
        /**
         * Function Purpose: Create Work Days for each day of existing Timesheets
         */

        List<Id> timesheetIdList = new List<Id>();

        for(Replicon_Timesheet__c timesheet : timesheetList){
            timesheetIdList.add(timesheet.Id);
        }

        List<WorkDay__c> existingWorkDayList = new List<WorkDay__c>();
        existingWorkDayList = [SELECT Id, Name, Employee__c, WorkDayDate__c, RepliconTimesheet__c
                                FROM WorkDay__c
                                WHERE RepliconTimesheet__c IN :timesheetIdList];

        Map<String, WorkDay__c> existingWorkDayMap = new Map<String, WorkDay__c>();
        for(WorkDay__c wd : existingWorkDayList){
            //Create unique Id map of existing Work Day records (Unique Id is Employee Record Id a+ the WorkDayDate)
            String uniqueId = String.valueOf(wd.Employee__c) + '|' + String.valueOf(wd.WorkDayDate__c);
            existingWorkDayMap.put(uniqueId, wd);
        }

        List<WorkDay__c> newWorkDayToInsertList = new List<WorkDay__c>();
        for(Replicon_Timesheet__c timesheet : timesheetList){
            
            Date timesheetStartDate = timesheet.Start_Date__c;
            Integer addDays = 0;
            Date iterationDate = timesheetStartDate;

            while(iterationDate < timesheet.End_Date__c){
                iterationDate = timesheetStartDate.addDays(addDays);
                addDays++;

                String uniqueId = String.valueOf(timesheet.Employee__c) + '|' + String.valueOf(iterationDate);
                //Only create Work Days if they don't already exist
                if(!existingWorkDayMap.containsKey(uniqueId)){

                    WorkDay__c newWorkDay = new WorkDay__c();
                    newWorkDay.Employee__c = timesheet.Employee__c;
                    newWorkDay.EmployeeDivision__c = timesheet.Employee__r.Division_New__c;
                    newWorkDay.RepliconTimesheet__c = timesheet.Id;
                    newWorkDay.WorkDayDate__c = iterationDate;
                    newWorkDay.EmployeesManager__c = timesheet.Employee__r.ReportsToId;
                    newWorkDay.Name = (timesheet.Employee__r.Name + ' - ' + String.valueOf(DateTime.newInstance(iterationDate.year(), iterationDate.month(), iterationDate.day()).format('MM/dd/YYYY'))).left(80);

                    Datetime dt = DateTime.newInstance(iterationDate, Time.newInstance(0, 0, 0, 0));
                    String dayOfWeek = dt.format('EEEE'); //Format Date to see what day of the week it is  (i.e. Friday, Saturday)

                    if((timesheet.Employee__r.Ramp_End_Date__c != null && iterationDate < timesheet.Employee__r.Ramp_End_Date__c) || (timesheet.Employee__r.Weekly_Target__c <= 0 || timesheet.Employee__r.Weekly_Target__c == null) || 
                        (timesheet.Employee__r.Term_Date__c != null && iterationDate > timesheet.Employee__r.Term_Date__c) || timesheet.Employee__r.Active__c == false){
                        newWorkDay.WorkingHours__c = 0;

                    }else if(dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday' ){
                        //0 Working Hours if it is a Saturday or Sunday
                        newWorkDay.WorkingHours__c = 0;
                        
                    }else{
                        /** Working Hours is 8 if Working Day is NOT:
                          *     1.) Before the End of Employee's Ramp
                          *     2.) For a Non-billable employee (i.e. has a Weekly Target of 0 or null)
                          *     3.) Is after the Term Date of the Employee
                          *     4.) Is on a Saturday or Sunday
                          **/
                        newWorkDay.WorkingHours__c = 8;
                    }

                    existingWorkDayMap.put(uniqueId, newWorkDay);

                    newWorkDayToInsertList.add(newWorkDay);
                }
            }
        }

        if(newWorkDayToInsertList.size() > 0){
            System.debug('****************** Inserting ' + newWorkDayToInsertList.size() + ' Work Day Records *********************************');
            insert newWorkDayToInsertList;
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** CreateWorkDaysBatch FINISH ****');

    }
}