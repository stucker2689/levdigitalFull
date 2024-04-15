public class OpportunityCalculations {

    public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};

    public static void relOppReCalc(Set<Id> opps){


        Map<Id, Opportunity> parentOpptyIdToParentOpptyAggregateDetailsMap = new Map<Id, Opportunity>();
        for(Id opptyId : opps){

            //Set it at start to handle if the Opportunity has no Change Orders
            Opportunity parentOpptyWithNoChangeOrders = new Opportunity(Id = opptyId, Change_Order_Revenue__c = 0, Change_Order_Hours__c = 0, Number_of_Change_Orders__c = 0, Change_Order_Lev_Hours__c = 0, 
                                                                        Change_Order_Lev_Revenue__c = 0, Non_Lev_Change_Order_Hours__c = 0, Non_Lev_Change_Order_Revenue__c = 0, OffshoreChangeOrderHours__c = 0, OffshoreChangeOrderRevenue__c = 0, TCVChangeOrderAmount__c = 0);

            parentOpptyIdToParentOpptyAggregateDetailsMap.put(opptyId, parentOpptyWithNoChangeOrders);
        }

        //Aggregate Query of all Change Orders related to the incoming Opportunity Ids
        //Note TODO: PS_Hours__c (Service Hours) and Total_Hours__c (Opportunity Hours) are the same rollup summary (Rolling up Oppty Products where Product Family Hidden = 'Professional Services') (Total Hours also includes where Product Family Hidden = 'Support' )
        AggregateResult[] sumCO  = [SELECT SUM(Total_Hours__c) coHoursSum, SUM(Amount) coAmountSum, SUM(Lev_Opportunity_Hours__c) coLevHoursSum, SUM(Lev_Opportunity_Revenue__c) coLevRevenueSum, 
                                            SUM(OffshoreOpportunityHours__c) offshoreHoursSum, SUM(OffshoreOpportunityRevenue__c) offshoreRevSum, SUM(CognizantOpportunityHours__c) cognizantHoursSum, SUM(CognizantOpportunityRevenue__c) cognizantRevSum,
                                            SUM(PS_Hours__c) coServiceHoursSum, SUM(Non_Lev_Opportunity_Hours__c) coNonLevHoursSum, SUM(Non_Lev_Opportunity_Revenue__c) coNonLevRevenueSum, SUM(AllOtherNonLevResourceAmount__c) coTCVAmountSum,
                                            COUNT(Id) coCount, Change_Orders__c parentOpptyId
                                    FROM Opportunity
                                    WHERE Change_Orders__c IN :opps AND StageName IN :opportunityClosedWonStageNames GROUP BY Change_Orders__c];
        
        // go through and set Change order revenue to 0 or newly calculated amount
        List<Opportunity> updateOpportunityList = new List<Opportunity>();


        for (AggregateResult ar : sumCO){    

            Id parentOpptyId = (Id)ar.get('parentOpptyId');
            Decimal totalChangeOrderAmount = (Decimal)ar.get('coAmountSum') != null ? (Decimal)ar.get('coAmountSum') : 0;
            Decimal totalCOServiceHours = (Decimal)ar.get('coServiceHoursSum') != null ? (Decimal)ar.get('coServiceHoursSum') : 0;
            Decimal coCount = (Decimal)ar.get('coCount') != null ? (Decimal)ar.get('coCount') : 0;
            Decimal coLevHoursSum = (Decimal)ar.get('coLevHoursSum') != null ? (Decimal)ar.get('coLevHoursSum') : 0;
            Decimal coLevRevenueSum = (Decimal)ar.get('coLevRevenueSum') != null ? (Decimal)ar.get('coLevRevenueSum') : 0;
            Decimal coNonLevHoursSum = (Decimal)ar.get('coNonLevHoursSum') != null ? (Decimal)ar.get('coNonLevHoursSum') : 0;
            Decimal coNonLevRevenueSum = (Decimal)ar.get('coNonLevRevenueSum') != null ? (Decimal)ar.get('coNonLevRevenueSum') : 0;
            //Added for Offshore CO Sums
            Decimal coOffshoreHoursSum = (Decimal)ar.get('offshoreHoursSum') != null ? (Decimal)ar.get('offshoreHoursSum') : 0;
            Decimal coOffshoreRevSum = (Decimal)ar.get('offshoreRevSum') != null ? (Decimal)ar.get('offshoreRevSum') : 0;
            //Added for Cognizant CO Sums
            Decimal coCognizantHoursSum = (Decimal)ar.get('cognizantHoursSum') != null ? (Decimal)ar.get('cognizantHoursSum') : 0;
            Decimal coCognizantRevSum = (Decimal)ar.get('cognizantRevSum') != null ? (Decimal)ar.get('cognizantRevSum') : 0;
            //Added for TCV CO Sum
            Decimal coTCVAmountSum = (Decimal)ar.get('coTCVAmountSum') != null ? (Decimal)ar.get('coTCVAmountSum') : 0;

            //Initialize a Opportunity to store all the values (Alternate to having 7 Maps)
            Opportunity parentOpptyWithAggregateDetails = new Opportunity(Id = parentOpptyId, 
                                                                            Change_Order_Revenue__c = totalChangeOrderAmount, 
                                                                            Change_Order_Hours__c = totalCOServiceHours, 
                                                                            Number_of_Change_Orders__c = coCount,
                                                                            Change_Order_Lev_Hours__c = coLevHoursSum, 
                                                                            Change_Order_Lev_Revenue__c = coLevRevenueSum, 
                                                                            Non_Lev_Change_Order_Hours__c = coNonLevHoursSum, 
                                                                            Non_Lev_Change_Order_Revenue__c = coNonLevRevenueSum,
                                                                            OffshoreChangeOrderHours__c = coOffshoreHoursSum,
                                                                            OffshoreChangeOrderRevenue__c = coOffshoreRevSum,
                                                                            CognizantChangeOrderHours__c = coCognizantHoursSum,
                                                                            CognizantChangeOrderRevenue__c = coCognizantRevSum,
                                                                            TCVChangeOrderAmount__c = coTCVAmountSum);

            parentOpptyIdToParentOpptyAggregateDetailsMap.put(parentOpptyId, parentOpptyWithAggregateDetails); //Set Map of Parent Oppty Id to Opportunity Object with Aggregate Details
        }
        
        for(Opportunity existingOppty : [SELECT Id, Change_Order_Revenue__c,Change_Order_Hours__c,Number_of_Change_Orders__c, Change_Order_Lev_Hours__c, Change_Order_Lev_Revenue__c, Non_Lev_Change_Order_Hours__c, Non_Lev_Change_Order_Revenue__c,
                                                OffshoreChangeOrderHours__c, OffshoreChangeOrderRevenue__c, CognizantChangeOrderHours__c, CognizantChangeOrderRevenue__c, TCVChangeOrderAmount__c
                                        FROM Opportunity WHERE Id IN :opps]){
            Boolean updateNeeded = false;

            //New logic so we are not using too many maps and only update when an update is needed
            if(parentOpptyIdToParentOpptyAggregateDetailsMap.containsKey(existingOppty.Id)){
                Opportunity updatedOppty = parentOpptyIdToParentOpptyAggregateDetailsMap.get(existingOppty.Id);

                if(existingOppty.Change_Order_Revenue__c != updatedOppty.Change_Order_Revenue__c){            
                    existingOppty.Change_Order_Revenue__c = updatedOppty.Change_Order_Revenue__c;
                    updateNeeded = true;
                }            

                if(existingOppty.Change_Order_Hours__c != updatedOppty.Change_Order_Hours__c){            
                    existingOppty.Change_Order_Hours__c = updatedOppty.Change_Order_Hours__c;
                    updateNeeded = true;
                }            

                if(existingOppty.Number_of_Change_Orders__c != updatedOppty.Number_of_Change_Orders__c){            
                    existingOppty.Number_of_Change_Orders__c = updatedOppty.Number_of_Change_Orders__c;
                    updateNeeded = true;
                }            

                //ST Lev Change Order Hours and Revenue Addition 1/20/2022
                if(existingOppty.Change_Order_Lev_Hours__c != updatedOppty.Change_Order_Lev_Hours__c){            
                    existingOppty.Change_Order_Lev_Hours__c = updatedOppty.Change_Order_Lev_Hours__c;
                    updateNeeded = true;
                }
            
                if(existingOppty.Change_Order_Lev_Revenue__c != updatedOppty.Change_Order_Lev_Revenue__c){            
                    existingOppty.Change_Order_Lev_Revenue__c = updatedOppty.Change_Order_Lev_Revenue__c;
                    updateNeeded = true;
                }            

                //ST Non Lev Change Order Hours and Revenue Addition 5/19/2022         
                if(existingOppty.Non_Lev_Change_Order_Hours__c != updatedOppty.Non_Lev_Change_Order_Hours__c){            
                    existingOppty.Non_Lev_Change_Order_Hours__c = updatedOppty.Non_Lev_Change_Order_Hours__c;
                    updateNeeded = true;
                }
                            
                if(existingOppty.Non_Lev_Change_Order_Revenue__c != updatedOppty.Non_Lev_Change_Order_Revenue__c){            
                    existingOppty.Non_Lev_Change_Order_Revenue__c = updatedOppty.Non_Lev_Change_Order_Revenue__c;
                    updateNeeded = true;
                }
                
                //ST Offshore Change Order Hours and Revenue Addition 11/16/2022         
                if(existingOppty.OffshoreChangeOrderHours__c != updatedOppty.OffshoreChangeOrderHours__c){            
                    existingOppty.OffshoreChangeOrderHours__c = updatedOppty.OffshoreChangeOrderHours__c;
                    updateNeeded = true;
                }
                            
                if(existingOppty.OffshoreChangeOrderRevenue__c != updatedOppty.OffshoreChangeOrderRevenue__c){            
                    existingOppty.OffshoreChangeOrderRevenue__c = updatedOppty.OffshoreChangeOrderRevenue__c;
                    updateNeeded = true;
                } 

                //ST Cognizant Change Order Hours and Revenue Addition 3/7/2023      
                if(existingOppty.CognizantChangeOrderHours__c != updatedOppty.CognizantChangeOrderHours__c){            
                    existingOppty.CognizantChangeOrderHours__c = updatedOppty.CognizantChangeOrderHours__c;
                    updateNeeded = true;
                }
                            
                if(existingOppty.CognizantChangeOrderRevenue__c != updatedOppty.CognizantChangeOrderRevenue__c){            
                    existingOppty.CognizantChangeOrderRevenue__c = updatedOppty.CognizantChangeOrderRevenue__c;
                    updateNeeded = true;
                } 

                //ST TCV Change Order Amount Addition as part of RDG changes 3/30/2023
                if(existingOppty.TCVChangeOrderAmount__c != updatedOppty.TCVChangeOrderAmount__c){
                    existingOppty.TCVChangeOrderAmount__c = updatedOppty.TCVChangeOrderAmount__c;
                    updateNeeded = true;
                }
            }

            if(updateNeeded){ //Only if an update is needed should it get added to the update list
                updateOpportunityList.add(existingOppty);
            }
        }
        CheckFirst.calculateOpp=false;

        if(updateOpportunityList.size() > 0){
            update updateOpportunityList;
        }
    }


    public static void createRepliconTask(Set<Id> opps){

        //System.debug('opps:------> '+opps);
        /*if(opps.size()>0)
        {
            Map<Id,Opportunity> objMap=new Map<Id, Opportunity>();
            Set<Id> repliconOppId = new Set<Id>();
            List<Opportunity> ops = [select  Change_Orders__r.Id,Name,Total_Hours__c,Amount, Project_ManagerLookup__r.Name, CO_Number__c from Opportunity where Id in :opps];
            for(Opportunity op:ops)
            {
                objMap.put(op.Change_Orders__c, op);
                repliconOppId.add(op.Change_Orders__c);
            }
            //System.debug('Map: '+objMap);
            //System.debug('repliconOppId:------->'+repliconOppId);

            Id jobID = null;

            //System.debug('repliconOppId  '+repliconOppId);
            if(repliconOppId.size()>0 && CheckFirst.IfTaskRun==true){
                //Change Order Task

                List<Project__c> prList = [SELECT Id,Name,RepliconUri__c,Opportunity__c FROM Project__c WHERE Opportunity__c IN :repliconOppId] ;

                for(Project__c project : prList)
                {
                    Opportunity op = objMap.get(project.Opportunity__c);
                    if(!String.isBlank(op.Id))
                    {
                        RepliconTaskUpsert taskUpsert = new RepliconTaskUpsert(project.Id,op.Name,project.RepliconUri__c,op.Total_Hours__c,op.Amount, op.Project_ManagerLookup__r.Name,op.CO_Number__c);
                        if(jobID==null)
                        {
                            jobID = system.enqueueJob(taskUpsert);
                        }
                    }
                }
            }
            CheckFirst.IfTaskRun =  false;
        }*/
    }
}