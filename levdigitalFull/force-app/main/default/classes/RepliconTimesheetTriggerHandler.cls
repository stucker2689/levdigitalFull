public with sharing class RepliconTimesheetTriggerHandler {

    private static Date switchToATGTimeDate = Date.newInstance(2022, 6, 1);
    private static String levementumAccountName = 'Levementum LLC';
    private static String atgConsultantContactName = 'ATG Consultant';

    public static void onBeforeInsert(List<Replicon_Timesheet__c> newList){
        List<Replicon_Timesheet__c> timesheetToGiveCapacityList = new List<Replicon_Timesheet__c>();

        for(Replicon_Timesheet__c timesheet : newList){
            if(timesheet.Start_Date__c != null){
                if(timesheet.Name != null && !timesheet.Name.contains('ATG Consultant') ){
                    timesheetToGiveCapacityList.add(timesheet);
                }
                
            }
        }

        if(timesheetToGiveCapacityList.size() > 0){
            RepliconTimesheetTriggerHelper.populateCapacityOnTimesheet(timesheetToGiveCapacityList, false);
        }
    }

    public static void onAfterInsert(List<Replicon_Timesheet__c> newList){

        Map<Id, Decimal> capacityIdToTotalExpectedHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToTotalTimeOffMap = new Map<Id, Decimal>();
        List<Replicon_Timesheet__c> timesheetsForWorkDayCreationList = new List<Replicon_Timesheet__c>();
        List<Replicon_Timesheet__c> timesheetsForHollidayTimeOffCreationList = new List<Replicon_Timesheet__c>();


        for(Replicon_Timesheet__c timesheet : newList){

            if((timesheet.Target__c != null || timesheet.Target__c != 0) && timesheet.Capacity__c != null){
                capacityIdToTotalExpectedHoursMap.put(timesheet.Capacity__c, 0);
            }

            if(timesheet.Capacity__c != null && timesheet.Total_Time_Off_Hours__c != null){
                capacityIdToTotalTimeOffMap.put(timesheet.Capacity__c, 0);
            }

            if(timesheet.Employee__c != null && timesheet.Start_Date__c != null){
                timesheetsForWorkDayCreationList.add(timesheet);
            }

            if(timesheet.Start_Date__c != null && timesheet.Employee__c != null){
                timesheetsForHollidayTimeOffCreationList.add(timesheet);
            }
            
        }


        //Rollup Total Weekly Target tot Capacity Total Expected Hours
        if(capacityIdToTotalExpectedHoursMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityExpectedHours(capacityIdToTotalExpectedHoursMap);
        }

        //Rollup Total Time Off Hours to Capacity Total Time Off Hours
        if(capacityIdToTotalTimeOffMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityTimeoff(capacityIdToTotalTimeOffMap);
        }

        //Create Work Day from Timesheet
        if(timesheetsForWorkDayCreationList.size() > 0){
            RepliconTimesheetTriggerHelper.createWorkDaysForTimesheet(timesheetsForWorkDayCreationList);
        }

        if(timesheetsForHollidayTimeOffCreationList.size() > 0){
            RepliconTimesheetTriggerHelper.createHolidayTimeForTimesheet(timesheetsForHollidayTimeOffCreationList);
        }

    }

    public static void onBeforeUpdate(List<Replicon_Timesheet__c> newList, Map<Id, Replicon_Timesheet__c> oldMap){

        List<Replicon_Timesheet__c> timesheetToGiveCapacityList = new List<Replicon_Timesheet__c>();

        for(Replicon_Timesheet__c timesheet : newList){

            Replicon_Timesheet__c oldTimesheet = oldMap.get(timesheet.Id);

            if(timesheet.Start_Date__c != oldTimesheet.Start_Date__c){
                if(timesheet.Start_Date__c != null){
                    if(timesheet.Name != null && !timesheet.Name.contains('ATG Consultant') ){
                        timesheetToGiveCapacityList.add(timesheet);
                    }
                    
                }

            }
        }

        if(timesheetToGiveCapacityList.size() > 0){
            RepliconTimesheetTriggerHelper.populateCapacityOnTimesheet(timesheetToGiveCapacityList, false);
        }

    }

    public static void onAfterUpdate(List<Replicon_Timesheet__c> newList, Map<Id, Replicon_Timesheet__c> oldMap){

        Map<Id, Decimal> capacityIdToTotalTimeOffMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToTotalExpectedHoursMap = new Map<Id, Decimal>();

        for(Replicon_Timesheet__c timesheet : newList){

            Replicon_Timesheet__c oldTimesheet = oldMap.get(timesheet.Id);
            
            if(timesheet.Total_Time_Off_Hours__c != oldTimesheet.total_Time_Off_Hours__c && timesheet.Capacity__c != null){
                capacityIdToTotalTimeOffMap.put(timesheet.Capacity__c, 0);
            }

            if(timesheet.Target__c != oldTimesheet.Target__c && timesheet.Capacity__c != null){
                capacityIdToTotalExpectedHoursMap.put(timesheet.Capacity__c, 0);
            }

            //If Capacity is changed rollup Time Off and Expected Hours (if Old Timesheet had a Capacity Rollup the old one)
            if(timesheet.Capacity__c != oldTimesheet.Capacity__c){

                //If New Timesheet was changed
                if(timesheet.Capacity__c != null){
                    if(timesheet.Target__c != 0 && timesheet.Target__c != null){ //Only rollup Expected Hours on Capacity if the Timesheet has Expected Hours Populated
                        capacityIdToTotalExpectedHoursMap.put(timesheet.Capacity__c, 0);
                    }

                    if(timesheet.Target__c != 0){
                        capacityIdToTotalTimeOffMap.put(timesheet.Capacity__c, 0);
                    }
                }

                //If Old Timesheet had a Capacity that it was changed from
                if(oldTimesheet.Capacity__c != null){
                    if(oldTimesheet.Target__c != 0 && oldTimesheet.Target__c != null){ //Only rollup Timeoff Hours on Capacity if the Timesheet has Expected Hours and is Department Employee
                        capacityIdToTotalExpectedHoursMap.put(oldTimesheet.Capacity__c, 0);
                    }

                    if(oldTimesheet.Target__c != 0){
                        capacityIdToTotalTimeOffMap.put(oldTimesheet.Capacity__c, 0);
                    }
                }
            }

            //If Employee Division is changed to or from Department then rollup the Capacity Timeoff to either include or exclude the Time off hours so that it only includes Consulting Employees
            if((timesheet.EmployeeDepartment__c == 'Consulting' || oldTimesheet.EmployeeDepartment__c == 'Consulting') && timesheet.EmployeeDepartment__c != oldTimesheet.EmployeeDepartment__c ){
                capacityIdToTotalTimeOffMap.put(timesheet.Capacity__c, 0);
            }
            
        }

        //Rollup Total Time Off Hours to Capacity Total Time Off Hours
        if(capacityIdToTotalTimeOffMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityTimeoff(capacityIdToTotalTimeOffMap);
        }

        //Rollup Total Weekly Target tot Capacity Total Expected Hours
        if(capacityIdToTotalExpectedHoursMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityExpectedHours(capacityIdToTotalExpectedHoursMap);
        }
    }

    public static void onAfterDelete(List<Replicon_Timesheet__c> newList){

        Map<Id, Decimal> capacityIdToTotalTimeOffMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToTotalExpectedHoursMap = new Map<Id, Decimal>();
        
        for(Replicon_Timesheet__c timesheet : newList){
            if(timesheet.Capacity__c != null && timesheet.Total_Time_Off_Hours__c != 0){
                capacityIdToTotalTimeOffMap.put(timesheet.Capacity__c, 0);
            }

            if(timesheet.Capacity__c != null && timesheet.Target__c != 0){
                capacityIdToTotalExpectedHoursMap.put(timesheet.Capacity__c, 0);
            }
        }

        //Rollup Total Time Off Hours to Capacity Total Time Off Hours
        if(capacityIdToTotalTimeOffMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityTimeoff(capacityIdToTotalTimeOffMap);
        }

        //Rollup Total Weekly Target tot Capacity Total Expected Hours
        if(capacityIdToTotalExpectedHoursMap.size() > 0){
            RepliconTimesheetTriggerHelper.rollupCapacityExpectedHours(capacityIdToTotalExpectedHoursMap);
        }

    }
}