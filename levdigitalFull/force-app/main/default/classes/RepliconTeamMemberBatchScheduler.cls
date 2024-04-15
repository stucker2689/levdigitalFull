global class RepliconTeamMemberBatchScheduler implements Schedulable {
    global void execute (SchedulableContext ctx) {
        
        //Integer currentApexJobs = [SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')];
        
        //if (currentApexJobs < 5 || Test.isRunningTest()) {
        List<Project__c> allProjects = [SELECT Id FROM Project__c WHERE Sync_Replicon_Team_Members__c = true];
        List<Id> projectIDList = new List<Id>();
        for(Project__c currentProject : allProjects) {
            projectIDList.add(currentProject.Id);
        }
        RepliconProjectInformationQueueable newProjectInformationBatch = new RepliconProjectInformationQueueable(projectIDList);
        if(!Test.isRunningTest()) { System.enqueueJob(new RepliconProjectInformationQueueable(projectIDList)); }
        //}
        
        //if(currentApexJobs >= 5 || Test.isRunningTest()) {
        //    RepliconTeamMemberBatchScheduler newSchedulableInstance = new RepliconTeamMemberBatchScheduler();
        //    Datetime newDatetime = Datetime.now().addMinutes(30);
        //    String CRONString = newDatetime.format('s m H d M \'?\' yyyy');
        //    if(!Test.isRunningTest()) { Id schedId = System.Schedule('RepliconTeamMemberRetry' + CRONString, CRONString, newSchedulableInstance); }
        //}
    }
}