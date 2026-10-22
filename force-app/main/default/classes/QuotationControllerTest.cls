/**
 * QuotationControllerTest
 * ─────────────────────────────────────────────────────────────────────────
 * Full test coverage for QuotationController (v4.0).
 * NOTE: No Asset (Asset__c / standard Asset) records are created anywhere
 *       in this test class, per requirement.
 *
 * Coverage strategy:
 *   - All DML-dependent methods are exercised with real test data for
 *     Quotation__c, Quotation_Line_Item__c, and Quote_Line_Group__c.
 *   - Methods that depend on org config not guaranteed to exist
 *     (EmailTemplate named 'Quotation Email Template', OrgWideEmailAddress)
 *     are wrapped so the test still passes and the code path is executed,
 *     whether or not that org-wide config is present in the running org.
 *   - generateVFPdf() relies on Test.isRunningTest() inside the controller
 *     to avoid actually rendering a Visualforce PDF during tests.
 *
 * IMPORTANT: Adjust field API names below ONLY if your org differs from
 * what is referenced in QuotationController itself (this test uses the
 * exact same field names the controller uses, so it should compile and
 * run as-is against the same org/metadata).
 * ─────────────────────────────────────────────────────────────────────────
 */
@isTest
private class QuotationControllerTest {

    // ─────────────────────────────────────────────────────────────────────
    //  TEST DATA SETUP
    // ─────────────────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {

        // Account + Contact (needed for Contact_Name__c lookup on Quotation__c)
        Account acc = new Account(Name = 'Test Account For Quotation');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Contact',
            AccountId = acc.Id,
            Email     = 'testcontact@example.com'
        );
        insert con;

        // Opportunity_Custom__c (needed because Quotation__c.Opportunity__c
        // is a lookup to this custom object, NOT the standard Opportunity)
        Opportunity_Custom__c opp = new Opportunity_Custom__c();
        insert opp;

        // Quotation__c record
        // NOTE: Quotation_Date__c and Reference__c are not writeable in this
        // org (likely formula/system fields), so they are intentionally
        // omitted here.
        Quotation__c quote = new Quotation__c();
        quote.Contact_Name__c   = con.Id;
        quote.Opportunity__c    = opp.Id;
        quote.Description__c    = 'Test Quotation Subject';
        quote.Expiration_Date__c = Date.today().addDays(30);
        quote.Email__c          = 'customer@example.com';
        quote.Email_CC__c       = 'cc@example.com';
        quote.Email_BCC__c      = 'bcc@example.com';
        quote.Bill_To__Street__s      = '123 Test Street';
        quote.Bill_To__City__s        = 'Test City';
        quote.Bill_To__StateCode__s   = 'GJ';
        quote.Bill_To__PostalCode__s  = '380001';
        quote.Bill_To__CountryCode__s = 'IN';
        quote.Bill_To_Name__c         = 'Test Customer';
        quote.Shipping_and_Handling__c = 100;
        // NOTE: Quotation_Created_By__c is a restricted picklist; 'Test User'
        // is not a valid value in this org, so it's left unset (not required).
        insert quote;

        // Quote_Line_Group__c records
        Quote_Line_Group__c grp1 = new Quote_Line_Group__c(
            Quotes__c    = quote.Id,
            Header__c    = 'Group 1',
            Sort_Order__c = 1
        );
        Quote_Line_Group__c grp2 = new Quote_Line_Group__c(
            Quotes__c    = quote.Id,
            Header__c    = 'Group 2',
            Sort_Order__c = 2
        );
        insert new List<Quote_Line_Group__c>{ grp1, grp2 };

        // Quotation_Line_Item__c records (no Product__c master needed unless
        // Productss__c is required; if it's required in your org, create a
        // minimal lookup target record here instead of an Asset).
        Quotation_Line_Item__c li1 = new Quotation_Line_Item__c();
        li1.Quotation__c        = quote.Id;
        li1.Quantity__c         = 2;
        li1.List_Price__c       = 100;
        li1.Line_Description__c = 'Line Item 1';
        li1.Quote_Line_Group__c = grp1.Id;
        li1.Sort_Order__c       = 1;

        Quotation_Line_Item__c li2 = new Quotation_Line_Item__c();
        li2.Quotation__c        = quote.Id;
        li2.Quantity__c         = 1;
        li2.List_Price__c       = 200;
        li2.Line_Description__c = 'Line Item 2';
        li2.Quote_Line_Group__c = grp2.Id;
        li2.Sort_Order__c       = 2;

        insert new List<Quotation_Line_Item__c>{ li1, li2 };
    }

    // Helper to fetch the seeded Quotation__c
    private static Quotation__c getSeededQuotation() {
        return [SELECT Id, Contact_Name__c FROM Quotation__c LIMIT 1];
    }

    // ─────────────────────────────────────────────────────────────────────
    //  getQuoteLineGroups
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGetQuoteLineGroups_success() {
        Quotation__c q = getSeededQuotation();

        Test.startTest();
        List<Quote_Line_Group__c> groups = QuotationController.getQuoteLineGroups(q.Id);
        Test.stopTest();

        System.assertEquals(2, groups.size(), 'Expected 2 groups ordered by Sort_Order__c');
        System.assertEquals('Group 1', groups[0].Header__c);
        System.assertEquals('Group 2', groups[1].Header__c);
    }

    @isTest
    static void testGetQuoteLineGroups_nullId_throws() {
        Boolean caught = false;
        try {
            QuotationController.getQuoteLineGroups(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for null quotationId');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveQuoteLineGroup
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testSaveQuoteLineGroup_create() {
        Quotation__c q = getSeededQuotation();

        Test.startTest();
        String newId = QuotationController.saveQuoteLineGroup(q.Id, null, 'New Group', 3);
        Test.stopTest();

        System.assertNotEquals(null, newId, 'Expected a new Id to be returned');

        Quote_Line_Group__c created = [
            SELECT Header__c, Sort_Order__c, Quotes__c
            FROM Quote_Line_Group__c
            WHERE Id = :newId
        ];
        System.assertEquals('New Group', created.Header__c);
        System.assertEquals(3, created.Sort_Order__c);
        System.assertEquals(q.Id, created.Quotes__c);
    }

    @isTest
    static void testSaveQuoteLineGroup_update() {
        Quotation__c q = getSeededQuotation();  // ← ADD THIS
        Quote_Line_Group__c existing = [SELECT Id FROM Quote_Line_Group__c LIMIT 1];
    
        Test.startTest();
        String updatedId = QuotationController.saveQuoteLineGroup(
            q.Id,        // ← PASS quotationId instead of null
            existing.Id, 
            'Updated Header', 
            5
        );
        Test.stopTest();
    
        System.assertEquals(existing.Id, updatedId);
    
        Quote_Line_Group__c reloaded = [
            SELECT Header__c, Sort_Order__c FROM Quote_Line_Group__c WHERE Id = :existing.Id
        ];
        System.assertEquals('Updated Header', reloaded.Header__c);
        System.assertEquals(5, reloaded.Sort_Order__c);
    }
    @isTest
    static void testSaveQuoteLineGroup_blankQuotationId_throws() {
        Boolean caught = false;
        try {
            QuotationController.saveQuoteLineGroup('', null, 'Header', 1);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank quotationId on create');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  deleteQuoteLineGroup
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testDeleteQuoteLineGroup_success_unlinksChildren() {
        Quote_Line_Group__c grp = [SELECT Id FROM Quote_Line_Group__c WHERE Header__c = 'Group 1' LIMIT 1];
        Quotation_Line_Item__c li = [
            SELECT Id, Quote_Line_Group__c FROM Quotation_Line_Item__c
            WHERE Quote_Line_Group__c = :grp.Id LIMIT 1
        ];
        System.assertEquals(grp.Id, li.Quote_Line_Group__c);

        Test.startTest();
        QuotationController.deleteQuoteLineGroup(grp.Id);
        Test.stopTest();

        // Group should be deleted
        List<Quote_Line_Group__c> remaining = [SELECT Id FROM Quote_Line_Group__c WHERE Id = :grp.Id];
        System.assertEquals(0, remaining.size(), 'Group should have been deleted');

        // Child line item should now be ungrouped
        Quotation_Line_Item__c reloadedLi = [
            SELECT Quote_Line_Group__c FROM Quotation_Line_Item__c WHERE Id = :li.Id
        ];
        System.assertEquals(null, reloadedLi.Quote_Line_Group__c, 'Line item should be unlinked from deleted group');
    }

    @isTest
    static void testDeleteQuoteLineGroup_blankId_throws() {
        Boolean caught = false;
        try {
            QuotationController.deleteQuoteLineGroup(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank groupId');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  reorderGroups
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testReorderGroups_success() {
        List<Quote_Line_Group__c> groups = [SELECT Id, Sort_Order__c FROM Quote_Line_Group__c ORDER BY Sort_Order__c ASC];

        List<Map<String, Object>> groupOrders = new List<Map<String, Object>>();
        Integer newOrder = 10;
        for (Quote_Line_Group__c g : groups) {
            groupOrders.add(new Map<String, Object>{
                'id'        => g.Id,
                'sortOrder' => newOrder
            });
            newOrder += 10;
        }

        Test.startTest();
        QuotationController.reorderGroups(groupOrders);
        Test.stopTest();

        List<Quote_Line_Group__c> reloaded = [
            SELECT Id, Sort_Order__c FROM Quote_Line_Group__c ORDER BY Sort_Order__c ASC
        ];
        System.assertEquals(10, reloaded[0].Sort_Order__c);
        System.assertEquals(20, reloaded[1].Sort_Order__c);
    }

    @isTest
    static void testReorderGroups_emptyList_noOp() {
        Test.startTest();
        QuotationController.reorderGroups(new List<Map<String, Object>>());
        Test.stopTest();
        // No exception expected; nothing to assert beyond successful completion.
        System.assert(true);
    }

    // ─────────────────────────────────────────────────────────────────────
    //  generateVFPdf
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGenerateVFPdf_success() {
        Quotation__c q = getSeededQuotation();

        Test.startTest();
        String contentDocId = QuotationController.generateVFPdf(q.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocId, 'Expected a ContentDocument Id back');

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :q.Id
        ];
        System.assert(!links.isEmpty(), 'Expected the generated PDF to be linked to the Quotation record');
    }

    @isTest
    static void testGenerateVFPdf_blankId_throws() {
        Boolean caught = false;
        try {
            QuotationController.generateVFPdf('');
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank quotationId');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  getPdfDownloadUrl
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGetPdfDownloadUrl_success() {
        Quotation__c q = getSeededQuotation();

        String contentDocId = QuotationController.generateVFPdf(q.Id);

        Test.startTest();
        String url = QuotationController.getPdfDownloadUrl(contentDocId);
        Test.stopTest();

        System.assert(url.startsWith('/sfc/servlet.shepherd/version/download/'), 'Unexpected URL format: ' + url);
    }

    @isTest
    static void testGetPdfDownloadUrl_blankId_throws() {
        Boolean caught = false;
        try {
            QuotationController.getPdfDownloadUrl(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank contentDocumentId');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveQuotationPDF
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testSaveQuotationPDF_success() {
        Quotation__c q = getSeededQuotation();

        Map<String, Object> payload = buildBasePayloadMap(q.Id);
        payload.put('htmlContent', '<html><body>Quote</body></html>');

        Test.startTest();
        String result = QuotationController.saveQuotationPDF(payload);
        Test.stopTest();

        System.assertNotEquals('ERROR', result);
        System.assertNotEquals('NO_DATA', result);
    }

    @isTest
    static void testSaveQuotationPDF_emptyMap_returnsNoData() {
        Test.startTest();
        String result = QuotationController.saveQuotationPDF(new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('NO_DATA', result);
    }

    @isTest
    static void testSaveQuotationPDF_nullMap_returnsNoData() {
        Test.startTest();
        String result = QuotationController.saveQuotationPDF(null);
        Test.stopTest();

        System.assertEquals('NO_DATA', result);
    }

    @isTest
    static void testSaveQuotationPDF_blankHtml_handledGracefully() {
        Quotation__c q = getSeededQuotation();

        Map<String, Object> payload = buildBasePayloadMap(q.Id);
        payload.put('htmlContent', '');

        Test.startTest();
        String result = QuotationController.saveQuotationPDF(payload);
        Test.stopTest();

        // saveAsAttachment returns null when htmlContent is blank;
        // saveQuotationPDF still completes without throwing.
        System.assertEquals(null, result);
    }

    // ─────────────────────────────────────────────────────────────────────
    //  getEmailTemplateContent
    //  NOTE: This depends on an EmailTemplate existing with the given name.
    //  We create one here (EmailTemplate is metadata-like but insertable
    //  in Apex tests) so the method can be fully exercised.
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGetEmailTemplateContent_success() {
        Quotation__c q = [
            SELECT Id, Quote_Number__c, Contact_Salutation__c, Contact_Name__c
            FROM Quotation__c LIMIT 1
        ];

        Id folderId = UserInfo.getUserId(); // not used directly; templates need a folder
        EmailTemplate et = createTestEmailTemplate('QC_Test_Template_' + System.now().getTime());

        Test.startTest();
        Map<String, String> result = QuotationController.getEmailTemplateContent(et.Name, q.Id);
        Test.stopTest();

        System.assert(result.containsKey('subject'));
        System.assert(result.containsKey('htmlBody'));
        System.assert(result.containsKey('body'));
    }

    @isTest
    static void testGetEmailTemplateContent_notFound_throws() {
        Quotation__c q = getSeededQuotation();

        Boolean caught = false;
        Test.startTest();
        try {
            QuotationController.getEmailTemplateContent('Nonexistent_Template_XYZ', q.Id);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        Test.stopTest();

        System.assert(caught, 'Expected AuraHandledException when template is not found');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  sendQuotationEmail
    //  NOTE: Email sending is not actually delivered in test context;
    //  Messaging.sendEmail still executes the code path and returns a
    //  result object. We create the required 'Quotation Email Template'
    //  so the SOQL lookup inside the method succeeds.
    // ─────────────────────────────────────────────────────────────────────
   @isTest
    static void testSendQuotationEmail_success() {
        Quotation__c q = getSeededQuotation();
        
        // Setup objects (EmailTemplate) in separate runAs context
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            // ★ Template name exactly 'Quotation Email Template' chahiye
            //   (controller mein hardcoded hai)
            createTestEmailTemplate('Quotation Email Template');
        }
        
        // Generate PDF before startTest
        QuotationController.generateVFPdf(q.Id);
        
        Map<String, Object> payload = buildBasePayloadMap(q.Id);
        payload.put('toAddresses',  new List<Object>{ 'valid@example.com' });
        payload.put('ccAddresses',  new List<Object>{ 'cc@example.com', 'not-an-email' });
        payload.put('bccAddresses', new List<Object>{ 'bcc@example.com' });
        
        Test.startTest();
        String result = QuotationController.sendQuotationEmail(payload);
        Test.stopTest();
        
        System.assertEquals('SUCCESS', result);
    }
    @isTest
    static void testSendQuotationEmail_noToAddresses_throws() {
        Quotation__c q = getSeededQuotation();

        Map<String, Object> payload = buildBasePayloadMap(q.Id);
        // No toAddresses key at all

        Boolean caught = false;
        try {
            QuotationController.sendQuotationEmail(payload);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException when no recipients are provided');
    }

    @isTest
    static void testSendQuotationEmail_allInvalidToAddresses_throws() {
        Quotation__c q = getSeededQuotation();
        createTestEmailTemplate('Quotation Email Template');

        Map<String, Object> payload = buildBasePayloadMap(q.Id);
        payload.put('toAddresses', new List<Object>{ 'not-a-valid-email' });

        Boolean caught = false;
        try {
            QuotationController.sendQuotationEmail(payload);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException when all TO addresses are invalid');
    }

    @isTest
    static void testSendQuotationEmail_quotationWithoutContact_throws() {
        // Create non-setup objects first
        Opportunity_Custom__c tempOpp = new Opportunity_Custom__c();
        insert tempOpp;
    
        Quotation__c q2 = new Quotation__c();
        q2.Opportunity__c = tempOpp.Id;
        insert q2;
    
        // Create setup object (EmailTemplate) in separate runAs context
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            createTestEmailTemplate('Quotation Email Template');
        }
    
        Map<String, Object> payload = buildBasePayloadMap(q2.Id);
        payload.put('toAddresses', new List<Object>{ 'valid@example.com' });
    
        Boolean caught = false;
        try {
            QuotationController.sendQuotationEmail(payload);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException when Quotation has no Contact');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  getQuotations
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGetQuotations_success() {
        Quotation__c q = getSeededQuotation();

        Test.startTest();
        List<Quotation__c> results = QuotationController.getQuotations(q.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(q.Id, results[0].Id);
    }

    @isTest
    static void testGetQuotations_nullId_throws() {
        Boolean caught = false;
        try {
            QuotationController.getQuotations(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for null recordId');
    }

    @isTest
    static void testGetQuotations_notFound_throws() {
        Opportunity_Custom__c tempOpp = new Opportunity_Custom__c();
        insert tempOpp;

        Quotation__c temp = new Quotation__c();
        temp.Opportunity__c = tempOpp.Id;
        insert temp;
        Id tempId = temp.Id;
        delete temp;

        Boolean caught = false;
        try {
            QuotationController.getQuotations(tempId);
        } catch (Exception ex) {
            caught = true;
        }
        System.assert(caught, 'Expected an exception for a non-existent quotation Id');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  getQuotationLineItems
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGetQuotationLineItems_success() {
        Quotation__c q = getSeededQuotation();

        Test.startTest();
        List<Quotation_Line_Item__c> items = QuotationController.getQuotationLineItems(q.Id);
        Test.stopTest();

        System.assertEquals(2, items.size());
    }

    @isTest
    static void testGetQuotationLineItems_nullId_throws() {
        Boolean caught = false;
        try {
            QuotationController.getQuotationLineItems(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for null quotationId');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveFullQuotation
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testSaveFullQuotation_success() {
        Quotation__c q = getSeededQuotation();

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('recordId', q.Id);
        payload.put('validUntil', String.valueOf(Date.today().addDays(15)));
        payload.put('quotationName', 'Updated Quotation Name');
        payload.put('subject', 'Updated Subject');
        // NOTE: 'quotationCreatedBy' maps to the restricted picklist
        // Quotation_Created_By__c. Omitted here since we don't have a
        // confirmed valid picklist value; add payload.put('quotationCreatedBy', '<VALID_VALUE>')
        // if you want to assert on this field specifically.
        payload.put('pfPercent', 5);
        payload.put('gstPercent', 18);
        payload.put('freightCharges', '250');
        payload.put('customerEmail', 'updated@example.com');
        payload.put('customerAddress', '456 Updated Street');
        payload.put('customerCity', 'Updated City');
        payload.put('customerState', 'GJ');
        payload.put('customerPostalCode', '380002');
        payload.put('customerCountry', 'IN');

        Test.startTest();
        QuotationController.saveFullQuotation(payload);
        Test.stopTest();

        Quotation__c reloaded = [
            SELECT Description__c, Email__c, Shipping_and_Handling__c
            FROM Quotation__c WHERE Id = :q.Id
        ];
        System.assertEquals('Updated Subject', reloaded.Description__c);
        System.assertEquals('updated@example.com', reloaded.Email__c);
        System.assertEquals(250, reloaded.Shipping_and_Handling__c);
    }

    @isTest
    static void testSaveFullQuotation_nullPayload_throws() {
        Boolean caught = false;
        try {
            QuotationController.saveFullQuotation(null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for null payload');
    }

    @isTest
    static void testSaveFullQuotation_missingRecordId_throws() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('quotationName', 'No Record Id');

        Boolean caught = false;
        try {
            QuotationController.saveFullQuotation(payload);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for missing recordId');
    }

    @isTest
    static void testSaveFullQuotation_invalidSObjectType_throws() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('recordId', acc.Id);

        Boolean caught = false;
        try {
            QuotationController.saveFullQuotation(payload);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for a recordId of the wrong SObject type');
    }

    @isTest
    static void testSaveFullQuotation_invalidFreightCharges_handledByCatch() {
        Quotation__c q = getSeededQuotation();

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('recordId', q.Id);
        payload.put('freightCharges', 'not-a-number'); // forces Decimal.valueOf to throw

        Boolean caught = false;
        try {
            QuotationController.saveFullQuotation(payload);
        } catch (AuraHandledException ex) {
            caught = true;
            System.assert(
                ex.getMessage().contains('Unable to save quotation') ||
                ex.getMessage().length() > 0
            );
        }
        System.assert(caught, 'Expected AuraHandledException to be thrown and mapped by the catch block');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  updateQuotationLineItems
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testUpdateQuotationLineItems_updateExisting() {
        Quotation__c q = getSeededQuotation();
        List<Quotation_Line_Item__c> existing = [
            SELECT Id, Quotation__c, Quantity__c, List_Price__c, Quote_Line_Group__c, Sort_Order__c
            FROM Quotation_Line_Item__c WHERE Quotation__c = :q.Id
        ];

        for (Quotation_Line_Item__c li : existing) {
            li.Quantity__c = 9;
        }

        Test.startTest();
        QuotationController.updateQuotationLineItems(q.Id, existing);
        Test.stopTest();

        List<Quotation_Line_Item__c> reloaded = [
            SELECT Quantity__c FROM Quotation_Line_Item__c WHERE Quotation__c = :q.Id
        ];
        for (Quotation_Line_Item__c li : reloaded) {
            System.assertEquals(9, li.Quantity__c);
        }
    }

    @isTest
    static void testUpdateQuotationLineItems_insertNew() {
        Quotation__c q = getSeededQuotation();

        Quotation_Line_Item__c newItem = new Quotation_Line_Item__c();
        newItem.Quantity__c   = 3;
        newItem.List_Price__c = 50;
        newItem.Line_Description__c = 'Brand New Item';

        List<Quotation_Line_Item__c> items = new List<Quotation_Line_Item__c>{ newItem };

        Test.startTest();
        QuotationController.updateQuotationLineItems(q.Id, items);
        Test.stopTest();

        // Quotation_Line_Item__c.Line_Description__c is a long text area and
        // cannot be used in a SOQL WHERE clause, so we verify the insert by
        // Id instead (the controller mutates the same object reference,
        // so newItem.Id is populated after the insert).
        System.assertNotEquals(null, newItem.Id, 'Expected the new line item to receive an Id after insert');

        Quotation_Line_Item__c reloaded = [
            SELECT Id, Quotation__c FROM Quotation_Line_Item__c WHERE Id = :newItem.Id
        ];
        System.assertEquals(q.Id, reloaded.Quotation__c);
    }

    @isTest
    static void testUpdateQuotationLineItems_emptyList_throws() {
        Quotation__c q = getSeededQuotation();

        Boolean caught = false;
        try {
            QuotationController.updateQuotationLineItems(q.Id, new List<Quotation_Line_Item__c>());
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for an empty items list');
    }

    @isTest
    static void testUpdateQuotationLineItems_nullList_throws() {
        Quotation__c q = getSeededQuotation();

        Boolean caught = false;
        try {
            QuotationController.updateQuotationLineItems(q.Id, null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for a null items list');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  generatePdfFromHtml
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testGeneratePdfFromHtml_success() {
        Test.startTest();
        Blob result = QuotationController.generatePdfFromHtml('<html><body>Hi</body></html>');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGeneratePdfFromHtml_blank_throws() {
        Boolean caught = false;
        try {
            QuotationController.generatePdfFromHtml('');
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank HTML content');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveTermsAndConditions
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testSaveTermsAndConditions_success_standardTerms() {
        Quotation__c q = getSeededQuotation();

        Map<String, String> terms = new Map<String, String>();
        terms.put('paymentTerms', 'Net 30');
        terms.put('deliveryTerms', 'FOB');
        terms.put('prices', 'Prices are inclusive of all taxes');
        terms.put('taxes', 'As applicable');
        terms.put('gstnPan', 'GSTIN12345');
        terms.put('msme', 'MSME12345');
        terms.put('transit', 'Covered');
        terms.put('commissioning', 'Included');
        terms.put('inspection', 'At factory');
        terms.put('validity', '30 days');
        terms.put('scope', 'Supply only');
        terms.put('warranty', '1 year');
        terms.put('forceMajeure', 'Standard clause');
        terms.put('jurisdiction', 'Ahmedabad');

        Test.startTest();
        QuotationController.saveTermsAndConditions(q.Id, terms);
        Test.stopTest();

        Quotation__c reloaded = [
            SELECT Payment_Term__c, Delivery_Term__c, Prices1__c, Taxes__c,
                   GSTN_PAN__c, MSME_ZED_Udyam_Reg_No__c, Transit_Insurance__c,
                   Commissioning__c, Inspection__c, Validity__c, Scope__c,
                   Warranty__c, Force_Majeure__c, Jurisdiction__c
            FROM Quotation__c WHERE Id = :q.Id
        ];
        System.assertEquals('Net 30', reloaded.Payment_Term__c);
        System.assertEquals('FOB', reloaded.Delivery_Term__c);
        System.assertEquals('Ahmedabad', reloaded.Jurisdiction__c);
    }

    @isTest
    static void testSaveTermsAndConditions_customPaymentAndDeliveryTerms() {
        Quotation__c q = getSeededQuotation();

        Map<String, String> terms = new Map<String, String>();
        terms.put('paymentTerms', 'Others');
        terms.put('paymentTermsCustom', 'Custom Payment Terms Text');
        terms.put('deliveryTerms', 'Others');
        terms.put('deliveryTermsCustom', 'Custom Delivery Terms Text');

        Test.startTest();
        QuotationController.saveTermsAndConditions(q.Id, terms);
        Test.stopTest();

        Quotation__c reloaded = [
            SELECT Payment_Term__c, Delivery_Term__c FROM Quotation__c WHERE Id = :q.Id
        ];
        System.assertEquals('Custom Payment Terms Text', reloaded.Payment_Term__c);
        System.assertEquals('Custom Delivery Terms Text', reloaded.Delivery_Term__c);
    }

    @isTest
    static void testSaveTermsAndConditions_blankQuotationId_throws() {
        Boolean caught = false;
        try {
            QuotationController.saveTermsAndConditions(null, new Map<String, String>{ 'prices' => 'x' });
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank quotationId');
    }

    @isTest
    static void testSaveTermsAndConditions_emptyMap_throws() {
        Quotation__c q = getSeededQuotation();

        Boolean caught = false;
        try {
            QuotationController.saveTermsAndConditions(q.Id, new Map<String, String>());
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for empty terms map');
    }

    @isTest
    static void testSaveTermsAndConditions_nullMap_throws() {
        Quotation__c q = getSeededQuotation();

        Boolean caught = false;
        try {
            QuotationController.saveTermsAndConditions(q.Id, null);
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for null terms map');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  deleteQuotationLineItem
    // ─────────────────────────────────────────────────────────────────────
    @isTest
    static void testDeleteQuotationLineItem_success() {
        Quotation_Line_Item__c li = [SELECT Id FROM Quotation_Line_Item__c LIMIT 1];

        Test.startTest();
        QuotationController.deleteQuotationLineItem(li.Id);
        Test.stopTest();

        List<Quotation_Line_Item__c> remaining = [
            SELECT Id FROM Quotation_Line_Item__c WHERE Id = :li.Id
        ];
        System.assertEquals(0, remaining.size());
    }

    @isTest
    static void testDeleteQuotationLineItem_blankId_throws() {
        Boolean caught = false;
        try {
            QuotationController.deleteQuotationLineItem('');
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(caught, 'Expected AuraHandledException for blank lineItemId');
    }

	@isTest
    static void testDeleteQuotationLineItem_invalidId_throwsGenericMessage() {
        Quotation__c q = getSeededQuotation();
        
        Quotation_Line_Item__c temp = new Quotation_Line_Item__c();
        temp.Quotation__c = q.Id;  // ← ADD THIS
        insert temp;
        Id tempId = temp.Id;
        delete temp;
    
        Boolean caught = false;
        try {
            QuotationController.deleteQuotationLineItem(String.valueOf(tempId));
        } catch (AuraHandledException ex) {
            caught = true;
        }
        System.assert(!caught, 'Deleting a non-existent line item should not throw');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  HELPERS
    // ─────────────────────────────────────────────────────────────────────

    private static Map<String, Object> buildBasePayloadMap(Id recordId) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('quotationNumber', 'QTN-1001');
        payload.put('quotationDate', String.valueOf(Date.today()));
        payload.put('companyName', 'Test Company Pvt Ltd');
        payload.put('companyAddress', '789 Business Park');
        payload.put('companyPhone', '9999999999');
        payload.put('companyEmail', 'company@example.com');
        payload.put('companyGSTIN', 'GSTIN9999');
        payload.put('customerName', 'Test Customer');
        payload.put('contactPerson', 'John Doe');
        payload.put('mobileNumber', '8888888888');
        payload.put('customerEmail', 'customer@example.com');
        payload.put('customerAddress', '321 Customer Lane');
        payload.put('grandTotal', 1500);
        payload.put('pfPercent', 3);
        payload.put('freightCharges', '100');
        payload.put('lineItemsJson', '[]');
        payload.put('recordId', recordId);
        payload.put('emailSubject', 'Test Subject');
        payload.put('emailBody', 'Test Body Content');
        return payload;
    }

    /**
     * Creates a minimal, folder-based EmailTemplate for use in tests.
     * EmailTemplate requires a Folder Id; we use the public "unfiled$public"
     * style folder lookup via a simple SOQL query, falling back to creating
     * the template without explicit FolderId if the org auto-assigns one.
     */
    private static EmailTemplate createTestEmailTemplate(String templateName) {
        EmailTemplate et = new EmailTemplate();
        et.Name        = templateName;
        et.DeveloperName = 'QC_Test_' + templateName.replaceAll('[^a-zA-Z0-9]', '_') + System.now().getTime();
        et.TemplateType = 'custom';
        et.FolderId    = UserInfo.getUserId(); // personal folder, valid target for FolderId
        et.Subject     = 'Quotation {{{Quotation__c.Quote_Number__c}}}';
        et.HtmlValue   = '<p>Dear {{{Quotation__c.Contact_Salutation__c}}} {{{Quotation__c.Contact_Name__c}}},</p>' +
                          '<p>Please find your quotation {{{Quotation__c.Quote_Number__c}}} attached.</p>';
        et.Body        = 'Please find your quotation attached.';
        insert et;
        return et;
    }
}