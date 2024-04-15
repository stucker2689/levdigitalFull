/**********************************************************************************************************************************************************************
Purpose: Runs to check that all Opportunities created within the day are properly converted to COs if they were meant to come in as COs via the Winzone Integration
    Checks the WZ Related Opportunity ID field on Opportunities created the same day as the Batch run and converts them to COs 
    and assigns the proper Parent Opportunity that has a matching ESA Project Id of the WZ Related Opportunity on the incoming Opportunity

Run the logic once: 
WinzoneChangeOrderConversionBatch winzoneChangeOrderConversionCheck = new WinzoneChangeOrderConversionBatch(true);
Database.executeBatch(winzoneChangeOrderConversionCheck, 5);

Apex to schedule this class to run once every 3 hours daily:
WinzoneChangeOrderConversionBatch winzoneChangeOrderConversionCheck = new WinzoneChangeOrderConversionBatch(true);
System.schedule('Winzone Change Order Conversion Hourly Check', '0 0 0/3 1/1 * ? *', winzoneChangeOrderConversionCheck);

************************************************************************************************************************************************************************/

public with sharing class WinzoneChangeOrderConversionBatch implements Schedulable, Database.Batchable<sObject>{
    
    public final String QueryString;
    public final Boolean forOpptysCreatedToday;
    //private String salesforceOpportunityRTId = '012d0000000kcjgAAA';
    //private String changeOrderOpportunityRTId = '012d0000000kcxHAAQ';

    public WinzoneChangeOrderConversionBatch(Boolean forOpportunitiesCreatedToday) {

        forOpptysCreatedToday = forOpportunitiesCreatedToday;
        if(forOpportunitiesCreatedToday){
            //Query Opportunities that were created TODAY with the WZ Related Opportunity ID is populated and has a RT of 'Salesforce'
            QueryString = 'SELECT Id, Name, RecordTypeId, RecordType.Name, Peoplesoft_Project_Id__c, StageName, Change_Orders__c, WZRelatedOpportunityID__c'
                            + ' FROM Opportunity'
                            + ' WHERE (CreatedDate = TODAY OR CreatedDate = YESTERDAY) AND WZRelatedOpportunityID__c != null AND RecordTypeId = \'012d0000000kcjgAAA\''
                            + ' ORDER BY CreatedDate'; 
        }else{
            QueryString = 'SELECT Id, Name, RecordTypeId, RecordType.Name, Peoplesoft_Project_Id__c, StageName, Change_Orders__c, WZRelatedOpportunityID__c'
                        + ' FROM Opportunity'
                        + ' WHERE WZRelatedOpportunityID__c != null AND RecordTypeId = \'012d0000000kcjgAAA\''
                        + ' ORDER BY CreatedDate'; 
        }

    }

    public void execute (SchedulableContext ctx) {
        System.debug('**** WinzoneChangeOrderConversionBatch SCHEDULABLE EXECUTE ****');
        WinzoneChangeOrderConversionBatch winzoneChangeOrderConversionCheck = new WinzoneChangeOrderConversionBatch(forOpptysCreatedToday);
        Database.executeBatch(winzoneChangeOrderConversionCheck, 5);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('**** WinzoneChangeOrderConversionBatch START ****');
        return Database.getQueryLocator(QueryString);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> opptyList){
        System.debug('**** WinzoneChangeOrderConversionBatch BATCH EXECUTE ****');
        Set<String> wzRelatedOpportunityIdSet = new Set<String>();
        for(Opportunity oppty : opptyList){
            if(oppty.WZRelatedOpportunityID__c != null){
                wzRelatedOpportunityIdSet.add(oppty.WZRelatedOpportunityID__c);
            }
        }

        List<Opportunity> relatedParentOpportunityList = new List<Opportunity>();
        relatedParentOpportunityList = [SELECT Id, Name, StageName, Peoplesoft_Project_Id__c, CreatedDate, RecordTypeId, RecordType.Name
                                        FROM Opportunity
                                        WHERE Peoplesoft_Project_Id__c IN :wzRelatedOpportunityIdSet AND IsWon = true AND RecordTypeId = '012d0000000kcjgAAA'
                                        ORDER BY CreatedDate ASC];

        Map<String, Opportunity> peoplesoftProjIdToParentOppty = new Map<String, Opportunity>();
        for(Opportunity parentOppty : relatedParentOpportunityList){
            peoplesoftProjIdToParentOppty.put(parentOppty.Peoplesoft_Project_Id__c, parentOppty);
        }

        List<Opportunity> opportunitiesToConvertUpdateList = new List<Opportunity>();
        for(Opportunity oppty : opptyList){
            if(peoplesoftProjIdToParentOppty.containsKey(oppty.WZRelatedOpportunityID__c) && oppty.Id != peoplesoftProjIdToParentOppty.get(oppty.WZRelatedOpportunityID__c).Id){
                oppty.Change_Orders__c = peoplesoftProjIdToParentOppty.get(oppty.WZRelatedOpportunityID__c).Id;
                oppty.RecordTypeId = '012d0000000kcxHAAQ';
                opportunitiesToConvertUpdateList.add(oppty);
            }
        }

        if(opportunitiesToConvertUpdateList.size() > 0){
            System.debug('Updating ' + opportunitiesToConvertUpdateList.size() + ' Opportunities to Change Orders via the WZ Related Oppportunity Id Batch Check Process');
            update opportunitiesToConvertUpdateList;
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('**** WinzoneChangeOrderConversionBatch FINISH ****');

    }
}