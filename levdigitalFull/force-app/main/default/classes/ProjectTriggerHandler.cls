/**
 * Created by jmahapatra on 11/13/17.
 * Populate Lev Support Email from Account when Project is created
 */

public class ProjectTriggerHandler extends SObjects {

    private static String OoOCoverageRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('OoO Coverage Request').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();
    private static List<String> closedProjectStatusList = new List<String>{'Completed', 'Terminated - Opportunity Lost', 'Terminated - Project Killed'};

    public ProjectTriggerHandler() { }

    public override void beforeInsert(SObject[] records) {
        List<Project__c> populateSupportEmailList = new List<Project__c>();
        List<Project__c> newProjList = new List<Project__c>();
        // iterate of the newly created records
        for(SObject obj : records) {
            Project__c project = (Project__c)obj;

            if(project.Account__c != null){
                populateSupportEmailList.add(project);
            }
            if(project.Opportunity__c != null){
                newProjList.add(project);
            }
        }

        if(populateSupportEmailList.size() > 0){
            populateLevSupportEmailFromAccount(populateSupportEmailList);
        }

        if(newProjList.size() > 0){
            OppLineTriggerHelper.checkForHybridStaffOnProject(newProjList, false);
        }
    }

    public override void afterInsert(SObject[] records) {

        List<Project__c> newProjectList = new List<Project__c>();
        Set<Id> activeProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> closedProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> onHoldProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> projectRollupCountRelatedAccountIdSet = new Set<Id>();

        // iterate of the newly created records
        for(SObject obj : records) {
            Project__c project = (Project__c)obj;

            //DLRS replacement to Apex Work ST 1/9/2023
            if(project.Account__c != null){
                projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                //Active Project Count - Real Time ST 1/9/2023
                /*if(project.Active_Project__c){
                    activeProjectRelatedAccountIdSet.add(project.Account__c);
                }
                //Count Closed Projects ST 1/9/2023
                if(project.Closed_Project__c){
                    closedProjectRelatedAccountIdSet.add(project.Account__c);
                }
                //On Hold Projects Count ST 1/9/2023
                if(project.Project_Status__c == 'On Hold'){
                    onHoldProjectRelatedAccountIdSet.add(project.Account__c);
                }*/
            }

            newProjectList.add(project);

            // doesnt run during unit testing to avoid callouts during test data setup
            if(!Test.isRunningTest()){
                //this.upsertRepliconProject(project); 
            }
        }

        if(newProjectList.size() > 0){
            ProjectRoleManager.ProjectRoleManager_Handler(newProjectList);
            ProjectBillingRateManager.syncProjectBillingRates(newProjectList);
        }

        /*if(activeProjectRelatedAccountIdSet.size() > 0){
            rollupActiveProjectCountOnAccount(activeProjectRelatedAccountIdSet);
        }
        if(closedProjectRelatedAccountIdSet.size() > 0){
            rollupClosedProjectCountOnAccount(closedProjectRelatedAccountIdSet);
        }
        if(onHoldProjectRelatedAccountIdSet.size() > 0){
            rollupOnHoldProjectCountOnAccount(onHoldProjectRelatedAccountIdSet);
        }*/
        if(projectRollupCountRelatedAccountIdSet.size() > 0){
            rollupProjectCountForAccount(projectRollupCountRelatedAccountIdSet);
        }

    }
    //    public override void beforeUpdate(SObject[] records, SObject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap) { }
    public override void afterUpdate(SObject[] records, SOBject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap) {

        List<Project__c> projectManagerChangedProjectList = new List<Project__c>();
        Set<Id> activeProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> closedProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> onHoldProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> projectRollupCountRelatedAccountIdSet = new Set<Id>();

        // iterate over the updated records
        for(SObject obj : records) {
            Project__c project = (Project__c)obj;
            Project__c project_old = (Project__c)oldRecordMap.get(project.Id);

            // check if required fields have changed
            if(isRepliconFieldsChanged(project, project_old)) {
                // doesnt run during unit testing to avoid callouts during test data setup
                if(!Test.isRunningTest()){
                    //this.upsertRepliconProject(project);
                }
            }

            //Check if Project Manager changes
            if(project.Project_Manager__c != project_old.Project_Manager__c){
                projectManagerChangedProjectList.add(project);
            }

            //DLRS replacement to Apex Work ST 1/9/2023
            if(project.Account__c != null){
                //Active Project Count - Real Time ST 1/9/2023
                if(project.Active_Project__c != project_old.Active_Project__c){
                    //activeProjectRelatedAccountIdSet.add(project.Account__c);
                    projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                }else if(project.Closed_Project__c != project_old.Closed_Project__c){ //Count Closed Projects ST 1/9/2023
                    //closedProjectRelatedAccountIdSet.add(project.Account__c);
                    projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                }else if((project.Project_Status__c == 'On Hold' || project_old.Project_Status__c == 'On Hold') && project.Project_Status__c != project_old.Project_Status__c){ //On Hold Projects Count ST 1/9/2023
                    //onHoldProjectRelatedAccountIdSet.add(project.Account__c);
                    projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                }else if((closedProjectStatusList.contains(project.Project_Status__c) && !closedProjectStatusList.contains(project_old.Project_Status__c)) || (!closedProjectStatusList.contains(project.Project_Status__c) && closedProjectStatusList.contains(project_old.Project_Status__c))){
                    projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                }
            }
        }

        this.updateProjectDetailsInAccount((Map<Id, Project__c>)oldRecordMap, (Map<Id, Project__c>)recordMap);

        if(projectManagerChangedProjectList.size() > 0){
            projectManagerChanged(projectManagerChangedProjectList);
            updateOoOCasesForProjectManager(projectManagerChangedProjectList);
        }

        /*if(activeProjectRelatedAccountIdSet.size() > 0){
            rollupActiveProjectCountOnAccount(activeProjectRelatedAccountIdSet);
        }
        if(closedProjectRelatedAccountIdSet.size() > 0){
            rollupClosedProjectCountOnAccount(closedProjectRelatedAccountIdSet);
        }
        if(onHoldProjectRelatedAccountIdSet.size() > 0){
            rollupOnHoldProjectCountOnAccount(onHoldProjectRelatedAccountIdSet);
        }*/
        if(projectRollupCountRelatedAccountIdSet.size() > 0){
            rollupProjectCountForAccount(projectRollupCountRelatedAccountIdSet);
        }

    }

    public static void afterDelete(List<Project__c> projectList){

        System.debug('***************** Project After Delete ');

        Set<Id> activeProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> closedProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> onHoldProjectRelatedAccountIdSet = new Set<Id>();
        Set<Id> projectRollupCountRelatedAccountIdSet = new Set<Id>();

        for(Project__c project : projectList){

            //DLRS replacement to Apex Work ST 1/9/2023
            if(project.Account__c != null){
                projectRollupCountRelatedAccountIdSet.add(project.Account__c);
                //Active Project Count - Real Time ST 1/9/2023
                /*if(project.Active_Project__c){
                    activeProjectRelatedAccountIdSet.add(project.Account__c);
                }
                //Count Closed Projects ST 1/9/2023
                if(project.Closed_Project__c){
                    System.debug('***************** Project Closed ');
                    closedProjectRelatedAccountIdSet.add(project.Account__c);
                }
                //On Hold Projects Count ST 1/9/2023
                if(project.Project_Status__c == 'On Hold'){
                    onHoldProjectRelatedAccountIdSet.add(project.Account__c);
                }*/
            }
        }

        /*if(activeProjectRelatedAccountIdSet.size() > 0){
            rollupActiveProjectCountOnAccount(activeProjectRelatedAccountIdSet);
        }
        if(closedProjectRelatedAccountIdSet.size() > 0){
            System.debug('***************** Rollup Project Closed ');
            rollupClosedProjectCountOnAccount(closedProjectRelatedAccountIdSet);
        }
        if(onHoldProjectRelatedAccountIdSet.size() > 0){
            rollupOnHoldProjectCountOnAccount(onHoldProjectRelatedAccountIdSet);
        }*/
        if(projectRollupCountRelatedAccountIdSet.size() > 0){
            rollupProjectCountForAccount(projectRollupCountRelatedAccountIdSet);
        }
    }


    private static void projectManagerChanged(List<Project__c> projList){

        //Get Related Parent Opptys
        //Get any COs of the Related Parent Opptys
        //Set the PM of all those Opptys to the PM on the Project
        //Update the Opportunities
        Map<Id, Id> relatedOpptyToPMMap = new Map<Id, Id>();
        for(Project__c proj : projList){
            relatedOpptyToPMMap.put(proj.Opportunity__c, proj.Project_Manager__c);
        }

        List<Opportunity> relatedOpptyList = new List<Opportunity>();
        relatedOpptyList = [SELECT Id, Project_ManagerLookup__c, Change_Orders__c
                            FROM Opportunity
                            WHERE Id IN :relatedOpptyToPMMap.keySet() OR Change_Orders__c IN :relatedOpptyToPMMap.keySet()];

        List<Opportunity> opptyToUpdateList = new List<Opportunity>();
        for(Opportunity relatedOpp : relatedOpptyList){

            if(relatedOpptyToPMMap.containsKey(relatedOpp.Id)){
                relatedOpp.Project_ManagerLookup__c = relatedOpptyToPMMap.get(relatedOpp.Id);
                opptyToUpdateList.add(relatedOpp);
            }else if(relatedOpptyToPMMap.containsKey(relatedOpp.Change_Orders__c)){
                relatedOpp.Project_ManagerLookup__c = relatedOpptyToPMMap.get(relatedOpp.Change_Orders__c);
                opptyToUpdateList.add(relatedOpp);
            }
        }

        if(opptyToUpdateList.size() > 0){
            update opptyToUpdateList;
        }

    }

    private static void updateOoOCasesForProjectManager(List<Project__c> projList){
        
        Map<Id, Id> projToPMMap = new Map<Id, Id>();
        for(Project__c proj : projList){
            projToPMMap.put(proj.Id, proj.Project_Manager__c);
        }

        List<Case> relatedOoOCaseList = new List<Case>();
        relatedOoOCaseList = [SELECT Id, Project__c, ProjectManagerLookup__c, Status
                            FROM Case
                            WHERE RecordTypeId =: OoOCoverageRequestCaseRT AND Project__c IN :projToPMMap.keySet() AND Status != 'Completed' AND Status != 'Cancelled'];

        List<Case> updateCaseList = new List<Case>();
        for(Case c : relatedOoOCaseList){
            if(projToPMMap.containsKey(c.Project__c)){
                c.ProjectManagerLookup__c = projToPMMap.get(c.Project__c);
                updateCaseList.add(c);
            }
        }

        if(updateCaseList.size() > 0){
            update updateCaseList;
        }
    }

    //=========================================================================
    //PRIVATE METHODS
    //=========================================================================
    /**
     * Enqueues a background job to push the Project data from Salesforce to Replicon.
     *
     * @param [Project__c] project The project record to sync with Replicon
     */
    @TestVisible
    private void upsertRepliconProject(Project__c project) {

        System.debug('Updating Project');
        RepliconProjectUpsert projectUpsert = new RepliconProjectUpsert(project.Id,true);
        system.enqueueJob(projectUpsert);
    }

    /**
     * Checks if the fields used in the Replicon integration have changed so that updates
     * can be sent to Replicon if they have.
     *
     * @param [Project__c] project The new project record value from the trigger
     * @param [Project__c] oldProject The old project record value from the trigger
     */
    private Boolean isRepliconFieldsChanged(Project__c project, Project__c oldProject) {
        if(project.Type__c != oldProject.Type__c) return true;
        if(project.Project_Background_Objectives__c != oldProject.Project_Background_Objectives__c) return true;
        if(project.TimeAndExpenseEntry__c != oldProject.TimeAndExpenseEntry__c) return true;
        if(project.Project_Manager__c != oldProject.Project_Manager__c) return true;
        if(project.Account__c != oldProject.Account__c) return true;
        if(project.Name != oldProject.Name) return true;
        if(project.Project_Status__c != oldProject.Project_Status__c) return true;

        return false;
    }

    /**
     * Updates the remaining hours / remaining amount to the account level.
     * Only retrieves active projects with a positive remaining hours / remaining amount
     * (On account, we don't need to see the negative)
     * If any/all projects went negative, updates the value to 0
     *
     * @param [Map<Id, Project__c>] oldMap The map of old record values from the trigger
     * @param [Map<Id, Project__c>] newMap The map of new record values from the trigger
     */
    private void updateProjectDetailsInAccount(Map<Id, Project__c> oldMap, Map<Id, Project__c> newMap) {
        List<Account> updateAccountList = new List<Account>();
        List<Project__c> projList = new List<Project__c>();
        Set<String> prjAccIds = new Set<String>();

        for(Project__c newproj: newMap.values()) {
            Project__c oldProj = oldMap.get(newproj.ID);
            if(newproj.Total_Hours_Invoiced_to_Date__c != oldProj.Total_Hours_Invoiced_to_Date__c ||
                newproj.Total_Amount_Invoiced_to_Date__c != oldProj.Total_Amount_Invoiced_to_Date__c ||
                newProj.SR_Overall_Health_Value__c != oldProj.SR_Overall_Health_Value__c ||
                newProj.Percent_Of_Budget_Remaining__c != oldProj.Percent_Of_Budget_Remaining__c ||
                newproj.Project_Status__c != oldProj.Project_Status__c) {


                if(newProj.Account__c != null){
                    prjAccIds.add(newProj.Account__c); //Add Account Ids to List if project fields have changed
                }
            }

        }

        if(prjAccIds.size() != 0) {           

            //Query for the rest of the projects related to the Accounts
            projList = [SELECT Id, Account__c, Project_Status__c, Remaining_Hours__c, Remaining_Amount__c, Percent_Of_Budget_Remaining__c, SR_Overall_Health_Value__c 
                        FROM Project__c 
                        WHERE Account__c IN :prjAccIds AND Project_Status__c IN ('Active', 'On Hold')]; //Need to only get Active Projects?? Project_Status__c = 'Active'
                        
            System.debug('Proj List: ' + projList);

            Map<Id, Decimal> acctToRemainingHoursMap = new Map<Id, Decimal>();
            Map<Id, Decimal> acctToRemainingAmountMap = new Map<Id, Decimal>();
            Map<Id, Decimal> acctToLowestBudgetPercentMap = new Map<Id, Decimal>();
            Map<Id, String> acctToLowestPHIMap = new Map<Id, String>();

            for(Project__c prj : projList) { //Loop through Projects 

                /************* Rollup functionality for Account Portfolio Available Hours *******************/
                if(acctToRemainingHoursMap.containsKey(prj.Account__c)){ //If Account is already in acctToRemainingHoursMap
                    if(prj.Remaining_Hours__c != null && prj.Remaining_Hours__c >= 0) { //Only rollup positive values for remaining hours
                        Decimal acctRemainingHoursRollup = acctToRemainingHoursMap.get(prj.Account__c) + prj.Remaining_Hours__c; //Add project remaining hours to existing remaining hours for related Account
                        acctToRemainingHoursMap.put(prj.Account__c, acctRemainingHoursRollup); //Add rollup of remaining hours to map of account to Remaining Hours
                    }
                }else{ //If Account is not yet in acctToRemainingHoursMap
                    if(prj.Remaining_Hours__c != null && prj.Remaining_Hours__c >= 0) { //If project remaining hours is 0 or positive initialize map with the value
                        acctToRemainingHoursMap.put(prj.Account__c, prj.Remaining_Hours__c);
                    }else{ //If project remaining hours is negative then initialize map with 0 hours
                        acctToRemainingHoursMap.put(prj.Account__c, 0);
                    }
                }
                /********************************************************************************************/




                /************* Rollup functionality for Account Portfolio Available Dollars *******************/
                if(acctToRemainingAmountMap.containsKey(prj.Account__c)){ //If Account is already in acctToRemainingAmountMap
                    if(prj.Remaining_Amount__c != null && prj.Remaining_Amount__c >= 0) { //Only rollup positive values for remaining hours
                        Decimal acctRemainingAmountRollup = acctToRemainingAmountMap.get(prj.Account__c) + prj.Remaining_Amount__c; //Add project remaining hours to existing remaining hours for related Account
                        acctToRemainingAmountMap.put(prj.Account__c, acctRemainingAmountRollup); //Add rollup of remaining hours to map of account to Remaining Hours
                    }
                }else{ //If Account is not yet in acctToRemainingAmountMap
                    if(prj.Remaining_Amount__c != null && prj.Remaining_Amount__c >= 0) { //If project remaining hours is 0 or positive initialize map with the value
                        acctToRemainingAmountMap.put(prj.Account__c, prj.Remaining_Amount__c);
                    }else{ //If project remaining hours is negative then initialize map with 0 hours
                        acctToRemainingAmountMap.put(prj.Account__c, 0);
                    }
                }
                /**********************************************************************************************/

                //Only set lowest budget remaining percent and lowest PHI Overall Health Value into map to related account
                if(prj.Project_Status__c == 'Active') {

                    /************* Functionality setting Map of Account to Lowest Budget percent of related Projects *******************/
                    if(acctToLowestBudgetPercentMap.containsKey(prj.Account__c)){ //If Account is already in acctToLowestBudgetPercentMap

                        if(prj.Percent_Of_Budget_Remaining__c != null && prj.Percent_Of_Budget_Remaining__c < acctToLowestBudgetPercentMap.get(prj.Account__c)) { //Only set Map of Lowest Budget Remaining if it is lower than what is already in the map for that account
                            acctToLowestBudgetPercentMap.put(prj.Account__c, prj.Percent_Of_Budget_Remaining__c); //Set newest lowest Budget Remaining of Project as the new value in acctToLowestBudgetPercentMap
                        }
                    }else{ //If Account is not yet in acctToLowestBudgetPercentMap
                        if(prj.Percent_Of_Budget_Remaining__c != null) { //If Project Percent of Budget Remaining is not null then initialize map with the value
                            acctToLowestBudgetPercentMap.put(prj.Account__c, prj.Percent_Of_Budget_Remaining__c);
                        }else{ //If Project Percent of Budget Remaining is null then initialize map with 0 percent
                            acctToRemainingAmountMap.put(prj.Account__c, 0);
                        }
                    }
                    /******************************************************************************************************************/




                    /************* Functionality setting Map of Account to Lowest PHI Overall Health value of related Projects *******************/
                    if(acctToLowestPHIMap.containsKey(prj.Account__c)){ //If Account is already in acctToLowestPHIMap

                        if(prj.SR_Overall_Health_Value__c != null){ //Check to ensure Project Project PHI Overall Health Value is not null
                            if(prj.SR_Overall_Health_Value__c == 'Red' && acctToLowestPHIMap.get(prj.Account__c) != 'Red') { //If Project Overall Health is 'RED' AND Account is not ALREADY mapped to a Red value
                                acctToLowestPHIMap.put(prj.Account__c, 'Red'); //Set new lowest Project PHI Overall Health of Project as the new value in acctToLowestPHIMap

                            }else if(prj.SR_Overall_Health_Value__c == 'Yellow' && acctToLowestPHIMap.get(prj.Account__c) != 'Yellow'){ //If Project Overall Health is 'Yellow' AND Account is not ALREADY mapped to a Yellow value
                                acctToLowestPHIMap.put(prj.Account__c, 'Yellow');

                            }else if(prj.SR_Overall_Health_Value__c == 'Green' &&  acctToLowestPHIMap.get(prj.Account__c) != 'Green'){ //If Project Overall Health is 'Green' AND Account is not ALREADY mapped to a Green value
                                acctToLowestPHIMap.put(prj.Account__c, 'Green');    

                            }
                        }
                    }else{ //If Account is not yet in acctToLowestPHIMap
                        if(prj.SR_Overall_Health_Value__c != null) { 
                            acctToLowestPHIMap.put(prj.Account__c, prj.SR_Overall_Health_Value__c);    
                        }else{  
                            acctToLowestPHIMap.put(prj.Account__c, 'Green');   
                        }
                    }
                    /****************************************************************************************************************************/
                }
            }

            //Query for Related Accounts of changed Projects to apply potential updates to
            List<Account> acclist = new List<Account>();
            acclist = [SELECT Id, Porftolio_Available_Hours__c, Porftolio_Available_Dollars__c, Lowest_Overall_PHI_Indicator_Value__c, Lowest_Project_Budget_Remaining_Percent__c
                        FROM Account
                        WHERE Id IN :prjAccIds FOR UPDATE];
            
            for(Account acc : acclist) { //Loop through related Accounts
                Boolean addToUpdateListBool = false; //Boolean to flip if account needs an update for any of the 4 fields

                if(acctToRemainingHoursMap.containsKey(acc.Id)){ //If Account is in Map for Account to Remaining Hours 
                    if(acc.Porftolio_Available_Hours__c != acctToRemainingHoursMap.get(acc.Id)){ //If Account Portfolio Available Hours has changed then change value and set boolean to add it to update list
                        acc.Porftolio_Available_Hours__c = acctToRemainingHoursMap.get(acc.Id);
                        addToUpdateListBool = true;
                    }
                }
                if(acctToRemainingAmountMap.containsKey(acc.Id)){ //If Account is in Map for Account to Remaining Amount 
                    if(acc.Porftolio_Available_Dollars__c != acctToRemainingAmountMap.get(acc.Id)){ //If Account Portfolio Available Dollars has changed then change value and set boolean to add it to update list
                        acc.Porftolio_Available_Dollars__c = acctToRemainingAmountMap.get(acc.Id);
                        addToUpdateListBool = true;
                    }
                }
                if(acctToLowestBudgetPercentMap.containsKey(acc.Id)){ //If Account is in Map for Lowest Project Budget Remaining Amount 
                    if(acc.Lowest_Project_Budget_Remaining_Percent__c != acctToLowestBudgetPercentMap.get(acc.Id)){ //If Account Lowest Project Budget Remaining Percent has changed then change value and set boolean to add it to update list
                        acc.Lowest_Project_Budget_Remaining_Percent__c = acctToLowestBudgetPercentMap.get(acc.Id);
                        addToUpdateListBool = true;
                    }
                }
                if(acctToLowestPHIMap.containsKey(acc.Id)){ //If Account is in Map for Account to Lowest PHI Overall Health Value
                    if(acc.Lowest_Overall_PHI_Indicator_Value__c != acctToLowestPHIMap.get(acc.Id)){ //If Account Lowest Overall PHI Indicator Value has changed then change value and set boolean to add it to update list
                        acc.Lowest_Overall_PHI_Indicator_Value__c = acctToLowestPHIMap.get(acc.Id);
                        addToUpdateListBool = true;
                    }
                }

                if(addToUpdateListBool == true){
                    updateAccountList.add(acc);
                }

            }

            if(updateAccountList.size() > 0){
                try{
                    System.debug('ProjectTriggerHandler: Acc List To Update Size: ' + updateAccountList.size());
                    System.debug('ProjectTriggerHandler: ACC LIST TO UPDATE #########: ' + updateAccountList);
                    update updateAccountList;
                }catch(Exception e){
                    LevExceptionHandler.logError(e, 'ProjectTriggerHandler', 'updateProjectDetailsInAccount', null);
                }
            }
        }
    }

    private static void populateLevSupportEmailFromAccount(List<Project__c> projList){

        Map<Id, Project__c> accountIdToProjMap = new Map<Id, Project__c>();
        for(Project__c proj : projList){
            accountIdToProjMap.put(proj.Account__c, proj);
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Lev_Support_Email_Address__c FROM Account WHERE Id IN :accountIdToProjMap.keySet()];

        Map<Id, Account> accIdToAccountMap = new Map<Id, Account>();
        for(Account acc : relatedAccountList){
            accIdToAccountMap.put(acc.Id, acc);
        }

        for(Project__c proj : projList){
            if(accIdToAccountMap.containsKey(proj.Account__c)){
                if(accIdToAccountMap.get(proj.Account__c).Lev_Support_Email_Address__c != null){
                    proj.Lev_Support_Email_Address__c = accIdToAccountMap.get(proj.Account__c).Lev_Support_Email_Address__c;
                }
            }
        }
    }

    /*public static void rollupActiveProjectCountOnAccount(Set<Id> accountIdSet){

        Map<Id, Integer> accountToActiveProjectCountMap = new Map<Id, Integer>();
        for(Id accountId : accountIdSet){
            accountToActiveProjectCountMap.put(accountId, 0);
        }

        AggregateResult[] projectAgg = [SELECT COUNT(Id), Account__c
                                        FROM Project__c
                                        WHERE Active_Project__c = true AND Account__c IN :accountIdSet
                                        GROUP BY Account__c];

        for(AggregateResult ar : projectAgg){

            Integer projectCount = (Integer)ar.get('expr0');
            Id relatedAccountId = (Id)ar.get('Account__c');

            accountToActiveProjectCountMap.put(relatedAccountId, projectCount);
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, ActiveProjectCount__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){

            if(accountToActiveProjectCountMap.containsKey(acc.Id)){
                Integer activeProjectCount = accountToActiveProjectCountMap.get(acc.Id);
                if(acc.ActiveProjectCount__c != activeProjectCount){
                    acc.ActiveProjectCount__c = activeProjectCount;
                    updateAccountList.add(acc);
                }
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating Active Project Count on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }

    }*/

    /*public static void rollupClosedProjectCountOnAccount(Set<Id> accountIdSet){

        System.debug('***************** rollupClosedProjectCountOnAccount ');

        Map<Id, Integer> accountToClosedProjectCountMap = new Map<Id, Integer>();
        for(Id accountId : accountIdSet){
            accountToClosedProjectCountMap.put(accountId, 0);
        }

        System.debug('***************** accountToClosedProjectCountMap ' + accountToClosedProjectCountMap);

        AggregateResult[] projectAgg = [SELECT COUNT(Id), Account__c
                                        FROM Project__c
                                        WHERE Closed_Project__c = true AND Account__c IN :accountIdSet
                                        GROUP BY Account__c];

        for(AggregateResult ar : projectAgg){

            Integer projectCount = (Integer)ar.get('expr0');
            Id relatedAccountId = (Id)ar.get('Account__c');

            accountToClosedProjectCountMap.put(relatedAccountId, projectCount);
        }

        System.debug('***************** accountToClosedProjectCountMap 2 ' + accountToClosedProjectCountMap);

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, Closed_Projects__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){

            if(accountToClosedProjectCountMap.containsKey(acc.Id)){
                Integer closedProjectCount = accountToClosedProjectCountMap.get(acc.Id);
                if(acc.Closed_Projects__c != closedProjectCount){
                    System.debug('***************** Updating Project Closed Projects Count ' + closedProjectCount);
                    acc.Closed_Projects__c = closedProjectCount;
                    updateAccountList.add(acc);
                }
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating Closed Project Count on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }
    }*/

    /*public static void rollupOnHoldProjectCountOnAccount(Set<Id> accountIdSet){

        Map<Id, Integer> accountToOnHoldProjectCountMap = new Map<Id, Integer>();
        for(Id accountId : accountIdSet){
            accountToOnHoldProjectCountMap.put(accountId, 0);
        }

        AggregateResult[] projectAgg = [SELECT COUNT(Id), Account__c
                                        FROM Project__c
                                        WHERE Project_Status__c = 'On Hold' AND Account__c IN :accountIdSet
                                        GROUP BY Account__c];

        for(AggregateResult ar : projectAgg){

            Integer projectCount = (Integer)ar.get('expr0');
            Id relatedAccountId = (Id)ar.get('Account__c');

            accountToOnHoldProjectCountMap.put(relatedAccountId, projectCount);
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, On_Hold_Projects__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){

            if(accountToOnHoldProjectCountMap.containsKey(acc.Id)){
                Integer onHoldProjectCount = accountToOnHoldProjectCountMap.get(acc.Id);
                if(acc.On_Hold_Projects__c != onHoldProjectCount){
                    acc.On_Hold_Projects__c = onHoldProjectCount;
                    updateAccountList.add(acc);
                }
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating On Hold Project Count on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }
    }*/

    /*public static void rollupTotalProjectCountOnAccount(Set<Id> accountIdSet){

        Map<Id, Integer> accountToTotalProjectCountMap = new Map<Id, Integer>();
        for(Id accountId : accountIdSet){
            accountToTotalProjectCountMap.put(accountId, 0);
        }

        AggregateResult[] projectAgg = [SELECT COUNT(Id), Account__c
                                        FROM Project__c
                                        WHERE Account__c IN :accountIdSet
                                        GROUP BY Account__c];

        for(AggregateResult ar : projectAgg){

            Integer projectCount = (Integer)ar.get('expr0');
            Id relatedAccountId = (Id)ar.get('Account__c');

            accountToTotalProjectCountMap.put(relatedAccountId, projectCount);
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, TotalProjectCount__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){

            if(accountToTotalProjectCountMap.containsKey(acc.Id)){
                Integer totalProjectCount = accountToTotalProjectCountMap.get(acc.Id);
                if(acc.TotalProjectCount__c != totalProjectCount){
                    acc.TotalProjectCount__c = totalProjectCount;
                    updateAccountList.add(acc);
                }
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating Total Project Count on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }
    }*/

    public static void rollupProjectCountForAccount(Set<Id> accountIdSet){

        Map<Id, Decimal> accountIdToTotalProjectCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> accountIdToActiveProjectCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> accountIdToClosedProjectCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> accountIdToOnHoldProjectCountMap = new Map<Id, Decimal>();

        for(Id acctId : accountIdSet){
            accountIdToActiveProjectCountMap.put(acctId, 0);
            accountIdToClosedProjectCountMap.put(acctId, 0);
            accountIdToOnHoldProjectCountMap.put(acctId, 0);
            accountIdToTotalProjectCountMap.put(acctId, 0);
        }

        AggregateResult[] projectAgg = [SELECT COUNT(Id), Account__c, Project_Status__c, Active_Project__c, Closed_Project__c
                                        FROM Project__c
                                        WHERE Account__c IN :accountIdSet
                                        GROUP BY Account__c, Project_Status__c, Active_Project__c, Closed_Project__c
                                        ORDER BY Account__c];

        for(AggregateResult ar : projectAgg){

            Decimal projectCount = (Decimal)ar.get('expr0');
            Id accountId = (Id)ar.get('Account__c');
            String projectStatus = (String)ar.get('Project_Status__c');
            Boolean activeProjectBool = (Boolean)ar.get('Active_Project__c');
            Boolean closedProjectBool = (Boolean)ar.get('Closed_Project__c');

            //Rollup Total Project Count
            Decimal totalProjectCount = accountIdToTotalProjectCountMap.get(accountId);
            totalProjectCount += projectCount;
            accountIdToTotalProjectCountMap.put(accountId, totalProjectCount);

            //Rollup Active Project Count
            if(activeProjectBool){
                Decimal activeProjectCount = accountIdToActiveProjectCountMap.get(accountId);
                activeProjectCount += projectCount;
                accountIdToActiveProjectCountMap.put(accountId, activeProjectCount);
            }

            //Rollup Closed Project Count
            if(closedProjectBool){
                Decimal closedProjectCount = accountIdToClosedProjectCountMap.get(accountId);
                closedProjectCount += projectCount;
                accountIdToClosedProjectCountMap.put(accountId, closedProjectCount);
            }

            //Rollup On Hold Project Count
            if(projectStatus == 'On Hold'){
                Decimal onHoldProjectCount = accountIdToOnHoldProjectCountMap.get(accountId);
                onHoldProjectCount += projectCount;
                accountIdToOnHoldProjectCountMap.put(accountId, onHoldProjectCount);
            }
        }

        List<Account> relatedAccountList = new List<Account>();
        relatedAccountList = [SELECT Id, Name, TotalProjectCount__c, On_Hold_Projects__c, Closed_Projects__c, ActiveProjectCount__c
                                FROM Account
                                WHERE Id IN :accountIdSet];

        List<Account> updateAccountList = new List<Account>();
        for(Account acc : relatedAccountList){
            Boolean needsUpdate = false;
            //Update Total Project Count
            if(accountIdToTotalProjectCountMap.containsKey(acc.Id) && acc.TotalProjectCount__c != accountIdToTotalProjectCountMap.get(acc.Id)){
                acc.TotalProjectCount__c = accountIdToTotalProjectCountMap.get(acc.Id);
                needsUpdate = true;
            }
            //Update Active Project Count
            if(accountIdToActiveProjectCountMap.containsKey(acc.Id) && acc.ActiveProjectCount__c != accountIdToActiveProjectCountMap.get(acc.Id)){
                acc.ActiveProjectCount__c = accountIdToActiveProjectCountMap.get(acc.Id);
                needsUpdate = true;
            }
            //Update Closed Project Count
            if(accountIdToClosedProjectCountMap.containsKey(acc.Id) && acc.Closed_Projects__c != accountIdToClosedProjectCountMap.get(acc.Id)){
                acc.Closed_Projects__c = accountIdToClosedProjectCountMap.get(acc.Id);
                needsUpdate = true;
            }
            //Update On Hold Project Count
            if(accountIdToOnHoldProjectCountMap.containsKey(acc.Id) && acc.On_Hold_Projects__c != accountIdToOnHoldProjectCountMap.get(acc.Id)){
                acc.On_Hold_Projects__c = accountIdToOnHoldProjectCountMap.get(acc.Id);
                needsUpdate = true;
            }

            if(needsUpdate){
                updateAccountList.add(acc);
            }

        }

        if(updateAccountList.size() > 0){
            System.debug('******************* Updating Project Count(s) on ' + updateAccountList.size() + ' Accounts *******************');
            update updateAccountList;
        }   

        
    }
}