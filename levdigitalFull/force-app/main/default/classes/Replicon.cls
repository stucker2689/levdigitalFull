/**
 * Created by jmahapatra on 11/13/17.
 */

public with sharing class Replicon
{
    public static final Integer MAX_DESCRIPTION_CHARS = 255;
    
    public static Replicon.Project getProjectById(String projectId) {
        Project__c projectData = [
                SELECT Id, Name, Project_Status__c, Type__c, Project_Background_Objectives__c, TimeAndExpenseEntry__c, CreatedDate,
                        Planned_Go_Live_Date__c, RepliconUri__c, Project_Manager__r.RepliconLoginName__c, Account__r.Name,Account__r.RepliconClientUri__c,
                        Opportunity__r.SOW_Number__c, Opportunity__r.Total_Hours__c, Opportunity__r.Project_Terms__c,
                        Opportunity__r.Payment_Terms__c, Opportunity__r.Interested_In__c, Opportunity__r.LevementumVertical__c,
                        Opportunity__r.Create_Project__c,Opportunity__r.Opportunity_RecordType_Name__c,Opportunity__r.Start_Date__c,
                        Opportunity__r.End_Date__c,Opportunity__r.SubPractice__c,Opportunity__r.Amount,Opportunity__r.Opportunity_Amount_COs__c,
                        Opportunity__r.Geographical_Area__c,Project_Manager__r.Name,Opportunity__r.CloseDate, Opportunity__r.Payment_Schedule__c,
                        Opportunity__r.Change_Order_Revenue__c,Opportunity__r.Change_Order_Hours__c,Opportunity__r.Name
                FROM Project__c
                WHERE Id = :projectId
        ];

        return new Replicon.Project(projectData);
    }

    public static Replicon.Task getProjectTaskById(String projectId) {
        Project__c projectData = [
                SELECT Id, Name, Project_Status__c, Type__c, Project_Background_Objectives__c, TimeAndExpenseEntry__c, CreatedDate,
                        Planned_Go_Live_Date__c, RepliconUri__c, Project_Manager__r.RepliconLoginName__c, Account__r.RepliconClientUri__c,
                        Opportunity__r.Name,Opportunity__r.Description,Opportunity__r.SOW_Number__c, Opportunity__r.Total_Hours__c, Opportunity__r.Project_Terms__c,
                        Opportunity__r.Payment_Terms__c, Opportunity__r.Interested_In__c, Opportunity__r.LevementumVertical__c,Opportunity__r.Create_Project__c,
                        Opportunity__r.Id,Opportunity__r.StageName,Opportunity__r.Opportunity_RecordType_Name__c,Opportunity__r.Start_Date__c,
                        Opportunity__r.End_Date__c,Opportunity__r.SubPractice__c,Opportunity__r.Amount,Opportunity__r.Opportunity_Amount_COs__c,Opportunity__r.CloseDate,
                        Opportunity__r.Change_Order_Revenue__c,Opportunity__r.Change_Order_Hours__c,Project_Manager__r.Name,Opportunity__r.CO_Number__c
                FROM Project__c
                WHERE Id = :projectId
        ];

        return new Replicon.Task(projectData);

    }

    public static Replicon.Client getClientById(String accountId) {
        //JA 04.13.2018 ILP-3
        Account accountData = [
                SELECT Id, Name, RepliconClientUri__c, Phone, Fax, Website, Description,BillingStreet,Billingcity,
                        BillingState,BillingPostalCode,ShippingCity,ShippingStreet,ShippingState,
                        ShippingPostalCode,MSA_Number__c
                FROM Account
                WHERE Id = :accountId
        ];

        return new Replicon.Client(accountData);
    }

    public static List<OpportunityLineItem> OppLineItems(String oppId){
        List<OpportunityLineItem> ols = [select Opportunity.Name,Id,Name,UnitPrice from OpportunityLineItem where Opportunity.Id=:oppId];
        return ols;
    }

    private virtual class RObject {
        public String uri;
    }

    public class ProjectSummary {
        public String name;
        public String salesforceId;
        public Double billableHours;
        public Double nonBillableHours;
        public Double totalHours;
    }

    public class TimeOffEntry {
        public String username;
        public String timeOffMonth;
        public String department;
        public String type;
        public Date startDate;
        public Date endDate;
        public Decimal timeOffDays;
        public String approvalStatus;
        public String firstName;
        public String lastName;
        public String email;
    }

    public class TimeEntry {
        public String username;
        public String userId;
        public DateTime modifiedOn;
        public String projectName;
        public String entryId;
        public String activity;
        public Decimal hours;
        public String comments;
        public String taskId;
    }

    public class Task {
        public String name; // mapped to task name
        public String code; // mapped to opportunity sow
        public String description; // mapped to task objectives
        public TaskDateRange timeEntryDateRange;
        public Integer percentCompleted;
        public Boolean isTimeEntryAllowed;
        public TimeData estimatedHours;
        public Boolean isClosed;
        public CustomField[] customFieldValues;
        public String projectUri;
        public Replicon.Target target;
        public String costTypeUri;
        public String timeAndExpenseEntryTypeUri;
        public String[] assignedResources;
        public EstimatedCost estimatedCost;

        public Task()
        {
            customFieldValues = new CustomField[] {};
            timeEntryDateRange = new TaskDateRange();
            this.percentCompleted = 0;
            this.isTimeEntryAllowed = true;
        }
        public Task(Project__c p){

            this();

            this.target = new Replicon.Target();
            this.target.name = p.Name;
            this.target.uri=null;

            this.name = p.Opportunity__r.Name;
            this.code = p.Opportunity__r.CO_Number__c;
            
            if(p.Opportunity__r.Description != null) {
            	this.description = p.Opportunity__r.Description.length() > MAX_DESCRIPTION_CHARS ? 
            				       p.Opportunity__r.Description.substring(0, MAX_DESCRIPTION_CHARS) : p.Opportunity__r.Description;
            }

            this.isClosed = false;
            this.setPractice(p.Opportunity__r.SubPractice__c);
            this.setType('Change Order');
            this.setProjectTerms(p.Opportunity__r.Project_Terms__c);
            this.setPaymentTerms(p.Opportunity__r.Payment_Terms__c);

            this.timeEntryDateRange.startDate = this.convertDate(p.CreatedDate);
            this.timeEntryDateRange.endDate = this.convertDate(p.Planned_Go_Live_Date__c);
            this.timeEntryDateRange.relativeDateRangeUri = null;
            this.timeEntryDateRange.relativeDateRangeAsOfDate = null;
            this.costTypeUri = null;
            this.timeAndExpenseEntryTypeUri=null;
            this.assignedResources = new List<String>();
            this.estimatedCost = new Replicon.EstimatedCost(p.Opportunity__r.Change_Order_Revenue__c);
            this.setSowCo(String.valueOf(p.Opportunity__r.Opportunity_Amount_COs__c));
            if(String.isNotBlank(String.valueOf(p.Opportunity__r.Change_Order_Hours__c))){
                this.setEstimatedHours(p.Opportunity__r.Change_Order_Hours__c);
            }
            else{
                this.setEstimatedHours(0);
            }
            this.setBookdate(Datetime.valueOf(p.Opportunity__r.CloseDate+' 00:00:00'));
            this.setProjectManager(p.Project_Manager__r.Name);

        }
        public void setPractice(String value){
            Replicon.CustomField practice = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Ts-Practice-Url').uri__c));
            practice.text=null;//value;

            if(!String.isBlank(value)) {
                String key = 'Ts-Practice-'+value.replace(' ','-');
                practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
            }
            else if(value == 'SFDC-MC') {
                practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Ts-Practice-Marketing-Cloud').uri__c), null);
            }
            else{
                practice.text='Other';
                practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Ts-Practice-Other').uri__c), null);
            }

            customFieldValues.add(practice);
        }
        public void setType(String value) {
            Replicon.CustomField type = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Ts-Type-Url').uri__c));
            type.text=null;//value;
            type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Ts-Type-Change-Order').uri__c), null);
            customFieldValues.add(type);
        }
        public void setProjectTerms(String value) {
            Replicon.CustomField projectTerms = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Ts-Pr-Terms-Url').uri__c));
            projectTerms.text = null;//value;

            if(!String.isBlank(value)) {
                String key = 'Ts-Pr-Terms-'+value.replace(' ','-');
                if (!String.isBlank(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c))) {
                    projectTerms.text = null;//String.valueOf(RepliconDropdowns__c.getValues(key).value__c);
                    projectTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
                }
            }
            else{
                projectTerms.text = null;//'Time & Materials';
                projectTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Ts-Pr-terms-Time-and-Materials').uri__c), null);
            }

            customFieldValues.add(projectTerms);
        }
        public void setPaymentTerms(String value){
            Replicon.CustomField paymentTerms = new Replicon.CustomField('Payment Terms', String.valueOf(RepliconDropdowns__c.getValues('Ts-Payment-Terms-Url').uri__c));
            paymentTerms.text = null;//value;

            if(!String.isBlank(value)) {
                String key = 'Ts-Payment-Terms-'+value.replace(' ','-');
                System.debug('Key: '+key);
                if (!String.isBlank(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c))) {
                    paymentTerms.text = null;//String.valueOf(RepliconDropdowns__c.getValues(key).value__c);
                    paymentTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
                }
            }
            else{
                paymentTerms.text = null;//'Special';
                paymentTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Ts-Payment-Terms-Special').uri__c), null);
            }

            customFieldValues.add(paymentTerms);
        }
        private DateData convertDate(DateTime dateValue) {
            if(dateValue != null) {
                DateData data = new DateData();
                data.year = String.valueOf(dateValue.year());
                data.month = String.valueOf(dateValue.month());
                data.day = String.valueOf(dateValue.day());

                return data;
            }

            return null;
        }
        public void setProjectUri(String val){
            this.projectUri = val;
        }
        public void setSowCo(String value){
            Replicon.CustomField sow = new Replicon.CustomField(null,'urn:replicon-tenant:levementum:user-defined-field:2496b9bb-3207-4495-94e0-e1bb450f0c9c');
            sow.number_r = Decimal.valueOf(value);
            customFieldValues.add(sow);
        }
        public void setEstimatedHours(Decimal hours) {
            estimatedHours = new TimeData();
            List<string> hourStrings = String.valueOf(hours).split('\\.');
            if(hourStrings.size()==1){
                estimatedHours.hours = String.valueOf(hourStrings[0]);
                estimatedHours.minutes = '0';
            }
            if(hourStrings.size()>1){
                estimatedHours.hours = String.valueOf(hourStrings[0]);
                Decimal minutes = ((Decimal.valueOf(hourStrings[1])/100)*60).round();
                estimatedHours.minutes = String.valueOf(minutes);
            }
        }
        public void setBookdate(Datetime dt){
            System.debug('****** Task Book Date '+dt);
            Replicon.CustomField bookedDt = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:72876770-b198-4534-8102-d339492eded8');
            bookedDt.date_r = this.convertDate(dt);
            customFieldValues.add(bookedDt);
        }
        public void setProjectManager(String val){
            if(!String.isBlank(val)) {

                Replicon.CustomField manager = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:677c4a20-cd7f-42ff-9af3-ba986559c991');
                manager.text = val ;
                customFieldValues.add(manager);
            }
        }


        public override String toString() {
            return '{"project":{"uri":"'+this.projectUri+'","name":null,"parameterCorrelationId":null},"task":' + JSON.serialize(this).replace('date_r','date') + ',"unitOfWorkId": "change-order"}';
        }
    }

    public class Project {
        public ProjectInfo projectInfo;
        public Replicon.Target target;
        public Fixedbid fixedBid;
        public Project() {
        }
        public Project(Project__c p)
        {
            projectInfo = new ProjectInfo(p.Opportunity__r, p);
            target = new Replicon.Target();
            target.name = p.Name;

            if(String.isNotBlank(p.RepliconUri__c)) {
                target.uri = p.RepliconUri__c;
                target.name = null;
            }
            if(p.Opportunity__r.Opportunity_RecordType_Name__c.equalsIgnoreCase('service_contract'))
            {
                fixedBid = new Replicon.Fixedbid(p.Opportunity__c);
            }
        }

        public override String toString() {
            return '{"project":' + JSON.serialize(this).replace('date_r','date').replace('amount_r','amount').replace('currency_r','currency').replace('number_r','number') + '}';
        }
    }

    public class ProjectInfo {
        public String name; // mapped to project name
        public String code; // mapped to opportunity sow
        public String description; // mapped to project objectives
        public DateRange timeEntryDateRange;
        public ProjectStatusLabel projectStatusLabel;
        public Integer percentCompleted;
        //public Client client;
        public Program program; // mapped to opportunity levementum vertical
        public ProjectLeader projectLeader;
        public Boolean isTimeEntryAllowed;
        public TimeData estimatedHours;
        public Boolean isProjectLeaderApprovalRequired;
        public String billingTypeUri; // mapped to opportunity project terms
        public TimeAndMaterials timeAndMaterials;
        public CustomField[] customFieldValues;
        public EstimatedCost estimatedCost;
        public RClient client;

        /*public String costTypeUri;
        public String estimatedExpenses;
        public String budget;
        public String estimationModeUri;
        public String defaultBillingCurrency;*/

        public ProjectInfo() {
            timeAndMaterials = new Replicon.TimeAndMaterials();
            customFieldValues = new CustomField[] {};
            timeEntryDateRange = new DateRange();

            // set default values
            this.percentCompleted = 0;
            this.isTimeEntryAllowed = true;
            this.isProjectLeaderApprovalRequired = true;
        }

        public ProjectInfo(Opportunity o, Project__c p) {
            this();

            this.name = p.Name;
            this.code = o.SOW_Number__c;
            //this.description = p.Project_Background_Objectives__c;
            this.estimatedCost = new Replicon.EstimatedCost(o.Amount);

            Decimal estHour = 0;
            if(!String.isBlank(String.valueOf(o.Total_Hours__c))){
                estHour+=o.Total_Hours__c;
            }
            if(!String.isBlank(String.valueOf(o.Change_Order_Hours__c))){
                estHour+=o.Change_Order_Hours__c;
            }
            this.setEstimatedHours(estHour);
            this.setProjectTerms(o.Project_Terms__c);

            this.setPaymentTerms(o.Payment_Terms__c);
            this.setPractice(o.SubPractice__c);
            this.setType(p.Type__c);
            this.setSalesforceId(p.Id);
            this.setProgram(o.LevementumVertical__c);
            this.setGeo(o.Geographical_Area__c);
            //this.setProjectManger(p.Project_Manager__r.Name);
            this.setProjectLeader(p.Project_Manager__r.RepliconLoginName__c);
            this.setBookdate(Datetime.valueOf(o.CloseDate+' 00:00:00'));
            this.setPaymentSchedule(o.Payment_Schedule__c);

            String status = p.Project_Status__c;

            if(status.equalsIgnoreCase('Not Started') || status.equalsIgnoreCase('Active') || status.equalsIgnoreCase('On Hold')){
                status ='In Progress';
            }
            else if(status.equalsIgnoreCase('Completed')){
                status ='Completed';
            }
            else{
                status ='Cancelled';
            }

            this.setStatus(status);


            if(!String.isBlank(p.Account__r.RepliconClientUri__c))
            {
                this.setClient(p.Account__r.RepliconClientUri__c,null);
            }
            else{
                this.setClient(null,p.Account__r.Name);
            }

            this.setBillingType(o.Project_Terms__c,String.valueOf(o.Opportunity_RecordType_Name__c));

            if(o.Opportunity_RecordType_Name__c.equalsIgnoreCase('Service_Contract')){
                this.timeEntryDateRange.startDate = this.convertDate(o.Start_Date__c);
                this.timeEntryDateRange.endDate = this.convertDate(o.End_Date__c);
            }
            else{
                this.setTimeAndExpenseEntryType(o.Project_Terms__c);
                this.timeEntryDateRange.startDate = this.convertDate(p.CreatedDate);
                this.timeEntryDateRange.endDate = this.convertDate(p.Planned_Go_Live_Date__c);
            }
            this.setSowCo(String.valueOf(o.Opportunity_Amount_COs__c));

        }
        //================================================================================
        // Public Methods
        //================================================================================
        /**
         * Mapped from Project Time & Expense Entry field
         */
        public void setTimeAndExpenseEntryType(String value) {

//            if(value == 'Fixed Price') {
//                timeAndMaterials.timeAndExpenseEntryTypeUri = String.valueOf(RepliconDropdowns__c.getValues('Pr-Expense-Entry-Type-Fixed-Price').uri__c);
//            }
//            else if(value == 'Time and Materials') {
//                timeAndMaterials.timeAndExpenseEntryTypeUri = String.valueOf(RepliconDropdowns__c.getValues('Pr-Expense-Entry-Type-Fixed-Price').uri__c);
//            }
//            else{
//                //timeAndMaterials.timeAndExpenseEntryTypeUri = null;
//                timeAndMaterials.timeAndExpenseEntryTypeUri = String.valueOf(RepliconDropdowns__c.getValues('Pr-Expense-Entry-Type-Fixed-Price').uri__c);
//            }
            timeAndMaterials.timeAndExpenseEntryTypeUri = String.valueOf(RepliconDropdowns__c.getValues('Pr-Expense-Entry-Type-Fixed-Price').uri__c);

        }

        /**
         * Mapped from Project Type field.
         */
        public void setType(String value) {
            Replicon.CustomField type = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-URL').uri__c));

            if(!String.isBlank(value)) {
                String key = 'Pr-Type-' + value.replace(' ', '-');
                if (!String.isBlank(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c))) {
                    type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
                    type.text = null;//String.valueOf(RepliconDropdowns__c.getValues(key).value__c);
                } else {
                    type.text = null;//'Project';
                    type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Project').uri__c), null);
                }
            }
            else {
                type.text = null;//'Project';
                type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Project').uri__c), null);
            }
            customFieldValues.add(type);

            /*
            type.text = value;
            if(value == 'Change Order') {
                type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Change-Order').uri__c), null);
            } else if(value == 'Managed Services') {
                type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Managed-Services').uri__c), null);
            } else if(value == 'Project') {
                type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Project').uri__c), null);
            } else{
                type.text = 'Project';
                type.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Type-Project').uri__c), null);
            }
            customFieldValues.add(type);
            */
        }

        /**
         * Mapped from the Opportunity Practice field.
         */
        public void setPractice(String value) {
            Replicon.CustomField practice = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Pr-Project-Practice-URL').uri__c));

            if(!String.isBlank(value)) {
                String key = 'Pr-Practice-' + value.replace(' ', '-');
                if (!String.isBlank(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c))) {
                    practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
                    practice.text = null;//String.valueOf(RepliconDropdowns__c.getValues(key).value__c);
                } else {
                    practice.text = null;//'Other';
                    practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Practice-Other').uri__c), null);
                }
            }
            else {
                practice.text = null;//'Other';
                practice.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Practice-Other').uri__c), null);
            }
            customFieldValues.add(practice);

        }

        /* Project Manager */
        public void setProjectManger(String value)
        {
            Replicon.CustomField pm = new Replicon.CustomField(null,'urn:replicon-tenant:levementum:custom-field-group:5e846ef1-fe5a-4ee7-9044-b00b661b5530');
            if(!String.isBlank(value))
            {
                pm.text = value;
                customFieldValues.add(pm);
            }
        }

        /*
        SET GEO
         */
        public void setGeo(string value){
            Replicon.CustomField geo = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:8c2deffa-85f7-4c5d-b5e0-33f7ba8badc8');

            if(value=='LATAM')
            {
                geo.addDropDownOption('urn:replicon-tenant:levementum:custom-field-option:a7b28723-c478-472a-b6aa-fdef08167282', null);
            }
            else if(value=='North America') {
                geo.addDropDownOption('urn:replicon-tenant:levementum:custom-field-option:a09490eb-6c21-4c48-a10f-fd4330c5fd7f', null);
            }
            else{
                geo.addDropDownOption('urn:replicon-tenant:levementum:custom-field-option:9d2bba0d-c372-49fa-ade7-3c84b19ca0cd', null);
            }
            customFieldValues.add(geo);
        }


        /**
         * Mapped from Opportunity Invoice Payment Terms.
         */
        public void setPaymentTerms(String value){
            System.debug('Payment Terms Value: '+value);
            Replicon.CustomField paymentTerms = new Replicon.CustomField('Payment Terms', String.valueOf(RepliconDropdowns__c.getValues('Pr-Payment-Terms-Url').uri__c));
            paymentTerms.text = null;//value;

            if(!String.isBlank(value)) {
                String key = 'Pr-Payment-Terms-' + value.replace(' ', '-');
                if (!String.isBlank(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c))) {
                    paymentTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c), null);
                } else {
                    paymentTerms.text = null;//'Special';
                    paymentTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Payment-Terms-Special').uri__c), null);
                }
            }
            else {
                paymentTerms.text = null;//'Special';
                paymentTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Payment-Terms-Special').uri__c), null);
            }
            customFieldValues.add(paymentTerms);
        }

        /**
         * Mapped to Opportunity Project Terms
         */
        public void setBillingType(String value,String type) {

            if(type.equalsIgnoreCase('service_contract')){
                billingTypeUri = String.valueOf(RepliconDropdowns__c.getValues('BillingType-Fixed-Price').uri__c);
            }
            else{
                billingTypeUri = String.valueOf(RepliconDropdowns__c.getValues('BillingType-Time-and-Materials').uri__c);
            }
//            if(!String.isBlank(value)) {
//                String key = 'BillingType-'+value.replace(' ','-');
//                billingTypeUri = String.valueOf(RepliconDropdowns__c.getValues(key).uri__c);
//            }
//            else{
//                billingTypeUri = String.valueOf(RepliconDropdowns__c.getValues('BillingType-Time-and-Materials').uri__c);
//            }
        }

        /**
         * Mapped from Opportunity Project Terms.
         */
        public void setProjectTerms(String value) {
            Replicon.CustomField projectTerms = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Pr-Terms-Url').uri__c));

            if(!String.isBlank(value)) {
                String key = 'Pr-Terms-'+value.replace(' ','-');
                projectTerms.text = null;//String.valueOf(RepliconDropdowns__c.getValues(key).value__c);
                projectTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c),null);
            }
            else{
                projectTerms.text = null;//'Time & Materials';
                projectTerms.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-Terms-Time-and-Materials').uri__c), null);
            }
            customFieldValues.add(projectTerms);
        }

        /*
        Invoice Schedule for Replicon
         */
        public void setPaymentSchedule(String value){
            Replicon.CustomField invSchedule = new Replicon.CustomField(null, String.valueOf(RepliconDropdowns__c.getValues('Pr-Inv-Schedule-Url').uri__c));

            invSchedule.text = null;

            if(!String.isBlank(value)) {
                String key = 'Pr-InvTerms-'+value.replace(' ','-'); System.debug('Invoice Schedule Key: '+key);
                invSchedule.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues(key).uri__c),null);
            }
            else{
                invSchedule.addDropDownOption(String.valueOf(RepliconDropdowns__c.getValues('Pr-InvTerms-Standard-TM').uri__c), null);
            }
            customFieldValues.add(invSchedule);
        }

        /**
         * Mapped to the Salesforce ID of a Project record.
         */
        public void setSalesforceId(String value) {
            Replicon.CustomField salesforceId = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:d91844aa-b94c-4081-9a35-2d687a105b54');
            salesforceId.text = value;

            customFieldValues.add(salesforceId);
        }

        public void setSowCo(String value){
            Replicon.CustomField sow = new Replicon.CustomField(null,'urn:replicon-tenant:levementum:user-defined-field:1c2c03ef-4d2a-4e7c-8ca5-9aaa78bbb35a');
            sow.number_r = Decimal.valueOf(value);
            customFieldValues.add(sow);
        }

        //TODO: set status on project info
        public void setStatus(String value) {
            projectStatusLabel = new ProjectStatusLabel();
            projectStatusLabel.name = value;

            if(value == '') {
                projectStatusLabel.uri = '';
            } else if(value == '') {
                projectStatusLabel.uri = '';
            }

        }

        /**
         * Mapped to the Opportunity Levementum Vertical field
         */
        public void setProgram(String value) {

            program = new Program();

            if(value == 'CPG') {
                program.name = null;//'CPG/Retail';
                program.uri = 'urn:replicon-tenant:levementum:program:6c475fbb-7b83-4ccb-8f16-0b6404b09a9d';
            }
            else if(value == 'Retail') {
                program.name = null;//'CPG/Retail';
                program.uri = 'urn:replicon-tenant:levementum:program:6c475fbb-7b83-4ccb-8f16-0b6404b09a9d';
            }
            else if(value == 'Manufacturing') {
                program.name = null;//'Manufacturing';
                program.uri = 'urn:replicon-tenant:levementum:program:432db80a-6111-4205-aab3-cc0c6e3afd0b';
            }
            else{
                program.uri = 'urn:replicon-tenant:levementum:program:fabd3d08-76bb-4fa4-b48b-5e0be2af2730';
                program.name = null;//'Other';
            }
        }

        /**
         *
         */
        public void setProjectLeader(String loginName) {
            if(String.isNotBlank(loginName)) {
                projectLeader = new ProjectLeader();
                projectLeader.loginName = loginName;
            }
        }

        /*public void addClient(String clientUri) {
            if(client == null) client = new Client();
            client.uri=clientUri;
            client.client = null;
        }*/

        public void setClient(String clientUri, String name){
            client = new RClient();
            if(String.isBlank(clientUri))
            {
                client.name = name;
                client.uri = null;
            }
            if(String.isBlank(name))
            {
                client.name = null;
                client.uri = clientUri;
            }
        }

        public void setEstimatedHours(Decimal hours) {
            estimatedHours = new TimeData();
            List<string> hourStrings = String.valueOf(hours).split('\\.');
            if(hourStrings.size()==1){
                estimatedHours.hours = String.valueOf(hourStrings[0]);
                estimatedHours.minutes = '0';
            }
            if(hourStrings.size()>1){
                estimatedHours.hours = String.valueOf(hourStrings[0]);
                Decimal minutes = ((Decimal.valueOf(hourStrings[1])/100)*60).round();
                estimatedHours.minutes = String.valueOf(minutes);
            }
        }

        public void setBookdate(Datetime dt){
            //System.debug('****** Book Date '+dt);
            Replicon.CustomField bookedDt = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:14ab37b2-59a6-4533-b567-50c83b044d5f');
            bookedDt.date_r = this.convertDate(dt);
            customFieldValues.add(bookedDt);
        }

        //================================================================================
        // Private Methods
        //================================================================================
        /**
         * Converts a Salesforce DateTime object into a Replicon Date object.
         *
         * @param dateValue The Salesforce date/time value to convert
         */
        private DateData convertDate(DateTime dateValue) {
            if(dateValue != null) {
                DateData data = new DateData();
                data.year = String.valueOf(dateValue.year());
                data.month = String.valueOf(dateValue.month());
                data.day = String.valueOf(dateValue.day());

                return data;
            }

            return null;
        }
    }

    public class RepliconCurrency{
        public String uri;
        public String name;
        public String symbol;
    }

    public class EstimatedCost{
        public Decimal amount;
        public RepliconCurrency currency_r;

        public EstimatedCost(Decimal amt){
            if(String.isBlank(String.valueOf(amt))){
                amt = 0;
            }
            this.amount = amt;
            this.currency_r = new RepliconCurrency();
            this.currency_r.uri = 'urn:replicon-tenant:levementum:currency:1';
        }
    }

    public class Target extends Replicon.RObject {
        public String name;
        public String parameterCorrelationId;
    }

    public class CustomField {
        public CustomFieldData customField;
        public DropDownOption dropDownOption;
        public String text;
        public Decimal number_r;
        public DateData date_r;

        public CustomField(String name, String uri) {
            this.customField = new CustomFieldData();
            this.customField.name = name;
            this.customField.uri = uri;
        }

        public void addDropDownOption(String uri, String name) {
            if(dropDownOption == null) dropDownOption = new Replicon.DropDownOption();

            dropDownOption.uri = uri;
            dropDownOption.name = name;
        }
    }

    public class CustomFieldData extends Replicon.RObject {
        public String name;
        public String groupUri;
    }

    public class DropDownOption extends Replicon.RObject {
        public String name;
    }

    public class TimeAndMaterials {
        public String timeAndExpenseEntryTypeUri;
        public String billingRateFrequency;
        public String billingRateFrequencyDuration;
    }

    public class TimeAndExpenseEntryType extends Replicon.RObject {
        public String displayText;
    }

    public class ProjectStatusLabel extends Replicon.RObject {
        public String name;
    }

    public class Program extends Replicon.RObject {
        public String name;
    }

    public class ProjectLeader extends Replicon.RObject {
        public String loginName;
        public String parameterCorrelationId;
    }

    public class RClient extends Replicon.RObject{
        public String name;
        public RClient()
        {

        }
    }

    public class Client extends Replicon.RObject {
        public ClientData client;

        public Client() {
            client = new ClientData();
            client.isActive = 'true';

        }

        public Client(Account a) {
            this();
            this.setName(a.Name);
            this.setPhoneNumber(a.Phone);
            this.setFaxNumber(a.Fax);
            this.setWebsite(a.Website);
            this.client.comment = a.Description;
            this.setMSANumber(a.MSA_Number__c);
            System.debug('****** address: '+a);
            //if(a.BillingAddress != null) this.setBillingAddress(a.BillingAddress);


            if(client.billingAddress == null) client.billingAddress = new Replicon.Address();
            client.billingAddress.address = a.BillingStreet;
            client.billingAddress.city = a.Billingcity;
            client.billingAddress.stateProvince = a.BillingState;
            client.billingAddress.zipPostalCode = a.BillingPostalCode;

            client.billingAddress.country = new Replicon.Country();
            client.billingAddress.country.uri = 'urn:replicon:country:united-states';
            client.billingAddress.country.name = 'United States';



            if(String.isNotBlank(a.RepliconClientUri__c)) client.target.uri = a.RepliconClientUri__c;

            //???: what address is mapped to client address? Find out from Raul
            //TODO: add client contact
            //TODO: add client contact email
            //TODO: add client address
            //TODO: add client manager
            //TODO: add client code
        }

        public override String toString() {
            return JSON.serialize(this);
        }

        public void setName(String value) {
            this.client.name = value;
            this.client.target.name = value;
        }

        public void setWebsite(String value) {
            if(client.clientAddress == null) client.clientAddress = new Replicon.Address();
            client.clientAddress.website = value;
        }

        public void setPhoneNumber(String value) {
            if(client.clientAddress == null) client.clientAddress = new Replicon.Address();
            client.clientAddress.phoneNumber = value;
        }

        public void setFaxNumber(String value) {
            if(client.clientAddress == null) client.clientAddress = new Replicon.Address();
            client.clientAddress.faxNumber = value;
        }

        public void setBillingAddress(System.Address billingAddress) {
            if(client.billingAddress == null) client.billingAddress = new Replicon.Address();
            client.billingAddress.address = billingAddress.street;
            client.billingAddress.city = billingAddress.city;
            client.billingAddress.stateProvince = billingAddress.state;
            client.billingAddress.zipPostalCode = billingAddress.postalcode;

            client.billingAddress.country = new Replicon.Country();
            client.billingAddress.country.uri = 'urn:replicon:country:united-states';
            client.billingAddress.country.name = 'United States';
        }
        public void setMSANumber(string val){
            if(!String.isBlank(val)) {

                Replicon.CustomField manager = new Replicon.CustomField(null, 'urn:replicon-tenant:levementum:user-defined-field:db91a4ed-5c8c-4a70-b75f-a795bb0a773f');
                manager.text = val ;
                client.customFieldValues.add(manager);
            }
        }
    }

    public class ClientData extends Replicon.RObject {
        public Replicon.Target target;
        public String name;
        public String billingContact;
        public Address clientAddress;
        public Address billingAddress;
        public String isActive;
        public String comment;
        //public String msaNumber;
        public CustomField[] customFieldValues;

        public ClientData() {
            target = new Replicon.Target();
            customFieldValues = new CustomField[] {};
        }
    }

    public class TimeData {
        public String hours;
        public String minutes;
        public String seconds;

        public TimeData() {
            hours = '0';
            minutes = '0';
            seconds = '0';
        }
    }

    public class DateData {
        public String year;
        public String month;
        public String day;
    }

    public class DateRange {
        public DateData startDate;
        public DateData endDate;

        public DateRange() {
            startDate = new DateData();
            endDate = new DateData();
        }
    }

    public class TaskDateRange {
        public DateData startDate;
        public DateData endDate;
        public String relativeDateRangeUri;
        public String relativeDateRangeAsOfDate;

        public TaskDateRange() {
            startDate = new DateData();
            endDate = new DateData();
        }
    }

    public class Address {
        public String address; // street
        public String city;
        public String stateProvince;
        public String zipPostalCode;
        public String phoneNumber;
        public String faxNumber;
        public String email;
        public String website;
        public Country country;
    }

    public class Country extends  Replicon.RObject {
        public String name;
    }

    public class UpsertResponse {
        public String displayText;
        public String name;
        public String slug;
        public String uri;
        public RepliconError error;

        public UpsertResponse(Map<String, Object> data) {
            if(data != null && data.size() > 0) {
                if(data.containsKey('displayText')) this.displayText = (String) data.get('displayText');
                if(data.containsKey('name')) this.name = (String) data.get('name');
                if(data.containsKey('slug')) this.slug = (String) data.get('slug');
                if(data.containsKey('uri')) this.uri = (String) data.get('uri');
                if(data.containsKey('error')) this.error = (RepliconError) data.get('error');
            }
        }
    }

    public class RepliconError {
        public String code;
        public String correlationId;
        public String reason;
    }

    public class BillingRate {
        public String projectUri;
        public String companyBillingRateUri;
        public DateData effectiveDate;
        Public Rate rate;

        public BillingRate(String projectUri,String billinguri,DateTime effectiveDate,String rate){
            this.projectUri = projectUri;
            this.companyBillingRateUri = billinguri;
            this.effectiveDate = null;
            this.rate = new Rate(rate,'urn:replicon-tenant:levementum:currency:1');
        }

        public override String toString() {
            return  JSON.serialize(this).replace('amount_r','amount') ;
        }

        public DateData convertDate(DateTime dateValue) {
            if(dateValue != null)
            {
                DateData data = new DateData();
                data.year = String.valueOf(dateValue.year());
                data.month = String.valueOf(dateValue.month());
                data.day = String.valueOf(dateValue.day());

                return data;
            }

            return null;
        }
    }

    public class Fixedbid{

        Public Rate rate;
        public string fixedBidBillingFrequencyUri;

        public Fixedbid(String oppId){
            List<OpportunityLineItem> ols = Replicon.OppLineItems(oppId);
            OpportunityLineItem ol = ols[0];
            this.rate = new Rate(String.valueOf(ol.UnitPrice),'urn:replicon-tenant:levementum:currency:1');
            this.fixedBidBillingFrequencyUri = 'urn:replicon:fixed-bid-frequency:end-of-project';
        }

        public override String toString() {
            return  JSON.serialize(this).replace('amount_r','amount') ;
        }
    }
    public class Rate{
        public String amount_r;
        public String currencyUri;

        public Rate(String amt, String uri){
            this.amount_r = amt;
            this.currencyUri = uri;
        }
    }
}