public with sharing class RepliconTimesheetTriggerHelper {

    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';
    private static String placeholderContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Placeholder Employee').getRecordTypeId();

    public static void populateCapacityOnTimesheet(List<Replicon_Timesheet__c> timesheetList, Boolean needsUpdate){


        //Loop through incoming Timesheets to get Employee Ids and Timesheet Start Dates
        List<Id> relatedContactIdList = new List<Id>();
        List<Date> levTimesheetStartDateList = new List<Date>();
        for(Replicon_Timesheet__c timesheet : timesheetList){
            if(timesheet.Employee__c != null){
                relatedContactIdList.add(timesheet.Employee__c);
                levTimesheetStartDateList.add(timesheet.Start_Date__c);
            }
        }

        //Get Account of Timesheet Contacts
        List<Contact> relatedContactList = new List<Contact>();
        if(relatedContactIdList.size() > 0){
            relatedContactList = [SELECT Id, Name, AccountId, Account.Name, Active__c, Term_Date__c
                                    FROM Contact
                                    WHERE Id IN :relatedContactIdList AND Account.Name = 'Levementum LLC'];
        }

        //Loop through Contacts to get map of Contact Id to Contact for use to check Employee Account to see if it is a Lev Timesheet (only rolling up Lev Capacity to Capacity Records)
        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>();
        for(Contact c : relatedContactList){
            contactIdToContactMap.put(c.Id, c);
        }

        //Query Capacity Records with the same Week Start Date as the Timesheets
        List<Capacity__c> capacityList = new List<Capacity__c>();
        capacityList = [SELECT Id, Name, WeekStartDate__c FROM Capacity__c WHERE WeekStartDate__c IN :levTimesheetStartDateList];

        //Loop through Capacity Records and make Map of Start Date to Capacity 
        Map<Date, Capacity__c> weekStartDateToCapacityMap = new Map<Date, Capacity__c>();
        for(Capacity__c cap : capacityList){
            weekStartDateToCapacityMap.put(cap.WeekStartDate__c ,cap);
        }

        //Loop through Timesheets to check if they are Lev Timesheets and assign Capacity Lookups
        List<Replicon_Timesheet__c> timesheetUpdateList = new List<Replicon_Timesheet__c>();
        for(Replicon_Timesheet__c timesheet : timesheetList){
            if(contactIdToContactMap.containsKey(timesheet.Employee__c)){
                Contact timesheetEmployee = contactIdToContactMap.get(timesheet.Employee__c);

                if((timesheet.Start_Date__c < switchToATGTimeDate && timesheetEmployee.Name != atgConsultantContactName) || 
                (timesheet.Start_Date__c >= switchToATGTimeDate && timesheetEmployee.Account.Name == levementumAccountName && timesheetEmployee.Name != atgConsultantContactName)
                && (timesheetEmployee.Active__c = true || (timesheetEmployee.Active__c == false && timesheet.End_Date__c < timesheetEmployee.Term_Date__c))){

                    //Assign Lev Timesheet and/or Capacity Look up if (Timesheet is not marked as Lev Timesheet) OR (Capacity is null AND Timesheet Start Date is in Capacity Map) OR (Capacity is NOT null AND Timesheet Start Date is in Capacity Map AND Capacity != the id that is in the map)
                    if(timesheet.Is_Lev_Timesheet__c != true || (timesheet.Capacity__c == null && weekStartDateToCapacityMap.containsKey(timesheet.Start_Date__c)) || (timesheet.Capacity__c != null && weekStartDateToCapacityMap.containsKey(timesheet.Start_Date__c) && timesheet.Capacity__c != weekStartDateToCapacityMap.get(timesheet.Start_Date__c).Id)){
                        timesheet.Is_Lev_Timesheet__c = true;
                        if(weekStartDateToCapacityMap.containsKey(timesheet.Start_Date__c)){
                            timesheet.Capacity__c = weekStartDateToCapacityMap.get(timesheet.Start_Date__c).Id;
                        }
                        //Add Timesheet Update List
                        timesheetUpdateList.add(timesheet);
                    }
                }else{
                    if(timesheet.Is_Lev_Timesheet__c != false || timesheet.Capacity__c != null){  
                        timesheet.Is_Lev_Timesheet__c = false;
                        timesheet.Capacity__c = null;
                        timesheetUpdateList.add(timesheet);
                    }
                }
            }

        }

        //Update if the needsUpdate Boolean is true
        if(needsUpdate && timesheetUpdateList.size() > 0){
            System.debug('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Updating ' + timesheetUpdateList.size() + ' timesheets with Capacity Lookup(s) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
            update timesheetUpdateList;
        }

    }

    public static void rollupCapacityTimeoff(Map<Id, Decimal> capacityIdToTotalTimeOffMap){

        List<Capacity__c> capacityRecordsToUpdateList = new List<Capacity__c>();

        AggregateResult[] timesheetTimeOffRollup = [SELECT SUM(Total_Time_Off_Hours__c), Capacity__c
                                                    FROM Replicon_Timesheet__c
                                                    WHERE Capacity__c IN :capacityIdToTotalTimeOffMap.keySet() AND Total_Time_Off_Hours__c != 0 AND Total_Time_Off_Hours__c != null AND Employee__r.Quarterly_Target__c != null AND Employee__r.Quarterly_Target__c != 0
                                                    GROUP BY Capacity__c];

        System.debug('Timesheet Rollup: ' + timesheetTimeOffRollup);

        for(AggregateResult ar : timesheetTimeOffRollup){
            Id capacityId = (Id)ar.get('Capacity__c');
            Decimal rolledUpTimeOff = (Decimal)ar.get('expr0');

            capacityIdToTotalTimeOffMap.put(capacityId, rolledUpTimeOff);    
        }

        System.debug('capacityIdToTotalTimeOffMap: ' + capacityIdToTotalTimeOffMap);
        
        List<Capacity__c> relatedCapacityRecords = new List<Capacity__c>();
        relatedCapacityRecords = [SELECT Id, Name, TotalTimeOffHours__c, TotalExpectedHours__c FROM Capacity__c WHERE Id IN :capacityIdToTotalTimeOffMap.keySet()];

        System.debug('relatedCapacityRecords: ' + relatedCapacityRecords);
        for(Capacity__c cap : relatedCapacityRecords){
            if(capacityIdToTotalTimeOffMap.containsKey(cap.Id)){
                if(cap.TotalTimeOffHours__c != capacityIdToTotalTimeOffMap.get(cap.Id)){
                    cap.TotalTimeOffHours__c = capacityIdToTotalTimeOffMap.get(cap.Id);
                    capacityRecordsToUpdateList.add(cap);
                }
            }
        }

        if(capacityRecordsToUpdateList.size() > 0){
            System.debug('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Updating ' + capacityRecordsToUpdateList.size() + ' Capacity with Total Time Off Rollups ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            update capacityRecordsToUpdateList;
        }

    }

    public static void rollupCapacityExpectedHours(Map<Id, Decimal> capacityIdToTotalExpectedHoursMap){
        List<Capacity__c> capacityRecordsToUpdateList = new List<Capacity__c>();

        AggregateResult[] timesheetExpectedHoursRollup = [SELECT SUM(Target__c), Capacity__c
                                                            FROM Replicon_Timesheet__c
                                                            WHERE Capacity__c IN :capacityIdToTotalExpectedHoursMap.keySet() AND Target__c != 0 AND Target__c != null
                                                            GROUP BY Capacity__c];

        for(AggregateResult ar : timesheetExpectedHoursRollup){
            Id capacityId = (Id)ar.get('Capacity__c');
            Decimal rolledUpExpectedHours = (Decimal)ar.get('expr0');

            capacityIdToTotalExpectedHoursMap.put(capacityId, rolledUpExpectedHours);    
        }
        
        List<Capacity__c> relatedCapacityRecords = new List<Capacity__c>();
        relatedCapacityRecords = [SELECT Id, Name, TotalTimeOffHours__c, TotalExpectedHours__c FROM Capacity__c WHERE Id IN :capacityIdToTotalExpectedHoursMap.keySet()];

        for(Capacity__c cap : relatedCapacityRecords){
            if(capacityIdToTotalExpectedHoursMap.containsKey(cap.Id)){
                if(cap.TotalExpectedHours__c != capacityIdToTotalExpectedHoursMap.get(cap.Id)){
                    cap.TotalExpectedHours__c = capacityIdToTotalExpectedHoursMap.get(cap.Id);
                    capacityRecordsToUpdateList.add(cap);
                }
            }
        }

        if(capacityRecordsToUpdateList.size() > 0){
            System.debug('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++ Updating ' + capacityRecordsToUpdateList.size() + ' Capacity with Total Expected Hours Rollups ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            update capacityRecordsToUpdateList;
        }
    }
    


    public static Decimal getTimesheetExpectedHours(Decimal weeklyTarget, Decimal rampTime, Date rampEndDate, Date timesheetStartDate){

        //Get the expected hours and factor in Ramp Time
        //Based on the RampTime there is a different % of their Weekly Target that they are expected to bill based on how far away they are from the ramp end date

        /**
         * Functionality: 
         * Get how many weeks the timesheet is away from the Ramp End Date
         * Based on their Ramp Time multiply the weekly target by a percentage
         */

        System.debug('********************************************* Get Timesheet Expected Hours *********************************************');
        System.debug('Weekly Target: ' + weeklyTarget);
        System.debug('Ramp Time: ' + rampTime);
        System.debug('Ramp End Date: ' + rampEndDate);
        System.debug('Timesheet Start Date: ' + timesheetStartDate);

        Decimal expectedHours;

        //Only factor in Ramp time if the Timesheet Start Date is prior to the Ramp End Date
        if(timesheetStartDate < rampEndDate){
            Date rampEndWeekStart = rampEndDate.toStartOfWeek();
            Decimal weeksBetweenTimesheetDateAndRampBeforeRound = ((timesheetStartDate.daysBetween(rampEndWeekStart)) / 7);
            Decimal weeksBetweenTimesheetDateAndRamp = weeksBetweenTimesheetDateAndRampBeforeRound.round(System.RoundingMode.HALF_EVEN);

            System.debug('Ramp End Week Start Date: ' + rampEndWeekStart);
            System.debug('Weeks Between Timesheet Start And Ramp Date Before Rounding: ' + weeksBetweenTimesheetDateAndRampBeforeRound);
            System.debug('Weeks Between Timesheet Start And Ramp Date After Rounding: ' + weeksBetweenTimesheetDateAndRamp);

            if(rampTime <= 2){

                if(weeksBetweenTimesheetDateAndRamp >= 2){ //Week 0
                    expectedHours = weeklyTarget * 0.67;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 1
                    expectedHours = weeklyTarget * 0.90;
                }else{
                    expectedHours = weeklyTarget; //Week 2
                }

            }else if(rampTime <= 4){

                //Switches on weeks until ramp end date
                if(weeksBetweenTimesheetDateAndRamp >= 3){ //3 Weeks out would be Week 1 of the 4 Week Ramp Schedule
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 2
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 3
                    expectedHours = weeklyTarget * 0.67;
                }else{
                    expectedHours = weeklyTarget; //Week 4
                }
                

            }else if(rampTime <= 5){

                if(weeksBetweenTimesheetDateAndRamp >= 3){ //Week 1, 2
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 3
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 4
                    expectedHours = weeklyTarget * 0.67;
                }else{ //Week 5
                    expectedHours = weeklyTarget; 
                }

            }else if(rampTime <= 6){

                if(weeksBetweenTimesheetDateAndRamp >= 3){ //Week 1, 2, 3
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 4
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 5
                    expectedHours = weeklyTarget * 0.67;
                }else{ //Week 6
                    expectedHours = weeklyTarget;
                }

            }else if(rampTime <= 7){

                if(weeksBetweenTimesheetDateAndRamp >= 3){ //Week 1, 2, 3, 4
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 5
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 6
                    expectedHours = weeklyTarget * 0.67;
                }else{ //Week 7
                    expectedHours = weeklyTarget;
                }

            }else if(rampTime <= 8){

                if(weeksBetweenTimesheetDateAndRamp >= 3){ //Week 1, 2, 3, 4, 5
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 6
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 7
                    expectedHours = weeklyTarget * 0.67;
                }else{ //Week 8
                    expectedHours = weeklyTarget;
                }

            }else if(rampTime <= 9){

                if(weeksBetweenTimesheetDateAndRamp >= 3){ //Week 1, 2, 3, 4, 5, 6
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 7
                    expectedHours = weeklyTarget * 0.25;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 8
                    expectedHours = weeklyTarget * 0.67;
                }else{ //Week 9
                    expectedHours = weeklyTarget;
                }

            }else if(rampTime <= 10){

                if(weeksBetweenTimesheetDateAndRamp >= 5){ //Week 1, 2, 3, 4, 5
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 4){ //Week 6
                    expectedHours = weeklyTarget * 0.42;
                }else if(weeksBetweenTimesheetDateAndRamp == 3){ //Week 7
                    expectedHours = weeklyTarget * 0.56;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 8
                    expectedHours = weeklyTarget * 0.70;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 9
                    expectedHours = weeklyTarget * 0.84;
                }else{ //Week 10
                    expectedHours = weeklyTarget;
                }

            }else if(rampTime <= 14){

                if(weeksBetweenTimesheetDateAndRamp >= 8){ //Week 1, 2, 3, 4, 5, 6
                    expectedHours = weeklyTarget * 0;
                }else if(weeksBetweenTimesheetDateAndRamp == 7){ //Week 7
                    expectedHours = weeklyTarget * 0.14;
                }else if(weeksBetweenTimesheetDateAndRamp == 6){ //Week 8
                    expectedHours = weeklyTarget * 0.28;
                }else if(weeksBetweenTimesheetDateAndRamp == 5){ //Week 9
                    expectedHours = weeklyTarget * 0.42;
                }else if(weeksBetweenTimesheetDateAndRamp == 4){ //Week 10
                    expectedHours = weeklyTarget * 0.56;
                }else if(weeksBetweenTimesheetDateAndRamp == 3){ //Week 11
                    expectedHours = weeklyTarget * 0.70;
                }else if(weeksBetweenTimesheetDateAndRamp == 2){ //Week 12
                    expectedHours = weeklyTarget * 0.84;
                }else if(weeksBetweenTimesheetDateAndRamp == 1){ //Week 13
                    expectedHours = weeklyTarget * 0.98;
                }else{ //Week 14
                    expectedHours = weeklyTarget;
                }

            }else{

                System.debug('Expected Hours After 14 Ramp Time');
                expectedHours = weeklyTarget;
            }
        }else{
            System.debug('Last Else');
            expectedHours = weeklyTarget;
        }


        return expectedHours.setScale(2, System.RoundingMode.HALF_EVEN);
    }

    public static void createWorkDaysForTimesheet(List<Replicon_Timesheet__c> timesheetList){

        List<Id> employeeIdList = new List<Id>();
        List<Date> entryDateList = new List<Date>();
        List<Replicon_Timesheet__c> timesheetsForWorkDaysList = new List<Replicon_Timesheet__c>();

        /************** Get Timesheet Details (Contact Id and Entry Dates) **************/
        for(Replicon_Timesheet__c timesheet : timesheetList){
            if(timesheet.Employee__c != null && timesheet.Start_Date__c != null && timesheet.End_Date__c != null){
                timesheetsForWorkDaysList.add(timesheet);
                employeeIdList.add(timesheet.Employee__c);

                Integer addDays = 0;
                Date iterationDate = timesheet.Start_Date__c;

                while(iterationDate < timesheet.End_Date__c){
                    iterationDate = (timesheet.Start_Date__c).addDays(addDays);
                    entryDateList.add(iterationDate);
                    addDays++;
                }
            }
        }

        /************** Get Related Contact Details **************/
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT Id, Name, Division_New__c, Weekly_Target__c, Department, ReportsToId, ReportsTo.Name, Title, Term_Date__c, Ramp_End_Date__c, RecordTypeId, RecordType.Name
                        FROM Contact
                        WHERE Id IN :employeeIdList];

        Map<Id, Contact> contactIdToRecordMap = new Map<Id, Contact>();
        for(Contact c : contactList){
            contactIdToRecordMap.put(c.Id, c);
        }

        /************** Get Existing Work Days **************/
        List<WorkDay__c> existingWorkDayList = new List<WorkDay__c>();
        existingWorkDayList = [SELECT Id, Name, Employee__c, WorkDayDate__c
                                FROM WorkDay__c
                                WHERE Employee__c IN :employeeIdList AND WorkDayDate__c IN :entryDateList];

        Map<String, WorkDay__c> existingWorkDayUniqueIdToRecordMap = new Map<String, WorkDay__c>();
        for(WorkDay__c wd : existingWorkDayList){

            String uniqueId = String.valueOf(wd.Employee__c) + '|' + String.valueOf(wd.WorkDayDate__c);
            existingWorkDayUniqueIdToRecordMap.put(uniqueId, wd);
        }

        /************** Create New Work Days **************/
        List<WorkDay__c> newWorkDayToInsertList = new List<WorkDay__c>();
        for(Replicon_Timesheet__c timesheet : timesheetsForWorkDaysList){

            Integer addDays = 0;
            Date iterationDate = timesheet.Start_Date__c;

            while(iterationDate < timesheet.End_Date__c){
                iterationDate = (timesheet.Start_Date__c).addDays(addDays);
                addDays++;

                String uniqueId = String.valueOf(timesheet.Employee__c) + '|' + String.valueOf(iterationDate);
                //Only create Work Days if they don't already exist
                if(!existingWorkDayUniqueIdToRecordMap.containsKey(uniqueId) && contactIdToRecordMap.containsKey(timesheet.Employee__c)){

                    Contact relatedContact = contactIdToRecordMap.get(timesheet.Employee__c);
                    if(relatedContact.RecordTypeId != placeholderContactRT){
                        WorkDay__c newWorkDay = new WorkDay__c();
                        newWorkDay.Employee__c = timesheet.Employee__c;
                        newWorkDay.EmployeesManager__c = relatedContact.ReportsToId;
                        newWorkDay.EmployeeDivision__c = relatedContact.Division_New__c;
                        newWorkDay.RepliconTimesheet__c = timesheet.Id;
                        newWorkDay.WorkDayDate__c = iterationDate;
                        newWorkDay.Name = (relatedContact.Name + ' - ' + String.valueOf(DateTime.newInstance(iterationDate.year(), iterationDate.month(), iterationDate.day()).format('MM/dd/YYYY'))).left(80);

                        Datetime dt = DateTime.newInstance(iterationDate, Time.newInstance(0, 0, 0, 0));
                        String dayOfWeek = dt.format('EEEE'); //Format Date to see what day of the week it is  (i.e. Friday, Saturday)

                        if((relatedContact.Ramp_End_Date__c != null && iterationDate < relatedContact.Ramp_End_Date__c) || (relatedContact.Weekly_Target__c <= 0 || relatedContact.Weekly_Target__c == null) || 
                            (relatedContact.Term_Date__c != null && iterationDate > relatedContact.Term_Date__c)){
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

                        newWorkDayToInsertList.add(newWorkDay);
                    }
                }
            }
        }

        if(newWorkDayToInsertList.size() > 0){
            System.debug('********************************* Inserting ' + newWorkDayToInsertList.size() + ' Work Days from Timesheet Creation *************************************');
            insert newWorkDayToInsertList;
        }

    }

    public static void createHolidayTimeForTimesheet(List<Replicon_Timesheet__c> timesheetList){

        Set<Id> contactIdSet = new Set<Id>();

        List<Replicon_Time_Entry__c> holidayEntryInsertList = new List<Replicon_Time_Entry__c>();

        for(Replicon_Timesheet__c timesheet : timesheetList){      
            if(!TimeEntryService.contactIdToRecordPublicMap.containsKey(timesheet.Employee__c)){
                contactIdSet.add(timesheet.Employee__c);
            }   
        }

        if(contactIdSet.size() > 0){
            List<Contact> relatedContacts = new List<Contact>();
            //Query for Contacts that have matching Cognizant Contact Ids of the inserted Time Entries
            relatedContacts = [SELECT Id, Name, Title, Department, Cognizant_Employee_ID__c, Division_New__c, ReportsToId, ReportsTo.Name, Weekly_Target__c, RampTime__c, Ramp_End_Date__c, Term_Date__c, Active__c, Account.Name, AccountId
                                FROM Contact 
                                WHERE Id IN :contactIdSet];

            for(Contact con : relatedContacts){
                TimeEntryService.contactIdToRecordPublicMap.put(con.Id, con);
            }
        }

        List<Holiday> holidayList = new List<Holiday>();
        holidayList = [SELECT Id, Name, ActivityDate
                        FROM Holiday];

        Set<Date> holidayDateSet = new Set<Date>();
        for(Holiday h : holidayList){
            holidayDateSet.add(h.ActivityDate);
        }

        for(Replicon_Timesheet__c timesheet : timesheetList){
            if(timesheet.Start_Date__c != null){
                for(Integer i = 0; i < 7; i++){
                    Date iterationDate = timesheet.Start_Date__c.toStartOfWeek().addDays(i);
                    if(holidayDateSet.contains(iterationDate)){
                        holidayEntryInsertList.add(createHolidayTime(timesheet, iterationDate));
                    }
                }
            }
        }

        if(holidayEntryInsertList.size() > 0){
            System.debug('************************* Inserting ' + holidayEntryInsertList.size() + ' Holiday Time Off Entries ****************************');
            insert holidayEntryInsertList;
        }
    }

    public static Replicon_Time_Entry__c createHolidayTime(Replicon_Timesheet__c timesheet, Date holidayDate){
        Replicon_Time_Entry__c holidayEntry = new Replicon_Time_Entry__c();
        holidayEntry.Account__c = '001d000000JGuQaAAL'; //Levementum LLC
        holidayEntry.Opportunity__c = '0066T0000173VyXQAU'; // Lev - PTO oppty
        holidayEntry.Project__c = 'a1q6T000003v4mFQAQ'; // Lev - PTO project
        holidayEntry.Employee__c = timesheet.Employee__c;
        holidayEntry.EntryDate__c = holidayDate;
        holidayEntry.TotalHrs__c = 8;
        holidayEntry.Time_Off__c = true;
        holidayEntry.Time_Off_Description__c = 'Holiday';
        holidayEntry.Replicon_Timesheet__c = timesheet.Id;
        holidayEntry.Name = TimeEntryService.contactIdToRecordPublicMap.get(timesheet.Employee__c).Name + ' - ' + String.valueOf(holidayDate.format()) + ' - Lev - PTO';
        holidayEntry.Cognizant_Employee_Id__c = TimeEntryService.contactIdToRecordPublicMap.get(timesheet.Employee__c).Cognizant_Employee_Id__c;

        return holidayEntry;
    }
}