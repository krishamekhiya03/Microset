global class InboundEmailHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try{

            System.debug('Email From: ' + envelope.fromAddress);
            System.debug('Email Subject: ' + email.subject);
            System.debug('Email Body: ' + email.plainTextBody);

            Error_Log__c log = new Error_Log__c();
            log.Class_Name__c = 'InboundEmailHandler';
            log.Error_Message__c = email.subject + ' | ' + email.plainTextBody;
            log.Error_Date__c = System.now();

            insert log;

            result.success = true;

        }catch(Exception e){

            result.success = false;

            Error_Log__c log = new Error_Log__c();
            log.Class_Name__c = 'InboundEmailHandler';
            log.Error_Message__c = e.getMessage();
            log.Error_Date__c = System.now();

            insert log;
        }

        return result;
    }
}