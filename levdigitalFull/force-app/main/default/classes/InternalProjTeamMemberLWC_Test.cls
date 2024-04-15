@isTest(seeAllData=true)
public with sharing class InternalProjTeamMemberLWC_Test {
    
    @isTest
    static void createTeamMemberName_Test(){
        Project__c testProj = [SELECT Id, Name, Account__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact tesetContact = [SELECT Id, Name FROM Contact WHERE Name = 'Sam Tucker'];

        String teamMemberName = InternalProjTeamMemberLWCController.createProjectTeamMemberName(tesetContact.Id, testProj.Id);

        System.assertEquals(true, teamMemberName.contains('Sam Tucker'), 'The created Team Member name did not properly get created');
    }
    
    @isTest
    static void getInternalProjectTeamMembers_Test(){

        AggregateResult[] teamMemberCount = [SELECT COUNT(Id), Project__c 
                                            FROM Client_Contact__c 
                                            WHERE Project__c != null
                                            GROUP BY Project__c 
                                            ORDER BY COUNT(Id) DESC];

        String projId;
        for(AggregateResult ar : teamMemberCount){
            if(projId == null){
                projId = (String)ar.get('Project__c');
            }
        }

        InternalProjTeamMemberLWCController newController = new InternalProjTeamMemberLWCController();
        InternalProjTeamMemberLWCController.getProjectTeamMembersWrapper(projId);
    }

    @isTest
    static void getInternalProjectTeamMembersWithEffectiveRate_Test(){

        AggregateResult[] teamMemberCount = [SELECT COUNT(Id), Project__c 
                                            FROM Client_Contact__c 
                                            WHERE Project__c != null
                                            GROUP BY Project__c 
                                            ORDER BY COUNT(Id) DESC];

        String projId;
        for(AggregateResult ar : teamMemberCount){
            if(projId == null){
                projId = (String)ar.get('Project__c');
            }
        }

        Client_Contact__c teamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Project__c, Client_Contact__c, Project__r.CreatedDate
                                        FROM Client_Contact__c
                                        WHERE Project__c =: projId
                                        LIMIT 1];


        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate3 = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Solution Architect', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{newBillRate, newBillRate2, newBillRate3};
        insert billRateInsertList;

        teamMember.Assigned_Billing_Rate__c = newBillRate.Id;
        update teamMember;


        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, newBillRate.Id, newBillRate2.Id, Date.today().addDays(-7), teamMember.Project__r.CreatedDate);

        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, newBillRate.Id, newBillRate3.Id, Date.today().addDays(-5), teamMember.Project__r.CreatedDate);

        InternalProjTeamMemberLWCController.getProjectTeamMembersWrapper(projId);
    }

    @isTest
    static void getBillingRatesForAssignment_Test(){

        AggregateResult[] teamMemberCount = [SELECT COUNT(Id), Project__c
                                            FROM Client_Contact__c 
                                            WHERE Project__c != null
                                            GROUP BY Project__c
                                            ORDER BY COUNT(Id) DESC];

        String projId;
        for(AggregateResult ar : teamMemberCount){
            if(projId == null){
                projId = (String)ar.get('Project__c');
            }
        }

        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 210, Project__c = projId, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 210, Project__c = projId, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate3 = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Solution Architect', Hourly_Rate__c = 210, Project__c = projId, Created_in_Salesforce__c = true);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{newBillRate, newBillRate2, newBillRate3};
        insert billRateInsertList;

        List<Project_Team_Member_Billing_Rate__c> billRatesForUseList = InternalProjTeamMemberLWCController.getProjectBillingRatesForAssignment(projId);
        System.assertNotEquals(0, billRatesForUseList.size(), 'The wrong amount of bill rates for assignment was retrieved');
    }

    @isTest
    static void checkIfProjectTeamMemberAlreadyExists_Test(){

        AggregateResult[] teamMemberCount = [SELECT COUNT(Id), Project__c
                                                    FROM Client_Contact__c 
                                                    WHERE Project__c != null
                                                    GROUP BY Project__c
                                                    ORDER BY COUNT(Id) DESC];

        String projId;
        for(AggregateResult ar : teamMemberCount){
            if(projId == null){
                projId = (String)ar.get('Project__c');
            }
        }

        List<Client_Contact__c> teamMemberList = [SELECT Id, Name, Project__c, Client_Contact__c
                                                    FROM Client_Contact__c
                                                    WHERE Project__c =: projId AND Client_Contact__c != null];        

        Boolean projTeamMemberExistsCheck = InternalProjTeamMemberLWCController.checkIfProjectTeamMemberAlreadyExists(projId, teamMemberList[0].Client_Contact__c);

        System.assertEquals(true, projTeamMemberExistsCheck, 'THe check to see if a Project Team Member already exists on a project returned flase when it should have returned true');
    }

    @isTest
    static void getPlaceholderRoles_Test(){

        List<Product2> productsList = new List<Product2>();
        productsList = InternalProjTeamMemberLWCController.getPlaceholderRoles();

        System.assertNotEquals(0, productsList.size(), 'The wrong amount of placeholder roles was retrieved');
    }

    @isTest
    static void createPlaceholder_Test(){

        Project__c testProj = [SELECT Id, Name, Account__c FROM Project__c WHERE Rollup_Billable__c > 0 AND Project_Status__c = 'Active' AND Peoplesoft_Project_Id__c != null LIMIT 1];
        Contact placeholderContact = [SELECT Id, Name FROM Contact WHERE Name = 'Place Holder'];

        List<Product2> placeholderProductRoleList = new List<Product2>();
        placeholderProductRoleList = ProjectForecastingTableController.getPlaceholderRoles();

        Client_Contact__c newPlaceholderTeamMember = InternalProjTeamMemberLWCController.createPlaceholder(testProj.Id, placeholderContact.Id, placeholderProductRoleList[0].Name, placeholderProductRoleList[0].Id);
    }

    @isTest
    static void deleteTeamMember_Test(){

        List<Client_Contact__c> teamMemberList = [SELECT Id, Name, Project__c, Client_Contact__c
                                                    FROM Client_Contact__c
                                                    WHERE Project__c != null AND Client_Contact__c != null];  

        InternalProjTeamMemberLWCController.deleteProjectTeamMember(teamMemberList[0].Id);
    }

    @isTest
    static void createEffectiveRate_Test(){

        Client_Contact__c teamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Project__c, Client_Contact__c, Project__r.CreatedDate
                                        FROM Client_Contact__c
                                        LIMIT 1];


        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate3 = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Solution Architect', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{newBillRate, newBillRate2, newBillRate3};
        insert billRateInsertList;

        teamMember.Assigned_Billing_Rate__c = newBillRate.Id;
        update teamMember;


        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, newBillRate.Id, newBillRate2.Id, Date.today().addDays(7), teamMember.Project__r.CreatedDate);
    }

    @isTest
    static void createEffectiveRate_MakeEffective_Test(){

        Client_Contact__c teamMember = [SELECT Id, Name, Assigned_Billing_Rate__c, Active_Effective_Billing_Rate__c, Project__c, Client_Contact__c, Project__r.CreatedDate
                                        FROM Client_Contact__c
                                        LIMIT 1];


        Project_Team_Member_Billing_Rate__c newBillRate = new Project_Team_Member_Billing_Rate__c(Name = 'Developer', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate2 = new Project_Team_Member_Billing_Rate__c(Name = 'Project Manager', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        Project_Team_Member_Billing_Rate__c newBillRate3 = new Project_Team_Member_Billing_Rate__c(Name = 'CORE - Solution Architect', Hourly_Rate__c = 210, Project__c = teamMember.Project__c, Created_in_Salesforce__c = true);
        List<Project_Team_Member_Billing_Rate__c> billRateInsertList = new List<Project_Team_Member_Billing_Rate__c>{newBillRate, newBillRate2, newBillRate3};
        insert billRateInsertList;

        teamMember.Assigned_Billing_Rate__c = newBillRate.Id;
        update teamMember;


        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, newBillRate.Id, newBillRate2.Id, Date.today().addDays(-7), teamMember.Project__r.CreatedDate);

        InternalProjTeamMemberLWCController.createEffectiveRate(teamMember.Id, newBillRate.Id, newBillRate3.Id, Date.today().addDays(-5), teamMember.Project__r.CreatedDate);
    }


    

}