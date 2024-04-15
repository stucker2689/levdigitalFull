@isTest
private class RegTest2{
    @isTest
    static void createUser_Test(){
        RegHandler newHandler = new RegHandler();
        newHandler.createUser(null, null);
    }
    @isTest
    static void updateUser_Test(){
        RegHandler newHandler = new RegHandler();
        newHandler.updateUser(null, null, null);
    }
}