trigger OpportunityBeforeInsertUpdate on Opportunity (before insert, before update) {
/*
** Created by: Levementum
** Created Date: 10/30/2012
** If Latest Work Log is updated on an opportunity, the work log is appended to tracking who made the change and when
*/
    /*String fName = UserInfo.getFirstName();
    fName = (fName == null ? '' : fName.substring(0,1));
    String uName = fName + (UserInfo.getLastName() == null ? '' : UserInfo.getLastName());
    //Map<Id, RecordType> rtMap = new Map<Id, RecordType>([Select Id, DeveloperName from RecordType where sObjectType = 'Opportunity' and IsActive = true]);
    Datetime td = Datetime.now();
    String today = td.Format('MM/dd');
    String nextStepsLog;
    String managersNotesLog;
    String sowStages = OpportunitySettings__c.getInstance().SOWStages__c;
    String changeOrderStages = OpportunitySettings__c.getInstance().ChangeOrderStages__c;
    Boolean runFindMaxSOW = false;
    Boolean runFindMaxCO = false;*/
    //does this record type work?
    //get the max sow number
    //for(Opportunity opp : Trigger.new){
        /*if(opp.SOW_Number__c == null && sowStages != null && sowStages.contains(opp.StageName) && opp.Opportunity_RecordType_Name__c != 'Change_Order' && runFindMaxSOW == false){
            runFindMaxSOW = true;
        }

        if(opp.CO_Number__c == null && changeOrderStages != null && changeOrderStages.contains(opp.StageName) && opp.Opportunity_RecordType_Name__c == 'Change_Order' && runFindMaxCO == false){
            runFindMaxCO = true;
        }*/
    //}

    /*static AggregateResult[] maxSOW;
    List<Opportunity> maxSOWNumberOpportunityList = new List<Opportunity>();
    String sowNO;
    Integer sowNum;*/
    //if(runFindMaxSOW){

        /*if(maxSOW==NULL){
            maxSOW  = [SELECT Max(SOW_Number__c) msow
                        FROM Opportunity
                        WHERE SOW_Number__c != null and SOW_Number__c like 'SOW-%%' and RecordType.DeveloperName != 'Change_Order'];
        }      

        for (AggregateResult ar : maxSOW){
            sowNO = String.valueOf(ar.get('msow'));
        }*/

        /*maxSOWNumberOpportunityList = [SELECT Id, Name, SOW_Number__c 
                                        FROM Opportunity 
                                        WHERE SOW_Number__c != null AND SOW_Number__c LIKE 'SOW-%%' AND RecordType.DeveloperName != 'Change_Order' 
                                        ORDER BY SOW_Number__c DESC 
                                        LIMIT 1];

        for(Opportunity oppty : maxSOWNumberOpportunityList){
            if(oppty.SOW_Number__c != null){
                sowNO = oppty.SOW_Number__c;
            }
        }

        if(sowNO != null){
            sowNO = sowNO.substring(9, 14);
            System.debug('sowNO: ' + sowNO);
            sowNum = Integer.valueOf(sowNO);
        }*/
    //}

    //CO
    /*static AggregateResult[] maxCO;
    List<Opportunity> maxCONumberOpportunityList = new List<Opportunity>();
    String coNo;
    Integer coNum;*/
    //if(runFindMaxCO){

        /*if(maxCO==NULL){
            maxCO = [SELECT Max(CO_Number__c) mco
            FROM Opportunity
            WHERE CO_Number__c != null and CO_Number__c like 'CO-%' and RecordType.DeveloperName = 'Change_Order'];
        }

        for (AggregateResult ar : maxCO){
            coNO = String.valueOf(ar.get('mco'));
        }*/

        /*maxCONumberOpportunityList = [SELECT Id, Name, CO_Number__c 
                                        FROM Opportunity 
                                        WHERE CO_Number__c != null AND CO_Number__c LIKE 'CO-%' AND RecordType.DeveloperName = 'Change_Order' 
                                        ORDER BY CO_Number__c DESC 
                                        LIMIT 1];

        for(Opportunity oppty : maxCONumberOpportunityList){
            if(oppty.CO_Number__c != null){
                coNO = oppty.CO_Number__c;
            }
        }

        if(coNO != null){
            coNO = coNO.substring(8, 13);
            System.debug('coNo: ' + coNO);
            coNum = Integer.valueOf(coNO);
        }*/
    //}

    //Set<Id> msaAccounts = new Set<Id>();
    //for(Opportunity o:Trigger.new)
    //{
        /*if(trigger.isInsert && o.Latest_Work_Log__c != null)
        {
            o.Work_Logs__c = uName + ' ' + LevUtility.stringDate(System.today()) + ' : ' + o.Latest_Work_Log__c;
        }
        else if (trigger.isUpdate && o.Latest_Work_Log__c != null && o.Latest_Work_Log__c != trigger.oldMap.get(o.Id).Latest_Work_Log__c)
        {
            o.Work_Logs__c = (o.Work_Logs__c == null ? '' : o.Work_Logs__c) + '\n' + uName + ' ' + LevUtility.stringDate(System.today()) + ' : '  + o.Latest_Work_Log__c;
        }*/

        //set sow number
        /*if(o.SOW_Number__c == null && sowStages!=null && sowStages.contains(o.StageName) && o.Opportunity_RecordType_Name__c != 'Change_Order')
        {
            sowNum = (sowNum == null ? 40000 : sowNum + 1);
            o.SOW_Number__c = 'SOW-' + String.valueOf(system.today().year()) + '-' + String.valueOf(sowNum);
            msaAccounts.add(o.AccountId);
        }*/

        //set change order number
        /*if(o.CO_Number__c == null && changeOrderStages!=null && changeOrderStages.contains(o.StageName) && o.Opportunity_RecordType_Name__c == 'Change_Order')
        {
            coNum = (coNum == null ? 40000 : coNum + 1);
            o.CO_Number__c = 'CO-' + String.valueOf(system.today().year()) + '-' + String.valueOf(coNum);
        }*/

        //Clear SOW number, if the record type is changed to Change order from  other
        /*if(trigger.isUpdate && o.Opportunity_RecordType_Name__c == 'Change_Order'
            && o.Opportunity_RecordType_Name__c!= trigger.oldMap.get(o.Id).Opportunity_RecordType_Name__c
            && o.SOW_Number__c !=NULL)
        {
            o.SOW_Number__c ='';
        }*/
        //Clear CO number, if the record type is changed from 'Change order' to other
        /*if(trigger.isUpdate && trigger.oldMap.get(o.Id).Opportunity_RecordType_Name__c == 'Change_Order'
            && o.Opportunity_RecordType_Name__c!= trigger.oldMap.get(o.Id).Opportunity_RecordType_Name__c
            && o.CO_Number__c !=NULL)
        {
            o.CO_Number__c ='';
        }*/

        //Naren: Added logic to update Next Steps Log field when the 'Next Steps' field is updated

        /*if(trigger.isInsert && o.Next_Steps__c != null)
        {
            o.Next_Steps__c = today + ' : ' + o.Next_Steps__c;
            o.Next_Steps_Log__c   = uName + ' ' + o.Next_Steps__c;
            o.Next_Steps_Timestamp__c = td;
            //o.Next_Steps_Log__c   = uName + ' ' + today + ' : '  + o.Next_Steps__c;

        }
        else if (trigger.isUpdate && o.Next_Steps__c != null && o.Next_Steps__c != trigger.oldMap.get(o.Id).Next_Steps__c)
        {
            
            o.Next_Steps__c = today + ' : ' + o.Next_Steps__c;
            nextStepsLog = uName + ' ' + o.Next_Steps__c+ '\n' + (o.Next_Steps_Log__c == null ? '' : o.Next_Steps_Log__c);
            //nextStepsLog = uName + + ' ' + today + ' : ' + o.Next_Steps__c+ '\n' + (o.Next_Steps_Log__c == null ? '' : o.Next_Steps_Log__c);
            if(nextStepsLog.length()>32768) {
                o.Next_Steps_Log__c = ' ' + nextStepsLog.left(32768);
            } else {
                o.Next_Steps_Log__c  = nextStepsLog;
            }
            //Moved Next Steps Field Timestamp Workflow Rule into trigger to avoid recursive Opp triggers.
            //Update Next Steps timestamp
             o.Next_Steps_Timestamp__c = td;

        }*/

        //Sam: Added logic to update Managers Notes Log field when Managers Notes field is updated

        /*if(trigger.isInsert && o.Managers_Notes__c != null)
        {
            o.Managers_Notes__c = today + ' : ' + o.Managers_Notes__c;
            o.Managers_Notes_Log__c   = uName + ' ' + o.Managers_Notes__c;

            String managersNote;
            if(!o.Managers_Notes__c.contains('<li>')){
                managersNote = '<p>' + today + ' : ' + o.Managers_Notes__c.substring(3, o.Managers_Notes__c.length());
            }else{
                managersNote = '<p>' + today + ' : ' + o.Managers_Notes__c;
            }
            o.Managers_Notes__c = managersNote;
            o.Managers_Notes_Log__c = '<p>' + uName + ' ' + o.Managers_Notes__c.substring(3, o.Managers_Notes__c.length())  + '<p/>' + (o.Managers_Notes_Log__c == null ? '' : o.Managers_Notes_Log__c);

        }
        else if (trigger.isUpdate && o.Managers_Notes__c != null && o.Managers_Notes__c != trigger.oldMap.get(o.Id).Managers_Notes__c)
        {
            String managersNote;
            if(!o.Managers_Notes__c.contains('<li>')){
                managersNote = '<p>' + today + ' : ' + o.Managers_Notes__c.substring(3, o.Managers_Notes__c.length());
            }else{
                managersNote = '<p>' + today + ' : ' + o.Managers_Notes__c;
            }

            o.Managers_Notes__c = managersNote;
            managersNotesLog = '<p>' + uName + ' ' + o.Managers_Notes__c.substring(3, o.Managers_Notes__c.length())  + '<p/>' + (o.Managers_Notes_Log__c == null ? '' : o.Managers_Notes_Log__c);

            if(managersNotesLog.length()>131072) {
                o.Managers_Notes_Log__c = ' ' + managersNotesLog.left(131072);
            } else {
                o.Managers_Notes_Log__c  = managersNotesLog;
            }
        }*/


        //Naren: Setting the 'Create Project' flag to True, if the opportunity Stage is set to 'Closed Won', as we are creating project automatically at this stage
        /*if((o.Opportunity_RecordType_Name__c == 'Salesforce'|| o.Opportunity_RecordType_Name__c == 'SugarCRM' ||
            o.Opportunity_RecordType_Name__c == 'PSS' || o.Opportunity_RecordType_Name__c=='Service_Contract')&& (o.StageName=='Closed Won')&&o.Do_Not_Create_Project__c == FALSE)
            {
                o.Create_Project__c = TRUE;
            }*/

    //}

    /*if(msaAccounts.size() >0)
    {
        AccountCalculations.SetMSA(msaAccounts);
    }*/

    //Naren: Added logic to capture the values of Total Hours, Invoice payment terms, Opportunity Amount when stage is changed to Verbal/ Finalize Contracts
    /*String stagesBeforeVerbal = 'Interested Prospect, Discovery, Negotiation, Solution Validation';
    String stagesBeforeFinalize = 'Interested Prospect, Discovery, Negotiation, Solution Validation, Verbal Approval';

    if(trigger.isUpdate && trigger.isBefore)
    {
        for(Opportunity o:Trigger.new)
        {
            if(stagesBeforeVerbal.contains(o.StageName))
            {
                o.Total_Hours_Verbal__c = o.Total_Hours__c;
                o.Invoice_Payment_Terms_Verbal__c = o.Payment_Terms__c;
                o.Opportunity_Amount_Verbal__c = o.Amount;

            }

            if(stagesBeforeFinalize.contains(o.StageName))
            {
                o.Total_Hours_Finalize_Contracts__c = o.Total_Hours__c;
                o.Invoice_Payment_Terms_Finalize_Contracts__c =  o.Payment_Terms__c;
                o.Opportunity_Amount_Finalize_Contract__c = o.Amount;
            }

        }

    }*/
}