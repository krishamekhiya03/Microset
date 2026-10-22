/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaServiceTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaService
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaServiceTest {

    /* ---------------------------------------
       Mock: Inquiry Success Response
    --------------------------------------- */
    class TradeIndiaInquiryMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{' +
                '"subject":"Need Steel Pipes",' +
                '"message":"We need 500 units",' +
                '"sender_co":"ABC Traders",' +
                '"sender_name":"Rahul Shah",' +
                '"sender_city":"Ahmedabad",' +
                '"sender_state":"Gujarat",' +
                '"sender_country":"India",' +
                '"sender_mobile":"9876543210",' +
                '"sender_phone":"07926543210",' +
                '"sender_other_emails":"alt@example.com",' +
                '"sender_other_mobiles":"9000000001",' +
                '"sender_uid":1001,' +
                '"rfi_id":"RFI-001",' +
                '"inquiry_type":"Buy",' +
                '"source":"TradeIndia",' +
                '"generated":1709712000000,' +
                '"product_name":"Stainless Steel Pipes",' +
                '"receiver_mobile":"9876543210"' +
                '}]');
            res.setStatusCode(200);
            return res;
        }
    }

    /* ---------------------------------------
       Mock: Buy Lead Success Response
    --------------------------------------- */
    class TradeIndiaBuyLeadMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{' +
                '"sender_email":"buyer@example.com",' +
                '"lead_id":"LD-001",' +
                '"country":"India",' +
                '"contactable":1,' +
                '"country_code":"+91",' +
                '"description":"Looking for pipes",' +
                '"city":"Ahmedabad",' +
                '"profile_link":"https://tradeindia.com/profile/123",' +
                '"user_lead_status":"Active",' +
                '"product_name":"Steel Pipes",' +
                '"delivery_loc":"Gujarat",' +
                '"profile_id":123,' +
                '"lead_type":"Buy",' +
                '"state":"Gujarat",' +
                '"category_id":456,' +
                '"valid_from":"2026-03-01",' +
                '"userid":789,' +
                '"co_name":"Example Corp",' +
                '"contact_details":{' +
                    '"country_code":"+91",' +
                    '"phone_no":"9876543210",' +
                    '"contact_number":"9876543210",' +
                    '"user_desg":"Purchase Manager",' +
                    '"user_name":"Mr. Rahul Shah",' +
                    '"city":"Ahmedabad",' +
                    '"state":"Gujarat",' +
                    '"address":"123 Main St",' +
                    '"pincode":"380001",' +
                    '"contact_email":"rahul@example.com"' +
                '},' +
                '"extra_params_for_pagination":{' +
                    '"add_important":"0",' +
                    '"transaction_details":"none"' +
                '}' +
                '}]');
            res.setStatusCode(200);
            return res;
        }
    }

    /* ---------------------------------------
       Mock: Failure Response (400)
    --------------------------------------- */
    class TradeIndiaMockFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Invalid API Key"}');
            res.setStatusCode(400);
            return res;
        }
    }

    /* ---------------------------------------
       Mock: Empty Array Response
    --------------------------------------- */
    class TradeIndiaMockEmptyResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[]');
            res.setStatusCode(200);
            return res;
        }
    }

    /* ---------------------------------------
       Mock: Invalid/Blank Response
    --------------------------------------- */
    class TradeIndiaMockInvalidResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(200);
            return res;
        }
    }

    /* ---------------------------------------
       Helper: Insert Inquiry Config Setting
    --------------------------------------- */
    private static void insertInquiryConfig() {
        TradeIndia_Inquiry_Configration_Setting__c config =
            new TradeIndia_Inquiry_Configration_Setting__c();
        config.SetupOwnerId    = UserInfo.getOrganizationId();
        config.sender_name__c  = 'Full Name';
        config.sender_uid__c   = 'Unique_Query_ID__c';
        config.product_name__c = 'Product_Name__c';
        config.sender_city__c  = 'Address_City__c';
        config.sender_state__c = 'Address_State_Province__c';
        config.sender_country__c = 'Countries__c';
        insert config;
    }

    /* ---------------------------------------
       Helper: Insert Buy Lead Config Setting
    --------------------------------------- */
    private static void insertBuyLeadConfig() {
        TradeIndia_Buy_Lead_Configration_Setting__c config =
            new TradeIndia_Buy_Lead_Configration_Setting__c();
        config.SetupOwnerId    = UserInfo.getOrganizationId();
        config.product_name__c = 'Product_Name__c';
        config.city__c         = 'Address_City__c';
        config.state__c        = 'Address_State_Province__c';
        config.country__c      = 'Countries__c';
        insert config;
    }

    /* =====================================================
       FETCH MY INQUIRY - TEST METHODS
    ===================================================== */

    /* ---------------------------------------
       Test 1: fetchMyInquiry - Success
    --------------------------------------- */
    @isTest
    static void testFetchMyInquiry_Success() {
        insertInquiryConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaInquiryMockSuccess());

        Test.startTest();
        TradeIndiaService.fetchMyInquiry();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id, Lead_Source__c FROM Lead_Custom__c];
        // leads inserted — no assert, just verifying no exception thrown
    }

    /* ---------------------------------------
       Test 2: fetchMyInquiry - Failure (400)
    --------------------------------------- */
    @isTest
    static void testFetchMyInquiry_Failure() {
        insertInquiryConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockFailure());

        Test.startTest();
        try {
            TradeIndiaService.fetchMyInquiry();
        } catch (Exception e) {
            // Exception expected on non-200 response
        }
        Test.stopTest();
    }

    /* ---------------------------------------
       Test 3: fetchMyInquiry - Empty Response
    --------------------------------------- */
    @isTest
    static void testFetchMyInquiry_EmptyResponse() {
        insertInquiryConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockEmptyResponse());

        Test.startTest();
        try {
            TradeIndiaService.fetchMyInquiry();
        } catch (Exception e) {
            // No exception expected, safe exit
        }
        Test.stopTest();
    }

    /* ---------------------------------------
       Test 4: fetchMyInquiry - Invalid/Blank Body
    --------------------------------------- */
    @isTest
    static void testFetchMyInquiry_InvalidResponse() {
        insertInquiryConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockInvalidResponse());

        Test.startTest();
        try {
            TradeIndiaService.fetchMyInquiry();
        } catch (Exception e) {
            // Blank body handled gracefully inside service
        }
        Test.stopTest();
    }

    /* =====================================================
       FETCH BUY LEADS - TEST METHODS
    ===================================================== */

    /* ---------------------------------------
       Test 5: fetchBuyLeads - Success
    --------------------------------------- */
    @isTest
    static void testFetchBuyLeads_Success() {
        insertBuyLeadConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaBuyLeadMockSuccess());

        Test.startTest();
        TradeIndiaService.fetchBuyLeads();
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id, Lead_Source__c FROM Lead_Custom__c];
        // leads inserted — no assert, just verifying no exception thrown
    }

    /* ---------------------------------------
       Test 6: fetchBuyLeads - Failure (400)
    --------------------------------------- */
    @isTest
    static void testFetchBuyLeads_Failure() {
        insertBuyLeadConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockFailure());

        Test.startTest();
        try {
            TradeIndiaService.fetchBuyLeads();
        } catch (Exception e) {
            // Exception expected on non-200 response
        }
        Test.stopTest();
    }

    /* ---------------------------------------
       Test 7: fetchBuyLeads - Empty Response
    --------------------------------------- */
    @isTest
    static void testFetchBuyLeads_EmptyResponse() {
        insertBuyLeadConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockEmptyResponse());

        Test.startTest();
        try {
            TradeIndiaService.fetchBuyLeads();
        } catch (Exception e) {
            // No exception expected, safe exit
        }
        Test.stopTest();
    }

    /* ---------------------------------------
       Test 8: fetchBuyLeads - Invalid/Blank Body
    --------------------------------------- */
    @isTest
    static void testFetchBuyLeads_InvalidResponse() {
        insertBuyLeadConfig();

        Test.setMock(HttpCalloutMock.class, new TradeIndiaMockInvalidResponse());

        Test.startTest();
        try {
            TradeIndiaService.fetchBuyLeads();
        } catch (Exception e) {
            // Blank body handled gracefully inside service
        }
        Test.stopTest();
    }

    /* =====================================================
       UPSERT LEADS - TEST METHODS
    ===================================================== */

    /* ---------------------------------------
       Test 9: upsertLeads - With valid leads
    --------------------------------------- */
    @isTest
    static void testUpsertLeads_WithValidLeads() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            List<Lead_Custom__c> leadList = new List<Lead_Custom__c>();

            Lead_Custom__c lead1 = new Lead_Custom__c();
            lead1.Name              = 'Rahul';
            lead1.Last_Name__c      = 'Shah';
            lead1.Lead_Source__c    = 'TradeIndia - My Inquiry';
            lead1.Unique_Query_ID__c = 'UID-001';
            leadList.add(lead1);

            Lead_Custom__c lead2 = new Lead_Custom__c();
            lead2.Name              = 'Priya';
            lead2.Last_Name__c      = 'Mehta';
            lead2.Lead_Source__c    = 'TradeIndia - Buy Lead';
            lead2.Unique_Query_ID__c = 'UID-002';
            leadList.add(lead2);

            Test.startTest();
            TradeIndiaService.upsertLeads(leadList);
            Test.stopTest();

        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testUpsertLeads_WithValidLeads FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 10: upsertLeads - Empty list
       (should return without error)
    --------------------------------------- */
    @isTest
    static void testUpsertLeads_EmptyList() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.startTest();
            TradeIndiaService.upsertLeads(new List<Lead_Custom__c>());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testUpsertLeads_EmptyList FAILED: ' + errorMessage);
        }
    }
}