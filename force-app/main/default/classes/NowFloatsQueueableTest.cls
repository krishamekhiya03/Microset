/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsQueueableTest
 * Description     : Test class for NowFloatsQueueable
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
private class NowFloatsQueueableTest {

    // ─────────────────────────────────────────────────────────────────────
    //  MOCK
    // ─────────────────────────────────────────────────────────────────────

    private class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{'
                + '"date_and_time_of_enquiry":"15/06/2026 12:59:06",'
                + '"customer_message":"Name: Test User\\nSubject: Test Subject\\nMessage: Test Message\\nEmail: test@example.com",'
                + '"enquiry_entityType":"Lead",'
                + '"Customercontact":"9876543210",'
                + '"business_name":"Test Corp",'
                + '"business_state_name":"Gujarat",'
                + '"business_city_name":"Ahmedabad",'
                + '"business_locality":"Navrangpura"'
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

    // ─────────────────────────────────────────────────────────────────────
    //  SETUP
    // ─────────────────────────────────────────────────────────────────────

    private static void setupCustomSetting() {
        NowFloats_Configuration_Setting__c config =
            new NowFloats_Configuration_Setting__c();
        config.Authorization_Key__c = 'Bearer test-auth-key';
        config.Enterprise_Id__c     = 'TEST-ENTERPRISE-ID';
        config.Fetch_Limit__c       = 10;
        upsert config;
    }

    // ─────────────────────────────────────────────────────────────────────
    //  TESTS
    // ─────────────────────────────────────────────────────────────────────

    @isTest
    static void testQueueable_executesAndFetchesLeads() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        Test.startTest();
        System.enqueueJob(new NowFloatsQueueable());
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(1, leads.size(),
            'Queueable should trigger fetchLeads and upsert one lead');
    }

    @isTest
    static void testQueueable_emptyResponse_noLeadsCreated() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        Test.startTest();
        System.enqueueJob(new NowFloatsQueueable());
        Test.stopTest();

        List<Lead_Custom__c> leads = [SELECT Id FROM Lead_Custom__c];
        System.assertEquals(0, leads.size(),
            'No leads should be created when API returns empty array');
    }

    @isTest
    static void testQueueable_jobIsEnqueued() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        Test.startTest();
        Id jobId = System.enqueueJob(new NowFloatsQueueable());
        Test.stopTest();

        System.assertNotEquals(null, jobId,
            'enqueueJob should return a valid AsyncApexJob Id');
    }

    @isTest
    static void testQueueable_instantiation() {
        // Verifies the class can be constructed and assigned to both
        // of its interface types without compiler warnings.
        Queueable q = new NowFloatsQueueable();
        Database.AllowsCallouts c = (Database.AllowsCallouts) q;
        System.assertNotEquals(null, q, 'Queueable instance should not be null');
        System.assertNotEquals(null, c, 'AllowsCallouts cast should not be null');
    }
}