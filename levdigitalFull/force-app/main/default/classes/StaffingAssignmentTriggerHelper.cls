public with sharing class StaffingAssignmentTriggerHelper {

    private static String salesforceOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Salesforce').getRecordTypeId();
    private static String changeOrderOpptyRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Change Order').getRecordTypeId();

    public static void createProjTeamMembersFromOpptyCW(List<Opportunity> opptyList){

        List<Id> opptyIdList = new List<Id>();
        for(Opportunity oppty : opptyList){
            opptyIdList.add(oppty.Id);
        }

        if(opptyIdList.size() > 0){
            List<Staffing_Assignment__c> staffingAssignmentList = new List<Staffing_Assignment__c>();
            staffingAssignmentList = [SELECT Id, Name, Opportunity__c, Resource_Assigned__c, Product__c, Status__c, Resource_Delivery_Group__c, Resource_Assigned__r.AccountId 
                                        FROM Staffing_Assignment__c 
                                        WHERE Status__c = 'Completed' AND Opportunity__c IN :opptyIdList ORDER BY Opportunity__c];

            if(staffingAssignmentList.size() > 0){
                createProjectTeamMembersFromStaffingAssignments(staffingAssignmentList);
            }
        }
    }

    public static void createProjectTeamMembersFromStaffingAssignments(List<Staffing_Assignment__c> staffingAssignmentList){
        //Create Internal Project Team Members (Client_Contact__c) on Project when a Staffing Assignment is marked as Complete

        //Process:

        /**
         * Process (High Level):
         * Step 1.) Check if Project exists for the Opportunity yet
         * Step 2.) Check if Project has Contact as Project Team Member yet
         * Step 3.) Create Project Team Member on Project with Estimated HPW, 
         */

        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        
        Map<Id, Id> opptyIdToParentOpptyIdMap = new Map<Id, Id>(); //Map of Oppty Id to the Parent Id (If oppty is a parent Oppty already then it just doubles up on the value so it is just Parent Id to Parent Id)
        Map<Id, Project__c> opptyIdToProjectMap = new Map<Id, Project__c>(); //Create Map of Opportunity Id to the Project
        Map<Id, Product2> productIdToProductMap = new Map<Id, Product2>(); //Map of Product Id to Product Details
        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>();
        Map<id, Contact> userIdToContactMap = new Map<Id, Contact>();
        Map<Id, User> contactIdToUserMap = new Map<Id, User>();

        for(Staffing_Assignment__c sa : staffingAssignmentList){   

            if(sa.Opportunity__c != null){
                opportunityIdSet.add(sa.Opportunity__c);
            }

            if(sa.Product__c != null){
                productIdSet.add(sa.Product__c);
            }

            if(sa.Resource_Assigned__c != null){
                contactIdSet.add(sa.Resource_Assigned__c);
            }
        }

        /******************************** Get Details of Staffing Assignment Opportunity ********************************/
        if(opportunityIdSet.size() > 0){
            List<Opportunity> opptyList = new List<Opportunity>();
            opptyList = [SELECT Id, Name, Change_Orders__c, RecordType.Name, RecordTypeId FROM Opportunity WHERE Id IN :opportunityIdSet];

            for(Opportunity oppty : opptyList){
                if(oppty.RecordTypeId == changeOrderOpptyRT){ //If Oppty is Change Order then get the Parent Oppty Id
                    if(oppty.Change_Orders__c != null){
                        opptyIdToParentOpptyIdMap.put(oppty.Id, oppty.Change_Orders__c);
                    }
                }else{//If Not Change Order then just add the Oppty Id to list
                    opptyIdToParentOpptyIdMap.put(oppty.Id, oppty.Id);
                }
            }
        }

        /******************************** Get Details of Staffing Assignment Project ********************************/
        if(opptyIdToParentOpptyIdMap.size() > 0){
            List<Project__c> projectList = new List<Project__c>();
            projectList = [SELECT Id, Name, Opportunity__c, Account__c, Project_Manager__c FROM Project__c WHERE Opportunity__c IN :opptyIdToParentOpptyIdMap.values()];

            for(Project__c proj : projectList){

                opptyIdToProjectMap.put(proj.Opportunity__c, proj);
            }
        }

        /******************************** Get Details of Staffing Assignment Product ********************************/
        if(productIdSet.size() > 0){
            List<Product2> relatedProductList = new List<Product2>();
            relatedProductList = [SELECT Id, Name FROM Product2 WHERE Id IN :productIdSet];

            for(Product2 prod : relatedProductList){
                productIdToProductMap.put(prod.Id, prod);
            }
        }

        /******************************** Get Details of Staffing Assignment Assigned Resource ********************************/
        if(contactIdSet.size() > 0){
            List<Contact> relatedContactList = new List<Contact>();
            relatedContactList = [SELECT Id, Name, AccountId, Account.Name, ReportsToId, Weekly_Target__c FROM Contact WHERE Id IN :contactIdSet];

            for(Contact con : relatedContactList){
                contactIdToContactMap.put(con.Id, con);
            }
        }

        /******************************** Create the Project Team Members of Staffing Assignment Product ********************************/
        Map<String, Client_Contact__c> uniqueProjTeamMemberIdToProjTeamMemberMap = new Map<String, Client_Contact__c>();
        Set<Id> projectTeamMemberProjectIdSet = new Set<Id>();
        Set<Id> projectTeamMemberContactIdSet = new Set<Id>();
        Set<String> projectTeamMemberProductNameSet = new Set<String>();
        List<Client_Contact__c> projectManagerProjectTeamMemberList = new List<Client_Contact__c>();
        Map<Id, Client_Contact__c> projectIdToProjectManagerClientContact= new Map<Id, Client_Contact__c>();
        for(Staffing_Assignment__c sa : staffingAssignmentList){

            if(sa.Opportunity__c != null && opptyIdToParentOpptyIdMap.containsKey(sa.Opportunity__c) && opptyIdToProjectMap.containsKey(opptyIdToParentOpptyIdMap.get(sa.Opportunity__c))){ //Check to make sure to only create Project Team members if the Project already exists

                Client_Contact__c newProjectTeamMember = new Client_Contact__c();
                newProjectTeamMember.Client_Contact__c = sa.Resource_Assigned__c;
                Project__c relatedProject = opptyIdToProjectMap.get(opptyIdToParentOpptyIdMap.get(sa.Opportunity__c)); //Get the Project for the Parent Oppty Id of the Staffing Assignment Record Opportunity
                newProjectTeamMember.Project__c = relatedProject.Id;
                newProjectTeamMember.Account__c = relatedProject.Account__c;
                newProjectTeamMember.Staffing_Assignment__c = sa.Id;
                newProjectTeamMember.Internal_Project_Team_Member_Name__c = contactIdToContactMap.get(sa.Resource_Assigned__c).Name + ' - ' + relatedProject.Name;

                if(sa.Product__c != null && productIdToProductMap.containsKey(sa.Product__c)){
                    newProjectTeamMember.Contact_Role__c = productIdToProductMap.get(sa.Product__c).Name;

                    if(sa.Resource_Delivery_Group__c != null && ((productIdToProductMap.get(sa.Product__c).Name).contains('Project Manager') || productIdToProductMap.get(sa.Product__c).Name == 'MC - Campaign Manager') && relatedProject.Project_Manager__c == null && (sa.Resource_Delivery_Group__c == 'Lev-NA' || sa.Resource_Delivery_Group__c == 'Lev - NA')){
                        projectManagerProjectTeamMemberList.add(newProjectTeamMember);
                    }
                }

                //Add Project, Contact, and Product to the Sets for querying existing Client Contacts
                projectTeamMemberProjectIdSet.add(newProjectTeamMember.Project__c);
                projectTeamMemberContactIdSet.add(newProjectTeamMember.Client_Contact__c);
                projectTeamMemberProductNameSet.add(newProjectTeamMember.Contact_Role__c);

                //String uniquePTMId = String.valueOf(newProjectTeamMember.Client_Contact__c) + '|' + String.valueOf(newProjectTeamMember.Project__c) + '|' + String.valueOf(newProjectTeamMember.Contact_Role__c);
                String uniquePTMId = String.valueOf(newProjectTeamMember.Client_Contact__c) + '|' + String.valueOf(newProjectTeamMember.Project__c); //Change for Horizon ST 6.6.2023
                System.debug('New Staffing Assignment Unique PTM Id: ' + uniquePTMId);
                uniqueProjTeamMemberIdToProjTeamMemberMap.put(uniquePTMId, newProjectTeamMember);
            }
        }

        /******************************** Check for existing Project Team Members ********************************/
        List<Client_Contact__c> existingProjectTeamMembersList = new List<Client_Contact__c>();
        existingProjectTeamMembersList = [SELECT Id, Name, Project__c, Account__c, Client_Contact__c, Contact_Role__c, Internal_Project_Team_Member_Name__c
                                            FROM Client_Contact__c 
                                            WHERE Project__c IN :projectTeamMemberProjectIdSet AND Client_Contact__c IN :projectTeamMemberContactIdSet
                                            ORDER BY Project__c, Client_Contact__c, Contact_Role__c];

        for(Client_Contact__c existingProjTeamMembers : existingProjectTeamMembersList){

            //String uniquePTMId = String.valueOf(existingProjTeamMembers.Client_Contact__c) + '|' + String.valueOf(existingProjTeamMembers.Project__c) + '|' + String.valueOf(existingProjTeamMembers.Contact_Role__c);
            String uniquePTMId = String.valueOf(existingProjTeamMembers.Client_Contact__c) + '|' + String.valueOf(existingProjTeamMembers.Project__c); //Change for Horizon ST 6.6.2023
            System.debug('Existing Client Contact Unique PTM Id: ' + uniquePTMId);
            if(uniqueProjTeamMemberIdToProjTeamMemberMap.containsKey(uniquePTMId)){
                //If Project Team Member already exists with same Contact, Project, and Product then it will be removed from the insert list
                uniqueProjTeamMemberIdToProjTeamMemberMap.remove(uniquePTMId);
            }

        }

        /******************************** Insert Project Team Members ********************************/
        if(uniqueProjTeamMemberIdToProjTeamMemberMap.size() > 0){
            List<Client_Contact__c> projTeamMembersToInsertList = new List<Client_Contact__c>();
            projTeamMembersToInsertList.addAll(uniqueProjTeamMemberIdToProjTeamMemberMap.values());
            insert projTeamMembersToInsertList;
        }

        /******************************** Link Project Managers to Project Project Manager Lookup ********************************/
        if(projectManagerProjectTeamMemberList.size() > 0){
            linkProjectManagersToProjectFromStaffingAssignment(projectManagerProjectTeamMemberList);
        }
    }

    public static void linkProjectManagersToProjectFromStaffingAssignment(List<Client_Contact__c> projTeamMemberList){

        /**
         * Process:
         * Step 1.) Get Project of Project Manager Team Member
         * Step 2.) If Project Exists then get Active User that has same name or same email as the Contact related to the Project Team Member
         * Step 3.) If Project's Project Manager field is not populated then populate it with the correct User.
         */
        List<Id> projectIdList = new List<Id>();
        List<Id> contactIdList = new List<Id>();
        Map<String, Id> contactNameToContactIdMap = new Map<String, Id>();
        Map<String, Id> contactEmailToContactIdMap = new Map<String, Id>();
        Map<Id, Id> contactIdToUserIdMap = new Map<Id, Id>();

        for(Client_Contact__c ptm : projTeamMemberList){
            if(ptm.Project__c != null){
                projectIdList.add(ptm.Project__c);
            }

            if(ptm.Client_Contact__c != null){
                contactIdList.add(ptm.Client_Contact__c);
            }
        }

        if(contactIdList.size() > 0){
            List<Contact> contactList = new List<Contact>();
            contactList = [SELECT Id, Name, FirstName, LastName, Email FROM Contact WHERE Id IN :contactIdList];

            for(Contact c : contactList){
                contactNameToContactIdMap.put(c.Name, c.Id);
                contactEmailToContactIdMap.put(c.Email, c.Id);
            }
        }

        List<User> userList = new List<User>();
        userList = [SELECT Id, Name, Email, IsActive, ContactId, Contact.Name, Contact.Email 
                    FROM User 
                    WHERE IsActive = true AND UserType = 'Standard' AND (ContactId IN :contactIdList OR Name IN :contactNameToContactIdMap.keySet() OR Email IN :contactEmailToContactIdMap.keySet())];

        for(User u : userList){
            
            if(u.ContactId != null && u.Name == u.Contact.Name){ //If Contact Lookup is populated and that related Contact has the same name as the user then link the two in the map
                contactIdToUserIdMap.put(u.ContactId, u.Id);

            }else if(contactNameToContactIdMap.containsKey(u.Name)){
                contactIdToUserIdMap.put(contactNameToContactIdMap.get(u.Name), u.Id);

            }else if(contactEmailToContactIdMap.containsKey(u.Email)){
                contactIdToUserIdMap.put(contactEmailToContactIdMap.get(u.Email), u.Id);
            }
        }

        List<Project__c> projectList = new List<Project__c>();
        projectList = [SELECT Id, Name, Project_Manager__c FROM Project__c WHERE Id IN :projectIdList];

        Map<Id, Project__c> projIdToProjMap = new Map<Id, Project__c>();
        for(Project__c proj : projectList){
            projIdToProjMap.put(proj.Id, proj);
        }

        /**************************** Populate Project Manager on Projects ****************************/
        List<Id> projectUpdateIdList = new List<Id>();
        List<Project__c> projectUpdateList = new List<Project__c>();
        for(Client_Contact__c ptm : projTeamMemberList){

            if(projIdToProjMap.containsKey(ptm.Project__c) && !projectUpdateIdList.contains(ptm.Project__c)){

                Project__c updateProj = projIdToProjMap.get(ptm.Project__c);

                if(contactIdToUserIdMap.containsKey(ptm.Client_Contact__c) && updateProj.Project_Manager__c == null){
                    updateProj.Project_Manager__c = contactIdToUserIdMap.get(ptm.Client_Contact__c);

                    projectUpdateList.add(updateProj);
                    projectUpdateIdList.add(ptm.Project__c); //Put Project Id into list to make sure that it isn't already in update list
                }
            }
        }

        if(projectUpdateList.size() > 0){
            update projectUpdateList;
        }
    }

    
    public static void countStaffingAssignmentsCreatedOnOppty(Set<Id> opptyIdSet){

        Map<Id, Decimal> opptyIdToStaffingAssignmentCountMap = new Map<Id, Decimal>();
        for(Id opptyId : opptyIdSet){
            opptyIdToStaffingAssignmentCountMap.put(opptyId, 0);
        }

        AggregateResult[] completedStaffingAssignmentAgg = [SELECT COUNT(Id) staffingAssignmentCount, Opportunity__c, Opportunity__r.Name
                                                            FROM Staffing_Assignment__c
                                                            WHERE Opportunity__c IN :opptyIdSet
                                                            GROUP BY Opportunity__c, Opportunity__r.Name
                                                            ORDER BY COUNT(Id) DESC];

        for(AggregateResult ar : completedStaffingAssignmentAgg){
            Id opptyId = (Id)ar.get('Opportunity__c');
            Decimal staffingAssignmentCount = (Decimal)ar.get('staffingAssignmentCount');

            opptyIdToStaffingAssignmentCountMap.put(opptyId, staffingAssignmentCount);
        }

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, Count_of_Created_Staffing_Created__c
                        FROM Opportunity
                        WHERE Id IN :opptyIdToStaffingAssignmentCountMap.keySet()];
        
        List<Opportunity> opptyUpdateList = new List<Opportunity>();
        for(Opportunity oppty : opptyList){

            if(opptyIdToStaffingAssignmentCountMap.containsKey(oppty.Id) && opptyIdToStaffingAssignmentCountMap.get(oppty.Id) != oppty.Count_of_Created_Staffing_Created__c){
                oppty.Count_of_Created_Staffing_Created__c = opptyIdToStaffingAssignmentCountMap.get(oppty.Id);
                opptyUpdateList.add(oppty);
            }
        }

        if(opptyUpdateList.size() > 0){
            System.debug('****************** Updating Staffing Assignment Created Count on ' + opptyUpdateList.size() + ' Opportunities ******************');
            update opptyUpdateList;
        }
    }


    public static void countStaffingAssignmentsCompletedOnOppty(Set<Id> opptyIdSet){

        Map<Id, Decimal> opptyIdToCompletedStaffingAssignmentCountMap = new Map<Id, Decimal>();
        for(Id opptyId : opptyIdSet){
            opptyIdToCompletedStaffingAssignmentCountMap.put(opptyId, 0);
        }

        AggregateResult[] completedStaffingAssignmentAgg = [SELECT COUNT(Id) staffingAssignmentCount, Opportunity__c, Opportunity__r.Name
                                                            FROM Staffing_Assignment__c
                                                            WHERE Opportunity__c IN :opptyIdSet AND Status__c IN ('Completed', 'Cancelled', 'Pending')
                                                            GROUP BY Opportunity__c, Opportunity__r.Name
                                                            ORDER BY COUNT(Id) DESC];

        for(AggregateResult ar : completedStaffingAssignmentAgg){
            Id opptyId = (Id)ar.get('Opportunity__c');
            Decimal completedStaffingAssignmentCount = (Decimal)ar.get('staffingAssignmentCount');

            opptyIdToCompletedStaffingAssignmentCountMap.put(opptyId, completedStaffingAssignmentCount);
        }

        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [SELECT Id, Name, Count_of_Staffing_Completed__c
                        FROM Opportunity
                        WHERE Id IN :opptyIdToCompletedStaffingAssignmentCountMap.keySet()];
        
        List<Opportunity> opptyUpdateList = new List<Opportunity>();
        for(Opportunity oppty : opptyList){

            if(opptyIdToCompletedStaffingAssignmentCountMap.containsKey(oppty.Id) && opptyIdToCompletedStaffingAssignmentCountMap.get(oppty.Id) != oppty.Count_of_Staffing_Completed__c){
                oppty.Count_of_Staffing_Completed__c = opptyIdToCompletedStaffingAssignmentCountMap.get(oppty.Id);
                opptyUpdateList.add(oppty);
            }
        }

        if(opptyUpdateList.size() > 0){
            System.debug('****************** Updating Staffing Assignment Completed Count on ' + opptyUpdateList.size() + ' Opportunities ******************');
            update opptyUpdateList;
        }
    }

}