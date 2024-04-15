public with sharing class InternalProjTeamMemberLWCController {

    public InternalProjTeamMemberLWCController(){

    }

    @AuraEnabled
    public static String createProjectTeamMemberName(String contactId, String projectId){
        
        try{
        System.debug('Contact Id: ' + contactId);
        System.debug('Project Id: ' + projectId);
        Boolean isDuplicateTeamMember = false;
        isDuplicateTeamMember = checkIfProjectTeamMemberAlreadyExists(projectId, contactId);
        if(isDuplicateTeamMember){
            String message = 'Project Team Member already exists';
            AuraHandledException auraError = new AuraHandledException(message);
            auraError.setMessage('Project Team Member already exists');
            throw auraError;
        }

        String projectTeamMemberName;
        Contact con = [SELECT Id, Name FROM Contact WHERE Id = :contactId LIMIT 1];
        Project__c proj = [SELECT Id, Name FROM Project__c WHERE Id = :projectId LIMIT 1];
        projectTeamMemberName = con.Name + ' - ' + proj.Name;

        return projectTeamMemberName;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

    }

    @AuraEnabled(cacheable = true)
    public static List<ProjectTeamMemberWrapper> getProjectTeamMembersWrapper(String projectId){
        try {
            List<Client_Contact__c> placeholderMemberList = new List<Client_Contact__c>();

            placeholderMemberList = [SELECT Id, Name, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__c, Project__c, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, 
                                Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Is_Temporary_Rate__c, Assigned_Billing_Rate__r.Is_Concession_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Active_Effective_Billing_Rate__c, Active_Effective_Billing_Rate__r.Effective_Date__c,
                                Active_Effective_Billing_Rate__r.Project_Billing_Rate__c, CreatedDate
                            FROM Client_Contact__c 
                            WHERE Project__c = :projectId AND Client_Contact__r.Name = 'Place Holder'
                            ORDER BY Client_Contact__r.Name, Assigned_Billing_Rate__r.Name];

            List<Client_Contact__c> memberList = new List<Client_Contact__c>();

            memberList = [SELECT Id, Name, Client_Contact__r.Name, Client_Contact__r.FirstName, Client_Contact__r.LastName, Client_Contact__c, Project__c, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Assigned_Billing_Rate__r.Name, 
                                Assigned_Billing_Rate__r.Hourly_Rate__c, Assigned_Billing_Rate__r.Is_Temporary_Rate__c, Assigned_Billing_Rate__r.Is_Concession_Rate__c, Assigned_Billing_Rate__r.Outdated_Rate__c, Active_Effective_Billing_Rate__c, Active_Effective_Billing_Rate__r.Effective_Date__c,
                                Active_Effective_Billing_Rate__r.Project_Billing_Rate__c, CreatedDate, Project__r.CreatedDate
                            FROM Client_Contact__c 
                            WHERE Project__c = :projectId AND Client_Contact__r.Name != 'Place Holder'
                            ORDER BY Client_Contact__r.LastName, Client_Contact__r.FirstName];

            List<Project_Team_Member_Effective_Rate__c> effectiveRateList = new List<Project_Team_Member_Effective_Rate__c>();
            effectiveRateList = [SELECT Id, Name, Internal_Project_Team_Member__c, Project_Billing_Rate__c, Project_Billing_Rate__r.Name, Project_Billing_Rate__r.Hourly_Rate__c, Effective_Date__c, Internal_Project_Team_Member__r.Project__r.CreatedDate, CreatedDate
                                    FROM Project_Team_Member_Effective_Rate__c
                                    WHERE Internal_Project_Team_Member__r.Project__c = :projectId AND Internal_Project_Team_Member__r.Client_Contact__r.Name != 'Place Holder'
                                    ORDER BY Internal_Project_Team_Member__c, Effective_Date__c];

            Map<Id, List<effectiveRateWrapper>> projTeamMemberIdToEffectiveRateWrapperListMap = new Map<Id, List<effectiveRateWrapper>>();
            Map<Id, Date> projTeamMemberIdToEffectiveUntilDateMap = new Map<Id, Date>();
            Map<Id, Datetime> projTeamMemberIdToEffectiveUntilDatetimeMap = new Map<Id, Datetime>();
            for(Project_Team_Member_Effective_Rate__c effectiveRate : effectiveRateList){

                effectiveRateWrapper newWrapper = new effectiveRateWrapper();
                newWrapper.effectiveRateId = effectiveRate.Id;
                newWrapper.effectiveRateAndHourlyRateName = effectiveRate.Project_Billing_Rate__r.Name + ' - $' + String.valueOf(effectiveRate.Project_Billing_Rate__r.Hourly_Rate__c);
                newWrapper.effectiveRateName = effectiveRate.Project_Billing_Rate__r.Name;
                newWrapper.effectiveDate = effectiveRate.Effective_Date__c;

                if(effectiveRate.Effective_Date__c != null){
                    Datetime effectiveDatetime = Datetime.newInstance(effectiveRate.Effective_Date__c.year(), effectiveRate.Effective_Date__c.month(), effectiveRate.Effective_Date__c.day());
                    String effectiveDateString = effectiveDatetime.format('MMM d, yyyy');
                    newWrapper.effectiveDateString = effectiveDateString;
                }else{
                    String effectiveDateString = effectiveRate.Internal_Project_Team_Member__r.Project__r.CreatedDate.format('MMM d, yyyy');
                    newWrapper.effectiveDateString = effectiveDateString;
                }

                if(projTeamMemberIdToEffectiveRateWrapperListMap.containsKey(effectiveRate.Internal_Project_Team_Member__c)){
                    List<effectiveRateWrapper> effectiveRateWrapperList = projTeamMemberIdToEffectiveRateWrapperListMap.get(effectiveRate.Internal_Project_Team_Member__c);
                    effectiveRateWrapperList.add(newWrapper);
                    projTeamMemberIdToEffectiveRateWrapperListMap.put(effectiveRate.Internal_Project_Team_Member__c, effectiveRateWrapperList);
                }else{
                    List<effectiveRateWrapper> effectiveRateWrapperList = new List<effectiveRateWrapper>();
                    effectiveRateWrapperList.add(newWrapper);
                    projTeamMemberIdToEffectiveRateWrapperListMap.put(effectiveRate.Internal_Project_Team_Member__c, effectiveRateWrapperList);
                }

                if(effectiveRate.Effective_Date__c != null && effectiveRate.Effective_Date__c > Date.today() && !projTeamMemberIdToEffectiveUntilDateMap.containsKey(effectiveRate.Internal_Project_Team_Member__c)){
                    projTeamMemberIdToEffectiveUntilDateMap.put(effectiveRate.Internal_Project_Team_Member__c, effectiveRate.Effective_Date__c);
                    projTeamMemberIdToEffectiveUntilDatetimeMap.put(effectiveRate.Internal_Project_Team_Member__c, Datetime.newInstance(effectiveRate.Effective_Date__c.year(), effectiveRate.Effective_Date__c.month(), effectiveRate.Effective_Date__c.day()));
                }
            }

            List<Client_Contact__c> totalMemberList = new List<Client_Contact__c>();
            totalMemberList.addAll(placeholderMemberList);
            totalMemberList.addAll(memberList);

            List<ProjectTeamMemberWrapper> wrapperList = new List<ProjectTeamMemberWrapper>();
            for(Client_Contact__c ptm : totalMemberList){
                ProjectTeamMemberWrapper wrap = new ProjectTeamMemberWrapper();
                wrap.ptmId = ptm.Id;
                wrap.name = ptm.Client_Contact__r.Name;
                wrap.ptmFormattedName = ptm.Client_Contact__r.LastName + ', ' + ptm.Client_Contact__r.FirstName;
                wrap.nameUrl = '/' + ptm.Id;
                wrap.billingRateName = ptm.Assigned_Billing_Rate__r.Name;
                wrap.billingRateId = ptm.Assigned_Billing_Rate__c;
                wrap.employeeName = ptm.Client_Contact__r.Name;

                if(ptm.Client_Contact__r.Name == 'Place Holder'){
                    wrap.isPlaceholderEmployee = true;
                    wrap.placeholderStyleClass = 'background: repeating-linear-gradient(-55deg, rgb(255, 255, 255), rgb(255, 255, 255) 10px, rgb(235, 235, 235) 10px, rgb(235, 235, 235) 20px)';
                }else{
                    wrap.isPlaceholderEmployee = false;
                }

                String billingRateCombinedName = 'Assign Billing Rate';
                if(ptm.Assigned_Billing_Rate__c != null){
                    billingRateCombinedName = ptm.Assigned_Billing_Rate__r.Name + ' - $' + String.valueOf(ptm.Assigned_Billing_Rate__r.Hourly_Rate__c);
                }
                wrap.billingRateNameAndRate = billingRateCombinedName;

                Boolean billingRateNeeded = false;
                if(ptm.Assigned_Billing_Rate__c == null || ptm.Assigned_Billing_Rate__r.Is_Temporary_Rate__c == true || ptm.Assigned_Billing_Rate__r.Outdated_Rate__c == true ){
                    billingRateNeeded = true;
                }
                wrap.needsBillingRateAssignment = billingRateNeeded;

                if(ptm.Active_Effective_Billing_Rate__c != null && ptm.Active_Effective_Billing_Rate__r.Effective_Date__c != null){

                    Date effectiveDate = ptm.Active_Effective_Billing_Rate__r.Effective_Date__c;
                    wrap.activeEffectiveDate = effectiveDate;

                    Datetime activeEffectiveDatetime = Datetime.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day());
                    String effectiveDateString = activeEffectiveDatetime.format('MMM d, yyyy');
                    wrap.activeEffectiveDateString = effectiveDateString;
                    wrap.hasEffectiveDate = true;


                    //Get Effective Date Range
                    if(projTeamMemberIdToEffectiveUntilDateMap.containsKey(ptm.Id)){
                        wrap.effectiveRateRangeString = effectiveDateString + ' - ' + projTeamMemberIdToEffectiveUntilDatetimeMap.get(ptm.Id).format('MMM d, yyyy');
                    }else{
                        wrap.effectiveRateRangeString = effectiveDateString;
                    }

                }else{
                    if(ptm.Client_Contact__c != null && ptm.Client_Contact__r.Name != 'Place Holder'){
                        wrap.activeEffectiveDateString = 'Effective Indefinitely';
                        wrap.hasEffectiveDate = false;

                        //Get Effective Date Range
                        if(projTeamMemberIdToEffectiveUntilDateMap.containsKey(ptm.Id)){
                            wrap.hasEffectiveDate = true;
                            wrap.effectiveRateRangeString = 'Until ' + projTeamMemberIdToEffectiveUntilDatetimeMap.get(ptm.Id).format('MMM d, yyyy');
                        }else{
                            wrap.effectiveRateRangeString = 'Effective Indefinitely';
                        }
                    }
                }


                //For Effective Rate Table Popover
                if(projTeamMemberIdToEffectiveRateWrapperListMap.containsKey(ptm.Id)){

                    wrap.effectiveRateList = projTeamMemberIdToEffectiveRateWrapperListMap.get(ptm.Id);
                    wrap.hasEffectiveRates = true;
                    Integer effectiveRateStyleHeight = 35 + ((Integer)wrap.effectiveRateList.size() * 25);
                    Integer effectiveRateStyleTop = -1 * (effectiveRateStyleHeight);
                    wrap.effectiveRateListStyle = 'position:absolute;top:' + String.valueOf(effectiveRateStyleTop) + 'px;left:-368px;width:600px;height:' + String.valueOf(effectiveRateStyleHeight) + 'px;background-color:rgb(201,201,201);';
                }else{
                    wrap.hasEffectiveRates = false;
                }
            
                wrapperList.add(wrap);
            }

            return wrapperList;
        } catch (Exception e) {
            System.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class ProjectTeamMemberWrapper{
        @AuraEnabled
        public Id ptmId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String ptmFormattedName {get;set;}
        @AuraEnabled
        public String nameUrl {get;set;}
        @AuraEnabled
        public String billingRateName {get;set;}
        @AuraEnabled
        public Id billingRateId {get;set;}
        @AuraEnabled
        public String employeeName {get;set;}
        @AuraEnabled
        public String billingRateNameAndRate {get;set;}
        @AuraEnabled
        public Boolean needsBillingRateAssignment {get;set;}
        @AuraEnabled
        public String placeholderStyleClass {get;set;}
        @AuraEnabled
        public boolean isPlaceholderEmployee {get;set;}
        @AuraEnabled
        public Date activeEffectiveDate {get;set;}
        @AuraEnabled
        public String activeEffectiveDateString {get;set;}
        @AuraEnabled
        public Boolean hasEffectiveDate {get;set;}
        @AuraEnabled
        public Boolean hasEffectiveRates {get;set;}
        @AuraEnabled
        public List<effectiveRateWrapper> effectiveRateList {get;set;}
        @AuraEnabled
        public String effectiveRateListStyle {get;set;}
        @AuraEnabled
        public String effectiveRateRangeString {get;set;}
    }

    private class effectiveRateWrapper{
        @AuraEnabled
        public Id effectiveRateId {get;set;}
        @AuraEnabled
        public String effectiveRateName {get;set;}
        @AuraEnabled
        public String effectiveRateAndHourlyRateName {get;set;}
        @AuraEnabled
        public Date effectiveDate {get;set;}
        @AuraEnabled
        public String effectiveDateString {get;set;}
    }

    @AuraEnabled(cacheable = true)
    public static List<Project_Team_Member_Billing_Rate__c> getProjectBillingRatesForAssignment(String projectId){
        try {
        
            List<Project_Team_Member_Billing_Rate__c> rateList = new List<Project_Team_Member_Billing_Rate__c>();

            rateList = [SELECT Id, Name, Hourly_Rate__c 
                        FROM Project_Team_Member_Billing_Rate__c 
                        WHERE Project__c = :projectId AND Is_Temporary_Rate__c != true AND Is_Concession_Rate__c != true AND Is_Placeholder_Rate__c != true AND Created_in_Salesforce__c = true AND Outdated_Rate__c = false
                        ORDER BY Name];

            System.debug('Rate List: ' + rateList);
            return rateList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }

    @AuraEnabled
    public static Boolean checkIfProjectTeamMemberAlreadyExists(string projectId, String contactId){

        System.debug('Check if Project Team Member Already Exists************************************ ');
        Boolean projectTeamMemberAlreadyExists = false;

        System.debug('projectId: ' + projectId);
        System.debug('contactId: ' + contactId);
        List<Client_Contact__c> existingProjectTeamMemberList = new List<Client_Contact__c>();
        existingProjectTeamMemberList = [SELECT Id, Name, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Project__c, Project__r.Name, Client_Contact__c, Client_Contact__r.Name
                                            FROM Client_Contact__c
                                            WHERE Project__c =: projectId AND Client_Contact__c =: contactId AND Client_Contact__r.Name != 'Place Holder' AND Client_Contact__r.Name != 'ATG Consultant'];
System.debug('existingProjectTeamMemberList: ' + existingProjectTeamMemberList);
        if(existingProjectTeamMemberList.size() > 0){
            projectTeamMemberAlreadyExists = true;
        }

        return projectTeamMemberAlreadyExists;
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getPlaceholderRoles(){
        try {

            List<Product2> placeholderRoleProductList = new List<Product2>();

            List<Product2> productsList = new List<Product2>();
            productsList = [SELECT Id, Name, IsActive
                            FROM Product2
                            WHERE IsActive = true AND Name != 'Adobe Consultant'
                            ORDER BY Name];

            for(Product2 p : productsList){
                placeholderRoleProductList.add(p);
            }

            return placeholderRoleProductList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Client_Contact__c createPlaceholder(String projectId, String contactId, String placeholderRoleName, String productId){

        /**
         * 1.) Check to see if there is a billing rate on the project with the same name as the Placeholder Role Name
         * 2a.) If there is a match then prep that Bill Rate to assign to the Placeholder Internal Project Team Member
         * 2b.) If no match, then create the bill rate with hourly rate of average bill rate for org (average bill rate is on capacity record)
         * 3.) Check if Placeholder with the rate already exists, if they do add a 2 or 3 or etc... to the Internal Project Team Member Name
         * 4.) Insert Placeholder Internal Project Team Member
         */

        Client_Contact__c newPlaceholderProjectTeamMember = new Client_Contact__c();

        List<Project_Team_Member_Billing_Rate__c> relatedProjectBillRateList = new List<Project_Team_Member_Billing_Rate__c>();
        relatedProjectBillRateList = [SELECT Id, Name, Created_in_Salesforce__c, Hourly_Rate__c, Project__c, Is_Placeholder_Rate__c
                                        FROM Project_Team_Member_Billing_Rate__c
                                        WHERE Project__c =: projectId AND Name =: placeholderRoleName AND Created_in_Salesforce__c = true
                                        ORDER BY Hourly_Rate__c ASC];

        Id assignedBillingRateId;
        if(relatedProjectBillRateList.size() > 0){
            for(Project_Team_Member_Billing_Rate__c rate : relatedProjectBillRateList){
                assignedBillingRateId = rate.Id;
            }
        }else{
            //If no matching Rate exists yet then create one
            Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c();
            newRate.Name = placeholderRoleName;
            newRate.Is_Placeholder_Rate__c = true;
            newRate.Created_in_Salesforce__c = true;
            newRate.Hourly_Rate__c = 210;
            newRate.Project__c = (Id)projectId;

        }

        return newPlaceholderProjectTeamMember;
    }

    @AuraEnabled
    public static void deleteProjectTeamMember(String projectTeamMemberId){

        List<RepliconForecast__c> forecastList = new List<RepliconForecast__c>();
        forecastList = [SELECT Id, Name, Project__c, Internal_Project_Team_Member__c 
                        FROM RepliconForecast__c 
                        WHERE Internal_Project_Team_Member__c =:projectTeamMemberId AND Week_End_Date__c > TODAY];

        if(forecastList.size() > 0){
            System.debug('************************** Deleting ' + forecastList.size() + ' Forecasts related to a Project Team Member that is getting Deleted ***********************************');
            delete forecastList;
        }

        Client_Contact__c projTeamMember = [SELECT Id, Name, Project__c FROM Client_Contact__c WHERE Id =: projectTeamMemberId LIMIT 1];

        delete projTeamMember;

    }

    @AuraEnabled
    public static void createEffectiveRate(String projectTeamMemberId, String priorBillingRateId, String newBillingRateId, Date effectiveDate, Datetime projectCreatedDate){

        /**
         * Functionality: Create Effective Rates for the Project Team Member
         * 
         * If Project Team Member does not have any effective rates, then create one for the previous billing rate, with NO Effective date, then create one for the NEW Billing Rate with the entered effective rate.
         * If Project Team Member DOES have effective rates already, then create one for the new one with the effective date.
         * 
         */
        System.debug('************************ START createEffectiveRate ************************ ');
        System.debug('Project Team Member Id: ' + projectTeamMemberId);
        System.debug('Previous Billing Rate Id: ' + priorBillingRateId);
        System.debug('New Billing Rate Id: ' + newBillingRateId);
        System.debug('Effective Date: ' + effectiveDate);
        System.debug('Project Created Date: ' + projectCreatedDate);

        List<Project_Team_Member_Effective_Rate__c> teamMemberEffectiveRatesToInsertList = new List<Project_Team_Member_Effective_Rate__c>();

        List<Project_Team_Member_Effective_Rate__c> teamMemberEffectiveRatesList = new List<Project_Team_Member_Effective_Rate__c>();
        teamMemberEffectiveRatesList = [SELECT Id, Internal_Project_Team_Member__c, Project_Billing_Rate__c, Effective_Date__c
                                        FROM Project_Team_Member_Effective_Rate__c
                                        WHERE Internal_Project_Team_Member__c =: projectTeamMemberId];


        Boolean makeNewRateTheActiveRate = false;
        Project_Team_Member_Effective_Rate__c newEffectiveRate = new Project_Team_Member_Effective_Rate__c();
        if(teamMemberEffectiveRatesList.size() > 0){
            for(Project_Team_Member_Effective_Rate__c effectiveRate : teamMemberEffectiveRatesList){

                if(effectiveRate.Effective_Date__c == effectiveDate){
                    String message = 'An Effective Rate with the same Effectiuve Date already exists for this Project Team Member.';
                    AuraHandledException auraError = new AuraHandledException(message);
                    auraError.setMessage('An Effective Rate with the same Effectiuve Date already exists for this Project Team Member.');
                    throw auraError;
                }

                if(effectiveDate <= Date.today() && effectiveRate.Effective_Date__c != null && effectiveRate.Effective_Date__c <= Date.today()){ //Check to see if effective rate entered should be made the current rate or if there is another rate that is before the current date but is closer to the current date than the newly created effective rate

                    if(effectiveDate.daysBetween(Date.today()) < effectiveRate.Effective_Date__c.daysBetween(Date.today())){ //Daysbetween() = Days from the first date to get to the date in the parameter (i.e. if first date is after the date in the parameter, then it will return a negative number, and vice versa)
                        makeNewRateTheActiveRate = true;
                    }
                }
            }

            newEffectiveRate.Internal_Project_Team_Member__c = (Id)projectTeamMemberId;
            newEffectiveRate.Project_Billing_Rate__c = (Id)newBillingRateId;
            newEffectiveRate.Effective_Date__c = effectiveDate;
            teamMemberEffectiveRatesToInsertList.add(newEffectiveRate);
        }else{
            Project_Team_Member_Effective_Rate__c oldEffectiveRate = new Project_Team_Member_Effective_Rate__c();
            oldEffectiveRate.Internal_Project_Team_Member__c = (Id)projectTeamMemberId;
            oldEffectiveRate.Project_Billing_Rate__c = (Id)priorBillingRateId;
            oldEffectiveRate.Effective_Date__c = Date.valueOf(projectCreatedDate);
            teamMemberEffectiveRatesToInsertList.add(oldEffectiveRate);

            newEffectiveRate.Internal_Project_Team_Member__c = (Id)projectTeamMemberId;
            newEffectiveRate.Project_Billing_Rate__c = (Id)newBillingRateId;
            newEffectiveRate.Effective_Date__c = effectiveDate;
            teamMemberEffectiveRatesToInsertList.add(newEffectiveRate);

            if(effectiveDate <= Date.today()){
                //If this is the first effective Rate entered for this Project team Member, and the effective Date entered is prior to the current day, then mark it to be set as the currently active rate.
                makeNewRateTheActiveRate = true;
            }
        }

        if(teamMemberEffectiveRatesToInsertList.size() > 0){
            System.debug('****************** Inserting ' + teamMemberEffectiveRatesToInsertList.size() + ' Effective Rates from Internal Project Team Member Table ************************');
            insert teamMemberEffectiveRatesToInsertList;
        }


        if(makeNewRateTheActiveRate){
            //If Effective Rate is less than today

            System.debug('Project Team Member Id: ' + projectTeamMemberId);
            List<Client_Contact__c> existingProjectTeamMemberList = new List<Client_Contact__c>();
            Client_Contact__c projTeamMember = [SELECT Id, Name, Internal_Project_Team_Member_Name__c, Assigned_Billing_Rate__c, Project__c, Project__r.Name, Client_Contact__c, Client_Contact__r.Name, Active_Effective_Billing_Rate__c
                                                FROM Client_Contact__c
                                                WHERE Id =: projectTeamMemberId];

            projTeamMember.Assigned_Billing_Rate__c = (Id)newBillingRateId;
            projTeamMember.Active_Effective_Billing_Rate__c = newEffectiveRate.Id;
            System.debug('****************** Updating Project Team Member Assigned Billing Rate due to Effective Rate wiith past Effective Date created ************************');
            update projTeamMember;
            System.debug('*********************** AFTER Updating Proj Team Member *******************');

            List<Id> projTeamMemberIdList = new List<Id>{projTeamMember.Id};
            futureCheckTimeEntryBillRatesAfterEffectiveRateAssignment(projTeamMemberIdList);
            //ProjTeamMemEffectiveRateTriggerHelper.checkTimeEntryBillingRatePopulation(projTeamMemberIdSet);
        }


    }

    @future(callout=false)
    public static void futureCheckTimeEntryBillRatesAfterEffectiveRateAssignment(List<Id> projTeamMemberIdList){

        Set<Id> projTeamMemberIdSet = new Set<Id>();
        for(Id projTeamMemberId : projTeamMemberIdList){
            projTeamMemberIdSet.add(projTeamMemberId);
        }

        ProjTeamMemEffectiveRateTriggerHelper.checkTimeEntryBillingRatePopulation(projTeamMemberIdSet);
    }


    @AuraEnabled
    public static void updatePlaceholderBillRate(String projectId, String productId, String placeholderRoleName, String projectTeamMemberId){
        try {

            List<Project_Team_Member_Billing_Rate__c> relatedProjectBillRateList = new List<Project_Team_Member_Billing_Rate__c>();
            relatedProjectBillRateList = [SELECT Id, Name, Created_in_Salesforce__c, Hourly_Rate__c, Project__c, Product__c, Product__r.Name, Is_Placeholder_Rate__c, 
                                                (SELECT Id, Client_Contact__c FROM Internal_Project_Team_Members__r WHERE Is_Placeholder_Team_Member__c = true)
                                            FROM Project_Team_Member_Billing_Rate__c
                                            WHERE Project__c =: projectId AND Product__c =: productId AND Created_in_Salesforce__c = true
                                            ORDER BY CreatedDate ASC];

            Id assignedBillingRateId;
            if(relatedProjectBillRateList.size() > 0){
                for(Project_Team_Member_Billing_Rate__c rate : relatedProjectBillRateList){
                    if(rate.Internal_Project_Team_Members__r.size() > 0){
                        String message = 'A Placeholder with this rate already exists on this Project.';
                        AuraHandledException auraError = new AuraHandledException(message);
                        auraError.setMessage('A Placeholder with this rate already exists on this Project.');
                        throw auraError;
                    }
                    assignedBillingRateId = rate.Id;
                }
            }else{
                //If no matching Rate exists yet then create one
                Project_Team_Member_Billing_Rate__c newRate = new Project_Team_Member_Billing_Rate__c();
                newRate.Name = placeholderRoleName;
                newRate.Created_in_Salesforce__c = true;
                newRate.Is_Placeholder_Rate__c = true;
                newRate.Hourly_Rate__c = 210;
                newRate.Project__c = (Id)projectId;
                newRate.Product__c = (Id)productId;
                insert newRate;

                assignedBillingRateId = newRate.Id;
            }

            Client_Contact__c placeholderTeamMemberToUpdate = new Client_Contact__c(Id = projectTeamMemberId, Assigned_Billing_Rate__c = assignedBillingRateId);
            update placeholderTeamMemberToUpdate;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}