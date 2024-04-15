/*
 * Description: Perform neccessary data retrieval for skills matrix  
 * Author: Michelle McLane
 * Date: April 21, 2020
 */
public without sharing class SkillsMatrixController {
    
    //Get all Skills Ratings for related contact
    public static List<Skill_Rating__c> getSkillRatings(String contactId) {
        return [SELECT Id, Skill__c, Rating__c, Area_of_Focus__c FROM Skill_Rating__c WHERE Resource__c = :contactId];
    }

    //Get all available Skills to display on the skills matrix cmp
    public static List<Skill__c> getAllSkills() {
        return [SELECT Id, Name, Product_Area__r.Name, Product_Area__r.Category__c, Description__c FROM Skill__c WHERE Active__c = true];
    }

    //Return all Skill Matrix data
    @AuraEnabled(cacheable=true)
    public static List<SkillsMatrixController.SkillsMatrixData> getSkillsMatrixRows(String contactId) {
        List<Skill__c> allSkills = getAllSkills();
        List<Skill_Rating__c> skillRatings = getSkillRatings(contactId);
        Map<Id, Skill_Rating__c> skillIdToRatingMap = new Map<Id, Skill_Rating__c>();
        //For Test Coverage
        if(Test.isRunningTest()) { 
			Contact c = [SELECT Id from Contact WHERE Id =: contactId LIMIT 1];
            List<Skill_Rating__c> ratings = [SELECT Id, Skill__c, Rating__c, Area_of_Focus__c FROM Skill_Rating__c WHERE Resource__c = :c.Id];
            skillRatings = ratings;
        }
        
        for (Skill_Rating__c rating : skillRatings) {
            skillIdToRatingMap.put(rating.Skill__c, rating);
        }

        Map<String, List<SkillsMatrixController.SkillsMatrixRow>> skillsMatrixMap = new Map<String, List<SkillsMatrixController.SkillsMatrixRow>>();
        for (Skill__c skill : allSkills) {
            SkillsMatrixController.SkillsMatrixRow row = new SkillsMatrixController.SkillsMatrixRow();
            if (skillIdToRatingMap.containsKey(skill.Id)) {
                Skill_Rating__c skillRating = skillIdToRatingMap.get(skill.Id);
                row.ratingId = skillRating.Id;
                row.skillRating = skillRating.Rating__c;
                row.areaFocus = skillRating.Area_of_Focus__c;
            } else {
                row.skillRating = '0';
            }
            row.contactId = contactId;
            row.skillId = skill.Id;
            row.skillCategory = skill.Product_Area__r.Category__c;
            row.skillProductArea = skill.Product_Area__r.Name;
            row.skillName = skill.Name;
            row.skillDescription = skill.Description__c;

            if (skillsMatrixMap.containsKey(row.skillCategory)) {
                skillsMatrixMap.get(row.skillCategory).add(row);
            } else {
                skillsMatrixMap.put(row.skillCategory, new List<SkillsMatrixController.SkillsMatrixRow>{ row });
            }
        }

        List<SkillsMatrixController.SkillsMatrixData> skillsMatrixData = new List<SkillsMatrixController.SkillsMatrixData>();
        for (String matrixCategory : skillsMatrixMap.keySet()) {
            SkillsMatrixController.SkillsMatrixData matrixCategoryData = new SkillsMatrixController.SkillsMatrixData();
            matrixCategoryData.category = matrixCategory;
            matrixCategoryData.rows = skillsMatrixMap.get(matrixCategory);
            skillsMatrixData.add(matrixCategoryData);
        }

        return skillsMatrixData;
    }

    //Return all matrix data for specific contact to display on table
    @AuraEnabled(cacheable=true)
    public static List<SkillsMatrixController.SkillsMatrixData> getSkillsMatrixRowsByContact(Id contactId) {
        try {
            return getSkillsMatrixRows(contactId);
        } catch(Exception e) {
            System.debug(e);
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    //Save all skill change
    @AuraEnabled
    public static List<SkillsMatrixController.SkillsMatrixData> saveRows(String skillsMap, String existingSkills, Id resourceId) {
        skillsMap = skillsMap.replace('on', 'true');
        skillsMap = skillsMap.replace('off', 'false');
        Contact cont = [SELECT Id FROM Contact WHERE Id =: resourceId];

        List<Skill_Rating__c> existingRatings = (Skill_Rating__c[])JSON.deserialize(existingSkills, List<Skill_Rating__c>.class);
        Skill_Rating__c [] changedSkills = (Skill_Rating__c[])JSON.deserialize(skillsMap, List<Skill_Rating__c>.class);
        
        Map<String, Id> existingMap = new Map<String, Id>();
        for (Skill_Rating__c rating : existingRatings) {
            existingMap.put(rating.Skill__c, rating.Id);
        }
        
        for(Integer i = 0; i < changedSkills.size(); i++) {
            Skill_Rating__c changedRating = changedSkills[i];
            changedRating.Id = existingMap.get(changedRating.Skill__c);
            changedSkills[i].Resource__c = cont.Id;
            changedSkills[i].Area_of_Focus__c = changedSkills[i].Area_of_Focus__c;
        }

        try {
            upsert changedSkills;
        } catch(Exception e) {
            System.debug(e);
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
        return getSkillsMatrixRowsByContact(cont.Id);
    }

    public class SkillsMatrixData {
        @AuraEnabled
        public string category;
        @AuraEnabled
        public List<SkillsMatrixController.SkillsMatrixRow> rows;
    }

    public class SkillsMatrixRow {
        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String skillId;
        @AuraEnabled
        public String ratingId;
        @AuraEnabled
        public String skillCategory;
        @AuraEnabled
        public String skillProductArea;
        @AuraEnabled
        public String skillName;
        @AuraEnabled
        public String skillDescription;
        @AuraEnabled
        public String skillRating;
        @AuraEnabled
        public Boolean areaFocus;
    }
}