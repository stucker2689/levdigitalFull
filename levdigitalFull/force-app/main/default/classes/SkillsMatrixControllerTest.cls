/*
 * Description: Skills Matrix test coverage
 * Author: Michelle McLane 
 * Date: April 21, 2020
 * Updated: July 22, 2020
 */
@isTest
public class SkillsMatrixControllerTest {
    @TestSetup
    public static void getTestData() {
        Id recordId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Id acctRcdId = Schema.SObjectType.Account.getRecordTypeinfosByName().get('Client').getRecordTypeId();
        Account a = new Account();
        a.Name = 'Levementum LLC';
        a.RecordTypeId = acctRcdId;
        a.PrimaryPractice__c = 'SFDC-Core';
        a.Salesforce_Business_Unit__c = 'Enterprise';
        a.LevementumVertical__c = 'Other';
        a.Lead_Source_Category__c = 'Levementum';
        a.Lead_Source__c = 'Employee';
        insert a;
        
        //Create Employees
        List<Contact> employees = new List<Contact>();        
        for(Integer i = 0; i < 20; i++){
            Contact cont = new Contact();
            cont.FirstName = 'Test';
            cont.LastName = 'Lev' + i + 'Setup';
            cont.RecordTypeId = recordId;
            cont.AccountId = a.Id;
            cont.Division__c = 'Projects - CORE';
            cont.Department = 'Operations';
            cont.Active__c = true;
            employees.add(cont);
        }
        
        insert employees;

        //Create Product Area
        Skill_Product_Area__c  pa = new Skill_Product_Area__c ();
        pa.Name = 'Core Tasks';
        pa.Category__c = 'Core';
        insert pa;
        
        //Insert Skills
        List<Skill__c> skills = new List<Skill__c>();
        for(Integer i = 0; i < 20; i++) {
            Skill__c s = new Skill__c();
            s.Name = 'Apex Developing ' + i;
            s.Product_Area__c = pa.Id;
            s.Active__c = true;
            s.Description__c = 'Apex is awesome';
            skills.add(s);
        }
        insert skills;
        
        //insert skill ratings
        List<Skill_Rating__c> ratings = new List<Skill_Rating__c>();
        for(Integer i = 0; i < 20; i++) {
            Contact c = employees[i];
            Skill_Rating__c r = new Skill_Rating__c();
            r.Skill__c = skills[i].Id;
            r.Rating__c = '1';
            r.Area_of_Focus__c = false;
            r.Resource__c = c.Id;
            ratings.add(r);
        }
        
        insert ratings;
    }
    
    //Test Successful insert of Skills Ratings
    public testmethod static void getSkillMatrixSuccess() {
        List<Skill_Rating__c> s = [SELECT Id, Skill__c, Rating__c, Area_of_Focus__c FROM Skill_Rating__c WHERE Rating__c = '1'];
        List<Skill__c> sk = [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c];
        Contact cont = [SELECT Id, LastName FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        Test.startTest();
        System.assertEquals(20, s.size());
        System.assertEquals(20, sk.size());
        Test.stopTest();
 
    }
    
    //Test Successful retrieving of Skills Matrix Data
    public testmethod static void getSkillMatrixDataSuccess() {
        List<Skill_Rating__c> s = [SELECT Id, Skill__c, Rating__c, Area_of_Focus__c FROM Skill_Rating__c WHERE Rating__c = '1'];
        List<Skill__c> sk = [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c];
        Contact cont = [SELECT Id, LastName FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
		List<SkillsMatrixController.SkillsMatrixData> data = SkillsMatrixController.getSkillsMatrixRows(cont.Id);
        Test.stopTest();
    }
    
    //Test failure of getting Skills Data
    public testmethod static void getSkillMatrixDataFailure() {
        List<Skill_Rating__c> s = [SELECT Id, Skill__c, Rating__c, Area_of_Focus__c FROM Skill_Rating__c WHERE Rating__c = '1'];
        List<Skill__c> sk = [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c];
        Contact cont = [SELECT Id, LastName FROM Contact WHERE FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
		List<SkillsMatrixController.SkillsMatrixData> data = SkillsMatrixController.getSkillsMatrixRowsByContact(cont.Id);
        Test.stopTest();
    }
    
    //Test successful save of Skills Matrix data
    public testmethod static void saveSkillMatrixDataSuccess() {
        List<String> skill = new List<String>(); 
        List<String> newSkills = new List<String>();
        List<Skill__c> sk = [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c];
        System.debug('sk ' + sk);
        for(Skill__c s : sk) {
            String newSkill = '{"Skill__c": "' + s.Id + '", "Rating__c": "1", "Area_of_Focus__c": true}';
            skill.add(newSkill);
        }
        
        for(Skill__c s : sk) {
            String newSkill = '{"Skill__c": "' + s.Id + '", "Rating__c": "2", "Area_of_Focus__c": true}';
            newSkills.add(newSkill);
        }
        String skillsMap = '[';
        skillsMap = skillsMap + String.join(skill, ',');
        String existingSkills = '[';
        existingSkills = existingSkills + String.join(newSkills, ',');
        skillsMap = skillsMap + ']';
        existingSkills = existingSkills + ']';
        String resourceId = [SELECT Id, LastName FROM Contact WHERE FirstName = 'Test' LIMIT 1].Id;
        Test.startTest();
		SkillsMatrixController.saveRows(skillsMap, existingSkills, resourceId);
        Test.stopTest();   
    }
    
    //Test failure save of Skills Matrix data
    public static void saveSkillMatrixDataFailure() {
        List<String> skill = new List<String>(); 
        List<String> newSkills = new List<String>();
        List<Skill__c> sk = [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c];
        System.debug('sk ' + sk);
        for(Skill__c s : sk) {
            String newSkill = '{"Skill__c": "' + s.Id + '", "Rating__c": "1", "Area_of_Focus__c": true}';
            skill.add(newSkill);
        }
        
        for(Skill__c s : sk) {
            String newSkill = '{"Skill__c": "' + s.Id + '", "Rating__c": "2", "Area_of_Focus__c": true}';
            newSkills.add(newSkill);
        }
        String skillsMap = '[';
        skillsMap = skillsMap + String.join(skill, ',');
        String existingSkills = '[';
        existingSkills = existingSkills + String.join(newSkills, ',');
        skillsMap = skillsMap + ']';
        existingSkills = existingSkills + ']';
        Contact c = new Contact();
        Test.startTest();
		SkillsMatrixController.saveRows(skillsMap, existingSkills, c.Id);
        Test.stopTest();  
    }
    
    //Test Successful insert of Employee Skills when new Contact is created
    public testmethod static void testInsertSkillsContactMatrixSucess() {
        List<Contact> employees = TestDataFactory.createEmployee(100, true);
        
        Test.startTest();
        SkillsMatrixService.insertEmployeeSkills(employees);
        List<Skill_Rating__c> skills = [SELECT Id FROM Skill_Rating__c WHERE Resource__c in: employees];
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];
        
        //Assert new skills have been created for the new 100 employees
        System.assertEquals(2000, skills.size());
        System.assertEquals(1, errors.size());

        Test.stopTest();
    }
    
	//Test Successful delete of employee when it becomes inactive    
    public testmethod static void testDeleteSkillsMatrixSucess() {
        List<Contact> employees = TestDataFactory.createEmployee(100, true);
        List<Skill_Rating__c> ratings = TestDataFactory.createRatings(employees, true);
        
        Test.startTest();
        SkillsMatrixService.deleteEmployeeSkills(employees);
        List<Skill_Rating__c> skills = [SELECT Id FROM Skill_Rating__c WHERE Resource__c in: employees];
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];

        //Assert the skills have been deleted for the inactive employee and no errors
        System.assertEquals(0, skills.size());
        System.assertEquals(2, errors.size());

        Test.stopTest();
    }

    //Test successful insert of new Skill and auto creation of skills ratings
    public testmethod static void testInsertSkillsMatrixSuccess() {
        List<Skill__c> newSkill = TestDataFactory.createSkills(10, true);
        List<Contact> employees = TestDataFactory.createEmployee(10, true);
        
        Test.startTest();
        SkillsMatrixService.insertNewSkills(newSkill); 
        List<Skill_Rating__c> skills = [SELECT Id, Resource__r.Name FROM Skill_Rating__c];
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];
        System.assertEquals(820, skills.size());
        System.assertEquals(3, errors.size());
        Test.stopTest();
    }    
    
    //Test failure insert of Employee Skills when new Contact is created
    public testmethod static void testInsertSkillsContactMatrixFailure() {
        List<Contact> employees = TestDataFactory.createEmployee(100, false);
        Test.startTest();
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];
        System.assertEquals(1, errors.size());
        SkillsMatrixService.insertEmployeeSkills(null);
        Test.stopTest();
    }
    
    //Test failure delete of employee when it becomes inactive        
    public testmethod static void testDeleteSkillsMatrixFailure() {
        List<Contact> employees = TestDataFactory.createEmployee(100, true);
        List<Skill_Rating__c> ratings = TestDataFactory.createRatings(employees, true);
        Test.startTest();
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];
        System.assertEquals(2, errors.size());
        SkillsMatrixService.deleteEmployeeSkills(null);
        Test.stopTest();
    }
    
    //Test failure insert of new Skill and auto creation of skills ratings
    public testmethod static void testInsertSkillsMatrixFailure() {
        List<Skill__c> newSkill = TestDataFactory.createSkills(10, true);
        Test.startTest();
        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c WHERE Function__c = 'SkillsMatrixService.insertNewSkill'];
        System.assertEquals(2, errors.size());
        SkillsMatrixService.insertNewSkills(null);
        Test.stopTest();
    }    
    
    //
    public testmethod static void testInsertContactSuccess() {
        Test.startTest();
        List<Contact> emp = [SELECT Id, Name FROM Contact WHERE FirstName = 'Test'];
        for(Contact c : emp) {
            c.Active__c = false;
        }
        update emp;
        Test.stopTest();
    }   
}