/**
 * Created 7/7/2022 ST
 * 
 * Purpose: Handle logic from Risk Report Trigger
 */
public with sharing class RiskReportTriggerHandler {

    public static void onBeforeInsert(List<Risk_Report__c> riskReportList){

        List<Risk_Report__c> riskReportNextStepsLogUpdateList = new List<Risk_Report__c>();

        for(Risk_Report__c rr : riskReportList){

            if(rr.Next_Steps__c != null){
                riskReportNextStepsLogUpdateList.add(rr);
            }
        }

        if(riskReportNextStepsLogUpdateList.size() > 0){
            updateNextStepsLog(riskReportNextStepsLogUpdateList, true);
        }
    }

    public static void onBeforeUpdate(List<Risk_Report__c> riskReportList, Map<Id, Risk_Report__c> oldMap){

        List<Risk_Report__c> riskReportNextStepsLogUpdateList = new List<Risk_Report__c>();

        for(Risk_Report__c rr : riskReportList){

            if(rr.Next_Steps__c != null && rr.Next_Steps__c != oldMap.get(rr.Id).Next_Steps__c){
                riskReportNextStepsLogUpdateList.add(rr);
            }
        }

        if(riskReportNextStepsLogUpdateList.size() > 0){
            updateNextStepsLog(riskReportNextStepsLogUpdateList, false);
        }
    }

    //Add the User name to Next Steps and User Name and Date of when update happened to Next Steps Log and make the Next Steps Log additive to keep log of all changes from Next Steps field in Next Steps Log Field
    public static void updateNextStepsLog(List<Risk_Report__c> riskReportList, Boolean isBeforeInsert){

        String todayMonthAndDayString = Datetime.now().Format('MM/dd');
        String triggeringUserFirstName = (UserInfo.getFirstName() == null ? '' : UserInfo.getFirstName().substring(0,1));
        String triggeringUserName = triggeringUserFirstName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());

        for(Risk_Report__c rr : riskReportList){
            if(isBeforeInsert){
                //Populate Next Steps and Next Steps Log on Before Insert
                rr.Next_Steps__c = todayMonthAndDayString + ' : ' + rr.Next_Steps__c;
                rr.Next_Steps_Log__c   = triggeringUserName + ' ' + rr.Next_Steps__c;
            }else{
                //Populate Next Steps and Next Steps Log on Before Update
                String nextStepsLog;
                rr.Next_Steps__c = todayMonthAndDayString + ' : ' + rr.Next_Steps__c;
                nextStepsLog = triggeringUserName + ' ' + rr.Next_Steps__c+ '\n' + (rr.Next_Steps_Log__c == null ? '' : rr.Next_Steps_Log__c);
                if(nextStepsLog.length() > 100000) {
                    rr.Next_Steps_Log__c = ' ' + nextStepsLog.left(100000);
                } else {
                    rr.Next_Steps_Log__c  = nextStepsLog;
                }

            }
            //Added 8.15.22 ST -- This stamps the DateNextStepsLastUpdated__c field with the DateTime that the Next Steps field was last updated
            rr.DateNextStepsLastUpdated__c = Date.today();
        }
    }
}