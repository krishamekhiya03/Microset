public class OpportunityTriggerHandler {

    public static void handleAfterUpdate(
        List<Opportunity_Custom__c> newOppList,
        Map<Id, Opportunity_Custom__c> oldMap
    ) {

        Map<Id, Decimal> oppFreightMap = new Map<Id, Decimal>();

        for (Opportunity_Custom__c opp : newOppList) {

            Opportunity_Custom__c oldOpp = oldMap.get(opp.Id);

            // Check if Freight Charges changed
            if (opp.Freight_Charges__c != oldOpp.Freight_Charges__c) {

                oppFreightMap.put(
                    opp.Id,
                    opp.Freight_Charges__c
                );
            }
        }

        // No changes found
        if (oppFreightMap.isEmpty()) {
            return;
        }

        // Fetch related quotations
        List<Quotation__c> quoteList = [
            SELECT Id,
                   Opportunity__c,
                   Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Opportunity__c IN :oppFreightMap.keySet()
        ];

        List<Quotation__c> quotesToUpdate = new List<Quotation__c>();

        for (Quotation__c quote : quoteList) {

            Decimal newFreightValue =
                oppFreightMap.get(quote.Opportunity__c);

            // Update only if value changed
            if (quote.Shipping_and_Handling__c != newFreightValue) {

                quote.Shipping_and_Handling__c =
                    newFreightValue;

                quotesToUpdate.add(quote);
            }
        }

        // Update quotations
        if (!quotesToUpdate.isEmpty()) {

            update quotesToUpdate;
        }
    }
}