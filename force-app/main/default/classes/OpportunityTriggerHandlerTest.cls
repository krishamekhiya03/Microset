/**
* @File Name : OpportunityTriggerHandlerTest.cls
* @Description : Test class for OpportunityTriggerHandler.handleAfterUpdate.
*                 Organized into POSITIVE scenarios (Freight Charges changed,
*                 related Quotation(s) updated) and NEGATIVE scenarios
*                 (no change, no related quotations, quote already matches).
*                 No System.assert statements are used, per request — results
*                 are written to System.debug for manual verification in logs.
*
*                 NOTE: Opportunity_Custom__c and Quotation__c are custom
*                 objects. Only the fields referenced by the handler
*                 (Freight_Charges__c, Shipping_and_Handling__c,
*                 Opportunity__c) plus a Name are populated here. If your org
*                 has additional required fields or validation rules on
*                 either object, add the necessary field values in
*                 createTestOpportunity()/createTestQuotation() below.
*
* @Author :
* @Last Modified By :
* @Last Modified On : June 18, 2026
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 18, 2026 |   | Initial Version
**/
@isTest
private class OpportunityTriggerHandlerTest {

    //==================================================================
    // TEST DATA HELPERS
    //==================================================================

    private static Opportunity_Custom__c createTestOpportunity(String name, Decimal freightCharges) {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        opp.Name = name;
        opp.Freight_Charges__c = freightCharges;
        return opp;
    }

    private static Quotation__c createTestQuotation(Id opportunityId, Decimal shippingAndHandling) {
        Quotation__c quote = new Quotation__c();
        quote.Name = 'Quote For ' + opportunityId;
        quote.Opportunity__c = opportunityId;
        quote.Shipping_and_Handling__c = shippingAndHandling;
        return quote;
    }

    //==================================================================
    // POSITIVE TEST SCENARIOS
    //==================================================================

    /**
     * Positive: Freight_Charges__c changes on the Opportunity, and the
     * related Quotation's Shipping_and_Handling__c differs from the new
     * value, so the quotation should be updated to match.
     */
    @isTest
    static void testHandleAfterUpdate_Positive_UpdatesQuotationWhenFreightChanges() {
        Opportunity_Custom__c opp = createTestOpportunity('Opp With Freight Change', 100);
        insert opp;

        Quotation__c quote = createTestQuotation(opp.Id, 50);
        insert quote;

        // "Old" version of the record before the update (in-memory copy).
        Opportunity_Custom__c oldOpp = opp.clone(true, true, false, false);
        oldOpp.Freight_Charges__c = 50;
        Map<Id, Opportunity_Custom__c> oldMap = new Map<Id, Opportunity_Custom__c>{
            opp.Id => oldOpp
        };

        // "New" version reflecting the updated Freight_Charges__c value.
        Opportunity_Custom__c newOpp = opp.clone(true, true, false, false);
        newOpp.Id = opp.Id;
        newOpp.Freight_Charges__c = 100;
        List<Opportunity_Custom__c> newOppList = new List<Opportunity_Custom__c>{ newOpp };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newOppList, oldMap);
        Test.stopTest();

        Quotation__c updatedQuote = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('Updated Shipping_and_Handling__c: ' + updatedQuote.Shipping_and_Handling__c);
    }

    /**
     * Positive: bulk scenario — multiple opportunities each with their own
     * quotation, freight changed on all of them, confirms each related
     * quotation is updated independently to its own opportunity's new value.
     */
    @isTest
    static void testHandleAfterUpdate_Positive_BulkUpdatesMultipleQuotations() {
        Opportunity_Custom__c oppOne = createTestOpportunity('Bulk Opp One', 200);
        Opportunity_Custom__c oppTwo = createTestOpportunity('Bulk Opp Two', 300);
        insert new List<Opportunity_Custom__c>{ oppOne, oppTwo };

        Quotation__c quoteOne = createTestQuotation(oppOne.Id, 10);
        Quotation__c quoteTwo = createTestQuotation(oppTwo.Id, 20);
        insert new List<Quotation__c>{ quoteOne, quoteTwo };

        Opportunity_Custom__c oldOppOne = oppOne.clone(true, true, false, false);
        oldOppOne.Freight_Charges__c = 10;
        Opportunity_Custom__c oldOppTwo = oppTwo.clone(true, true, false, false);
        oldOppTwo.Freight_Charges__c = 20;
        Map<Id, Opportunity_Custom__c> oldMap = new Map<Id, Opportunity_Custom__c>{
            oppOne.Id => oldOppOne,
            oppTwo.Id => oldOppTwo
        };

        Opportunity_Custom__c newOppOne = oppOne.clone(true, true, false, false);
        newOppOne.Id = oppOne.Id;
        newOppOne.Freight_Charges__c = 200;
        Opportunity_Custom__c newOppTwo = oppTwo.clone(true, true, false, false);
        newOppTwo.Id = oppTwo.Id;
        newOppTwo.Freight_Charges__c = 300;
        List<Opportunity_Custom__c> newOppList = new List<Opportunity_Custom__c>{ newOppOne, newOppTwo };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newOppList, oldMap);
        Test.stopTest();

        List<Quotation__c> updatedQuotes = [
            SELECT Id, Opportunity__c, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id IN :new List<Id>{ quoteOne.Id, quoteTwo.Id }
        ];
        System.debug('Updated quotes: ' + updatedQuotes);
    }

    //==================================================================
    // NEGATIVE TEST SCENARIOS
    //==================================================================

    /**
     * Negative: Freight_Charges__c is unchanged between old and new versions
     * of the Opportunity. The handler should return early (oppFreightMap
     * stays empty) and no Quotation update should occur.
     */
    @isTest
    static void testHandleAfterUpdate_Negative_NoFreightChange_NoUpdatePerformed() {
        Opportunity_Custom__c opp = createTestOpportunity('Opp No Freight Change', 75);
        insert opp;

        Quotation__c quote = createTestQuotation(opp.Id, 999);
        insert quote;

        Opportunity_Custom__c oldOpp = opp.clone(true, true, false, false);
        oldOpp.Freight_Charges__c = 75;
        Map<Id, Opportunity_Custom__c> oldMap = new Map<Id, Opportunity_Custom__c>{
            opp.Id => oldOpp
        };

        Opportunity_Custom__c newOpp = opp.clone(true, true, false, false);
        newOpp.Id = opp.Id;
        newOpp.Freight_Charges__c = 75; // same as old value
        List<Opportunity_Custom__c> newOppList = new List<Opportunity_Custom__c>{ newOpp };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newOppList, oldMap);
        Test.stopTest();

        Quotation__c untouchedQuote = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        // Expected to remain 999 since the handler should have returned early.
        System.debug('Shipping_and_Handling__c after no-change update: ' + untouchedQuote.Shipping_and_Handling__c);
    }

    /**
     * Negative: Freight_Charges__c changes, but there is no Quotation__c
     * related to the Opportunity. The SOQL query returns an empty list,
     * quotesToUpdate stays empty, and the method completes without error.
     */
    @isTest
    static void testHandleAfterUpdate_Negative_NoRelatedQuotations() {
        Opportunity_Custom__c opp = createTestOpportunity('Opp No Quotations', 150);
        insert opp;
        // Intentionally no Quotation__c inserted for this opportunity.

        Opportunity_Custom__c oldOpp = opp.clone(true, true, false, false);
        oldOpp.Freight_Charges__c = 50;
        Map<Id, Opportunity_Custom__c> oldMap = new Map<Id, Opportunity_Custom__c>{
            opp.Id => oldOpp
        };

        Opportunity_Custom__c newOpp = opp.clone(true, true, false, false);
        newOpp.Id = opp.Id;
        newOpp.Freight_Charges__c = 150;
        List<Opportunity_Custom__c> newOppList = new List<Opportunity_Custom__c>{ newOpp };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newOppList, oldMap);
        Test.stopTest();
        // No exception expected; method should complete normally with no DML.
    }

    /**
     * Negative: Freight_Charges__c changes, and a related Quotation exists,
     * but its Shipping_and_Handling__c already equals the new freight value.
     * This exercises the "skip update" branch — the quote should not be
     * added to quotesToUpdate, and no DML update should occur for it.
     */
    @isTest
    static void testHandleAfterUpdate_Negative_QuoteAlreadyMatchesNewValue() {
        Opportunity_Custom__c opp = createTestOpportunity('Opp Quote Already Matches', 400);
        insert opp;

        // Quote's existing value already equals the new freight value (400).
        Quotation__c quote = createTestQuotation(opp.Id, 400);
        insert quote;

        Opportunity_Custom__c oldOpp = opp.clone(true, true, false, false);
        oldOpp.Freight_Charges__c = 350;
        Map<Id, Opportunity_Custom__c> oldMap = new Map<Id, Opportunity_Custom__c>{
            opp.Id => oldOpp
        };

        Opportunity_Custom__c newOpp = opp.clone(true, true, false, false);
        newOpp.Id = opp.Id;
        newOpp.Freight_Charges__c = 400;
        List<Opportunity_Custom__c> newOppList = new List<Opportunity_Custom__c>{ newOpp };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newOppList, oldMap);
        Test.stopTest();

        Quotation__c reQueriedQuote = [
            SELECT Id, Shipping_and_Handling__c, LastModifiedDate
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        // Expected to remain 400 and not have been re-updated.
        System.debug('Shipping_and_Handling__c (already matched): ' + reQueriedQuote.Shipping_and_Handling__c);
    }
}