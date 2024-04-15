/*
TemporaryRateScheduledEmailReport tempRateAlertEmail = new TemporaryRateScheduledEmailReport();
Id scheduledEmailJobId = System.schedule('Scheduled Email Test', '0 30 12 ? * TUE', tempRateAlertEmail);
*/

public with sharing class TemporaryRateScheduledEmailReport implements Schedulable{
    
    public void execute(SchedulableContext sc){
        scheduleJob();
    }

    //@future(callout=true)
    public static void scheduleJob(){
        String reportId;
        if(!Test.isRunningTest()){
            Report tempRateReport = [SELECT Id, Name, DeveloperName FROM Report WHERE DeveloperName = 'Temporary_Rate_Project_Time_Entries_YmN' LIMIT 1];
            reportId = tempRateReport.Id;
        }else{
            reportId = 'abcdefg12345';
        }
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        User samUser = [SELECT Id, Name, Email FROM User WHERE Email = 'samuel.tucker@cognizant.com' LIMIT 1];       
        
        message.setSubject('ACTION NEEDED: Weekly User Billing Rate Audit - Projects using "Temporary Rate"');

        String emailBody = 'Hi everyone, ';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'We have found missing billing rates on the below projects (for possibly both actual team members and/or placeholders), which means these have now been assigned the "Temporary Rate" of $210.';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'We need the assistance of each PM listed below with updating these user\'s billing rate assignments <b style="color:red;">TODAY</b> to ensure the proper rate is assigned, as these billing rate assignments will be reflected in PeopleSoft / ESA. If users are not assigned a real billing rate, their assignment will not be created in PeopleSoft properly and timesheets may be delayed.';
        emailBody += '<br/>' + '<br/>';
        emailBody += 'Please reference this ' + '<b><a href="' + Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Report/' + reportId + '/view">Salesforce Report</a></b>' + ' for your Project(s) impacted.';
        emailBody += '<br/>' + '<br/>' + '<br/>';
        emailBody += '<i>This is an automated report.</i>';
        emailBody += '<br/>' + '<br/>';

        List<String> pmEmailsList = new List<String>();
        /**Create Table of Report **/
        List<Replicon_Time_Entry__c> tempRateEntryList = new List<Replicon_Time_Entry__c>();
        AggregateResult[] tempRateAggregate;
        tempRateAggregate = [SELECT Project__r.Name projName, Project__r.Project_Manager__c pmId, Project__r.Project_Manager__r.Name pmName, Project__r.Project_Manager__r.Email pmEmail, Project__r.Project_Manager__r.ManagerId pmManagerId, Project__r.Project_Manager__r.Manager.Email pmManagerEmail, 
                                    Employee__r.Name empName, Associated_Billing_Rate__r.Name rateName,  Employee__r.ReportsToId employeeManagerId, Employee__r.ReportsTo.Email employeeManagerEmail, SUM(TotalHrs__c) totalHrs
                                FROM Replicon_Time_Entry__c
                                WHERE Project__r.Project_Status__c IN ('Not Started', 'Active') AND Account__r.Name != 'ABC Lev Test' AND Associated_Billing_Rate__r.Name = 'Temporary Rate' AND Deleted_in_Replicon__c = false
                                    AND EntryDate__c >= LAST_N_WEEKS:4
                                GROUP BY Project__r.Name, Project__r.Project_Manager__c, Project__r.Project_Manager__r.Name, Project__r.Project_Manager__r.Email, Project__r.Project_Manager__r.ManagerId, Project__r.Project_Manager__r.Manager.Email, Employee__r.Name, Associated_Billing_Rate__r.Name,  Employee__r.ReportsToId, Employee__r.ReportsTo.Email
                                ORDER BY Project__r.Name];


        String htmlTableBody;
        htmlTableBody = '<table border="1" style="border-collapse: collapse"><title>Temporary Rate Time Entry Report</title>';
        htmlTableBody += '<tr style="background-color: #abc6ed"><th>Project Name</th><th>Project Manager</th><th>Employee Name</th><th>Billing Rate Name</th><th>Total Hours Billed</th></tr>';
        Integer counter = 0;
        for(AggregateResult tempRate : tempRateAggregate){
            counter++;

            //Create Zebra Stripe Affect
            if(Math.mod(counter, 2) != 0){ //If Counter is odd
                htmlTableBody += '<tr style="background-color: #cce1ff; padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;"><td>' + tempRate.get('projName') + '</td><td>' + tempRate.get('pmName') + '</td>';
                htmlTableBody += '<td>' + tempRate.get('empName') + '</td><td>' + tempRate.get('rateName') + '</td><td>' + tempRate.get('totalHrs') + '</td></tr>';
            }else{
                htmlTableBody += '<tr style="padding-right: 40px; padding-left: 2px; padding-top: 2px; padding-bottom: 2px;"><td>' + tempRate.get('projName') + '</td><td>' + tempRate.get('pmName') + '</td>';
                htmlTableBody += '<td>' + tempRate.get('empName') + '</td><td>' + tempRate.get('rateName') + '</td><td>' + tempRate.get('totalHrs') + '</td></tr>';
            }

            if((String)tempRate.get('pmEmail') != null){
                pmEmailsList.add((String)tempRate.get('pmEmail'));
            }

            /*if((String)tempRate.get('employeeManagerId') != null && (String)tempRate.get('employeeManagerEmail') != null){
                pmEmailsList.add((String)tempRate.get('employeeManagerEmail'));
            }*/

            if((String)tempRate.get('pmManagerId') != null && (String)tempRate.get('pmManagerEmail') != null){
                pmEmailsList.add((String)tempRate.get('pmManagerEmail'));
            }
        }

        //pmEmailsList.add('samuel.tucker@cognizant.com');

        htmlTableBody += '</table>';
        /***************************************/

        emailBody += htmlTableBody;
        message.setHtmlBody(emailBody);

        System.debug('Send --'+ message); 
        if(pmEmailsList.size() > 0){  
            System.debug('Pm Email List: ' + pmEmailsList);
            message.setToAddresses(pmEmailsList);

            List<String> ccEmailList = new List<String>();
            List<User> ccUsersList = new List<User>();
            ccUsersList = [SELECT Id, Name, Email FROM User WHERE Name IN ('Lori Davis', 'Jamie Lindley', 'Raul Ventura', 'Becky Blair', 'Erin Wray', 'Sam Tucker', 'Michelle Murray', 'Ashley Herter') AND IsActive = true AND UserType = 'Standard'];
            for(User u : ccUsersList){
                if(u.Email != null){
                    ccEmailList.add(u.Email);
                }
            }

            if(ccEmailList.size() > 0){
                message.setCcAddresses(ccEmailList);
            }

            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@levdigital.com'];
            if ( owea.size() > 0 ) {
                message.setOrgWideEmailAddressId(owea.get(0).Id);
            }

            //message.setOrgWideEmailAddressId('0D20W000001Q7JpSAK');

            lstEmail.add(message); 
            if(!lstEmail.isEmpty()){
                Messaging.sendEmail(lstEmail); 
            }
        }

    }
}