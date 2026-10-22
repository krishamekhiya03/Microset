/**
 * QuotationPDFControllerTest
 * ─────────────────────────────────────────────────────────────────────────
 * Full coverage test class for QuotationPDFController v2.0
 *
 * Coverage strategy:
 *   - Constructor with no parameters (blank quotationId / orderId)
 *   - loadQuotation() via constructor with valid quotationId
 *   - loadQuotation() with grouped + ungrouped line items
 *   - loadQuotation() with line item images (ContentDocumentLink)
 *   - loadQuotation() with freight amount = 0 (EXTRA AT ACTUAL branch)
 *   - loadQuotation() with freight amount > 0
 *   - loadQuotation() with discount on line items
 *   - loadQuotation() with empty quotationId → no data loaded
 *   - loadOrder() via constructor with valid orderId pointing to Order__c
 *   - GroupWrapper inner class instantiation
 *   - LineItemWrapper inner class property coverage
 *   - fmtDecimal() — small number, large Indian-format number
 *   - formatDate() — via formatted date properties
 *
 * NO System.assert / System.assertEquals anywhere in this file (per requirement).
 * ─────────────────────────────────────────────────────────────────────────
 */
@isTest
private class QuotationPDFControllerTest {

    // ─────────────────────────────────────────────────────────────────────
    //  TEST DATA SETUP
    // ─────────────────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {

        // ── Account & Contact ──
        Account acc = new Account(Name = 'PDF Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'PDF',
            LastName  = 'TestContact',
            AccountId = acc.Id,
            Email     = 'pdftest@example.com'
        );
        insert con;

        // ── Opportunity_Custom__c (parent of Quotation__c) ──
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        // ── Quotation__c  ──
        Quotation__c quote = new Quotation__c();
        quote.Contact_Name__c         = con.Id;
        quote.Opportunity__c          = opp.Id;
        quote.Description__c          = 'PDF Test Subject';
        quote.Expiration_Date__c      = Date.today().addDays(30);
        quote.Email__c                = 'customer@pdftest.com';
        quote.Bill_To__Street__s      = '10 PDF Street';
        quote.Bill_To__City__s        = 'PDF City';
        quote.Bill_To__StateCode__s   = 'GJ';
        quote.Bill_To__PostalCode__s  = '380001';
        quote.Bill_To__CountryCode__s = 'IN';
        quote.Bill_To_Name__c         = 'PDF Customer';
        quote.Shipping_and_Handling__c = 0;   // triggers EXTRA AT ACTUAL branch
        quote.Payment_Term__c         = 'Net 30';
        quote.Delivery_Term__c        = 'FOB';
        quote.Validity__c             = '30 Days';
        quote.Prices1__c              = 'Ex-Works';
        quote.Transit_Insurance__c    = 'Included';
        quote.GSTN_PAN__c             = 'GSTIN123';
        quote.MSME_ZED_Udyam_Reg_No__c = 'MSME123';
        quote.Taxes__c                = 'GST 18%';
        quote.Scope__c                = 'Supply only';
        quote.Force_Majeure__c        = 'Standard';
        quote.Jurisdiction__c         = 'Ahmedabad';
        quote.Warranty__c             = '12 months';
        quote.Inspection__c           = 'At works';
        quote.Commissioning__c        = 'Included';
        insert quote;

        // ── Quote_Line_Group__c records ──
        Quote_Line_Group__c grp1 = new Quote_Line_Group__c(
            Quotes__c     = quote.Id,
            Header__c     = 'Group Alpha',
            Sort_Order__c = 1
        );
        Quote_Line_Group__c grp2 = new Quote_Line_Group__c(
            Quotes__c     = quote.Id,
            Header__c     = 'Group Beta',
            Sort_Order__c = 2
        );
        insert new List<Quote_Line_Group__c>{ grp1, grp2 };

        // ── Quotation_Line_Item__c: 2 grouped + 1 ungrouped ──
        Quotation_Line_Item__c li1 = new Quotation_Line_Item__c();
        li1.Quotation__c        = quote.Id;
        li1.Quantity__c         = 2;
        li1.List_Price__c       = 500;
        li1.Discount__c         = 10;
        li1.Line_Description__c = 'Item One\nSecond line';
        li1.Quote_Line_Group__c = grp1.Id;
        li1.Sort_Order__c       = 1;

        Quotation_Line_Item__c li2 = new Quotation_Line_Item__c();
        li2.Quotation__c        = quote.Id;
        li2.Quantity__c         = 3;
        li2.List_Price__c       = 1000;
        li2.Discount__c         = 0;
        li2.Line_Description__c = 'Item Two';
        li2.Quote_Line_Group__c = grp2.Id;
        li2.Sort_Order__c       = 2;

        Quotation_Line_Item__c li3 = new Quotation_Line_Item__c(); // ungrouped
        li3.Quotation__c        = quote.Id;
        li3.Quantity__c         = 1;
        li3.List_Price__c       = 250;
        li3.Discount__c         = 5;
        li3.Line_Description__c = 'Ungrouped Item';
        li3.Sort_Order__c       = 3;

        insert new List<Quotation_Line_Item__c>{ li1, li2, li3 };

        // ── Attach an image ContentVersion to li1 ──
        ContentVersion cv = new ContentVersion();
        cv.Title          = 'TestImage';
        cv.PathOnClient   = 'TestImage.jpg';
        cv.VersionData    = Blob.valueOf('FakeImageBytes');
        cv.IsMajorVersion = true;
        insert cv;

        ContentVersion inserted = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = inserted.ContentDocumentId;
        cdl.LinkedEntityId    = li1.Id;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        // ── Attach a non-image file (pdf) to li2 — should be ignored ──
        ContentVersion cvPdf = new ContentVersion();
        cvPdf.Title          = 'SomeDoc';
        cvPdf.PathOnClient   = 'SomeDoc.pdf';
        cvPdf.VersionData    = Blob.valueOf('FakePdfBytes');
        cvPdf.IsMajorVersion = true;
        insert cvPdf;

        ContentVersion insertedPdf = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvPdf.Id LIMIT 1
        ];

        ContentDocumentLink cdlPdf = new ContentDocumentLink();
        cdlPdf.ContentDocumentId = insertedPdf.ContentDocumentId;
        cdlPdf.LinkedEntityId    = li2.Id;
        cdlPdf.ShareType         = 'V';
        cdlPdf.Visibility        = 'AllUsers';
        insert cdlPdf;

        // ── Order__c pointing back to the quotation ──
        Order__c ord = new Order__c();
        ord.Quotes__c          = quote.Id;
        ord.Account__c         = acc.Id;
        ord.EffectiveDate__c   = Date.today();
        insert ord;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  HELPER: fetch seeded records
    // ─────────────────────────────────────────────────────────────────────
    private static Quotation__c getQuote() {
        return [SELECT Id FROM Quotation__c LIMIT 1];
    }

    private static Order__c getOrder() {
        return [SELECT Id FROM Order__c LIMIT 1];
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 1: Constructor with NO page parameters → defaults only
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructor_noParams_loadsDefaults() {
        PageReference page = Page.Quotationpdf;
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        // No assertions — just confirm the constructor completes
        String companyName = ctrl.companyName;
        Boolean hasGroups  = ctrl.hasGroups;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 2: loadQuotation with valid quotationId
    //          Covers: header fields, address building, grouped items,
    //                  ungrouped items, sequenceLabel assignment,
    //                  freight = 0 → EXTRA AT ACTUAL branch
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_validId_fullCoverage() {
        Quotation__c q = getQuote();

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        // Touch all properties to confirm they were populated
        String qNum        = ctrl.quotationNumber;
        String qDate       = ctrl.quotationDateFormatted;
        String validUntil  = ctrl.validUntilFormatted;
        String reference   = ctrl.reference;
        String subject     = ctrl.subject;
        String contact     = ctrl.contactPerson;
        String salutation  = ctrl.contactSalutation;
        String custName    = ctrl.customerName;
        String custEmail   = ctrl.customerEmail;
        String mobile      = ctrl.mobileNumber;
        String custAddr    = ctrl.customerAddress;
        String payment     = ctrl.paymentTerms;
        String prices      = ctrl.prices;
        String transit     = ctrl.transit;
        String delivery    = ctrl.deliveryTerms;
        String validity    = ctrl.validity;
        String inspection  = ctrl.inspection;
        String commission  = ctrl.commissioning;
        String msme        = ctrl.MSME_ZED_Udyam_Reg_No;
        String gstn        = ctrl.GSTN_PAN;
        String taxStr      = ctrl.tax;
        String scope       = ctrl.scope;
        String force       = ctrl.forceMajeure;
        String juris       = ctrl.jurisdiction;
        String warranty    = ctrl.warrantyTerms;
        String createdBy   = ctrl.quotationCreatedByName;
        String subtotal    = ctrl.subtotalFmt;
        String freight     = ctrl.freightDisplay;
        String pfAmt       = ctrl.pfAmtFmt;
        String gst         = ctrl.totalGSTFmt;
        String grand       = ctrl.grandTotalFmt;
        Boolean hasTerms   = ctrl.hasTermsRows;
        Boolean hasGroups  = ctrl.hasGroups;
        Boolean isOrder    = ctrl.isOrderPDF;
        String offerNum    = ctrl.offerNumber;
        String offerDate   = ctrl.offerDate;

        List<QuotationPDFController.GroupWrapper>    groups    = ctrl.groupedItems;
        List<QuotationPDFController.LineItemWrapper> ungrouped = ctrl.ungroupedItems;
        List<QuotationPDFController.LineItemWrapper> allItems  = ctrl.lineItems;

        // Touch group-level fields
        for (QuotationPDFController.GroupWrapper gw : groups) {
            String gId        = gw.groupId;
            String header     = gw.headerName;
            Decimal sortOrder = gw.sortOrder;
            Integer idx       = gw.groupIndex;

            for (QuotationPDFController.LineItemWrapper li : gw.lines) {
                Integer num         = li.itemNumber;
                String  label       = li.sequenceLabel;
                String  prod        = li.productName;
                String  hsn         = li.hsnCode;
                String  description = li.description;
                Decimal qty      = li.quantity;
                String  unit     = li.unit;
                Decimal disc     = li.discount;
                Decimal gstPct   = li.gst;
                Decimal price    = li.unitPrice;
                Boolean hilight  = li.isHighlighted;
                Boolean hasDisc  = li.hasDiscount;
                String  upFmt    = li.unitPriceFmt;
                String  adFmt    = li.afterDiscFmt;
                String  totFmt   = li.itemTotalFmt;
                String  qtyDisp  = li.qtyDisplay;
                List<String> imgs = li.imageUrls;
            }
        }

        // Touch ungrouped items
        for (QuotationPDFController.LineItemWrapper li : ungrouped) {
            String label = li.sequenceLabel;
            String prod  = li.productName;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 3: freight amount > 0  → "₹ X,XX,XXX.XX" display branch
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_freightGreaterThanZero() {
        Quotation__c q = [SELECT Id, Shipping_and_Handling__c FROM Quotation__c LIMIT 1];
        q.Shipping_and_Handling__c = 1250;
        update q;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        String freightDisplay = ctrl.freightDisplay;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 4: Quotation with NO line items → covers empty loop paths
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_noLineItems() {
        // Create a fresh quotation with no line items
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q2 = new Quotation__c();
        q2.Opportunity__c          = opp.Id;
        q2.Expiration_Date__c      = Date.today().addDays(10);
        q2.Shipping_and_Handling__c = 0;
        insert q2;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q2.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> items = ctrl.lineItems;
        Boolean hasGroups = ctrl.hasGroups;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 5: Quotation with NO groups but WITH line items
    //          Covers: all items land in ungroupedItems, sequenceLabel = "1","2"
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_noGroups_allUngrouped() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q3 = new Quotation__c();
        q3.Opportunity__c          = opp.Id;
        q3.Shipping_and_Handling__c = 500;
        insert q3;

        Quotation_Line_Item__c li = new Quotation_Line_Item__c();
        li.Quotation__c    = q3.Id;
        li.Quantity__c     = 4;
        li.List_Price__c   = 100;
        li.Sort_Order__c   = 1;
        insert li;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q3.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> ungrouped = ctrl.ungroupedItems;
        String label = ungrouped.isEmpty() ? '' : ungrouped[0].sequenceLabel;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 6: Invalid / nonexistent quotationId → empty return (no crash)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_nonexistentId_noCrash() {
        // Insert then delete a quotation to get a stale but syntactically
        // valid Id of the correct SObject type
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c temp = new Quotation__c();
        temp.Opportunity__c = opp.Id;
        insert temp;
        Id tempId = temp.Id;
        delete temp;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', String.valueOf(tempId));
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        // Controller should complete gracefully; lineItems list will be empty
        List<QuotationPDFController.LineItemWrapper> items = ctrl.lineItems;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 7: loadOrder — valid Order__c Id triggers loadOrder() path
    //          Covers: isOrderPDF = true, quotationNumber override,
    //                  quotationDateFormatted override
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadOrder_validOrderId() {
        Order__c ord = getOrder();

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('id', ord.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        Boolean isOrderPDF = ctrl.isOrderPDF;
        String  qNum       = ctrl.quotationNumber;
        String  qDate      = ctrl.quotationDateFormatted;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 8: Id passed as 'id' param but belongs to a non-Order__c SObject
    //          → the objectName check fails → loadOrder() NOT called (no crash)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructor_idParamIsNotOrder_noCrash() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('id', acc.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        Boolean isOrderPDF = ctrl.isOrderPDF;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 9: Both quotationId AND id params present
    //          → loadQuotation() first, then loadOrder() overrides 2 fields
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructor_bothParams_orderOverridesFields() {
        Quotation__c q   = getQuote();
        Order__c     ord = getOrder();

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        page.getParameters().put('id', ord.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        Boolean isOrderPDF = ctrl.isOrderPDF;
        String  qNum       = ctrl.quotationNumber;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 10: Order__c whose Quotes__c is null → loadQuotation skipped
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadOrder_noLinkedQuotation_noCrash() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order__c ordNoQuote = new Order__c();
        ordNoQuote.Account__c       = acc.Id;
        ordNoQuote.EffectiveDate__c = Date.today();
        // Quotes__c intentionally left null
        insert ordNoQuote;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('id', ordNoQuote.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        Boolean isOrderPDF = ctrl.isOrderPDF;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 11: GroupWrapper inner class direct instantiation
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGroupWrapper_directInstantiation() {
        Quote_Line_Group__c g = [SELECT Id, Header__c, Sort_Order__c FROM Quote_Line_Group__c LIMIT 1];

        Test.startTest();
        QuotationPDFController.GroupWrapper gw =
            new QuotationPDFController.GroupWrapper(g);
        Test.stopTest();

        String gId          = gw.groupId;
        String header       = gw.headerName;
        Decimal sortOrder   = gw.sortOrder;
        List<QuotationPDFController.LineItemWrapper> lines = gw.lines;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 12: LineItemWrapper property coverage
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLineItemWrapper_propertyAccess() {
        Test.startTest();
        QuotationPDFController.LineItemWrapper li =
            new QuotationPDFController.LineItemWrapper();
        li.itemNumber    = 1;
        li.sequenceLabel = '1A';
        li.productName   = 'Sensor X';
        li.hsnCode       = '9026';
        li.description   = 'Multi<br/>Line';
        li.quantity      = 5;
        li.unit          = 'Nos';
        li.discount      = 10;
        li.gst           = 18;
        li.unitPrice     = 100;
        li.isHighlighted = false;
        li.hasDiscount   = true;
        li.unitPriceFmt  = '100.00';
        li.afterDiscFmt  = '90.00';
        li.itemTotalFmt  = '450.00';
        li.qtyDisplay    = '05 Nos';
        li.imageUrls     = new List<String>{ 'https://example.com/img.jpg' };
        Test.stopTest();

        // Touch all fields
        Integer n  = li.itemNumber;
        String  sl = li.sequenceLabel;
        String  pn = li.productName;
        String  hc = li.hsnCode;
        String  ds = li.description;
        Decimal q  = li.quantity;
        String  u  = li.unit;
        Decimal d  = li.discount;
        Decimal g  = li.gst;
        Decimal up = li.unitPrice;
        Boolean ih = li.isHighlighted;
        Boolean hd = li.hasDiscount;
        String  uf = li.unitPriceFmt;
        String  af = li.afterDiscFmt;
        String  tf = li.itemTotalFmt;
        String  qd = li.qtyDisplay;
        List<String> imgs = li.imageUrls;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 13: Large-number formatting path in fmtDecimal (Indian format)
    //          Covered indirectly via grandTotalFmt for a high-value quote
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testFmtDecimal_largeNumber_indianFormat() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        // Many high-value line items to force a large grand total
        List<Quotation_Line_Item__c> items = new List<Quotation_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            Quotation_Line_Item__c li = new Quotation_Line_Item__c();
            li.Quotation__c  = q.Id;
            li.Quantity__c   = 100;
            li.List_Price__c = 50000;
            li.Sort_Order__c = i + 1;
            items.add(li);
        }
        insert items;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        // grandTotalFmt will be a large Indian-format number like "2,95,00,000.00"
        String grandFmt = ctrl.grandTotalFmt;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 14: formatDate with null date → empty string branch
    //           Covered by setting Expiration_Date__c = null
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testFormatDate_nullDate_emptyString() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c     = opp.Id;
        q.Expiration_Date__c = null;   // validUntilFormatted → ''
        q.Shipping_and_Handling__c = 0;
        insert q;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        String validUntil = ctrl.validUntilFormatted; // Should be ''
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 15: Multiple line items in single group (covers A, B, C labels)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGroupedItems_multipleItemsInOneGroup() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        Quote_Line_Group__c grp = new Quote_Line_Group__c(
            Quotes__c     = q.Id,
            Header__c     = 'Solo Group',
            Sort_Order__c = 1
        );
        insert grp;

        List<Quotation_Line_Item__c> items = new List<Quotation_Line_Item__c>();
        for (Integer i = 1; i <= 3; i++) {
            Quotation_Line_Item__c li = new Quotation_Line_Item__c();
            li.Quotation__c        = q.Id;
            li.Quantity__c         = i;
            li.List_Price__c       = 100 * i;
            li.Quote_Line_Group__c = grp.Id;
            li.Sort_Order__c       = i;
            items.add(li);
        }
        insert items;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        // Labels should be 1A, 1B, 1C
        List<QuotationPDFController.GroupWrapper> groups = ctrl.groupedItems;
        if (!groups.isEmpty() && !groups[0].lines.isEmpty()) {
            for (QuotationPDFController.LineItemWrapper li : groups[0].lines) {
                String label = li.sequenceLabel;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 16: Line item with null Discount__c → discount defaults to 0
    //           and hasDiscount = false branch
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLineItem_nullDiscount_defaultsToZero() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        Quotation_Line_Item__c li = new Quotation_Line_Item__c();
        li.Quotation__c  = q.Id;
        li.Quantity__c   = 2;
        li.List_Price__c = 300;
        li.Discount__c   = null;  // explicitly null
        li.Sort_Order__c = 1;
        insert li;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> allItems = ctrl.lineItems;
        if (!allItems.isEmpty()) {
            Boolean hd = allItems[0].hasDiscount; // should be false
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 17: Line item with null Quantity and null List_Price → default 0
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLineItem_nullQtyAndPrice_defaultsToZero() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        // List_Price__c and Quantity__c might be required fields in your org.
        // If so, use minimum values (1, 0) and confirm the controller handles them.
        Quotation_Line_Item__c li = new Quotation_Line_Item__c();
        li.Quotation__c  = q.Id;
        li.Quantity__c   = 1;
        li.List_Price__c = 0;
        li.Sort_Order__c = 1;
        insert li;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> allItems = ctrl.lineItems;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 18: Quotation with address fields all blank
    //           → customerAddress = '' (all addrParts empty)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_blankAddress_emptyString() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        // All Bill_To fields left blank
        insert q;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        String addr = ctrl.customerAddress; // Should be ''
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 19: png image extension check (covers 'png' branch in imageUrl loop)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_pngImage_attached() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        Quotation_Line_Item__c li = new Quotation_Line_Item__c();
        li.Quotation__c  = q.Id;
        li.Quantity__c   = 1;
        li.List_Price__c = 100;
        li.Sort_Order__c = 1;
        insert li;

        // Attach a PNG
        ContentVersion cvPng = new ContentVersion();
        cvPng.Title          = 'PngImage';
        cvPng.PathOnClient   = 'PngImage.png';
        cvPng.VersionData    = Blob.valueOf('FakePngBytes');
        cvPng.IsMajorVersion = true;
        insert cvPng;

        ContentVersion insertedPng = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvPng.Id LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedPng.ContentDocumentId;
        cdl.LinkedEntityId    = li.Id;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> allItems = ctrl.lineItems;
        if (!allItems.isEmpty()) {
            List<String> imgs = allItems[0].imageUrls;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST 20: jpeg extension (covers 'jpeg' branch)
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testLoadQuotation_jpegImage_attached() {
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        Quotation__c q = new Quotation__c();
        q.Opportunity__c          = opp.Id;
        q.Shipping_and_Handling__c = 0;
        insert q;

        Quotation_Line_Item__c li = new Quotation_Line_Item__c();
        li.Quotation__c  = q.Id;
        li.Quantity__c   = 1;
        li.List_Price__c = 100;
        li.Sort_Order__c = 1;
        insert li;

        ContentVersion cvJpeg = new ContentVersion();
        cvJpeg.Title          = 'JpegImage';
        cvJpeg.PathOnClient   = 'JpegImage.jpeg';
        cvJpeg.VersionData    = Blob.valueOf('FakeJpegBytes');
        cvJpeg.IsMajorVersion = true;
        insert cvJpeg;

        ContentVersion insertedJpeg = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvJpeg.Id LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedJpeg.ContentDocumentId;
        cdl.LinkedEntityId    = li.Id;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        PageReference page = Page.Quotationpdf;
        page.getParameters().put('quotationId', q.Id);
        Test.setCurrentPage(page);

        Test.startTest();
        QuotationPDFController ctrl = new QuotationPDFController();
        Test.stopTest();

        List<QuotationPDFController.LineItemWrapper> allItems = ctrl.lineItems;
    }
}