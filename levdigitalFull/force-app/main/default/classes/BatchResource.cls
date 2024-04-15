public class BatchResource {

    private static Set<Id> projectIdUpdateList = new Set<Id>();
    private static Boolean repliconTimeEntryBatchIsRunning = false;
    
    public static void addToProjectIdUpdateSet(Set<Id> newProjectIdSet){
        projectIdUpdateList.addAll(newProjectIdSet);
    }

    public static Set<Id> getProjectUpdateSet(){
        return projectIdUpdateList;
    }

    public static void setRepliconTimeEntryBatchAsRunning(){
        repliconTimeEntryBatchIsRunning = true;
    }

    public static Boolean isRepliconTimeEntryBatchRunning(){
        return repliconTimeEntryBatchIsRunning;
    }
}