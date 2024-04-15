public class CheckRecursive {
    private static boolean runbeforeInsert = true;
    private static boolean runafterInsert = true;
    private static boolean runbeforeUpdate = true;
    private static boolean runafterUpdate = true;
    private static boolean runafterUpdate2 = true;
    private static boolean runafterUpdate3 = true;
    private static boolean runCreateProject = true;
    private static boolean runCalculateAccount = true;
    private static boolean runUpdateAcctLowestBudgetRemaining = true;
    private static boolean runUpdateAccountFirstYearBooking = true;
    private static boolean runCountAccountRiskLevel = true;
    private static boolean runLowRateOpptyProductAlert = true;

    public static Boolean runbeforeInsertOnce() {
        if(runbeforeInsert){
            runbeforeInsert = false;
            return true;
        }else{
            return runbeforeInsert;
        }
    }
    public static Boolean runafterInsertOnce() {
        if(runafterInsert){
            runafterInsert = false;
            return true;
        }else{
            return runafterInsert;
        }
    }
    public static Boolean runbeforeUpdateOnce() {
        if(runbeforeUpdate){
            runbeforeUpdate = false;
            return true;
        }else{
            return runbeforeUpdate;
        }
    }
    public static Boolean runafterUpdateOnce() {
        if(runafterUpdate){
            runafterUpdate = false;
            return true;
        }else{
            return runafterUpdate;
        }
    }
    public static Boolean runafterUpdateOnce2() {
        if(runafterUpdate2){
            runafterUpdate2 = false;
            return true;
        }else{
            return runafterUpdate2;
        }
    }
    public static Boolean runafterUpdateOnce3() {
        if(runafterUpdate3){
            runafterUpdate3 = false;
            return true;
        }else{
            return runafterUpdate3;
        }
    }

    //Used in OpportunityAfter Trigger to only run the Create Projects class once
    public static Boolean runCreateProjectsOnce(){ 
        if(runCreateProject){
            runCreateProject = false;
            return true;
        }else{
            return runCreateProject;
        }
    }

    //Used in OpportunityAfter Trigger to only run the AccountCalculations Calculate First Year Bookings class once
    public static Boolean runCalculateAccountOnce(){ 
        if(runCalculateAccount){
            runCalculateAccount = false;
            return true;
        }else{
            return runCalculateAccount;
        }
    }

    //Used in OpportunityTriggerHandler to only run the updateAccountLowestBudgetRemaining function once
    public static Boolean runUpdateAcctLowestBudgetRemainingOnce(){
        if(runUpdateAcctLowestBudgetRemaining){
            runUpdateAcctLowestBudgetRemaining = false;
            return true;
        }else{
            return runUpdateAcctLowestBudgetRemaining;
        }
    } 
    
    //Used in OpportunityTriggerHandler to only run the updateAccountFirstYearBooking function once
    public static Boolean runUpdateAccountFirstYearBookingOnce(){
        if(runUpdateAccountFirstYearBooking){
            runUpdateAccountFirstYearBooking = false;
            return true;
        }else{
            return runUpdateAccountFirstYearBooking;
        }
    } 
    //Used in OpportunityTriggerHandler to only run the updateAccountFirstYearBooking function once
    public static Boolean runCountAccountRiskLevelOnce(){
        if(runCountAccountRiskLevel){
            runCountAccountRiskLevel = false;
            return true;
        }else{
            return runCountAccountRiskLevel;
        }
    }

    public static Boolean runLowRateOpptyProductAlertOnce(){
        if(runLowRateOpptyProductAlert){
            runLowRateOpptyProductAlert = false;
            return true;
        }else{
            return runLowRateOpptyProductAlert;
        }
    } 

}