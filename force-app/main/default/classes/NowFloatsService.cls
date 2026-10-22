/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : NowFloatsService
 * Description     : Fetches enquiries from NowFloats API and upserts into
 *                   Lead_Custom__c using Custom Setting field mappings.
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public with sharing class NowFloatsService {
    
    public class NowFloatsServiceException extends Exception {}

    private static final String ENDPOINT =
        'https://enquirycalls.nowfloats.com/api/GetAllEnquiriesByEnterprise/';

    public static void fetchLeads() {

        /* ==========================================
           LOAD CUSTOM SETTING
        ========================================== */

        NowFloats_Configuration_Setting__c config =
            NowFloats_Configuration_Setting__c.getOrgDefaults();

        String  authKey      = config.Authorization_Key__c;
        String  enterpriseId = config.Enterprise_Id__c;
        Integer fetchLimit   = (config.Fetch_Limit__c != null)
                                ? Integer.valueOf(config.Fetch_Limit__c)
                                : 10;

        /* ==========================================
           BUILD FIELD MAPPING FROM CUSTOM SETTING
           key   = custom setting API name (lowercase)
           value = Salesforce Lead_Custom__c field API name
        ========================================== */

        Map<String, String> fieldMapping = new Map<String, String>();

        Map<String, Schema.SObjectField> settingFields =
            NowFloats_Configuration_Setting__c.SObjectType
            .getDescribe().fields.getMap();

        for (String apiName : settingFields.keySet()) {
            Object val = config.get(apiName);
            if (val != null && String.isNotBlank(String.valueOf(val))) {
                fieldMapping.put(apiName, String.valueOf(val));
            }
        }

        /* ==========================================
           PAGINATE — skip/limit until no more data
        ========================================== */

        Integer              skip     = 0;
        Boolean              hasMore  = true;
        List<Lead_Custom__c> allLeads = new List<Lead_Custom__c>();

        Map<String, Schema.SObjectField> leadFields =
            Lead_Custom__c.SObjectType.getDescribe().fields.getMap();

        while (hasMore) {

            /* ---- Build request (GET w/ body — matches working anon-window call) ---- */
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('GET');
            req.setHeader('Content-Type',  'application/json');
            req.setHeader('Authorization', authKey);
            req.setTimeout(120000);
            req.setBody(JSON.serialize(new Map<String, Object>{
                'EnterpriseId' => enterpriseId,
                'limit'        => fetchLimit,
                'skip'         => skip
            }));

            HttpResponse res = new Http().send(req);

            /* ==========================================
               ONLY HERE ERROR LOG SHOULD BE CREATED
               (API/callout failure — the ONLY place ErrorLogger
               is invoked in this class)
            ========================================== */

            if (res.getStatusCode() != 200) {

                String rawBody = res.getBody();
                String message = 'HTTP ' + res.getStatusCode();

                if (String.isNotBlank(rawBody)) {
                    try {
                        Object parsed = JSON.deserializeUntyped(rawBody);

                        if (parsed instanceof Map<String, Object>) {
                            Map<String, Object> errMap = (Map<String, Object>) parsed;
                            if (errMap.containsKey('message') && errMap.get('message') != null) {
                                // String.valueOf instead of a direct (String) cast —
                                // avoids ClassCastException if 'message' comes back
                                // as a number/boolean/nested object.
                                message = String.valueOf(errMap.get('message'));
                            } else {
                                message = 'HTTP ' + res.getStatusCode() + ' - ' + rawBody;
                            }
                        } else {
                            // Valid JSON, but not an object (e.g. a plain string/array)
                            message = 'HTTP ' + res.getStatusCode() + ' - ' + rawBody;
                        }
                    } catch (JSONException je) {
                        // Body wasn't JSON at all — fall back to raw text.
                        message = 'HTTP ' + res.getStatusCode() + ' - ' + rawBody;
                    }
                }

                System.debug('NowFloats call failed: ' + message);
                ErrorLogger.logError('NowFloatsService', message);
                throw new NowFloatsServiceException(message);
            }

            System.debug('NowFloats res.getBody()::> ' + json.serialize(res.getBody()));

            /* ---- Parse response array ---- */
            List<NowFloatsResponse.RESPONSE> responseList =
                NowFloatsResponse.parse(res.getBody());

            if (responseList == null || responseList.isEmpty()) {
                break;
            }

            /* ==========================================
               MAP EACH ENQUIRY → Lead_Custom__c
            ========================================== */

            for (NowFloatsResponse.RESPONSE enquiry : responseList) {

                // Flatten typed object → generic map (all keys lowercase, underscores kept)
                Map<String, Object> enquiryMap = flattenEnquiry(enquiry);

                Lead_Custom__c newLead   = new Lead_Custom__c();
                newLead.Lead_Source__c   = 'Website - Microsetindia.com';

                for (String settingKey : fieldMapping.keySet()) {

                    // Skip system/config fields
                    if (settingKey == 'authorization_key__c'
                        || settingKey == 'enterprise_id__c'
                        || settingKey == 'fetch_limit__c'
                        || settingKey == 'setupownerid'
                        || settingKey == 'id'
                        || settingKey == 'isdeleted'
                        || settingKey == 'systemmodstamp'
                        || settingKey == 'createddate'
                        || settingKey == 'createdbyid'
                        || settingKey == 'lastmodifieddate'
                        || settingKey == 'lastmodifiedbyid') {
                        continue;
                    }

                    String sfField = fieldMapping.get(settingKey);
                    if (String.isBlank(sfField)) continue;

                    /* ==========================================
                       REMOVED — Query_Time__c has no valid mapping
                       on Lead_Custom__c, skip it entirely. The
                       enquiry's date/time is instead only used to
                       build Unique_Query_ID__c below.
                    ========================================== */
                    if (sfField == 'Query_Time__c') continue;

                    // Derive normalized key (strip underscores + __c) so
                    // "enquiry_entity_type__c" still matches JSON key "enquiry_entitytype"
                    String normalizedSettingKey =
                        settingKey.removeEnd('__c').toLowerCase().replace('_', '');

                    String matchedJsonKey = null;
                    for (String jsonKey : enquiryMap.keySet()) {
                        if (jsonKey.replace('_', '') == normalizedSettingKey) {
                            matchedJsonKey = jsonKey;
                            break;
                        }
                    }
                    if (matchedJsonKey == null) continue;

                    Object value = enquiryMap.get(matchedJsonKey);
                    if (value == null) continue;

                    if (!leadFields.containsKey(sfField)) {
                        System.debug('NowFloats: SF field not found: ' + sfField);
                        continue;
                    }

                    Schema.DisplayType fType =
                        leadFields.get(sfField).getDescribe().getType();

                    try {
                        if (fType == Schema.DisplayType.DATETIME) {
                            newLead.put(sfField,
                                parseNowFloatsDatetime((String) value));

                        } else if (fType == Schema.DisplayType.DATE) {
                            newLead.put(sfField,
                                Date.valueOf((String) value));

                        } else {
                            newLead.put(sfField, value);
                        }
                    } catch (Exception e) {
                        // Not an API failure — field-level mapping issue only.
                        // Debug log only, no Error_Log__c entry.
                        System.debug('NowFloats field mapping error ['
                            + sfField + ']: ' + e.getMessage());
                    }
                }

                /* ==========================================
                   PARSE NAME / SUBJECT / MESSAGE / EMAIL FROM
                   customer_message (CONTACTQUERY entries embed them)
                ========================================== */

                parseCustomerMessage(enquiry.customer_message, newLead);

                /* ==========================================
                   ADDRESS COMBINE
                ========================================== */

                List<String> addrParts = new List<String>();

                if (!String.isBlank(newLead.Address_Street__c))
                    addrParts.add(newLead.Address_Street__c);
                if (!String.isBlank(newLead.Address_City__c))
                    addrParts.add(newLead.Address_City__c);
                if (!String.isBlank(newLead.Address_State_Province__c))
                    addrParts.add(newLead.Address_State_Province__c);

                if (!addrParts.isEmpty())
                    newLead.Addresses__c = String.join(addrParts, ', ');

                /* ==========================================
                   UNIQUE KEY — use contact + datetime combo
                   (NowFloats has no native unique ID field)
                ========================================== */

                if (!String.isBlank(enquiry.Customercontact)
                    && !String.isBlank(enquiry.date_and_time_of_enquiry)) {

                    newLead.Unique_Query_ID__c =
                        enquiry.Customercontact.trim()
                        + '_'
                        + enquiry.date_and_time_of_enquiry.trim()
                            .replace('/', '')
                            .replace(' ', '_')
                            .replace(':', '');
                }

                allLeads.add(newLead);
            }

            /* ---- Pagination control ---- */
            if (responseList.size() < fetchLimit) {
                hasMore = false;
            } else {
                skip += fetchLimit;
            }
        }

        /* ==========================================
           UPSERT ALL LEADS
        ========================================== */

        if (!allLeads.isEmpty()) {

            Database.UpsertResult[] results =
                Database.upsert(
                    allLeads,
                    Lead_Custom__c.Fields.Unique_Query_ID__c,
                    false
                );

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        // Not an API failure — DML/validation issue only.
                        // Debug log only, no Error_Log__c entry.
                        System.debug('NowFloats Upsert Failed: '
                            + err.getMessage());
                    }
                }
            }
        }
    }

    /* ==========================================
       HELPER — flatten typed RESPONSE → lowercase map
    ========================================== */

    private static Map<String, Object> flattenEnquiry(
        NowFloatsResponse.RESPONSE e) {

        Map<String, Object> m = new Map<String, Object>();
        m.put('date_and_time_of_enquiry', e.date_and_time_of_enquiry);
        m.put('customer_message',         e.customer_message);
        m.put('enquiry_entitytype',       e.enquiry_entityType);
        m.put('customercontact',          e.Customercontact);
        m.put('business_name',            e.business_name);
        m.put('business_state_name',      e.business_state_name);
        m.put('business_city_name',       e.business_city_name);
        m.put('business_locality',        e.business_locality);
        return m;
    }

    /* ==========================================
       HELPER — parse "dd/MM/yyyy HH:mm:ss" → Datetime
       NowFloats format: "15/06/2026 12:59:06"
       (kept in case any OTHER real datetime field needs it —
        no longer used for Query_Time__c)
    ========================================== */

    private static Datetime parseNowFloatsDatetime(String val) {
        if (String.isBlank(val)) return null;
        try {
            List<String> parts     = val.split(' ');
            List<String> dateParts = parts[0].split('/');
            String iso = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0]
                         + ' ' + parts[1];
            return Datetime.valueOf(iso);
        } catch (Exception e) {
            // Not an API failure — parsing issue only.
            // Debug log only, no Error_Log__c entry.
            System.debug('NowFloats datetime parse error: ' + e.getMessage());
            return null;
        }
    }
        private static String stripHtmlTags(String input) {
        if (String.isBlank(input)) return input;

        String cleaned = input.replaceAll('<[^>]+>', '');

        cleaned = cleaned.replace('&nbsp;', ' ')
                          .replace('&amp;',  '&')
                          .replace('&lt;',   '<')
                          .replace('&gt;',   '>')
                          .replace('&quot;', '"')
                          .replace('&#39;',  '\'');

        return cleaned.trim();
    }
    /* ==========================================
       HELPER — parse Name / Subject / Message / Email
       embedded inside customer_message

       Expected format (each on its own line):
         Name: Krisha Mekhiya
         Subject: Developer test Email
         Message: test
         Email: krishamekhiya03@gmail.com

       Rules:
         - Name    -> split on FIRST space: before = Name (first name),
                      after = Last_Name__c. If no space, Name = full text,
                      Last_Name__c = "."
                      If Name label itself is missing/blank -> both = "."
         - Subject -> Subject__c
         - Message -> Description__c
         - Email   -> Email__c
         - If NONE of the labels (Name:/Subject:/Message:/Email:) are
           found anywhere in the text, the ENTIRE customer_message is
           put into Description__c instead.
    ========================================== */

private static void parseCustomerMessage(String msg, Lead_Custom__c lead) {

        if (String.isBlank(msg)) return;
        msg = stripHtmlTags(msg);

        List<String> lines = msg.split('\n');

        Boolean foundName    = false;
        Boolean foundSubject = false;
        Boolean foundMessage = false;
        Boolean foundEmail   = false;

        String        messageBuffer     = null; // accumulates Message: content (can span lines)
        List<String>  descriptionLines  = new List<String>(); // generic/unlabeled lines

        for (Integer i = 0; i < lines.size(); i++) {

            String line = lines[i].trim();

            if (line.startsWith('Name:') || line.startsWith('From:')) {
                foundName = true;
                String namePrefix = line.startsWith('Name:') ? 'Name:' : 'From:';
                String fullName   = line.substringAfter(namePrefix).trim();

                if (!String.isBlank(fullName)) {
                    if (fullName.contains(' ')) {
                        lead.Name         = fullName.substringBefore(' ').trim();
                        lead.Last_Name__c = fullName.substringAfter(' ').trim();
                    } else {
                        lead.Name         = fullName;
                        lead.Last_Name__c = '-';
                    }
                } else {
                    lead.Name         = '-';
                    lead.Last_Name__c = '-';
                }

            } else if (line.startsWith('Subject:')) {
                foundSubject = true;
                String subject = line.substringAfter('Subject:').trim();
                lead.Subject__c = String.isBlank(subject) ? '-' : subject;

            } else if (line.startsWith('Message:')) {
                foundMessage = true;
                // Start collecting message text — may continue on following
                // line(s) until the next known label is hit.
                messageBuffer = line.substringAfter('Message:').trim();

            } else if (line.startsWith('Email:')) {
                foundEmail = true;
                String email = line.substringAfter('Email:').trim();
                if (!String.isBlank(email)) {
                    lead.Email__c = email;
                }

            } else if (messageBuffer != null) {
                // Continuation line belonging to an explicit Message: block
                messageBuffer += '\n' + line;

            } else {
                // Generic unlabeled line (e.g. plain requirement text
                // with no Name:/Subject:/Message:/Email:/From: prefix)
                if (!String.isBlank(line)) {
                    descriptionLines.add(line);
                }
            }
        }

        // If Name label was never present at all, still default to "-"
        if (!foundName) {
            lead.Name         = '-';
            lead.Last_Name__c = '-';
        }

        /* ==========================================
           DESCRIPTION — priority:
           1) explicit Message: block (if present)
           2) otherwise, generic unlabeled lines (excludes
              Name:/From:/Subject:/Email: lines automatically)
        ========================================== */
        if (foundMessage) {
            lead.Description__c = String.isBlank(messageBuffer) ? '-' : messageBuffer.trim();
        } else if (!descriptionLines.isEmpty()) {
            lead.Description__c = String.join(descriptionLines, '\n').trim();
        }
    }
}