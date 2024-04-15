/**
 * Created by jmahapatra on 3/9/18.
 */

global class GdriveSyncScheduler implements Schedulable {

    global void execute(SchedulableContext ctx){
        //GdriveSync.processInovoices();
        List<GooleDriveSync__mdt> keyVals = [select DeveloperName,Value__c from GooleDriveSync__mdt WHERE DeveloperName = 'BatchSize']  ;
        string BatchSize = '';
        if(keyVals.size()>0) {
            BatchSize = keyVals[0].Value__c;
        }else{
            BatchSize = '10';
        }
        Database.executeBatch(new BatchGDriveSync(),Integer.valueOf(BatchSize));
    }

   // Public static void SchedulerMethod() {
       // string timeinterval = '0 5 * * * ?';
       // System.schedule('GDrive Sync - Every hours plus 5 mins',timeinterval, new GdriveSyncScheduler());
    //}
}