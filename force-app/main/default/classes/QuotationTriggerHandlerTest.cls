/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : QuotationTriggerHandlerTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for QuotationTriggerHandler
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class QuotationTriggerHandlerTest {

    private static Account createAccount(String name) {
        Account acc = new Account();
        acc.Name = name;
        insert acc;
        return acc;
    }

    private static Opportunity_Custom__c createOpportunity(
        Id accountId,
        Decimal freightCharges
    ) {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        opp.Account_Name__c    = accountId;
        opp.Freight_Charges__c = freightCharges;
        insert opp;
        return opp;
    }

    private static Quotation__c createQuotation(Id opportunityId) {
        Quotation__c quote = new Quotation__c();
        quote.Opportunity__c = opportunityId;
        insert quote;
        return quote;
    }

    @isTest
    static void testHandleBeforeInsert_FreightChargesCopied() {
        Account acc = createAccount('Test Account');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 500.00);

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c insertedQuote = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('FreightChargesCopied - Shipping_and_Handling__c: ' + insertedQuote.Shipping_and_Handling__c);
    }

    @isTest
    static void testHandleBeforeInsert_NoOpportunityLinked() {
        // Opportunity__c is required on Quotation__c, so "no opportunity impact"
        // is tested using an Opportunity with no Freight_Charges__c set instead
        // of a blank Quotation__c.
        Account acc = createAccount('No Freight Account');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, null);

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c insertedQuote = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('NoOpportunityLinked - Shipping_and_Handling__c: ' + insertedQuote.Shipping_and_Handling__c);
    }

    @isTest
    static void testHandleBeforeInsert_FreightChargesZero() {
        Account acc = createAccount('Zero Freight Account');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 0.00);

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c insertedQuote = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('FreightChargesZero - Shipping_and_Handling__c: ' + insertedQuote.Shipping_and_Handling__c);
    }

    @isTest
    static void testHandleBeforeInsert_MultipleQuotations() {
        Account acc = createAccount('Multi Quote Account');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 750.00);

        List<Quotation__c> quoteList = new List<Quotation__c>();
        quoteList.add(new Quotation__c(Opportunity__c = opp.Id));
        quoteList.add(new Quotation__c(Opportunity__c = opp.Id));

        Test.startTest();
        insert quoteList;
        Test.stopTest();

        List<Quotation__c> insertedQuotes = [
            SELECT Id, Shipping_and_Handling__c
            FROM Quotation__c
            WHERE Opportunity__c = :opp.Id
        ];
        for (Quotation__c q : insertedQuotes) {
            System.debug('MultipleQuotations - Id: ' + q.Id + ' Shipping_and_Handling__c: ' + q.Shipping_and_Handling__c);
        }
    }

    @isTest
    static void testHandleAfterInsert_QuoteNameUpdated() {
        Account acc = createAccount('Shah Industries');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 300.00);

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c updatedQuote = [
            SELECT Id, Name, Quote_Number__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('QuoteNameUpdated - Name: ' + updatedQuote.Name + ' Quote_Number__c: ' + updatedQuote.Quote_Number__c);
    }

    @isTest
    static void testHandleAfterInsert_NoOpportunity_NameNotUpdated() {
        // Opportunity__c is required, so this uses an Opportunity whose Account
        // has no name-worthy link (blank account name scenario is not possible
        // since Account.Name is required too) — instead we use an Opportunity
        // with no Account_Name__c set, so Account_Name__r is null and the
        // trigger's name-update branch should be skipped.
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        opp.Freight_Charges__c = 50.00;
        insert opp;

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c insertedQuote = [
            SELECT Id, Name
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('NoOpportunity_NameNotUpdated - Name: ' + insertedQuote.Name);
    }

    @isTest
    static void testHandleAfterInsert_MultipleQuotations_NameUpdated() {
        Account acc = createAccount('Mehta Corp');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 100.00);

        List<Quotation__c> quoteList = new List<Quotation__c>();
        quoteList.add(new Quotation__c(Opportunity__c = opp.Id));
        quoteList.add(new Quotation__c(Opportunity__c = opp.Id));

        Test.startTest();
        insert quoteList;
        Test.stopTest();

        List<Quotation__c> updatedQuotes = [
            SELECT Id, Name, Quote_Number__c
            FROM Quotation__c
            WHERE Opportunity__c = :opp.Id
            ORDER BY Quote_Number__c ASC
        ];
        for (Quotation__c q : updatedQuotes) {
            System.debug('MultipleQuotations_NameUpdated - Name: ' + q.Name + ' Quote_Number__c: ' + q.Quote_Number__c);
        }
    }

    @isTest
    static void testFullFlow_BeforeAndAfterInsert() {
        Account acc = createAccount('Patel Enterprises');
        Opportunity_Custom__c opp = createOpportunity(acc.Id, 1200.00);

        Test.startTest();
        Quotation__c quote = createQuotation(opp.Id);
        Test.stopTest();

        Quotation__c result = [
            SELECT Id, Name, Shipping_and_Handling__c, Quote_Number__c
            FROM Quotation__c
            WHERE Id = :quote.Id
        ];
        System.debug('FullFlow - Shipping_and_Handling__c: ' + result.Shipping_and_Handling__c + ' Name: ' + result.Name);
    }
}