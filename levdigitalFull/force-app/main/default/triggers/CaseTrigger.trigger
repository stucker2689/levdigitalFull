/**
 * Name: Case Trigger
 * Author: Jonathan Broquist
 * Date:
 * Description: Trigger for the Case  object.
 */
trigger CaseTrigger on Case  (before insert, before update, after insert, after update, after delete, before delete)
{
  SObjects objectHandler = new CaseTriggerHandler();

  if(Trigger.isBefore && Trigger.isInsert)
    objectHandler.beforeInsert(trigger.new);

  if(Trigger.isAfter && Trigger.isInsert)
    objectHandler.afterInsert(trigger.new);

  if(Trigger.isBefore && Trigger.isUpdate)
    objectHandler.beforeUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);

  if(Trigger.isAfter && Trigger.isUpdate)
    objectHandler.afterUpdate(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);

  if(Trigger.isBefore && Trigger.isDelete)
    objectHandler.beforeDelete(trigger.old, trigger.oldMap);

  if(Trigger.isAfter && Trigger.isDelete)
    objectHandler.afterDelete(trigger.old, trigger.oldMap);

  if(Trigger.isAfter && Trigger.isUndelete)
    objectHandler.afterUndelete(trigger.new);
}