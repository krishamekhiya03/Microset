/**
 * QuotationController v4.0
 * ─────────────────────────────────────────────────────────────────────────
 * CHANGES FROM v3.0:
 *   + Added getQuoteLineGroups()  — fetches all Quote_Line_Group__c records
 *     for a given Quotation, ordered by Sort_Order__c.
 *   + Added saveQuoteLineGroup()  — upserts a single group record.
 *   + Added deleteQuoteLineGroup() — deletes a group (line items become ungrouped).
 *   + Added reorderGroups()       — bulk-updates Sort_Order__c on groups.
 *   + getQuotationLineItems()     — now includes Quote_Line_Group__c and
 *     Sort_Order__c fields and orders by Sort_Order__c ASC.
 *   + updateQuotationLineItems()  — now also persists Quote_Line_Group__c
 *     and Sort_Order__c.
 *
 * All other existing methods are UNCHANGED.
 * ─────────────────────────────────────────────────────────────────────────
 */
public with sharing class QuotationController {

    // ─────────────────────────────────────────────────────────────────────
    //  INNER CLASS: unified request payload
    // ─────────────────────────────────────────────────────────────────────
    public class QuotationPayload {
        @AuraEnabled public String  quotationNumber  { get; set; }
        @AuraEnabled public String  quotationDate    { get; set; }
        @AuraEnabled public String  companyName      { get; set; }
        @AuraEnabled public String  companyAddress   { get; set; }
        @AuraEnabled public String  companyPhone     { get; set; }
        @AuraEnabled public String  companyEmail     { get; set; }
        @AuraEnabled public String  companyGSTIN     { get; set; }
        @AuraEnabled public String  customerName     { get; set; }
        @AuraEnabled public String  contactPerson    { get; set; }
        @AuraEnabled public String  mobileNumber     { get; set; }
        @AuraEnabled public String  customerEmail    { get; set; }
        @AuraEnabled public String  customerAddress  { get; set; }
        @AuraEnabled public Decimal grandTotal       { get; set; }
        @AuraEnabled public Decimal pfPercent        { get; set; }
        @AuraEnabled public String  freightCharges   { get; set; }
        @AuraEnabled public String  lineItemsJson    { get; set; }
        @AuraEnabled public String  htmlContent      { get; set; }
        @AuraEnabled public String  recordId         { get; set; }
        @AuraEnabled public List<String> toAddresses  { get; set; }
        @AuraEnabled public List<String> ccAddresses  { get; set; }
        @AuraEnabled public List<String> bccAddresses { get; set; }//added
        @AuraEnabled public String       emailSubject { get; set; }
        @AuraEnabled public String       emailBody    { get; set; }
        @AuraEnabled public String expirationDate;
        @AuraEnabled public String reference;
        @AuraEnabled public String  quotationName  { get; set; }
        @AuraEnabled public String quotationCreatedBy { get; set; }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ NEW: getQuoteLineGroups
    //  Returns all Quote_Line_Group__c records for a Quotation,
    //  ordered by Sort_Order__c ASC.
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=false)
    public static List<Quote_Line_Group__c> getQuoteLineGroups(Id quotationId) {
        if (quotationId == null) {
            throw new AuraHandledException('Quotation Id is required');
        }
        return [
            SELECT Id, Name, Header__c, Sort_Order__c, Quotes__c
            FROM Quote_Line_Group__c
            WHERE Quotes__c  = :quotationId
            ORDER BY Sort_Order__c ASC NULLS LAST
        ];
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ NEW: saveQuoteLineGroup
    //  Creates or updates a Quote_Line_Group__c.
    //  Pass groupId = null to create, or existing Id to update.
    //  Returns the Id of the saved record.
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String saveQuoteLineGroup(String quotationId, String groupId,
                                             String headerName, Decimal sortOrder) {
        try {
            if (String.isBlank(quotationId)) {
                throw new AuraHandledException('Quotation Id is required');
            }
            Quote_Line_Group__c grp = String.isNotBlank(groupId)
                ? new Quote_Line_Group__c(Id = groupId)
                : new Quote_Line_Group__c(Quotes__c  = quotationId);

            grp.Header__c      = headerName;
            grp.Sort_Order__c  = sortOrder;

            upsert grp;
            return grp.Id;
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException('Error saving group: ' + ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ NEW: deleteQuoteLineGroup
    //  Deletes a group. Line items that referenced it become ungrouped
    //  (their Quote_Line_Group__c lookup becomes null automatically
    //   if you set the field to null before deleting, OR you can rely
    //   on a before-delete trigger / the field being non-required).
    //  Here we null-out the FK on children first to avoid orphan issues.
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static void deleteQuoteLineGroup(String groupId) {
        try {
            if (String.isBlank(groupId)) {
                throw new AuraHandledException('Group Id is required');
            }
            // Unlink all line items from this group first
            List<Quotation_Line_Item__c> children = [
                SELECT Id FROM Quotation_Line_Item__c
                WHERE Quote_Line_Group__c = :groupId
            ];
            for (Quotation_Line_Item__c li : children) {
                li.Quote_Line_Group__c = null;
            }
            if (!children.isEmpty()) update children;

            delete new Quote_Line_Group__c(Id = groupId);
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException('Error deleting group: ' + ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ NEW: reorderGroups
    //  Accepts a list of { id, sortOrder } maps and bulk-updates the
    //  Sort_Order__c field so the UI drag-reorder is persisted.
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static void reorderGroups(List<Map<String, Object>> groupOrders) {
        try {
            List<Quote_Line_Group__c> toUpdate = new List<Quote_Line_Group__c>();
            for (Map<String, Object> entry : groupOrders) {
                Quote_Line_Group__c g = new Quote_Line_Group__c(
                    Id           = (String) entry.get('id'),
                    Sort_Order__c = entry.get('sortOrder') != null
                        ? Decimal.valueOf(String.valueOf(entry.get('sortOrder')))
                        : 0
                );
                toUpdate.add(g);
            }
            if (!toUpdate.isEmpty()) update toUpdate;
        } catch (Exception ex) {
            throw new AuraHandledException('Error reordering groups: ' + ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  generateVFPdf  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
   @AuraEnabled
public static String generateVFPdf(String quotationId) {
    try {
        if (String.isBlank(quotationId)) {
            throw new AuraHandledException('Quotation Id is required.');
        }
        PageReference pdfPage = Page.Quotationpdf;
        pdfPage.getParameters().put('quotationId', quotationId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('PDF_TEST_CONTENT');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        Quotation__c q = [
            SELECT Quote_Number__c,
                   Contact_Name__r.Account.Name
            FROM Quotation__c
            WHERE Id = :quotationId
            LIMIT 1
        ];

        String quotNum = String.isNotBlank(q.Quote_Number__c) ? q.Quote_Number__c : quotationId;
        String customerName = (q.Contact_Name__r != null && q.Contact_Name__r.Account != null)
            ? q.Contact_Name__r.Account.Name
            : '';

        String displayName = buildQuotationFileName(quotNum, customerName);
        String fileName = displayName + '.pdf';

        ContentVersion cv = new ContentVersion();
        cv.Title          = displayName;
        cv.PathOnClient   = fileName;
        cv.VersionData    = pdfBlob;
        cv.IsMajorVersion = true;
        insert cv;

        ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        String cdocId = inserted.ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cdocId;
        cdl.LinkedEntityId    = quotationId;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        return cdocId;

    } catch (AuraHandledException ex) {
        throw ex;
    } catch (Exception ex) {
        throw new AuraHandledException('PDF generation failed: ' + ex.getMessage());
    }
}

// ─────────────────────────────────────────────────────────────────────
//  ★ NEW: builds the readable "Quote Number - Customer Name" file name
//  e.g. "MIC 2026-27 Q 008001 - LG"
// ─────────────────────────────────────────────────────────────────────
private static String buildQuotationFileName(String quoteNumber, String customerName) {
    String cleanNumber = String.isNotBlank(quoteNumber) ? quoteNumber : 'Quotation';

    // Turn path separators (the slashes in "MIC/2026-27/Q/00001") into spaces
    cleanNumber = cleanNumber.replaceAll('[\\\\/]+', ' ');

    // Strip anything else that isn't safe in a file name, keep letters/digits/space/hyphen
    cleanNumber = cleanNumber.replaceAll('[^a-zA-Z0-9 \\-]', ' ');

    // Collapse repeated spaces and trim
    cleanNumber = cleanNumber.replaceAll('\\s+', ' ').trim();

    String namePart = String.isNotBlank(customerName) ? customerName.trim() : '';

    return String.isNotBlank(namePart)
        ? cleanNumber + ' - ' + namePart
        : cleanNumber;
}

    // ─────────────────────────────────────────────────────────────────────
    //  getPdfDownloadUrl  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String getPdfDownloadUrl(String contentDocumentId) {
        try {
            if (String.isBlank(contentDocumentId)) {
                throw new AuraHandledException('ContentDocument Id is required.');
            }
            ContentVersion cv = [
                SELECT Id
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                  AND IsLatest = true
                LIMIT 1
            ];
            return '/sfc/servlet.shepherd/version/download/' + cv.Id;
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException('Could not get download URL: ' + ex.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveQuotationPDF  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static String saveQuotationPDF(Map<String, Object> payloadMap) {
        try {
            if (payloadMap == null || payloadMap.isEmpty()) {
                return 'NO_DATA';
            }
            QuotationPayload p = parsePayload(payloadMap);
            if (p == null) return 'NO_DATA';
            String contentDocId = saveAsAttachment(p);
            if (p != null) logActivity(p, contentDocId);
            return contentDocId;
        } catch (Exception ex) {
            System.debug('❌ Save failed: ' + ex.getMessage());
            return 'ERROR';
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  sendQuotationEmail  (UNCHANGED) old
    // ─────────────────────────────────────────────────────────────────────
   /* @AuraEnabled
    public static String sendQuotationEmail(Map<String, Object> payloadMap) {
        try {
            QuotationPayload p = parsePayload(payloadMap);
            if (p.toAddresses == null || p.toAddresses.isEmpty()) {
                throw new AuraHandledException('At least one recipient email is required.');
            }
            String contentDocId = saveAsAttachment(p);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(p.toAddresses);
            if (p.ccAddresses != null && !p.ccAddresses.isEmpty()) {
                mail.setCcAddresses(p.ccAddresses);
            }
            mail.setSubject(String.isNotBlank(p.emailSubject)
                ? p.emailSubject
                : 'Quotation ' + p.quotationNumber + ' from ' + p.companyName);
            mail.setPlainTextBody(String.isNotBlank(p.emailBody) ? p.emailBody : 'Please see attached quotation.');
            mail.setHtmlBody(buildHtmlEmailBody(p));
            mail.setSaveAsActivity(true);
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName('Quotation_' + sanitizeFilename(p.quotationNumber) + '.html');
            att.setBody(Blob.valueOf(p.htmlContent != null ? p.htmlContent : ''));
            att.setContentType('text/html');
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ att });

            /**List<Messaging.SendEmailResult> results = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
            if (results == null || results.isEmpty() || !results[0].isSuccess()) {
                String errMsg = 'Email send failed.';
                if (results != null && !results.isEmpty() && !results[0].getErrors().isEmpty()) {
                    errMsg = results[0].getErrors()[0].getMessage();
                }
                throw new AuraHandledException(errMsg);
            }
            logActivity(p, contentDocId);
            return 'SUCCESS';
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException('Send failed: ' + ex.getMessage());
        }
    }**/
    
@AuraEnabled(cacheable=true)
public static Map<String, String> getEmailTemplateContent(
    String templateName,
    Id quotationId
) {
    try {

        // Get Email Template
        EmailTemplate et = [
            SELECT Id, Subject, HtmlValue, Body
            FROM EmailTemplate
            WHERE Name = :templateName
            LIMIT 1
        ];

        // Get Quotation Details
        Quotation__c q = [
            SELECT Id,
                   Quote_Number__c,
                   Contact_Salutation__c,
                   Contact_Name__c,
                   Contact_Name__r.Name
            FROM Quotation__c
            WHERE Id = :quotationId
            LIMIT 1
        ];

        String subject  = et.Subject;
        String htmlBody = et.HtmlValue;

        // Quote Number
        subject = subject.replace(
            '{{{Quotation__c.Quote_Number__c}}}',
            q.Quote_Number__c != null ? q.Quote_Number__c : ''
        );

        htmlBody = htmlBody.replace(
            '{{{Quotation__c.Quote_Number__c}}}',
            q.Quote_Number__c != null ? q.Quote_Number__c : ''
        );

        // Contact Salutation
        htmlBody = htmlBody.replace(
            '{{{Quotation__c.Contact_Salutation__c}}}',
            q.Contact_Salutation__c != null ? q.Contact_Salutation__c : ''
        );

        // Contact Name
        String contactName = '';

        if (q.Contact_Name__r != null) {
            contactName = q.Contact_Name__r.Name;
        }

        htmlBody = htmlBody.replace(
            '{{{Quotation__c.Contact_Name__c}}}',
            contactName
        );

        return new Map<String, String>{
            'subject'  => subject,
            'htmlBody' => htmlBody,
            'body'     => htmlBody
        };

    } catch (Exception ex) {

        throw new AuraHandledException(
            'Template load failed: ' + ex.getMessage()
        );
    }
}
@AuraEnabled
public static String sendQuotationEmail(Map<String, Object> payloadMap) {
    try {
        QuotationPayload p = parsePayload(payloadMap);

        if (p.toAddresses == null || p.toAddresses.isEmpty()) {
            throw new AuraHandledException(
                'At least one recipient email is required.'
            );
        }

        // ★ Step 1: Invalid emails filter karo (bounce prevention)
        p.toAddresses  = filterValidEmails(p.toAddresses);
        p.ccAddresses  = filterValidEmails(p.ccAddresses);
        p.bccAddresses = filterValidEmails(p.bccAddresses);

        if (p.toAddresses.isEmpty()) {
            throw new AuraHandledException(
                'No valid TO email address found.'
            );
        }

        // ★ Step 2: Email Template
        EmailTemplate et = [
            SELECT Id
            FROM EmailTemplate
            WHERE Name = 'Quotation Email Template'
            LIMIT 1
        ];

        // ★ Step 3: Quotation + Contact (sirf merge-field rendering ke liye chahiye, recipient ke liye NAHI)
        Quotation__c quote = [
            SELECT Id, Contact_Name__c
            FROM Quotation__c
            WHERE Id = :p.recordId
            LIMIT 1
        ];

        if (quote.Contact_Name__c == null) {
            throw new AuraHandledException('Contact not found on Quotation.');
        }

        // ════════════════════════════════════════════════════════════
        // ★★★ FIX #1: Template ko sirf RENDER karo — SEND karne ke liye
        //     use mat karo. Isse merge fields (Subject/Body) resolve ho
        //     jaayenge, lekin targetObjectId (Contact) email recipient
        //     NAHI banega.
        // ════════════════════════════════════════════════════════════
        Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(
            et.Id,
            quote.Contact_Name__c,   // ★ sirf merge field resolution ke liye
            quote.Id                 // ★ {{{Quotation__c.xxx}}} merge fields ke liye
        );

        // ★ Step 4: Ek BILKUL NAYA email object banao — isme targetObjectId
        //   set HI nahi karna, taaki Contact ko email na jaaye.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(p.toAddresses);

        if (p.ccAddresses != null && !p.ccAddresses.isEmpty()) {
            mail.setCcAddresses(p.ccAddresses);
        }
        if (p.bccAddresses != null && !p.bccAddresses.isEmpty()) {
            mail.setBccAddresses(p.bccAddresses);
        }

        // ★ Rendered subject/body use karo (template se aaya hua)
        mail.setSubject(rendered.getSubject());
        mail.setHtmlBody(rendered.getHtmlBody());

        mail.setSaveAsActivity(true);
        mail.setWhatId(quote.Id);      // Activity history Quotation pe log hogi
        mail.setUseSignature(false);

        // ★ Step 5: Org Wide Email
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id FROM OrgWideEmailAddress LIMIT 1
        ];
        if (!oweaList.isEmpty()) {
            mail.setOrgWideEmailAddressId(oweaList[0].Id);
        }

        // ★ Step 6: Attachments
        List<Messaging.EmailFileAttachment> allAttachments =
            new List<Messaging.EmailFileAttachment>();

        if (String.isNotBlank(p.recordId)) {

            // ═══════════════════════════════════
            // PART A: Quotation PDF (sabse pehle attach hota hai)
            // ═══════════════════════════════════
            List<ContentDocumentLink> quoteLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :p.recordId
                ORDER BY SystemModstamp DESC
            ];

            Set<Id> quoteDocIds = new Set<Id>();
            for (ContentDocumentLink cdl : quoteLinks) {
                quoteDocIds.add(cdl.ContentDocumentId);
            }

            if (!quoteDocIds.isEmpty()) {
                List<ContentVersion> quoteFiles = [
                    SELECT Id, Title, VersionData, FileExtension, CreatedDate
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :quoteDocIds
                      AND IsLatest = true
                      AND FileExtension = 'pdf'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                for (ContentVersion cv : quoteFiles) {
                    if (cv.VersionData != null && cv.VersionData.size() > 0) {
                        Messaging.EmailFileAttachment att =
                            new Messaging.EmailFileAttachment();
                        att.setFileName(cv.Title + '.pdf');
                        att.setBody(cv.VersionData);
                        att.setContentType('application/pdf');
                        allAttachments.add(att);
                        System.debug('✅ Quotation PDF attached: ' + cv.Title);
                    }
                }
            }

            // ════════════════════════════════════════════════════════
            // ★★★ FIX #2: Product Catalogues — LINE-ITEM ORDER mein
            // ════════════════════════════════════════════════════════

            // ★ Line items ko Sort_Order__c se order mein fetch karo
            List<Quotation_Line_Item__c> qlis = [
                SELECT Productss__c
                FROM Quotation_Line_Item__c
                WHERE Quotation__c = :p.recordId
                  AND Productss__c != null
                ORDER BY Sort_Order__c ASC NULLS LAST
            ];

            // ★ Set ki jagah List use karo — taaki ORDER preserve ho
            List<Id> orderedProductIds = new List<Id>();
            for (Quotation_Line_Item__c qli : qlis) {
                orderedProductIds.add(qli.Productss__c);
            }

            if (!orderedProductIds.isEmpty()) {

                Set<Id> productIdSet = new Set<Id>(orderedProductIds);

                // ── Bulk fetch: Product → ContentDocumentIds ──
                Map<Id, List<Id>> productToDocIds = new Map<Id, List<Id>>();
                for (ContentDocumentLink cdl : [
                        SELECT ContentDocumentId, LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId IN :productIdSet
                ]) {
                    if (!productToDocIds.containsKey(cdl.LinkedEntityId)) {
                        productToDocIds.put(cdl.LinkedEntityId, new List<Id>());
                    }
                    productToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                }

                // ── Bulk fetch: latest ContentVersion per ContentDocument ──
                Set<Id> allDocIds = new Set<Id>();
                for (List<Id> docList : productToDocIds.values()) {
                    allDocIds.addAll(docList);
                }

                Map<Id, ContentVersion> docIdToVersion = new Map<Id, ContentVersion>();
                if (!allDocIds.isEmpty()) {
                    for (ContentVersion cv : [
                            SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                            FROM ContentVersion
                            WHERE ContentDocumentId IN :allDocIds
                              AND IsLatest = true
                    ]) {
                        docIdToVersion.put(cv.ContentDocumentId, cv);
                    }
                }

                // ── Bulk fetch: Classic Attachments per Product ──
                Map<Id, List<Attachment>> productToClassicAtts = new Map<Id, List<Attachment>>();
                for (Attachment att : [
                        SELECT Id, Name, Body, ContentType, ParentId
                        FROM Attachment
                        WHERE ParentId IN :productIdSet
                ]) {
                    if (!productToClassicAtts.containsKey(att.ParentId)) {
                        productToClassicAtts.put(att.ParentId, new List<Attachment>());
                    }
                    productToClassicAtts.get(att.ParentId).add(att);
                }

                // ════════════════════════════════════════════════════
                // ★ Ab LINE-ITEM ORDER mein hi attach karo
                //   (orderedProductIds wahi sequence hai jo line items mein hai)
                // ════════════════════════════════════════════════════
                for (Id prodId : orderedProductIds) {

                    // Modern Files
                    if (productToDocIds.containsKey(prodId)) {
                        for (Id docId : productToDocIds.get(prodId)) {
                            ContentVersion cv = docIdToVersion.get(docId);
                            if (cv != null && cv.VersionData != null && cv.VersionData.size() > 0) {
                                Messaging.EmailFileAttachment prodAtt =
                                    new Messaging.EmailFileAttachment();
                                String fileName = cv.Title;
                                if (String.isNotBlank(cv.FileExtension)) {
                                    fileName += '.' + cv.FileExtension;
                                }
                                prodAtt.setFileName(fileName);
                                prodAtt.setBody(cv.VersionData);
                                allAttachments.add(prodAtt);
                                System.debug('✅ Product File attached (order-wise): ' + fileName);
                            }
                        }
                    }

                    // Classic Attachments
                    if (productToClassicAtts.containsKey(prodId)) {
                        for (Attachment att : productToClassicAtts.get(prodId)) {
                            if (att.Body != null && att.Body.size() > 0) {
                                Messaging.EmailFileAttachment emailAtt =
                                    new Messaging.EmailFileAttachment();
                                emailAtt.setFileName(att.Name);
                                emailAtt.setBody(att.Body);
                                if (String.isNotBlank(att.ContentType)) {
                                    emailAtt.setContentType(att.ContentType);
                                }
                                allAttachments.add(emailAtt);
                                System.debug('✅ Classic Attachment (order-wise): ' + att.Name);
                            }
                        }
                    }
                }
            }
        }

        System.debug('Total attachments: ' + allAttachments.size());

        if (!allAttachments.isEmpty()) {
            mail.setFileAttachments(allAttachments);
        }

        // ★ Step 7: Send
        List<Messaging.SendEmailResult> results =
            Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail },
                false
            );

        if (results == null ||
            results.isEmpty() ||
            !results[0].isSuccess()) {

            String errMsg = 'Email send failed.';
            if (!results[0].getErrors().isEmpty()) {
                errMsg = results[0].getErrors()[0].getMessage();
            }
            throw new AuraHandledException(errMsg);
        }

        return 'SUCCESS';

    } catch (AuraHandledException ex) {
        throw ex;
    } catch (Exception ex) {
        throw new AuraHandledException('Send failed: ' + ex.getMessage());
    }
}
// @AuraEnabled
// public static String sendQuotationEmail(Map<String, Object> payloadMap) {
//     try {
//         QuotationPayload p = parsePayload(payloadMap);

//         if (p.toAddresses == null || p.toAddresses.isEmpty()) {
//             throw new AuraHandledException(
//                 'At least one recipient email is required.'
//             );
//         }

//         // ★ Step 1: Invalid emails filter karo (bounce prevention)
//         p.toAddresses  = filterValidEmails(p.toAddresses);
//         p.ccAddresses  = filterValidEmails(p.ccAddresses);
//         p.bccAddresses = filterValidEmails(p.bccAddresses);
//         system.debug('Filtered TO: ' + p.toAddresses);
//         system.debug('Filtered CC: ' + p.ccAddresses);
//         system.debug('Filtered BCC: ' + p.bccAddresses);    
//         if (p.toAddresses.isEmpty()) {
//             throw new AuraHandledException(
//                 'No valid TO email address found.'
//             );
//         }

//         // ★ Step 2: Email Template
//         EmailTemplate et = [
//             SELECT Id
//             FROM EmailTemplate
//             WHERE Name = 'Quotation Email Template'
//             LIMIT 1
//         ];

//         // ★ Step 3: Contact Id
//         Quotation__c quote = [
//             SELECT Id, Contact_Name__c
//             FROM Quotation__c
//             WHERE Id = :p.recordId
//             LIMIT 1
//         ];

//         if (quote.Contact_Name__c == null) {
//             throw new AuraHandledException('Contact not found on Quotation.');
//         }

//         // ★ Step 4: Email object
//         Messaging.SingleEmailMessage mail =
//             new Messaging.SingleEmailMessage();

//         mail.setTemplateId(et.Id);
//         mail.setTargetObjectId(quote.Contact_Name__c);
//         mail.setWhatId(quote.Id);
//         mail.setToAddresses(p.toAddresses);

//         if (p.ccAddresses != null && !p.ccAddresses.isEmpty()) {
//             mail.setCcAddresses(p.ccAddresses);
//         }
//         if (p.bccAddresses != null && !p.bccAddresses.isEmpty()) {
//             mail.setBccAddresses(p.bccAddresses);
//         }

//         mail.setSaveAsActivity(true);
//         mail.setUseSignature(false);

//         // ★ Step 5: Org Wide Email
//         List<OrgWideEmailAddress> oweaList = [
//             SELECT Id FROM OrgWideEmailAddress LIMIT 1
//         ];
//         if (!oweaList.isEmpty()) {
//             mail.setOrgWideEmailAddressId(oweaList[0].Id);
//         }

//         // ★ Step 6: Attachments
//         List<Messaging.EmailFileAttachment> allAttachments =
//             new List<Messaging.EmailFileAttachment>();

//         if (String.isNotBlank(p.recordId)) {

//             // ═══════════════════════════════════
//             // PART A: Quotation PDF
//             // ═══════════════════════════════════
//             List<ContentDocumentLink> quoteLinks = [
//                 SELECT ContentDocumentId
//                 FROM ContentDocumentLink
//                 WHERE LinkedEntityId = :p.recordId
//                 ORDER BY SystemModstamp DESC
//             ];

//             Set<Id> quoteDocIds = new Set<Id>();
//             for (ContentDocumentLink cdl : quoteLinks) {
//                 quoteDocIds.add(cdl.ContentDocumentId);
//             }

//             if (!quoteDocIds.isEmpty()) {
//                 List<ContentVersion> quoteFiles = [
//                     SELECT Id, Title, VersionData, FileExtension, CreatedDate
//                     FROM ContentVersion
//                     WHERE ContentDocumentId IN :quoteDocIds
//                       AND IsLatest = true
//                       AND FileExtension = 'pdf'
//                     ORDER BY CreatedDate DESC
//                     LIMIT 1
//                 ];

//                 for (ContentVersion cv : quoteFiles) {
//                     if (cv.VersionData != null &&
//                         cv.VersionData.size() > 0) {

//                         Messaging.EmailFileAttachment att =
//                             new Messaging.EmailFileAttachment();
//                         att.setFileName(cv.Title + '.pdf');
//                         att.setBody(cv.VersionData);
//                         att.setContentType('application/pdf');
//                         allAttachments.add(att);
//                         System.debug('✅ Quotation PDF attached: ' + cv.Title);
//                     }
//                 }
//             }

//             // ═══════════════════════════════════════════
//             // PART B: Product Catalogues
//             // ═══════════════════════════════════════════
//             List<Quotation_Line_Item__c> qlis = [
//                 SELECT Productss__c
//                 FROM Quotation_Line_Item__c
//                 WHERE Quotation__c = :p.recordId
//                   AND Productss__c != null
//             ];

//             Set<Id> productIds = new Set<Id>();
//             for (Quotation_Line_Item__c qli : qlis) {
//                 productIds.add(qli.Productss__c);
//             }

//             if (!productIds.isEmpty()) {

//                 // METHOD 1: Files (ContentDocumentLink)
//                 List<ContentDocumentLink> productLinks = [
//                     SELECT ContentDocumentId
//                     FROM ContentDocumentLink
//                     WHERE LinkedEntityId IN :productIds
//                 ];

//                 Set<Id> productDocIds = new Set<Id>();
//                 for (ContentDocumentLink cdl : productLinks) {
//                     productDocIds.add(cdl.ContentDocumentId);
//                 }

//                 if (!productDocIds.isEmpty()) {
//                     List<ContentVersion> productFiles = [
//                         SELECT Id, Title, VersionData, FileExtension
//                         FROM ContentVersion
//                         WHERE ContentDocumentId IN :productDocIds
//                           AND IsLatest = true
//                     ];

//                     for (ContentVersion cv : productFiles) {
//                         if (cv.VersionData != null &&
//                             cv.VersionData.size() > 0) {

//                             Messaging.EmailFileAttachment prodAtt =
//                                 new Messaging.EmailFileAttachment();
//                             String fileName = cv.Title;
//                             if (String.isNotBlank(cv.FileExtension)) {
//                                 fileName += '.' + cv.FileExtension;
//                             }
//                             prodAtt.setFileName(fileName);
//                             prodAtt.setBody(cv.VersionData);
//                             allAttachments.add(prodAtt);
//                             System.debug('✅ Product File attached: ' + fileName);
//                         }
//                     }
//                 }

//                 // ★ METHOD 2: Classic Attachments
//                 // (Notes & Attachments — "product catalogue2.pdf")
//                 List<Attachment> classicAtts = [
//                     SELECT Id, Name, Body, ContentType
//                     FROM Attachment
//                     WHERE ParentId IN :productIds
//                 ];

//                 for (Attachment att : classicAtts) {
//                     if (att.Body != null && att.Body.size() > 0) {
//                         Messaging.EmailFileAttachment emailAtt =
//                             new Messaging.EmailFileAttachment();
//                         emailAtt.setFileName(att.Name);
//                         emailAtt.setBody(att.Body);
//                         if (String.isNotBlank(att.ContentType)) {
//                             emailAtt.setContentType(att.ContentType);
//                         }
//                         allAttachments.add(emailAtt);
//                         System.debug('✅ Classic Attachment: ' + att.Name);
//                     }
//                 }
//             }
//         }

//         System.debug('Total attachments: ' + allAttachments.size());

//         if (!allAttachments.isEmpty()) {
//             mail.setFileAttachments(allAttachments);
//         }

//         // ★ Step 7: Send
//         List<Messaging.SendEmailResult> results =
//             Messaging.sendEmail(
//                 new List<Messaging.SingleEmailMessage>{ mail },
//                 false
//             );

//         if (results == null ||
//             results.isEmpty() ||
//             !results[0].isSuccess()) {

//             String errMsg = 'Email send failed.';
//             if (!results[0].getErrors().isEmpty()) {
//                 errMsg = results[0].getErrors()[0].getMessage();
//             }
//             throw new AuraHandledException(errMsg);
//         }

//         return 'SUCCESS';

//     } catch (AuraHandledException ex) {
//         throw ex;
//     } catch (Exception ex) {
//         throw new AuraHandledException('Send failed: ' + ex.getMessage());
//     }
// }

// ★ NEW: Valid email filter helper
private static List<String> filterValidEmails(List<String> emails) {
    List<String> valid = new List<String>();
    if (emails == null || emails.isEmpty()) return valid;

    // Simple email validation pattern
    Pattern emailPattern = Pattern.compile(
        '^[a-zA-Z0-9._|\\\\%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
    );

    for (String email : emails) {
        if (String.isNotBlank(email)) {
            String trimmed = email.trim();
            Matcher m = emailPattern.matcher(trimmed);
            if (m.matches()) {
                valid.add(trimmed);
            } else {
                System.debug('⚠️ Invalid email skipped: ' + trimmed);
            }
        }
    }
    return valid;
}


    // ─────────────────────────────────────────────────────────────────────
    //  getQuotations  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Quotation__c> getQuotations(Id recordId) {
        try {
            if (recordId == null) throw new AuraHandledException('Record Id is required');
            List<Quotation__c> quotations = [
                SELECT Id, Name,
                       Quote_Number__c,
                       Contact_Name__r.Name,
                       Contact_Name__r.Account.Name,
                       Email__c,
                       Email_CC__c,        
                       Email_BCC__c, 
                       ContactPhone__c,
                       Quotation_Date__c,
                       Reference__c,
                       Description__c,
                       Expiration_Date__c,
                       Bill_To__Street__s,
                       Bill_To__City__s,
                       Bill_To__StateCode__s,
                       Bill_To__PostalCode__s,
                       Bill_To__CountryCode__s,
                       Bill_To_Name__c,
                       Shipping_and_Handling__c,
                       Quotation_Created_By__c,
                       CurrencyIsoCode
                FROM Quotation__c
                WHERE Id = :recordId
            ];
            if (quotations.isEmpty()) {
                throw new AuraHandledException('No quotation found for this record');
            }
            return quotations;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching quotation: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ UPDATED: getQuotationLineItems
    //  Now includes Quote_Line_Group__c and Sort_Order__c,
    //  ordered by Sort_Order__c ASC so groups stay in sequence.
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=false)
    public static List<Quotation_Line_Item__c> getQuotationLineItems(Id quotationId) {
        if (quotationId == null) {
            throw new AuraHandledException('Quotation Id is required');
        }
        try {
            return [
                SELECT Id,
                       Productss__c,
                       Discount__c,
                       Model_Number__c,   
                       Productss__r.Product_Name__c,
                       Productss__r.HSN_Code__c,
                       Quotation__c,
                       Quantity__c,
                       Line_Description__c,
                       List_Price__c,
                       SubTotal__c,
                       Total_Price__c,
                       Quote_Line_Group__c,
                       Quote_Line_Group__r.Header__c,
                       Sort_Order__c,
                       GST__c
                FROM Quotation_Line_Item__c
                WHERE Quotation__c = :quotationId
                ORDER BY Sort_Order__c ASC NULLS LAST
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching line items: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  saveFullQuotation (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    @AuraEnabled
    public static void saveFullQuotation(Map<String, Object> payloadMap) {
        try {
            if (payloadMap == null) throw new AuraHandledException('No data received');
            Id recId = (Id) payloadMap.get('recordId');
            if (recId == null) throw new AuraHandledException('Quotation Id is required');
            if (recId.getSObjectType() != Quotation__c.SObjectType) {
                throw new AuraHandledException('Invalid Quotation Id');
            }
            Quotation__c q = new Quotation__c(Id = recId);
            String expDateStr = (String) payloadMap.get('validUntil');
            if (String.isNotBlank(expDateStr)) {
                q.Expiration_Date__c = Date.valueOf(expDateStr);
            }
            q.Name           = (String) payloadMap.get('quotationName');
            q.Description__c = (String) payloadMap.get('subject');
            q.Quotation_Created_By__c =(String) payloadMap.get('quotationCreatedBy');
            // if (payloadMap.containsKey('pfPercent')) {
            //     q.P_F__c = Decimal.valueOf(String.valueOf(payloadMap.get('pfPercent')));
            // }
            // if (payloadMap.containsKey('gstPercent')) {
            //     q.Tax__c = Decimal.valueOf(String.valueOf(payloadMap.get('gstPercent')));
            // }
            // freightCharges — null-safe
            Object freightObj = payloadMap.get('freightCharges');
            q.Shipping_and_Handling__c = (freightObj != null)
                ? Decimal.valueOf(String.valueOf(freightObj))
                : 0;

            // pfPercent — already if(containsKey) check hai, but value null bhi ho sakti hai
            if (payloadMap.containsKey('pfPercent') && payloadMap.get('pfPercent') != null) {
                q.P_F__c = Decimal.valueOf(String.valueOf(payloadMap.get('pfPercent')));
            }

            if (payloadMap.containsKey('gstPercent') && payloadMap.get('gstPercent') != null) {
                q.Tax__c = Decimal.valueOf(String.valueOf(payloadMap.get('gstPercent')));
            }
            q.Shipping_and_Handling__c =
                Decimal.valueOf(
                    String.valueOf(
                        payloadMap.get('freightCharges')
                    )
                );
            q.Email__c =
                (String) payloadMap.get('customerEmail');
            q.bill_To__Street__s =
                (String) payloadMap.get('customerAddress');
            q.bill_To__City__s =
                (String) payloadMap.get('customerCity');
            q.bill_To__StateCode__s =
                (String) payloadMap.get('customerState');
            q.bill_To__PostalCode__s =
                (String) payloadMap.get('customerPostalCode');
            q.bill_To__CountryCode__s =
                (String) payloadMap.get('customerCountry');

            // q.ContactPhone__c =
            //     (String) payloadMap.get('mobileNumber');
                        update q;
        } 
        
        // catch (Exception e) {
        //     throw new AuraHandledException('Error saving quotation: ' + e.getMessage());
        // }
  catch (Exception e) {

    String errorMessage = e.getMessage();

    System.debug('FULL ERROR => ' + errorMessage);
    System.debug('ERROR TYPE => ' + e.getTypeName());          // ★ NEW
    System.debug('STACK TRACE => ' + e.getStackTraceString());  // ★ NEW

    if (errorMessage != null && errorMessage.toLowerCase().contains('invalid_email_address')) {
        throw new AuraHandledException('Please enter a valid email address.');
    }
    else if (errorMessage != null && errorMessage.toLowerCase().contains('required_field_missing')) {
        throw new AuraHandledException('Please fill all required fields.');
    }
    else if (errorMessage != null && errorMessage.toLowerCase().contains('duplicate_value')) {
        throw new AuraHandledException('This record already exists.');
    }
    else {
        // ★ TEMP: testing ke time actual error bhi dikhao
        throw new AuraHandledException('Unable to save quotation: ' + errorMessage);
    }
}
    }

    // ─────────────────────────────────────────────────────────────────────
    //  ★ UPDATED: updateQuotationLineItems
    //  Now also persists Quote_Line_Group__c and Sort_Order__c
    //  so group assignments and ordering survive a save.
    // ─────────────────────────────────────────────────────────────────────
    // @AuraEnabled
    // public static void updateQuotationLineItems(List<Quotation_Line_Item__c> items) {
    //     try {
    //         if (items == null || items.isEmpty()) {
    //             throw new AuraHandledException('No items to update');
    //         }
    //         // Quote_Line_Group__c and Sort_Order__c are included on the
    //         // objects passed in from the LWC — just update as-is.
    //         update items;
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Error updating items: ' + e.getMessage());
    //     }
    // }
    @AuraEnabled
public static void updateQuotationLineItems(
    String quotationId,
    List<Quotation_Line_Item__c> items
) {
    try {
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('No items to update');
        }

        List<Quotation_Line_Item__c> toInsert = new List<Quotation_Line_Item__c>();
        List<Quotation_Line_Item__c> toUpdate = new List<Quotation_Line_Item__c>();

        for (Quotation_Line_Item__c item : items) {
            if (item.Id != null) {
                toUpdate.add(item);
            } else {
                // ★ New item — set the parent Quotation
                item.Quotation__c = quotationId;
                toInsert.add(item);
            }
        }

        if (!toUpdate.isEmpty()) update toUpdate;
        if (!toInsert.isEmpty()) insert toInsert;

    } catch (AuraHandledException ex) {
        throw ex;
    } catch (Exception e) {
        throw new AuraHandledException('Error saving items: ' + e.getMessage());
    }
}
    // ─────────────────────────────────────────────────────────────────────
    //  PRIVATE HELPERS  (all UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static Blob generatePdfFromHtml(String htmlContent) {
        try {
            if (String.isBlank(htmlContent)) throw new AuraHandledException('HTML content is required.');
            return Blob.valueOf(htmlContent);
        } catch (Exception ex) {
            throw new AuraHandledException('PDF generation failed: ' + ex.getMessage());
        }
    }

    private static String saveAsAttachment(QuotationPayload p) {
        String html     = p.htmlContent != null ? p.htmlContent : buildMinimalHtml(p);
        String fileName = 'Quotation_' + sanitizeFilename(p.quotationNumber) + '.html';

    if (String.isBlank(p.htmlContent)) {
        System.debug('htmlContent is blank');
        return null;
    }

        ContentVersion cv = new ContentVersion();
        cv.Title          = 'Quotation ' + p.quotationNumber;
        cv.PathOnClient   = fileName;
        cv.VersionData    = Blob.valueOf(html);
        cv.IsMajorVersion = true;
        insert cv;
        ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        String cdocId = inserted.ContentDocumentId;
        if (String.isNotBlank(p.recordId)) {
            try {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cdocId;
                cdl.LinkedEntityId    = p.recordId;
                cdl.ShareType         = 'V';
                cdl.Visibility        = 'AllUsers';
                insert cdl;
            } catch (Exception linkEx) {
                System.debug('Could not link to record: ' + linkEx.getMessage());
            }
        }
        return cdocId;
    }

    private static void logActivity(QuotationPayload p, String contentDocId) {
        try {
            if (p == null) return;
            Task t = new Task();
            t.Subject = 'Quotation Created: ' + (p.quotationNumber != null ? p.quotationNumber : '');
            t.Description =
                'Quotation ' + (p.quotationNumber != null ? p.quotationNumber : '') +
                ' for ' + (p.customerName != null ? p.customerName : '') +
                '\nGrand Total: ' + (p.grandTotal != null ? String.valueOf(p.grandTotal) : '0') +
                '\nContent Doc ID: ' + contentDocId;
            t.Status       = 'Completed';
            t.Priority     = 'Normal';
            t.ActivityDate = Date.today();
            t.OwnerId      = UserInfo.getUserId();
            if (String.isNotBlank(p.recordId)) {
                try { t.WhatId = p.recordId; } catch (Exception e) { System.debug('Invalid WhatId: ' + e.getMessage()); }
            }
            insert t;
        } catch (Exception ex) {
            System.debug('Activity log failed: ' + ex.getMessage());
        }
    }

    private static String buildHtmlEmailBody(QuotationPayload p) {
        String grandTotalStr = p.grandTotal != null ? String.valueOf(p.grandTotal.setScale(2)) : '0.00';
        String bodyText = String.isNotBlank(p.emailBody) ? p.emailBody.replace('\n', '<br/>') : '';
        return '<!DOCTYPE html><html><head><meta charset="UTF-8">' +
            '<style>body{font-family:Arial,sans-serif;background:#f4f6f9;margin:0;padding:20px}' +
            '.wrap{max-width:620px;margin:0 auto;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 10px rgba(0,0,0,.1)}' +
            '.hd{background:#0f3b5e;color:#fff;padding:22px 28px}.hd h2{margin:0;font-size:18px}' +
            '.hd p{margin:4px 0 0;opacity:.8;font-size:12px}.bd{padding:26px;color:#333;font-size:14px;line-height:1.6}' +
            '.sumbox{background:#f0f7ff;border:1px solid #c5dff0;border-radius:6px;padding:14px;margin:18px 0}' +
            '.sumbox h3{margin:0 0 10px;color:#0f3b5e;font-size:13px;text-transform:uppercase;letter-spacing:.05em}' +
            '.row{display:flex;justify-content:space-between;padding:3px 0;font-size:13px;border-bottom:1px solid #dde}' +
            '.row:last-child{border-bottom:none;font-weight:700;color:#0f3b5e;font-size:15px}' +
            '.ft{background:#f4f6f9;padding:12px 28px;text-align:center;font-size:11px;color:#999;border-top:1px solid #eee}' +
            '</style></head><body><div class="wrap">' +
            '<div class="hd"><h2>Quotation from ' + escHtml(p.companyName) + '</h2>' +
            '<p>Techno-Commercial Offer — ' + escHtml(p.quotationNumber) + '</p></div>' +
            '<div class="bd"><p>' + bodyText + '</p>' +
            '<div class="sumbox"><h3>Quotation Summary</h3>' +
            '<div class="row"><span>Quotation No.</span><span>' + escHtml(p.quotationNumber) + '</span></div>' +
            '<div class="row"><span>Date</span><span>' + escHtml(p.quotationDate) + '</span></div>' +
            '<div class="row"><span>Customer</span><span>' + escHtml(p.customerName) + '</span></div>' +
            '<div class="row"><span>Grand Total</span><span>&#8377; ' + grandTotalStr + '</span></div>' +
            '</div><p style="font-size:12px;color:#999">For queries, contact ' +
            escHtml(p.companyPhone) + ' / ' + escHtml(p.companyEmail) + '</p></div>' +
            '<div class="ft">This is an automated message from ' + escHtml(p.companyName) + '</div>' +
            '</div></body></html>';
    }

    private static String buildMinimalHtml(QuotationPayload p) {
        return '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Quotation ' +
            escHtml(p.quotationNumber) + '</title></head><body>' +
            '<h2>' + escHtml(p.companyName) + '</h2>' +
            '<p><strong>Quotation No:</strong> ' + escHtml(p.quotationNumber) + '</p>' +
            '<p><strong>Date:</strong> ' + escHtml(p.quotationDate) + '</p>' +
            '<p><strong>Customer:</strong> ' + escHtml(p.customerName) + '</p>' +
            '<p><strong>Grand Total:</strong> ' +
            (p.grandTotal != null ? String.valueOf(p.grandTotal) : '0') + '</p>' +
            '</body></html>';
    }

    private static QuotationPayload parsePayload(Map<String, Object> m) {
        QuotationPayload p = new QuotationPayload();
        p.quotationNumber = str(m, 'quotationNumber');
        p.quotationDate   = str(m, 'quotationDate');
        p.companyName     = str(m, 'companyName');
        p.companyAddress  = str(m, 'companyAddress');
        p.companyPhone    = str(m, 'companyPhone');
        p.companyEmail    = str(m, 'companyEmail');
        p.companyGSTIN    = str(m, 'companyGSTIN');
        p.customerName    = str(m, 'customerName');
        p.contactPerson   = str(m, 'contactPerson');
        p.mobileNumber    = str(m, 'mobileNumber');
        p.customerEmail   = str(m, 'customerEmail');
        p.customerAddress = str(m, 'customerAddress');
        p.grandTotal      = m.get('grandTotal') != null
            ? Decimal.valueOf(String.valueOf(m.get('grandTotal'))) : 0;
        p.pfPercent       = m.get('pfPercent') != null
            ? Decimal.valueOf(String.valueOf(m.get('pfPercent'))) : 3;
        p.freightCharges  = str(m, 'freightCharges');
        p.lineItemsJson   = str(m, 'lineItemsJson');
        p.htmlContent     = str(m, 'htmlContent');
        p.recordId        = str(m, 'recordId');
        p.emailSubject    = str(m, 'emailSubject');
        p.emailBody       = str(m, 'emailBody');

        Object toObj = m.get('toAddresses');
        if (toObj instanceof List<Object>) {
            p.toAddresses = new List<String>();
            for (Object o : (List<Object>) toObj) p.toAddresses.add(String.valueOf(o));
        }
        Object ccObj = m.get('ccAddresses');
        if (ccObj instanceof List<Object>) {
            p.ccAddresses = new List<String>();
            for (Object o : (List<Object>) ccObj) p.ccAddresses.add(String.valueOf(o));
        }
         Object bccObj = m.get('bccAddresses');

    if (bccObj instanceof List<Object>) {

        p.bccAddresses = new List<String>();

        for (Object o : (List<Object>) bccObj) {
            p.bccAddresses.add(String.valueOf(o));
        }
    }
        return p;
    }

    private static String str(Map<String, Object> m, String key) {
        return m.get(key) != null ? String.valueOf(m.get(key)) : '';
    }

    private static String escHtml(String s) {
        if (s == null) return '';
        return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                .replace('"', '&quot;').replace('\'', '&#39;');
    }

    private static String sanitizeFilename(String filename) {
        if (filename == null) return 'quotation';
        return filename.replaceAll('[^a-zA-Z0-9._-]', '_');
    }
    // ─────────────────────────────────────────────────────────────────────
//  ★ NEW: saveTermsAndConditions
//  Saves all Terms & Conditions fields from the LWC back to Salesforce.
//  Accepts a Map of field keys → values.
// ─────────────────────────────────────────────────────────────────────
@AuraEnabled
public static void saveTermsAndConditions(String quotationId, Map<String, String> termsMap) {
    try {
        if (String.isBlank(quotationId)) {
            throw new AuraHandledException('Quotation Id is required');
        }
        if (termsMap == null || termsMap.isEmpty()) {
            throw new AuraHandledException('No terms data provided');
        }

        Quotation__c q = new Quotation__c(Id = quotationId);

          String paymentTerm = (String) termsMap.get('paymentTerms');

        if (paymentTerm == 'Others' &&
            termsMap.containsKey('paymentTermsCustom')) {

            q.Payment_Term__c =
                (String) termsMap.get('paymentTermsCustom');

        } else {
            q.Payment_Term__c = paymentTerm;
        }
        String deliveryTerm = (String) termsMap.get('deliveryTerms');

        if (deliveryTerm == 'Others' &&
            termsMap.containsKey('deliveryTermsCustom')) {

            q.Delivery_Term__c =
                (String) termsMap.get('deliveryTermsCustom');

        } else {
            q.Delivery_Term__c = deliveryTerm;
        }

        if (termsMap.containsKey('prices'))
            q.Prices1__c = termsMap.get('prices');

        if (termsMap.containsKey('taxes'))
            q.Taxes__c = termsMap.get('taxes');

        if (termsMap.containsKey('gstnPan'))
            q.GSTN_PAN__c = termsMap.get('gstnPan');

        if (termsMap.containsKey('msme'))
            q.MSME_ZED_Udyam_Reg_No__c = termsMap.get('msme');

        if (termsMap.containsKey('transit'))
            q.Transit_Insurance__c = termsMap.get('transit');

        if (termsMap.containsKey('commissioning'))
            q.Commissioning__c = termsMap.get('commissioning');

        if (termsMap.containsKey('inspection'))
            q.Inspection__c = termsMap.get('inspection');

        if (termsMap.containsKey('validity'))
            q.Validity__c = termsMap.get('validity');

        if (termsMap.containsKey('scope'))
            q.Scope__c = termsMap.get('scope');

        if (termsMap.containsKey('warranty'))
            q.Warranty__c = termsMap.get('warranty');

        if (termsMap.containsKey('forceMajeure'))
            q.Force_Majeure__c = termsMap.get('forceMajeure');

        if (termsMap.containsKey('jurisdiction'))
            q.Jurisdiction__c = termsMap.get('jurisdiction');

        update q;

    } catch (AuraHandledException ex) {
        throw ex;
    } catch (Exception ex) {
        throw new AuraHandledException('Error saving Terms & Conditions: ' + ex.getMessage());
    }
}
// public class SendEmailController {
 
//     public static void sendQuoteEmail(Id quoteId) {
 
//         /*
//          * TO / CC / BCC
//          */
//         List<String> toAddress = new List<String>{
//             'test@example.com'
//         };
 
//         List<String> ccAddress = new List<String>{
//             'cc@example.com'
//         };
 
//         List<String> bccAddress = new List<String>{
//             'bcc@example.com'
//         };
 
//         /*
//          * EMAIL
//          */
//         Messaging.SingleEmailMessage mail =
//             new Messaging.SingleEmailMessage();
 
//         mail.setToAddresses(toAddress);
 
//         mail.setCcAddresses(ccAddress);
 
//         mail.setBccAddresses(bccAddress);
 
//         mail.setSubject('Quote Documents');
 
//         mail.setPlainTextBody(
//             'Please find attached Quote PDF and Product Catalogs.'
//         );
 
//         /*
//          * ALL ContentDocumentIds
//          */
//         Set<Id> contentDocumentIds = new Set<Id>();
 
 
//         /*****************************************************************
//          * 1. GET QUOTE PDF ATTACHMENT
//          *****************************************************************/
//         List<ContentDocumentLink> quoteFiles = [
 
//             SELECT Id,
//                    ContentDocumentId,
//                    LinkedEntityId
//             FROM ContentDocumentLink
//             WHERE LinkedEntityId = :quoteId
//         ];
 
//         for (ContentDocumentLink cdl : quoteFiles) {
 
//             contentDocumentIds.add(cdl.ContentDocumentId);
//         }
 
 
//         /*****************************************************************
//          * 2. GET QUOTE LINE ITEMS
//          *****************************************************************/
//         List<Quotation_Line_Item__c> quoteLineList = [
 
//             SELECT Id,
//                    Productss__c
//             FROM Quotation_Line_Item__c
//             WHERE Quotation__c = :quoteId
//         ];
 
//         Set<Id> productIds = new Set<Id>();
 
//         for (Quotation_Line_Item__c qli : quoteLineList) {
 
//             if (qli.Productss__c != null) {
 
//                 productIds.add(qli.Productss__c);
//             }
//         }
 
 
//         /*****************************************************************
//          * 3. GET PRODUCT CATALOG FILES
//          *****************************************************************/
//         if (!productIds.isEmpty()) {
 
//             List<ContentDocumentLink> productFiles = [
 
//                 SELECT Id,
//                        ContentDocumentId,
//                        LinkedEntityId
//                 FROM ContentDocumentLink
//                 WHERE LinkedEntityId IN :productIds
//             ];
 
//             for (ContentDocumentLink cdl : productFiles) {
 
//                 contentDocumentIds.add(
//                     cdl.ContentDocumentId
//                 );
//             }
//         }
 
 
//         /*****************************************************************
//          * 4. GET ACTUAL FILE DATA
//          *****************************************************************/
//         List<Messaging.EmailFileAttachment> attachmentList =
//             new List<Messaging.EmailFileAttachment>();
 
//         if (!contentDocumentIds.isEmpty()) {
 
//             List<ContentVersion> versionList = [
 
//                 SELECT Id,
//                        Title,
//                        FileExtension,
//                        VersionData
//                 FROM ContentVersion
//                 WHERE ContentDocumentId IN :contentDocumentIds
//                 AND IsLatest = true
//             ];
 
//             for (ContentVersion cv : versionList) {
 
//                 Messaging.EmailFileAttachment attachment =
//                     new Messaging.EmailFileAttachment();
 
//                 attachment.setFileName(
//                     cv.Title + '.' + cv.FileExtension
//                 );
 
//                 attachment.setBody(cv.VersionData);
 
//                 attachmentList.add(attachment);
//             }
//         }
 
 
//         /*****************************************************************
//          * 5. ADD ATTACHMENTS
//          *****************************************************************/
//         if (!attachmentList.isEmpty()) {
 
//             mail.setFileAttachments(attachmentList);
//         }
 
 
//         /*****************************************************************
//          * 6. SEND EMAIL
//          *****************************************************************/
//         Messaging.sendEmail(
//             new Messaging.SingleEmailMessage[] { mail }
//         );
//     }
// } 
    @AuraEnabled
    public static void deleteQuotationLineItem(String lineItemId) {

        try {

            if (String.isBlank(lineItemId)) {
                throw new AuraHandledException('Line Item Id is required');
            }

            delete [
                SELECT Id
                FROM Quotation_Line_Item__c
                WHERE Id = :lineItemId
                LIMIT 1
            ];

        } catch (Exception ex) {

            throw new AuraHandledException(
                'Unable to delete item. Please try again.'
            );
        }
    }

}