/**
 * Created 6/27/2022 ST
 * 
 */

@isTest
public with sharing class SkillRatingTrigger_Test {
    
    @TestSetup
    static void makeData(){

        //Create Levementum LLC Account
        Account levementumLLCAcct = TestDataFactory.createAccount(false, 'Partner');
        levementumLLCAcct.Name = 'Levementum LLC';
        insert levementumLLCAcct;

        //Create Contact
        Contact testLevEmployee = TestDataFactory.createEmployee(true, levementumLLCAcct.Id); //Created with Name 'Test Lev Employee'

        //Create Skill Product/Area (Skill_Product_Area__c)
        Skill_Product_Area__c testSkillProdArea1 = new Skill_Product_Area__c();
        testSkillProdArea1.Name = 'Test Skill Product Area #1';
        insert testSkillProdArea1;

        //Create Skill (Skill__c)
        Skill__c testSkill1 = new Skill__c();
        testSkill1.Active__c = true;
        testSkill1.Name = 'Test Skill #1';
        testSkill1.Product_Area__c = testSkillProdArea1.Id;
        insert testSkill1;

        //Create Skill Rating (Skill_Rating__c)
        Skill_Rating__c testSkillRating1 = new Skill_Rating__c();
        testSkillRating1.Resource__c = testLevEmployee.Id;
        testSkillRating1.Rating__c = '0';
        testSkillRating1.Skill__c = testSkill1.Id;
        insert testSkillRating1;
        
    }

    @isTest
    static void testDateSkillRatingLastUpdatedOnInsert(){
        //Test the functionality that populates the DateSkillsMatrixLastUpdated__c field with the current date if a Skill Rating is updated for the Contact

        //Assert that DateSkillsMatrixLastUpdated__c is blank before start
        Contact testContactBefore = [SELECT Id, Name, DateSkillsMatrixLastUpdated__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Id testContactId = testContactBefore.Id;
        System.assertEquals(Date.today(), testContactBefore.DateSkillsMatrixLastUpdated__c, 'Contact\'s Date Skills Matrix Last Updated Field was not properly set when Skill Rating is created.');
    }

    @isTest
    static void testDateSkillRatingLastUpdatedOnUpdate(){
        //Test the functionality that populates the DateSkillsMatrixLastUpdated__c field with the current date if a Skill Rating is updated for the Contact

        //Assert that DateSkillsMatrixLastUpdated__c is blank before start
        Contact testContactBefore = [SELECT Id, Name, DateSkillsMatrixLastUpdated__c FROM Contact WHERE Name = 'Test Lev Employee' LIMIT 1];
        Id testContactId = testContactBefore.Id;
        testContactBefore.DateSkillsMatrixLastUpdated__c = null;
        update testContactBefore;

        //Query for Skill Rating for the Contact and Update the Skill Rating
        Skill_Rating__c testSkillRating = [SELECT Id, Name, Resource__c, Rating__c, Skill__c FROM Skill_Rating__c WHERE Resource__c =: testContactId LIMIT 1];
        testSkillRating.Rating__c = '3';
        update testSkillRating;

        //Assert the Contact DateSkillsMatrixLastUpdated__c is = current date
        Contact testContactAfter = [SELECT Id, Name, DateSkillsMatrixLastUpdated__c FROM Contact WHERE Id =: testContactId LIMIT 1];
        System.assertEquals(Date.today(), testContactAfter.DateSkillsMatrixLastUpdated__c, 'Contact\'s Date Skills Matrix Last Updated Field was not properly updated after a related Skill Rating was updated.');
    }
}