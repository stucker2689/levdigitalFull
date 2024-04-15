/**
 * Created by jmahapatra on 11/13/17.
 */

public with sharing class RepliconClientUpsert implements Queueable, Database.AllowsCallouts
{
    private String accountId;

    public RepliconClientUpsert(String accountId) {
        this.accountId = accountId;
    }

    public void execute(QueueableContext sc) {
        Boolean syncReplicon = false;
        List<EnableReplicon__c> obj = [Select IsActiveProject__c from EnableReplicon__c];
        if(obj.size()>0)
        {
            if(obj[0].IsActiveProject__c==true){
                syncReplicon = true;
            }
        }
        if(syncReplicon) {
            // query client data
            System.debug('**** Creating Client');
            Replicon.Client client = Replicon.getClientById(this.accountId);
            //System.debug(client);
            RepliconService service = new RepliconService();
            service.upsertClient(client, this.accountId);
        }
        else{
            System.debug('Sync is disabled from custom settings');
        }
    }
}