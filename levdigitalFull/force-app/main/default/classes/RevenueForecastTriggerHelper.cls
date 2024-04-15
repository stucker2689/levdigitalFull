public with sharing class RevenueForecastTriggerHelper {

    private static String monthlyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Monthly Target').getRecordTypeId();
    private static String weeklyTargetRT = Schema.SObjectType.Revenue_Forecast__c.getRecordTypeInfosByName().get('Weekly Target').getRecordTypeId();

    public static List<String> opportunityClosedWonStageNames = new List<String>{'Won', 'Partial Win', 'Closed Won'};

    //private static String levementumAccountId = '001d000000JGuQaAAL';
    private static String levementumAccountName = 'Levementum LLC';

    public static void populateMonthlyTargetFields(List<Revenue_Forecast__c> newMonthlyTargetList){
        System.debug('*******************************populateMonthlyTargetFields');
        //Create the Record Name for Weekly Target Record Types

        for(Revenue_Forecast__c rf : newMonthlyTargetList){
            if(rf.MonthStartDate__c != null){
                //Populate Revenue Forecast Name
                String monthName = getMonthNameFromNumber(rf.MonthStartDate__c.month());
                String monthYear = String.valueOf(rf.MonthStartDate__c.year());
                String monthlyTargetRecordName = 'Monthly Target: ' + monthName + ' ' + monthYear;
                rf.RevenueForecastName__c = monthlyTargetRecordName;

                //Populate Month End Date
                Integer daysInMonth = date.daysInMonth(rf.MonthStartDate__c.year(), rf.MonthStartDate__c.month());
                rf.MonthEndDate__c = rf.MonthStartDate__c.addDays(daysInMonth - 1);

                //Populate Business Days for the Month
                Integer businessDaysInMonth = getBusinessDaysBetweenTwoDates(rf.MonthStartDate__c, rf.MonthStartDate__c.addDays(daysInMonth), true); //The End Date is not included in the Days Between Calc so need to extend end date by 1 to get all days in month
                rf.BusinessDaysInForecastRange__c = businessDaysInMonth;
            }else{
                rf.addError('Month Start Date is required to be populated for Monthly Target Revenue Forecast');
            }
        }
    }

    public static void rollupWeeklyForecastsOnInsert(List<Revenue_Forecast__c> newWeeklyTargetList){
        /**
         * Purpose: To rollup the existing Replicon Forecast Estimated Revenue to the Weekly target on Insert
         */
        List<Date> weekEndDateList = new List<Date>();
        for(Revenue_Forecast__c weeklyTarget : newWeeklyTargetList){
            if(weeklyTarget.FullWeekEndDate__c != null){
                weekEndDateList.add(weeklyTarget.FullWeekEndDate__c);
            }
        }

        AggregateResult[] repliconForecasts = [SELECT sum(EstimatedRevenue__c), Week_End_Date__c
                                                FROM RepliconForecast__c
                                                WHERE Deleted_in_Replicon__c = false AND EstimatedRevenue__c > 0 AND Week_End_Date__c IN :weekEndDateList AND Contact__r.Account.Name =: levementumAccountName
                                                GROUP BY Week_End_Date__c];

        Map<Date, Decimal> forecastWeekEndDateToRevenueMap = new Map<Date, Decimal>();
        for(AggregateResult ar : repliconForecasts){
            Decimal estimatedRevenueSum;
            Date weekEndDate;
            estimatedRevenueSum = (Decimal)ar.get('expr0');
            weekEndDate = (Date)ar.get('Week_End_Date__c');
            forecastWeekEndDateToRevenueMap.put(weekEndDate, estimatedRevenueSum);
        }

        List<Revenue_Forecast__c> weeklyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c weeklyTarget : newWeeklyTargetList){

            if(forecastWeekEndDateToRevenueMap.containsKey(weeklyTarget.FullWeekEndDate__c)){
                if(weeklyTarget.FullWeekEndDate__c.month() == weeklyTarget.FullWeekStartDate__c.month()){ //Forecast $ will all go to a singular weekly target
                    weeklyTarget.WeeklyForecast__c = forecastWeekEndDateToRevenueMap.get(weeklyTarget.FullWeekEndDate__c);
                    weeklyTargetsToUpdate.add(weeklyTarget);

                }else{ //Forecast $ needs to be split between 2 weekly targets because it is a week that spans 2 months
                    /**
                     * To split forecast amount across two weekly targets we need to get the amount of business days in that week and divide the forecast $ by that number to get the forecast per day amount
                     * Then multiple the daily forecast by the business days in the weekly target to get the forecast $
                     */                    
                    Integer daysInWeek;
                    Decimal forecastDailyAmount;
                    Decimal weekForecastAmount; 
                    daysInWeek = getBusinessDaysBetweenTwoDates(weeklyTarget.FullWeekStartDate__c, weeklyTarget.FullWeekEndDate__c, false);
                    if(daysInWeek > 0){
                        forecastDailyAmount = forecastWeekEndDateToRevenueMap.get(weeklyTarget.FullWeekEndDate__c) / daysInWeek;
                        weekForecastAmount = forecastDailyAmount * weeklyTarget.BusinessDaysInForecastRange__c;
                    }else{
                        weekForecastAmount = 0;
                    }

                    weeklyTarget.WeeklyForecast__c = weekForecastAmount;
                    weeklyTargetsToUpdate.add(weeklyTarget);
                }
            }

        }

        if(weeklyTargetsToUpdate.size() > 0){
            //update weeklyTargetsToUpdate; //Moved to Before Insert
            //Need to update the monthly Forecast amount on insert as well
            weeklyForecastsChanged(weeklyTargetsToUpdate); //Rollup Changed Weekly Forecast Amounts to the related Monthly Actuals Amount
        }

    }

    public static void rollupWeeklyBookingsOnInsert(List<Revenue_Forecast__c> newRWeeklyTargetList){
        /**
         * Purpose: Rollup the Amounts of Existing Closed Won Opptys that have the Close Date within the weekly target range
         */

        Map<Date, Revenue_Forecast__c> weekStartDateToWeeklyTargetMap = new Map<Date, Revenue_Forecast__c>();
        List<Date> weeklyTargetDateRangeList = new List<Date>(); //Get List of all dates within the ranges of the incoming Weekly Targets Week Start Date - Week End Date, do this to use in the query for the Closed Won Opptys 
        for(Revenue_Forecast__c weeklyTarget : newRWeeklyTargetList){
            Date weekStartDate;
            Date weekEndDate;
            if(weeklyTarget.WeekStartDate__c != null && weeklyTarget.WeekEndDate__c != null){
                weekStartDate = weeklyTarget.WeekStartDate__c;
                weekEndDate = weeklyTarget.WeekEndDate__c;

                Integer daysBetweenStartAndEnd;
                daysBetweenStartAndEnd = weekStartDate.daysBetween(weekEndDate); //Gets Days between start date and end date 0 = same day, 1 = days are next to eachother, 2 = one day inbetween (i.e. 2 = startDate: 3/10 and endDate: 3/12 )

                switch on daysBetweenStartAndEnd {
                    when 0 {
                        //Week Start Date and Week End Date are the same date, so only need to add the Start Date
                        weeklyTargetDateRangeList.add(weekStartDate);
                    }
                    when 1 {
                        //Week is only 2 Days, so only need to add week start date and week end date
                        weeklyTargetDateRangeList.add(weekStartDate);
                        weeklyTargetDateRangeList.add(weekEndDate);

                    }
                    when 2, 3, 4, 5, 6 {
                        //Week spans longer than just 2 days so need to iterate to add all days of week to list
                        for(Integer i=0; i <= daysBetweenStartAndEnd; i++){ //iterate i times where i is the days between start and end dates to add each day of the week to the list
                            weeklyTargetDateRangeList.add(weekStartDate.addDays(i)); //First run adds start date, last should add End Date regardless of if it is partial week of not
                        }
                    }
                    when else {
                        //This would mean the week start date and week end date span more than a week, (aka would mean broken if it reaches here)
                        weeklyTarget.addError('Weekly Target was created with improper Week Start Date of: ' + weekStartDate + ' or Week End Date of: ' + weekEndDate + '. These dates do span longer than a week.');

                    }
                }

                //Create Map of Week Start Date to Weekly Target Record
                weekStartDateToWeeklyTargetMap.put(weekStartDate, weeklyTarget);
            }
        }
        //Query the Closed Won Oppty Amounts that are marked with a Close Date that falls within the range of one of the Weekly Targets inserted
        AggregateResult[] closedWonOpptys = [SELECT sum(Amount), CloseDate
                                            FROM Opportunity
                                            WHERE CloseDate IN :weeklyTargetDateRangeList AND  StageName IN :opportunityClosedWonStageNames AND Amount != 0
                                            GROUP BY CloseDate];

        Map<Date, Decimal> closeDateStartOfWeekToBookingsAmountMap = new Map<Date, Decimal>();
        for(AggregateResult ar : closedWonOpptys){
            Date closeDate;
            Date startOfCloseDateWeek;
            closeDate = (Date)ar.get('CloseDate');
            
            if(closeDate.month() != closeDate.toStartOfWeek().month()){
                 //If the close date is not the same month as the previous Sunday, then Close Date falls on the 2nd half of a partial week where it is at the beginning of a new month and the start of the full week is a different month
                startOfCloseDateWeek = closeDate.toStartOfMonth(); //Therefore the start of Week date for the 2nd half of a partial week is = the start of the month (aka .toStartOfMonth() ) and that will be how to find Weekly Target via WeekStartDate
            }else{
                startOfCloseDateWeek = closeDate.toStartOfWeek();//If start of week is same month as close date then Weekly Target can be found via the previous Sunday for WeekStartDate
            }

            Decimal bookingsAmount = (Decimal)ar.get('expr0');
            //Create map of WeekStartDate to Bookings Amount                            
            if(closeDateStartOfWeekToBookingsAmountMap.containsKey(startOfCloseDateWeek)){
                Decimal existingBookingsAmount = closeDateStartOfWeekToBookingsAmountMap.get(startOfCloseDateWeek);
                existingBookingsAmount += bookingsAmount;
                closeDateStartOfWeekToBookingsAmountMap.put(startOfCloseDateWeek, existingBookingsAmount);
            }else{
                closeDateStartOfWeekToBookingsAmountMap.put(startOfCloseDateWeek, bookingsAmount);
            }

        }         
        
        for(Revenue_Forecast__c weeklyTarget : newRWeeklyTargetList){
            if(closeDateStartOfWeekToBookingsAmountMap.containsKey(weeklyTarget.WeekStartDate__c)){
                weeklyTarget.Bookings__c = closeDateStartOfWeekToBookingsAmountMap.get(weeklyTarget.WeekStartDate__c);
            }else{
                weeklyTarget.Bookings__c = 0;
            }
        }

    }

    public static void createWeeklyTargetsFromMonthly(List<Revenue_Forecast__c> newMonthlyTargetList, Map<Date, Capacity__c> weekStartDateToCapacityMap){
        System.debug('*******************************createWeeklyTargetsFromMonthly');
        //Create the Weekly Target Records that fall under the month for the Monthly Target being created

        //Step 1:
        //Get the start date of the month then create a weekly target rt with WeekStartDate__c as that date
        //Find all the Sundays of the month after the 1st then create weekly targets with that as the WeekStartDate__c
        //Also add Monthly Target Record Id as Lookup on the Weekly Target on field RelatedMonthlyForecast__c

        //Step 2:
        //Split the Monthly Target of the Monthly Target to the Weekly Target
        //Split the Monthly Target up into equal parts per business days of the month
        //Check to see if days in the month are holidays, then also check to see if any day within the week is also a holiday
        List<Capacity__c> capacityRecordsToUpdate = new List<Capacity__c>();
        Map<Date, Capacity__c> capacityStartDateToRecordUpdateMap = new Map<Date, Capacity__c>();
        Set<Revenue_Forecast__c> weeklyTargetsToInsertSet = new Set<Revenue_Forecast__c>();

        Map<Id, Decimal> monthlyTargetIdToMonthlyTargetAmount = new Map<Id, Decimal>();
        for(Revenue_Forecast__c rf : newMonthlyTargetList){
            monthlyTargetIdToMonthlyTargetAmount.put(rf.Id, rf.MonthlyTarget__c);

            Revenue_Forecast__c firstWeeklyTarget = new Revenue_Forecast__c(); //Create Weekly Target Record for the first week of the month starting with the date of the 1st of the Month
            firstWeeklyTarget.RecordTypeId = weeklyTargetRT;
            firstWeeklyTarget.WeekStartDate__c = rf.MonthStartDate__c;
            firstWeeklyTarget.FullWeekStartDate__c = firstWeeklyTarget.WeekStartDate__c.toStartOfWeek();
            firstWeeklyTarget.FullWeekEndDate__c = firstWeeklyTarget.FullWeekStartDate__c.addDays(6);
            firstWeeklyTarget.WeekEndDate__c = firstWeeklyTarget.FullWeekStartDate__c.addDays(6);
            firstWeeklyTarget.RelatedMonthlyForecast__c = rf.Id;
            firstWeeklyTarget.RevenueForecastName__c = 'Weekly Target: ' + firstWeeklyTarget.WeekStartDate__c.format() + ' - ' + firstWeeklyTarget.WeekEndDate__c.format();
            firstWeeklyTarget.BusinessDaysInForecastRange__c = getBusinessDaysBetweenTwoDates(firstWeeklyTarget.WeekStartDate__c, firstWeeklyTarget.WeekEndDate__c.addDays(1), true); //The End Date is not included in the Days Between Calc so need to extend end date by 1 to get all days in week (to include last day)
            
            if(rf.MonthlyTarget__c != null){ //Spread out Monthly Target to the Weekly Targets
                firstWeeklyTarget.WeeklyTarget__c = getWeeklyTargetValueFromMonthTarget(firstWeeklyTarget.WeekStartDate__c, rf.MonthlyTarget__c);
            }

            /********************************************************** Related the Weekly Target to its Respective and rollup the Weekly Target Amount to the Capacity Budget  **********************************************************/
            if(capacityStartDateToRecordUpdateMap.containsKey(firstWeeklyTarget.FullWeekStartDate__c)){
                //If Capacity Record is already in the Update Map then get it from this map to keep any changes that have already occurred
                Capacity__c cap = capacityStartDateToRecordUpdateMap.get(firstWeeklyTarget.FullWeekStartDate__c);
                if(firstWeeklyTarget.WeeklyTarget__c != null){
                    cap.Budget__c = cap.Budget__c == null ? firstWeeklyTarget.WeeklyTarget__c : cap.Budget__c + firstWeeklyTarget.WeeklyTarget__c;
                }
                //capacityRecordsToUpdate.add(cap);
                capacityStartDateToRecordUpdateMap.put(cap.WeekStartDate__c, cap);

                firstWeeklyTarget.Capacity__c = cap.Id;

            }else if(weekStartDateToCapacityMap.containsKey(firstWeeklyTarget.FullWeekStartDate__c)){
                Capacity__c cap = weekStartDateToCapacityMap.get(firstWeeklyTarget.FullWeekStartDate__c);
                if(firstWeeklyTarget.WeeklyTarget__c != null){
                    cap.Budget__c = cap.Budget__c == null ? firstWeeklyTarget.WeeklyTarget__c : cap.Budget__c + firstWeeklyTarget.WeeklyTarget__c;
                }
                //capacityRecordsToUpdate.add(cap);
                capacityStartDateToRecordUpdateMap.put(cap.WeekStartDate__c, cap);

                firstWeeklyTarget.Capacity__c = cap.Id;
            }
            /*****************************************************************************************************************************************************************************************************************************/

            weeklyTargetsToInsertSet.add(firstWeeklyTarget);

            Date weekStartDate = firstWeeklyTarget.WeekStartDate__c.toStartOfWeek();
            
            Integer daysInMonth = Date.daysInMonth(rf.MonthStartDate__c.year(), rf.MonthStartDate__c.month());
            Date lastDayOfMonth = firstWeeklyTarget.WeekStartDate__c.addDays(daysInMonth - 1);

            //While the next Sunday is still in the same month as the Monthly Target then add the next Sunday's Capacity Record to the insert Map
            while(weekStartDate.addDays(7).month() ==  (rf.MonthStartDate__c).month()){
                weekStartDate = weekStartDate.addDays(7); //Add 7 days to set it for the new record and have it check in the while loop if it can use the next week as well for this Month's Revenue Target
                
                Revenue_Forecast__c newWeeklyTarget = new Revenue_Forecast__c(); //Create Weekly Target Record for the all Sundays within Month
                newWeeklyTarget.RecordTypeId = weeklyTargetRT;
                newWeeklyTarget.WeekStartDate__c = weekStartDate;
                newWeeklyTarget.FullWeekStartDate__c = weekStartDate;
                newWeeklyTarget.FullWeekEndDate__c = weekStartDate.addDays(6);
                newWeeklyTarget.RelatedMonthlyForecast__c = rf.Id;

                //If Full Week End Date is the next month, then set the Week End Date as the last day of the month
                if(newWeeklyTarget.FullWeekEndDate__c.month() != rf.MonthStartDate__c.month()){
                    newWeeklyTarget.WeekEndDate__c = lastDayOfMonth;
                }else{
                    newWeeklyTarget.WeekEndDate__c = weekStartDate.addDays(6);
                }
                 //The End Date is not included in the Days Between Calc so need to extend end date by 1 to get all days in week (to include last day);
                newWeeklyTarget.BusinessDaysInForecastRange__c = getBusinessDaysBetweenTwoDates(newWeeklyTarget.WeekStartDate__c, newWeeklyTarget.WeekEndDate__c.addDays(1), true);
                newWeeklyTarget.RevenueForecastName__c = 'Weekly Target: ' + newWeeklyTarget.WeekStartDate__c.format() + ' - ' + newWeeklyTarget.WeekEndDate__c.format();

                if(rf.MonthlyTarget__c != null){ //Spread out Monthly Target to the Weekly Targets
                    newWeeklyTarget.WeeklyTarget__c = getWeeklyTargetValueFromMonthTarget(newWeeklyTarget.WeekStartDate__c, rf.MonthlyTarget__c);
                }

                /********************************************************** Related the Weekly Target to its Respective and rollup the Weekly Target Amount to the Capacity Budget  **********************************************************/
                if(capacityStartDateToRecordUpdateMap.containsKey(newWeeklyTarget.FullWeekStartDate__c)){
                    //If Capacity Record is already in the Update Map then get it from this map to keep any changes that have already occurred
                    Capacity__c cap = capacityStartDateToRecordUpdateMap.get(firstWeeklyTarget.FullWeekStartDate__c);
                    if(newWeeklyTarget.WeeklyTarget__c != null){
                        cap.Budget__c = cap.Budget__c == null ? newWeeklyTarget.WeeklyTarget__c : cap.Budget__c + newWeeklyTarget.WeeklyTarget__c;
                    }
                    //capacityRecordsToUpdate.add(cap);
                    capacityStartDateToRecordUpdateMap.put(cap.WeekStartDate__c, cap);
    
                    newWeeklyTarget.Capacity__c = cap.Id;
    
                }else if(weekStartDateToCapacityMap.containsKey(newWeeklyTarget.FullWeekStartDate__c)){
                    //If Capacity Record has not already been modified then get it from the passed in Map
                    Capacity__c cap = weekStartDateToCapacityMap.get(newWeeklyTarget.FullWeekStartDate__c);
                    if(newWeeklyTarget.WeeklyTarget__c != null){
                        cap.Budget__c = cap.Budget__c == null ? newWeeklyTarget.WeeklyTarget__c : cap.Budget__c + newWeeklyTarget.WeeklyTarget__c;
                    }
                    //capacityRecordsToUpdate.add(cap);
                    capacityStartDateToRecordUpdateMap.put(cap.WeekStartDate__c, cap);

                    newWeeklyTarget.Capacity__c = cap.Id;

                }
                /*****************************************************************************************************************************************************************************************************************************/

                weeklyTargetsToInsertSet.add(newWeeklyTarget);
            }
        }

        List<Revenue_Forecast__c> revForecastsToInsert = new List<Revenue_Forecast__c>();
        if(weeklyTargetsToInsertSet.size() > 0){
            revForecastsToInsert.addAll(weeklyTargetsToInsertSet); //Move Set to List so it can be in DML
            insert revForecastsToInsert; //Insert Weekly Targets for all Weeks within Month of Monthly Targets that were inserted
        }

        if(capacityStartDateToRecordUpdateMap.size() > 0){
            update capacityStartDateToRecordUpdateMap.values();
        }

    }

    public static void monthlyTargetChanged(List<Revenue_Forecast__c> updatedMonthlyTargetList, Map<Id, Revenue_Forecast__c> oldMap){
        System.debug('*******************************monthlyTargetChanged');
        //Evenly distribute the changed Monthly Target Amount among the children Weekly Target Records of the month

        /** Steps:
         * Get the difference from previous amount and new amount of the changed Monthly Target
         * Get the amount of business days in the month of the monthly target
         * Divide the Monthly Target change amount by the business days in the month to find the amount the changed amount should be divided per day
         * Query for all the Weekly Targets that are related to the Monthly Target that was editted
         * 
         * for each of them run the getWeeklyTargetValueFromMonthTarget function with each start date and new monthly Target
         * update the Weekly Targets
         */

        Map<Id, Decimal> monthlyTargetIdToTargetChangePerDayMap = new Map<Id, Decimal>();
        Decimal monthlyTargetChangeAmount;
        Decimal monthlyTargetChangePerDayOfMonth;

        for(Revenue_Forecast__c rf : updatedMonthlyTargetList){

            monthlyTargetChangeAmount = rf.MonthlyTarget__c - oldMap.get(rf.Id).MonthlyTarget__c; //Set Amount that the Monthly Target Changed (New Amount - Old Amount)
            monthlyTargetChangePerDayOfMonth = monthlyTargetChangeAmount / rf.BusinessDaysInForecastRange__c; //Set Amount that the change is to be spread out per day of the month.

            monthlyTargetIdToTargetChangePerDayMap.put(rf.Id, monthlyTargetChangePerDayOfMonth);

        }

        List<Revenue_Forecast__c> relatedWeeklyForecastList = new List<Revenue_Forecast__c>();
        if(monthlyTargetIdToTargetChangePerDayMap.size() > 0){
        relatedWeeklyForecastList = [SELECT Id, WeeklyTarget__c, WeekStartDate__c, WeekEndDate__c, BusinessDaysInForecastRange__c, RelatedMonthlyForecast__c, RelatedMonthlyForecast__r.MonthlyTarget__c
                                    FROM Revenue_Forecast__c
                                    WHERE RelatedMonthlyForecast__c IN :monthlyTargetIdToTargetChangePerDayMap.keySet()];
        }

        List<Revenue_Forecast__c> weeklyForecastsToUpdateList = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : relatedWeeklyForecastList){
            if(monthlyTargetIdToTargetChangePerDayMap.containsKey(rf.RelatedMonthlyForecast__c)){
                //Commented out due to above addition
                //Decimal targetChangeForWeek = monthlyTargetIdToTargetChangePerDayMap.get(rf.RelatedMonthlyForecast__c) * rf.BusinessDaysInForecastRange__c;
                //rf.WeeklyTarget__c += targetChangeForWeek;
                //weeklyForecastsToUpdateList.add(rf);

                //Added 9.8.22 ST
                Decimal newWeeklyTargetAmount = getWeeklyTargetValueFromMonthTarget(rf.WeekStartDate__c, rf.RelatedMonthlyForecast__r.MonthlyTarget__c);
                if(rf.WeeklyTarget__c != newWeeklyTargetAmount){
                    rf.WeeklyTarget__c = newWeeklyTargetAmount;
                    weeklyForecastsToUpdateList.add(rf);
                }
            }
        }
         
        if(weeklyForecastsToUpdateList.size() > 0){
            update weeklyForecastsToUpdateList;
        }

    }

    public static void weeklyTargetChanged(List<Revenue_Forecast__c> updatedWeeklyTargetList){
        System.debug('*******************************weeklyTargetChanged');
        //Adjust the parent Monthly target with the changed amount of the weekly Target changed amount
        
        /**Steps:
         * Create Map of all the related Monthly Targets of the updated Weekly Targets
         * run a sum(WeeklyTarget__c) query for the Weekly Targets where Monthly Target Id = the same as the one changed
         * update the Monthly Targets 
         */

        Set<Id> relatedMonthlyTargetsSet = new Set<Id>();
        Set<Id> relatedCapacityIdSet = new Set<Id>();
        for(Revenue_Forecast__c rf : updatedWeeklyTargetList){
            if(rf.RelatedMonthlyForecast__c != null){
                relatedMonthlyTargetsSet.add(rf.RelatedMonthlyForecast__c);
            }

            if(rf.Capacity__c != null){
                relatedCapacityIdSet.add(rf.Capacity__c);
            }
        }

        List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();

        if(relatedMonthlyTargetsSet.size() > 0){
            weeklyTargetsList = [SELECT WeeklyTarget__c, RelatedMonthlyForecast__c, Capacity__c
                            FROM Revenue_Forecast__c
                            WHERE (RelatedMonthlyForecast__c IN :relatedMonthlyTargetsSet OR Capacity__c IN :relatedCapacityIdSet) AND RecordTypeId =: weeklyTargetRT];
        }

        Map<Id, Decimal> monthlyForecastIdToTargetAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToBudgetMap = new Map<Id, Decimal>();
        for(Revenue_Forecast__c rf : weeklyTargetsList){
            
            //Set Map for Monthly Target Id to total Monthly Target Amount
            if(monthlyForecastIdToTargetAmountMap.containsKey(rf.RelatedMonthlyForecast__c)){
                Decimal monthlyTargetAmount = rf.WeeklyTarget__c == null ? monthlyForecastIdToTargetAmountMap.get(rf.RelatedMonthlyForecast__c) : rf.WeeklyTarget__c + monthlyForecastIdToTargetAmountMap.get(rf.RelatedMonthlyForecast__c);
                monthlyForecastIdToTargetAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyTargetAmount);
            }else{
                Decimal monthlyTargetAmount = rf.WeeklyTarget__c == null ? 0 : rf.WeeklyTarget__c;
                monthlyForecastIdToTargetAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyTargetAmount);
            }

            //Set Map for Capacity Id to Total Capacity Budget Amount Added 9.8.22 ST
            if(capacityIdToBudgetMap.containsKey(rf.Capacity__c)){
                Decimal capacityBudgetAmount = rf.WeeklyTarget__c == null ? capacityIdToBudgetMap.get(rf.Capacity__c) : rf.WeeklyTarget__c + capacityIdToBudgetMap.get(rf.Capacity__c);
                capacityIdToBudgetMap.put(rf.Capacity__c, capacityBudgetAmount);
            }else{
                Decimal capacityBudgetAmount = rf.WeeklyTarget__c == null ? 0 : rf.WeeklyTarget__c;
                capacityIdToBudgetMap.put(rf.Capacity__c, capacityBudgetAmount);
            }

        }

        //Get Related Monthly Targets to Update
        List<Revenue_Forecast__c> relatedMonthlyTargets = new List<Revenue_Forecast__c>();
        relatedMonthlyTargets = [SELECT Id, MonthlyTarget__c
                                FROM Revenue_Forecast__c
                                WHERE Id IN :monthlyForecastIdToTargetAmountMap.keySet()];

        List<Revenue_Forecast__c> revForecastsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : relatedMonthlyTargets){
            if(monthlyForecastIdToTargetAmountMap.containsKey(rf.Id)){
                Decimal newMonthlyTargetSum = monthlyForecastIdToTargetAmountMap.get(rf.Id);
                if(rf.MonthlyTarget__c != newMonthlyTargetSum){
                    rf.MonthlyTarget__c = monthlyForecastIdToTargetAmountMap.get(rf.Id);
                    revForecastsToUpdate.add(rf);
                }
            }
        }

        //Get Related Capacity Records to Update
        /** Potentially don't need to query, can just create Capacity record with Id that is in Map and then update those without checking if they need a change, 
         * since we can assume that if the Weekly Target Changes then its safe to say the Capacity Budget will change as well
         * Can do the same with Monthly Target as well, but due to recursion on the Monthly Targets Target Update it is still advisable to keep that check there
         **/
        List<Capacity__c> relatedCapacityList = new List<Capacity__c>();
        relatedCapacityList = [SELECT Id, Budget__c
                                FROM Capacity__c
                                WHERE Id IN :capacityIdToBudgetMap.keySet()];

        List<Capacity__c> capacityRecordsToUpdate = new List<Capacity__c>();
        for(Capacity__c cap : relatedCapacityList){
            if(relatedCapacityIdSet.contains(cap.Id)){

                if(capacityIdToBudgetMap.containsKey(cap.Id)){
                    Decimal newCapacityBudget = capacityIdToBudgetMap.get(cap.Id);
                    if(cap.Budget__c != newCapacityBudget){
                        cap.Budget__c = capacityIdToBudgetMap.get(cap.Id);
                        capacityRecordsToUpdate.add(cap);
                    }
                }
            }
        }

        //Update Monthly Targets
        if(revForecastsToUpdate.size() > 0){
            update revForecastsToUpdate;
        }

        //Update Capacity Budgets
        if(capacityRecordsToUpdate.size() > 0){
            update capacityRecordsToUpdate;
        }

    }

    public static void weeklyActualsChanged(List<Revenue_Forecast__c> updatedWeeklyActualsList){
        //Get the parent Monthly Target of the Weekly Target that had it's Actuals changed and sum up all the child records of the parent record and update that
        System.debug('*******************************weeklyActualsChanged');

        Set<Id> relatedMonthlyTargetsSet = new Set<Id>();
        Set<id> relatedCapacityIdSet = new Set<Id>();
        for(Revenue_Forecast__c weeklyTarget : updatedWeeklyActualsList){
            if(weeklyTarget.RelatedMonthlyForecast__c != null){
                relatedMonthlyTargetsSet.add(weeklyTarget.RelatedMonthlyForecast__c);
            }

            if(weeklyTarget.Capacity__c != null){
                relatedCapacityIdSet.add(weeklyTarget.Capacity__c);
            }
        }

        List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();
        if(relatedMonthlyTargetsSet.size() > 0){
            weeklyTargetsList = [SELECT WeeklyActuals__c, RelatedMonthlyForecast__c, Capacity__c
                                FROM Revenue_Forecast__c
                                WHERE (RelatedMonthlyForecast__c IN :relatedMonthlyTargetsSet OR Capacity__c IN :relatedCapacityIdSet) AND RecordTypeId =: weeklyTargetRT];
        }

        Map<Id, Decimal> monthlyForecastIdToActualAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToActualsMap = new Map<Id, Decimal>();
        for(Revenue_Forecast__c rf : weeklyTargetsList){


            if(relatedMonthlyTargetsSet.contains(rf.RelatedMonthlyForecast__c)){ //Only add to map if we want to rollup for the Monthly Target for this Weekly Target in this loop
                //Set Map for Monthly Target Id to total Monthly Actuals Amount
                if(monthlyForecastIdToActualAmountMap.containsKey(rf.RelatedMonthlyForecast__c)){
                    Decimal monthlyTargetAmount = rf.WeeklyActuals__c == null ? monthlyForecastIdToActualAmountMap.get(rf.RelatedMonthlyForecast__c) : rf.WeeklyActuals__c + monthlyForecastIdToActualAmountMap.get(rf.RelatedMonthlyForecast__c);
                    monthlyForecastIdToActualAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyTargetAmount);
                }else{
                    Decimal monthlyTargetAmount = rf.WeeklyActuals__c == null ? 0 : rf.WeeklyActuals__c;
                    monthlyForecastIdToActualAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyTargetAmount);
                }
            }

            if(relatedCapacityIdSet.contains(rf.Capacity__c)){ //Only add to map if we want to rollup for the capacity for this Weekly Target in this loop
                //Set Map for Capacity Id to Total Capacity Actuals Amount Added 9.8.22 ST
                if(capacityIdToActualsMap.containsKey(rf.Capacity__c)){
                    Decimal capacityActualsAmount = rf.WeeklyActuals__c == null ? capacityIdToActualsMap.get(rf.Capacity__c) : rf.WeeklyActuals__c + capacityIdToActualsMap.get(rf.Capacity__c);
                    capacityIdToActualsMap.put(rf.Capacity__c, capacityActualsAmount);
                }else{
                    Decimal capacityActualsAmount = rf.WeeklyActuals__c == null ? 0 : rf.WeeklyActuals__c;
                    capacityIdToActualsMap.put(rf.Capacity__c, capacityActualsAmount);
                }
            }
        }

        //Get Related Monthly Targets to Update
        List<Revenue_Forecast__c> relatedMonthlyTargets = new List<Revenue_Forecast__c>();
        relatedMonthlyTargets = [SELECT Id, MonthlyActuals__c
                                FROM Revenue_Forecast__c
                                WHERE Id IN :monthlyForecastIdToActualAmountMap.keySet()];

        List<Revenue_Forecast__c> monthlyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : relatedMonthlyTargets){
            if(monthlyForecastIdToActualAmountMap.containsKey(rf.Id)){
                Decimal newMonthlyActualsSum = monthlyForecastIdToActualAmountMap.get(rf.Id);
                if(rf.MonthlyActuals__c != newMonthlyActualsSum){
                    rf.MonthlyActuals__c = newMonthlyActualsSum;
                    monthlyTargetsToUpdate.add(rf);
                }
            }
        }

        //Get Related Capacity Records to Update
        List<Capacity__c> relatedCapacityRecordsList = new List<Capacity__c>();
        relatedCapacityRecordsList = [SELECT Id, Actuals__c
                                        FROM Capacity__c
                                        WHERE Id IN :capacityIdToActualsMap.keySet()];

        List<Capacity__c> capacityRecordsToUpdate = new List<Capacity__c>();
        for(Capacity__c cap : relatedCapacityRecordsList){
            
            if(relatedCapacityIdSet.contains(cap.Id)){

                if(capacityIdToActualsMap.containsKey(cap.Id)){
                    Decimal newCapacityActuals = capacityIdToActualsMap.get(cap.Id);
                    if(cap.Actuals__c != newCapacityActuals){
                        cap.Actuals__c = newCapacityActuals;
                        capacityRecordsToUpdate.add(cap);
                    }
                }
            }
        }
        //Update Monthly Targets
        if(monthlyTargetsToUpdate.size() > 0){
            update monthlyTargetsToUpdate;
        }
        //Update Capacity Records
        if(capacityRecordsToUpdate.size() > 0){
            update capacityRecordsToUpdate;
        }
    }

    public static void weeklyForecastsChanged(List<Revenue_Forecast__c> updatedWeeklyForecastsList){
        //Get the parent Monthly Target of the Weekly Target that had it's Forecast Amount changed and sum up all the child records of the parent record and update
        System.debug('*******************************weeklyForecastsChanged');

        Set<Id> relatedMonthlyTargetsSet = new Set<Id>();
        Set<Id> relatedCapacityIdSet = new Set<Id>();
        for(Revenue_Forecast__c weeklyTarget : updatedWeeklyForecastsList){
            if(weeklyTarget.RelatedMonthlyForecast__c != null){
                relatedMonthlyTargetsSet.add(weeklyTarget.RelatedMonthlyForecast__c);
            }

            if(weeklyTarget.Capacity__c != null){
                relatedCapacityIdSet.add(weeklyTarget.Capacity__c);
            }
        }

        List<Revenue_Forecast__c> weeklyTargetsList = new List<Revenue_Forecast__c>();
        if(relatedMonthlyTargetsSet.size() > 0){
            weeklyTargetsList = [SELECT WeeklyForecast__c, RelatedMonthlyForecast__c, Capacity__c
                                    FROM Revenue_Forecast__c
                                    WHERE (RelatedMonthlyForecast__c IN :relatedMonthlyTargetsSet OR Capacity__c IN :relatedCapacityIdSet) AND RecordTypeId =: weeklyTargetRT];
        }

        Map<Id, Decimal> monthlyForecastIdToForecastAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> capacityIdToForecastAmountMap = new Map<Id, Decimal>();
        for(Revenue_Forecast__c rf : weeklyTargetsList){

            //Set Map for Monthly Target Id to total Monthly Forecast Amount
            if(monthlyForecastIdToForecastAmountMap.containsKey(rf.RelatedMonthlyForecast__c)){
                Decimal monthlyForecastAmount = rf.WeeklyForecast__c == null ? monthlyForecastIdToForecastAmountMap.get(rf.RelatedMonthlyForecast__c) : rf.WeeklyForecast__c + monthlyForecastIdToForecastAmountMap.get(rf.RelatedMonthlyForecast__c);
                monthlyForecastIdToForecastAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyForecastAmount);
            }else{
                Decimal monthlyForecastAmount = rf.WeeklyForecast__c == null ? 0 : rf.WeeklyForecast__c;
                monthlyForecastIdToForecastAmountMap.put(rf.RelatedMonthlyForecast__c, monthlyForecastAmount);
            }

            //Set Map for Capacity Id to Total Capacity Budget Amount Added 9.8.22 ST
            if(capacityIdToForecastAmountMap.containsKey(rf.Capacity__c)){
                Decimal capacityForecastAmount = rf.WeeklyForecast__c == null ? capacityIdToForecastAmountMap.get(rf.Capacity__c) : rf.WeeklyForecast__c + capacityIdToForecastAmountMap.get(rf.Capacity__c);
                capacityIdToForecastAmountMap.put(rf.Capacity__c, capacityForecastAmount);
            }else{
                Decimal capacityForecastAmount = rf.WeeklyForecast__c == null ? 0 : rf.WeeklyForecast__c;
                capacityIdToForecastAmountMap.put(rf.Capacity__c, capacityForecastAmount);
            }
        }

        //Get Related Monthly Targets to Update
        List<Revenue_Forecast__c> relatedMonthlyTargets = new List<Revenue_Forecast__c>();
        relatedMonthlyTargets = [SELECT Id, MonthlyForecast__c
                                FROM Revenue_Forecast__c
                                WHERE Id IN :monthlyForecastIdToForecastAmountMap.keySet()];

        List<Revenue_Forecast__c> monthlyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : relatedMonthlyTargets){
            if(monthlyForecastIdToForecastAmountMap.containsKey(rf.Id)){
                if(rf.MonthlyForecast__c != monthlyForecastIdToForecastAmountMap.get(rf.Id)){ //Added 9.8.22 ST
                    rf.MonthlyForecast__c = monthlyForecastIdToForecastAmountMap.get(rf.Id);
                    monthlyTargetsToUpdate.add(rf);
                }
            }
        }

        //Get Related Capacity Records to Update
        List<Capacity__c> relatedCapacityRecordsList = new List<Capacity__c>();
        relatedCapacityRecordsList = [SELECT Id, Forecast__c
                                        FROM Capacity__c
                                        WHERE Id IN :capacityIdToForecastAmountMap.keySet()];

        List<Capacity__c> capacityRecordsToUpdate = new List<Capacity__c>();
        for(Capacity__c cap : relatedCapacityRecordsList){
            if(relatedCapacityIdSet.contains(cap.Id)){

                if(capacityIdToForecastAmountMap.containsKey(cap.Id)){
                    if(cap.Forecast__c != capacityIdToForecastAmountMap.get(cap.Id)){ //Added 9.8.22 ST
                        cap.Forecast__c = capacityIdToForecastAmountMap.get(cap.Id);
                        capacityRecordsToUpdate.add(cap);
                    }
                }
            }
        }

        //Update Monthly Targets Forecast Amount
        if(monthlyTargetsToUpdate.size() > 0){
            update monthlyTargetsToUpdate;
        }

        //Update Capacity Forecast Amount
        if(capacityRecordsToUpdate.size() > 0){
            update capacityRecordsToUpdate;
        }
    }

    public static void weeklyBookingsChanged(List<Revenue_Forecast__c> updatedWeeklyBookingsList){
        //Get the parent Monthly Target of the Weekly Target that had it's Bookings Amount changed and sum up all the child records of the parent record and update
        System.debug('*******************************weeklyBookingsChanged');

        Set<Id> relatedMonthlyTargetsSet = new Set<Id>();
        for(Revenue_Forecast__c weeklyTarget : updatedWeeklyBookingsList){
            if(weeklyTarget.RelatedMonthlyForecast__c != null){
                relatedMonthlyTargetsSet.add(weeklyTarget.RelatedMonthlyForecast__c);
            }
        }

        AggregateResult[] monthlyBookingsSum;
        if(relatedMonthlyTargetsSet.size() > 0){
            monthlyBookingsSum = [SELECT sum(Bookings__c), RelatedMonthlyForecast__c
                                FROM Revenue_Forecast__c
                                WHERE RelatedMonthlyForecast__c IN :relatedMonthlyTargetsSet AND RecordTypeId =: weeklyTargetRT
                                GROUP BY RelatedMonthlyForecast__c];
        }

        Map<Id, Decimal> monthlyForecastIdToBookingsAmountMap = new Map<Id, Decimal>();
        for(AggregateResult ar : monthlyBookingsSum){
            monthlyForecastIdToBookingsAmountMap.put((Id)ar.get('RelatedMonthlyForecast__c'), (Decimal)ar.get('expr0'));
        }

        List<Revenue_Forecast__c> relatedMonthlyTargets = new List<Revenue_Forecast__c>();
        relatedMonthlyTargets = [SELECT Id, Bookings__c
                                FROM Revenue_Forecast__c
                                WHERE Id IN :monthlyForecastIdToBookingsAmountMap.keySet()];

        List<Revenue_Forecast__c> monthlyTargetsToUpdate = new List<Revenue_Forecast__c>();
        for(Revenue_Forecast__c rf : relatedMonthlyTargets){
            if(monthlyForecastIdToBookingsAmountMap.containsKey(rf.Id)){
                rf.Bookings__c = monthlyForecastIdToBookingsAmountMap.get(rf.Id);
                monthlyTargetsToUpdate.add(rf);
            }
        }

        if(monthlyTargetsToUpdate.size() > 0){
            update monthlyTargetsToUpdate;
        }
    }

    //Create the Weekly Capacity Records from Monthly Revenue Forecast Records
    public static Map<Date, Capacity__c> createWeeklyCapacityRecordsFromMonthlyTarget(List<Revenue_Forecast__c> newMonthlyTargetList){

        List<Capacity__c> capacityRecordsToCreateList = new List<Capacity__c>();
        List<Date> capacityStartDatesToInsertList = new List<Date>();

        Map<Date, Capacity__c> weekStartDateToCapacityToInsertMap = new Map<Date, Capacity__c>(); 
        Map<Date, Capacity__c> weekStartDateToCapacityToReturnMap = new Map<Date, Capacity__c>(); 

        for(Revenue_Forecast__c rf : newMonthlyTargetList){

            Capacity__c firstWeeklyCapacityRecordForMonth = new Capacity__c();
            firstWeeklyCapacityRecordForMonth.WeekStartDate__c = (rf.MonthStartDate__c).toStartOfWeek(); 
            firstWeeklyCapacityRecordForMonth.WeekEndDate__c = (rf.MonthStartDate__c).toStartOfWeek().addDays(6);
            firstWeeklyCapacityRecordForMonth.Name = 'Capacity for Week: ' + firstWeeklyCapacityRecordForMonth.WeekStartDate__c.format() + ' - ' + firstWeeklyCapacityRecordForMonth.WeekEndDate__c.format();

            weekStartDateToCapacityToInsertMap.put(firstWeeklyCapacityRecordForMonth.WeekStartDate__c, firstWeeklyCapacityRecordForMonth);

            Date capacityStartDate = (rf.MonthStartDate__c).toStartOfWeek();

            //While the next Sunday is still in the same month as the Monthly Target then add the next Sunday's Capacity Record to the insert Map
            while(capacityStartDate.addDays(7).month() ==  (rf.MonthStartDate__c).month()){
                capacityStartDate = capacityStartDate.addDays(7); //Add 7 days to set it for the new record and have it check in the while loop if it can use the next week as well for this Month's Revenue Target
                
                Capacity__c newCapacityRecord = new Capacity__c();
                newCapacityRecord.WeekStartDate__c = capacityStartDate; 
                newCapacityRecord.WeekEndDate__c = capacityStartDate.addDays(6);
                newCapacityRecord.Name = 'Capacity for Week: ' + newCapacityRecord.WeekStartDate__c.format() + ' - ' + newCapacityRecord.WeekEndDate__c.format();

                weekStartDateToCapacityToInsertMap.put(newCapacityRecord.WeekStartDate__c , newCapacityRecord);
            }
        }

        weekStartDateToCapacityToReturnMap.putAll(weekStartDateToCapacityToInsertMap);

        if(weekStartDateToCapacityToInsertMap.size() > 0){

            List<Capacity__c> existingCapacityRecords = new List<Capacity__c>();
            existingCapacityRecords = [SELECT Id, WeekStartDate__c, WeekEndDate__c, Budget__c
                                        FROM Capacity__c
                                        WHERE WeekStartDate__c IN :weekStartDateToCapacityToInsertMap.keySet()];

            for(Capacity__c existingCapacity : existingCapacityRecords){
                if(weekStartDateToCapacityToInsertMap.containsKey(existingCapacity.WeekStartDate__c)){
                    //If the Capacity Week already exists then remove it from the Map to avoid from creating duplicates
                    weekStartDateToCapacityToInsertMap.remove(existingCapacity.WeekStartDate__c);
                    weekStartDateToCapacityToReturnMap.put(existingCapacity.WeekStartDate__c, existingCapacity);
                }
            }

            if(weekStartDateToCapacityToInsertMap.size() > 0){
                insert weekStartDateToCapacityToInsertMap.values();
            }
        }

        return weekStartDateToCapacityToReturnMap;
    }

    /******************************************************************************** Private Functions ********************************************************************************/

    private static Decimal getWeeklyTargetValueFromMonthTarget(Date weekStart, Decimal monthTarget){
        
        //Get Beginning and End Date of Month
        Date firstDayOfMonthDate = weekStart.ToStartOfMonth();
        Integer daysInMonth = date.daysInMonth(weekStart.year(), weekStart.month());
        Date firstDayOfNextMonth = firstDayOfMonthDate.addDays(daysInMonth);

        Integer businessDaysInMonth = getBusinessDaysBetweenTwoDates(firstDayOfMonthDate, firstDayOfNextMonth, true); //Get count of business days within the month

        Decimal monthlyTargetPerDay = monthTarget / businessDaysInMonth; //Divide the Monthly Target by that amount
        Integer businessDaysInWeek = getBusinessDaysBetweenTwoDates(weekStart, weekStart.toStartofWeek().addDays(6), true); //Get Business Days in the Week by getting week start date then get that weeks End of Week (aka Saturday by getting start of week, Sunday, then add 6 days to get to Saturday)        
        Decimal weeklyTarget = monthlyTargetPerDay * businessDaysInWeek; //Multiply the monthly Per Day value by the business days amount

        return weeklyTarget;
    }

    public static Integer getBusinessDaysBetweenTwoDates(Date startDate, Date endDate, Boolean checkForSameMonth){

        List<Holiday> holidays =[SELECT StartTimeInMinutes, Name, ActivityDate FROM Holiday];

        Integer allDaysBetween = startDate.daysBetween(endDate);
        Integer allWorkingDays = 0;
        for(Integer k = 0; k < allDaysBetween; k++ ){
            if(checkifItisWorkingDay(startDate.addDays(k),holidays)){
                if(checkForSameMonth){ //Marked true if you only want business days within same month as the start date
                    if(startDate.month() == startDate.addDays(k).month()){ //Added to ensure it only checks the working days of days in the same month as the startDate
                        allWorkingDays++;
                    }
                }else{
                    allWorkingDays++;
                }
            } 
        }
        return allWorkingDays;
    }

    private static boolean checkifItisWorkingDay(Date currentDate,List<Holiday> holidays){
        Date weekStart  = currentDate.toStartofWeek();
        for(Holiday hDay:holidays){
            if(currentDate.daysBetween(hDay.ActivityDate) == 0){
                return false;
            }
        }
        if(weekStart.daysBetween(currentDate) == 0 || weekStart.daysBetween(currentDate) == 6){
            return false;
        }else{
            return true;
        }
    }

    private static String getMonthNameFromNumber(Integer monthNumber){
        String monthName;
        switch on monthNumber{
            when 1{
                monthName = 'January';
            }
            when 2{
                monthName = 'February';
            }
            when 3{
                monthName = 'March';
            }
            when 4{
                monthName = 'April';
            }
            when 5{
                monthName = 'May';
            }
            when 6{
                monthName = 'June';
            }
            when 7{
                monthName = 'July';
            }
            when 8{
                monthName = 'August';
            }
            when 9{
                monthName = 'September';
            }
            when 10{
                monthName = 'October';
            }
            when 11{
                monthName = 'November';
            }
            when 12{
                monthName = 'December';
            }
          }

        return monthName;
    }
}