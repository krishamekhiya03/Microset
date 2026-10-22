@isTest
private class TradeIndiaBuyLeadQueueableTest {

    // Generic mock in case fetchBuyLeads() makes an HTTP callout.
    // Harmless if no callout is made.
    private class GenericSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"STATUS":"SUCCESS","RESPONSE":[]}');
            return res;
        }
    }

    @isTest
    static void testExecute_Success() {

        Test.setMock(HttpCalloutMock.class, new GenericSuccessMock());

        Test.startTest();
        System.enqueueJob(new TradeIndiaBuyLeadQueueable());
        Test.stopTest();
    }

    @isTest
    static void testExecute_HandlesExceptionGracefully() {

        // If fetchBuyLeads() throws for any reason (e.g. no mock matching,
        // missing config, etc.), the class's own try-catch should swallow it
        // and the job should still complete without failing the test.
        Test.startTest();
        System.enqueueJob(new TradeIndiaBuyLeadQueueable());
        Test.stopTest();
    }
}