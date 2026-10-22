/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaInquiryResponseTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaInquiryResponse wrapper
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaInquiryResponseTest {

    /* ---------------------------------------
       Helper: Full JSON with all mapped fields
    --------------------------------------- */
    private static String buildFullJson() {
        return '[{'
            + '"subject":"Need Stainless Steel Pipes",'
            + '"message":"We require 500 units of SS pipes urgently",'
            + '"sender_co":"ABC Traders",'
            + '"receiver_mobile":"9876543210",'
            + '"sender_city":"Ahmedabad",'
            + '"sender_mobile":"9876543210",'
            + '"sender_uid":1001,'
            + '"sender_other_mobiles":"9000000001,9000000002",'
            + '"rfi_id":"RFI-001",'
            + '"inquiry_type":"Buy",'
            + '"sender_country":"India",'
            + '"source":"TradeIndia",'
            + '"generated":1709712000000,'
            + '"sender_name":"Rahul Shah",'
            + '"sender_state":"Gujarat",'
            + '"product_name":"Stainless Steel Pipes",'
            + '"sender_phone":"07926543210",'
            + '"sender_other_emails":"alt1@example.com,alt2@example.com"'
            + '}]';
    }

    /* ---------------------------------------
       Helper: Minimal JSON with only
       few fields
    --------------------------------------- */
    private static String buildMinimalJson() {
        return '[{'
            + '"rfi_id":"RFI-MIN",'
            + '"product_name":"Test Product",'
            + '"sender_uid":1'
            + '}]';
    }

    /* ---------------------------------------
       Helper: Multi-record JSON
    --------------------------------------- */
    private static String buildMultiJson() {
        return '[{'
            + '"rfi_id":"RFI-A","product_name":"Product A","sender_uid":1'
            + '},{'
            + '"rfi_id":"RFI-B","product_name":"Product B","sender_uid":2'
            + '},{'
            + '"rfi_id":"RFI-C","product_name":"Product C","sender_uid":3'
            + '}]';
    }

    /* ---------------------------------------
       Test 1: Full parse – all top-level fields
    --------------------------------------- */
    @isTest
    static void testParse_AllFields() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse(buildFullJson());
            Test.stopTest();

            if (results == null) {
                isValid = false; errorMessage = 'Result list is null';
            } else if (results.size() != 1) {
                isValid = false; errorMessage = 'Expected 1 record, got: ' + results.size();
            } else {
                TradeIndiaInquiryResponse res = results[0];
                if (res.subject                != 'Need Stainless Steel Pipes')           { isValid = false; errorMessage = 'subject mismatch'; }
                else if (res.message           != 'We require 500 units of SS pipes urgently') { isValid = false; errorMessage = 'message mismatch'; }
                else if (res.sender_co         != 'ABC Traders')                          { isValid = false; errorMessage = 'sender_co mismatch'; }
                else if (res.receiver_mobile   != '9876543210')                           { isValid = false; errorMessage = 'receiver_mobile mismatch'; }
                else if (res.sender_city       != 'Ahmedabad')                            { isValid = false; errorMessage = 'sender_city mismatch'; }
                else if (res.sender_mobile     != '9876543210')                           { isValid = false; errorMessage = 'sender_mobile mismatch'; }
                else if (res.sender_uid        != 1001)                                   { isValid = false; errorMessage = 'sender_uid mismatch'; }
                else if (res.sender_other_mobiles != '9000000001,9000000002')             { isValid = false; errorMessage = 'sender_other_mobiles mismatch'; }
                else if (res.rfi_id            != 'RFI-001')                              { isValid = false; errorMessage = 'rfi_id mismatch'; }
                else if (res.inquiry_type      != 'Buy')                                  { isValid = false; errorMessage = 'inquiry_type mismatch'; }
                else if (res.sender_country    != 'India')                                { isValid = false; errorMessage = 'sender_country mismatch'; }
                else if (res.source            != 'TradeIndia')                           { isValid = false; errorMessage = 'source mismatch'; }
                else if (res.generated         != 1709712000000L)                         { isValid = false; errorMessage = 'generated mismatch'; }
                else if (res.sender_name       != 'Rahul Shah')                           { isValid = false; errorMessage = 'sender_name mismatch'; }
                else if (res.sender_state      != 'Gujarat')                              { isValid = false; errorMessage = 'sender_state mismatch'; }
                else if (res.product_name      != 'Stainless Steel Pipes')                { isValid = false; errorMessage = 'product_name mismatch'; }
                else if (res.sender_phone      != '07926543210')                          { isValid = false; errorMessage = 'sender_phone mismatch'; }
                else if (res.sender_other_emails != 'alt1@example.com,alt2@example.com') { isValid = false; errorMessage = 'sender_other_emails mismatch'; }
            }
        } catch (Exception e) {
            isValid     = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_AllFields FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 2: Minimal JSON – optional fields null
    --------------------------------------- */
    @isTest
    static void testParse_MinimalJson_OptionalFieldsAreNull() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse(buildMinimalJson());
            Test.stopTest();

            if (results.size() != 1) {
                isValid = false; errorMessage = 'Expected 1 record, got: ' + results.size();
            } else {
                TradeIndiaInquiryResponse res = results[0];
                if (res.rfi_id       != 'RFI-MIN')      { isValid = false; errorMessage = 'rfi_id mismatch'; }
                else if (res.product_name != 'Test Product') { isValid = false; errorMessage = 'product_name mismatch'; }
                else if (res.sender_uid   != 1)          { isValid = false; errorMessage = 'sender_uid mismatch'; }
                else if (res.subject      != null)        { isValid = false; errorMessage = 'subject should be null'; }
                else if (res.message      != null)        { isValid = false; errorMessage = 'message should be null'; }
                else if (res.sender_co    != null)        { isValid = false; errorMessage = 'sender_co should be null'; }
                else if (res.sender_city  != null)        { isValid = false; errorMessage = 'sender_city should be null'; }
                else if (res.sender_name  != null)        { isValid = false; errorMessage = 'sender_name should be null'; }
                else if (res.sender_state != null)        { isValid = false; errorMessage = 'sender_state should be null'; }
                else if (res.sender_phone != null)        { isValid = false; errorMessage = 'sender_phone should be null'; }
                else if (res.source       != null)        { isValid = false; errorMessage = 'source should be null'; }
                else if (res.generated    != null)        { isValid = false; errorMessage = 'generated should be null'; }
            }
        } catch (Exception e) {
            isValid      = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_MinimalJson FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 3: Multiple records parsed correctly
    --------------------------------------- */
    @isTest
    static void testParse_MultipleRecords() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse(buildMultiJson());
            Test.stopTest();

            if (results.size() != 3) {
                isValid = false; errorMessage = 'Expected 3 records, got: ' + results.size();
            } else if (results[0].rfi_id != 'RFI-A') {
                isValid = false; errorMessage = 'First rfi_id mismatch';
            } else if (results[1].rfi_id != 'RFI-B') {
                isValid = false; errorMessage = 'Second rfi_id mismatch';
            } else if (results[2].rfi_id != 'RFI-C') {
                isValid = false; errorMessage = 'Third rfi_id mismatch';
            } else if (results[0].product_name != 'Product A') {
                isValid = false; errorMessage = 'First product_name mismatch';
            } else if (results[1].product_name != 'Product B') {
                isValid = false; errorMessage = 'Second product_name mismatch';
            } else if (results[2].product_name != 'Product C') {
                isValid = false; errorMessage = 'Third product_name mismatch';
            } else if (results[0].sender_uid != 1) {
                isValid = false; errorMessage = 'First sender_uid mismatch';
            } else if (results[1].sender_uid != 2) {
                isValid = false; errorMessage = 'Second sender_uid mismatch';
            } else if (results[2].sender_uid != 3) {
                isValid = false; errorMessage = 'Third sender_uid mismatch';
            }
        } catch (Exception e) {
            isValid      = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_MultipleRecords FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 4: Empty array JSON
    --------------------------------------- */
    @isTest
    static void testParse_EmptyArray() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse('[]');
            Test.stopTest();

            if (results == null) {
                isValid = false; errorMessage = 'Result should not be null';
            } else if (results.size() != 0) {
                isValid = false; errorMessage = 'Expected empty list, got: ' + results.size();
            }
        } catch (Exception e) {
            isValid      = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_EmptyArray FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 5: Invalid JSON throws exception
    --------------------------------------- */
    @isTest
    static void testParse_InvalidJson_ThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            TradeIndiaInquiryResponse.parse('INVALID_JSON');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        if (!exceptionThrown) {
            throw new AuraHandledException('testParse_InvalidJson FAILED: Expected exception was not thrown');
        }
    }

    /* ---------------------------------------
       Test 6: Long datatype for generated field
    --------------------------------------- */
    @isTest
    static void testParse_GeneratedLongValue() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            String jsonStr = '[{'
                + '"rfi_id":"RFI-LONG",'
                + '"sender_uid":999,'
                + '"generated":1709712000000'
                + '}]';

            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse(jsonStr);
            Test.stopTest();

            if (results == null || results.isEmpty()) {
                isValid = false; errorMessage = 'Result is null or empty';
            } else if (results[0].generated != 1709712000000L) {
                isValid = false; errorMessage = 'generated Long value mismatch, got: ' + results[0].generated;
            }
        } catch (Exception e) {
            isValid      = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_GeneratedLongValue FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 7: sender_uid integer value check
    --------------------------------------- */
    @isTest
    static void testParse_SenderUidIntegerValue() {
        Boolean isValid     = true;
        String errorMessage = '';

        try {
            String jsonStr = '[{'
                + '"rfi_id":"RFI-UID",'
                + '"sender_uid":9999,'
                + '"product_name":"Some Product"'
                + '}]';

            Test.startTest();
            List<TradeIndiaInquiryResponse> results =
                TradeIndiaInquiryResponse.parse(jsonStr);
            Test.stopTest();

            if (results == null || results.isEmpty()) {
                isValid = false; errorMessage = 'Result is null or empty';
            } else if (results[0].sender_uid != 9999) {
                isValid = false; errorMessage = 'sender_uid mismatch, got: ' + results[0].sender_uid;
            }
        } catch (Exception e) {
            isValid      = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_SenderUidIntegerValue FAILED: ' + errorMessage);
        }
    }
}