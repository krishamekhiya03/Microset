trigger QuotationTrigger on Quotation__c (
    before insert,
    after insert
) {

    if (Trigger.isBefore && Trigger.isInsert) {

        QuotationTriggerHandler.handleBeforeInsert(
            Trigger.new
        );
    }

    if (Trigger.isAfter && Trigger.isInsert) {

        QuotationTriggerHandler.handleAfterInsert(
            Trigger.new
        );
    }
}