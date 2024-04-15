@isTest
private class TaskTriggerHandlerTest {
	
	@isTest static void TestUpdateNextTouchDate() 
	{
		Lead l = new Lead(LastName='Test', Company='Test', Latest_Work_Log__c = 'test');
	 	insert l;	

	 	Task task = new Task(whoId = l.id, Subject = 'Call', ActivityDate= Date.today());
	 	insert task; 


		
	}
	
	
}