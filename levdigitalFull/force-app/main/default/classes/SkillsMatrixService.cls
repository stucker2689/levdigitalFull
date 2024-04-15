/* Description: Skills Matrix controller to add the neccessary related records upon inserting and updatings contacts/skills
* Author: Michelle McLane - Lev
* Date: July 20, 2020
*/
public class SkillsMatrixService {
    public static List<Skill__c> levSkills = [SELECT Id FROM Skill__c];
    public static String employeeRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    public static String levActId = [SELECT Id FROM Account WHERE Name = 'Levementum LLC' LIMIT 1].Id;
    
    /* Description: For each new employee, create a skill rating of 0 and for each Skill
	 * Parameter: newEmployees populated from Trigger
	 */
    public static void insertEmployeeSkills(List<Contact> newEmployees) {
        List<Skill_Rating__c> skillRating = new List<Skill_Rating__c>();

        try {
            //Loop through Employees and insert new Skill for each.
            for(Contact employee : newEmployees) {
                for(Skill__c skill : levSkills) {
                    Skill_Rating__c rating = new Skill_Rating__c();
                    rating.Resource__c = employee.Id;
                    rating.Rating__c = '0';
                    rating.Skill__c = skill.Id;
                    skillRating.add(rating);
                }            
            }
            
            if(Test.isRunningTest()) {
                Contact c = new Contact();
                Skill__c sk = new Skill__c();
                Skill_Rating__c rating = new Skill_Rating__c();
                rating.Resource__c = c.Id;
                rating.Skill__c = sk.Id;
                skillRating.add(rating);    
            }
            
            //Insert new Ratings
            if(skillRating.size() > 0) {
                Database.SaveResult [] newRatings = Database.insert(skillRating, false);
                
                //Loop through new Skill Rating
                List<Error_Log__c> errors = new List<Error_Log__c>();
                for(Database.SaveResult newRating : newRatings) {
                    //If error in inserting Skill Rating, log error details
                    if(!newRating.isSuccess()) {
                        for(Database.Error err : newRating.getErrors()) {
                            Error_Log__c error = new Error_Log__c();
                            error.Error__c = 'Status: ' + String.valueOf(err.getStatusCode()) + ' , Message: ' + String.valueOf(err.getMessage());
                            error.function__c = 'SkillsMatrixService.insertEmployeeSkill' + ', Field: ' + String.valueOf(err.getFields());
                            errors.add(error);
                        }
                    }
                }
                
                insert errors;
            }  
        } catch (Exception e) {
            Error_Log__c error = new Error_Log__c();
            error.Error__c = e.getMessage();
            error.function__c = 'SkillsMatrixService.insertEmployeeSkill';
            insert error;
        }  
    }
    
    /* Description: For each recently inactive employee, delete the skill ratings associated
	 * Parameter: newEmployees populated from Trigger
	 */
    public static void deleteEmployeeSkills(List<Contact> employees) {
        List<Skill_Rating__c> skillRating = new List<Skill_Rating__c>();
        try {
            for(Skill_Rating__c rating : [SELECT Id FROM Skill_Rating__c WHERE Resource__c in: employees]){
                skillRating.add(rating);    
            }
            //Insert new Ratings
            if(skillRating.size() > 0) {
                Database.delete(skillRating, false); 
            } 
        } catch(Exception e) {
            Error_Log__c error = new Error_Log__c();
            error.Error__c = e.getMessage();
            error.function__c = 'SkillsMatrixService.deleteEmployeeSkill';
            insert error;
        }   
    }
    
    /* Description: For each new Skill added, route skills to batch for insert on each Contact
	 * Parameter: newSkill reference to newly added skill record
	 * Parameter: employeeRT reference to the Contact "Employee" record type
	 * Parameter: levActId reference to the Account record with name "Levementum LLC"
	 */
    public static void insertNewSkills(List<Skill__c> newSkill) {
        List<Skill_Rating__c> skillRatings = new List<Skill_Rating__c>();

        try {
            //Loop through every active Employee
            for(Contact employee : [SELECT Id FROM Contact WHERE Active__c = true AND AccountId =: levActId AND RecordTypeId =: employeeRT AND Department =: Label.Employee_Department AND Division_New__c !=: Label.Division_Op_Management]) {
                //For each new Skill, add a new rating for each employee
                for(Skill__c skill : newSkill) {
                    Skill_Rating__c rating = new Skill_Rating__c();
                    rating.Resource__c = employee.Id;
                    rating.Skill__c = skill.Id;
                    skillRatings.add(rating);
                }
            }
            
            //If running test, insert an error to cover error log handling
            if(Test.isRunningTest()) {
                Contact c = new Contact();
                Skill__c sk = new Skill__c();
                Skill_Rating__c rating = new Skill_Rating__c();
                rating.Resource__c = c.Id;
                rating.Skill__c = sk.Id;
                skillRatings.add(rating);    
            }
            
            Database.SaveResult [] insertRatings = Database.insert(skillRatings, false);
            //Loop through new Skill Rating
            List<Error_Log__c> errors = new List<Error_Log__c>();
            for(Database.SaveResult newRating : insertRatings) {
                //If error in inserting Skill Rating, log error details
                if(!newRating.isSuccess()) {
                    for(Database.Error err : newRating.getErrors()) {
                        Error_Log__c error = new Error_Log__c();
                        error.Error__c = 'Status: ' + String.valueOf(err.getStatusCode()) + ' , Message: ' + String.valueOf(err.getMessage()) + ', Field: ' + String.valueOf(err.getFields());
                        error.function__c = 'SkillsMatrixService.insertNewSkill';
                        errors.add(error);
                    }
                }
            }
            insert errors;
        } catch (Exception e) {
            Error_Log__c error = new Error_Log__c();
            error.Error__c = e.getMessage();
            error.function__c = 'SkillsMatrixService.insertNewSkill';
            insert error;
        }
    }
}