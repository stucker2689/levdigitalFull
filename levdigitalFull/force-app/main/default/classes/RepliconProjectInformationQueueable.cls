public class RepliconProjectInformationQueueable implements Queueable, Database.AllowsCallouts{
	
    public List<Id> projectIDList;
    
    public RepliconProjectInformationQueueable(List<Id> inputIDList) {
        projectIDList = inputIDList;
    }
    
    public void execute(QueueableContext qc) {
        if(projectIDList.size() > 0) {
            RepliconService newService = new RepliconService();
            if(!Test.isRunningTest()) { newService.getProjectInformation(projectIDList[0]);}
            projectIDList.remove(0);
        }
        if(projectIDList.size() > 0) {
            System.enqueueJob(new RepliconProjectInformationQueueable(projectIDList));
        }
    }
}