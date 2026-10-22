public with sharing class IndiaMartService {

    public static void fetchLeads() {

        String crmKey = 'mRy0E7Fo53jIQfep7neD7luNoVvElTY='; 

        Date endDateObj = Date.today();
        Date startDateObj = endDateObj.addDays(-7);

        Datetime endDT = Datetime.now();
        Datetime startDT = endDT.addDays(-7);

        String startDate = startDT.format('dd-MM-yyyy HH:mm:ss', 'Asia/Kolkata');
        
        String endDate   = endDT.format('dd-MM-yyyy HH:mm:ss', 'Asia/Kolkata');

        System.debug('Dynamic Start Date:::> ' + startDate);
        System.debug('Dynamic End Date:::> ' + endDate);

        Http http = new Http();
        HttpRequest req = new HttpRequest();

      //  String endpoint = 'https://mapi.indiamart.com/wservce/crm/crmListing/v2/' +
        //    '?glusr_crm_key=' + EncodingUtil.urlEncode(crmKey,'UTF-8') +
          //  '&start_time=' + EncodingUtil.urlEncode(startDate,'UTF-8') +
        //    '&end_time=' + EncodingUtil.urlEncode(endDate,'UTF-8');
	String endpoint = 'https://mapi.indiamart.com/wservce/crm/crmListing/v2/' +     
        '?glusr_crm_key=' + EncodingUtil.urlEncode(crmKey,'UTF-8') +     
        '&start_time=' + EncodingUtil.urlEncode(startDate,'UTF-8').replace('+', '%20') +     
        '&end_time=' + EncodingUtil.urlEncode(endDate,'UTF-8').replace('+', '%20');
 
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);

        HttpResponse res = http.send(req);

        /* ==========================================
           ONLY HERE ERROR LOG SHOULD BE CREATED
        ========================================== */

        if(res.getStatusCode() != 200){

            Map<String, Object> responseMap = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            String message = (String) responseMap.get('MESSAGE');

            System.debug('IndiaMart call failed: ' + message);

            // ERROR LOG ONLY FOR API FAILURE
            ErrorLogger.logError('IndiaMartService', message);

            throw new AuraHandledException(message);
        }

        System.debug('res.getBody()::> ' + res.getBody());

        Map<String, Object> result =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        List<Object> responseList =
            (List<Object>) result.get('RESPONSE');

        if(responseList == null || responseList.isEmpty()){
            return;
        }

        /* ==========================================
           GET CUSTOM SETTING MAPPING
        ========================================== */

        IndiaMart_Configration_Setting__c config =
            IndiaMart_Configration_Setting__c.getOrgDefaults();

        Map<String, Object> configFieldMap = new Map<String, Object>();

        Map<String, Schema.SObjectField> settingFields =
            IndiaMart_Configration_Setting__c.SObjectType
            .getDescribe().fields.getMap();

        for(String fieldApiName : settingFields.keySet()){
            configFieldMap.put(fieldApiName, config.get(fieldApiName));
        }

        List<Lead_Custom__c> leadList = new List<Lead_Custom__c>();

        for(Object obj : responseList){

            Map<String, Object> leadMap =
                (Map<String, Object>) obj;

            Lead_Custom__c newLead = new Lead_Custom__c();
            newLead.Lead_Source__c = 'IndiaMART';

            for(String key : leadMap.keySet()){

                if(configFieldMap.containsKey(key.toLowerCase() + '__c')){

                    String sfFieldName =
                        (String) configFieldMap.get(key.toLowerCase() + '__c');

                    if(sfFieldName != null){

                        Object value = leadMap.get(key);

                        Map<String, Schema.SObjectField> leadFields =
                            Lead_Custom__c.SObjectType
                            .getDescribe().fields.getMap();

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

                                        }else if(fieldType ==
                                                Schema.DisplayType.DATE){

                                            newLead.put(
                                                sfFieldName,
                                                Date.valueOf((String)value)
                                            );

                                       }else{

                                    if(sfFieldName == 'Description__c'){

                                        String cleanedValue = String.valueOf(value);

                                        cleanedValue =
                                            cleanedValue.replaceAll('<br\\s*/?>', '\n');

                                        cleanedValue =
                                            cleanedValue.replaceAll('<[^>]*>', '');

                                        newLead.put(sfFieldName, cleanedValue);

                                    }else{

                                        newLead.put(sfFieldName,value);
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

                            if(leadMap.containsKey('SENDER_NAME')){

                                String fullName =
                                    String.valueOf(
                                        leadMap.get('SENDER_NAME')
                                    ).trim();

                                if(!String.isBlank(fullName)){

                                    if(fullName.contains(' ')){

                                        List<String> nameParts =
                                            fullName.split(' ');

                                        newLead.Name = nameParts[0];

                                        String lastName = '';

                                        for(Integer i=1;
                                            i<nameParts.size(); i++){

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

            /* ==========================================
               ADDRESS COMBINE
            ========================================== */

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
                newLead.Addresses__c =
                    String.join(addressParts, ', ');
            }

            leadList.add(newLead);
        }

        /* ==========================================
           UPSERT LEADS
        ========================================== */

        if(!leadList.isEmpty()){

            Database.UpsertResult[] results =
                Database.upsert(
                    leadList,
                    Lead_Custom__c.Fields.Unique_Query_ID__c,
                    false
                );

            for(Integer i = 0; i < results.size(); i++){

                if(!results[i].isSuccess()){

                    for(Database.Error err : results[i].getErrors()){

                        System.debug(
                            'Upsert Failed: ' +
                            err.getMessage()
                        );
                    }
                }
            }
        }
    }
}