public with sharing class WorkDayTriggerHelper {
    
    
    public static void setWorkDayWorkingHours(List<WorkDay__c> workDayList, Boolean needsUpdate){

        List<WorkDay__c> workDayUpdateList = new List<WorkDay__c>();

        Set<Id> employeeIdSet = new Set<Id>();
        for(WorkDay__c wd : workDayList){
            if(wd.Employee__c != null){
                employeeIdSet.add(wd.Employee__c);
            }
        }

        if(employeeIdSet.size() > 0){
            Map<Id, Contact> employeeMap = new Map<Id, Contact>([SELECT Id, Name, Ramp_End_Date__c, Term_Date__c, Weekly_Target__c, Active__c FROM Contact WHERE Id IN :employeeIdSet]);


            for(WorkDay__c wd : workDayList){

                if(employeeMap.containsKey(wd.Employee__c)){
                    Contact relatedEmployee = employeeMap.get(wd.Employee__c);

                    Datetime dt = DateTime.newInstance(wd.WorkDayDate__c, Time.newInstance(0, 0, 0, 0));
                    String dayOfWeek = dt.format('EEEE'); //Format Date to see what day of the week it is  (i.e. Friday, Saturday)

                    if((relatedEmployee.Ramp_End_Date__c != null && wd.WorkDayDate__c < relatedEmployee.Ramp_End_Date__c) 
                        || (relatedEmployee.Weekly_Target__c <= 0 
                        || relatedEmployee.Weekly_Target__c == null) 
                        || (relatedEmployee.Term_Date__c != null && wd.WorkDayDate__c > relatedEmployee.Term_Date__c) 
                        || relatedEmployee.Active__c == false
                        || (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday')
                        || wd.TotalLOAHours__c > 0){

                            if(wd.WorkingHours__c != 0){
                                wd.WorkingHours__c = 0;
                                workDayUpdateList.add(wd);                            
                            }
                        
                    }else{
                        /** Working Hours is 8 if Working Day is NOT:
                        *     1.) Before the End of Employee's Ramp
                        *     2.) For a Non-billable employee (i.e. has a Weekly Target of 0 or null)
                        *     3.) Is after the Term Date of the Employee
                        *     4.) Is on a Saturday or Sunday
                        *     5.) Have any LOA Hours for the Day
                        **/

                            if(wd.WorkingHours__c != 8){
                                wd.WorkingHours__c = 8;
                                workDayUpdateList.add(wd);                            
                            }
                    }
                }
            }
        }

        if(needsUpdate && workDayUpdateList.size() > 0){
            System.debug('************************** Updating Working Hours on ' + workDayUpdateList.size() + ' Work Day Records **************************');
            update workDayUpdateList;
        }

    }
}