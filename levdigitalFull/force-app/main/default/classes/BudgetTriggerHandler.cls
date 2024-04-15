public class BudgetTriggerHandler {
    public static boolean isUpdate = false;
    public static Map<ID,Schema.RecordTypeInfo> oppRecordTypes = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();

    public static void updateRepliconForecast(List<Budget__c> budgets) {
        try {
            Map<ID,Schema.RecordTypeInfo> rt_Map = Budget__c.sObjectType.getDescribe().getRecordTypeInfosById();
            List<Budget__c> weeklyBudgets = new List<Budget__c>();
            List<Budget__c> quarterlyBudgets = new List<Budget__c>();
            List<Budget__c> monthlyBudgets = new List<Budget__c>();
            for(Budget__c bdg : budgets) {
                if(rt_map.get(bdg.recordTypeID).getName().containsIgnoreCase('Weekly Budget')) {
                    weeklyBudgets.add(bdg);
                } else if(rt_map.get(bdg.recordTypeID).getName().containsIgnoreCase('Monthly Budget')) {
                    monthlyBudgets.add(bdg);
                } else {
                    quarterlyBudgets.add(bdg);
                }
            }

            if(weeklyBudgets.size() > 0) {
                processWeeks(weeklyBudgets);
            }

            if(quarterlyBudgets.size() > 0) {
                processQuarters(quarterlyBudgets);
            }

            if(monthlyBudgets.size() > 0) {
                processMonths(monthlyBudgets);
            }
        } catch(Exception ex) {
            system.debug(ex.getStackTraceString() + ' ' + ex.getMessage());
        }
    }

    private static void processWeeks(List<Budget__c> budgets) {
        // Get only the forecasts we need to process by week start date
        Set<Date> dates = new Set<Date>();
        Map<Date, Budget__c> matchedBudgetWeekDates = new Map<Date, Budget__c>();
        for(Budget__c bdg : budgets) {
            if(bdg != null) {
                if(isUpdate) {
                    resetBudgetValues(bdg);
                }
                dates.add(bdg.Week_Start_Date__c);
                matchedBudgetWeekDates.put(bdg.Week_Start_Date__c, bdg);
            }
        }

        if(matchedBudgetWeekDates.isEmpty()) {
            return;
        }
        Datetime startWeek = system.today().toStartofWeek();
        Datetime endWeek = system.today().toStartofWeek() + 7;
        Datetime previousWeek = system.today().toStartofWeek() - 7;

        for(RepliconForecast__c frc : [Select id, Actual_Revenue__c, EstimatedRevenue__c, Week_Start_Date__c, Week_End_Date__c from RepliconForecast__c where Week_Start_Date__c in : dates]) {
            if(frc.Actual_Revenue__c == null) {frc.Actual_Revenue__c = 0;}
            if(matchedBudgetWeekDates.get(frc.Week_Start_Date__c) != null) {
                matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c += frc.EstimatedRevenue__c;
                if(matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c == null) {matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = 0;}

                // Check current week
                if(frc.Week_Start_Date__c > previousWeek && frc.Week_End_Date__c <= endWeek) {

                    // For current Week
                    if(system.today() >= frc.Week_Start_Date__c && system.today() <= frc.Week_End_Date__c) {
                        matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                        //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                    } else if(frc.Week_Start_Date__c < system.today()) {
                        matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c += frc.Actual_Revenue__c;
                        //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecasted_Revenue__c;
                    } else if(frc.Week_Start_Date__c > system.today()) { // Update to Forecasted_Revenue only for weeks here, same for quarter)
                        //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c += frc.EstimatedRevenue__c;
                        //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecasted_Revenue__c;
                        matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                        //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                    }
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                } else if(frc.Week_Start_Date__c > system.today()) {
                    //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c += frc.EstimatedRevenue__c;
                    //matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecasted_Revenue__c;
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecast_LOS__c;
                } else {
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual_Forecast_LOS__c += frc.Actual_Revenue__c;
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Dynamic_Forecasted_Revenue__c = matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Forecasted_Revenue__c;
                }


                if(frc.Actual_Revenue__c != null) {
                    matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Actual__c += frc.Actual_Revenue__c;
                }
                matchedBudgetWeekDates.get(frc.Week_Start_Date__c).Replicon_Forecast__c  = frc.id;
            }
        }
    }

    private static void processMonths(List<Budget__c> budgets) {
        // Get only the forecasts we need to process by month
        Set<Integer> months = new Set<Integer>();
        Map<Integer, Budget__c> matchedBudgetMonths = new Map<Integer, Budget__c>();
        for(Budget__c bdg : budgets) {
            if(bdg != null) {
                if(isUpdate) {
                    resetBudgetValues(bdg);
                }
                Integer m = 0;
                if(bdg.Month__c == 'January') {
                    months.add(1); m = 1;
                }
                if(bdg.Month__c == 'February') {
                    months.add(2); m = 2;
                }
                if(bdg.Month__c == 'March') {
                    months.add(3); m = 3;
                }
                if(bdg.Month__c == 'April') {
                    months.add(4); m = 4;
                }
                if(bdg.Month__c == 'May') {
                    months.add(5); m = 5;
                }
                if(bdg.Month__c == 'June') {
                    months.add(6); m = 6;
                }
                if(bdg.Month__c == 'July') {
                    months.add(7); m = 7;
                }
                if(bdg.Month__c == 'August') {
                    months.add(8); m = 8;
                }
                if(bdg.Month__c == 'September') {
                    months.add(9); m = 9;
                }
                if(bdg.Month__c == 'October') {
                    months.add(10); m = 10;
                }
                if(bdg.Month__c == 'November') {
                    months.add(11); m = 11;
                }
                if(bdg.Month__c == 'December') {
                    months.add(12); m = 12;
                }
                matchedBudgetMonths.put(m, bdg);
            }
        }

        if(matchedBudgetMonths.isEmpty()) {
            return;
        }

        List<RepliconForecast__c> forecastsToProcess = [Select id, Actual_Revenue__c, EstimatedRevenue__c, Week_Start_Date__c from RepliconForecast__c where CALENDAR_MONTH(Week_Start_Date__c) in : months];
        for(RepliconForecast__c frc : forecastsToProcess) {
            if(matchedBudgetMonths.get(frc.Week_Start_Date__c.month()) != null) {
                Integer year = Integer.valueOf(matchedBudgetMonths.get(frc.Week_Start_Date__c.month()).Year__c);
                if(year == frc.Week_Start_Date__c.year()) {
                    if(frc.EstimatedRevenue__c != null) {
                        matchedBudgetMonths.get(frc.Week_Start_Date__c.month()).Forecast_LOS__c += frc.EstimatedRevenue__c;
                    }
                    if(frc.Actual_Revenue__c != null) {
                        matchedBudgetMonths.get(frc.Week_Start_Date__c.month()).Actual__c += frc.Actual_Revenue__c;
                    }
                    if(frc.Actual_Revenue__c != null) {
                        if(frc.Week_Start_Date__c <= system.today()) {
                            matchedBudgetMonths.get(frc.Week_Start_Date__c.month()).Actual_Forecast_LOS__c += frc.Actual_Revenue__c;
                        }
                    }
                    if(frc.EstimatedRevenue__c != null) {
                        if(frc.Week_Start_Date__c >= system.today()) {
                            matchedBudgetMonths.get(frc.Week_Start_Date__c.month()).Actual_Forecast_LOS__c += frc.EstimatedRevenue__c;
                        }
                    }
                }
            }
        }
    }

    private static void processQuarters(List<Budget__c> budgets) {
        // Get only the forecasts we need to process by quarter
        Set<Integer> quarters = new Set<Integer>();
        Map<Integer, Budget__c> matchedBudgetQuarters = new Map<Integer, Budget__c>();
        Map<Id, Project__c> currentProjectsProcessed = new Map<Id, Project__c>();

        for(Budget__c bdg : budgets) {
            if(bdg != null) {
                if(isUpdate) {
                    resetBudgetValues(bdg);
                }
                Integer q = 0;
                if(bdg.Quarter__c == 'Q1') {
                    quarters.add(1); q = 1;
                }
                else if(bdg.Quarter__c == 'Q2') {
                    quarters.add(2); q = 2;
                }
                else if(bdg.Quarter__c == 'Q3') {
                    quarters.add(3); q = 3;
                }
                else if(bdg.Quarter__c == 'Q4') {
                    quarters.add(4); q = 4;
                }
                matchedBudgetQuarters.put(q, bdg);
            }
        }
        system.debug(matchedBudgetQuarters);

        if(matchedBudgetQuarters.isEmpty()) {
            return;
        }

        List<RepliconForecast__c> forecastsToProcess = null;
        Date fiscalYearStartDate = null;
        Date fiscalYearEndDate = null;
        Date q1StartDate = null;
        Date q2StartDate = null;
        Date q3StartDate = null;
        Date q4StartDate = null;
        Date q1EndDate = null;
        Date q2EndDate = null;
        Date q3EndDate = null;
        Date q4EndDate = null;
        if(System.Today().year() == 2019) {
            q1StartDate = Date.newInstance(2019, 1, 1);
            q1EndDate = Date.newInstance(2019, 3, 30);

            q2StartDate = Date.newInstance(2019, 3, 31);
            q2EndDate = Date.newInstance(2019, 6, 29);

            q3StartDate = Date.newInstance(2019, 6, 30);
            q3EndDate = Date.newInstance(2019, 9, 28);

            q4StartDate = Date.newInstance(2019, 9, 29);
            q4EndDate = Date.newInstance(2019, 12, 28);

            fiscalYearStartDate = Date.newInstance(2019, 1, 1);
            fiscalYearEndDate = Date.newInstance(2019, 12, 28);
            forecastsToProcess = [Select id, Actual_Revenue__c, EstimatedRevenue__c, Week_Start_Date__c, Week_End_Date__c
            from RepliconForecast__c where Week_Start_Date__c >=: fiscalYearStartDate AND Week_Start_Date__c <=: fiscalYearEndDate];
        } else if(System.Today().year() == 2020) {
            q1StartDate = Date.newInstance(2019, 12, 29);
            q1EndDate = Date.newInstance(2020, 3, 28);

            q2StartDate = Date.newInstance(2020, 3, 29);
            q2EndDate = Date.newInstance(2020, 6, 27);

            q3StartDate = Date.newInstance(2020, 6, 28);
            q3EndDate = Date.newInstance(2020, 9, 26);

            q4StartDate = Date.newInstance(2020, 9, 27);
            q4EndDate = Date.newInstance(2020, 12, 26);

            fiscalYearStartDate = Date.newInstance(2019, 12, 29);
            fiscalYearEndDate = Date.newInstance(2020, 12, 28);
            forecastsToProcess = [Select id, Actual_Revenue__c, EstimatedRevenue__c, Week_Start_Date__c, Week_End_Date__c
            from RepliconForecast__c where Week_Start_Date__c >=: fiscalYearStartDate AND Week_Start_Date__c <=: fiscalYearEndDate];
        }

        List<Opportunity> opps = [Select Id, CloseDate, Quarter_revenue_Earn__c, RecordTypeId, Interested_In__c, StageName
        From Opportunity
        Where Interested_In__c = 'Salesforce' AND
        StageName != 'Closed Won' AND StageName != 'Closed Lost' AND StageName != 'On Hold'];

        for(Budget__c b : matchedBudgetQuarters.values()) {
            b.Quarter_Revenue_Earned__c = 0;
            for(Opportunity opp : opps) {
                Integer year = opp.closedate.year();
                String fiscalQuarter = 'Q1';
                if(opp.closeDate.month() >= 1 && opp.closeDate.month() <= 3) {fiscalQuarter = 'Q1';}
                else if(opp.closeDate.month() >= 4 && opp.closeDate.month() <= 6){fiscalQuarter = 'Q2';}
                else if(opp.closeDate.month() >= 7 && opp.closeDate.month() <= 9){fiscalQuarter = 'Q3';}
                else{fiscalQuarter = 'Q4';}

                if(b.quarter__c == fiscalQuarter && b.Year__c == String.valueOf(year)) {
                    b.Quarter_Revenue_Earned__c += opp.Quarter_revenue_Earn__c;
                }
            }
        }


        Decimal totalActualRevenue = 0;
        Decimal estimatedRevenue = 0;
        Integer currQt = null;
        for(RepliconForecast__c frc : forecastsToProcess) {
            if(frc.Actual_Revenue__c == null) {frc.Actual_Revenue__c = 0;}

            // Current Processed Quarter
            Integer currentQuarter = 0;
            if(frc.Week_Start_Date__c >= q1StartDate  && frc.Week_Start_Date__c <= q1EndDate) {currentQuarter = 1;}
            else if(frc.Week_Start_Date__c >= q2StartDate  && frc.Week_Start_Date__c <= q2EndDate){currentQuarter = 2;}
            else if(frc.Week_Start_Date__c >= q3StartDate  && frc.Week_Start_Date__c <= q3EndDate){currentQuarter = 3;}
            else if(frc.Week_Start_Date__c >= q4StartDate  && frc.Week_Start_Date__c <= q4EndDate){currentQuarter = 4;}

            // Current Quarter
            currQt = 0;
            if(system.today() >= q1StartDate  && system.today() <= q1EndDate) {currQt = 1;}
            else if(system.today() >= q2StartDate  && system.today() <= q2EndDate){currQt = 2;}
            else if(system.today() >= q3StartDate  && system.today() <= q3EndDate){currQt = 3;}
            else if(system.today() >= q4StartDate  && system.today() <= q4EndDate){currQt = 4;}

            if(matchedBudgetQuarters.get(currentQuarter) != null) {
                if(matchedBudgetQuarters.get(currentQuarter).Dynamic_Forecasted_Revenue__c == null) {matchedBudgetQuarters.get(currentQuarter).Dynamic_Forecasted_Revenue__c = 0;}
                Integer year = Integer.valueOf(matchedBudgetQuarters.get(currentQuarter).Year__c);
                //if(year == frc.Week_Start_Date__c.year()) {
                    // Current Quarter
                    if(currQt == currentQuarter) {
                        // Actual from of beginning up to previos week of current week, estimated of current week plus remaining weeks
                        matchedBudgetQuarters.get(currentQuarter).Forecast_LOS__c += frc.EstimatedRevenue__c;
                        if(currQt == currentQuarter && frc.Week_End_Date__c < system.today()) {
                            totalActualRevenue += frc.Actual_Revenue__c;
                        }

                        // FORECASTED VALUES
                        if(frc.EstimatedRevenue__c != null) {
                            if(frc.Week_Start_Date__c < system.today() && frc.Week_End_Date__c < system.today()) {
                                //matchedBudgetQuarters.get(currentQuarter).Actual_Forecast_LOS__c += frc.Actual_Revenue__c;//
                            } else if(frc.Week_End_Date__c > system.today()) {
                                //matchedBudgetQuarters.get(currentQuarter).Actual_Forecast_LOS__c += frc.EstimatedRevenue__c;
                                //matchedBudgetQuarters.get(currentQuarter).Actual_Forecast_LOS__c = matchedBudgetQuarters.get(currentQuarter).Forecasted_Revenue__c;
                            }

                            if(system.today() <= matchedBudgetQuarters.get(currentQuarter).Quarter_End_Date__c && frc.Week_End_Date__c > system.today() && currQt == currentQuarter) {
                                estimatedRevenue += frc.EstimatedRevenue__c;
                            }
                        }
                    } else {
                        matchedBudgetQuarters.get(currentQuarter).Forecast_LOS__c += frc.EstimatedRevenue__c;
                        matchedBudgetQuarters.get(currentQuarter).Dynamic_Forecasted_Revenue__c = matchedBudgetQuarters.get(currentQuarter).Forecasted_Revenue__c;
                        matchedBudgetQuarters.get(currentQuarter).Actual_Forecast_LOS__c  = matchedBudgetQuarters.get(currentQuarter).Forecasted_Revenue__c;
                        // ACTUALS
                        if(frc.Actual_Revenue__c != null) {
                           // matchedBudgetQuarters.get(currentQuarter).Actual_Forecast_LOS__c  += frc.EstimatedRevenue__c;
                        }
                    }
                //}
            }
        }
        if(currQt != null) {
            matchedBudgetQuarters.get(currQt).Dynamic_Forecasted_Revenue__c = 0;
            matchedBudgetQuarters.get(currQt).Dynamic_Forecasted_Revenue__c = totalActualRevenue + estimatedRevenue; // sum of billed actuals logic Actual_LOS_field
            matchedBudgetQuarters.get(currQt).Actual_Forecast_LOS__c = 0;
            matchedBudgetQuarters.get(currQt).Actual_Forecast_LOS__c = totalActualRevenue + estimatedRevenue;
        }
    }

    public static void setUpdateFlag(boolean flag) {
        isUpdate = true;
    }

    public static void resetBudgetValues(Budget__c bdg) {
        bdg.Forecast_LOS__c = 0;
        bdg.Actual__c = 0;
        bdg.Actual_Forecast_LOS__c = 0;
        bdg.Dynamic_Forecasted_Revenue__c = 0;
    }
}