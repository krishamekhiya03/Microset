public with sharing class TradeIndiaService {

    /* =====================================================
       FETCH MY INQUIRY LEADS
    ===================================================== */

    public static void fetchMyInquiry(){

        String userid = '9314131';
        String profileId = '12809313';
        String apiKey = '0774b9f7d458f83c8a0a55fc10a6fcc0';

        Datetime endDT = Datetime.now();
        Datetime startDT = endDT.addHours(-1);

        String fromDate = startDT.format('yyyy-MM-dd');
        String toDate   = endDT.format('yyyy-MM-dd');

        String endpoint =
        'https://www.tradeindia.com/utils/my_inquiry.html' +
        '?userid=' + userid +
        '&profile_id=' + profileId +
        '&key=' + apiKey +
        '&from_date=' + fromDate +
        '&to_date=' + toDate +
        '&limit=50&page_no=1';

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept','application/json');
        req.setTimeout(120000);

        HttpResponse res = http.send(req);

        System.debug('TradeIndia Inquiry API Response: ' + res.getBody());

        if(res.getStatusCode() != 200){
            throw new CalloutException('TradeIndia API Failed: ' + res.getBody());
        }

        String responseBody = res.getBody();

        if(String.isBlank(responseBody) || !responseBody.trim().startsWith('[')){
            System.debug('Invalid TradeIndia Response: ' + responseBody);
            return;
        }

        List<Object> responseList =
        (List<Object>)JSON.deserializeUntyped(responseBody);

        if(responseList == null || responseList.isEmpty()){
            return;
        }

        TradeIndia_Inquiry_Configration_Setting__c config =
        TradeIndia_Inquiry_Configration_Setting__c.getOrgDefaults();

        Map<String,Object> configFieldMap = new Map<String,Object>();

        Map<String,Schema.SObjectField> settingFields =
        TradeIndia_Inquiry_Configration_Setting__c.SObjectType
        .getDescribe().fields.getMap();

        for(String fieldApiName : settingFields.keySet()){
            configFieldMap.put(fieldApiName, config.get(fieldApiName));
        }

        List<Lead_Custom__c> leadList = new List<Lead_Custom__c>();

        for(Object obj : responseList){

            Map<String,Object> leadMap = (Map<String,Object>)obj;

            Lead_Custom__c newLead = new Lead_Custom__c();
            newLead.Lead_Source__c = 'TradeIndia - My Inquiry';

           for(String fieldKey : leadMap.keySet()){

                if(configFieldMap.containsKey(fieldKey.toLowerCase() + '__c')){

                    String sfFieldName =
                        (String) configFieldMap.get(fieldKey.toLowerCase() + '__c');

                    if(sfFieldName != null){

                        Object value = leadMap.get(fieldKey);

                        Map<String, Schema.SObjectField> leadFields =
                            Lead_Custom__c.SObjectType.getDescribe().fields.getMap();

                        if(sfFieldName != 'Full Name'){

                            if(leadFields.containsKey(sfFieldName)){

                                Schema.DisplayType fieldType =
                                    leadFields.get(sfFieldName)
                                    .getDescribe().getType();

                                if(value != null){

                                    try{

                                        if(fieldType ==
                                            Schema.DisplayType.DATETIME){

                                            newLead.put(
                                                sfFieldName,
                                                Datetime.valueOf((String)value)
                                            );
                                        }

                                        else if(fieldType ==
                                                Schema.DisplayType.DATE){

                                            newLead.put(
                                                sfFieldName,
                                                Date.valueOf((String)value)
                                            );
                                        }

                                      else{

    if(value instanceof Integer){

        newLead.put(
            sfFieldName,
            String.valueOf(value)
        );
    }
                                            else{

                                                if(sfFieldName == 'Description__c'){

                                                    String cleanedValue = String.valueOf(value);

                                                    cleanedValue =
                                                        cleanedValue.replaceAll('<br\\s*/?>', '\n');

                                                    cleanedValue =
                                                        cleanedValue.replaceAll('<[^>]*>', '');

                                                    newLead.put(sfFieldName, cleanedValue);
                                                }
                                                else{
                                                    newLead.put(sfFieldName, value);
                                                }
                                            }
                                        }

                                    }catch(Exception e){

                                        System.debug(
                                            'Field Conversion Error: ' +
                                            e.getMessage()
                                        );
                                    }
                                }
                            }
                        }
                        else{

                            if(leadMap.containsKey('sender_name')){

                                String fullName =
                                    String.valueOf(
                                        leadMap.get('sender_name')
                                    ).trim();

                                if(!String.isBlank(fullName)){

                                    if(fullName.contains(' ')){

                                        List<String> nameParts =
                                            fullName.split(' ');

                                        newLead.Name = nameParts[0];

                                        String lastName = '';

                                        for(Integer i = 1;
                                            i < nameParts.size();
                                            i++){

                                            lastName += ' ' + nameParts[i];
                                        }

                                        newLead.Last_Name__c =
                                            lastName.trim();
                                    }
                                    else{

                                        newLead.Name = fullName;
                                        newLead.Last_Name__c = '.';
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // if(leadMap.containsKey('sender_mobile')){
            //     newLead.Phone__c = String.valueOf(leadMap.get('sender_mobile'));
            // }
            List<String> addressParts = new List<String>();

                if(!String.isBlank(newLead.Address_Street__c)){
                    addressParts.add(newLead.Address_Street__c);
                }

                if(!String.isBlank(newLead.Address_City__c)){
                    addressParts.add(newLead.Address_City__c);
                }

                if(!String.isBlank(newLead.Address_State_Province__c)){
                    addressParts.add(newLead.Address_State_Province__c);
                }

                if(!String.isBlank(newLead.Countries__c)){
                    addressParts.add(newLead.Countries__c);
                }

                if(!String.isBlank(newLead.Address_ZIP_Postal_Code__c)){
                    addressParts.add(newLead.Address_ZIP_Postal_Code__c);
                }

                if(!addressParts.isEmpty()){
                    newLead.Addresses__c = String.join(addressParts, ', ');
                }
            if(leadMap.containsKey('sender_uid')){
                newLead.Unique_Query_ID__c =
                    String.valueOf(leadMap.get('sender_uid'));
            }

            leadList.add(newLead);
        }

        upsertLeads(leadList);
    }


    /* =====================================================
       FETCH BUY LEADS
    ===================================================== */

    public static void fetchBuyLeads(){

        String userid = '9314131';
        String profileId = '12809313';
        String apiKey = '0774b9f7d458f83c8a0a55fc10a6fcc0';

        Datetime endDT = Datetime.now();
        Datetime startDT = endDT.addHours(-1);

        String fromDate = startDT.format('yyyy-MM-dd');
        String toDate   = endDT.format('yyyy-MM-dd');

        String endpoint =
        'https://www.tradeindia.com/utils/my_buy_leads.html' +
        '?userid=' + userid +
        '&profile_id=' + profileId +
        '&key=' + apiKey +
        '&from_date=' + fromDate +
        '&to_date=' + toDate +
        '&limit=50&page_no=1'; 

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept','application/json');
        req.setTimeout(120000);

        HttpResponse res = http.send(req);

        System.debug('TradeIndia Buy Lead API Response: ' + res.getBody());

        if(res.getStatusCode() != 200){
            throw new CalloutException('TradeIndia API Failed: ' + res.getBody());
        }

        String responseBody = res.getBody();

        if(String.isBlank(responseBody) || !responseBody.trim().startsWith('[')){
            System.debug('Invalid TradeIndia Response: ' + responseBody);
            return;
        }
        System.debug('Valid Response Received: ' + responseBody);
        List<Object> responseList = (List<Object>)JSON.deserializeUntyped(responseBody);

        if(responseList == null || responseList.isEmpty()){
            return;
        }

        TradeIndia_Buy_Lead_Configration_Setting__c config =
        TradeIndia_Buy_Lead_Configration_Setting__c.getOrgDefaults();

        Map<String,Object> configFieldMap = new Map<String,Object>();

        Map<String,Schema.SObjectField> settingFields =
        TradeIndia_Buy_Lead_Configration_Setting__c.SObjectType
        .getDescribe().fields.getMap();

        for(String fieldApiName : settingFields.keySet()){
            configFieldMap.put(fieldApiName, config.get(fieldApiName));
        }

        List<Lead_Custom__c> leadList = new List<Lead_Custom__c>();
        System.debug('Response List :::> ' + responseList);

        for(Object obj : responseList){
            System.debug('Lead Object :::> ' + obj);
            System.debug('lead contains contact_number key:::> ' + ((Map<String,Object>)obj).containsKey('contact_number'));    
            Map<String,Object> leadMap = (Map<String,Object>)obj;

            Lead_Custom__c newLead = new Lead_Custom__c();
            newLead.Lead_Source__c = 'TradeIndia - Buy Lead';

            
            for(String fieldKey : leadMap.keySet()){
                 
                if(configFieldMap.containsKey(fieldKey.toLowerCase() + '__c')){

                    String sfFieldName =
                        (String) configFieldMap.get(fieldKey.toLowerCase() + '__c');

                    if(sfFieldName != null){

                        Object value = leadMap.get(fieldKey);

                        Map<String, Schema.SObjectField> leadFields =
                            Lead_Custom__c.SObjectType.getDescribe().fields.getMap();

                        if(sfFieldName != 'Full Name'){

                            if(leadFields.containsKey(sfFieldName)){

                                Schema.DisplayType fieldType =
                                    leadFields.get(sfFieldName)
                                    .getDescribe().getType();

                                if(value != null){

                                    try{

                                        if(fieldType ==
                                            Schema.DisplayType.DATETIME){

                                            newLead.put(
                                                sfFieldName,
                                                Datetime.valueOf((String)value)
                                            );
                                        }

                                        else if(fieldType == Schema.DisplayType.DATE){
                                                    newLead.put(
                                                        sfFieldName,
                                                        Date.parse((String)value)
                                                    );
                                                }

                                       else{

    if(value instanceof Integer){

        newLead.put(
            sfFieldName,
            String.valueOf(value)
        );
    }
                                        else{

                                            if(sfFieldName == 'Description__c'){

                                                String cleanedValue = String.valueOf(value);

                                                cleanedValue =
                                                    cleanedValue.replaceAll('<br\\s*/?>', '\n');

                                                cleanedValue =
                                                    cleanedValue.replaceAll('<[^>]*>', '');

                                                newLead.put(sfFieldName, cleanedValue);
                                            }
                                            else{
                                                newLead.put(sfFieldName, value);
                                            }
                                        }
                                    }
                                    }catch(Exception e){

                                        System.debug(
                                            'Field Conversion Error: ' +
                                            e.getMessage()
                                        );
                                    }
                                }
                            }
                        }
                        else{

                            if(leadMap.containsKey('sender_name')){

                                String fullName =
                                    String.valueOf(
                                        leadMap.get('sender_name')
                                    ).trim();

                                if(!String.isBlank(fullName)){

                                    if(fullName.contains(' ')){

                                        List<String> nameParts =
                                            fullName.split(' ');

                                        newLead.Name = nameParts[0];

                                        String lastName = '';

                                        for(Integer i = 1;
                                            i < nameParts.size();
                                            i++){

                                            lastName += ' ' + nameParts[i];
                                        }

                                        newLead.Last_Name__c =
                                            lastName.trim();
                                    }
                                    else{

                                        newLead.Name = fullName;
                                        newLead.Last_Name__c = '.';
                                    }
                                }
                            }
                        }
                    }
                }
            }
               if(leadMap.containsKey('contact_details')){

                Map<String, Object> contactDetails =
                    (Map<String, Object>) leadMap.get('contact_details');

                if(contactDetails != null &&
                contactDetails.containsKey('contact_number')){

                    System.debug('Contact Number:::> ' + contactDetails.get('contact_number'));

                    newLead.Phone__c =
                        String.valueOf(contactDetails.get('contact_number'));
                }
                if(contactDetails != null &&
                    contactDetails.containsKey('user_name')){

                        String fullName =
                            String.valueOf(contactDetails.get('user_name')).trim();


                        if(!String.isBlank(fullName)){

                              List<String> salutations = new List<String>{'Mr.', 'Mrs.', 'Miss.', 'Ms.' , 'Dr.', 'Prof.' ,'MD','Mr', 'Mrs', 'Miss', 'Ms' , 'Dr', 'Prof' ,'MD.'};

                            for(String sal : salutations){

                                if(fullName.startsWith(sal + ' ')){

                                    newLead.Salutation__c = sal;

                                    // Remove salutation from name
                                    fullName = fullName.replace(sal,'').trim();
                                    break;
                                }
                            }

                            if(fullName.contains(' ')){

                                List<String> nameParts = fullName.split(' ');

                                newLead.Name = nameParts[0];

                                String lastName = '';

                                for(Integer i = 1; i < nameParts.size(); i++){
                                    lastName += ' ' + nameParts[i];
                                }

                                newLead.Last_Name__c = lastName.trim();
                            }
                            else{

                                newLead.Name = fullName;
                                newLead.Last_Name__c = '.';
                            }
                        }
                    }
            }
                   List<String> addressParts = new List<String>();

                    if(!String.isBlank(newLead.Address_Street__c)){
                        addressParts.add(newLead.Address_Street__c);
                    }

                    if(!String.isBlank(newLead.Address_City__c)){
                        addressParts.add(newLead.Address_City__c);
                    }

                    if(!String.isBlank(newLead.Address_State_Province__c)){
                        addressParts.add(newLead.Address_State_Province__c);
                    }

                    if(!String.isBlank(newLead.Countries__c)){
                        addressParts.add(newLead.Countries__c);
                    }

                    if(!String.isBlank(newLead.Address_ZIP_Postal_Code__c)){
                        addressParts.add(newLead.Address_ZIP_Postal_Code__c);
                    }

                    if(!addressParts.isEmpty()){
                        newLead.Addresses__c = String.join(addressParts, ', ');
                    }

            leadList.add(newLead);
        }

        upsertLeads(leadList);
    }


    /* =====================================================
       COMMON UPSERT METHOD
    ===================================================== */

    public static void upsertLeads(List<Lead_Custom__c> leadList){

        if(leadList.isEmpty()) return;

        Database.UpsertResult[] results =
        Database.upsert(
            leadList,
            Lead_Custom__c.Fields.Unique_Query_ID__c,
            false
        );

        for(Integer i=0;i<results.size();i++){

            if(results[i].isSuccess()){
                System.debug('Lead Upserted: ' + results[i].getId());
            }
            else{
                for(Database.Error err : results[i].getErrors()){
                    System.debug('Lead Error: ' + err.getMessage());
                }
            }
        }
    }
}