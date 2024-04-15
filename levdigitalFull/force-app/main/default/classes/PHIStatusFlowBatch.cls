/**
 * Created By Sam Tucker 2/25/2022
 * Batch Apex class that runs the Project PHI Status/History Flow in Batches
 * 
 * Run the PHI Batch Manually
PHIStatusFlowBatch newBatchRun = new PHIStatusFlowBatch();
Database.executeBatch(newBatchRun, 50);
 * 
 * 
 */

 /**
  * Edits List:
  * 4/25/22: Filter out projects with ESA End Date of NULL and Projects where Oppty Products are all Offshore
  */
public with sharing class PHIStatusFlowBatch implements Database.Batchable<sObject>{

    List<Project__c> inputList;

    public PHIStatusFlowBatch() {
        //TODO: Additions as of 4/25/22 ST
        //Only run automation for Projects where ESA_End_Date__c != null AND Where Lev_Opportunity_COs_Hours__c > 0
        inputList = [SELECT Id, Name, Project_Status__c, SR_Overall_Health_Value__c, Project_Terms__c, Estimate_to_Complete__c, Non_Bill_Hours_Perc__c, SR_Budget_Value__c, Run_Rate_Difference__c, X20_Greater_Remaining_Hours__c, SR_Scope_Value__c,
                            Planned_Go_Live_Date__c, Planned_Close_Date__c, Remaining_Forecasted_Hrs__c, X10_Greater_Remaining_Hours__c, X30_Days_before_ESA_End_Date__c, X60_Days_Before_ESA_EndDate__c, X25_Greater_Remaining_Hours__c, X25_Less_Remaining_Hours__c, 
                            SR_Schedule_Value__c, Previous_PHI_Value__c, Active_History_Record__c, X2_Weeks_from_Initial_Staffing__c, PM_Email__c, PM_s_Manager_Email_Address__c, AD_ID__c, Project_Manager_Email__c, PM_Managers_ID__c, PM_ID__c, Forecasted_Expected_Run_Rate__c,
                            Forecasted_Run_Rate__c, Historical_Run_Rate__c, X4_Weeks_from_ESA_End_Date__c, Remaining_Hours__c, Opportunity__c, Budget_PHI_Reason__c, Schedule_PHI_Reason__c, Duration_Exceed_Hours_Remaining__c, Hours_Exceed_Duration__c, Last_PHI_Run_Date__c,
                            Duration_Remaining__c, TotalBudgetRemaining__c, TotalRemainingHours__c, TotalPercentHoursRemaining__c 
                    FROM Project__c
                    WHERE Project_Status__c IN ('Not Started', 'Active') AND X2_Weeks_from_Initial_Staffing__c <= TODAY AND Planned_Close_Date__c != null AND Lev_Opportunity_COs_Hours__c > 0];   
    }

    //public (Database.QueryLocator | Iterable<sObject>) start(Database.BatchableContext bc) {
    public List<Project__c> start(Database.BatchableContext bc) {
        System.debug('PHIStatusFlowBatch START HERE');
        System.debug('inputList Size: ' + inputList.size());
        System.debug('inputList: ' + inputList);
        return inputList;
    }

    public void execute(Database.BatchableContext BC, List<Project__c> phiProjectList){
        System.debug('PHI Status Flow Execute');
        //Create custom class of phiProjectFlowObject from the project list passed in the batch to pass into flow
        Set<Id> projSet = new Set<Id>();
        for(Project__c proj : phiProjectList){ //Get Set of Project Ids to search for Related Open PHI History Records
            projSet.add(proj.Id);
        }

        /*** Create and Set Map for use to check if Project has an unresolved PHI History Record ***/
        List<PHI_History__c> relatedActivePhiHistoryRecs = new List<PHI_History__c>(); //Query for Related PHI History Records
        relatedActivePhiHistoryRecs = [SELECT Id, Name, Current_PHI__c, Date_Moved_to_Red__c, Date_Moved_to_Yellow__c, Date_Resolved__c, Initial_Escalation_Color__c, Project_ID__c, Project_Name__c, Resolved__c,
                                                Budget_PHI_Reason__c, Schedule_PHI_Reason__c
                                        FROM PHI_History__c
                                        WHERE Project_Name__c IN :projSet AND Resolved__c = false];

        Map<Id, PHI_History__c> projIdToPhiMap = new Map<Id, PHI_History__c>();
        for(PHI_History__c phi : relatedActivePhiHistoryRecs){ //Create Map of Project Id to Related PHI History Record
            projIdToPhiMap.put(phi.Project_Name__c, phi);
        }

        /*** Create and Set Map for use to check if Project has a Time Entry in the last 14 days ***/
        List<Replicon_Time_Entry__c> last14DaysTimeEntriesList = new List<Replicon_Time_Entry__c>(); //Query for Time Entries in the last 14 Days
        last14DaysTimeEntriesList = [SELECT Id, Name, Employee__c, Project__c, EntryDate__c, CreatedDate
                                        FROM Replicon_Time_Entry__c
                                        WHERE Project__c IN :projSet AND Deleted_in_Replicon__c = false AND EntryDate__c = LAST_N_DAYS:14
                                        ORDER BY EntryDate__c ASC];

        Map<Id, Date> projIdToMostRecentEntryDateMap = new Map<Id, Date>();
        for(Replicon_Time_Entry__c entry : last14DaysTimeEntriesList){ //Create Map of Project Id to Most Recent Time Entry Date
            projIdToMostRecentEntryDateMap.put(entry.Project__c, entry.EntryDate__c);
        }

        /*** Loop Through Projects in Batch to set the Apex Variables in the Wrapper ***/
        List<phiProjectFlowObjWrapper> flowObjWrapperList = new List<phiProjectFlowObjWrapper>();
        for(Project__c proj : phiProjectList){ //Loop through batched projects to create the Flow Obj Wrapper List that is passed to the Flow
            phiProjectFlowObjWrapper newWrapperObj = new phiProjectFlowObjWrapper();
            newWrapperObj.phiProject = proj;

            /**Set if Project has an unresolved PHI History Record **/
            if(projIdToPhiMap.containsKey(proj.Id)){
                newWrapperObj.phiHistoryRecord = projIdToPhiMap.get(proj.Id);
                newWrapperObj.hasUnResolvedPhiHistoryRec = true;
            }else{
                newWrapperObj.hasUnResolvedPhiHistoryRec = false;
            }

            /**Set if Project has a Time Entry in the last 14 Days **/
            if(projIdToMostRecentEntryDateMap.containsKey(proj.Id)){
                newWrapperObj.hasTimeEntryInLast14Days = true;
            }else{
                newWrapperObj.hasTimeEntryInLast14Days = false;
            }

            flowObjWrapperList.add(newWrapperObj);
        }
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('PhiProjectFlowObjCollection', flowObjWrapperList);
        if(flowObjWrapperList.size() > 0){
            //Call Flow
            if(!Test.isRunningTest()){
                Flow.Interview.Project_PHI_Status_History_Flow phiFlow = new Flow.Interview.Project_PHI_Status_History_Flow(flowInputs);
                phiFlow.start();
            }
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('PHIStatusFlowBatch FINISH');

    }  


}