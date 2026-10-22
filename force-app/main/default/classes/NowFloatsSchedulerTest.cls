/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsSchedulerTest
 * Description     : Test class for NowFloatsScheduler
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
private class NowFloatsSchedulerTest {

    // ─────────────────────────────────────────────────────────────────────
    //  MOCK
    // ─────────────────────────────────────────────────────────────────────

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
    static void testScheduler_executesAndEnqueuesJob() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        Test.startTest();
        String jobId = System.schedule(
            'NowFloats Test Job',
            '0 0 0 1 1 ? 2099',
            new NowFloatsScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId,
            'schedule() should return a valid CronTrigger Id');

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(),
            'Exactly one scheduled job should exist for this Id');
        System.assertEquals('NowFloats Test Job', jobs[0].CronJobDetail.Name,
            'Scheduled job name should match');
    }

    @isTest
    static void testScheduler_implementsSchedulable() {
        Schedulable s = new NowFloatsScheduler();
        System.assertNotEquals(null, s,
            'NowFloatsScheduler should be assignable to Schedulable');
    }

    @isTest
    static void testScheduler_cronExpression_runsWithoutError() {
        setupCustomSetting();
        Test.setMock(HttpCalloutMock.class, new MockEmptyResponse());

        // Verifies a variety of valid cron expressions are accepted
        // without throwing — covers scheduling at different frequencies.
        List<String> cronExpressions = new List<String>{
            '0 0 * * * ?',       // every hour
            '0 0 8 * * ?',       // daily at 8 AM
            '0 0 0 ? * MON-FRI'  // weekdays at midnight
        };

        Test.startTest();
        for (Integer i = 0; i < cronExpressions.size(); i++) {
            String jobId = System.schedule(
                'NowFloats Cron Test ' + i,
                cronExpressions[i],
                new NowFloatsScheduler()
            );
            System.assertNotEquals(null, jobId,
                'schedule() should return a non-null Id for cron: ' + cronExpressions[i]);
        }
        Test.stopTest();
    }
}