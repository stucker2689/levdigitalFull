@isTest 
public class LevExceptionHandlerTest {
    
    @isTest 
    static void testExceptionSignature() {
        LevExceptionHandler.SystemException newSystemException = new LevExceptionHandler.SystemException('Test Error Message');
        try {
            LevExceptionHandler.logError(newSystemException, NULL);
            LevExceptionHandler.logError(newSystemException, 'Test', 'Test', NULL);
        }
        catch(Exception e) {
            System.debug(e);
        }
    }
    
    @isTest 
    static void testPrimitiveSignature() {
        try {
            LevExceptionHandler.logError('Test Error Message', 1, 'TestClass', 'TestMethod', NULL);
        }
        catch(Exception e) {
            System.debug(e);
        }
    }
}