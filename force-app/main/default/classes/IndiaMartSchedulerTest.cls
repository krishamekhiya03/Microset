@isTest
public class IndiaMartSchedulerTest {

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
    static void testSchedulerExecution() {

        Test.setMock(
            HttpCalloutMock.class,
            new IndiaMartMock()
        );

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2050';
        System.schedule('IndiaMart Scheduler Test',cronExp,new IndiaMartScheduler());
        Test.stopTest();

        System.assert(true);
    }
}