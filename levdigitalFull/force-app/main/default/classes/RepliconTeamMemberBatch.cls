global class RepliconTeamMemberBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    List<Project__c> inputList;
	
    public RepliconTeamMemberBatch(List<Project__c> projectList) {
        inputList = projectList;
    }
    
    global sObject[] start(Database.BatchableContext BC) {
        return inputList;
    }
    
    global void execute(Database.BatchableContext bc, List<Project__c> records){
        RepliconService newService = new RepliconService();
        if(!Test.isRunningTest()) { newService.getProjectInformation(records[0].Id); }
    }
    
    global void finish(Database.BatchableContext bc){} 
}