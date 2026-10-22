/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : IndiaMartResponse
 * Author          : <YourName>
 * Created Date    : Feb 12, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Feb 12, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Feb 12, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class IndiaMartResponse {
    public Integer CODE;
    public String STATUS;
    public String MESSAGE;
    public Integer TOTAL_RECORDS;
    public List<RESPONSE> RESPONSE;

    public class RESPONSE {
        public String UNIQUE_QUERY_ID;
        public String QUERY_TYPE;
        public String QUERY_TIME;
        public String SENDER_NAME;
        public String SENDER_MOBILE;
        public String SENDER_EMAIL;
        public String SUBJECT;
        public String SENDER_COMPANY;
        public String SENDER_ADDRESS;
        public String SENDER_CITY;
        public String SENDER_STATE;
        public String SENDER_PINCODE;
        public String SENDER_COUNTRY_ISO;
        public String SENDER_MOBILE_ALT;
        public String SENDER_PHONE;
        public String SENDER_PHONE_ALT;
        public String SENDER_EMAIL_ALT;
        public String QUERY_PRODUCT_NAME;
        public String QUERY_MESSAGE;
        public String QUERY_MCAT_NAME;
        public String CALL_DURATION;
        public String RECEIVER_MOBILE;
        public String RECEIVER_CATALOG;
    }
    public static IndiaMartResponse parse(String json) {
        return (IndiaMartResponse) System.JSON.deserialize(json, IndiaMartResponse.class);
    }
}