public class QuotationTriggerHandler {
    public static void handleBeforeInsert(
        List<Quotation__c> newQuoteList
    ) {
        Set<Id> oppIds = new Set<Id>();
        for (Quotation__c quote : newQuoteList) {
            if (quote.Opportunity__c != null) {
               oppIds.add(quote.Opportunity__c);
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }
        Map<Id, Opportunity_Custom__c> oppMap =
            new Map<Id, Opportunity_Custom__c>([
                SELECT Id,
                       Freight_Charges__c
                FROM Opportunity_Custom__c
                WHERE Id IN :oppIds
            ]);
        for (Quotation__c quote : newQuoteList) {
            Opportunity_Custom__c opp =
                oppMap.get(quote.Opportunity__c);
            if (opp != null) {
                // Existing Functionality
                quote.Shipping_and_Handling__c =
                   opp.Freight_Charges__c;
            }
        }
    }
    public static void handleAfterInsert(
        List<Quotation__c> newQuoteList
    ) {
        Set<Id> oppIds = new Set<Id>();
        for (Quotation__c quote : newQuoteList) {
            if (quote.Opportunity__c != null) {
                oppIds.add(quote.Opportunity__c);
            }
        }
        Map<Id, Opportunity_Custom__c> oppMap =
            new Map<Id, Opportunity_Custom__c>([
                SELECT Id,
                       Account_Name__r.Name
                FROM Opportunity_Custom__c
                WHERE Id IN :oppIds
            ]);
        List<Quotation__c> updateQuotes =
            new List<Quotation__c>();
        for (Quotation__c quote : newQuoteList) {
            Opportunity_Custom__c opp =
                oppMap.get(quote.Opportunity__c);
            if (
                opp != null &&
                opp.Account_Name__r != null
            ) {
                updateQuotes.add(
                    new Quotation__c(
                        Id = quote.Id,
                        Name =
                            quote.Quote_Number__c +
                            ' - ' +
                            opp.Account_Name__r.Name
                    )
                );
            }
        }
        if (!updateQuotes.isEmpty()) {
            update updateQuotes;
        }
    }
}