/* Author: Michelle McLane 
 * Date: July 20, 2020
 */
trigger SkillTrigger on Skill__c (after insert) {

    //Handle After Insert routing
    if(Trigger.isAfter && Trigger.isInsert) {
		
        //Route Skill to Skill Matrix Service
        SkillsMatrixService.insertNewSkills(Trigger.new);
    }
}