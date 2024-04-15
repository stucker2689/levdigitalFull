public class LevExceptionHandler {
    
    public static void logError(Exception e, String relatedID) {
        createError(e.getMessage(), e.getLineNumber(), NULL, NULL, relatedID);
    }
    
    public static void logError(String errorMessage, Integer lineNumber, String className, String methodName, String relatedID) {
        createError(errorMessage, lineNumber, className, methodName, relatedID);
    }
    
    public static void logError(Exception e, String className, String methodName, String relatedID) {
        createError(e.getMessage(), e.getLineNumber(), className, methodName, relatedID);
    }
    
    public static void createError(String errorMessage, Integer lineNumber, String className, String methodName, String relatedID) {
        Error_Log_Lev__c newErrorLog = new Error_Log_Lev__c();
        newErrorLog.Error_Message__c = errorMessage;
        newErrorLog.Line_Number__c = lineNumber;
        newErrorLog.Method_Name__c = methodName;
        newErrorLog.Class_Name__c = className;
        newErrorLog.Related_ID__c = relatedID;
        insert newErrorLog;
        System.debug('*************Unexpected Error*************');
        System.debug(newErrorLog);
    }
    
    
    public class SystemException extends Exception {
    }
}