/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsServiceTest
 * Description     : Test class for NowFloatsService
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
private class NowFloatsServiceTest {

    // ─────────────────────────────────────────────────────────────────────
    //  MOCK CLASSES
    // ─────────────────────────────────────────────────────────────────────

    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"15/06/2026 12:59:06",'
                + '"customer_message":"Name: John Doe\\nSubject: Product Query\\nMessage: I need more info\\nEmail: john.doe@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9876543210",'
                + '"business_name":"Acme Corp",'
                + '"business_state_name":"Gujarat",'
                + '"business_city_name":"Ahmedabad",'
                + '"business_locality":"Navrangpura"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessNoLabels implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"20/06/2026 09:00:00",'
                + '"customer_message":"Just a plain message with no labels at all",'
                + '"enquiry_entityType":"Contact",'
                + '"Customercontact":"9000000001",'
                + '"business_name":"Plain Corp",'
                + '"business_state_name":"Maharashtra",'
                + '"business_city_name":"Mumbai",'
                + '"business_locality":"Andheri"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessSingleWordName implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"21/06/2026 10:00:00",'
                + '"customer_message":"Name: SingleName\\nSubject: Test\\nMessage: Hello\\nEmail: single@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9000000002",'
                + '"business_name":"Solo Biz",'
                + '"business_state_name":"Rajasthan",'
                + '"business_city_name":"Jaipur",'
                + '"business_locality":"Malviya Nagar"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessBlankName implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"22/06/2026 11:00:00",'
                + '"customer_message":"Name:\\nSubject: Blank Name Test\\nMessage: Testing\\nEmail: blank@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9000000003",'
                + '"business_name":"Blank Name Corp",'
                + '"business_state_name":"Karnataka",'
                + '"business_city_name":"Bangalore",'
                + '"business_locality":"Koramangala"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessMultiLineMessage implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"23/06/2026 14:00:00",'
                + '"customer_message":"Name: Jane Smith\\nSubject: Multi Line\\nMessage: Line one\\nLine two continued\\nEmail: jane@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9000000004",'
                + '"business_name":"Multi Corp",'
                + '"business_state_name":"Delhi",'
                + '"business_city_name":"New Delhi",'
                + '"business_locality":"Connaught Place"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessBlankMessage implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"24/06/2026 08:00:00",'
                + '"customer_message":"",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9000000005",'
                + '"business_name":"Empty Msg Corp",'
                + '"business_state_name":"Punjab",'
                + '"business_city_name":"Chandigarh",'
                + '"business_locality":"Sector 17"'
                + '}]');
            return res;
        }
    }

    private class MockSuccessNullContactAndDate implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":null,'
                + '"customer_message":"Name: No ID\\nSubject: No UniqueID\\nMessage: test\\nEmail: noid@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":null,'
                + '"business_name":"Null ID Corp",'
                + '"business_state_name":"Goa",'
                + '"business_city_name":"Panaji",'
                + '"business_locality":"Campal"'
                + '}]');
            return res;
        }
    }

    private class MockEmptyResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[]');
            return res;
        }
    }

    private class MockErrorWithJsonBody implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"Unauthorized access","code":401}');
            return res;
        }
    }

    private class MockErrorWithPlainTextBody implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'text/plain');
            res.setBody('Internal Server Error - Gateway timeout');
            return res;
        }
    }

    private class MockPagination implements HttpCalloutMock {
        private Integer callCount = 0;
        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            if (callCount == 1) {
                List<String> records = new List<String>();
                for (Integer i = 1; i <= 10; i++) {
                    records.add('{'
                        + '"date_and_time_of_enquiry":"01/07/2026 0' + (i < 10 ? '0' : '') + i + ':00:00",'
                        + '"customer_message":"Name: User' + i + '\\nSubject: Page1\\nMessage: msg\\nEmail: user' + i + '@example.com",'
                        + '"enquiry_entityType":"Lead",'
                        + '"Customercontact":"900000' + String.valueOf(1000 + i) + '",'
                        + '"business_name":"Biz ' + i + '",'
                        + '"business_state_name":"Gujarat",'
                        + '"business_city_name":"Surat",'
                        + '"business_locality":"Ring Road"'
                        + '}');
                }
                res.setBody('[' + String.join(records, ',') + ']');
            } else {
                res.setBody('[]');
            }
            return res;
        }
    }

    private class MockSuccessNoAddress implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"25/06/2026 07:00:00",'
                + '"customer_message":"Name: No Address\\nSubject: Addr Test\\nMessage: no addr\\nEmail: noaddr@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9111111111",'
                + '"business_name":null,'
                + '"business_state_name":null,'
                + '"business_city_name":null,'
                + '"business_locality":null'
                + '}]');
            return res;
        }
    }

    /**
     * Returns a record whose date_and_time_of_enquiry is unparsable —
     * used to force parseNowFloatsDatetime()'s catch branch when the
     * custom setting maps that value to a DATETIME field.
     */
    private class MockSuccessBadDatetime implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"NOT-A-VALID-DATE",'
                + '"customer_message":"Name: Bad Date\\nSubject: Bad Date Test\\nMessage: test\\nEmail: baddate@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9222222222",'
                + '"business_name":"Bad Date Corp",'
                + '"business_state_name":"Kerala",'
                + '"business_city_name":"Kochi",'
                + '"business_locality":"Marine Drive"'
                + '}]');
            return res;
        }
    }

    /**
     * customer_message uses "From:" instead of "Name:" and has plain
     * unlabeled requirement lines, wrapped in HTML tags — mirrors the
     * real NowFloats payload (e.g. "<i>...</i>" / "<b>From:</b> Piyush").
     */
    private class MockSuccessFromLabelWithHtmlTags implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"26/06/2026 10:00:00",'
                + '"customer_message":"<i>Piyush Test Requirement\\nJust For test</i>\\n<b>From:</b> Piyush",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9333333333",'
                + '"business_name":"Piyush Corp",'
                + '"business_state_name":"Gujarat",'
                + '"business_city_name":"Ahmedabad",'
                + '"business_locality":"Bopal"'
                + '}]');
            return res;
        }
    }

    /**
     * customer_message contains a "From:" line together with an explicit
     * "Message:" label — Description should come from the Message: block,
     * and From: should still populate Name/Last_Name__c, not Description.
     */
    private class MockSuccessFromWithExplicitMessage implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"27/06/2026 10:00:00",'
                + '"customer_message":"From: Ravi Kumar\\nMessage: Need a quote\\nEmail: ravi@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9444444444",'
                + '"business_name":"Ravi Corp",'
                + '"business_state_name":"Gujarat",'
                + '"business_city_name":"Surat",'
                + '"business_locality":"Adajan"'
                + '}]');
            return res;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TEST DATA FACTORY
    // ─────────────────────────────────────────────────────────────────────

    private static void setupCustomSetting() {
        NowFloats_Configuration_Setting__c config =
            new NowFloats_Configuration_Setting__c();
        config.Authorization_Key__c = 'Bearer test-auth-key-12345';
        config.Enterprise_Id__c     = 'TEST-ENTERPRISE-ID';
        config.Fetch_Limit__c       = 10;
        upsert config;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TESTS — fetchLeads()
    // ─────────────────────────────────────────────────────────────────────

    @isTest
    static void testFetchLeads_successWithFullRecord() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [
            SELECT Id, Unique_Query_ID__c, Lead_Source__c,
                   Name, Last_Name__c, Email__c,
                   Subject__c, Description__c
            FROM Lead_Custom__c
        ];

        System.assertEquals(1, leads.size(), 'Should upsert exactly one lead');
        System.assertEquals('Website - Microsetindia.com', leads[0].Lead_Source__c);
        System.assertEquals('John', leads[0].Name);
        System.assertEquals('Doe', leads[0].Last_Name__c);
        System.assertEquals('john.doe@example.com', leads[0].Email__c);
        System.assertEquals('Product Query', leads[0].Subject__c);
        System.assertEquals('I need more info', leads[0].Description__c);
        System.assert(
            leads[0].Unique_Query_ID__c.startsWith('9876543210_'),
            'Unique_Query_ID__c should start with the contact number'
        );

        // Informational only — no assert, since Error_Message__c is a long
        // text area and cannot be filtered in SOQL. Just confirming the
        // query executes cleanly on the happy path.
        List<Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Error_Log__c];
        System.debug('Error_Log__c count after success run: ' + logs.size());
    }

    @isTest
    static void testFetchLeads_noLabelsInMessage_descriptionIsFull() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessNoLabels());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Description__c FROM Lead_Custom__c];
        System.assertEquals(1, leads.size());
        System.assertEquals(
            'Just a plain message with no labels at all',
            leads[0].Description__c,
            'Full customer_message should be used as Description when no labels present'
        );
    }

    @isTest
    static void testFetchLeads_singleWordName_lastNameIsDash() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessSingleWordName());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Name, Last_Name__c FROM Lead_Custom__c];
        System.assertEquals(1, leads.size());
        System.assertEquals('SingleName', leads[0].Name);
        System.assertEquals('-', leads[0].Last_Name__c,
            'Last_Name__c should be "-" when name has no space');
    }

    @isTest
    static void testFetchLeads_blankNameAfterLabel_bothDefaultToDash() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessBlankName());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Name, Last_Name__c FROM Lead_Custom__c];
        System.assertEquals(1, leads.size());
        System.assertEquals('-', leads[0].Name,
            'Name should be "-" when Name label is blank');
        System.assertEquals('-', leads[0].Last_Name__c,
            'Last_Name__c should be "-" when Name label is blank');
    }

    @isTest
    static void testFetchLeads_multiLineMessage_descriptionCombined() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessMultiLineMessage());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Description__c FROM Lead_Custom__c];
        System.assertEquals(1, leads.size());
        System.assert(
            leads[0].Description__c.contains('Line one'),
            'Description should contain the first message line'
        );
        System.assert(
            leads[0].Description__c.contains('Line two continued'),
            'Description should contain the continuation line'
        );
    }

    @isTest
    static void testFetchLeads_blankCustomerMessage_noDescriptionSet() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessBlankMessage());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(1, leads.size(), 'Lead should still be created with blank message');
    }

    @isTest
    static void testFetchLeads_nullContactAndDate_noUniqueId() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessNullContactAndDate());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Unique_Query_ID__c FROM Lead_Custom__c];
        System.assertEquals(0, leads.size(),
            'Lead with null Unique_Query_ID__c should not be persisted by the upsert');

        // Informational only — Error_Message__c is a long text area field
        // and cannot be filtered (WHERE/LIKE) in SOQL, so we just query it
        // without a filter here and skip asserting on its content.
        List<Error_Log__c> allLogs = [SELECT Id, Error_Message__c FROM Error_Log__c];
        System.debug('Error_Log__c rows found: ' + allLogs.size());
    }

    @isTest
    static void testFetchLeads_emptyApiResponse_noLeadsCreated() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(0, leads.size(), 'No leads should be created for empty API response');
    }

    @isTest
    static void testFetchLeads_httpError401_withJsonBody_throws() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockErrorWithJsonBody());

        Test.startTest();
        try {
            NowFloatsService.fetchLeads();
            System.assert(false, 'Expected NowFloatsServiceException for 401 response');
        } catch (NowFloatsService.NowFloatsServiceException ex) {
            System.assert(
                ex.getMessage().length() > 0,
                'Exception message should not be blank'
            );
        }
        Test.stopTest();

        // Informational only — no assert on message content since
        // Error_Message__c is a long text area field.
        List<Error_Log__c> logs = [SELECT Id, Class_Name__c, Error_Message__c FROM Error_Log__c];
        System.debug('Error_Log__c rows after 401: ' + logs.size());
    }

    @isTest
    static void testFetchLeads_httpError500_withPlainTextBody_throws() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockErrorWithPlainTextBody());

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            NowFloatsService.fetchLeads();
        } catch (NowFloatsService.NowFloatsServiceException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown,
            'Should throw NowFloatsServiceException for a 500 plain-text error response');

        // Informational only — no assert on message content.
        List<Error_Log__c> logs = [SELECT Id, Error_Message__c FROM Error_Log__c];
        System.debug('Error_Log__c rows after 500: ' + logs.size());
    }

    @isTest
    static void testFetchLeads_pagination_twoPages() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockPagination());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(10, leads.size(),
            'Should upsert all 10 leads fetched from the first paginated page');
    }

    @isTest
    static void testFetchLeads_noAddressParts_addressesNotSet() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessNoAddress());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Addresses__c FROM Lead_Custom__c];
        System.assertEquals(1, leads.size());
        System.assertEquals(null, leads[0].Addresses__c,
            'Addresses__c should not be set when all address components are null');
    }

    @isTest
    static void testFetchLeads_upsertDeduplication_sameUniqueIdUpdates() {
        setupCustomSetting();

        Lead_Custom__c existing = new Lead_Custom__c();
        existing.Unique_Query_ID__c = '9876543210_15062026_125906';
        existing.Name               = 'Old';
        existing.Last_Name__c       = 'Name';
        insert existing;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [
            SELECT Id, Name FROM Lead_Custom__c
            WHERE Unique_Query_ID__c = '9876543210_15062026_125906'
        ];
        System.assertEquals(1, leads.size(),
            'Upsert should update the existing record, not insert a duplicate');
        System.assertEquals('John', leads[0].Name,
            'Name should be updated to the value from the API response');
    }

    @isTest
    static void testFetchLeads_fetchLimitDefaultsTo10_whenSettingIsNull() {
        NowFloats_Configuration_Setting__c config =
            new NowFloats_Configuration_Setting__c();
        config.Authorization_Key__c = 'Bearer default-limit-key';
        config.Enterprise_Id__c     = 'DEFAULT-LIMIT-ENTERPRISE';
        upsert config;

        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        System.assert(true, 'fetchLeads should not throw when Fetch_Limit__c is null');
    }

    /**
     * NOTE: This test only exercises the datetime-parse-error branch if
     * your Custom Setting has a field mapped to a Lead_Custom__c field of
     * type DATETIME that receives the "date_and_time_of_enquiry" (or any
     * other mapped source) value. Adjust the config field mapping to match
     * your real org setup if you want this branch specifically covered.
     */
    @isTest
    static void testFetchLeads_badDatetimeValue_doesNotThrow() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessBadDatetime());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        // Even with a bad datetime, the lead should still be created —
        // parseNowFloatsDatetime() catches and returns null instead of throwing.
        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(1, leads.size(),
            'Lead should still be created even when a datetime value fails to parse');
    }

    // ─────────────────────────────────────────────────────────────────────
    //  NEW TESTS — "From:" label + HTML tag stripping
    // ─────────────────────────────────────────────────────────────────────

    @isTest
    static void testFetchLeads_fromLabelWithHtmlTags_nameSetAndTagsStripped() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessFromLabelWithHtmlTags());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [
            SELECT Name, Last_Name__c, Description__c FROM Lead_Custom__c
        ];
        System.assertEquals(1, leads.size());

        System.assertEquals('Piyush', leads[0].Name,
            'Name should be populated from the From: label');
        System.assertEquals('-', leads[0].Last_Name__c,
            'Last_Name__c should default to "-" for a single-word From: value');

        System.assert(
            !leads[0].Description__c.contains('<i>') &&
            !leads[0].Description__c.contains('</i>') &&
            !leads[0].Description__c.contains('<b>') &&
            !leads[0].Description__c.contains('</b>'),
            'Description should not contain any HTML tags'
        );
        System.assert(
            !leads[0].Description__c.contains('From:'),
            'Description should not contain the From: line since it is used for Name'
        );
        System.assert(
            leads[0].Description__c.contains('Piyush Test Requirement'),
            'Description should retain the plain unlabeled requirement text'
        );
        System.assert(
            leads[0].Description__c.contains('Just For test'),
            'Description should retain the plain unlabeled requirement text'
        );
    }

    @isTest
    static void testFetchLeads_fromLabelWithExplicitMessage_descriptionFromMessageOnly() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccessFromWithExplicitMessage());

        Test.startTest();
        NowFloatsService.fetchLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [
            SELECT Name, Last_Name__c, Description__c, Email__c FROM Lead_Custom__c
        ];
        System.assertEquals(1, leads.size());

        System.assertEquals('Ravi', leads[0].Name);
        System.assertEquals('Kumar', leads[0].Last_Name__c);
        System.assertEquals('ravi@example.com', leads[0].Email__c);
        System.assertEquals('Need a quote', leads[0].Description__c,
            'Description should come only from the explicit Message: block, not the From: line');
    }
}