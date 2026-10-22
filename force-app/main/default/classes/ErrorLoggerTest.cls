@isTest
private class ErrorLoggerTest {

    @isTest
    static void testLogError_Success() {
        Test.startTest();
        ErrorLogger.logError('SomeClassName', 'Some error message occurred');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c, Error_Date__c
            FROM Error_Log__c
        ];
    }

    @isTest
    static void testLogError_NullValues() {
        Test.startTest();
        ErrorLogger.logError(null, null);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c
            FROM Error_Log__c
        ];
    }

    @isTest
    static void testLogError_LongErrorMessage() {
        String longMessage = '';
        for (Integer i = 0; i < 50; i++) {
            longMessage += 'This is a long error message segment. ';
        }

        Test.startTest();
        ErrorLogger.logError('AnotherClass', longMessage);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c
            FROM Error_Log__c
            WHERE Class_Name__c = 'AnotherClass'
        ];
    }

    @isTest
    static void testLogError_MultipleCalls() {
        Test.startTest();
        ErrorLogger.logError('ClassA', 'Error A');
        ErrorLogger.logError('ClassB', 'Error B');
        ErrorLogger.logError('ClassC', 'Error C');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c
            FROM Error_Log__c
            ORDER BY Class_Name__c
        ];
    }

    @isTest
    static void testLogError_EmptyStringValues() {
        Test.startTest();
        ErrorLogger.logError('', '');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c
            FROM Error_Log__c
        ];
    }

    @isTest
    static void testLogError_ExceptionPath() {
        // Class_Name__c is string(255). Passing a value longer than the field
        // limit forces insert to throw a DmlException, which exercises the
        // catch block inside logError().
        String tooLongClassName = 'X'.repeat(300); // 300 characters, exceeds 255 limit

        Test.startTest();
        ErrorLogger.logError(tooLongClassName, 'This call should hit the catch block');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Error_Message__c
            FROM Error_Log__c
        ];
    }
}