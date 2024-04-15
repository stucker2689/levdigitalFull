/*
Created By: Naren Pillai
Date: 6/8/2015
Description: This class is used to update the project with the info from the latest status report record associated with the project.
*/

public without sharing class StatusReportTriggerHandler {
	
	//After insert, update the project fields 
	public static void updateProjectFieldsAfterInsert(List<Status_Report__c> trigList) 
	{

		Status_Report__c strep = new Status_Report__c(); 
		List<Project__c> projlist = new List<Project__c>();
		projlist = StatusReportTriggerHandler.getListofProjects(trigList); //Replace this function to return a Map so we dont have to use nested for loops
		for(Status_Report__c str : trigList)
		{
			for(Project__c prj : projlist) //Not good
			{
				if(str.project__c == prj.id)
				{

				  prj.SR_Reporting_Period_From__c = str.Reporting_Period_From__c;
				  prj.SR_Reporting_Period_To__c = str.Reporting_Period_Ending__c;
				  prj.SR_Executive_Summary__c = str.Executive_Summary__c;
				  prj.SR_Key_Accomplishments_This_Period__c = str.Key_Accomplishments_This_Period__c;
				  prj.SR_Key_Decisions__c = str.Key_Decisions__c;
				  prj.SR_Plans_for_Next_Period__c = str.Plans_for_Next_Period__c;
				  //prj.SR_Overall_Health_Value__c = str.Overall_Health_Value__c;
				  //prj.SR_Budget_Value__c = str.Budget_Value__c;
				  //prj.SR_Risk_Value__c = str.Risk_Value__c; 
				  //prj.SR_Schedule_Value__c = str.Schedule_Value__c;
				  //prj.SR_Scope_Value__c = str.Scope_Value__c;
				  prj.SR_Overall_Health_Comments__c = str.Overall_Health_Comments__c;
				  prj.SR_Budget_Comments__c = str.Budget_Comments__c;
				  prj.SR_Risk_Comments__c = str.Risk_Comments__c;
				  prj.SR_Schedule_Comments__c = str.Schedule_Comments__c;
				  prj.SR_Scope_Comments__c = str.Scope_Comments__c;
				  prj.Latest_Status_Report_Date__c = str.CreatedDate;
				  prj.Customer_Comments__c = '';
				  if(str.Lev_Internal_Help_Needed__c != null) { 
				  	 prj.SR_Lev_Internal_Help_Needed__c = str.Lev_Internal_Help_Needed__c;
				  }
				  prj.Latest_Status_Report_ID__c = str.Id;
                  if(str.Last_Status_Report_E_Mailed_On__c!=NULL)
			  			prj.Last_Status_Report_E_Mailed_On__c = str.Last_Status_Report_E_Mailed_On__c;
				  /*if(str.Overall_Health_Value__c == 'Red')
				  {
				  	prj.OverallPHINumberValue__c = 1; 
				  }
				  else if (str.Overall_Health_Value__c == 'Yellow')
				  {
				  	prj.OverallPHINumberValue__c = 2; 
				  }
				  else if (str.Overall_Health_Value__c == 'Green')
				  {
				  	prj.OverallPHINumberValue__c = 3; 
				  }*/

				}

			}
		}
		system.debug('ProjLIST'+projlist);
		update projlist; 
	}

	//After update, check if its the latest status report record, and if so update the project fields. 
	public static void updateProjectFieldsAfterUpdate(Map<Id,Status_Report__c> oldMap,Map<Id,Status_Report__c> newMap)
	{
		//Check if its the latest status report, and if so, update the project related fields 
		//First check with the Period Ending Date, and then probably the created datE? will see how this pans out. 
		
		Status_Report__c streport = new Status_Report__c();
		List<Project__c> projectlist = new List<Project__c>();
		List<Status_Report__c> strlist = new List<Status_Report__c>();
		Status_Report__c latestSTR = new Status_Report__c();

		projectlist = StatusReportTriggerHandler.getListofProjects(newMap.values());
		String lateststatusrepid;
		//First, Need to check if the date of Reporting Period Ending has been changed in the current status report, if it did, then 
		// need to see if that is still the latest Reporting period ending, else, get the most recent one from the list, and update the project.
		for (Status_Report__c newstr : newMap.values())
		{
			Status_Report__c oldstrvalue =  oldMap.get(newstr.Id);
			if(newstr.Reporting_Period_Ending__c!= oldstrvalue.Reporting_Period_Ending__c && newstr.Reporting_Period_Ending__c <=oldstrvalue.Reporting_Period_Ending__c)
			{
				//Call Method to get the latest  status report record.
				latestSTR = StatusReportTriggerHandler.getLatestStatusReport(newStr.Project__c);
				for (Project__c prj: projectlist)
				{
					if(prj.ID==latestSTR.Project__c)
					{
						prj.SR_Reporting_Period_From__c = latestSTR.Reporting_Period_From__c;
				  		prj.SR_Reporting_Period_To__c = latestSTR.Reporting_Period_Ending__c;
				  		prj.SR_Collection_Id__c = latestSTR.Collection_Id__c;
				  		prj.SR_Executive_Summary__c = latestSTR.Executive_Summary__c;
				  		prj.SR_Key_Accomplishments_This_Period__c = latestSTR.Key_Accomplishments_This_Period__c;
				  		prj.SR_Key_Decisions__c = latestSTR.Key_Decisions__c;
				  		prj.SR_Plans_for_Next_Period__c = latestSTR.Plans_for_Next_Period__c;
				  		//prj.SR_Overall_Health_Value__c = latestSTR.Overall_Health_Value__c;
				  		//prj.SR_Budget_Value__c = latestSTR.Budget_Value__c;
				  		//prj.SR_Risk_Value__c = latestSTR.Risk_Value__c;
				  		//prj.SR_Schedule_Value__c = latestSTR.Schedule_Value__c;
				  		//prj.SR_Scope_Value__c = latestSTR.Scope_Value__c;
				  		//prj.SR_Overall_Health_Comments__c = latestSTR.Overall_Health_Comments__c;
				  		//prj.SR_Budget_Comments__c = latestSTR.Budget_Comments__c;
				  		//prj.SR_Risk_Comments__c = latestSTR.Risk_Comments__c;
				 		//prj.SR_Schedule_Comments__c = latestSTR.Schedule_Comments__c;
				 		//prj.SR_Scope_Comments__c = latestSTR.Scope_Comments__c;
				  		prj.Latest_Status_Report_Date__c = latestSTR.LastModifiedDate;
				  		if(LatestSTR.Lev_Internal_Help_Needed__c != null) {
							prj.SR_Lev_Internal_Help_Needed__c = LatestSTR.Lev_Internal_Help_Needed__c;
						}
						prj.Latest_Status_Report_ID__c = LatestSTR.Id;
				  		if(LatestSTR.Customer_Comments__c!=NULL)
				  			prj.Customer_Comments__c =LatestSTR.Customer_Comments__c;
			  			if(LatestSTR.Last_Status_Report_E_Mailed_On__c!=NULL)
			  				prj.Last_Status_Report_E_Mailed_On__c = LatestSTR.Last_Status_Report_E_Mailed_On__c;
			  			if(LatestSTR.Last_DocuSign_Report_Sent__c!= NULL)
			  				prj.Last_DocuSign_Report_Sent__c = LatestSTR.Last_DocuSign_Report_Sent__c;

			  			/*if(latestSTR.Overall_Health_Value__c == 'Red')
						  {
						  	prj.OverallPHINumberValue__c = 1; 
						  }
						else if (latestSTR.Overall_Health_Value__c == 'Yellow')
						  {
						  	prj.OverallPHINumberValue__c = 2; 
						  }
						else if (latestSTR.Overall_Health_Value__c == 'Green')
						  {
						  	prj.OverallPHINumberValue__c = 3; 
				  		  }*/

					}

				}
			}

		}

		for(Project__c prj : projectlist)
		{
			//We are getting the latest status report of the project. And check if the latest status report is the one that is updated
			streport = StatusReportTriggerHandler.getLatestStatusReport(prj.Id);
			system.debug(lateststatusrepid);

			for(Status_Report__c str : newMap.values())
			{
				if(str.Project__c== prj.id)
				{                          
					if(str.Id== streport.Id)
					{

				  	prj.SR_Reporting_Period_From__c = str.Reporting_Period_From__c;
				  	prj.SR_Reporting_Period_To__c = str.Reporting_Period_Ending__c;
				  	prj.SR_Collection_Id__c = str.Collection_Id__c;
				  	prj.SR_Executive_Summary__c = str.Executive_Summary__c;
				  	prj.SR_Key_Accomplishments_This_Period__c = str.Key_Accomplishments_This_Period__c;
				  	prj.SR_Key_Decisions__c = str.Key_Decisions__c;
				  	prj.SR_Plans_for_Next_Period__c = str.Plans_for_Next_Period__c;
				  	//prj.SR_Overall_Health_Value__c = str.Overall_Health_Value__c;
				  	//prj.SR_Budget_Value__c = str.Budget_Value__c;
				  	//prj.SR_Risk_Value__c = str.Risk_Value__c;
				  	//prj.SR_Schedule_Value__c = str.Schedule_Value__c;
				  	//prj.SR_Scope_Value__c = str.Scope_Value__c;
				    //prj.SR_Overall_Health_Comments__c = str.Overall_Health_Comments__c;
				  	//prj.SR_Budget_Comments__c = str.Budget_Comments__c;
				  	//prj.SR_Risk_Comments__c = str.Risk_Comments__c;
				 	//prj.SR_Schedule_Comments__c = str.Schedule_Comments__c;
				 	//prj.SR_Scope_Comments__c = str.Scope_Comments__c;
				  	prj.Latest_Status_Report_Date__c = str.LastModifiedDate;
					if(str.Lev_Internal_Help_Needed__c != null) {  
						prj.SR_Lev_Internal_Help_Needed__c = str.Lev_Internal_Help_Needed__c;
					}
				  	prj.Latest_Status_Report_ID__c = str.Id;
				  	if(str.Customer_Comments__c!= NULL)
				  		prj.Customer_Comments__c =str.Customer_Comments__c;
				  	if(str.Last_Status_Report_E_Mailed_On__c!=NULL)
			  			prj.Last_Status_Report_E_Mailed_On__c = str.Last_Status_Report_E_Mailed_On__c;
			  		if(str.Last_DocuSign_Report_Sent__c!= NULL)
			  			prj.Last_DocuSign_Report_Sent__c = str.Last_DocuSign_Report_Sent__c;
			  		/*if(str.Overall_Health_Value__c == 'Red')
					  {
					  	prj.OverallPHINumberValue__c = 1; 
					  }
					else if (str.Overall_Health_Value__c == 'Yellow')
					  {
					  	prj.OverallPHINumberValue__c = 2; 
					  }
					else if (str.Overall_Health_Value__c == 'Green')
					  {
					  	prj.OverallPHINumberValue__c = 3; 
					  }*/

					}
				}

			}

		}
		system.debug(projectlist);
		update projectlist;
	
	}

	public static void updateProjectFieldsAfterDelete(Map<Id, Status_Report__c> oldMap){

		//Get List of Projects related to deleted Status Reports
		//Check to see if the deleted reports were the LATEST report of any of the related Projects
		//If a deleted Status Report WAS a LATEST report for its project, then find the NEW latest report and assign the proper values on the related project

		Map<Id, Id> statusReportIdToProjMap = new Map<Id, Id>();
		for(Status_Report__c sr : oldMap.values()){
			statusReportIdToProjMap.put(sr.Id, sr.Project__c);
		}

		List<Project__c> relatedProjList = new List<Project__c>();
		relatedProjList = [SELECT Id,Name,SR_Reporting_Period_From__c,SR_Reporting_Period_To__c, SR_Collection_Id__c,SR_Executive_Summary__c, SR_Key_Accomplishments_This_Period__c,SR_Key_Decisions__c,SR_Plans_for_Next_Period__c,
									SR_Overall_Health_Value__c,SR_Budget_Value__c,SR_Risk_Value__c,	SR_Schedule_Value__c,SR_Scope_Value__c,Latest_Status_Report_Date__c, SR_Lev_Internal_Help_Needed__c, Latest_Status_Report_ID__c,
									SR_Overall_Health_Comments__c, SR_Budget_Comments__c, SR_Risk_Comments__c, SR_Schedule_Comments__c, SR_Scope_Comments__c, Customer_Comments__c, Last_DocuSign_Report_Sent__c, Last_Status_Report_E_Mailed_On__c, OverallPHINumberValue__c
							FROM Project__c
							WHERE Id IN :statusReportIdToProjMap.values()];

		Map<Id, Project__c> projIdToProjMap = new Map<Id, Project__c>();
		for(Project__c proj : relatedProjList){
			if(statusReportIdToProjMap.containsKey(proj.Latest_Status_Report_ID__c)){
				projIdToProjMap.put(proj.Id, proj);
			}
		}

		Map<Id, Status_Report__c> projToLatestSRMap = new Map<Id, Status_Report__c>();
		if(projIdToProjMap.size() > 0){

			List<Status_Report__c> relatedStatusReportList = new List<Status_Report__c>();
			relatedStatusReportList = [SELECT Id,Project__c,Reporting_Period_From__c, Reporting_Period_Ending__c,Collection_Id__c, Executive_Summary__c,Key_Accomplishments_This_Period__c,Customer_comments__c, CreatedDate,
												Key_Decisions__c, Plans_for_Next_Period__c,Overall_Health_Value__c,Budget_Value__c, Risk_Value__c,Schedule_Value__c,Scope_Value__c,LastModifiedDate, Lev_Internal_Help_Needed__c
												,Overall_Health_Comments__c, Budget_Comments__c, Risk_Comments__c, Schedule_Comments__c, Scope_Comments__c, Last_Status_Report_E_Mailed_On__c, Last_DocuSign_Report_Sent__c
										FROM Status_Report__c
										WHERE Project__c IN :projIdToProjMap.keySet() 
										ORDER BY Reporting_Period_Ending__c ASC];

			for(Status_Report__c sr : relatedStatusReportList){

				if(projToLatestSRMap.containsKey(sr.Project__c)){
					projToLatestSRMap.put(sr.Project__c, sr);
				}else{
					projToLatestSRMap.put(sr.Project__c, sr);
				}
			}
		}

		List<Project__c> projToUpdateList = new List<Project__c>();
		for(Project__c proj : projIdToProjMap.values()){
			if(projToLatestSRMap.containsKey(proj.Id)){

				Status_Report__c str = projToLatestSRMap.get(proj.Id);

				proj.SR_Reporting_Period_From__c = str.Reporting_Period_From__c;
				proj.SR_Reporting_Period_To__c = str.Reporting_Period_Ending__c;
				proj.SR_Executive_Summary__c = str.Executive_Summary__c;
				proj.SR_Key_Accomplishments_This_Period__c = str.Key_Accomplishments_This_Period__c;
				proj.SR_Key_Decisions__c = str.Key_Decisions__c;
				proj.SR_Plans_for_Next_Period__c = str.Plans_for_Next_Period__c;
				//proj.SR_Overall_Health_Value__c = str.Overall_Health_Value__c;
				//proj.SR_Budget_Value__c = str.Budget_Value__c;
				//proj.SR_Risk_Value__c = str.Risk_Value__c; 
				//proj.SR_Schedule_Value__c = str.Schedule_Value__c;
				//proj.SR_Scope_Value__c = str.Scope_Value__c;
				//proj.SR_Overall_Health_Comments__c = str.Overall_Health_Comments__c;
				//proj.SR_Budget_Comments__c = str.Budget_Comments__c;
				//proj.SR_Risk_Comments__c = str.Risk_Comments__c;
				//proj.SR_Schedule_Comments__c = str.Schedule_Comments__c;
				//proj.SR_Scope_Comments__c = str.Scope_Comments__c;
				proj.Latest_Status_Report_Date__c = str.CreatedDate;
				proj.Customer_Comments__c = '';
				if(str.Lev_Internal_Help_Needed__c != null) { 
					proj.SR_Lev_Internal_Help_Needed__c = str.Lev_Internal_Help_Needed__c;
				}
				proj.Latest_Status_Report_ID__c = str.Id;
				if(str.Last_Status_Report_E_Mailed_On__c != null){
					proj.Last_Status_Report_E_Mailed_On__c = str.Last_Status_Report_E_Mailed_On__c;
				}
				/*if(str.Overall_Health_Value__c == 'Red'){
					proj.OverallPHINumberValue__c = 1; 
				} else if (str.Overall_Health_Value__c == 'Yellow'){
					proj.OverallPHINumberValue__c = 2; 
				} else if (str.Overall_Health_Value__c == 'Green'){
					proj.OverallPHINumberValue__c = 3; 
				}*/

				projToUpdateList.add(proj);

			}
		}

		if(projToUpdateList.size() > 0){
			update projToUpdateList;
		}


	}

	//method to get the latest status report record for the given project
	public static Status_Report__c getLatestStatusReport(string projectid)
	{
		
		Status_Report__c str = new Status_Report__c();
		str = [select Id,Project__c,Reporting_Period_From__c, Reporting_Period_Ending__c,Collection_Id__c,
								Executive_Summary__c,Key_Accomplishments_This_Period__c,Customer_comments__c,
								 Key_Decisions__c, Plans_for_Next_Period__c,Overall_Health_Value__c,Budget_Value__c,
								  Risk_Value__c,Schedule_Value__c,Scope_Value__c,LastModifiedDate, Lev_Internal_Help_Needed__c
								  ,Overall_Health_Comments__c,
								  Budget_Comments__c,
								  Risk_Comments__c,
								  Schedule_Comments__c,
								  Scope_Comments__c,
								  Last_Status_Report_E_Mailed_On__c,
								  Last_DocuSign_Report_Sent__c
								   from Status_Report__c where Project__c = : projectid ORDER BY Reporting_Period_Ending__c DESC LIMIT 1];
		
		system.debug(str);
		return str; 


	}

	public static List<Project__c> getListofProjects(List<Status_Report__c> trigList)
	{
		List<Project__c> projlist = new List<Project__c>();
		Set<String> projids = new Set<String>();
		For(Status_Report__c str: trigList)
		{
			projids.add(str.Project__c);

		}

		projlist = [Select Id,Name,SR_Reporting_Period_From__c,SR_Reporting_Period_To__c, SR_Collection_Id__c,SR_Executive_Summary__c,
					SR_Key_Accomplishments_This_Period__c,SR_Key_Decisions__c,SR_Plans_for_Next_Period__c,
					SR_Overall_Health_Value__c,SR_Budget_Value__c,SR_Risk_Value__c,
					SR_Schedule_Value__c,SR_Scope_Value__c,Latest_Status_Report_Date__c, SR_Lev_Internal_Help_Needed__c
					,Latest_Status_Report_ID__c
					,SR_Overall_Health_Comments__c,
					SR_Budget_Comments__c,
					SR_Risk_Comments__c,
					SR_Schedule_Comments__c,
					SR_Scope_Comments__c,
					Customer_Comments__c,
					Last_DocuSign_Report_Sent__c,
					Last_Status_Report_E_Mailed_On__c,
					OverallPHINumberValue__c
					from Project__c where id in: projids];
		system.debug('ProjLIST'+projlist);
		return projlist;
	}



}