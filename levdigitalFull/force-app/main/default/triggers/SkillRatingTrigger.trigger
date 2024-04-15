/**
 * Created 6/27/2022 ST
 */

trigger SkillRatingTrigger on Skill_Rating__c (before insert, after insert, before update, after update) {

    if(Trigger.isAfter && Trigger.isInsert){
        if(Test.isRunningTest()){
            SkillRatingTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

	if(Trigger.isAfter && Trigger.isUpdate){
        SkillRatingTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

}