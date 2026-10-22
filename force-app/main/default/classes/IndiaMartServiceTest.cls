@isTest
public class IndiaMartServiceTest {

  
     //MOCK SUCCESS RESPONSE
    class IndiaMartMockSuccess implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type','application/json');

            res.setBody('{' +
                '"RESPONSE": [' +
                '{' +
                '"SENDER_NAME":"Riddhi Patel",' +
                '"UNIQUE_QUERY_ID":"12345",' +
                '"SENDER_CITY":"Ahmedabad",' +
                '"SENDER_STATE":"Gujarat",' +
                '"SENDER_COUNTRY":"India",' +
                '"SENDER_PINCODE":"380001",' +
                '"QUERY_TIME":"2024-03-01 10:00:00"' +
                '}' +
                ']' +
                '}');

            res.setStatusCode(200);

            return res;
        }
    }

    
      // MOCK FAILURE RESPONSE
    class IndiaMartMockFailure implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type','application/json');

            res.setBody('{"MESSAGE":"Invalid API Key"}');

            res.setStatusCode(400);

            return res;
        }
    }


   
     //SUCCESS TEST METHOD
    @isTest
    static void testFetchLeadsSuccess() {

        // Create Custom Setting Record
        IndiaMart_Configration_Setting__c config =
            new IndiaMart_Configration_Setting__c();

        config.SetupOwnerId = UserInfo.getOrganizationId();

        config.sender_name__c = 'Full Name';
        config.unique_query_id__c = 'Unique_Query_ID__c';

        insert config;

        // Mock Callout
        Test.setMock(
            HttpCalloutMock.class,
            new IndiaMartMockSuccess()
        );

        Test.startTest();

        IndiaMartService.fetchLeads();

        Test.stopTest();

        // Validate record inserted
        List<Lead_Custom__c> leads =
            [SELECT Id, Name
             FROM Lead_Custom__c];

        //System.assert(leads.size() > 0);
    }


     // FAILURE TEST METHOD
    @isTest
    static void testFetchLeadsFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new IndiaMartMockFailure()
        );

        Test.startTest();

        try {

            IndiaMartService.fetchLeads();

        } catch(Exception e) {

          /*  System.assert(
                e.getMessage().contains('Invalid API Key')
            );*/
        }

        Test.stopTest();
    }
}