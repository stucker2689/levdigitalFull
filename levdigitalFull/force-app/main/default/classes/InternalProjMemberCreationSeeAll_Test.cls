@isTest(seeAllData=true)
public with sharing class InternalProjMemberCreationSeeAll_Test {

    @isTest
    static void testForecastBatchRun(){

        AggregateResult[] teamMemberAgg = [SELECT COUNT(Id), Project__c, Project__r.Name, Project__r.Project_Status__c
                                            FROM RepliconForecast__c
                                            GROUP BY Project__c, Project__r.Name, Project__r.Project_Status__c
                                            HAVING COUNT(Id) > 5 AND COUNT(Id) < 100
                                            ORDER BY COUNT(Id) DESC];

        List<Id> projIdList = new List<Id>();                               
        for(AggregateResult ar : teamMemberAgg){
            if(projIdList.size() < 2){
                projIdList.add((Id)ar.get('Project__c'));
            }
        }

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Forecast', projIdList);
        Database.executeBatch(newProjTeamMemberCreationBatch, 500);

    }

    @isTest
    static void testForecastBatchRunWithPlaceholders(){

        AggregateResult[] teamMemberAgg = [SELECT COUNT(Id), Project__c, Project__r.Name, Project__r.Project_Status__c
                                            FROM RepliconForecast__c
                                            WHERE Contact__r.Name = 'Place Holder' AND Project__c != null
                                            GROUP BY Project__c, Project__r.Name, Project__r.Project_Status__c
                                            HAVING COUNT(Id) < 500
                                            ORDER BY COUNT(Id) DESC];

        List<Id> projIdList = new List<Id>();                               
        for(AggregateResult ar : teamMemberAgg){
            if(projIdList.size() < 1){
                projIdList.add((Id)ar.get('Project__c'));
            }
        }

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Forecast', projIdList);
        Database.executeBatch(newProjTeamMemberCreationBatch, 1000);

    }

    @isTest
    static void testTimeEntryBatchRun(){

        AggregateResult[] teamMemberAgg = [SELECT COUNT(Id), Project__c, Project__r.Name, Project__r.Project_Status__c
                                            FROM Replicon_Time_Entry__c
                                            WHERE Project__c != null
                                            GROUP BY Project__c, Project__r.Name, Project__r.Project_Status__c
                                            HAVING COUNT(Id) > 5 AND COUNT(Id) < 100
                                            ORDER BY COUNT(Id) DESC];

        List<Id> projIdList = new List<Id>();                               
        for(AggregateResult ar : teamMemberAgg){
            if(projIdList.size() < 2){
                projIdList.add((Id)ar.get('Project__c'));
            }
        }

        InternalProjectMemberCreationBatch newProjTeamMemberCreationBatch = new InternalProjectMemberCreationBatch('Time Entry', projIdList);
        Database.executeBatch(newProjTeamMemberCreationBatch, 1000);

    }


}