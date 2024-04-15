/**
 * Created by wfrohwein on 8/28/18.
 */

global class GdriveInvoiceBatch implements Database.Batchable <String>, Database.AllowsCallouts, Database.Stateful {
    public static String emailId;
    public String errors = '';
    public Map<String, String> keyPair;

    global Iterable<String> start(Database.BatchableContext BC) {

        List<String> iterate = new List<String>();
        iterate.add('execute');
        return iterate;
    }

    global void execute(Database.BatchableContext BC, List<String> scope) {
        try {
            keyPair = GoogleDriveRestService.driveLogin();system.debug(keyPair);
            emailId = keyPair.get('email_id');
            List<GoogleDriveRestService.JsonObj> listFiles = GoogleDriveRestService.searchDrive(keyPair);
            List<Invoices_to_Process__c> itps = new List<Invoices_to_Process__c>();
            for (GoogleDriveRestService.JsonObj file : listFiles) {
                itps.add(new Invoices_to_Process__c(
                        Kind__c = file.kind,
                        ID__c = file.id,
                        Filename__c = file.name.left(131072),
                        Status__c = 'Unprocessed'
                ));
            }
            if (itps.size() > 0) {
                upsert itps ID__c;
            } else {
                Error_Log__c err = new Error_Log__c();
                err.Error__c = 'There are no invoices to process from Google Drive';
                err.File__c = 'GdriveInvoiceBatch';
                err.function__c = 'execute';
                err.Level__c = 'WARN';
                errors += err.Error__c + '<br>';
                insert err;
            }
        } catch(Exception ex) {Error_Log__c err = new Error_Log__c();err.Error__c = ex.getStackTraceString();err.File__c = 'GdriveInvoiceBatch';err.function__c = 'execute';err.Request__c = '';err.Response__c = '';err.Level__c = 'ERROR';errors += err.Error__c + '. ';insert err;}
    }

    global void finish(Database.BatchableContext BC) {

        try {
            List<GooleDriveSync__mdt> keyVals = [
                    SELECT DeveloperName,Value__c
                    FROM GooleDriveSync__mdt
                    WHERE DeveloperName = 'BatchSize'
            ] ;

            String BatchSize = '';

            if (keyVals.size() > 0) {
                BatchSize = keyVals[0].Value__c;
            } else {
                BatchSize = '10';
            }
            errors += GoogleDriveRestService.errors;
            Database.executeBatch(new BatchGDriveSync(keyPair, errors), Integer.valueOf(BatchSize));
        } catch(Exception ex) {Error_Log__c err = new Error_Log__c();err.Error__c = ex.getStackTraceString();err.File__c = 'GdriveInvoiceBatch';err.function__c = 'finish';err.Level__c = 'ERROR';errors += err.Error__c + '. ';insert err;}
    }
}