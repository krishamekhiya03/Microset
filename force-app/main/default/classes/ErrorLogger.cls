public with sharing class ErrorLogger {

    public static void logError(String className, String errorMessage){

        try{
            Error_Log__c err = new Error_Log__c();

            err.Class_Name__c = className;
            err.Error_Message__c = errorMessage;
            err.Error_Date__c = System.now();

            insert err;

        }catch(Exception e){
            System.debug('Error while logging error: ' + e.getMessage());
        }
    }
}