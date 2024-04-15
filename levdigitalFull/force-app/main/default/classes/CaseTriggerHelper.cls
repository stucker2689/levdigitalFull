public with sharing class CaseTriggerHelper {
	private static String internalCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Levementum Internal Case').getRecordTypeId();
	private static String dealDeskRequestCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Deal Desk Request').getRecordTypeId();
	private static String trainingAndEnablementRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Training & Enablement').getRecordTypeId();
	private static String LevSOWCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lev SOW').getRecordTypeId();
	private static String LevCOSOWCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('LEV CO SOW').getRecordTypeId();
	private static String LevSwapResourceRequestRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lev Swap Resource Request').getRecordTypeId();
	private static String nonbillOrConcessionRequestRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Nonbill Request').getRecordTypeId();

	private static String sprintPlanWeekRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Week').getRecordTypeId();
	private static String sprintPlanMonthRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Month').getRecordTypeId();
	private static String sprintPlanQuarterRT = Schema.SObjectType.Sprint_Plan__c.getRecordTypeInfosByName().get('Sprint Plan Quarter').getRecordTypeId();

	//Link Deal Desk Opportunity lookup field with Case Opportunities for Deal Desk Request Cases
	public static void assignDealDeskLookupField(List<Case> newDealDeskCases, String triggerEntry){
		for(Case newCase : newDealDeskCases){
		if(newCase.RecordTypeId == dealDeskRequestCaseRT){
			if(triggerEntry == 'beforeInsert'){
			newCase.Deal_Desk_Opportunity__c = newCase.Case_Opportunity__c; 
			}else if(triggerEntry == 'beforeUpdate'){
			if(newCase.Case_Opportunity__c != newCase.Deal_Desk_Opportunity__c){
				newCase.Deal_Desk_Opportunity__c = newCase.Case_Opportunity__c;  
			}
			}
		}
		}
	}

  	//Count Related SOW/CO SOW Cases
	public static void countRelatedSOWCasesOnOppty(Set<Id> opptyIdSet){

		Map<Id, Decimal> opptyIdToSOWCaseCountMap = new Map<Id, Decimal>();
		Map<Id, Decimal> opptyIdToNonCancelledSOWCaseCountMap = new Map<Id, Decimal>();
		for(Id opptyId : opptyIdSet){
			opptyIdToSOWCaseCountMap.put(opptyId, 0);
			opptyIdToNonCancelledSOWCaseCountMap.put(opptyId, 0);
		}
		
		AggregateResult[] caseCountResult = [SELECT count(Id) caseCount, Case_Opportunity__c, Status
											FROM Case 
											WHERE (RecordTypeId =: LevSOWCaseRT OR RecordTypeId =: LevCOSOWCaseRT) AND Case_Opportunity__c IN :opptyIdSet 
											GROUP BY Case_Opportunity__c, Status
											ORDER BY Case_Opportunity__c];

		for(AggregateResult ar : caseCountResult){
			Decimal caseCount = (Decimal)ar.get('caseCount');
			Id opptyId = (Id)ar.get('Case_Opportunity__c');
			String caseStatus = (String)ar.get('Status');

			if(opptyIdToSOWCaseCountMap.containsKey(opptyId)){
				Decimal SOWCaseCount = opptyIdToSOWCaseCountMap.get(opptyId);
				SOWCaseCount += caseCount;
				opptyIdToSOWCaseCountMap.put(opptyId, SOWCaseCount);
			}

			if(caseStatus != 'Cancelled'){
				if(opptyIdToNonCancelledSOWCaseCountMap.containsKey(opptyId)){
					Decimal nonCalcelledSOWCaseCount = opptyIdToNonCancelledSOWCaseCountMap.get(opptyId);
					nonCalcelledSOWCaseCount += caseCount;
					opptyIdToNonCancelledSOWCaseCountMap.put(opptyId, nonCalcelledSOWCaseCount);
				}
			}
		}

		List<Opportunity> relatedOpptyList = new List<Opportunity>();
		relatedOpptyList = [SELECT Id, Name, Related_SOW_CO_SOW_Cases__c, Number_of_SOW_Cases__c 
							FROM Opportunity 
							WHERE Id IN :opptyIdSet];

		List<Opportunity> updateOpptyList = new List<Opportunity>();
		for(Opportunity opp : relatedOpptyList){
			Boolean needsUpdate = false;
			
			if(opptyIdToSOWCaseCountMap.containsKey(opp.Id) && opp.Number_of_SOW_Cases__c != opptyIdToSOWCaseCountMap.get(opp.Id)){
				opp.Number_of_SOW_Cases__c = opptyIdToSOWCaseCountMap.get(opp.Id);
				needsUpdate = true;
			}

			if(opptyIdToNonCancelledSOWCaseCountMap.containsKey(opp.Id)){
				opp.Related_SOW_CO_SOW_Cases__c = opptyIdToNonCancelledSOWCaseCountMap.get(opp.Id);
				needsUpdate = true;
			}

			if(needsUpdate){
				updateOpptyList.add(opp);
			}
		}

		if(updateOpptyList.size() > 0){
			System.debug('Updating SOW Count on Opportunity for ' + updateOpptyList.size() + ' Opportunities');
			update updateOpptyList;
		}	
	}

  	//New as of 8/10 ST
  	public static void setCaseSprintWeeks(Map<Id, Case> newCaseMap){
		//Before Insert/Update
		/**
		 * If case has Start Date then Create Sprint Weeks
		 * If Start Date or Due Date has changed also set Sprint Weeks field
		 */

		for(Case c : newCaseMap.values()){
			List<String> sprintWeeksList = new List<String>();
			Date firstSprintWeek;
			Date lastSprintWeek;
			String finalSprintWeeksString;
			String finalSprintMonthsString;
			String finalSprintQuartersString;
			Set<String> sprintMonthSet = new Set<String>();

			if(c.Start_Date__c != null){
				//Get First Sprint Week from Case Start Date
				firstSprintWeek = (c.Start_Date__c).toStartOfWeek().addDays(1); //Gets the Sunday of the Start Date and adds one day to get the Monday of that week.
				sprintWeeksList.add(formatDateToString(firstSprintWeek)); //Format the date for proper format for the Sprint Week Multi-Picklist
				sprintMonthSet.add(String.valueOf(firstSprintWeek.month()));
			}

			if(c.Start_Date__c != null && c.Due_Date_Internal__c != null){
				//Get all Mondays of Sprint Weeks

				//Get the last Sprint week in order to see how many Sprint Weeks between Start and Due Date need to be added
				lastSprintWeek = (c.Due_Date_Internal__c).toStartOfWeek().addDays(1);
				Integer daysBetweenFirstAndLastSprintWeeks = firstSprintWeek.daysBetween(lastSprintWeek);
				Integer weeksBetweenFirstAndLastSprintWeeks = (daysBetweenFirstAndLastSprintWeeks + 1) / 7;

				//Loop through each week between Start and Due Date and add the Monday of that week to the Sprint Week List
				for(Integer i = 1; i <= weeksBetweenFirstAndLastSprintWeeks; i++){
					Date sprintWeek = firstSprintWeek.addDays(7 * i);
					//Dont add the Last Week if the Due Date is on a Monday
					if(sprintWeek != c.Due_Date_Internal__c){
						sprintWeeksList.add(formatDateToString(sprintWeek));
						sprintMonthSet.add(String.valueOf(sprintWeek.month()));
					}
				}
			}

			if(sprintWeeksList.size() > 0){
				//Set the Sprint Weeks if the Sprint Week list contains Sprint Weeks
				finalSprintWeeksString = String.join(sprintWeeksList, ';');
				finalSprintMonthsString = getMonthsFromNumber(sprintMonthSet, true);
				finalSprintQuartersString = getMonthsFromNumber(sprintMonthSet, false);

				if(c.Sprint_Week__c != finalSprintWeeksString){
					c.Sprint_Week__c = finalSprintWeeksString; //Set Sprint Weeks
				}

				if(c.Sprint_Month__c != finalSprintMonthsString){
					c.Sprint_Month__c = finalSprintMonthsString; //Set Sprint Months
				}

				if(c.Sprint_Quarter__c != finalSprintQuartersString){
					c.Sprint_Quarter__c = finalSprintQuartersString; //Set Sprint Quarters
				}

			}else{
				//If Sprint Weeks are empty then set the field(s) to null
				if(c.Sprint_Week__c != null || c.Sprint_Month__c != null || c.Sprint_Quarter__c != null){
					c.Sprint_Week__c = null;
					c.Sprint_Month__c = null;
					c.Sprint_Quarter__c = null;
				}
			}
		}
	}

	//New as of 8/10 ST
	public static void setCaseSprintMonthsAndQuarters(Map<Id, Case> newCaseMap){
		//This function sets the Sprint Months and Quarters from the Sprint Weeks

		for(Case c : newCaseMap.values()){
			Set<String> sprintMonthSet = new Set<String>();
			String finalSprintMonthsString;
			String finalSprintQuartersString;

			if(c.Sprint_Week__c != null){
				//Split the Sprint Weeks into a list seperated by the ; 
				List<String> sprintWeekStringList = new List<String>();
				sprintWeekStringList = (c.Sprint_Week__c).split(';');

				for(String sprintWeek : sprintWeekStringList){
					//Loop through the Sprint Weeks and get the Month of each
					String sprintWeekMonth = sprintWeek.substringBefore('/');
					sprintMonthSet.add(sprintWeekMonth);
				}

				if(sprintMonthSet.size() > 0){
					finalSprintMonthsString = getMonthsFromNumber(sprintMonthSet, true);
					finalSprintQuartersString = getMonthsFromNumber(sprintMonthSet, false);

					if(c.Sprint_Month__c != finalSprintMonthsString){
						c.Sprint_Month__c = finalSprintMonthsString; //Set Sprint Months
					}
	
					if(c.Sprint_Quarter__c != finalSprintQuartersString){
						c.Sprint_Quarter__c = finalSprintQuartersString; //Set Sprint Quarters
					}
				}
			}else{
				//If Sprint Week is empty then set the Sprint Months and Quarters to empty as well
				if(c.Sprint_Month__c != null || c.Sprint_Quarter__c != null){
					c.Sprint_Month__c = null;
					c.Sprint_Quarter__c = null;
				}
			}
		}
	}

	public static void createCaseSprintPlans(Map<Id, Case> caseMap){

		//Go through each case and create the Sprint Plans (Weeks, Months, Quarters for the Sprint Weeks on the Case)

		List<Sprint_Plan__c> existingSprintPlans = new List<Sprint_Plan__c>();

      	existingSprintPlans = [SELECT Id, Name, Estimated_Hours_per_Week__c, Sprint_Week__c, Sprint_Week_Date__c, Case__c, Full_Name__c, Sprint_Week_Picklist__c, Case__r.Subject, RecordTypeId,
                                        Estimated_Hours_for_Month__c, Sprint_Month__c, Sprint_Month_Date__c, Sprint_Month_Picklist__c,
                                        Estimated_Hours_for_Quarter__c, Sprint_Quarter__c, Sprint_Quarter_Picklist__c, EstimatedQAHours__c
                                FROM Sprint_Plan__c 
                                WHERE Case__c IN :caseMap.keySet() ];

		Map<String, Sprint_Plan__c> existingSprintPlanWeeksUIDMap = new Map<String, Sprint_Plan__c>();
		Map<String, Sprint_Plan__c> existingSprintPlanMonthsUIDMap = new Map<String, Sprint_Plan__c>();
		Map<String, Sprint_Plan__c> existingSprintPlanQuartersUIDMap = new Map<String, Sprint_Plan__c>();

		Map<String, SprintWeekDetailsObj> weekSprintPlanUIDToDetailsMap = new Map<String, SprintWeekDetailsObj>();
		Map<String, SprintWeekDetailsObj> monthSprintPlanUIDToDetailsMap = new Map<String, SprintWeekDetailsObj>();
		Map<String, SprintWeekDetailsObj> quarterSprintPlanUIDToDetailsMap = new Map<String, SprintWeekDetailsObj>();

		for(Sprint_Plan__c sp : existingSprintPlans){
			if(sp.RecordTypeId == sprintPlanWeekRT ){
				existingSprintPlanWeeksUIDMap.put(sp.Case__c + sp.Sprint_Week_Picklist__c, sp);
			}else if(sp.RecordTypeId == sprintPlanMonthRT ){
				existingSprintPlanMonthsUIDMap.put(sp.Case__c + String.valueOf(sp.Sprint_Month_Date__c.month()) + String.valueOf(sp.Sprint_Month_Date__c.year()), sp);
			}else if(sp.RecordTypeId == sprintPlanQuarterRT ){
				existingSprintPlanQuartersUIDMap.put(sp.Case__c + sp.Sprint_Quarter__c, sp);
			}
		}

		List<Sprint_Plan__c> sprintPlansToDelete = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlansToUpdate = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlansToInsert = new List<Sprint_Plan__c>();

		for(Case c : caseMap.values()){
			String lastSprintWeek;
			if(c.Sprint_Week__c != null){ //Check if the Case has any sprint Weeks
				List<String> sprintWeeks = new List<String>();
				sprintWeeks = (c.Sprint_Week__c).split(';');
				Decimal numberOfSprintWeeks;
				numberOfSprintWeeks = sprintWeeks.size();
				lastSprintWeek = sprintWeeks[sprintWeeks.size() - 1]; //Get the last Sprint Week to assign the QA Hours to the last sprint week only.
				List<String> lastSprintWeekParts = lastSprintWeek.split('/');
				System.debug('Last Sprint Week: ' + lastSprintWeek);
				Decimal estimatedHoursPerSprintWeek = 0;
				if(c.Internal_Ops_Estimated_Hours__c != null){
					if(numberOfSprintWeeks != null && numberOfSprintWeeks != 0){
						//Get Estimated Hours of the Case Per Sprint Week
						estimatedHoursPerSprintWeek = c.Internal_Ops_Estimated_Hours__c / numberOfSprintWeeks;
						Decimal roundedToFloorEstHours = estimatedHoursPerSprintWeek.round(System.RoundingMode.FLOOR);
						Decimal nearestFourthDecimal = estimatedHoursPerSprintWeek - roundedToFloorEstHours;
						if(nearestFourthDecimal < 0.125){
							estimatedHoursPerSprintWeek = roundedToFloorEstHours;
						}else if(nearestFourthDecimal < 0.375){
							estimatedHoursPerSprintWeek= roundedToFloorEstHours + 0.25;
						}else if(nearestFourthDecimal < 0.625){
							estimatedHoursPerSprintWeek= roundedToFloorEstHours + 0.50;
						}else if(nearestFourthDecimal < 0.825){
							estimatedHoursPerSprintWeek= roundedToFloorEstHours + 0.75;
						}else{
							estimatedHoursPerSprintWeek= roundedToFloorEstHours + 1;
						}
					}else{
						estimatedHoursPerSprintWeek = 0;
					}
				}

				for(String s : sprintWeeks){
				/**********************Create Map of Unique Id of New Sprint Plan for Week***************************************/
					String uniqueSprintWeekId;
					uniqueSprintWeekId = c.Id + s;

					String sprintWeekName = c.Subject + ': Sprint Week ' + s;
					
					List<String> sprintWeekDateParts = new List<String>();
					sprintWeekDateParts = s.split('/');
					String sprintDayofMonth = sprintWeekDateParts[1];
					String sprintMonth = sprintWeekDateParts[0];
					String sprintYear;
					if(sprintWeekDateParts.size() > 2){
						sprintYear = sprintWeekDateParts[2];
					}else{ 
						sprintYear = String.valueOf((System.today()).year());
					}
					String sprintWeekDateString = sprintYear + '-' + sprintMonth + '-' + sprintDayofMonth;
					Date sprintDate = Date.valueOf(sprintWeekDateString);
					Datetime sprintDateTime = Datetime.newInstance(sprintDate.year(), sprintDate.month(), sprintDate.day());

					//Added 8.19 as a catch all to use with a custom Apex object instead of multiple maps
					SprintWeekDetailsObj newWeekSprintPlanDetailsObj = new SprintWeekDetailsObj();
					newWeekSprintPlanDetailsObj.relatedCase = c;
					newWeekSprintPlanDetailsObj.estimatedSprintHours = estimatedHoursPerSprintWeek;
					newWeekSprintPlanDetailsObj.sprintName = sprintWeekName;
					newWeekSprintPlanDetailsObj.sprintDate = sprintDateTime;
					newWeekSprintPlanDetailsObj.estimatedSprintQAHours = c.Estimated_QA_Hours__c;
					newWeekSprintPlanDetailsObj.lastSprint = lastSprintWeek;
					weekSprintPlanUIDToDetailsMap.put(uniqueSprintWeekId, newWeekSprintPlanDetailsObj);


					/**********************Create Map of Unique Id of New Sprint Plan for Month***************************************/
					String uniqueSprintMonthId;
					uniqueSprintMonthId = c.Id + sprintMonth + sprintYear;

					//UID to Sprint Month Name
					String sprintMonthDateString = sprintYear + '-' + sprintMonth + '-01';
					Date sprintMonthDate = Date.valueOf(sprintWeekDateString);
					Datetime sprintMonthDateTime = Datetime.newInstance(sprintMonthDate.year(), sprintMonthDate.month(), 1);
					String sprintMonthName = c.Subject + ': Sprint Month ' + sprintMonthDateTime.format('MMMM') + ' ' + sprintYear;

					//Added 8.19 as a catch all to use with a custom Apex object instead of multiple maps
					SprintWeekDetailsObj newMonthlySprintPlanDetailsObj = new SprintWeekDetailsObj();

					Decimal estimatedHoursForMonth = 0; 

					//UID to Estimated Quarter Hours
					if(monthSprintPlanUIDToDetailsMap.containsKey(uniqueSprintMonthId) && monthSprintPlanUIDToDetailsMap.get(uniqueSprintMonthId).estimatedSprintHours != null){
						estimatedHoursForMonth = monthSprintPlanUIDToDetailsMap.get(uniqueSprintMonthId).estimatedSprintHours + estimatedHoursPerSprintWeek;
					}else{
						estimatedHoursForMonth = estimatedHoursPerSprintWeek;
					}

					newMonthlySprintPlanDetailsObj.relatedCase = c;
					newMonthlySprintPlanDetailsObj.estimatedSprintHours = estimatedHoursForMonth;
					newMonthlySprintPlanDetailsObj.sprintName = sprintMonthName;
					newMonthlySprintPlanDetailsObj.sprintDate = sprintMonthDateTime;
					newMonthlySprintPlanDetailsObj.estimatedSprintQAHours = c.Estimated_QA_Hours__c;
					String lastSprintMonth = lastSprintWeekParts[0] + '/' + 1 + '/' + lastSprintWeekParts[2];
					newMonthlySprintPlanDetailsObj.lastSprint = lastSprintMonth;
					monthSprintPlanUIDToDetailsMap.put(uniqueSprintMonthId, newMonthlySprintPlanDetailsObj);

					/**********************Create Map of Unique Id of New Sprint Plan for Quarter***************************************/
					String uniqueSprintQuarterId;
					String quarterName;
					switch on sprintMonth {
						when '1', '2', '3'{
							quarterName = 'Q1';
						}
						when '4', '5', '6'{
							quarterName = 'Q2';
						}
						when '7', '8', '9'{
							quarterName = 'Q3';
						}
						when '10', '11', '12'{
							quarterName = 'Q4';
						}
					}
					uniqueSprintQuarterId = c.Id + quarterName;              

					//UID to Sprint Quarter Name
					String sprintQuarterName = c.Subject + ': Sprint Quarter ' + quarterName + ' ' + sprintYear;

					//Added 8.19 as a catch all to use with a custom Apex object instead of multiple maps
					SprintWeekDetailsObj newQuarterSprintPlanDetailsObj = new SprintWeekDetailsObj();
					Decimal estimatedHoursForQuarter = 0; 

					//UID to Estimated Quarter Hours
					if(quarterSprintPlanUIDToDetailsMap.containsKey(uniqueSprintQuarterId) && quarterSprintPlanUIDToDetailsMap.get(uniqueSprintQuarterId).estimatedSprintHours != null){
						estimatedHoursForQuarter = quarterSprintPlanUIDToDetailsMap.get(uniqueSprintQuarterId).estimatedSprintHours + estimatedHoursPerSprintWeek;
					}else{
						estimatedHoursForQuarter = estimatedHoursPerSprintWeek;
					}
					newQuarterSprintPlanDetailsObj.relatedCase = c;
					newQuarterSprintPlanDetailsObj.estimatedSprintHours = estimatedHoursForQuarter;
					newQuarterSprintPlanDetailsObj.sprintName = sprintQuarterName;
					newQuarterSprintPlanDetailsObj.estimatedSprintQAHours = c.Estimated_QA_Hours__c;
					newQuarterSprintPlanDetailsObj.lastSprint = getQuarterFromDate(lastSprintWeek);
					quarterSprintPlanUIDToDetailsMap.put(uniqueSprintQuarterId, newQuarterSprintPlanDetailsObj);
				}
			}
		}

		/****************************************Insert/Update/Delete Sprint Quarter Plans ********************************************************************************************/
		List<Sprint_Plan__c> sprintPlanQuartersToUpdate = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanQuartersToInsert = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanQuartersToDelete = new List<Sprint_Plan__c>();
		Boolean quarterPlanChanged;
		//Loop through new Quarter plans and check against existing Quarter Plans
		for(String uid : quarterSprintPlanUIDToDetailsMap.keySet()){
			quarterPlanChanged = false;
			SprintWeekDetailsObj sprintQuarterDetail = quarterSprintPlanUIDToDetailsMap.get(uid);
			if(existingSprintPlanQuartersUIDMap.containsKey(uid)){

				Sprint_Plan__c existingSPQ = existingSprintPlanQuartersUIDMap.get(uid);

				if(existingSPQ.Estimated_Hours_for_Quarter__c != sprintQuarterDetail.estimatedSprintHours){
					quarterPlanChanged = true;
					existingSPQ.Estimated_Hours_for_Quarter__c = sprintQuarterDetail.estimatedSprintHours;
				}

				//8.19.22 ST If this week is the last Sprint Month for the Case then we want to give it all the Estimated QA Hours

				if(existingSPQ.Sprint_Quarter__c == sprintQuarterDetail.lastSprint){
					if(existingSPQ.EstimatedQAHours__c != sprintQuarterDetail.estimatedSprintQAHours){
						quarterPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = sprintQuarterDetail.estimatedSprintQAHours;
					}
				}else{
					if(existingSPQ.EstimatedQAHours__c != 0){
						quarterPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = 0;
					}
				}

				if(existingSPQ.Full_Name__c != sprintQuarterDetail.sprintName){
					quarterPlanChanged = true;
					existingSPQ.Full_Name__c = sprintQuarterDetail.sprintName;
					if(sprintQuarterDetail.sprintName.length() > 80){
						existingSPQ.Name = sprintQuarterDetail.sprintName.left(80);
					}else{
						existingSPQ.Name = sprintQuarterDetail.sprintName;
					}
				}
				if(quarterPlanChanged){
					sprintPlanQuartersToUpdate.add(existingSPQ);
				}
				existingSprintPlanQuartersUIDMap.remove(uid);

			}else{
				//These Sprint Plans need to be created
				Sprint_Plan__c newPlan = new Sprint_Plan__c();
				newPlan.RecordTypeId = sprintPlanQuarterRT;
				String planName = sprintQuarterDetail.sprintName;
				if(planName.length() > 80){
				newPlan.Name = planName.left(80);
				}else{
				newPlan.Name = planName;
				}
				newPlan.Full_Name__c = planName;
				newPlan.Case__c = sprintQuarterDetail.relatedCase.Id;
				newPlan.Estimated_Hours_for_Quarter__c = sprintQuarterDetail.estimatedSprintHours;
				String quarterAndYear = planName.substringAfter(': Sprint Quarter ');
				String planQuarterName = quarterAndYear.substringBefore(' ');
				newPlan.Sprint_Quarter__c = planQuarterName;
				newPlan.Sprint_Quarter_Picklist__c = planQuarterName;
				//8.19.22 ST If this week is the last Sprint Week for the Case then we want to give it all the Estimated QA Hours
				if(planQuarterName == sprintQuarterDetail.lastSprint){
					newPlan.EstimatedQAHours__c = sprintQuarterDetail.estimatedSprintQAHours;
				}else{
					newPlan.EstimatedQAHours__c = 0;
				}
				sprintPlanQuartersToInsert.add(newPlan);
			}
		}

		for(Sprint_Plan__c sp : existingSprintPlanQuartersUIDMap.values()){
			sprintPlanQuartersToDelete.add(sp);
		}

		if(sprintPlanQuartersToUpdate.size() > 0){
			sprintPlansToUpdate.addAll(sprintPlanQuartersToUpdate);
		}
		if(sprintPlanQuartersToInsert.size() > 0){
			sprintPlansToInsert.addAll(sprintPlanQuartersToInsert);
		}
		if(sprintPlanQuartersToDelete.size() > 0){
			sprintPlansToDelete.addAll(sprintPlanQuartersToDelete);
		}

		/****************************************Insert/Update/Delete Sprint Month Plans ********************************************************************************************/
		List<Sprint_Plan__c> sprintPlanMonthsToUpdate = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanMonthsToInsert = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanMonthsToDelete = new List<Sprint_Plan__c>();
		Boolean monthPlanChanged;
		//Loop through new Month plans and check against existing Month Plans
		for(String uid : monthSprintPlanUIDToDetailsMap.keySet()){
			monthPlanChanged = false;
			SprintWeekDetailsObj sprintMonthDetail = monthSprintPlanUIDToDetailsMap.get(uid);

			List<String> lastSprintParts = sprintMonthDetail.lastSprint.split('/');
			Date lastSprintMonthDate = Date.newInstance(Integer.valueOf(lastSprintParts[2]), Integer.valueOf(lastSprintParts[0]), 1); 
			System.debug('Last Sprint Month Date: ' + lastSprintMonthDate);

			if(existingSprintPlanMonthsUIDMap.containsKey(uid)){

				Sprint_Plan__c existingSPQ = existingSprintPlanMonthsUIDMap.get(uid);

				if(existingSPQ.Estimated_Hours_for_Month__c != sprintMonthDetail.estimatedSprintHours){
					monthPlanChanged = true;
					existingSPQ.Estimated_Hours_for_Month__c = sprintMonthDetail.estimatedSprintHours;
				}

				//8.19.22 ST If this week is the last Sprint Month for the Case then we want to give it all the Estimated QA Hours
				System.debug('Sprint Month Date: ' + existingSPQ.Sprint_Month_Date__c);
				if(existingSPQ.Sprint_Month_Date__c == lastSprintMonthDate){
					if(existingSPQ.EstimatedQAHours__c != sprintMonthDetail.estimatedSprintQAHours){
						System.debug('Setting Sprint Month Estimated Sprint QA Hours: ' + sprintMonthDetail.estimatedSprintQAHours);
						monthPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = sprintMonthDetail.estimatedSprintQAHours;
					}
				}else{
					if(existingSPQ.EstimatedQAHours__c != 0){
						monthPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = 0;
					}
				}

				if(existingSPQ.Full_Name__c != sprintMonthDetail.sprintName){
					monthPlanChanged = true;
					existingSPQ.Full_Name__c = sprintMonthDetail.sprintName;
					if(sprintMonthDetail.sprintName.length() > 80){
						existingSPQ.Name = sprintMonthDetail.sprintName.left(80);
					}else{
						existingSPQ.Name = sprintMonthDetail.sprintName;
					}
				}
				if(monthPlanChanged){
					sprintPlanMonthsToUpdate.add(existingSPQ);
				}
				existingSprintPlanMonthsUIDMap.remove(uid);

			}else{
				//These Sprint Plans need to be created
				Sprint_Plan__c newPlan = new Sprint_Plan__c();
				newPlan.RecordTypeId = sprintPlanMonthRT;
				String planName = sprintMonthDetail.sprintName;
				if(planName.length() > 80){
					newPlan.Name = planName.left(80);
				}else{
					newPlan.Name = planName;
				}
				newPlan.Full_Name__c = planName;
				newPlan.Case__c = sprintMonthDetail.relatedCase.Id;
				newPlan.Estimated_Hours_for_Month__c = sprintMonthDetail.estimatedSprintHours;
				DateTime sprintMonthDateTime = sprintMonthDetail.sprintDate;
				String sprintMonth = sprintMonthDateTime.format('MMMM');
				Date sprintMonthDate = sprintMonthDateTime.date();
				newPlan.Sprint_Month__c = sprintMonth; //String 'July'
				newPlan.Sprint_Month_Picklist__c = sprintMonth; //String 'July'
				newPlan.Sprint_Month_Date__c = sprintMonthDate; //Date 7/1/2021
				//8.19.22 ST If this week is the last Sprint Week for the Case then we want to give it all the Estimated QA Hours
				if(sprintMonthDate == lastSprintMonthDate){
					newPlan.EstimatedQAHours__c = sprintMonthDetail.estimatedSprintQAHours;
				}else{
					newPlan.EstimatedQAHours__c = 0;
				}

				sprintPlanMonthsToInsert.add(newPlan);
			}
		}

		for(Sprint_Plan__c sp : existingSprintPlanMonthsUIDMap.values()){
			sprintPlanMonthsToDelete.add(sp);
		}

		if(sprintPlanMonthsToUpdate.size() > 0){
			sprintPlansToUpdate.addAll(sprintPlanMonthsToUpdate);
		}
		if(sprintPlanMonthsToInsert.size() > 0){
			sprintPlansToInsert.addAll(sprintPlanMonthsToInsert);
		}
		if(sprintPlanMonthsToDelete.size() > 0){
			sprintPlansToDelete.addAll(sprintPlanMonthsToDelete);
		}

		/****************************************Insert/Update/Delete Sprint Week Plans ********************************************************************************************/
		List<Sprint_Plan__c> sprintPlanWeeksToUpdate = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanWeeksToInsert = new List<Sprint_Plan__c>();
		List<Sprint_Plan__c> sprintPlanWeeksToDelete = new List<Sprint_Plan__c>();
		Boolean weekPlanChanged;
		//Loop through new Week plans and check against existing Week Plans
		for(String uid : weekSprintPlanUIDToDetailsMap.keySet()){
			weekPlanChanged = false;
			SprintWeekDetailsObj sprintWeekDetail = weekSprintPlanUIDToDetailsMap.get(uid);
			if(existingSprintPlanWeeksUIDMap.containsKey(uid)){

				Sprint_Plan__c existingSPQ = existingSprintPlanWeeksUIDMap.get(uid);

				if(existingSPQ.Estimated_Hours_per_Week__c != sprintWeekDetail.estimatedSprintHours){
					weekPlanChanged = true;
					existingSPQ.Estimated_Hours_per_Week__c = sprintWeekDetail.estimatedSprintHours;
				}

				//8.19.22 ST If this week is the last Sprint Week for the Case then we want to give it all the Estimated QA Hours
				if(existingSPQ.Sprint_Week_Picklist__c == sprintWeekDetail.lastSprint){
					if(existingSPQ.EstimatedQAHours__c != sprintWeekDetail.estimatedSprintQAHours){
						weekPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = sprintWeekDetail.estimatedSprintQAHours;
					}
				}else{
					if(existingSPQ.EstimatedQAHours__c != 0){
						weekPlanChanged = true;
						existingSPQ.EstimatedQAHours__c = 0;
					}
				}

				if(existingSPQ.Full_Name__c != sprintWeekDetail.sprintName){
					weekPlanChanged = true;
					existingSPQ.Full_Name__c = sprintWeekDetail.sprintName;
					if(sprintWeekDetail.sprintName.length() > 80){
						existingSPQ.Name = sprintWeekDetail.sprintName.left(80);
					}else{
						existingSPQ.Name = sprintWeekDetail.sprintName;
					}
				}
				if(weekPlanChanged){
					sprintPlanWeeksToUpdate.add(existingSPQ);
				}
				existingSprintPlanWeeksUIDMap.remove(uid);

			}else{
				//These Sprint Plans need to be created
				Sprint_Plan__c newPlan = new Sprint_Plan__c();
				newPlan.RecordTypeId = sprintPlanWeekRT;
				String planName = sprintWeekDetail.sprintName;
				if(planName.length() > 80){
					newPlan.Name = planName.left(80);
				}else{
					newPlan.Name = planName;
				}
				newPlan.Full_Name__c = planName;
				newPlan.Case__c = sprintWeekDetail.relatedCase.Id;
				newPlan.Estimated_Hours_per_Week__c = sprintWeekDetail.estimatedSprintHours;


				String fullSprintWeek = planName.substringAfter(': Sprint Week ');
				String partialSprintWeek = fullSprintWeek.substringBeforeLast('/');
				newPlan.Sprint_Week__c = partialSprintWeek; //String 5/24
				newPlan.Sprint_Week_Picklist__c = fullSprintWeek; //5/24/2021
				//8.19.22 ST If this week is the last Sprint Week for the Case then we want to give it all the Estimated QA Hours
				if(fullSprintWeek == sprintWeekDetail.lastSprint){
					newPlan.EstimatedQAHours__c = sprintWeekDetail.estimatedSprintQAHours;
				}else{
					newPlan.EstimatedQAHours__c = 0;
				}
				DateTime sprintWeekDateTime = sprintWeekDetail.sprintDate;
				newPlan.Sprint_Week_Date__c = sprintWeekDateTime.date(); //Date 2021-05-24
				sprintPlanWeeksToInsert.add(newPlan);
			}
		}

		for(Sprint_Plan__c sp : existingSprintPlanWeeksUIDMap.values()){
			sprintPlanWeeksToDelete.add(sp);
		}

		if(sprintPlanWeeksToUpdate.size() > 0){
			sprintPlansToUpdate.addAll(sprintPlanWeeksToUpdate);
		}
		if(sprintPlanWeeksToInsert.size() > 0){
			sprintPlansToInsert.addAll(sprintPlanWeeksToInsert);
		}
		if(sprintPlanWeeksToDelete.size() > 0){
			sprintPlansToDelete.addAll(sprintPlanWeeksToDelete);
		}

		if(sprintPlansToUpdate.size() > 0){
			update sprintPlansToUpdate;
		}

		if(sprintPlansToInsert.size() > 0){
			insert sprintPlansToInsert;
		}

		if(sprintPlansToDelete.size() > 0){
			delete sprintPlansToDelete;
		}
	}

	public static void updateCaseOwnerForKanban(List<Case> newCaseList, Map<Id, Case> oldCaseMap, Boolean isForUpdate){
		//Keep the Case_Owner__c field updated with the OwnerId of the Case so that it is accurate and is populated correctly for the Kanban
		//Also update the actual Case OwnerId with the Case_Owner__c field when the change is made inside the Kanban
		for(Case c : newCaseList){

			Id ownerId = c.OwnerId;
			String newOwnerObjectType = String.valueOf(ownerId.getSObjectType());

			if(isForUpdate){
				//For Before Update
				if(c.OwnerId != oldCaseMap.get(c.Id).OwnerId && c.Case_Owner__c != c.OwnerId){
					//If the Case's OwnerId field changes then update the Case_Owner__c field with new value unless it is not a User then if so then NULL the Case_Owner__c field
					if(newOwnerObjectType == 'User'){
						c.Case_Owner__c = c.OwnerId;
					}else{
						c.Case_Owner__c = null;
					}

				}else if(c.Case_Owner__c != oldCaseMap.get(c.Id).Case_Owner__c && c.OwnerId != c.Case_Owner__c){
					c.OwnerId = c.Case_Owner__c;
				}
			}else{
				//For Before Insert
				if(newOwnerObjectType == 'User'){
					c.Case_Owner__c = c.OwnerId;
				}
			}
		}
	}

	public static void updateStaffTransitionsAmountOnAccount(List<Case> resourceSwapCases){

		List<Account> updateAccountList = new List<Account>();

		List<Id> relatedProjectIdList = new List<Id>();
		for(Case swapCase : resourceSwapCases){
			if(swapCase.Project__c != null){
				relatedProjectIdList.add(swapCase.Project__c);
			}
		}

		Map<Id, Decimal> accountIdToResourceSwapCaseCountMap = new Map<Id, Decimal>();
		if(relatedProjectIdList.size() > 0){

			List<Project__c> relatedProjectList = new List<Project__c>();
			relatedProjectList = [SELECT Id, Name, Account__c FROM Project__c WHERE Id IN :relatedProjectIdList];
			for(Project__c proj : relatedProjectList){

				if(proj.Account__c != null){
					accountIdToResourceSwapCaseCountMap.put(proj.Account__c, 0);
				}
			} 

			AggregateResult[] levSwapResourceAggregate = [SELECT COUNT(Id) caseCount, Project__r.Account__c acctId
															FROM Case
															WHERE Project__r.Account__c IN :accountIdToResourceSwapCaseCountMap.keySet() AND RecordTypeId =: LevSwapResourceRequestRT AND Status = 'Completed'
															GROUP BY Project__r.Account__c];

			for(AggregateResult ar : levSwapResourceAggregate){
				Id accountId = (Id)ar.get('acctId');
				if(accountIdToResourceSwapCaseCountMap.containsKey(accountId)){
					Integer levResourceSwapCaseCount = (Integer)ar.get('caseCount');
					accountIdToResourceSwapCaseCountMap.put(accountId, levResourceSwapCaseCount);
				}              
			}
		}

		if(accountIdToResourceSwapCaseCountMap.size() > 0){
			List<Account> relatedAccountList = new List<Account>();
			relatedAccountList = [SELECT Id, Name, Staff_Transitions_Amount__c FROM Account WHERE Id IN :accountIdToResourceSwapCaseCountMap.keySet()];

			for(Account acct : relatedAccountList){
				if(accountIdToResourceSwapCaseCountMap.containsKey(acct.Id)){
					if(acct.Staff_Transitions_Amount__c != accountIdToResourceSwapCaseCountMap.get(acct.Id)){ //If the Staff Transistions Amount changes then make update and add to update list, otherwise do nothing
						acct.Staff_Transitions_Amount__c = accountIdToResourceSwapCaseCountMap.get(acct.Id);
						updateAccountList.add(acct);
					}
				}
			}
		}

		if(updateAccountList.size() > 0){
			update updateAccountList;
		}
	}

	private static String getMonthsFromNumber(Set<String> monthNumber, Boolean isForMonth){
		String monthMultiPicklist = '';
		String quarterMultiPicklist = '';
		for(String mn : monthNumber){
		switch on mn{
			when '1'{
			monthMultiPicklist += 'January' + ';';
			}
			when '2'{
			monthMultiPicklist += 'February' + ';';
			}
			when '3'{
			monthMultiPicklist += 'March' + ';';
			}
			when '4'{
			monthMultiPicklist += 'April' + ';';
			}
			when '5'{
			monthMultiPicklist += 'May' + ';';
			}
			when '6'{
			monthMultiPicklist += 'June' + ';';
			}
			when '7'{
			monthMultiPicklist += 'July' + ';';
			}
			when '8'{
			monthMultiPicklist += 'August' + ';';
			}
			when '9'{
			monthMultiPicklist += 'September' + ';';
			}
			when '10'{
			monthMultiPicklist += 'October' + ';';
			}
			when '11'{
			monthMultiPicklist += 'November' + ';';
			}
			when '12'{
			monthMultiPicklist += 'December' + ';';
			}
		}
		}

		monthMultiPicklist = monthMultiPicklist.substring(0,monthMultiPicklist.length() - 1);
		if(isForMonth == true){
		return monthMultiPicklist;
		}else{
		if(monthMultiPicklist.contains('January') || monthMultiPicklist.contains('February') || monthMultiPicklist.contains('March')){
			quarterMultiPicklist += 'Q1;';
		}
		if(monthMultiPicklist.contains('April') || monthMultiPicklist.contains('May') || monthMultiPicklist.contains('June')){
			quarterMultiPicklist += 'Q2;';
		}
		if(monthMultiPicklist.contains('July') || monthMultiPicklist.contains('August') || monthMultiPicklist.contains('September')){
			quarterMultiPicklist += 'Q3;';
		}
		if(monthMultiPicklist.contains('October') || monthMultiPicklist.contains('November') || monthMultiPicklist.contains('December')){
			quarterMultiPicklist += 'Q4;';
		}
		return quarterMultiPicklist.substring(0,quarterMultiPicklist.length() - 1);
		}
	}

	//Format Date to Sprint Week format
	private static String formatDateToString(Date dateToFormat){
		String formattedDate;
		formattedDate = String.valueOf(dateToFormat.month()) + '/' +  String.valueOf(dateToFormat.day()) + '/' + String.valueOf(dateToFormat.year());

		return formattedDate;
	}

	private class SprintWeekDetailsObj{
		public String sprintPlanRecordType;
		public Case relatedCase;
		public Decimal estimatedSprintHours;
		public String sprintName;
		public Datetime sprintDate;
		public Decimal estimatedSprintQAHours;
		public String lastSprint;


	}

	private static String getQuarterFromDate(String inputDate){

		List<String> lastSprintWeekParts = inputDate.split('/');
		String sprintMonth = lastSprintWeekParts[0];
		String quarterName;

		switch on sprintMonth {
			when '1', '2', '3'{
				quarterName = 'Q1';
			}
			when '4', '5', '6'{
				quarterName = 'Q2';
			}
			when '7', '8', '9'{
				quarterName = 'Q3';
			}
			when '10', '11', '12'{
				quarterName = 'Q4';
			}
		}

		return quarterName;

	}

	public static void rollupNonBillOrConcessionRequestsOnProjects(Set<Id> projectIdSet){

		Map<Id, Decimal> projectIdToNonBillOrConcessionRequestsCountMap = new Map<Id, Decimal>();
		for(Id projId : projectIdSet){
			projectIdToNonBillOrConcessionRequestsCountMap.put(projId, 0);
		}

		AggregateResult[] nonbillOrConcessionCaseAgg = [SELECT COUNT(Id), Project__c
														FROM Case
														WHERE Project__c IN :projectIdToNonBillOrConcessionRequestsCountMap.keySet() AND RecordTypeId =: nonbillOrConcessionRequestRT
														GROUP BY Project__c
														ORDER BY COUNT(Id) DESC];

		for(AggregateResult ar : nonbillOrConcessionCaseAgg){
			Decimal nonBillOrConcessionRequestCount = (Decimal)ar.get('expr0');
			Id projectId = (Id)ar.get('Project__c');

			projectIdToNonBillOrConcessionRequestsCountMap.put(projectId, nonBillOrConcessionRequestCount);
		}

		List<Project__c> relatedProjectList = new List<Project__c>();
		relatedProjectList = [SELECT Id, Name, Total_Non_Bill_or_Concession_Requests__c
								FROM Project__c
								WHERE Id IN :projectIdToNonBillOrConcessionRequestsCountMap.keySet()];

		List<Project__c> projectUpdateList = new List<Project__c>();
		for(Project__c proj : relatedProjectList){
			if(projectIdToNonBillOrConcessionRequestsCountMap.containsKey(proj.Id) && proj.Total_Non_Bill_or_Concession_Requests__c != projectIdToNonBillOrConcessionRequestsCountMap.get(proj.Id)){
				proj.Total_Non_Bill_or_Concession_Requests__c = projectIdToNonBillOrConcessionRequestsCountMap.get(proj.Id);
				projectUpdateList.add(proj);
			}
		}

		if(projectUpdateList.size() > 0){
			System.debug('Updating Total Count of Nonbill Requests on ' + projectUpdateList.size() + ' Projects');
			update projectUpdateList;
		}
	}

}