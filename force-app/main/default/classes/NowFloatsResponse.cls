/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsResponse
 * Description     : Wrapper to deserialize NowFloats API response array
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public class NowFloatsResponse {

    public class RESPONSE {
        public String date_and_time_of_enquiry;
        public String customer_message;
        public String enquiry_entityType;
        public String Customercontact;
        public String business_name;
        public String business_state_name;
        public String business_city_name;
        public String business_locality;
    }

    public static List<RESPONSE> parse(String jsonStr) {
        return (List<RESPONSE>)
            System.JSON.deserialize(jsonStr, List<NowFloatsResponse.RESPONSE>.class);
    }
}