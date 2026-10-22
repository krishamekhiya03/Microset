/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaInquiryResponse
 * Author          : <Krisha Mekhiya>
 * Created Date    : Mar 06, 2026
 * Description     : Wrapper class for TradeIndia My Inquiry API response
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class TradeIndiaInquiryResponse {

    public String subject;
    public String message;
    public String sender_co;
    public String receiver_mobile;
    public String sender_city;
    public String sender_mobile;
    public Integer sender_uid;
    public String sender_other_mobiles;
    public String rfi_id;
    public String inquiry_type;
    public String sender_country;
    public String source;
    public Long generated;
    public String sender_name;
    public String sender_state;
    public String product_name;
    //public String sender_email;
    public String sender_phone;
    public String sender_other_emails;


    public static List<TradeIndiaInquiryResponse> parse(String json){
        return (List<TradeIndiaInquiryResponse>)
            System.JSON.deserialize(json, List<TradeIndiaInquiryResponse>.class);
    }
}