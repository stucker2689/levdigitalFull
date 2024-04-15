global with sharing class BatchGDriveSync implements Database.Batchable <SObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<String, String> keyPair;
    public String errors = '';
    public String warnings = '';
    public String emailId = '';

    public BatchGDriveSync() {}

    /** 
     *
     * @param keyPair:  Google Drive Integration Parameters
     * @param errors:   Errors Propagated from previous batch
     */
    public BatchGDriveSync(Map<String, String> keyPair, String errors) {
        this.keyPair = keyPair;system.debug(keyPair);
        this.errors += errors;
        this.emailId = keyPair.get('email_id');
    }

    /**
     *
     * @param BC:   BatchableContext automatically executed by Salesforce
     *
     * @return:     Invoices to Process (i.e. Unprocessed Status)
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, ID__c, Kind__c, Name, Filename__c, MimeType__c, Status__c ' +
                                        'FROM Invoices_to_Process__c ' +
                                        'WHERE Status__c IN (\'Unprocessed\', \'Error\')');
    }

    /**
     *
     * @param BC:       BatchableContext automatically executed by Salesforce
     * @param scope:    Invoices to process
     */
    public void execute(Database.BatchableContext BC, List<Invoices_to_Process__c> scope) {
        try {
            System.debug('*** Start Execute ***');

            Map<String, Blob> blobFiles = new Map<String, Blob>();
            List<Invoices_to_Process__c> processedInvoices = new List<Invoices_to_Process__c>();

            for (Invoices_to_Process__c file : scope) {
                String id = file.ID__c;
                Blob pdfData = GoogleDriveRestService.getDriveFileContent(file.ID__c, keyPair);
                GoogleDriveRestService.deleteFilefromGDrive(file.ID__c, file.Filename__c, keyPair);
                blobFiles.put(id, pdfData);
                processedInvoices.add(file);
            }

            for(Invoices_to_Process__c invp : processedInvoices) {
                invp.Status__c = 'Complete';
            }system.debug(processedInvoices);
            update processedInvoices;

            String emailBody = '';

            for (Invoices_to_Process__c file : scope) {

                String name = file.Filename__c.toLowerCase();
                name = name.substring(0, name.length() - 4);
                String[] oppInvoice = name.split('inv');
                String invoice = oppInvoice[1].trim();
                System.debug('inv num ' + invoice);

                String[] opps = oppInvoice[0].split('sow');
                String sow = 'SOW' + opps[1].trim();

                sow = sow.replace(' ', '');
                invoice = invoice.replace(' ', '');
                system.debug('sow ' + sow);

                List<Invoice__c> invoices = [
                        SELECT Id,Name,ApprovedBy__c,DateApproved__c,Status__c
                        FROM Invoice__c
                        WHERE InvoiceNum__c = :invoice
                ];
                System.debug('Invoice: ' + invoices);

                if (invoices.size() == 0) {
                    List<Opportunity> ops = [
                            SELECT Id,Name,Account.Id,Account.Name,OwnerId
                            FROM Opportunity
                            WHERE SOW_Number__c = :sow
                    ];

                    if (ops.size() == 1) {
                        Opportunity op = ops[0];
                        List<Project__c> projects = [
                                SELECT Id, Name, PM_s_Manager__c, Project_Manager__c, Account__c,Account__r.Name, Project__c.Project_Manager__r.Manager.Id
                                FROM Project__c
                                WHERE Opportunity__c = :op.Id
                        ];

                        if (projects.size() == 1) {
                            try {
                                Project__c project = projects[0];

                                String userId = '';
                                if (String.isBlank(project.Project_Manager__c)) {
                                    userId = op.OwnerId;
                                } else {
                                    userId = project.Project_Manager__c;
                                }
                                if (checkUserIsActive(userId) == false) {
                                    emailBody += 'Assigned User is inactive<br/>Assigned user in approval process found inactive. Assigning to PM\'s Manager for the following invoice number: ' + invoice;
                                    userId = project.Project_Manager__r.Manager.Id; 
                                }

                                Blob pdfData = blobFiles.get(file.ID__c);
                                Invoice__c inv = processInvoices(invoice, project, userId);
                                if(inv != null) {
                                    try {

                                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                        req.setComments('Submitting request for approval');
                                        req.setObjectId(inv.Id);
                                        Approval.ProcessResult result = Approval.process(req);
                                    } catch (DmlException ex) {
                                        emailBody += '<br/><br/> Error in Approval Process, No Approver/PM is available';
                                    }

                                    ContentVersion cv = processContentVersions(pdfData, file, inv);
                                    ContentVersion cd = [
                                            SELECT Id,Title, Description,ContentDocumentId
                                            FROM ContentVersion
                                            WHERE Id = :cv.Id
                                    ];
                                    ContentDocumentLink link = processContentDocumentLinks(inv, cd);
                                    processedInvoices.add(file);
                                }
                            } catch (Exception ex) {
                                processErrors(ex, 'execute', 'WARN');
                            }
                        } else {
                            if (!Test.isRunningTest()) {
                                emailBody += '<br/><br/>' + 'A Project for ' + sow + ' could not be found';
                            }
                        }
                    } else if (ops.size() > 1) {
                        if (!Test.isRunningTest()) {
                            emailBody += '<br/><br/>' + 'A Project for ' + sow + ' could not be found';
                        }
                    } else {
                        if (!Test.isRunningTest()) {
                            emailBody += '<br/><br/>' + 'An Opportunity for  ' + sow + ' could not be found';
                        }
                    }
                } else if (invoices.size() > 1) {
                    if (!Test.isRunningTest()) {
                        emailBody += '<br/><br/>' + 'Multiple Invoices fonund with ' + invoice + ' ';
                    }
                } else {
                    /*
                        Delete the existing file on the Invoice record and upload this new one
                        If Status = "Draft" then execute the Submit for Approval for the Invoice
                        Delete the file in the folder
                     */
                    System.debug('Invoice Found, Deleting existing invoice file');

                    //Blob pdfData = getDriveFileContent(file.id,keyPair);
                    //deleteFilefromGDrive(file.id,keyPair);
                    Blob pdfData = blobFiles.get(file.ID__c);
                    Invoice__c inv = invoices[0];
                    List<ContentDocumentLink> clink = [
                            SELECT Id
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId = :inv.Id
                    ];
                    delete clink;

                    ContentVersion cv = processContentVersions(pdfData, file, inv);

                    ContentVersion cd = [
                            SELECT Id,Title, Description,ContentDocumentId
                            FROM ContentVersion
                            WHERE Id = :cv.Id
                    ];

                    ContentDocumentLink link = processContentDocumentLinks(inv, cd);

                    try {
                        if (inv.Status__c.equalsIgnoreCase('draft') || inv.Status__c.equalsIgnoreCase('rejected')) {
                            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                            req.setComments('Submitting request for approval');
                            req.setObjectId(inv.Id);
                            Approval.ProcessResult result = Approval.process(req);
                        }
                    } catch (DmlException ex) {
                        System.debug(ex.getMessage());
                        processWarnings(ex, 'generateEmail', 'WARN', 'Error in Approval Process, No Approver/PM is available');
                        generateEmail(emailId, 'Error in Approval Process, No Approver/PM is available', ex.getMessage());
                    }
                }
            }

            if (String.isNotBlank(emailBody)) {
                System.debug('Issue: ' + emailBody);
                processWarnings(null, 'execute', 'WARN', emailBody);
                generateEmail(emailId, 'Found Issue On Invoicing', emailBody);
            }
            System.debug('Google Drive Sync Completed');
        } catch(Exception ex) {
            system.debug(ex.getStackTraceString());
            processErrors(ex, 'execute', 'ERROR');
        }
    }

    public void finish(Database.BatchableContext BC) {

        System.debug('*** Finish ****');
        String emailbody = '';
        if (!Test.isRunningTest()) {
            System.debug('JobId ' + BC.getJobId());

            AsyncApexJob job = [
                    SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                    FROM AsyncApexJob
                    WHERE Id = :BC.getJobId()
            ];
            Integer numOfJobs = 0;
            numOfJobs = Integer.valueOf(job.TotalJobItems);
            Integer numofErrors = 0;
            numofErrors = Integer.valueOf(job.NumberOfErrors);

            if (numOfJobs > 0 || numofErrors > 0) {
                emailbody = 'BatchGDriveSync: number of JobItems: ' + job.TotalJobItems + ' And Number of Failures ' + job.NumberOfErrors;
                emailbody += '<br>' + errors;
                generateEmail(emailId, 'Batch Results', emailBody);
            } else {
                generateEmail(emailId, 'Batch Results', errors);
            }
        }
    }

    private static Boolean checkUserIsActive(String userId) {
        List<User> users = [
                SELECT Id
                FROM User
                WHERE Id = :userId AND IsActive = TRUE
        ];
        if (users.size() > 0) {
            return true;
        }
        return false;
    }

    @TestVisible
    private void generateEmail(String to, String subject, String messageBody) {
        try {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new String[]{
                    to
            });
            message.setSubject(subject);
            message.setHtmlBody(messageBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    message
            });
        } catch(EmailException ex) {
            processErrors(ex, 'generateEmail', 'ERROR');
        }
    }

    public Invoice__c processInvoices(String invoice, Project__c project, String userId) {
        Invoice__c inv = new Invoice__c();
        try {
            String nameInv = invoice + ' for ' + project.Account__r.Name;
            if(nameInv.length() >= 80) {
                inv.Name = nameInv.left(80);
            } else {
                inv.Name = nameInv;
            }
            inv.Project__c = project.Id;
            inv.Account__c = project.Account__c;
            inv.ProjectManager__c = userId;
            inv.InvoiceNum__c = invoice;
            inv.Status__c = 'Draft';
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.allowFieldTruncation = true;
            Database.insert(inv, dmo);
        } catch(Exception ex) {
            processErrors(ex, 'processInvoices', 'WARN');
            return null;
        }
        return inv;
    }

    public ContentVersion processContentVersions(Blob pdfData, Invoices_to_Process__c file, Invoice__c inv) {
        ContentVersion cv = new ContentVersion();
        try {
            //Create Chatter Feed
            cv.VersionData = pdfData;
            cv.Title = file.Filename__c;
            cv.PathOnClient = file.Filename__c;
            cv.Description = inv.Id;
            insert cv;
        } catch(Exception ex) {
            system.debug(ex.getMessage() + ' ' + ex.getStackTraceString());
            processErrors(ex, 'processContentVersions', 'ERROR');
            return null;
        }
        return cv;
    }

    public ContentDocumentLink processContentDocumentLinks(Invoice__c inv, ContentVersion cd) {
        ContentDocumentLink link = new ContentDocumentLink();
        try {
            link.LinkedEntityId = inv.Id;
            link.ContentDocumentId = cd.ContentDocumentId;
            link.ShareType = 'V';
            insert link;
        } catch(Exception ex) {
            processErrors(ex, 'processContentDocumentLinks', 'ERROR');
            return null;
        }
        return link;
    }

    public void processErrors(Exception ex, String function, String level) {
        try {
            Error_Log__c err = new Error_Log__c();
            err.Error__c = ex.getMessage() + '. ' + ex.getStackTraceString();
            err.File__c = 'BatchGDriveSync';
            err.function__c = function;
            err.Level__c = level;
            errors += err.Error__c + '<br>';
            insert err;
        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    public void processWarnings(Exception ex, String function, String level, String message) {
        try {
            Error_Log__c err = new Error_Log__c();
            if(ex != null) {
                err.Error__c = message.replaceAll('<br/>', '') + '. ' + ex.getMessage() + '. ' + ex.getStackTraceString();
            } else {
                err.Error__c = message.replaceAll('<br/>', '');
            }
            err.File__c = 'BatchGDriveSync';
            err.function__c = function;
            err.Level__c = level;
            errors += err.Error__c + '<br>';
            insert err;
        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}