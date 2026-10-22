public with sharing class NowFloatsEnquiryService {
   
    public static List<EnquiryWrapper> getEnquiries(Integer limitSize, Integer skipSize){
        List<EnquiryWrapper> responseData = new List<EnquiryWrapper>();
        NowFloats_Config__mdt config = NowFloats_Config__mdt.getInstance('Now_Float');
        System.debug('Enterprise Id : ' + config.Enterprise_Id__c);
        System.debug('Authorization Token : ' + config.Authorization_Token__c);
        
        HttpRequest req = new HttpRequest();
        
        // ✅ Try passing params in URL as query string
        String endpoint = 'https://enquirycalls.nowfloats.com/api/GetAllEnquiriesByEnterprise/'
            + '?EnterpriseId=' + EncodingUtil.urlEncode(config.Enterprise_Id__c, 'UTF-8')
            + '&limit=' + limitSize
            + '&skip=' + skipSize;
        
        req.setEndpoint(endpoint);
        req.setMethod('GET');
    	req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', config.Authorization_Token__c);
        
        System.debug('Method : ' + req.getMethod());
        System.debug('Endpoint : ' + req.getEndpoint());
        
        HttpResponse res = new Http().send(req);
        System.debug('Status Code : ' + res.getStatusCode());
        System.debug('Status : ' + res.getStatus());
        System.debug('Response Body : ' + res.getBody());
        
        if(res.getStatusCode() == 200){
            responseData = (List<EnquiryWrapper>) JSON.deserialize(res.getBody(), List<EnquiryWrapper>.class);
            System.debug('Total Records : ' + responseData.size());
            for(EnquiryWrapper e : responseData){
                System.debug('Date : ' + e.date_and_time_of_enquiry);
                System.debug('Message : ' + e.customer_message);
                System.debug('Type : ' + e.enquiry_entityType);
                System.debug('Contact : ' + e.Customercontact);
                System.debug('Business Name : ' + e.business_name);
                System.debug('State : ' + e.business_state_name);
                System.debug('City : ' + e.business_city_name);
                System.debug('Locality : ' + e.business_locality);
            }
        } else {
            System.debug('Error - Status Code: ' + res.getStatusCode() + ' | Status: ' + res.getStatus());
            System.debug('Error Response Body: ' + res.getBody());
        }
        
        return responseData;
    }
    
    public class EnquiryWrapper {
        public String date_and_time_of_enquiry;
        public String customer_message;
        public String enquiry_entityType;
        public String Customercontact;
        public String business_name;
        public String business_state_name;
        public String business_city_name;
        public String business_locality;
    }
}