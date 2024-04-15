public with sharing class OpportunityContactRoleTriggerHandler {
    
    public static void beforeInsert(List<OpportunityContactRole> opptyContactRoleList) {
        
    }

    public static void afterInsert(List<OpportunityContactRole> opptyContactRoleList) {

        countContactTotalOpptys(opptyContactRoleList);
    }

    public static void beforeUpdate(List<OpportunityContactRole> opptyContactRoleList, Map<Id, OpportunityContactRole> oldOpptyContactRoleMap) {
        
    }

    public static void afterUpdate(List<OpportunityContactRole> opptyContactRoleList, Map<Id, OpportunityContactRole> oldOpptyContactRoleMap) {

        List<OpportunityContactRole> ocrToCountTotalOpptyList = new List<OpportunityContactRole>();
        for(OpportunityContactRole ocr : opptyContactRoleList){

            OpportunityContactRole oldOcr =  oldOpptyContactRoleMap.get(ocr.Id);

            if(ocr.ContactId != oldOcr.ContactId){
                ocrToCountTotalOpptyList.add(ocr);
                ocrToCountTotalOpptyList.add(oldOcr);
            }
        }

        if(ocrToCountTotalOpptyList.size() > 0){
            countContactTotalOpptys(ocrToCountTotalOpptyList);
        }
        
    }

    public static void beforeDelete(List<OpportunityContactRole> opptyContactRoleList) {
        
    }

    public static void afterDelete(List<OpportunityContactRole> opptyContactRoleList, Map<Id, OpportunityContactRole> oldOpptyContactRoleMap) {

        countContactTotalOpptys(opptyContactRoleList);
    }

    private static void countContactTotalOpptys(List<OpportunityContactRole> opptyContactRoleList){
        List<Id> contactIdList = new List<Id>();
        System.debug('WE ARE HERE');
        for(OpportunityContactRole ocr : opptyContactRoleList){
            contactIdList.add(ocr.ContactId);
        }

        AggregateResult [] opptyContactRoles = [SELECT count(Id), ContactId FROM OpportunityContactRole WHERE ContactId IN :contactIdList GROUP BY ContactId];

        Map<Id, Decimal> contactIdToOCRCountMap = new Map<Id, Decimal>();
        for(AggregateResult ar : opptyContactRoles){
            contactIdToOCRCountMap.put((Id)ar.get('ContactId'), (Decimal)ar.get('expr0'));
            System.debug('contactIdToOCRCountMap: ' + contactIdToOCRCountMap);
        }

        List<Contact> relatedContactList = new List<Contact>();
        //relatedContactList = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE Id IN :contactIdToOCRCountMap.keySet()];
        relatedContactList = [SELECT Id, Name, Total_Opportunities__c FROM Contact WHERE Id IN :contactIdList];

        List<Contact> contactToUpdateList = new List<Contact>();
        for(Contact c : relatedContactList){
            System.debug('In Loop');
            if(contactIdToOCRCountMap.containsKey(c.Id)){
                System.debug('CONTACT Name: ' + c.Name);
                System.debug('OPPTY COUNT: ' + contactIdToOCRCountMap.get(c.Id));
                c.Total_Opportunities__c = contactIdToOCRCountMap.get(c.Id);
                contactToUpdateList.add(c);
            }else{
                c.Total_Opportunities__c = 0;
                contactToUpdateList.add(c);
            }
        }

        if(contactToUpdateList.size() > 0){
            System.debug('UPDATE HERE');
            update contactToUpdateList;
        }
    }
}