public with sharing class StatusReportTrgHandler {
	
	public static void opportunityRisk(Status_Report__c[] trgNew){
		
		Set<Id> oppIds = new Set<Id>();
        //collect the opportunities ids that are going to be used
        for(Status_Report__c statusreport :trgNew){
            if(statusreport.Opportunity__c != null){
                oppIds.add(statusreport.Opportunity__c);
            }	
        }
            //store all of the opportunity info needed into a map
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id, Project_Health__c FROM Opportunity WHERE Id IN :oppIds]);
            
        
        for(Status_Report__c statusreport :trgNew){
            if(statusreport.Opportunity__c != null){
            	//Change Opportunity Project_Health__c depending on statusreport conditions
            	if(statusreport.Budget_Risk__c == 'High' || statusreport.Timeline_Risk__c == 'High' || statusreport.Scope_Risk__c == 'High'){
            		opportunityMap.get(statusreport.Opportunity__c).Project_Health__c = 'Red';
            	}else if(statusreport.Budget_Risk__c == 'Medium' || statusreport.Timeline_Risk__c == 'Medium' || statusreport.Scope_Risk__c == 'Medium'){
            		opportunityMap.get(statusreport.Opportunity__c).Project_Health__c = 'Yellow';
            	}else
            		opportunityMap.get(statusreport.Opportunity__c).Project_Health__c = 'Green';
            }	
        }
        update opportunityMap.values();
	}

}