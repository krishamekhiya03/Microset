/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaInquiryQueueableTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaInquiryQueueable
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaInquiryQueueableTest {

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
       Mock: Error / Failure Callout
    --------------------------------------- */
    private class TradeIndiaInquiryErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error","message":"Internal Server Error"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /* ---------------------------------------
       Test 1: Queueable executes successfully
    --------------------------------------- */
    @isTest
    static void testQueueable_ExecutesSuccessfully() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            System.enqueueJob(new TradeIndiaInquiryQueueable());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testQueueable_ExecutesSuccessfully FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 2: Direct execute() call
    --------------------------------------- */
    @isTest
    static void testQueueable_DirectExecute() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            TradeIndiaInquiryQueueable job = new TradeIndiaInquiryQueueable();
            job.execute(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testQueueable_DirectExecute FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 3: Handles server error gracefully
    --------------------------------------- */
    @isTest
    static void testQueueable_HandlesServerError() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquiryErrorMock());
            Test.startTest();
            System.enqueueJob(new TradeIndiaInquiryQueueable());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testQueueable_HandlesServerError FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 4: Enqueue job returns valid job ID
    --------------------------------------- */
    @isTest
    static void testQueueable_ReturnsValidJobId() {
        Boolean isValid     = false;
        String errorMessage = '';

        try {
            Test.setMock(HttpCalloutMock.class, new TradeIndiaInquirySuccessMock());
            Test.startTest();
            Id jobId = System.enqueueJob(new TradeIndiaInquiryQueueable());
            Test.stopTest();

            if (jobId != null) {
                isValid = true;
            } else {
                errorMessage = 'Job ID is null after enqueue';
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testQueueable_ReturnsValidJobId FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 5: Exception inside execute()
       is caught and does not propagate
    --------------------------------------- */
    @isTest
    static void testQueueable_InternalExceptionHandled() {
        Boolean exceptionThrown = false;
        String errorMessage     = '';

        try {
            // No mock set — callout will throw internally
            // execute() catches it via try/catch so job should not fail
            Test.startTest();
            TradeIndiaInquiryQueueable job = new TradeIndiaInquiryQueueable();
            job.execute(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage    = e.getMessage();
        }

        if (exceptionThrown) {
            throw new AuraHandledException('testQueueable_InternalExceptionHandled FAILED: ' + errorMessage);
        }
    }
}