/**
 * Created by jmahapatra on 11/14/17.
 */

global with sharing class RepliconTaskUpsert implements Queueable, Database.AllowsCallouts
{
    private String Id;
    private String projectId;
    private String taskName;
    private Decimal totalHour;
    private Decimal totalAmount;
    private String manager;
    private String CONumber;

    global RepliconTaskUpsert(String Id,String taskName,String projectId,Decimal totalHour,Decimal totalAmount,String manager, String CONumber) {
        this.Id = Id;
        this.projectId = projectId;
        this.taskName = taskName;
        this.totalHour = totalHour;
        this.totalAmount = totalAmount;
        this.manager = manager;
        this.CONumber = CONumber;
    }

    global void execute(QueueableContext qc) {

        // query project data
        Boolean syncReplicon = false;
        List<EnableReplicon__c> obj = [Select IsActiveProject__c from EnableReplicon__c];
        if(obj.size()>0)
        {
            if(obj[0].IsActiveProject__c==true){
                syncReplicon = true;
            }
        }

        if(syncReplicon)
        {
            //Create task
            Replicon.Task task = Replicon.getProjectTaskById(this.Id);
            RepliconService service = new RepliconService();

            task.name=this.taskName;
            task.target.name=this.taskName;
            task.setEstimatedHours(this.totalHour) ;
            task.estimatedCost = new Replicon.EstimatedCost(this.totalAmount);
            task.code = this.CONumber;
            task.setProjectManager(this.manager);
            task.setProjectUri(this.projectId);


            System.debug('Creating task');
            if(!Test.isRunningTest()) {
                service.upsertTask(task);
            }
            service = null;

            //Update Project
            Replicon.Project p =  Replicon.getProjectById(this.Id);
            Replicon.ProjectInfo info = p.projectInfo;
            Replicon.Target tg= p.target;

            RepliconService service2 = new RepliconService();
            string updateProjectRequest  = JSON.serialize(info);

            if(!Test.isRunningTest())
            {
                service2.UpdateProject('{"target":' + JSON.serialize(tg) + ',"projectInfo":' + updateProjectRequest.replace('date_r', 'date').replace('number_r', 'number').replace('currency_r', 'currency') + '}');
                RepliconService service3 = new RepliconService();
                String clientString = '{"projectUri":"' + tg.uri + '","clients": [{"client":{"uri":"' + info.client.uri + '","name":null},"costAllocationPercentage": 100}]}';
                service3.updateBillingRate('ProjectService1.svc/UpdateClients', clientString);
            }
        }
        else{
            System.debug('Sync is disabled from custom settings');
        }
    }
}