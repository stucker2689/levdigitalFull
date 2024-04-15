/*
NonbillWeeklyCheck nonbillCheckRun = new NonbillWeeklyCheck();
System.schedule('Scheduled Nonbill Weekly Check', '0 30 13 ? * MON,TUE', nonbillCheckRun);
*/

public with sharing class NonbillWeeklyCheck implements Schedulable{
    
    public void execute(SchedulableContext sc){
        sendNonbillCheck();
    }

    public static void sendNonbillCheck(){
        
        //Get Report to link into the email
        String reportId;
        if(!Test.isRunningTest()){
            Report tempRateReport = [SELECT Id, Name, DeveloperName FROM Report WHERE DeveloperName = 'Weekly_Unapproved_Nonbill_Check_8K0' LIMIT 1];
            reportId = tempRateReport.Id;
        }else{
            reportId = 'abcdefg12345';
        }

        //Get Open Nonbill Cases
        List<Case> openNonbillCaseList = new List<Case>();
        //Question for Alysia, notes say that the case needs to have Concession Request > 0, so need some confirmation on what field that means in order to determine if the case is a concession or nonbill request
        openNonbillCaseList = [SELECT Id, Subject, RecordType.Name, Approved_Denied__c, Status, Project__c
                                FROM Case
                                WHERE RecordType.Name = 'Nonbill Request' AND Approved_Denied__c != 'Denied' AND Status NOT IN ('Closed', 'Completed', 'Cancelled') AND Total_Hours_Requested__c > 0];

        List<Id> projectIdsWithOpenNonbillCasesList = new List<Id>();
        for(Case c : openNonbillCaseList){
            projectIdsWithOpenNonbillCasesList.add(c.Project__c);
        }

        Date previousWeekEndDate = Date.today().toStartOfWeek().addDays(-1);
        //Get Nonbill Entry Data
        List<Replicon_Time_Entry__c> nonbillEntryList = new List<Replicon_Time_Entry__c>();
        nonbillEntryList = [SELECT Id, Name, Employee__r.Name, WeekEndDate__c, EntryDate__c, Is_Billable__c, TotalHrs__c , Project__r.Name, Project__r.Peoplesoft_Project_Id__c, ActivityName__c, Project__r.Project_Manager__r.Email, Comments__c, Employee__r.Email
                            FROM Replicon_Time_Entry__c
                            WHERE Deleted_in_Replicon__c = false AND Is_Billable__c = false AND WeekEndDate__c =: previousWeekEndDate AND Project__c != null AND Account__r.Name != 'Levementum LLC' 
                                AND Project__c NOT IN :projectIdsWithOpenNonbillCasesList AND ActivityName__c NOT IN ('BCP', 'Business Support') AND Employee__r.Weekly_Target__c != null AND Employee__r.Weekly_Target__c > 0
                                AND Opportunity__r.Program_Type__c != 'Email to Case'
                            ORDER BY Employee__r.Name, Project__r.Name, EntryDate__c];


        /**Create Email Body **/
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        //message.setSubject('TESTING PLEASE IGNORE: Unapproved Nonbill Time Logged Last Week');
        message.setSubject('ACTION NEEDED: Unapproved Nonbill Time Logged Last Week');
        String emailBody = 'Hello, ';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'As occurs each week, this is the non-bill check that previously occurred in Slack. This check reviews non-billable time logged last week that is not BCP or Business Support time, and also not part of an already submitted nonbill request in Salesforce. ';
        emailBody += '<b>If you are receiving this email, please review the screenshotted report below and update your timesheets to billable.</b> Please note, if you are a CSP and receiving this email, you may need to update the Activity in your timesheet to "BCP".';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'If you need to discuss this non-billable time further, please reply to Jamie Lindley on this email. Remember all nonbill requests need to be submitted through Salesforce by the PM or CSP before the time is logged.';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'Please reference this ' + '<b><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Report/' + reportId + '/view">Salesforce Report</a></b>' + ' for your Project(s) impacted.';
        emailBody += '<br/>' + '<br/>' + '<br/>';
        emailBody += '<i>This is an automated message.</i>';
        emailBody += '<br/>' + '<br/>';

        String htmlTableBody;
        //Table Column Headers
        htmlTableBody = '<table border="1" style="border-collapse: collapse"><title>Unapproved Nonbill Time Report</title>';
        htmlTableBody += '<tr style="background-color: #abc6ed">';
        htmlTableBody += '<th>Employee Name</th>';
        htmlTableBody += '<th>Period End Date</th>';
        htmlTableBody += '<th>Billing Action</th>';
        htmlTableBody += '<th>Hours</th>';
        htmlTableBody += '<th>Project ID</th>';
        htmlTableBody += '<th>Project Name</th>';
        htmlTableBody += '<th>Comments</th>';
        htmlTableBody += '<th>Activity Name</th>';
        htmlTableBody += '</tr>';

        Set<String> recipientEmailSet = new Set<String>();
        Set<String> pmEmailSet = new Set<String>();
        Integer counter = 0;
        for(Replicon_Time_Entry__c entry : nonbillEntryList){
            counter++;

            //Create Zebra Stripe Affect
            if(Math.mod(counter, 2) != 0){ //If Counter is odd

                String billableAction = 'U';
                String comments = '';
                if(entry.Comments__c != null){
                    comments = entry.Comments__c;
                }

                htmlTableBody += '<tr style="background-color: #cce1ff; padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;">';
                htmlTableBody += '<td>' + entry.Employee__r.Name + '</td>';
                htmlTableBody += '<td>' + entry.WeekEndDate__c.format() + '</td>';
                htmlTableBody += '<td>' + billableAction + '</td>';
                htmlTableBody += '<td>' + entry.TotalHrs__c + '</td>';
                htmlTableBody += '<td>' + entry.Project__r.Peoplesoft_Project_Id__c + '</td>';
                htmlTableBody += '<td>' + entry.Project__r.Name + '</td>';
                htmlTableBody += '<td>' + comments + '</td>';
                htmlTableBody += '<td>' + entry.ActivityName__c + '</td>';
                htmlTableBody += '</tr>';
            }else{

                String billableAction = 'U';
                String comments = '';
                if(entry.Comments__c != null){
                    comments = entry.Comments__c;
                }

                htmlTableBody += '<tr style="padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;">';
                htmlTableBody += '<td>' + entry.Employee__r.Name + '</td>';
                htmlTableBody += '<td>' + entry.WeekEndDate__c.format() + '</td>';
                htmlTableBody += '<td>' + billableAction + '</td>';
                htmlTableBody += '<td>' + entry.TotalHrs__c + '</td>';
                htmlTableBody += '<td>' + entry.Project__r.Peoplesoft_Project_Id__c + '</td>';
                htmlTableBody += '<td>' + entry.Project__r.Name + '</td>';
                htmlTableBody += '<td>' + comments + '</td>';
                htmlTableBody += '<td>' + entry.ActivityName__c + '</td>';
                htmlTableBody += '</tr>';
            }

            if(entry.Project__c != null && entry.Project__r.Project_Manager__c != null && entry.Project__r.Project_Manager__r.Email != null){
                pmEmailSet.add(entry.Project__r.Project_Manager__r.Email);
            }

            if(entry.Employee__c != null && entry.Employee__r.Email != null){
                recipientEmailSet.add(entry.Employee__r.Email);
            }
        }

        htmlTableBody += '</table>';
        emailBody += htmlTableBody;
        /*****************************************************************************************************************************************************************************************************************************************/

        message.setHtmlBody(emailBody);

        User samUser = [SELECT Id, Name, Email FROM User WHERE Email = 'samuel.tucker@cognizant.com' LIMIT 1];

        System.debug('Send --'+ message); 
        if(Test.isRunningTest()){
            String testEmail = 'testemail@gmail.com';
            recipientEmailSet.add(testEmail);
        }
        if(recipientEmailSet.size() > 0){  
            recipientEmailSet.add(samUser.Email);
            System.debug('Recipient Email List: ' + recipientEmailSet);
            List<String> recipientEmailList = new List<String>();
            recipientEmailList.addAll(recipientEmailSet);
            message.setToAddresses(recipientEmailList);

            List<User> manualCCEmailList = new List<User>();
            manualCCEmailList = [SELECT Id, Name, Email FROM User WHERE Name IN ('Jamie Lindley') AND IsActive = true AND UserType = 'Standard'];
            for(User u : manualCCEmailList){
                if(u.Email != null){
                    pmEmailSet.add(u.Email);
                }
            }

            List<String> pmEmailList = new List<String>();
            pmEmailList.addAll(pmEmailSet);
            if(pmEmailList.size() > 0){
                message.setCcAddresses(pmEmailList);
            }

            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@levdigital.com'];
            if ( owea.size() > 0 ) {
                message.setOrgWideEmailAddressId(owea.get(0).Id);
            }

            lstEmail.add(message); 
            if(!lstEmail.isEmpty()){
                Messaging.sendEmail(lstEmail); 
            }
        }

    }
}