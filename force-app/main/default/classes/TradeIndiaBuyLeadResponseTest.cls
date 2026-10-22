/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaBuyLeadResponseTest
 * Author          : <Krisha Mekhiya>
 * Created Date    : Jun 17, 2026
 * Description     : Test class for TradeIndiaBuyLeadResponse wrapper
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@isTest
public class TradeIndiaBuyLeadResponseTest {

    /* ---------------------------------------
       Helper: build a single-element JSON
       that matches all mapped fields
    --------------------------------------- */
    private static String buildSingleLeadJson() {
        return '[{'
            + '"sender_email":"buyer@example.com",'
            + '"lead_id":"LD-001",'
            + '"country":"India",'
            + '"contactable":1,'
            + '"country_code":"+91",'
            + '"description":"Looking for stainless steel pipes",'
            + '"city":"Ahmedabad",'
            + '"profile_link":"https://tradeindia.com/profile/123",'
            + '"user_lead_status":"Active",'
            + '"product_name":"Stainless Steel Pipes",'
            + '"delivery_loc":"Gujarat",'
            + '"profile_id":123,'
            + '"lead_type":"Buy",'
            + '"state":"Gujarat",'
            + '"category_id":456,'
            + '"valid_from":"2026-03-01",'
            + '"userid":789,'
            + '"co_name":"Example Corp",'
            + '"contact_details":{'
            +     '"country_code":"+91",'
            +     '"phone_no":"9876543210",'
            +     '"contact_number":"9876543210",'
            +     '"user_desg":"Purchase Manager",'
            +     '"user_name":"Rahul Shah",'
            +     '"city":"Ahmedabad",'
            +     '"state":"Gujarat",'
            +     '"address":"123 Main St",'
            +     '"pincode":"380001",'
            +     '"contact_email":"rahul@example.com"'
            + '},'
            + '"extra_params_for_pagination":{'
            +     '"add_important":"0",'
            +     '"transaction_details":"none"'
            + '}'
            + '}]';
    }

    /* ---------------------------------------
       Helper: build a minimal JSON
    --------------------------------------- */
    private static String buildMinimalLeadJson() {
        return '[{'
            + '"lead_id":"LD-MIN",'
            + '"product_name":"Test Product",'
            + '"country":"US",'
            + '"contactable":0,'
            + '"country_code":"+1",'
            + '"userid":1'
            + '}]';
    }

    /* ---------------------------------------
       Helper: build a multi-lead JSON
    --------------------------------------- */
    private static String buildMultiLeadJson() {
        return '[{'
            + '"lead_id":"LD-A","product_name":"Product A","userid":1,'
            + '"contactable":1,"country":"India","country_code":"+91"'
            + '},{'
            + '"lead_id":"LD-B","product_name":"Product B","userid":2,'
            + '"contactable":0,"country":"USA","country_code":"+1"'
            + '},{'
            + '"lead_id":"LD-C","product_name":"Product C","userid":3,'
            + '"contactable":1,"country":"UK","country_code":"+44"'
            + '}]';
    }

    /* ---------------------------------------
       Test 1: Full parse – all top-level fields
    --------------------------------------- */
    @isTest
    static void testParse_AllTopLevelFields() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse(buildSingleLeadJson());
            Test.stopTest();

            if (results == null)                                        { isValid = false; errorMessage = 'Result list is null'; }
            else if (results.size() != 1)                              { isValid = false; errorMessage = 'Expected 1 lead, got: ' + results.size(); }
            else {
                TradeIndiaBuyLeadResponse lead = results[0];
                if (lead.sender_email      != 'buyer@example.com')                 { isValid = false; errorMessage = 'sender_email mismatch'; }
                else if (lead.lead_id      != 'LD-001')                            { isValid = false; errorMessage = 'lead_id mismatch'; }
                else if (lead.country      != 'India')                             { isValid = false; errorMessage = 'country mismatch'; }
                else if (lead.contactable  != 1)                                   { isValid = false; errorMessage = 'contactable mismatch'; }
                else if (lead.country_code != '+91')                               { isValid = false; errorMessage = 'country_code mismatch'; }
                else if (lead.description  != 'Looking for stainless steel pipes') { isValid = false; errorMessage = 'description mismatch'; }
                else if (lead.city         != 'Ahmedabad')                         { isValid = false; errorMessage = 'city mismatch'; }
                else if (lead.profile_link != 'https://tradeindia.com/profile/123'){ isValid = false; errorMessage = 'profile_link mismatch'; }
                else if (lead.user_lead_status != 'Active')                        { isValid = false; errorMessage = 'user_lead_status mismatch'; }
                else if (lead.product_name != 'Stainless Steel Pipes')             { isValid = false; errorMessage = 'product_name mismatch'; }
                else if (lead.delivery_loc != 'Gujarat')                           { isValid = false; errorMessage = 'delivery_loc mismatch'; }
                else if (lead.profile_id   != 123)                                 { isValid = false; errorMessage = 'profile_id mismatch'; }
                else if (lead.lead_type    != 'Buy')                               { isValid = false; errorMessage = 'lead_type mismatch'; }
                else if (lead.state        != 'Gujarat')                           { isValid = false; errorMessage = 'state mismatch'; }
                else if (lead.category_id  != 456)                                 { isValid = false; errorMessage = 'category_id mismatch'; }
                else if (lead.valid_from   != '2026-03-01')                        { isValid = false; errorMessage = 'valid_from mismatch'; }
                else if (lead.userid       != 789)                                 { isValid = false; errorMessage = 'userid mismatch'; }
                else if (lead.co_name      != 'Example Corp')                      { isValid = false; errorMessage = 'co_name mismatch'; }
            }
        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_AllTopLevelFields FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 2: Contact details parsed correctly
    --------------------------------------- */
    @isTest
    static void testParse_ContactDetails() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse(buildSingleLeadJson());
            Test.stopTest();

            TradeIndiaBuyLeadResponse.ContactDetails cd = results[0].contact_details;
            if (cd == null)                              { isValid = false; errorMessage = 'ContactDetails is null'; }
            else if (cd.country_code   != '+91')         { isValid = false; errorMessage = 'cd.country_code mismatch'; }
            else if (cd.phone_no       != '9876543210')  { isValid = false; errorMessage = 'cd.phone_no mismatch'; }
            else if (cd.contact_number != '9876543210')  { isValid = false; errorMessage = 'cd.contact_number mismatch'; }
            else if (cd.user_desg      != 'Purchase Manager') { isValid = false; errorMessage = 'cd.user_desg mismatch'; }
            else if (cd.user_name      != 'Rahul Shah')  { isValid = false; errorMessage = 'cd.user_name mismatch'; }
            else if (cd.city           != 'Ahmedabad')   { isValid = false; errorMessage = 'cd.city mismatch'; }
            else if (cd.state          != 'Gujarat')     { isValid = false; errorMessage = 'cd.state mismatch'; }
            else if (cd.address        != '123 Main St') { isValid = false; errorMessage = 'cd.address mismatch'; }
            else if (cd.pincode        != '380001')      { isValid = false; errorMessage = 'cd.pincode mismatch'; }
            else if (cd.contact_email  != 'rahul@example.com') { isValid = false; errorMessage = 'cd.contact_email mismatch'; }

        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_ContactDetails FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 3: ExtraParams parsed correctly
    --------------------------------------- */
    @isTest
    static void testParse_ExtraParams() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse(buildSingleLeadJson());
            Test.stopTest();

            TradeIndiaBuyLeadResponse.ExtraParams ep = results[0].extra_params_for_pagination;
            if (ep == null)                          { isValid = false; errorMessage = 'ExtraParams is null'; }
            else if (ep.add_important        != '0') { isValid = false; errorMessage = 'add_important mismatch'; }
            else if (ep.transaction_details  != 'none') { isValid = false; errorMessage = 'transaction_details mismatch'; }

        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_ExtraParams FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 4: Minimal JSON – optional fields null
    --------------------------------------- */
    @isTest
    static void testParse_MinimalJson_OptionalFieldsAreNull() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse(buildMinimalLeadJson());
            Test.stopTest();

            if (results.size() != 1)              { isValid = false; errorMessage = 'Expected 1 lead'; }
            else {
                TradeIndiaBuyLeadResponse lead = results[0];
                if (lead.lead_id      != 'LD-MIN')       { isValid = false; errorMessage = 'lead_id mismatch'; }
                else if (lead.product_name != 'Test Product') { isValid = false; errorMessage = 'product_name mismatch'; }
                else if (lead.sender_email != null)       { isValid = false; errorMessage = 'sender_email should be null'; }
                else if (lead.city         != null)       { isValid = false; errorMessage = 'city should be null'; }
                else if (lead.state        != null)       { isValid = false; errorMessage = 'state should be null'; }
                else if (lead.co_name      != null)       { isValid = false; errorMessage = 'co_name should be null'; }
                else if (lead.contact_details != null)    { isValid = false; errorMessage = 'contact_details should be null'; }
                else if (lead.extra_params_for_pagination != null) { isValid = false; errorMessage = 'extra_params should be null'; }
            }
        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_MinimalJson FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 5: Multiple leads in one response
    --------------------------------------- */
    @isTest
    static void testParse_MultipleLeads() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse(buildMultiLeadJson());
            Test.stopTest();

            if (results.size() != 3)                    { isValid = false; errorMessage = 'Expected 3 leads, got: ' + results.size(); }
            else if (results[0].lead_id != 'LD-A')      { isValid = false; errorMessage = 'First lead_id mismatch'; }
            else if (results[1].lead_id != 'LD-B')      { isValid = false; errorMessage = 'Second lead_id mismatch'; }
            else if (results[2].lead_id != 'LD-C')      { isValid = false; errorMessage = 'Third lead_id mismatch'; }
            else if (results[0].product_name != 'Product A') { isValid = false; errorMessage = 'First product_name mismatch'; }
            else if (results[1].product_name != 'Product B') { isValid = false; errorMessage = 'Second product_name mismatch'; }
            else if (results[2].product_name != 'Product C') { isValid = false; errorMessage = 'Third product_name mismatch'; }
            else if (results[0].userid != 1)            { isValid = false; errorMessage = 'First userid mismatch'; }
            else if (results[1].userid != 2)            { isValid = false; errorMessage = 'Second userid mismatch'; }
            else if (results[2].userid != 3)            { isValid = false; errorMessage = 'Third userid mismatch'; }

        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_MultipleLeads FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 6: Empty array JSON
    --------------------------------------- */
    @isTest
    static void testParse_EmptyArray() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            Test.startTest();
            List<TradeIndiaBuyLeadResponse> results =
                TradeIndiaBuyLeadResponse.parse('[]');
            Test.stopTest();

            if (results == null)        { isValid = false; errorMessage = 'Result should not be null'; }
            else if (results.size() != 0) { isValid = false; errorMessage = 'Result should be empty, got: ' + results.size(); }

        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_EmptyArray FAILED: ' + errorMessage);
        }
    }

    /* ---------------------------------------
       Test 7: Invalid JSON throws exception
    --------------------------------------- */
    @isTest
    static void testParse_InvalidJson_ThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            TradeIndiaBuyLeadResponse.parse('NOT_VALID_JSON');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        if (!exceptionThrown) {
            throw new AuraHandledException('testParse_InvalidJson FAILED: Expected exception was not thrown');
        }
    }

    /* ---------------------------------------
       Test 8: contactable integer boundary values
    --------------------------------------- */
    @isTest
    static void testParse_ContactableValues() {
        Boolean isValid = true;
        String errorMessage = '';

        try {
            String jsonZero = '[{"lead_id":"L1","userid":1,"contactable":0,"country":"IN","country_code":"+91","product_name":"X"}]';
            String jsonOne  = '[{"lead_id":"L2","userid":2,"contactable":1,"country":"IN","country_code":"+91","product_name":"Y"}]';

            Test.startTest();
            List<TradeIndiaBuyLeadResponse> r0 = TradeIndiaBuyLeadResponse.parse(jsonZero);
            List<TradeIndiaBuyLeadResponse> r1 = TradeIndiaBuyLeadResponse.parse(jsonOne);
            Test.stopTest();

            if (r0[0].contactable != 0)      { isValid = false; errorMessage = 'contactable=0 mismatch, got: ' + r0[0].contactable; }
            else if (r1[0].contactable != 1) { isValid = false; errorMessage = 'contactable=1 mismatch, got: ' + r1[0].contactable; }

        } catch (Exception e) {
            isValid = false;
            errorMessage = 'Exception thrown: ' + e.getMessage();
        }

        if (!isValid) {
            throw new AuraHandledException('testParse_ContactableValues FAILED: ' + errorMessage);
        }
    }
}