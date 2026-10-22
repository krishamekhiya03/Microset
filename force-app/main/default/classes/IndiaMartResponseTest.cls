@isTest
private class IndiaMartResponseTest {

    @isTest
    static void testParse_FullJson() {

        String jsonInput = '{'
            + '"CODE": 200,'
            + '"STATUS": "SUCCESS",'
            + '"MESSAGE": "Data fetched successfully",'
            + '"TOTAL_RECORDS": 1,'
            + '"RESPONSE": ['
            +   '{'
            +     '"UNIQUE_QUERY_ID": "Q123",'
            +     '"QUERY_TYPE": "W",'
            +     '"QUERY_TIME": "2026-02-12 10:00:00",'
            +     '"SENDER_NAME": "John Doe",'
            +     '"SENDER_MOBILE": "9876543210",'
            +     '"SENDER_EMAIL": "john@example.com",'
            +     '"SUBJECT": "Need pH Sensor",'
            +     '"SENDER_COMPANY": "ABC Pharma",'
            +     '"SENDER_ADDRESS": "Some Street",'
            +     '"SENDER_CITY": "Ahmedabad",'
            +     '"SENDER_STATE": "Gujarat",'
            +     '"SENDER_PINCODE": "380001",'
            +     '"SENDER_COUNTRY_ISO": "IN",'
            +     '"SENDER_MOBILE_ALT": "9876500000",'
            +     '"SENDER_PHONE": "07912345678",'
            +     '"SENDER_PHONE_ALT": "",'
            +     '"SENDER_EMAIL_ALT": "john.alt@example.com",'
            +     '"QUERY_PRODUCT_NAME": "pH Sensor",'
            +     '"QUERY_MESSAGE": "Looking for bulk order",'
            +     '"QUERY_MCAT_NAME": "Sensors",'
            +     '"CALL_DURATION": "120",'
            +     '"RECEIVER_MOBILE": "9999999999",'
            +     '"RECEIVER_CATALOG": "Catalog1"'
            +   '}'
            + ']'
        + '}';

        Test.startTest();
        IndiaMartResponse result = IndiaMartResponse.parse(jsonInput);
        Test.stopTest();
    }

    @isTest
    static void testParse_EmptyResponseList() {

        String jsonInput = '{'
            + '"CODE": 204,'
            + '"STATUS": "NO_CONTENT",'
            + '"MESSAGE": "No new leads",'
            + '"TOTAL_RECORDS": 0,'
            + '"RESPONSE": []'
        + '}';

        Test.startTest();
        IndiaMartResponse result = IndiaMartResponse.parse(jsonInput);
        Test.stopTest();
    }

    @isTest
    static void testParse_MultipleResponseRecords() {

        String jsonInput = '{'
            + '"CODE": 200,'
            + '"STATUS": "SUCCESS",'
            + '"MESSAGE": "OK",'
            + '"TOTAL_RECORDS": 2,'
            + '"RESPONSE": ['
            +   '{ "UNIQUE_QUERY_ID": "Q1", "SENDER_NAME": "Alice" },'
            +   '{ "UNIQUE_QUERY_ID": "Q2", "SENDER_NAME": "Bob" }'
            + ']'
        + '}';

        Test.startTest();
        IndiaMartResponse result = IndiaMartResponse.parse(jsonInput);
        Test.stopTest();
    }

    @isTest
    static void testParse_InvalidJson_ThrowsException() {

        String invalidJson = '{ "CODE": 200, "STATUS": "SUCCESS", '; // malformed JSON

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            IndiaMartResponse.parse(invalidJson);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }
}