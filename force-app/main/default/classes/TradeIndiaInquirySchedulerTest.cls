/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaInquirySchedulerTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaInquiryScheduler
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaInquirySchedulerTest {

    /* ---------------------------------------
       Mock: Success Callout
    --------------------------------------- */
    private class TradeIndiaInquirySuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /* ---------------------------------------
       Test 1: Scheduler executes successfully
    --------------------------------------- */
    @isTest
    static void testScheduler_ExecutesSuccessfully() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            String cronExp = '0 0 0 * * ?';
            System.schedule('TradeIndiaInquirySchedulerTest_Job', cronExp, new TradeIndiaInquiryScheduler());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_ExecutesSuccessfully FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 2: Scheduler enqueues Queueable job
    --------------------------------------- */
    @isTest
    static void testScheduler_EnqueuesQueueableJob() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            String cronExp = '0 0 1 * * ?';
            System.schedule('TradeIndiaInquirySchedulerTest_Enqueue', cronExp, new TradeIndiaInquiryScheduler());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_EnqueuesQueueableJob FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 3: Scheduler can be scheduled
       multiple times with different job names
    --------------------------------------- */
    @isTest
    static void testScheduler_MultipleSchedules() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            System.schedule('TradeIndiaInquirySchedulerTest_Job1', '0 0 2 * * ?', new TradeIndiaInquiryScheduler());
            System.schedule('TradeIndiaInquirySchedulerTest_Job2', '0 0 3 * * ?', new TradeIndiaInquiryScheduler());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_MultipleSchedules FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 4: Direct execute() call via
       SchedulableContext (manual trigger)
    --------------------------------------- */
    @isTest
    static void testScheduler_DirectExecute() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            TradeIndiaInquiryScheduler scheduler = new TradeIndiaInquiryScheduler();
            scheduler.execute(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_DirectExecute FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 5: Scheduled job returns valid Job ID
    --------------------------------------- */
    @isTest
    static void testScheduler_ReturnsValidJobId() {
        Boolean isValid     = false;
        String errorMessage = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            Id jobId = System.schedule('TradeIndiaInquirySchedulerTest_JobId', '0 0 5 * * ?', new TradeIndiaInquiryScheduler());
            Test.stopTest();

            if (jobId != null) {
                isValid = true;
            } else {
                errorMessage = 'Job ID is null after schedule';
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testScheduler_ReturnsValidJobId FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 6: Scheduled job can be aborted
    --------------------------------------- */
    @isTest
    static void testScheduler_JobCanBeAborted() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            String jobId = System.schedule('TradeIndiaInquirySchedulerTest_Abort', '0 0 4 * * ?', new TradeIndiaInquiryScheduler());
            System.abortJob(jobId);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testScheduler_JobCanBeAborted FAILED: ' + errorMessage);
        }
    }
}