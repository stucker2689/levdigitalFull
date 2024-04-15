public with sharing class ContactTriggerHelper {

    private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();

    private static String placeholderContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Placeholder Employee').getRecordTypeId();
    
    public static void updateRelatedOoOCases(List<Contact> contactList){
        
        Map<Id, Id> contactToManagerId = new Map<Id, Id>();
        for(Contact c : contactList){
            contactToManagerId.put(c.Id, c.ReportsToId);
        }

        List<Case> relatedOoOCaseList = new List<Case>();
        relatedOoOCaseList = [SELECT Id, ContactId, Manager_of_Resource__c, Out_of_Office_Coverage_Resource__c, Out_of_Office_Coverage_Resource_Manager__c, Status
                            FROM Case
                            WHERE RecordTypeId =: OoOCoverageRequestCaseRT AND (ContactId IN :contactToManagerId.keySet() OR Out_of_Office_Coverage_Resource__c IN :contactToManagerId.keySet()) AND Status != 'Completed' AND Status != 'Cancelled'];

        List<Case> updateCaseList = new List<Case>();
        for(Case c : relatedOoOCaseList){
            Boolean needsUpdate = false;
            if(contactToManagerId.containsKey(c.ContactId)){
                c.Manager_of_Resource__c = contactToManagerId.get(c.ContactId);
                needsUpdate = true;
            }
            if(contactToManagerId.containsKey(c.Out_of_Office_Coverage_Resource__c)){
                c.Out_of_Office_Coverage_Resource_Manager__c = contactToManagerId.get(c.Out_of_Office_Coverage_Resource__c);
                needsUpdate = true;
            }
            
            if(needsUpdate == true){
                updateCaseList.add(c);
            }
        }

        if(updateCaseList.size() > 0){
            update updateCaseList;
        }
    }


    public static void setContactWorkLog(List<Contact> contactList, Map<Id, Contact> oldContactMap, String triggerContext){
        String fName = UserInfo.getFirstName() == null ? '' : UserInfo.getFirstName().substring(0, 1);
        String loggedInUserName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());

        for(Contact c : contactList){

            if(triggerContext == 'Before Insert'){

                //Set the Work Logs on the Contact
                c.Work_Logs__c = loggedInUserName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + c.Latest_Work_Log__c;
                
            }else if(triggerContext == 'Before Update'){

                //Set the new Work Logs before update
                c.Work_Logs__c = (c.Work_Logs__c == null ? '' : c.Work_Logs__c) + '\n' + loggedInUserName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + c.Latest_Work_Log__c;
            }
        }

    }

    public static void setContactNPSContextLog(List<Contact> contactList, Map<Id, Contact> oldContactMap, String triggerContext){
        String today = Datetime.now().Format('MM/dd');
        String fName = UserInfo.getFirstName() == null ? '' : UserInfo.getFirstName().substring(0, 1);
        String loggedInUserName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());

        for(Contact c : contactList){

            if(triggerContext == 'Before Insert'){

                //Set the NPS Context Logs on the Contact 
                c.NPS_Context__c = today + ' : ' + c.NPS_Context__c;
                c.NPS_Context_Log__c   = loggedInUserName + ' ' + c.NPS_Context__c;
                
            }else if(triggerContext == 'Before Update'){

                //Set the NPS Context Logs on the Contact(s) before Update
                String npsContextLog;
                c.NPS_Context__c = today + ' : ' + c.NPS_Context__c;
                npsContextLog = loggedInUserName + ' ' + c.NPS_Context__c+ '\n' + (c.NPS_Context_Log__c == null ? '' : c.NPS_Context_Log__c);
                if(npsContextLog.length() > 131072) {
                    c.NPS_Context_Log__c = ' ' + npsContextLog.left(131072);
                } else {
                    c.NPS_Context_Log__c  = npsContextLog;
                }
            }

        }

    }

    public static void removeFutureTimesheetsAndEntriesForInactiveContacts(Map<Id, Contact> inactiveContactMap){


        Map<Id, Replicon_Timesheet__c> inactiveTimesheetMap = new Map<Id, Replicon_Timesheet__c>([SELECT Id, Name, Employee__c, Start_Date__c, End_Date__c FROM Replicon_Timesheet__c WHERE Start_Date__c > TODAY AND Employee__c IN :inactiveContactMap.keySet()]);

        if(inactiveTimesheetMap.size() > 0){

            List<Replicon_Time_Entry__c> entryList = new List<Replicon_Time_Entry__c>();
            entryList = [SELECT Id, Name, Employee__c, Employee__r.Name, Project__c, Project__r.Name, WeekEndDate__c, EntryDate__c, TotalHrs__c, Replicon_Timesheet__c, Deleted_in_Replicon__c, Time_Off__c 
                            FROM Replicon_Time_Entry__c
                            WHERE Replicon_Timesheet__c IN :inactiveTimesheetMap.keySet() AND Deleted_in_Replicon__c = false];

            List<Replicon_Time_Entry__c> entriesToDeleteList = new List<Replicon_Time_Entry__c>();
            for(Replicon_Time_Entry__c entry : entryList){
                entry.Deleted_in_Replicon__c = true;
                entriesToDeleteList.add(entry);
            }

            if(entriesToDeleteList.size() > 0){
                update entriesToDeleteList;
            }

            delete inactiveTimesheetMap.values();
        }

    }

    public static void updateContactTimesheetWeekTargets(Map<Id, Contact> contactMap){

        List<Replicon_Timesheet__c> timesheetsToUpdateList = new List<Replicon_Timesheet__c>();

        Date currentWeekStartDate = Date.today().toStartOfWeek();

        List<Replicon_Timesheet__c> relatedTimesheetList = new List<Replicon_Timesheet__c>();
        relatedTimesheetList = [SELECT Id, Name, Target__c, Start_Date__c, End_Date__c, Employee__c, Employee__r.Weekly_Target__c, Employee__r.Active__c, Employee__r.Term_Date__c, Employee__r.RampTime__c , Employee__r.Ramp_End_Date__c
                                FROM Replicon_Timesheet__c 
                                WHERE Employee__c IN :contactMap.keySet() AND Start_Date__c > :currentWeekStartDate];

        for(Replicon_Timesheet__c timesheet : relatedTimesheetList){
            if(contactMap.containsKey(timesheet.Employee__c)){
                Decimal timesheetExpectedHours;
                //Only Calculate Week Target on Timesheet if the Employee is Active OR if the Employee is not active then only calculate timesheet target if the timesheet was before their termination date
                if(timesheet.Employee__r.Active__c == true || (timesheet.Employee__r.Term_Date__c != null && timesheet.Employee__r.Active__c == false && timesheet.Start_Date__c < timesheet.Employee__r.Term_Date__c)){

                    //Calculate Ramp Time into the Expected Hours if Weekly Target, Ramp Time, Ramp End Date, and Timesheet Start Date are populated
                    if(timesheet.Employee__r.Weekly_Target__c != null && timesheet.Employee__r.RampTime__c != null && timesheet.Employee__r.Ramp_End_Date__c != null && timesheet.Start_Date__c != null){
                        timesheetExpectedHours = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(timesheet.Employee__r.Weekly_Target__c, timesheet.Employee__r.RampTime__c, timesheet.Employee__r.Ramp_End_Date__c, timesheet.Start_Date__c);

                    //If the Ramp fields are not populated then just populate the expected Hours with the weekly Target if populated
                    }else if(timesheet.Employee__r.Weekly_Target__c != null){
                        timesheetExpectedHours = timesheet.Employee__r.Weekly_Target__c;

                    //If Weekly Target is not populated then set Expected hours to 0
                    }else{
                        timesheetExpectedHours = 0;
                    }
                //If Timesheet is for an inactive employee and the timesheet is after the related Employee's Termination date then set the expected hours to 0
                }else{
                    timesheetExpectedHours = 0;
                }

                //If expected hours is not already equal to the timesheets existing expected hours then set it and add it to update list.
                if(timesheet.Target__c != timesheetExpectedHours){
                    timesheet.Target__c = timesheetExpectedHours;
                    timesheetsToUpdateList.add(timesheet);
                }
            }
        }

        if(timesheetsToUpdateList.size() > 0){
            System.debug('+++++++++++++++++++++++++++++++++++ Updating ' + timesheetsToUpdateList.size() + ' Timesheets Week Targets ++++++++++++++++++++++++++++++++++++++++++');
            update timesheetsToUpdateList;
        }

    }

    public static void updateTimesheetContactDetails(Map<Id, Contact> titleChangedContactMap, Map<Id, Contact> divisionChangedContactMap, Map<Id, Contact> managerChangedContactMap, Map<Id, Contact> departmentChangedContactMap){

        List<Replicon_Timesheet__c> updateTimesheetList = new List<Replicon_Timesheet__c>();

        Date currentWeekStartDate = Date.today().toStartOfWeek();

        List<Replicon_Timesheet__c> relatedTimesheetList = new List<Replicon_Timesheet__c>();
        relatedTimesheetList = [SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, EmployeeDivision__c, EmployeeTitle__c, EmployeesManager__c, EmployeeDepartment__c
                                FROM Replicon_Timesheet__c 
                                WHERE (Employee__c IN :titleChangedContactMap.keySet() OR Employee__c IN :divisionChangedContactMap.keySet() OR Employee__c IN :managerChangedContactMap.keySet()) AND Employee__c != null AND Start_Date__c > :currentWeekStartDate];

        for(Replicon_Timesheet__c timesheet : relatedTimesheetList){
            Boolean needsUpdate = false;

            //Update Employee Title on Timesheet if needed
            if(titleChangedContactMap.containsKey(timesheet.Employee__c)){
                if(timesheet.EmployeeTitle__c != titleChangedContactMap.get(timesheet.Employee__c).Title){
                    timesheet.EmployeeTitle__c = titleChangedContactMap.get(timesheet.Employee__c).Title;
                    needsUpdate = true;
                }
            }

            //Update Employee Division on Timesheet if needed
            if(divisionChangedContactMap.containsKey(timesheet.Employee__c)){
                if(timesheet.EmployeeDivision__c != divisionChangedContactMap.get(timesheet.Employee__c).Division_New__c){
                    timesheet.EmployeeDivision__c = divisionChangedContactMap.get(timesheet.Employee__c).Division_New__c;
                    needsUpdate = true;
                }
            }

            //Update Employee's Manager on Timesheet if needed
            if(managerChangedContactMap.containsKey(timesheet.Employee__c)){
                if(timesheet.EmployeesManager__c != managerChangedContactMap.get(timesheet.Employee__c).ReportsToId){
                    timesheet.EmployeesManager__c = managerChangedContactMap.get(timesheet.Employee__c).ReportsToId;
                    needsUpdate = true;
                }
            }

            //Update Employee Department on Timesheet if needed
            if(departmentChangedContactMap.containsKey(timesheet.Employee__c)){
                if(timesheet.EmployeeDepartment__c != departmentChangedContactMap.get(timesheet.Employee__c).Department){
                    timesheet.EmployeeDepartment__c = departmentChangedContactMap.get(timesheet.Employee__c).Department;
                    needsUpdate = true;
                }
            }

            if(needsUpdate){
                updateTimesheetList.add(timesheet);
            }
        }

        if(updateTimesheetList.size() > 0){
            System.debug('********************* Updating Timesheet Contact Details on ' + updateTimesheetList.size() + ' Timesheets *********************');
            update updateTimesheetList;
        }

    }

    public static void updateWorkDayEmployeeDetails(Map<Id, Contact> contactMap){

        List<WorkDay__c> workDateUpdateList = new List<WorkDay__c>();
        Date currentDate = Date.today();

        List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
        relatedWorkDayList = [SELECT Id, Name, WorkDayDate__c, Employee__c, EmployeeDivision__c, EmployeesManager__c
                                FROM WorkDay__c 
                                WHERE Employee__c IN :contactMap.keySet()  AND WorkDayDate__c >= :currentDate];

        for(WorkDay__c workDay : relatedWorkDayList){
            Boolean needsUpdate = false;
            if(contactMap.containsKey(workDay.Employee__c)){

                //Update Employee Manager on Work Day if needed
                if(workDay.EmployeeDivision__c != contactMap.get(workDay.Employee__c).Division_New__c){
                    workDay.EmployeeDivision__c = contactMap.get(workDay.Employee__c).Division_New__c;
                    needsUpdate = true;
                }

                //Update Employee Division on Work Day if needed
                if(workDay.EmployeesManager__c != contactMap.get(workDay.Employee__c).ReportsToId){
                    workDay.EmployeesManager__c = contactMap.get(workDay.Employee__c).ReportsToId;
                    needsUpdate = true;
                }

                if(needsUpdate){
                    workDateUpdateList.add(workDay);
                }
            }
        }

        if(workDateUpdateList.size() > 0){
            System.debug('********************* Updating Work Day Employee Details on ' + workDateUpdateList.size() + ' Work Day(s) *********************');
            update workDateUpdateList;
        }

    }

    public static void updateWorkDayWorkingHours(Map<Id, Contact> contactMap, Map<Id, Contact> oldMap, Boolean forRampEndDateUpdate, Boolean forTermDateUpdate, Boolean forQuarterlyTargetUpdate){
        /**
         * Purpose: When Ramp Date, Ramp Time, or Term Date are editted Work Days need to be recalculated to either have 8 Working Hours or 0 Working Hours
         */
        System.debug('Update Work Day Working Hours');

        List<WorkDay__c> workDaysToUpdateList = new List<WorkDay__c>();

        Map<Id, Date> contactIdToNewTermDateMap = new Map<Id, Date>();
        Map<Id, Date> contactIdToOldTermDateMap = new Map<Id, Date>();

        Map<Id, Date> contactIdToNewRampEndDateMap = new Map<Id, Date>();
        Map<Id, Date> contactIdToOldRampEndDateMap = new Map<Id, Date>();

        List<Id> contactIdWithQuarterlyTargetUpdatedToZeroList = new List<Id>();
        List<Id> contactIdWithQuarterlyTargetUpdatedFromZeroList = new List<Id>();

        Date latestNewRampEndDate;
        Date earliestTerminationDate;

        Date newRampEndDate;
        Date oldRampEndDate;

        Date currentDate = Date.today();

        String updateString;

        for(Contact con : contactMap.values()){     
            
            System.debug('Contact Ramp End Date: ' + con.Ramp_End_Date__c);

            if(oldMap.containsKey(con.Id)){
                Contact oldContact = oldMap.get(con.Id);
                System.debug('ContoldContactact Ramp End Date: ' + oldContact.Ramp_End_Date__c);

                /******************************************** Update Employees Related Work Day's Working Hours based on Changes to the Employee's Ramp Time or Hire Date (basically if Ramp End Date changes) ********************************************/
                if(forRampEndDateUpdate){
                    updateString = 'Ramp End Date';
                    if(con.RampTime__c != oldContact.RampTime__c || con.Hire_Date__c != oldContact.Hire_Date__c){

                        if(con.Hire_Date__c != null && con.RampTime__c != null){ //Get the new Ramp End Date
                            newRampEndDate = con.Hire_Date__c.addDays((Integer)(7 * con.RampTime__c));
                        }

                        if(oldContact.Hire_Date__c != null && con.RampTime__c != null){ //Get the old Ramp End Date
                            oldRampEndDate = oldContact.Hire_Date__c.addDays((Integer)(7 * con.RampTime__c));
                        }

                        if(newRampEndDate != null && oldRampEndDate != null){ //If Employee has an updated Ramp End Date

                            if(newRampEndDate > oldRampEndDate){ //If Ramp End Date moved forward       Ex. New Ramp End Date: 12/20/2022       Previous Ramp End Date: 12/10/2022
                                //Need to get the Work Days that are BEFORE THE NEW Ramp End Date but were AFTER THE OLD Ramp End Date and update them to 0 Working Hours
                                contactIdToNewRampEndDateMap.put(con.Id, newRampEndDate);
                                if(latestNewRampEndDate == null || newRampEndDate > latestNewRampEndDate){
                                    latestNewRampEndDate = newRampEndDate;
                                } 

                            }else if(newRampEndDate < oldRampEndDate){ //If Ramp End Date moved backwards        Ex. New Ramp End Date: 12/10/2022       Previous Ramp End Date: 12/20/2022
                                //Need to get the Work Days that were BEFORE THE OLD Ramp End Date but are now AFTER THE NEW Ramp End Date and update them to 8 Working Hours
                                contactIdToOldRampEndDateMap.put(con.Id, oldRampEndDate);
                                if(latestNewRampEndDate == null || oldRampEndDate > latestNewRampEndDate){
                                    latestNewRampEndDate = oldRampEndDate;
                                } 

                            }
                        }else if(newRampEndDate != null && oldRampEndDate == null){ //If Employee was updated to HAVE a Ramp End Date and previously did not
                            //Need to get the Work Days that fall before the Ramp End Date and update them to 0 Working Hours
                            contactIdToNewRampEndDateMap.put(con.Id, newRampEndDate);
                            if(latestNewRampEndDate == null || newRampEndDate > latestNewRampEndDate){
                                latestNewRampEndDate = newRampEndDate;
                            } 


                        }else if(newRampEndDate == null && oldRampEndDate != null){ //If Employee was updated to NOT HAVE Ramp End Date but previously had one
                            //Need to get the Work Days that fell before the previous Ramp End Date and update them to 8 working hours (dependent on other Working Hours factors)
                            contactIdToOldRampEndDateMap.put(con.Id, oldRampEndDate);
                            if(latestNewRampEndDate == null || oldRampEndDate > latestNewRampEndDate){
                                latestNewRampEndDate = oldRampEndDate;
                            } 
                        }
                    }
                }




                /******************************************** Update Employees Related Work Day's Working Hours based on Changes to the Employee's Termination Date ********************************************/
                if(forTermDateUpdate){
                    updateString = 'Termination Date';
                    if(con.Term_Date__c != oldContact.Term_Date__c){

                        if(con.Term_Date__c != null && oldContact.Term_Date__c == null){ //If Term Date was updated from Empty to Populated
                            //Need to update all existing Work Days after the Term Date to 0 Working Hours
                            contactIdToNewTermDateMap.put(con.Id, con.Term_Date__c);
                            if(earliestTerminationDate == null || con.Term_Date__c < earliestTerminationDate){
                                earliestTerminationDate = con.Term_Date__c;
                            }

                        }else if(con.Term_Date__c == null && oldContact.Term_date__c != null){ //If Term Date was previously populated and was updated to empty
                            /*Need to update all existing Work Days that were after the previous Term Date value from 0 back to 8 depending on the other factors of Working Hours (Stays at 0 If:
                                                                                                                                                                                                1.) Before the End of Employee's Ramp
                                                                                                                                                                                                2.) For a Non-billable employee (i.e. has a Weekly Target of 0 or null)
                                                                                                                                                                                                3.) Is after the Term Date of the Employee
                                                                                                                                                                                                4.) Is on a Saturday or Sunday     **/
                            contactIdToOldTermDateMap.put(oldContact.Id, oldContact.Term_Date__c);
                            if(earliestTerminationDate == null || oldContact.Term_Date__c < earliestTerminationDate){
                                earliestTerminationDate = oldContact.Term_Date__c;
                            }

                        }else if(con.Term_Date__c != null && oldContact.Term_Date__c != null){ //If Term Date was updated from one value to another
                            //Need to check if Days Term Date was moved forwards or backwards
                            if(con.Term_Date__c < oldContact.Term_Date__c){ //Term Date was moved backwards     Ex. New Term Date: 12/10/2022       Previous Term Date: 12/20/2022
                                //Need to update the Work Days that were previously BEFORE THE OLD Term Date but are now AFTER THE NEW Term Date to have 0 Working Hours
                                contactIdToNewTermDateMap.put(oldContact.Id, con.Term_Date__c);
                                if(earliestTerminationDate == null || con.Term_Date__c < earliestTerminationDate){
                                    earliestTerminationDate = con.Term_Date__c;
                                }


                            }else if(con.Term_Date__c > oldContact.Term_Date__c){ //Term Date was moved forwards       Ex. New Term Date: 12/20/2022       Previous Term Date: 12/10/2022
                                //Need to update the Work Days that were previously AFTER THE OLD Term Date but are now BEFORE THE NEW Term Date to have 8 Working Hours (Dependant on the other factors for Working Hours)
                                contactIdToOldTermDateMap.put(oldContact.Id, oldContact.Term_Date__c);
                                if(earliestTerminationDate == null || oldContact.Term_Date__c < earliestTerminationDate){
                                    earliestTerminationDate = oldContact.Term_Date__c;
                                }
                            }
                        }
                    }
                }

                if(forQuarterlyTargetUpdate){
                    updateString = 'Quarterly Target';

                    if(con.Quarterly_Target__c != oldContact.Quarterly_Target__c){
                        if((con.Quarterly_Target__c == null || con.Quarterly_Target__c == 0) && (oldContact.Quarterly_Target__c != null && oldContact.Quarterly_Target__c != 0)){
                            //If Quarterly Target was updated from populated to empty or 0
                            contactIdWithQuarterlyTargetUpdatedToZeroList.add(con.Id);

                        }else if((con.Quarterly_Target__c != null && con.Quarterly_Target__c != 0) && (oldContact.Quarterly_Target__c == null || oldContact.Quarterly_Target__c == 0)){
                            //If Quarterly Target was updated from empty or 0 to populated 
                            contactIdWithQuarterlyTargetUpdatedFromZeroList.add(con.Id);
                        }
                    }
                }
            }
        }

        /******************************************** Update Employees Related Work Day's Working Hours based on Changes to the Employee's Termination Date ********************************************/
        if(contactIdToNewRampEndDateMap.size() > 0 || contactIdToOldRampEndDateMap.size() > 0){
            List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
            relatedWorkDayList = [SELECT Id, Name, WorkDayDate__c, Employee__c, Employee__r.Weekly_Target__c, Employee__r.Ramp_End_Date__c, Employee__r.Term_Date__c, WorkingHours__c
                                    FROM WorkDay__c
                                    WHERE DAY_IN_WEEK(WorkDayDate__c) NOT IN (1, 7) AND Employee__r.Weekly_Target__c > 0 AND (Employee__c IN :contactIdToNewRampEndDateMap.keySet() OR Employee__c IN :contactIdToOldRampEndDateMap.keySet()) AND WorkDayDate__c <= :latestNewRampEndDate
                                    ORDER BY Employee__c, WorkDayDate__c DESC];

            for(WorkDay__c wd : relatedWorkDayList){
                Boolean addToUpdateList = false;

                if(((wd.Employee__r.Ramp_End_Date__c != null && wd.WorkDayDate__c < wd.Employee__r.Ramp_End_Date__c) || (wd.Employee__r.Term_Date__c != null && wd.WorkDayDate__c > wd.Employee__r.Term_Date__c) || (wd.Employee__r.Weekly_Target__c == null || wd.Employee__r.Weekly_Target__c <= 0))){
                    if(wd.WorkingHours__c != 0){
                        wd.WorkingHours__c = 0; //Update Working Days that fall before the new Ramp End Date to 0 Working Hours
                        workDaysToUpdateList.add(wd);
                    }
                }else if(wd.WorkingHours__c != 8){
                    wd.WorkingHours__c = 8;
                    workDaysToUpdateList.add(wd);
                }
            }
        }

        if(contactIdToNewTermDateMap.size() > 0 || contactIdToOldTermDateMap.size() > 0){
            List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
            relatedWorkDayList = [SELECT Id, Name, WorkDayDate__c, Employee__c, Employee__r.Weekly_Target__c, Employee__r.Ramp_End_Date__c, Employee__r.Term_Date__c, WorkingHours__c
                                    FROM WorkDay__c
                                    WHERE DAY_IN_WEEK(WorkDayDate__c) NOT IN (1, 7) AND Employee__r.Weekly_Target__c > 0 AND (Employee__c IN :contactIdToNewTermDateMap.keySet() OR Employee__c IN :contactIdToOldTermDateMap.keySet()) AND WorkDayDate__c >= :earliestTerminationDate
                                    ORDER BY Employee__c, WorkDayDate__c DESC];

            for(WorkDay__c wd : relatedWorkDayList){

                if(((wd.Employee__r.Ramp_End_Date__c != null && wd.WorkDayDate__c < wd.Employee__r.Ramp_End_Date__c) || (wd.Employee__r.Term_Date__c != null && wd.WorkDayDate__c > wd.Employee__r.Term_Date__c) || (wd.Employee__r.Weekly_Target__c == null || wd.Employee__r.Weekly_Target__c <= 0))){
                    if(wd.WorkingHours__c != 0){
                        wd.WorkingHours__c = 0; //Update Working Days that fall before the new Ramp End Date to 0 Working Hours
                        workDaysToUpdateList.add(wd);
                    }
                }else if(wd.WorkingHours__c != 8){
                    wd.WorkingHours__c = 8;
                    workDaysToUpdateList.add(wd);
                }
            }
        }

        if(contactIdWithQuarterlyTargetUpdatedToZeroList.size() > 0 || contactIdWithQuarterlyTargetUpdatedFromZeroList.size() > 0){
            List<WorkDay__c> relatedWorkDayList = new List<WorkDay__c>();
            relatedWorkDayList = [SELECT Id, Name, WorkDayDate__c, Employee__c, Employee__r.Weekly_Target__c, Employee__r.Quarterly_Target__c, Employee__r.Ramp_End_Date__c, Employee__r.Term_Date__c, WorkingHours__c
                                    FROM WorkDay__c
                                    WHERE DAY_IN_WEEK(WorkDayDate__c) NOT IN (1, 7) AND (Employee__c IN :contactIdWithQuarterlyTargetUpdatedToZeroList OR Employee__c IN :contactIdWithQuarterlyTargetUpdatedFromZeroList) AND WorkDayDate__c >= :currentDate
                                    ORDER BY Employee__c, WorkDayDate__c DESC];

            for(WorkDay__c wd : relatedWorkDayList){

                if(((wd.Employee__r.Ramp_End_Date__c != null && wd.WorkDayDate__c < wd.Employee__r.Ramp_End_Date__c) || (wd.Employee__r.Term_Date__c != null && wd.WorkDayDate__c > wd.Employee__r.Term_Date__c) || (wd.Employee__r.Quarterly_Target__c == null || wd.Employee__r.Quarterly_Target__c <= 0))){
                    if(wd.WorkingHours__c != 0){
                        wd.WorkingHours__c = 0; //Update Working Days that fall before the new Ramp End Date to 0 Working Hours
                        workDaysToUpdateList.add(wd);
                    }
                }else if(wd.WorkingHours__c != 8){
                    wd.WorkingHours__c = 8;
                    workDaysToUpdateList.add(wd);
                }
            }

        }

        if(workDaysToUpdateList.size() > 0){
            System.debug('********************************************** Updating ' + workDaysToUpdateList.size() + ' Work Days Working Hours due to ' + updateString + ' Change **********************************************');
            update workDaysToUpdateList;

        }

        

    }

    /*public static Set<Date> getAllDatesInbetweenTwoDates(Date dateOne, Date dateTwo, Boolean includeFirstDay, Boolean includeLastDay){

        Set<Date> datesInbetweenSet = new Set<Date>();

        if(dateOne != null && dateTwo != null){
            Date startDate;
            Date endDate;

            startDate = dateOne < dateTwo ? dateOne : dateTwo; //Set Earlier Date as the Start Date
            endDate = dateOne < dateTwo ? dateTwo : dateOne; //Set Later Date as End Date 
            
            Integer daysToAdd = 0;
            Date iterationDate = startDate;

            while(iterationDate < endDate){
                iterationDate = startDate.addDays(daysToAdd);
                if(iterationDate == startDate && includeFirstDay){ 
                    datesInbetweenSet.add(iterationDate);

                }else if(iterationDate == endDate && includeLastDay){
                    datesInbetweenSet.add(iterationDate);

                }else if(iterationDate != endDate && iterationDate != startDate){
                    datesInbetweenSet.add(iterationDate);
                }

                daysToAdd++;
            }
        }

        return datesInbetweenSet;
    }*/

    public static void createPlaceholderTimesheets(Map<Id, Contact> contactMap){

        List<Replicon_Timesheet__c> existingTimesheetsList = new List<Replicon_Timesheet__c>();
        existingTimesheetsList = [SELECT Id, Name, Start_Date__c, End_Date__c, Employee__c, EmployeeDepartment__c, EmployeeDivision__c, EmployeeTitle__c, Target__c, Is_Lev_Timesheet__c
                                    FROM Replicon_Timesheet__c
                                    WHERE Employee__c IN :contactMap.keyset()];

        Map<Id, List<Replicon_Timesheet__c>> employeeIdoTExistingTimesheetMap = new Map<Id, List<Replicon_Timesheet__c>>();

        for(Replicon_Timesheet__c timesheet : existingTimesheetsList){

            if(employeeIdoTExistingTimesheetMap.containsKey(timesheet.Employee__c)){
                List<Replicon_Timesheet__c> addToTimesheetList = employeeIdoTExistingTimesheetMap.get(timesheet.Employee__c);
                addToTimesheetList.add(timesheet);
                employeeIdoTExistingTimesheetMap.put(timesheet.Employee__c, addToTimesheetList);
            }else{
                List<Replicon_Timesheet__c> timesheetList = new List<Replicon_Timesheet__c>{timesheet};
                employeeIdoTExistingTimesheetMap.put(timesheet.Employee__c, timesheetList);
            }
        }

        List<Replicon_Timesheet__c> newTimesheetInsertList = new List<Replicon_Timesheet__c>();
        Set<Id> newPlaceholderContactIdSet = new Set<Id>();

        for(Contact c : contactMap.values()){
            //Loop through Contacts, first timesheet start date would be the week of their hire date then
            //Depending on Ramp Time the last timesheet will be at the Ramp End Date week

            if(c.RampTime__c != null && c.Hire_Date__c != null && c.RecordTypeId == placeholderContactRT){
                for(Integer i = 0; i < c.RampTime__c; i++){

                    Integer daysToAdd = 7 * i;
                    Date firstTimesheetDate = c.Hire_Date__c.toStartOfWeek();
                    Date timesheetStartDate = firstTimesheetDate.addDays(daysToAdd);
                    Replicon_Timesheet__c newTimesheet = new Replicon_Timesheet__c();
                    newTimesheet.Start_Date__c = timesheetStartDate;

                    Decimal timesheetExpectedHours = 0;
                    if(c.Weekly_Target__c != null && c.RampTime__c != null && c.Ramp_End_Date__c != null){
                        timesheetExpectedHours = RepliconTimesheetTriggerHelper.getTimesheetExpectedHours(c.Weekly_Target__c, c.RampTime__c, c.Ramp_End_Date__c.toStartOfWeek(), timesheetStartDate);
        
                    //If the Ramp fields are not populated then just populate the expected Hours with the weekly Target if populated
                    }else if(c.Weekly_Target__c != null){
                        timesheetExpectedHours = c.Weekly_Target__c;
                    }

                    newTimesheet.Target__c = timesheetExpectedHours;
                    newTimesheet.Employee__c = c.Id;
                    newTimesheet.Name = c.FirstName + ' ' + c.LastName + ': ' + timesheetStartDate.Format();

                    if(c.Department != null){
                        newTimesheet.EmployeeDepartment__c = c.Department;
                    }

                    if(c.Division_New__c != null){
                        newTimesheet.EmployeeDivision__c = c.Division_New__c;
                    }

                    if(c.Title != null){
                        newTimesheet.EmployeeTitle__c = c.Title;
                    }

                    if(c.ReportsToId != null){
                        newTimesheet.EmployeesManager__c = c.ReportsToId;
                    }

                    newPlaceholderContactIdSet.add(c.Id);
                    newTimesheetInsertList.add(newTimesheet);

                }
            }
        }

        List<Replicon_Timesheet__c> timesheetsToDeleteList = new List<Replicon_Timesheet__c>();
        for(Id employeeId : employeeIdoTExistingTimesheetMap.keySet()){
            timesheetsToDeleteList.addAll(employeeIdoTExistingTimesheetMap.get(employeeId));            
        }

        if(timesheetsToDeleteList.size() > 0){
            delete timesheetsToDeleteList;
        }

        if(newTimesheetInsertList.size() > 0){
            insert newTimesheetInsertList;
        }

    }

    public static void deleteInactiveContactCertifications(Map<Id, Contact> contactMap){

        List<Certification__c> certList = new List<Certification__c>();
        certList = [SELECT Id, Name, Employee__c, Status__c, Type__c
                    FROM Certification__c
                    WHERE Employee__c IN :contactMap.keySet()];

        if(certList.size() > 0){
            System.debug('********************************** Deleting ' + certList.size() + ' certifications for inactive Contacts **********************************');
            delete certList;
        }
    }
}