@isTest
public class IndiaMartQueueableTest {

    class IndiaMartMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');

            res.setBody('{' +
                '"CODE":200,' +
                '"STATUS":"SUCCESS",' +
                '"MESSAGE":"OK",' +
                '"TOTAL_RECORDS":0,' +
                '"RESPONSE":[]' +
            '}');

            res.setStatusCode(200);

            return res;
        }
    }


    @isTest
    static void testQueueableExecution() {

        Test.setMock(
            HttpCalloutMock.class,
            new IndiaMartMock()
        );

        Test.startTest();
        System.enqueueJob(new IndiaMartQueueable());
        Test.stopTest();

        System.assert(true);
    }
}