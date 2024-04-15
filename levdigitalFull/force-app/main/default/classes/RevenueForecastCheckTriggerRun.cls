public class RevenueForecastCheckTriggerRun {
    private static boolean runWeeklyTargetChanged = true;
    private static boolean runMonthlyTargetChanged = true;

    public static Boolean runWeeklyTargetChangedOnce() {
        if(runWeeklyTargetChanged){
            runWeeklyTargetChanged = false;
            return true;
        }else{
            return runWeeklyTargetChanged;
        }
    }
    public static Boolean runMonthlyTargetChangedOnce() {
        if(runMonthlyTargetChanged){
            runMonthlyTargetChanged = false;
            return true;
        }else{
            return runMonthlyTargetChanged;
        }
    }
}