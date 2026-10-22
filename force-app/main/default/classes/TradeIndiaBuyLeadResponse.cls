/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TradeIndiaBuyLeadResponse
 * Author          : <Krisha Mekhiya>
 * Created Date    : Mar 06, 2026
 * Description     : Wrapper class for TradeIndia Buy Leads API response
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class TradeIndiaBuyLeadResponse {

    public String sender_email;
    //public String tl_rfi_date;
    //public Integer has_buy_lead_plan;
    public String lead_id;
    public String country;
    public Integer contactable;
    //public String inq_rfi_id;
    public String country_code;
    public String description;
    //public String specification;
    public String city;
    //public String id;
    public String profile_link;
    public String user_lead_status;
    //public String tl_rfi_message;
    public String product_name;
    public String delivery_loc;
    //public String tl_rfi_id;
    public Integer profile_id;
    public String lead_type;
    //public String posted_on;
    public String state;
    public Integer category_id;
    public String valid_from;
    public Integer userid;
    public String co_name;
    //public String required_for;

    public ContactDetails contact_details;
    public ExtraParams extra_params_for_pagination;

    /* ---------------------------------------
       Contact Details Object
    --------------------------------------- */

    public class ContactDetails{

        public String country_code;
        public String phone_no;
        public String contact_number;
        public String user_desg;
        public String user_name;
        public String city;
        public String state;
        public String address;
        public String pincode;
        //public String fax_no;
        public String contact_email;
        //public Integer number_mask;
    }

    /* ---------------------------------------
       Pagination Object
    --------------------------------------- */

    public class ExtraParams{

        public String add_important;
        public String transaction_details;
    }

    /* ---------------------------------------
       Parse Method
    --------------------------------------- */

    public static List<TradeIndiaBuyLeadResponse> parse(String json){

        return (List<TradeIndiaBuyLeadResponse>)
        System.JSON.deserialize(json, List<TradeIndiaBuyLeadResponse>.class);
    }
}