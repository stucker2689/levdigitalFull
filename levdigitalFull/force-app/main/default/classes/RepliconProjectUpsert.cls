/**
 * Created by jmahapatra on 11/13/17.
 */

global with sharing class RepliconProjectUpsert implements Queueable, Database.AllowsCallouts {

    private String projectId;
    private Boolean updateSF;

    global RepliconProjectUpsert(String projectId,Boolean updateSF) {
        this.projectId = projectId;
        this.updateSF = updateSF;
    }

    global void execute(QueueableContext qc) {

        // query project data
        Boolean syncReplicon = false;
        Boolean syncBillingRates = false; //ST 2.28.2023 Only Update Replicon Billing Rates on initial Project Creation

        List<EnableReplicon__c> obj = [SELECT IsActiveProject__c FROM EnableReplicon__c];
        if(obj.size()>0){
            if(obj[0].IsActiveProject__c == true){
                syncReplicon = true;
            }
        }
        Date febTwentyEighthDate = Date.newInstance(2023, 2, 28);
        if(syncReplicon){
            string uri = '';
            String projectURI='';

            if(!String.isBlank(this.projectId)) {
                Project__c p = [SELECT Id,RepliconUri__c, Opportunity__c,Opportunity__r.CloseDate, Account__r.Id,Account__r.Name,Account__r.RepliconClientUri__c, Opportunity__r.Opportunity_RecordType_Name__c 
                                FROM Project__c 
                                WHERE Id = :this.projectId];

                /************** Create Client, if does not exist ******************/
                if (String.isBlank(p.Account__r.RepliconClientUri__c)) {
                    Replicon.Client cl = Replicon.getClientById(p.Account__r.Id);
                    RepliconService srv = new RepliconService();
                    if(!Test.isRunningTest()) {
                        uri = srv.upsertClient(cl, p.Account__r.Id);
                    }else{
                        uri ='urn:sample:client';
                    }
                }


                /*
                Create Project if does not exist on replicon
                If exists, then update the project with another endpoint.
                 */
                Replicon.Project project = Replicon.getProjectById(this.projectId);
                //System.debug('project string: '+project);

                if(String.isBlank(p.RepliconUri__c)){
                    RepliconService service = new RepliconService();
                    if(!Test.isRunningTest()) {
                        projectURI = service.upsertProject(project, this.projectId, this.updateSF);
                    }
                    syncBillingRates = true;
                }else{ /********** Update Project *************/
                    System.debug('Project Found: '+p.RepliconUri__c);

                    projectURI = p.RepliconUri__c;
                    Replicon.ProjectInfo info = project.projectInfo;
                    Replicon.Target tg = project.target;
                    RepliconService service2 = new RepliconService();
                    string updateProjectRequest  = JSON.serialize(info);
                    tg.uri = projectURI;
                    tg.name = null;

                    if(!Test.isRunningTest()) {
                        service2.UpdateProject('{"target":'+JSON.serialize(tg)+',"projectInfo":'+updateProjectRequest.replace('date_r','date').replace('number_r','number').replace('currency_r','currency')+'}');

                        // Updating Client
                        RepliconService service3 = new RepliconService();
                        String clientString = '{"projectUri":"'+tg.uri+'","clients": [{"client":{"uri":"'+info.client.uri+'","name":null},"costAllocationPercentage": 100}]}';
                        system.debug('*client ' + clientString);
                        service3.updateBillingRate('ProjectService1.svc/UpdateClients',clientString);
                    }
                }

                /*********************** Billing rate for Replicon OLD Deactivated before 3/1/2021 ***************************/
                /*
                System.debug('Billing for ASC');

                String pType='';
                List<OpportunityLineItem> ols;
                if(!String.isBlank(p.RepliconUri__c))
                {
                    projectURI = p.RepliconUri__c;
                    pType = p.Opportunity__r.Opportunity_RecordType_Name__c;
                    ols = [select Opportunity.Name,Id,Name,UnitPrice from OpportunityLineItem where Opportunity.Id=:p.Opportunity__c];
                }
                else{
                    Project__c p2 = [Select Id,RepliconUri__c, Opportunity__c,Opportunity__r.CloseDate,Opportunity__r.Opportunity_RecordType_Name__c,
                            Account__r.Id,Account__r.Name,Account__r.RepliconClientUri__c from Project__c where Id = :this.projectId];

                    //projectURI = p2.RepliconUri__c;
                    pType = p2.Opportunity__r.Opportunity_RecordType_Name__c;
                    ols = [select Opportunity.Name,Id,Name,UnitPrice from OpportunityLineItem where Opportunity.Id=:p2.Opportunity__c];
                }

                System.debug('p.RepliconUri__c: '+p.RepliconUri__c);
                System.debug('projectUri: '+projectURI);
                System.debug('pType: '+pType);
                System.debug('ols.size: '+String.valueOf(ols.size()));

                if(String.isNotBlank(projectURI) && String.isNotBlank(pType) && ols.size()>0){
                    System.debug('Process for ASC Billing');

                    //RepliconBillingRate rt = new RepliconBillingRate(projectUri,ols,pType);
                    //System.enqueueJob(rt);

                    for (OpportunityLineItem ol:ols)
                    {
                        if(!String.isBlank(ol.Name)) {

                            String repliconBillingName = ol.Name.replaceAll('\\s+','');
                            String oppName = ol.Opportunity.Name.replaceAll(' ','');

                            repliconBillingName = repliconBillingName.replaceAll(oppName,'');
                            System.debug('repliconBillingName: '+repliconBillingName);

                            if(pType.equalsIgnoreCase('Service_Contract')){
                                String jsonRate = '{' +
                                        '"projectUri": "'+projectURI+'",' +
                                        '"rate": {"amount": "'+String.valueOf(ol.UnitPrice)+'","currencyUri": "urn:replicon-tenant:levementum:currency:1"},' +
                                        '"projectFixedBidBillingFrequencyUri": "urn:replicon:fixed-bid-frequency:end-of-project"}';

                                String url ='FixedBidProjectService1.svc/UpdateProjectFixedBidRate';
                                RepliconService sv = new RepliconService();
                                if(!Test.isRunningTest()) {sv.updateBillingRate(url,jsonRate);}
                            }
                        }
                    }
                }
                */

                if(String.isNotBlank(projectURI)){
                    Project__c updatedProject = new Project__c();
                    updatedProject.Id = this.projectId;
                    updatedProject.RepliconUri__c = projectURI;
                    if(String.isBlank(p.RepliconURI__c)){ //Only Update project if the Replicon URI is new
                        update updatedProject;
                    }

                    if(syncBillingRates){
                        //CreateRepliconBillingRates.addOpportunityProductsAsRepliconBillRates(this.projectId); //Create Bill Rates on the Project in Replicon if necessary
                        AddBillingRatesToRepliconProject projectBillRatesUpdate = new AddBillingRatesToRepliconProject(this.projectId);
                        System.enqueueJob(projectBillRatesUpdate); 
                    }
                }

                /********************** Update Account for client id if created ***********************/
                if(String.isBlank(p.Account__r.RepliconClientUri__c) && !String.isBlank(uri)) {
                    Account updatedAccount = new Account();
                    updatedAccount.Id = p.Account__r.Id;
                    updatedAccount.RepliconClientUri__c = uri;
                    update updatedAccount;
                }
            }
        }
        else{
            System.debug('Sync is disabled from custom settings');
        }
    }
}