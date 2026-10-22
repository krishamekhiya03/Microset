public without sharing class CustomProductFetcher {
    
    @AuraEnabled
    // public static List<Price_Book_Entry_custom__c> getCustomPricebookEntries() {
    public static List<Object> getCustomPricebookEntries() {
        
        /*return [
            SELECT Id, List_Price__c, Product__c,  Product__r.Name,Active__c,
            Product__r.Product_Description__c, product__r.Product_Name__c
            FROM Price_Book_Entry_custom__c
            WHERE Active__c = true
        ];*/
        
        return new List<Object>();
    }

 @AuraEnabled
public static void createCustomLineItems(Id opportunityId, List<Map<String, Object>> items) {

    System.debug('opportunityId --> ' + opportunityId);
    System.debug('### ITEMS RECEIVED --> ' + JSON.serialize(items));

    if (opportunityId == null || items == null || items.isEmpty()) {
        throw new AuraHandledException('Missing Opportunity or Product data.');
    }

    try {

        // ★ NEW: Fetch parent Opportunity's CurrencyIsoCode
        String oppCurrencyCode = null;

        Opportunity_Custom__c parentOpp = [
            SELECT Id, CurrencyIsoCode
            FROM Opportunity_Custom__c
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        oppCurrencyCode = parentOpp.CurrencyIsoCode;

        System.debug('### Opportunity CurrencyIsoCode --> ' + oppCurrencyCode);

        List<Opportunity_Product_Line_Item__c> lineItemList = new List<Opportunity_Product_Line_Item__c>();

        for (Map<String, Object> item : items) {

            if (item.containsKey('Product__c') && item.get('Product__c') != null) {

                Opportunity_Product_Line_Item__c lineItem = new Opportunity_Product_Line_Item__c();

                lineItem.Opportunityss__c = opportunityId;
                lineItem.Productss__c = (Id) item.get('Product__c');
                lineItem.Product_Code__c = String.valueOf(item.get('HSN_Code__c'));
                lineItem.Model_Number__c = (String) item.get('ModelNumber');
                lineItem.Line_Description__c = (String) item.get('LineDescription__c');

                lineItem.Quantity__c = item.get('Quantity__c') != null
                    ? Decimal.valueOf(String.valueOf(item.get('Quantity__c')))
                    : null;

                lineItem.List_Price__c = item.get('List_Price__c') != null
                    ? Decimal.valueOf(String.valueOf(item.get('List_Price__c')))
                    : null;

                lineItem.Discount__c = item.get('Discount__c') != null
                    ? Decimal.valueOf(String.valueOf(item.get('Discount__c')))
                    : null;

                lineItem.GST__c =
                    item.get('GST__c') != null
                    ? Decimal.valueOf(
                        String.valueOf(item.get('GST__c'))
                    )
                    : 0;

                // ★ NEW: Set CurrencyIsoCode = Opportunity's currency (multi-currency orgs only)
                if (String.isNotBlank(oppCurrencyCode)) {
                    lineItem.put('CurrencyIsoCode', oppCurrencyCode);
                }

                lineItemList.add(lineItem);
            }
        }

        if (!lineItemList.isEmpty()) {
            insert lineItemList;
        }

    } catch (Exception e) {
        throw new AuraHandledException('Error processing Opportunity Line Items: ' + e.getMessage());
    }
}
            @AuraEnabled
        public static Quotation__c getCurrentQuotation(Id quotationId) {

            if (quotationId == null) {
                throw new AuraHandledException('Quotation Id is required');
            }

            return [
                SELECT Id,
                    Name,
                    Account_Name__c,
                    Discount__c,
                    Expiration_Date__c,
                    Opportunity__c,
                    Quotation_Name__c,
                    Quotation_Status__c,
                    Syncing__c,
                    Tax__c,
                    Total_Price__c,
                    Shipping_and_Handling__c,
                    P_F__c,
                    GST_Amount__c,
                    Grand_Total__c,
                     CurrencyIsoCode 
                FROM Quotation__c
                WHERE Id = :quotationId
                LIMIT 1
            ];
        }

    @AuraEnabled
    public static List<Quotation_Line_Item__c> getQuoteLineItemLastCreated(List<String> lineList, String accountId) {

        if (lineList == null || lineList.isEmpty() || String.isBlank(accountId)) {
            return new List<Quotation_Line_Item__c>();
        }

        Set<Id> productIds = new Set<Id>();

        /*List<Price_Book_Entry_custom__c> priceBookList = [
            SELECT Id, Product__c
            FROM Price_Book_Entry_custom__c 
            WHERE Id IN :lineList
            AND Active__c = true
        ];

        for (Price_Book_Entry_custom__c pbe : priceBookList) {
            if (pbe.Product__c != null) {
                productIds.add(pbe.Product__c);
            }
        }*/

        return new List<Quotation_Line_Item__c>();
    }

  @AuraEnabled
public static void createQuotationLineItems(Id quotationId, List<Map<String, Object>> items) {

    System.debug('quotationId --> ' + quotationId);
    System.debug('### items --> ' + items);

    if (quotationId == null || items == null || items.isEmpty()) {
        throw new AuraHandledException('Missing Quotation or Product data.');
    }

    try {

        // Fetch quotation — ★ UPDATED: also fetch CurrencyIsoCode
        Quotation__c currentSyncQuote = [
            SELECT Id, Syncing__c, Opportunity__c, CurrencyIsoCode
            FROM Quotation__c
            WHERE Id = :quotationId
            LIMIT 1
        ];

        String quoteCurrencyCode = currentSyncQuote.CurrencyIsoCode;
        System.debug('### Quotation CurrencyIsoCode --> ' + quoteCurrencyCode);

        // ★ NEW: If syncing with an Opportunity, also fetch its currency
        String oppCurrencyCode = null;

        if (currentSyncQuote.Opportunity__c != null) {

            Opportunity_Custom__c parentOpp = [
                SELECT Id, CurrencyIsoCode
                FROM Opportunity_Custom__c
                WHERE Id = :currentSyncQuote.Opportunity__c
                LIMIT 1
            ];

            oppCurrencyCode = parentOpp.CurrencyIsoCode;
            System.debug('### Opportunity CurrencyIsoCode --> ' + oppCurrencyCode);
        }

        // Store selected product ids
        Set<Id> productIds = new Set<Id>();

        for (Map<String, Object> item : items) {

            if (item.containsKey('Product__c') &&
                item.get('Product__c') != null) {

                productIds.add((Id)item.get('Product__c'));
            }
        }

        // Existing Opportunity Products
        Set<Id> existingOppProducts = new Set<Id>();

        if (currentSyncQuote.Opportunity__c != null) {

            for (Opportunity_Product_Line_Item__c oppLine : [

                SELECT Productss__c
                FROM Opportunity_Product_Line_Item__c
                WHERE Opportunityss__c = :currentSyncQuote.Opportunity__c

            ]) {

                existingOppProducts.add(oppLine.Productss__c);
            }
        }

        // Insert Lists
        List<Quotation_Line_Item__c> toInsert =
            new List<Quotation_Line_Item__c>();

        List<Opportunity_Product_Line_Item__c> toInsertOppLineItem =
            new List<Opportunity_Product_Line_Item__c>();


        // MAIN LOOP
        for (Map<String, Object> item : items) {

            Id productId = (Id)item.get('Product__c');

            // Quantity
            Decimal newQty = 0;

            if (item.containsKey('Quantity__c') &&
                item.get('Quantity__c') != null) {

                newQty = Decimal.valueOf(
                    String.valueOf(item.get('Quantity__c'))
                );
                System.debug('newQty::' + newQty);
            }

            Decimal listprice = Decimal.valueOf(String.valueOf(item.get('List_Price__c')));

            // Description — LineDescription__c (LWC se aata hai jo Product_Description__c se map hota hai)
            String descriptionLine = '';

            if (item.containsKey('LineDescription__c') &&
                item.get('LineDescription__c') != null) {

                descriptionLine =
                    String.valueOf(item.get('LineDescription__c'));
            }
           
            // Create Quotation Line Item
            Quotation_Line_Item__c qli =
                new Quotation_Line_Item__c();

            qli.Quotation__c = quotationId;
            qli.Productss__c = productId;
            qli.Quantity__c = newQty;
            qli.Line_Description__c = descriptionLine;
             qli.Model_Number__c = item.containsKey('ModelNumber') && item.get('ModelNumber') != null
            ? (String) item.get('ModelNumber')
            : null;

            // List Price
            qli.List_Price__c =
                item.get('List_Price__c') != null
                ? Decimal.valueOf(
                    String.valueOf(item.get('List_Price__c'))
                )
                : 0;
                // DISCOUNT
            qli.Discount__c =
                item.get('Discount__c') != null
                ? Decimal.valueOf(
                    String.valueOf(item.get('Discount__c'))
                )
                : 0;
            // Sales Price
            if (item.containsKey('SalesPrice__c') &&
                item.get('SalesPrice__c') != null) {

                qli.Sales_Price__c = Decimal.valueOf(
                    String.valueOf(item.get('SalesPrice__c'))
                );
            }

            // GST
            qli.GST__c =
                item.get('GST__c') != null
                ? Decimal.valueOf(
                    String.valueOf(item.get('GST__c'))
                )
                : 0;

            // Date
            if (item.containsKey('Date__c') &&
                item.get('Date__c') != null) {

                qli.put(
                    'Date__c',
                    Date.valueOf(
                        (String)item.get('Date__c')
                    )
                );
            }

            // ★ NEW: Set CurrencyIsoCode = Quotation's currency (multi-currency orgs only)
            if (String.isNotBlank(quoteCurrencyCode)) {
                qli.put('CurrencyIsoCode', quoteCurrencyCode);
            }

            toInsert.add(qli);


            // =========================================
            // CREATE OLI ONLY IF PRODUCT NOT EXISTS
            // =========================================

            if (currentSyncQuote.Syncing__c == true
                && !existingOppProducts.contains(productId)) {

                Opportunity_Product_Line_Item__c oli =
                    new Opportunity_Product_Line_Item__c();

                oli.Opportunityss__c =
                    currentSyncQuote.Opportunity__c;

                oli.Productss__c = productId;

                oli.Quantity__c = newQty;

                oli.List_Price__c = listprice;
                oli.Line_Description__c = descriptionLine;
                oli.Model_Number__c = item.containsKey('ModelNumber') && item.get('ModelNumber') != null
                ? (String) item.get('ModelNumber')
                : null;
                oli.GST__c = item.get('GST__c') != null
                ? Decimal.valueOf(String.valueOf(item.get('GST__c')))
                : 0;
                // Sales Price
                if (item.containsKey('SalesPrice__c') &&
                    item.get('SalesPrice__c') != null) {

                    oli.Sales_Price__c = Decimal.valueOf(
                        String.valueOf(item.get('SalesPrice__c'))
                    );
                }

                // Description
                oli.Line_Description__c = descriptionLine;

                // Service Date
                if (item.containsKey('Date__c') &&
                    item.get('Date__c') != null) {

                    oli.put(
                        'ServiceDate__c',
                        Date.valueOf(
                            (String)item.get('Date__c')
                        )
                    );
                }

                // ★ NEW: Set CurrencyIsoCode = Opportunity's currency
                // (fallback to Quotation's currency if Opportunity currency not found)
                String oliCurrency = String.isNotBlank(oppCurrencyCode)
                    ? oppCurrencyCode
                    : quoteCurrencyCode;

                if (String.isNotBlank(oliCurrency)) {
                    oli.put('CurrencyIsoCode', oliCurrency);
                }

                toInsertOppLineItem.add(oli);
            }
        }

        // Insert QLI
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        // Insert OLI
        if (!toInsertOppLineItem.isEmpty()) {
            insert toInsertOppLineItem;
        }

        System.debug('Inserted QLI: ' + toInsert.size());
        System.debug('Inserted OLI: ' + toInsertOppLineItem.size());

    } catch (Exception e) {

        throw new AuraHandledException(
            'Error processing Quotation Line Items: '
            + e.getMessage()
        );
    }
}

    // Get Products
    // @AuraEnabled
    // public static List<Product_custom__c> fetchActiveProduct(){

    //     List<Product_custom__c> allProducts =  [SELECT Id, Product_Name__c,Name, HSN_Code__c, List_Price__c,GST__c,Product_Description__c,CurrencyIsoCode,Model_Numbers__c , Active__c FROM Product_custom__c WHERE Active__c = true AND List_Price__c != Null];
    //     System.debug('### all products:'+allProducts);

    //     return allProducts;

    // }
    @AuraEnabled
    public static List<Product_custom__c> fetchActiveProduct(){

        List<Product_custom__c> allProducts = [
            SELECT Id, Product_Name__c, Name, HSN_Code__c, 
                List_Price__c, List_Price_USD__c,   // ★ NEW FIELD
                GST__c, Product_Description__c, CurrencyIsoCode, 
                Model_Numbers__c, Active__c 
            FROM Product_custom__c 
            WHERE Active__c = true AND List_Price__c != Null
        ];
        System.debug('### all products:'+allProducts);

        return allProducts;
    }
    
}