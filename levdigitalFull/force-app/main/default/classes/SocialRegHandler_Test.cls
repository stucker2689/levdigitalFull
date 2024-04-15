@isTest(SeeAllData=true)
public with sharing class SocialRegHandler_Test {

    static testMethod void testCreateAndUpdateUser() {
        SocialRegHandler handler = new SocialRegHandler();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
            'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
            null, new Map<String, String>{'language' => 'en_US'});
        User u = handler.createUser(null, sampleData);
        /*System.assertEquals('testFirst.50396097@social-sign-on.com', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);
        System.assertEquals('testuser', u.alias);*/
        insert(u);
        String uid = u.id;
        
        sampleData = new Auth.UserData('testNewId', 'testNewFirst', 'testNewLast',
            'testNewFirst testNewLast', 'testnewuser@example.org', null, 'testnewuserlong', 'en_US', 'facebook',
            null, new Map<String, String>{});
        handler.updateUser(uid, null, sampleData);
        
        User updatedUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:uid];
        /*System.assertEquals('testnewuserlong@salesforce.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        System.assertEquals('testNewLast', updatedUser.lastName);
        System.assertEquals('testNewFirst', updatedUser.firstName);
        System.assertEquals('testnewu', updatedUser.alias);*/
    }

    static testMethod void testCreateAndUpdateUserWithNetworkId() {
        Map<String, String> authUserAttMap = new Map<String, String>();
        authUserAttMap.put('sfdc_networkid', '12345');
        authUserAttMap.put('language', 'en_US');
        SocialRegHandler handler = new SocialRegHandler();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
            'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
            null, authUserAttMap);
        User u = handler.createUser(null, sampleData);
        /*System.assertEquals('testFirst.50396097@social-sign-on.com', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);
        System.assertEquals('testuser', u.alias);*/
        insert(u);
        String uid = u.id;
        
       
        /*System.assertEquals('testnewuserlong@salesforce.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        System.assertEquals('testNewLast', updatedUser.lastName);
        System.assertEquals('testNewFirst', updatedUser.firstName);
        System.assertEquals('testnewu', updatedUser.alias);*/
    }

    static testMethod void testCreateAndUpdateUserWithNetworkIdAndAccount() {

        Account socialSignOnAcct = TestDataFactory.createAccount(false, 'Partner');
        socialSignOnAcct.Name = 'Social Sign-On';
        insert socialSignOnAcct;

        Map<String, String> authUserAttMap = new Map<String, String>();
        authUserAttMap.put('sfdc_networkid', '12345');
        authUserAttMap.put('language', 'en_US');
        SocialRegHandler handler = new SocialRegHandler();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
            'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
            null, authUserAttMap);
        User u = handler.createUser(null, sampleData);
        /*System.assertEquals('testFirst.50396097@social-sign-on.com', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);
        System.assertEquals('testuser', u.alias);*/
        insert(u);
        String uid = u.id;
        
       
        /*System.assertEquals('testnewuserlong@salesforce.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        System.assertEquals('testNewLast', updatedUser.lastName);
        System.assertEquals('testNewFirst', updatedUser.firstName);
        System.assertEquals('testnewu', updatedUser.alias);*/
    }
}