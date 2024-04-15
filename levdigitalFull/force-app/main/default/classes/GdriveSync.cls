/**
 * Created by jmahapatra on 3/9/18.
 */

public with sharing class GdriveSync {

    public GdriveSync(){
        System.debug('Google Drive Sync Started');
    }

    @future (callout=true)
    public static void processInovoices(){

        Map<String,String> keyPair = driveLogin();
        System.debug('keyPair'+keyPair);

        String emailId = keyPair.get('email_id');

        List<JsonObj> listFiles = searchDrive(keyPair);
        //System.debug('listFiles: '+listFiles);

        Map<String,Blob> blobFiles = new Map<String,Blob>();

        for(JsonObj file:listFiles){
            String id = file.id;
            Blob pdfData = getDriveFileContent(file.id, keyPair);
            deleteFilefromGDrive(file.id,file.name, keyPair);
            blobFiles.put(id,pdfData);
            //System.debug('blobFiles: '+blobFiles);
        }
        String emailBody='';

        for(JsonObj file:listFiles)
        {
            String name = file.name.toLowerCase();
            name = name.substring(0,name.length()-4);
            String[] oppInvoice = name.split('inv');
            String invoice = oppInvoice[1].trim();

            String[] opps = oppInvoice[0].split('sow');
            String sow = 'SOW'+opps[1].trim();

            sow = sow.replace(' ','');
            invoice = invoice.replace(' ','');

            List<Invoice__c> invoices = [select Id,Name,ApprovedBy__c,DateApproved__c,Status__c from Invoice__c Where InvoiceNum__c=:invoice];
            System.debug('Invoce: '+invoices);
            String resp;


            if(invoices.size()==0)
            {
                //Search Opportuinty, project and create new

                List<Opportunity> ops = [Select Id,Name,Account.Id,Account.Name,OwnerId from Opportunity Where SOW_Number__c=:sow];
                //System.debug('Opportunities: '+ops);

                if(ops.size()==1)
                {

                    Opportunity op = ops[0];
                    List<Project__c> projects = [Select Id, Name,Project_Manager__c, Account__c,Account__r.Name from Project__c where Opportunity__c=:op.Id];
                    //Project__c project = [Select Id, Name,Project_Manager__c, Account__c,Account__r.Name from Project__c where Opportunity__c=:op.Id];

                    if(projects.size()==1)
                    {
                        try {
                            Project__c project = projects[0];

                            String userId='';
                            if (String.isBlank(project.Project_Manager__c)) {
                                userId = op.OwnerId;
                            } else {
                                userId = project.Project_Manager__c;
                            }
                            if(checkUserIsActive(userId)==false){
                                //generateEmail(emailId, 'Assigned User is inactive', 'Assigned user in approval process found inactive. Please assign to right user');
                                emailBody+='Assigned User is inactive<br/>Assigned user in approval process found inactive. Please assign to right user';

                            }

                            Blob pdfData = blobFiles.get(file.id);
                            //System.debug('*** '+invoice + ' for ' + project.Account__r.Name);
                            Invoice__c inv = new Invoice__c();
                            inv.Name = invoice + ' for ' + project.Account__r.Name;
                            inv.Project__c = project.Id;
                            inv.Account__c = project.Account__c;
                            inv.ProjectManager__c = userId;
                            inv.InvoiceNum__c = invoice;
                            inv.Status__c = 'Draft';
                            insert inv;

                            try {

                                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                req.setComments('Submitting request for approval');
                                req.setObjectId(inv.Id);
                                Approval.ProcessResult result = Approval.process(req);
                            } catch (DmlException ex) {
                                //generateEmail(emailId, 'Error in Approval Process, No Approver/PM is available', ex.getMessage());
                                emailBody+= '<br/><br/> Error in Approval Process, No Approver/PM is available';

                            }

                            //Create Chatter Feed

                            contentVersion cv = new contentversion();
                            cv.versionData = pdfData;
                            cv.title = file.name;
                            cv.pathOnClient = file.name;
                            cv.Description = inv.Id;
                            insert cv;

                            ContentVersion cd = [select Id,title, Description,ContentDocumentId from contentVersion where Id=:cv.Id];

                            ContentDocumentLink link = new ContentDocumentLink();
                            link.LinkedEntityId = inv.Id;
                            link.ContentDocumentId = cd.ContentDocumentId;
                            link.ShareType ='V';
                            insert link;

                            //create and insert post
                            /*FeedItem post = new FeedItem();
                            post.Body = 'New Invoice added';
                            post.ParentId = inv.Id;
                            post.Title = 'Invoice ';
                            insert post;

                            //create and associate a content attachment to the post
                            FeedAttachment feedAttachment = new FeedAttachment();
                            feedAttachment.FeedEntityId = post.Id;
                            feedAttachment.RecordId = cv.id;
                            feedAttachment.Type = 'CONTENT';
                            insert feedAttachment;*/
                        }
                        catch(Exception ex){
                            System.debug(ex.getMessage());
                        }
                    }
                    else{
                        if(!Test.isRunningTest())
                        //generateEmail(emailId,'A Project for '+sow+' could not be found','A Project for '+sow+' could not be found');
                        emailBody+='<br/><br/>'+'A Project for '+sow+' could not be found';
                    }

                }
                else if (ops.size()>1){
                    if(!Test.isRunningTest())
                    //generateEmail(emailId,'Mupltiple Opportunity for '+sow+' found','Mupltiple Opportunity for '+sow+' found');
                    emailBody+='<br/><br/>'+'A Project for '+sow+' could not be found';
                }
                else {
                    if(!Test.isRunningTest())
                    //generateEmail(emailId,'An Opportunity for '+sow+' could not be found','An Opportunity for '+sow+' could not be found');
                    emailBody+='<br/><br/>'+'An Opportunity for  '+sow+' could not be found';
                }
            }
            else if(invoices.size()>1){
                if(!Test.isRunningTest())
                //generateEmail(emailId,'Multiple Invoices fonund with '+invoice,'Multiple Invoices fonund with '+invoice);
                emailBody+='<br/><br/>'+'Multiple Invoices fonund with '+invoice+' ';
            }

            else{
            /*
            	Delete the existing file on the Invoice record and upload this new one
            	If Status = "Draft" then execute the Submit for Approval for the Invoice
            	Delete the file in the folder
             */
                System.debug('Invoice Found, Deleting existing invoice file');

                //Blob pdfData = getDriveFileContent(file.id,keyPair);
                //deleteFilefromGDrive(file.id,keyPair);
                Blob pdfData = blobFiles.get(file.id);

                Invoice__c inv = invoices[0];

                /*List<ContentVersion> cvDels = [select Id,title, Description,ContentDocumentId from contentVersion where Description=:inv.Id];

                for (ContentVersion cvDel:cvDels){
                    List<ContentDocumentLink> ft = [select Id from ContentDocumentLink where ContentDocumentId = :cvDel.ContentDocumentId];
                    delete ft;
                }*/
                
                List<ContentDocumentLink> clink = [select Id from ContentDocumentLink where LinkedEntityId = :inv.Id];
                delete clink;
                
                //List<FeedItem> p = [Select Id from FeedItem where parentId=:inv.Id];
                //delete p;
                
                contentVersion cv = new contentversion();
                cv.versionData = pdfData;
                cv.title = file.name;
                cv.pathOnClient = file.name;
                cv.Description = inv.Id;
                insert cv;

                ContentVersion cd = [select Id,title, Description,ContentDocumentId from contentVersion where Id=:cv.Id];

                ContentDocumentLink link = new ContentDocumentLink();
                link.LinkedEntityId = inv.Id;
                link.ContentDocumentId = cd.ContentDocumentId;
                link.ShareType ='V';
                insert link;

                //create and insert post
                /*FeedItem post = new FeedItem();
                post.Body = 'New Invoice added';
                post.ParentId = inv.Id;
                post.Title = 'Invoice';

                insert post;

                //create and associate a content attachment to the post
                FeedAttachment feedAttachment = new FeedAttachment();
                feedAttachment.FeedEntityId = post.Id;
                feedAttachment.RecordId = cv.id;
                feedAttachment.Type = 'CONTENT';
                insert feedAttachment;*/

                try {
                    if(inv.Status__c.equalsIgnoreCase('draft') || inv.Status__c.equalsIgnoreCase('rejected')) {
                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                        req.setComments('Submitting request for approval');
                        req.setObjectId(inv.Id);
                        Approval.ProcessResult result = Approval.process(req);
                    }
                }
                catch(DmlException ex){
                    generateEmail(emailId,'Error in Approval Process, No Approver/PM is available',ex.getMessage());
                }
            }

            System.debug('resp: '+resp);
        }
        if(String.isNotBlank(emailBody)){
            System.debug('Issue: '+emailBody);
            generateEmail(emailId,'Found Issue On Invoicing', emailBody);
        }
        System.debug('Google Drive Sync Completed');
    }

    private static Blob getDriveFileContent(String fileId,Map<String,String> keyPair){

        String access_token = keyPair.get('access_token');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/drive/v3/files/'+fileId+'?alt=media');
        req.setMethod('GET');

        req.setHeader('Authorization', 'Bearer '+access_token);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        Http h = new Http();
        HttpResponse response = h.send(req);
        return response.getBodyAsBlob();
    }

    /*private static void deleteFilefromGDrive2(String fileId,String fileName,Map<String,String> keyPair){
        String access_token = keyPair.get('access_token');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/drive/v3/files/'+fileId);
        req.setMethod('DELETE');
        req.setHeader('Authorization', 'Bearer '+access_token);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        Http h = new Http();
        HttpResponse response = h.send(req);
        System.debug('Deleteing file: '+response.getBody());
    }*/

    private static void deleteFilefromGDrive(String fileId,String fileName,Map<String,String> keyPair){
        String access_token = keyPair.get('access_token');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/drive/v2/files/'+fileId);
        req.setMethod('POST');
        req.setHeader('X-HTTP-Method-Override','PATCH');
        req.setHeader('Authorization', 'Bearer '+access_token);
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"title":"Processed'+fileName.replace(' ','')+'"}');
        Http h = new Http();
        HttpResponse response = h.send(req);
        //System.debug('Deleteing file: '+response.getBody());
    }

    private static Boolean checkUserIsActive(String userId){
        List<User> users = [select Id from User where Id=:userId and IsActive=true];
        if(users.size()>0){
            return true;
        }
        return false;
    }

    @TestVisible
    private static void generateEmail(String to, String subject, String messageBody){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new String[]{to});
        message.setSubject(subject);
        message.setHtmlBody(messageBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
    }

    @TestVisible
    private static List<JsonObj> searchDrive(Map<String,String> keyPair){

        String access_token = keyPair.get('access_token');

        String  root_folder='';

        if(keyPair.containsKey('folder_id')){
            root_folder = keyPair.get('folder_id');
        }
        System.debug('Root Folder: '+root_folder);

        Datetime dt = System.now().addDays(-7);
        String GMTDate =  dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        String q = '\''+root_folder+'\' in parents and createdTime>=\''+GMTDate+'\' and not name contains \'Processed\'' ;

        String searchString = EncodingUtil.urlEncode(q,'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/drive/v3/files?q='+searchString);
        req.setMethod('GET');

        req.setHeader('Authorization', 'Bearer '+access_token);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        Http h = new Http();
        HttpResponse response = h.send(req);

        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        List<Object> files = (List<Object>) dMap.get('files');
        List<JsonObj> listFiles = new List<JsonObj>();
        if(files.size()>0)
        {
            for(Integer i=0;i<files.size();i++){
                String js = JSON.serialize(files[i]);
                JsonObj myobj = (JsonObj) JSON.deserialize(js,JsonObj.class);
               //System.debug('fileid: '+ myobj.id);
               //System.debug('filekind: '+ myobj.kind);
                listFiles.add(myobj);
            }
        }

        System.debug('listFiles'+listFiles);
        return listFiles;
    }

    @TestVisible
    private static Map<String, String> driveLogin(){

        List<GooleDriveSync__mdt> keyVals = [select DeveloperName,Value__c from GooleDriveSync__mdt];

        Map<String,String> KeyMaps = new Map<String, String>();
        if(keyVals.size()>0) {
            for (GooleDriveSync__mdt obj : keyvals) {
                KeyMaps.put(obj.DeveloperName, obj.Value__c);
            }
        }
        else{
//            KeyMaps.put('client_secret', '8dJFBRLs_3lfCGMMggnkG-n0');
//            KeyMaps.put('refresh_token', '1/qLfwkzVqaD-UzbuLSib8vGfVXVp_pKQJlzGMI0XvWEd_xEs0KuaMEbARkp1H3cRY');
//            KeyMaps.put('client_id', '146722025060-hae4im9vo106cttcjcg0p1hal18u14jc.apps.googleusercontent.com');
//            KeyMaps.put('auth_url', 'https://www.googleapis.com/oauth2/v4/token');
//            KeyMaps.put('email_id', 'jmahapatra@levementum.com');

            KeyMaps.put('client_secret', 'g3WmRJ_Oe1ywCCIZJ54O8ovu');
            KeyMaps.put('refresh_token', '1/Hjw0FoEFAw0ROFaEytHjHYFIawbntDajooosgOa8NlQ');
            KeyMaps.put('client_id', '146722025060-tq0pq9kp5ii8jivl4ocm96m3u4llrtnf.apps.googleusercontent.com');
            KeyMaps.put('auth_url', 'https://www.googleapis.com/oauth2/v4/token');
            KeyMaps.put('email_id', 'jmahapatra@levementum.com');
            KeyMaps.put('folder_id', '1wxEQ4OJ7KesBIhr8JN4bwC1SZcYp9682');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(KeyMaps.get('auth_url'));
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('client_secret='+KeyMaps.get('client_secret')+'&grant_type=refresh_token&refresh_token='+KeyMaps.get('refresh_token')+'&client_id='+KeyMaps.get('client_id')+'');

        Http h = new Http();
        HttpResponse response = h.send(req);
        Map<String, Object> dMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        Map<String,String> keyPair = new Map<String, String>();
        keyPair.put('access_token',String.valueOf(dMap.get('access_token')));
        keyPair.put('token_type',String.valueOf(dMap.get('token_type')));
        keyPair.put('email_id',KeyMaps.get('email_id'));
        keyPair.put('folder_id',KeyMaps.get('folder_id'));

        return keyPair;
    }

    public class JsonObj{
        public String id {get; set;}
        public String mimeType {get; set;}
        public String kind {get; set;}
        public String name {get; set;}
    }

}