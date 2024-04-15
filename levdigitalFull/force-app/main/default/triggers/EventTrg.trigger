trigger EventTrg on Event (after insert, after update) {

	if(trigger.isAfter)
    {
        if(trigger.isInsert){
            EventTrgHandler.EventAccountReview(Trigger.new,trigger.oldMap);
             
        } 
        if(trigger.isUpdate){
        	EventTrgHandler.EventAccountReview(Trigger.new,trigger.oldMap);
        }  
    }
}