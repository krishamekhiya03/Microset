@isTest
private class CustomProductFetcherTest {

    @testSetup
    static void setupData() {

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Custom Opportunity
        Opportunity_Custom__c opp = new Opportunity_Custom__c(
            Name = 'Test Opportunity',
            Account_Name__c = acc.Id
        );
        insert opp;

        // Active Product
        Product_custom__c prod = new Product_custom__c(
            Product_Name__c = 'Test Product',
            HSN_Code__c = '1234',
         List_Price__c = 100,
            GST__c = 18,
            Product_Description__c = 'Test Description',
            Active__c = true
        );
        insert prod;

        // Inactive Product (to test filter exclusion)
        Product_custom__c inactiveProd = new Product_custom__c(
            Product_Name__c = 'Inactive Product',
            HSN_Code__c = '5678',
             List_Price__c = 50,
            GST__c = 18,
            Product_Description__c = 'Inactive Description',
            Active__c = false
        );
        insert inactiveProd;

        // Quotation linked to Opportunity
        Quotation__c quote = new Quotation__c(
            Opportunity__c = opp.Id,
            Syncing__c = true
        );
        insert quote;
    }

    // ---------- getCustomPricebookEntries ----------

    @isTest
    static void testGetCustomPricebookEntries() {

        Test.startTest();
        List<Object> result =
            CustomProductFetcher.getCustomPricebookEntries();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result list should not be null');
        System.assertEquals(0, result.size(), 'Method currently returns an empty list');
    }

    // ---------- createCustomLineItems ----------

    @isTest
    static void testCreateCustomLineItems_Success() {

        Opportunity_Custom__c opp = [SELECT Id, CurrencyIsoCode FROM Opportunity_Custom__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();

        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('HSN_Code__c', '1234');
        item.put('LineDescription__c', 'Some description');
        item.put('Quantity__c', 5);
        item.put('List_Price__c', 100);
        item.put('Discount__c', 10);
        item.put('GST__c', 18);

        items.add(item);

        Test.startTest();
        CustomProductFetcher.createCustomLineItems(opp.Id, items);
        Test.stopTest();

        List<Opportunity_Product_Line_Item__c> result = [
            SELECT Id, Productss__c, Quantity__c,
            List_Price__c, 
             Discount__c, GST__c, CurrencyIsoCode
            FROM Opportunity_Product_Line_Item__c
        ];

        System.assertEquals(1, result.size(), 'One OLI should be inserted');
        System.assertEquals(prod.Id, result[0].Productss__c, 'Product reference should match');
        System.assertEquals(5, result[0].Quantity__c, 'Quantity should match input');
        System.assertEquals(100, result[0].List_Price__c, 'List Price should match input');
        System.assertEquals(opp.CurrencyIsoCode, result[0].CurrencyIsoCode,
            'OLI currency should be set from parent Opportunity currency');
    }

    @isTest
    static void testCreateCustomLineItems_NullProductSkipped() {

        Opportunity_Custom__c opp = [SELECT Id FROM Opportunity_Custom__c LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();

        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', null);

        items.add(item);

        Test.startTest();
        CustomProductFetcher.createCustomLineItems(opp.Id, items);
        Test.stopTest();

        List<Opportunity_Product_Line_Item__c> result = [
            SELECT Id FROM Opportunity_Product_Line_Item__c
        ];

        System.assertEquals(0, result.size(), 'No OLI should be inserted when Product__c is null');
    }

    @isTest
    static void testCreateCustomLineItems_MissingOpportunityId() {

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', null);
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createCustomLineItems(null, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Null opportunityId should throw AuraHandledException');
    }

    @isTest
    static void testCreateCustomLineItems_EmptyItems() {

        Opportunity_Custom__c opp = [SELECT Id FROM Opportunity_Custom__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createCustomLineItems(opp.Id, new List<Map<String, Object>>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Empty items list should throw AuraHandledException');
    }

    @isTest
    static void testCreateCustomLineItems_ThrowsOnInvalidProductId() {

        Opportunity_Custom__c opp = [SELECT Id FROM Opportunity_Custom__c LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        // Invalid Id format -> (Id) cast throws inside try block -> hits catch
        item.put('Product__c', 'not-a-valid-id');
        item.put('Quantity__c', 1);
        item.put('List_Price__c', 10);
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            CustomProductFetcher.createCustomLineItems(opp.Id, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
            'Invalid Product Id should be caught in try/catch and rethrown as AuraHandledException');
    }

    @isTest
    static void testCreateCustomLineItems_ThrowsOnInvalidQuantity() {

        Opportunity_Custom__c opp = [SELECT Id FROM Opportunity_Custom__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 'not-a-number'); // Decimal.valueOf throws -> hits catch
         item.put('List_Price__c', 100);
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createCustomLineItems(opp.Id, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
            'Invalid Quantity__c should be caught and rethrown as AuraHandledException');
    }

    // ---------- getCurrentQuotation ----------

    @isTest
    static void testGetCurrentQuotation_Success() {

        Quotation__c quote = [SELECT Id FROM Quotation__c LIMIT 1];

        Test.startTest();
        Quotation__c result =
            CustomProductFetcher.getCurrentQuotation(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(quote.Id, result.Id, 'Returned quotation Id should match');
    }

    @isTest
    static void testGetCurrentQuotation_NullId() {

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.getCurrentQuotation(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Null quotationId should throw AuraHandledException');
    }

    // ---------- getQuoteLineItemLastCreated ----------

    @isTest
    static void testGetQuoteLineItemLastCreated_EmptyInputs() {

        Test.startTest();

        List<Quotation_Line_Item__c> result1 =
            CustomProductFetcher.getQuoteLineItemLastCreated(null, 'someAccountId');

        List<Quotation_Line_Item__c> result2 =
            CustomProductFetcher.getQuoteLineItemLastCreated(new List<String>(), 'someAccountId');

        List<Quotation_Line_Item__c> result3 =
            CustomProductFetcher.getQuoteLineItemLastCreated(new List<String>{'a'}, null);

        Test.stopTest();

        System.assertEquals(0, result1.size(), 'Null lineList should return empty list');
        System.assertEquals(0, result2.size(), 'Empty lineList should return empty list');
        System.assertEquals(0, result3.size(), 'Blank accountId should return empty list');
    }

    @isTest
    static void testGetQuoteLineItemLastCreated_ValidInputs() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Quotation_Line_Item__c> result =
            CustomProductFetcher.getQuoteLineItemLastCreated(
                new List<String>{'someLineId'},
                acc.Id
            );
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Method currently returns an empty list');
    }

    // ---------- createQuotationLineItems ----------

    @isTest
    static void testCreateQuotationLineItems_Success_WithSyncingTrue() {

        Quotation__c quote = [SELECT Id, Syncing__c, Opportunity__c, CurrencyIsoCode FROM Quotation__c LIMIT 1];
        Opportunity_Custom__c opp = [SELECT Id, CurrencyIsoCode FROM Opportunity_Custom__c WHERE Id = :quote.Opportunity__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();

        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 3);
         item.put('List_Price__c', 150);
        item.put('SalesPrice__c', 140);
        item.put('GST__c', 18);
        item.put('LineDescription__c', 'Line item description');

        items.add(item);

        Test.startTest();
        CustomProductFetcher.createQuotationLineItems(quote.Id, items);
        Test.stopTest();

        List<Quotation_Line_Item__c> qliResult = [
            SELECT Id, Productss__c, Quantity__c,
            List_Price__c, 
             Sales_Price__c, GST__c, Line_Description__c, CurrencyIsoCode
            FROM Quotation_Line_Item__c
            WHERE Quotation__c = :quote.Id
        ];

        List<Opportunity_Product_Line_Item__c> oliResult = [
            SELECT Id, Productss__c, CurrencyIsoCode
            FROM Opportunity_Product_Line_Item__c
            WHERE Opportunityss__c = :quote.Opportunity__c
        ];

        System.assertEquals(1, qliResult.size(), 'One QLI should be inserted');
        System.assertEquals(prod.Id, qliResult[0].Productss__c, 'QLI product reference should match');
        System.assertEquals(quote.CurrencyIsoCode, qliResult[0].CurrencyIsoCode,
            'QLI currency should be set from Quotation currency');

        System.assertEquals(1, oliResult.size(), 'One OLI should be created since Syncing__c is true and product did not already exist');
        System.assertEquals(prod.Id, oliResult[0].Productss__c, 'OLI product reference should match');
        System.assertEquals(opp.CurrencyIsoCode, oliResult[0].CurrencyIsoCode,
            'OLI currency should fall back to Opportunity currency when present');
    }

    @isTest
    static void testCreateQuotationLineItems_SkipsOLI_WhenProductAlreadyExists() {

        Quotation__c quote = [SELECT Id, Syncing__c, Opportunity__c FROM Quotation__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        // Pre-insert an OLI for this product so it's treated as "existing"
        Opportunity_Product_Line_Item__c existingOli = new Opportunity_Product_Line_Item__c(
            Opportunityss__c = quote.Opportunity__c,
            Productss__c = prod.Id,
            Quantity__c = 1,
            List_Price__c = 100
        );
        insert existingOli;

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 2);
        item.put('List_Price__c', 120);
        item.put('GST__c', 18);
        item.put('LineDescription__c', 'Already exists case');

        items.add(item);

        Test.startTest();
        CustomProductFetcher.createQuotationLineItems(quote.Id, items);
        Test.stopTest();

        List<Opportunity_Product_Line_Item__c> oliResult = [
            SELECT Id
            FROM Opportunity_Product_Line_Item__c
            WHERE Opportunityss__c = :quote.Opportunity__c
        ];

        List<Quotation_Line_Item__c> qliResult = [
            SELECT Id FROM Quotation_Line_Item__c WHERE Quotation__c = :quote.Id
        ];

        // Only the pre-inserted OLI should exist; no new one created for the same product
        System.assertEquals(1, oliResult.size(), 'No new OLI should be created for a product that already exists on the Opportunity');
        System.assertEquals(1, qliResult.size(), 'QLI should still be inserted regardless of existing OLI');
    }

    @isTest
    static void testCreateQuotationLineItems_SyncingFalse_NoOLI() {

        Opportunity_Custom__c opp = [SELECT Id FROM Opportunity_Custom__c LIMIT 1];

        // Create a separate Quotation with Syncing__c = false at insert time
        // instead of updating the existing one, to avoid the DmlException.
        Quotation__c quoteNoSync = new Quotation__c(
            Opportunity__c = opp.Id,
            Syncing__c = false
        );
        insert quoteNoSync;

        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 1);
         item.put('List_Price__c', 100);
        item.put('GST__c', 18);

        items.add(item);

        Test.startTest();
        CustomProductFetcher.createQuotationLineItems(quoteNoSync.Id, items);
        Test.stopTest();

        List<Opportunity_Product_Line_Item__c> oliResult = [
            SELECT Id
            FROM Opportunity_Product_Line_Item__c
            WHERE Opportunityss__c = :opp.Id
        ];

        System.assertEquals(0, oliResult.size(), 'No OLI should be created when Syncing__c is false');
    }

    @isTest
    static void testCreateQuotationLineItems_MissingRequiredData() {

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createQuotationLineItems(null, new List<Map<String, Object>>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Null quotationId should throw AuraHandledException');
    }

    @isTest
    static void testCreateQuotationLineItems_EmptyItemsList() {

        Quotation__c quote = [SELECT Id FROM Quotation__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createQuotationLineItems(quote.Id, new List<Map<String, Object>>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Empty items list should throw AuraHandledException');
    }

    @isTest
    static void testCreateQuotationLineItems_ThrowsOnInvalidListPrice() {

        Quotation__c quote = [SELECT Id FROM Quotation__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 1);
        // Decimal.valueOf(listprice) runs unconditionally/unguarded -> throws -> hits catch
        item.put('List_Price__c', 'not-a-number');
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createQuotationLineItems(quote.Id, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
            'Invalid List_Price__c should be caught and rethrown as AuraHandledException');
    }

    @isTest
    static void testCreateQuotationLineItems_ThrowsOnInvalidProductId() {

        Quotation__c quote = [SELECT Id FROM Quotation__c LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        // Invalid Id format -> (Id) cast on productId throws -> hits catch
        item.put('Product__c', 'not-a-valid-id');
        item.put('Quantity__c', 1);
        item.put('List_Price__c', 100);
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createQuotationLineItems(quote.Id, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
            'Invalid Product Id should be caught and rethrown as AuraHandledException');
    }

    @isTest
    static void testCreateQuotationLineItems_ThrowsOnInvalidDate() {

        Quotation__c quote = [SELECT Id FROM Quotation__c LIMIT 1];
        Product_custom__c prod = [SELECT Id FROM Product_custom__c WHERE Active__c = true LIMIT 1];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('Product__c', prod.Id);
        item.put('Quantity__c', 1);
         item.put('List_Price__c', 100);
        // Date.valueOf on a malformed string throws -> hits catch
        item.put('Date__c', 'not-a-date');
        items.add(item);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            CustomProductFetcher.createQuotationLineItems(quote.Id, items);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
            'Invalid Date__c should be caught and rethrown as AuraHandledException');
    }

    // ---------- fetchActiveProduct ----------

    @isTest
    static void testFetchActiveProduct() {

        Test.startTest();
        List<Product_custom__c> result =
            CustomProductFetcher.fetchActiveProduct();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only the active product with a List_Price__c should be returned');
        System.assertEquals('Test Product', result[0].Product_Name__c, 'Returned product should be the active one');
    }
}