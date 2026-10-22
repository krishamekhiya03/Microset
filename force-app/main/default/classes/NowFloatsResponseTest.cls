/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsResponseTest
 * Description     : Test class for NowFloatsResponse
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
private class NowFloatsResponseTest {

    @isTest
    static void testParseWithAllFields() {
        String jsonStr = '[{'
            + '"date_and_time_of_enquiry": "2025-06-17 10:30:00",'
            + '"customer_message": "I am interested in your product",'
            + '"enquiry_entityType": "Lead",'
            + '"Customercontact": "9876543210",'
            + '"business_name": "Acme Pvt Ltd",'
            + '"business_state_name": "Gujarat",'
            + '"business_city_name": "Ahmedabad",'
            + '"business_locality": "Navrangpura"'
            + '}]';

        Test.startTest();
        List<NowFloatsResponse.RESPONSE> result = NowFloatsResponse.parse(jsonStr);
        Test.stopTest();
    }

    @isTest
    static void testParseWithMultipleRecords() {
        String jsonStr = '['
            + '{'
            + '"date_and_time_of_enquiry": "2025-06-17 10:00:00",'
            + '"customer_message": "First enquiry",'
            + '"enquiry_entityType": "Lead",'
            + '"Customercontact": "9876543210",'
            + '"business_name": "Business One",'
            + '"business_state_name": "Maharashtra",'
            + '"business_city_name": "Mumbai",'
            + '"business_locality": "Andheri"'
            + '},'
            + '{'
            + '"date_and_time_of_enquiry": "2025-06-18 11:00:00",'
            + '"customer_message": "Second enquiry",'
            + '"enquiry_entityType": "Contact",'
            + '"Customercontact": "8765432109",'
            + '"business_name": "Business Two",'
            + '"business_state_name": "Karnataka",'
            + '"business_city_name": "Bangalore",'
            + '"business_locality": "Koramangala"'
            + '}'
            + ']';

        Test.startTest();
        List<NowFloatsResponse.RESPONSE> result = NowFloatsResponse.parse(jsonStr);
        Test.stopTest();
    }

    @isTest
    static void testParseWithNullFields() {
        String jsonStr = '[{'
            + '"date_and_time_of_enquiry": null,'
            + '"customer_message": null,'
            + '"enquiry_entityType": null,'
            + '"Customercontact": null,'
            + '"business_name": null,'
            + '"business_state_name": null,'
            + '"business_city_name": null,'
            + '"business_locality": null'
            + '}]';

        Test.startTest();
        List<NowFloatsResponse.RESPONSE> result = NowFloatsResponse.parse(jsonStr);
        Test.stopTest();
    }

    @isTest
    static void testParseWithEmptyArray() {
        String jsonStr = '[]';

        Test.startTest();
        List<NowFloatsResponse.RESPONSE> result = NowFloatsResponse.parse(jsonStr);
        Test.stopTest();
    }

    @isTest
    static void testParseWithPartialFields() {
        String jsonStr = '[{'
            + '"date_and_time_of_enquiry": "2025-06-17 09:00:00",'
            + '"customer_message": "Partial data enquiry"'
            + '}]';

        Test.startTest();
        List<NowFloatsResponse.RESPONSE> result = NowFloatsResponse.parse(jsonStr);
        Test.stopTest();
    }

    @isTest
    static void testResponseInnerClassInstantiation() {
        Test.startTest();
        NowFloatsResponse.RESPONSE resp = new NowFloatsResponse.RESPONSE();
        resp.date_and_time_of_enquiry = '2025-06-17 08:00:00';
        resp.customer_message         = 'Direct instantiation test';
        resp.enquiry_entityType       = 'Lead';
        resp.Customercontact          = '9000000000';
        resp.business_name            = 'Test Business';
        resp.business_state_name      = 'Rajasthan';
        resp.business_city_name       = 'Jaipur';
        resp.business_locality        = 'Malviya Nagar';
        Test.stopTest();
    }

    @isTest
    static void testNowFloatsResponseClassInstantiation() {
        Test.startTest();
        NowFloatsResponse wrapper = new NowFloatsResponse();
        Test.stopTest();
    }
}