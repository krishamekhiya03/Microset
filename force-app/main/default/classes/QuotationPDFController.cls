/**
* QuotationPDFController v2.0
* ─────────────────────────────────────────────────────────────────────────
* CHANGES FROM v1.0:
*   + Added GroupWrapper inner class to hold a group header + its line items.
*   + Added groupedItems  — list of GroupWrapper (groups with items beneath).
*   + Added ungroupedItems — line items that have no group assigned.
*   + loadQuotation() now queries groups first, then assigns line items
*     into groups or into ungroupedItems based on Quote_Line_Group__c.
*   + lineItems property is KEPT for backward-compatibility (contains ALL
*     items flat, used for totals calculation — unchanged).
*
* All existing properties and helpers are UNCHANGED.
* ─────────────────────────────────────────────────────────────────────────
*/
public with sharing class QuotationPDFController {
    
    // ─── Company defaults ─────────────────────────────────────────────────
    public String companyName     { get; set; }
    public String companyTagline  { get; set; }
    public String companyAddress  { get; set; }
    public String companyPhone    { get; set; }
    public String companyEmail    { get; set; }
    public String companyWebsite  { get; set; }
    
    // ─── Quotation header ─────────────────────────────────────────────────
    public String  quotationNumber        { get; set; }
    public String  quotationDateFormatted { get; set; }
    public String  validUntilFormatted    { get; set; }
    public String  reference              { get; set; }
    public String  subject                { get; set; }
    public Boolean hasTermsRows           { get; set; }
    Public String quotationCreatedByName { get; set; }
    
    // ─── Customer ─────────────────────────────────────────────────────────
    public String customerName    { get; set; }
    public String contactPerson   { get; set; }
    public String mobileNumber    { get; set; }
    public String customerEmail   { get; set; }
    public String customerAddress { get; set; }
    
    // ─── Charges / Terms ──────────────────────────────────────────────────
    public Decimal pfPercent       { get; set; }
    public String  freightCharges  { get; set; }
    public String  paymentTerms    { get; set; }
    public String  delivery        { get; set; }
    public String  warranty        { get; set; }
    public String  pricesBasis     { get; set; }
    public String  additionalNotes { get; set; }
    
    public String payment { get; set; }
    public String prices { get; set; }
    // public String courier { get; set; }
    public String transit { get; set; }
    // public String price { get; set; }
    public String deliveryTerms { get; set; }
    // public String customClearance { get; set; }
    public String validity { get; set; }
    public String scope { get; set; }
    public String forceMajeure { get; set; }
    public String jurisdiction { get; set; }
    public String warrantyTerms { get; set; }
    // public String sensorCondition { get; set; }
    public String MSME_ZED_Udyam_Reg_No { get; set; }
    public String GSTN_PAN { get; set; }
    public String tax { get; set; }
    public String inspection { get; set; }
    public String commissioning { get; set; }
    public String transitInsurance { get; set; }
    public String currencyCode { get; set; }   // ★ NEW: e.g. "INR" or "USD"
    public String currencySymbol { get; set; }
    // ─── Totals (formatted) ───────────────────────────────────────────────
    public String subtotalFmt  { get; set; }
    public String totalDiscFmt { get; set; }
    public String totalGSTFmt  { get; set; }
    public String pfAmtFmt     { get; set; }
    public String grandTotalFmt{ get; set; }
    public Boolean showDiscountColumn { get; set; }
    public Decimal subtotalAmount { get; set; }
    public Decimal freightAmount { get; set; }
    public Decimal pfAmount { get; set; }
    public Decimal gstAmount { get; set; }
    public Decimal grandAmount { get; set; }
    
    public String freightFmt { get; set; }
    public String freightDisplay { get; set; }
    public String offerNumber { get; set; }
public String offerDate   { get; set; }
public String contactSalutation { get; set; }
    
    // ─── All line items flat (for totals / backward-compat) ───────────────
    public List<LineItemWrapper> lineItems { get; set; }
    
    // ─── ★ NEW: Grouped line items for PDF rendering ──────────────────────
    public List<GroupWrapper>    groupedItems   { get; set; }
    public List<LineItemWrapper> ungroupedItems { get; set; }
    
    // ─── ★ NEW: flag — true if any groups exist ───────────────────────────
    public Boolean hasGroups { get; set; }
    public Boolean isOrderPDF { get; set; }
    
    // ─────────────────────────────────────────────────────────────────────
    //  ★ NEW INNER CLASS: GroupWrapper
    // ─────────────────────────────────────────────────────────────────────
    public class GroupWrapper {
        public String            groupId    { get; set; }
        public Integer groupIndex { get; set; }
        public String            headerName { get; set; }
        public Decimal           sortOrder  { get; set; }
        public List<LineItemWrapper> lines  { get; set; }
        
        public GroupWrapper(Quote_Line_Group__c g) {
            this.groupId    = g.Id;
            this.headerName = g.Header__c;
            this.sortOrder  = g.Sort_Order__c;
            this.lines      = new List<LineItemWrapper>();
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    //  INNER CLASS: LineItemWrapper  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    public class LineItemWrapper {
        public Integer itemNumber   { get; set; }
        public String sequenceLabel { get; set; }
        public String  productName  { get; set; }
        public String hsnCode      { get; set; }
         public String modelNumber  { get; set; }
        public String  description  { get; set; }
        public Decimal quantity     { get; set; }
        public String  unit         { get; set; }
        public Decimal discount     { get; set; }
        public Decimal gst          { get; set; }
        public Decimal unitPrice    { get; set; }
        public Boolean isHighlighted{ get; set; }
        public Boolean hasDiscount  { get; set; }
        
        // Formatted strings
        public String unitPriceFmt  { get; set; }
        public String afterDiscFmt  { get; set; }
        public String itemTotalFmt  { get; set; }
        public String qtyDisplay    { get; set; }
        
        public List<String> imageUrls { get; set; }
        
    }
    
    // ─────────────────────────────────────────────────────────────────────
    //  CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────────────
    public QuotationPDFController() {
        // ── Company defaults ──
        this.companyName    = 'MicroSet Instrumentation & Controls';
        this.companyTagline = 'Instrumentation & Controls';
        this.companyAddress = '102 Chinmay 1103A, 10 Lakaki Road, Model Colony, Shivajinagar, Pune 411016';
        this.companyPhone   = '+91 9112455550';
        this.companyEmail   = 'info@MicroSetindia.com';
        this.companyWebsite = 'www.MicroSetindia.com';
        
        // ── Charge / Term defaults ──
        this.pfPercent      = 3;
        this.freightCharges = 'EXTRA AT ACTUAL';
        this.paymentTerms   = '100% along with PO';
        this.delivery       = '3 to 4 weeks from payment';
        this.warranty       = '12 months from date of sale';
        this.pricesBasis    = 'FOB Pune (India)';
        this.additionalNotes= '';
        
        this.lineItems      = new List<LineItemWrapper>();
        this.groupedItems   = new List<GroupWrapper>();
        this.ungroupedItems = new List<LineItemWrapper>();
        this.hasGroups      = false;
        
        String qId = ApexPages.currentPage().getParameters().get('quotationId');
        
        if (String.isNotBlank(qId)) {
            
            loadQuotation(qId);
        }
        
        
        // ===== ORDER PDF SUPPORT =====
        
        String orderId = ApexPages.currentPage().getParameters().get('id');
        
        if(String.isNotBlank(orderId)){
            
            String objectName =
                Id.valueOf(orderId)
                .getSObjectType()
                .getDescribe()
                .getName();
            
            if(objectName == 'Order__c'){
                
                loadOrder(orderId);
            }
        }
    }
    
    
    // ─────────────────────────────────────────────────────────────────────
    //  PRIVATE: loadQuotation
    // ─────────────────────────────────────────────────────────────────────
    private void loadQuotation(String quotationId) {
        try {
            // ── Header ──
            List<Quotation__c> quotations = [
                SELECT Id, Name,
                Quote_Number__c,
                Contact_Name__r.Name,
                Contact_Name__r.Account.Name,
                Account_Name__r.Name,
                Email__c,
                ContactPhone__c,
                Contact_Salutation__c, 
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
                Payment_Term__c,
                Prices1__c,
                // Courier_Transport_Charges__c,
                Transit_Insurance__c,
                // Prices2__c,
                Delivery_Term__c,
                // Custom_Clearance__c,
                // Validity_of_Quotation__c,
                Validity__c,
                Inspection__c,
                Commissioning__c,
                MSME_ZED_Udyam_Reg_No__c,
                GSTN_PAN__c,
                Taxes__c,
                Scope__c,
                Force_Majeure__c,
                Jurisdiction__c,
                Warranty__c,
                Quotation_Created_By__c,
                Total_Price__c,
                Shipping_and_Handling__c,
                P_F__c,
                GST_Amount__c,
                Total_GST__c,
                Grand_Total__c,
                CurrencyIsoCode
                
                // Sensor_Electrode_Performance_Conditions__c
                FROM Quotation__c
                WHERE Id = :quotationId
                LIMIT 1
            ];
            
            if (quotations.isEmpty()) return;
            Quotation__c q = quotations[0];
            
            this.quotationNumber        = q.Quote_Number__c;
            this.quotationDateFormatted = formatDate(q.Quotation_Date__c);
            this.isOrderPDF = false;
            this.validUntilFormatted    = formatDate(q.Expiration_Date__c);
            this.reference              = q.Reference__c;
            this.subject                = q.Description__c;
            // this.contactPerson          = q.Contact_Name__r != null ? q.Contact_Name__r.Name : '';
            this.contactPerson   = q.Contact_Name__r != null ? q.Contact_Name__r.Name : '';
            this.contactSalutation = q.Contact_Salutation__c; 
            // this.customerName           = q.Name != null ? q.Name : '';
            this.customerName = (q.Account_Name__r != null && String.isNotBlank(q.Account_Name__r.Name))
            ? q.Account_Name__r.Name
            : q.Name;
            this.customerEmail          = q.Email__c;
            this.mobileNumber           = q.ContactPhone__c;
            // this.payment = q.Payment__c;
            this.paymentTerms = q.Payment_Term__c;
            this.prices = q.Prices1__c;
            // this.courier = q.Courier_Transport_Charges__c;
            this.transit = q.Transit_Insurance__c;
            // this.price = q.Prices2__c;
            this.deliveryTerms = q.Delivery_Term__c;
            // this.customClearance = q.Custom_Clearance__c;
            // this.validity = q.Validity_of_Quotation__c;
            // this.warranty = q.Warranty__c;
            this.validity = q.Validity__c;
            this.inspection = q.Inspection__c;
            this.commissioning = q.Commissioning__c;
            this.MSME_ZED_Udyam_Reg_No = q.MSME_ZED_Udyam_Reg_No__c;
            this.GSTN_PAN = q.GSTN_PAN__c;
            this.tax = q.Taxes__c;
            this.scope = q.Scope__c;
            this.forceMajeure = q.Force_Majeure__c;
            this.jurisdiction = q.Jurisdiction__c;
            this.warrantyTerms = q.Warranty__c;
            // this.sensorCondition = q.Sensor_Electrode_Performance_Conditions__c;
            this.quotationCreatedByName = q.Quotation_Created_By__c ;
            this.subtotalAmount = q.Total_Price__c;
            this.freightAmount = q.Shipping_and_Handling__c;
            this.pfAmount = q.P_F__c;
            this.gstAmount = q.Total_GST__c;
            this.grandAmount = q.Grand_Total__c;
            this.offerNumber = q.Quote_Number__c;
            this.offerDate   = formatDate(q.Quotation_Date__c);
            // this.currencyCode = q.CurrencyIsoCode;
            this.currencyCode = String.isNotBlank(q.CurrencyIsoCode) ? q.CurrencyIsoCode : 'INR';
            this.currencySymbol = (this.currencyCode == 'USD') ? 'USD' : 'INR';
            List<String> addrParts = new List<String>();
            if (String.isNotBlank(q.Bill_To__Street__s))     addrParts.add(q.Bill_To__Street__s);
            if (String.isNotBlank(q.Bill_To__City__s))       addrParts.add(q.Bill_To__City__s);
            if (String.isNotBlank(q.Bill_To__StateCode__s))  addrParts.add(q.Bill_To__StateCode__s);
            if (String.isNotBlank(q.Bill_To__PostalCode__s)) addrParts.add(q.Bill_To__PostalCode__s);
            if (String.isNotBlank(q.Bill_To__CountryCode__s))addrParts.add(q.Bill_To__CountryCode__s);
            // if (String.isNotBlank(q.Bill_To_Name__c))        addrParts.add(q.Bill_To_Name__c);
            this.customerAddress = String.join(addrParts, ', ');
            
            this.hasTermsRows = String.isNotBlank(this.paymentTerms)
                || String.isNotBlank(this.delivery)
                || String.isNotBlank(this.pricesBasis)
                || q.Expiration_Date__c != null;
            
            // ── ★ NEW: Load Groups ordered by Sort_Order__c ──
            List<Quote_Line_Group__c> groups = [
                SELECT Id, Header__c, Sort_Order__c
                FROM Quote_Line_Group__c
                WHERE Quotes__c = :quotationId
                ORDER BY Sort_Order__c ASC NULLS LAST
            ];
            
            // Build a map: groupId → GroupWrapper
            Map<String, GroupWrapper> groupMap = new Map<String, GroupWrapper>();
            for (Quote_Line_Group__c g : groups) {
                GroupWrapper gw = new GroupWrapper(g);
                groupMap.put(g.Id, gw);
                this.groupedItems.add(gw);
            }
            this.hasGroups = !groups.isEmpty();
            
            // ── Line Items ordered by Sort_Order__c ──
            List<Quotation_Line_Item__c> dbItems = [
                SELECT Id,
                Productss__c,
                Productss__r.Product_Name__c,
                Productss__r.HSN_Code__c,
                Model_Number__c, 
                Quotation__c,
                Quantity__c,
                Line_Description__c,
                List_Price__c,
                SubTotal__c,
                Total_Price__c,
                Discount__c,
                Quote_Line_Group__c,
                Sort_Order__c
                FROM Quotation_Line_Item__c
                WHERE Quotation__c = :quotationId
                ORDER BY Sort_Order__c ASC NULLS LAST
            ];
            
            // ==========================================
            // COLLECT LINE ITEM IDS
            // ==========================================
            
            Set<Id> lineItemIds = new Set<Id>();
            
            for (Quotation_Line_Item__c li : dbItems) {
                lineItemIds.add(li.Id);
            }
            
            // ==========================================
            // MAP: LINE ITEM -> MULTIPLE IMAGE URLS
            // ==========================================
            
            Map<Id, List<String>> lineItemImageMap =
                new Map<Id, List<String>>();
            
            // ==========================================
            // FETCH FILES
            // ==========================================
            
            List<ContentDocumentLink> fileLinks = [
                
                SELECT LinkedEntityId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.FileExtension
                
                FROM ContentDocumentLink
                
                WHERE LinkedEntityId IN :lineItemIds
            ];
            
            // ==========================================
            // BUILD IMAGE URLS
            // ==========================================
            
            for (ContentDocumentLink cdl : fileLinks) {
                
                String ext = cdl.ContentDocument.FileExtension;
                
                if (ext != null) {
                    
                    ext = ext.toLowerCase();
                    
                    // ONLY IMAGE FILES
                    if (ext == 'jpg' ||
                        ext == 'jpeg' ||
                        ext == 'png') {
                            
                            String imageUrl =
                                
                                URL.getOrgDomainUrl().toExternalForm()
                                
                                + '/sfc/servlet.shepherd/version/renditionDownload'
                                
                                + '?rendition=THUMB720BY480'
                                
                                + '&versionId='
                                
                                + cdl.ContentDocument.LatestPublishedVersionId;
                            
                            System.debug('Image URL => ' + imageUrl);
                            
                            // CREATE LIST
                            if (!lineItemImageMap.containsKey(cdl.LinkedEntityId)) {
                                
                                lineItemImageMap.put(
                                    cdl.LinkedEntityId,
                                    new List<String>()
                                );
                                System.debug('LinkedEntityId => ' + cdl.LinkedEntityId);
                            }
                            
                            // ADD IMAGE
                            lineItemImageMap
                                .get(cdl.LinkedEntityId)
                                .add(imageUrl);
                        }
                    
                }
            }
            
            Integer num = 0;
            Decimal subtotal  = 0;
            Decimal totalDisc = 0;
            Decimal totalGST  = 0;
            
            for (Quotation_Line_Item__c dbLi : dbItems) {
                num++;
                LineItemWrapper w = new LineItemWrapper();
                w.itemNumber   = num;
                w.productName  = dbLi.Productss__r != null ? dbLi.Productss__r.Product_Name__c : '';
                w.hsnCode      = dbLi.Productss__r != null ? dbLi.Productss__r.HSN_Code__c : '';
                w.modelNumber  = String.isNotBlank(dbLi.Model_Number__c) ? dbLi.Model_Number__c : '';
                // w.description  = String.isNotBlank(dbLi.Line_Description__c) ? dbLi.Line_Description__c : '';
              //  w.description = String.isNotBlank(dbLi.Line_Description__c)
                //    ? dbLi.Line_Description__c
                  //  .replaceAll('(\r\n|\r|\n)', '<br/>')
                    //: '';
                    w.description = String.isNotBlank(dbLi.Line_Description__c)
                        ? sanitizeForPdf(dbLi.Line_Description__c).replaceAll('(\r\n|\r|\n)', '<br/>')
                        : '';
                w.imageUrls = new List<String>();
                if (lineItemImageMap.containsKey(dbLi.Id)) {
                    w.imageUrls = lineItemImageMap.get(dbLi.Id);
                    System.debug(
                        'Images Found For Line Item => '
                        + dbLi.Id
                        + ' Count => '
                        + lineItemImageMap.get(dbLi.Id).size()
                    );  
                }
                w.quantity     = dbLi.Quantity__c   != null ? dbLi.Quantity__c   : 0;
                w.unitPrice    = dbLi.List_Price__c != null ? dbLi.List_Price__c : 0;
                w.unit         = '';
                w.discount     = 0;
                // w.gst          = 18;
                w.gst          = Decimal.valueOf(System.Label.GST_Amount);
                w.isHighlighted= false;
                
                // Decimal base      = w.quantity * w.unitPrice;
                // Decimal discAmt   = base * (w.discount / 100);
                // Decimal afterDisc = base - discAmt;
                // Decimal gstAmt    = afterDisc * (w.gst / 100);
                // Decimal itemTotal = afterDisc + gstAmt;
                // Decimal base = w.quantity * w.unitPrice;
                
                // ✅ take discount from DB
                w.discount = dbLi.Discount__c != null ? dbLi.Discount__c : 0;
                
                // ✅ base price
                Decimal base = w.quantity * w.unitPrice;
                
                // ✅ discount amount
                Decimal discAmt = 0;
                if (w.discount > 0) {
                    discAmt = (base * w.discount) / 100;
                }
                
                // ✅ after discount
                Decimal afterDisc = base - discAmt;
                
                // ✅ GST
                // Decimal gstAmt = (afterDisc * w.gst) / 100;
                
                // // ✅ final total
                // Decimal itemTotal = afterDisc + gstAmt;
                // ❌ REMOVE GST from item level
                Decimal itemTotal = afterDisc; // only after discount
                
                Decimal gstAmt = 0; // GST will be calculated at final level
                
                w.hasDiscount  = w.discount > 0;
                w.unitPriceFmt = fmtDecimal(w.unitPrice);
                w.afterDiscFmt = fmtDecimal(afterDisc);
                w.itemTotalFmt = fmtDecimal(itemTotal);
                w.qtyDisplay   = String.valueOf(Integer.valueOf(Math.ceil(w.quantity))).leftPad(2, '0')
                    + ' ' + w.unit;
                
                // subtotal  += base;
                // totalDisc += discAmt;
                // totalGST  += gstAmt;
                subtotal  += itemTotal; // after discount only
                totalDisc += discAmt;
                // ❌ do NOT add GST here
                
                // Always add to flat list (for totals)
                this.lineItems.add(w);
                
                // ★ Route into group or ungrouped
                String grpId = dbLi.Quote_Line_Group__c;
                if (String.isNotBlank(grpId) && groupMap.containsKey(grpId)) {
                    groupMap.get(grpId).lines.add(w);
                } else {
                    this.ungroupedItems.add(w);
                }
            }
            
            // ── Totals ──
            // Decimal pfAmt      = (subtotal - totalDisc) * (this.pfPercent / 100);
            // Decimal grandTotal = (subtotal - totalDisc) + totalGST + pfAmt;
            // ── Totals ──
            
            // ── Totals ──
            
            // // P&F on subtotal (already after discount)
            // Decimal pfAmt = subtotal * (this.pfPercent / 100);
            
            // // Taxable amount
            // Decimal taxableAmount = subtotal + pfAmt;
            
            // // GST on total (not per item)
            // totalGST = (taxableAmount * 18) / 100;
            
            // // Final total
            // Decimal grandTotal = taxableAmount + totalGST;

            // ★ Custom Label se GST rate lo
            Decimal gstRate = Decimal.valueOf(System.Label.GST_Amount);

            // USD quotations pe P&F/Freight ke upar GST nahi lagta
            Boolean isUSD = (this.currencyCode == 'USD');

            // P&F on subtotal (already after discount)
            Decimal pfAmt = subtotal * (this.pfPercent / 100);

            // Taxable amount
            Decimal taxableAmount = subtotal + pfAmt;

            // GST on total — INR pe Custom Label rate, USD pe 0
            totalGST = isUSD ? 0 : (taxableAmount * gstRate) / 100;

            // Final total
            Decimal grandTotal = taxableAmount + totalGST;
            
            // this.subtotalFmt   = fmtDecimal(subtotal);
            // this.totalDiscFmt  = fmtDecimal(totalDisc);
            // this.totalGSTFmt   = fmtDecimal(totalGST);
            // this.pfAmtFmt      = fmtDecimal(pfAmt);
            // this.grandTotalFmt = fmtDecimal(grandTotal);
            this.subtotalFmt   = fmtDecimal(this.subtotalAmount);
            // this.freightFmt    = fmtDecimal(this.freightAmount);
            // if (this.freightAmount == null || this.freightAmount == 0) {
            //     this.freightDisplay = 'EXTRA AT ACTUAL';
            // } else {
            //     this.freightDisplay =
            //         '₹ ' + fmtDecimal(this.freightAmount);
            // }
            if (this.freightAmount == null || this.freightAmount == 0) {
                this.freightDisplay =
                    '<span style="font-size:8pt; font-weight:bold;">EXTRA AT ACTUAL</span>';
            } else {
                this.freightDisplay =
                    '₹ ' + fmtDecimal(this.freightAmount);
            }
            
            // this.pfAmtFmt      = fmtDecimal(this.pfAmount);
            Decimal pfCalculatedAmount =
                (this.subtotalAmount * this.pfAmount) / 100;
            
            this.pfAmtFmt =
                fmtDecimal(pfCalculatedAmount);
            this.totalGSTFmt   = fmtDecimal(this.gstAmount);
            this.grandTotalFmt = fmtDecimal(this.grandAmount);
            
            // =====================================
            // ✅ ADD HERE (END OF METHOD)
            // =====================================
            // Integer groupCounter = 0;
            // String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            
            // for (GroupWrapper grp : this.groupedItems) {
            
            //     groupCounter++;
            //     grp.groupIndex = groupCounter; // 1,2,3...
            
            //     Integer itemCounter = 0;
            
            //     for (LineItemWrapper li : grp.lines) {
            
            //         itemCounter++;
            
            //         String alpha = letters.substring(itemCounter - 1, itemCounter);
            
            //         li.sequenceLabel = groupCounter + alpha; // 1A, 1B...
            //     }
            // }
            
            Integer mainCounter = 0;
            String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            
            // ===== GROUP ITEMS =====
            for (GroupWrapper grp : this.groupedItems) {
                
                mainCounter++; // 1,2,3...
                grp.groupIndex = mainCounter;
                
                Integer subCounter = 0;
                
                for (LineItemWrapper li : grp.lines) {
                    subCounter++;
                    
                    String alpha = letters.substring(subCounter - 1, subCounter);
                    
                    li.sequenceLabel = mainCounter + alpha; // 1A,1B
                }
            }
            
            // ===== STANDALONE ITEMS =====
            for (LineItemWrapper li : this.ungroupedItems) {
                
                mainCounter++; // continue numbering
                
                li.sequenceLabel = String.valueOf(mainCounter); // 2,3,4
            }
            
        } catch (Exception ex) {
            System.debug('QuotationPDFController error: ' + ex.getMessage());
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────
    //  PRIVATE: helpers  (UNCHANGED)
    // ─────────────────────────────────────────────────────────────────────
    private static String formatDate(Date d) {
        if (d == null) return '';
        String[] months = new String[]{ 'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec' };
                return String.valueOf(d.day()).leftPad(2, '0') + '-'
                + months[d.month() - 1] + '-'
                + String.valueOf(d.year());
    }
    
    private static String fmtDecimal(Decimal val) {
        if (val == null) val = 0;
        String formatted = val.setScale(2).toPlainString();
        List<String> parts = formatted.split('\\.');
        String intPart = parts[0];
        String decPart = parts.size() > 1 ? parts[1] : '00';
        
        String result = '';
        if (intPart.length() <= 3) {
            result = intPart;
        } else {
            String last3 = intPart.substring(intPart.length() - 3);
            String rest   = intPart.substring(0, intPart.length() - 3);
            String restComma = '';
            Integer restLen = rest.length();
            for (Integer i = 0; i < restLen; i++) {
                restComma += rest.substring(i, i + 1);
                Integer remaining = restLen - i - 1;
                if (remaining > 0 && Math.mod(remaining, 2) == 0) {
                    restComma += ',';
                }
            }
            result = restComma + ',' + last3;
        }
        return result + '.' + decPart;
    }
    
    private void loadOrder(String orderId){

    Order__c ord = [

        SELECT Id,
               Order_SO_Number__c,
               EffectiveDate__c,
               Quotes__c,
               Account__r.Name

        FROM Order__c

        WHERE Id = :orderId
        LIMIT 1
    ];

    // =========================================
    // LOAD COMPLETE QUOTATION DATA
    // =========================================

    if(ord.Quotes__c != null){

        loadQuotation(ord.Quotes__c);
    }

    // =========================================
    // CHANGE ONLY 2 FIELDS
    // =========================================

    this.quotationNumber =
        ord.Order_SO_Number__c;

    this.quotationDateFormatted =
        formatDate(ord.EffectiveDate__c);

    // =========================================
    // ENABLE ORDER TERMS & CONDITIONS
    // =========================================

    this.isOrderPDF = true;
}
  private static String sanitizeForPdf(String input) {

    if (String.isBlank(input)) return input;
 
    String result = input;
 
    Map<String, String> charMap = new Map<String, String>{

        'Ω' => '&Omega;', '°' => '&deg;', 'µ' => '&micro;', 'β' => '&beta;',

        'π' => '&pi;', '≤' => '&le;', '≥' => '&ge;',

        '½' => '&frac12;', '¼' => '&frac14;', '¾' => '&frac34;',

        '²' => '<sup>2</sup>', '³' => '<sup>3</sup>',

        '“' => '&ldquo;', '”' => '&rdquo;', '‘' => '&lsquo;', '’' => '&rsquo;'

    };
 
    for (String key : charMap.keySet()) {

        result = result.replace(key, charMap.get(key));

    }
 
    return result;

}
 
}