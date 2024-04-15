/**
 * Name: SObjects
 * Author: Jonathan Broquist
 * Date: 11/1/2012
 * Description: Base class for classes that are used to manage the trigger logic
 * for an object.
 */
public abstract class SObjects
{
    //VARIABLES
    //=========================================================================

    //CONSTRUCTOR
    //=========================================================================
    public SObjects() {}

    //PUBLIC METHODS
    //=========================================================================
    public virtual void beforeInsert(SObject[] records){}
    public virtual void afterInsert(SObject[] records){}
    public virtual void beforeUpdate(SObject[] records, SObject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap){}
    public virtual void afterUpdate(SObject[] records, SOBject[] oldRecords, Map<Id, SObject> recordMap, Map<Id, SObject> oldRecordMap){}
    public virtual void beforeDelete(SObject[] records, Map<Id, SObject> recordMap){}
    public virtual void afterDelete(SObject[] records, Map<Id, SObject> recordMap){}
    public virtual void afterUndelete(SObject[] records){}

    //PRIVATE METHODS
    //=========================================================================

}