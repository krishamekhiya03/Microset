trigger OpportunityCustomTrigger on Opportunity_Custom__c (after update) {

    if (TriggerRecursionHandler.isOpportunityTriggerRunning) {
        return;
    }

    TriggerRecursionHandler.isOpportunityTriggerRunning = true;

    System.debug(
        'TriggerRecursionHandler.isOpportunityTriggerRunning--' +
        TriggerRecursionHandler.isOpportunityTriggerRunning
    );

    try {

        if (Trigger.isAfter && Trigger.isUpdate) {

            OpportunityTriggerHandler.handleAfterUpdate(
                Trigger.new,
                Trigger.oldMap
            );
        }

    } finally {

        TriggerRecursionHandler.isOpportunityTriggerRunning = false;
    }
}