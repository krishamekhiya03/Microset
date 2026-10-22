import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_EMAIL from '@salesforce/schema/User.Email';
import USER_NAME from '@salesforce/schema/User.Name';
import saveQuotationPDF from '@salesforce/apex/QuotationController.saveQuotationPDF';
import sendQuotationEmail from '@salesforce/apex/QuotationController.sendQuotationEmail';
import getQuotations from '@salesforce/apex/QuotationController.getQuotations';
import getQuotationLineItems from '@salesforce/apex/QuotationController.getQuotationLineItems';
import saveFullQuotation from '@salesforce/apex/QuotationController.saveFullQuotation';
import updateQuotationLineItems from '@salesforce/apex/QuotationController.updateQuotationLineItems';
import generateVFPdf from '@salesforce/apex/QuotationController.generateVFPdf';
import getPdfDownloadUrl from '@salesforce/apex/QuotationController.getPdfDownloadUrl';
import { loadStyle } from 'lightning/platformResourceLoader';
import getEmailTemplateContent from '@salesforce/apex/QuotationController.getEmailTemplateContent';
import MY_STYLES from '@salesforce/resourceUrl/modelcss';
// ★ Group Apex imports
import getQuoteLineGroups from '@salesforce/apex/QuotationController.getQuoteLineGroups';
import saveQuoteLineGroup from '@salesforce/apex/QuotationController.saveQuoteLineGroup';
import deleteQuoteLineGroup from '@salesforce/apex/QuotationController.deleteQuoteLineGroup';
// ★ Terms & Conditions save import
import saveTermsAndConditions from '@salesforce/apex/QuotationController.saveTermsAndConditions';

import PAYMENT_TERM_FIELD from '@salesforce/schema/Quotation__c.Payment_Term__c';
import DELIVERY_TERM_FIELD from '@salesforce/schema/Quotation__c.Delivery_Term__c';
import PRICES_FIELD from '@salesforce/schema/Quotation__c.Prices1__c';
import TAXES_FIELD from '@salesforce/schema/Quotation__c.Taxes__c';
import GSTN_PAN_FIELD from '@salesforce/schema/Quotation__c.GSTN_PAN__c';
import MSME_FIELD from '@salesforce/schema/Quotation__c.MSME_ZED_Udyam_Reg_No__c';
import TRANSIT_FIELD from '@salesforce/schema/Quotation__c.Transit_Insurance__c';
import COMMISSIONING_FIELD from '@salesforce/schema/Quotation__c.Commissioning__c';
import INSPECTION_FIELD from '@salesforce/schema/Quotation__c.Inspection__c';
import VALIDITY_FIELD from '@salesforce/schema/Quotation__c.Validity__c';
import SCOPE_FIELD from '@salesforce/schema/Quotation__c.Scope__c';
import FORCE_FIELD from '@salesforce/schema/Quotation__c.Force_Majeure__c';
import JURISDICTION_FIELD from '@salesforce/schema/Quotation__c.Jurisdiction__c';
import WARRANTY_FIELD from '@salesforce/schema/Quotation__c.Warranty__c';
import PF_FIELD from '@salesforce/schema/Quotation__c.P_F__c';
import TAX_FIELD from '@salesforce/schema/Quotation__c.Tax__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import QUOTATION_OBJECT from '@salesforce/schema/Quotation__c';
import QUOTATION_CREATED_BY_FIELD
    from '@salesforce/schema/Quotation__c.Quotation_Created_By__c';
import deleteQuotationLineItem
    from '@salesforce/apex/QuotationController.deleteQuotationLineItem';
import SHIPPING_FIELD
    from '@salesforce/schema/Quotation__c.Shipping_and_Handling__c';
import CURRENCY_FIELD from '@salesforce/schema/Quotation__c.CurrencyIsoCode';
import GST_AMOUNT from '@salesforce/label/c.GST_Amount';
// import LightningConfirm from 'lightning/confirm';
// ─── helpers ───────────────────────────────────────────────────────────────
const fmt = (n) =>
    Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const fmtDate = (d) => {
    if (!d) return '';
    const [y, m, day] = d.split('-');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${String(day).padStart(2, '0')}-${months[parseInt(m, 10) - 1]}-${y}`;
};

let _seq = 0;
const newItem = (groupId = null) => {
    _seq++;
    return {
        id: `li_${Date.now()}_${_seq}`,
        sfId: null,           // ★ Salesforce record Id (null = new, not yet saved)
        itemNumber: _seq,
        productName: '',
        hsnCode: '',
        modelNumber: '',
        description: '',
        quantity: 1,
        unit: 'Nos',
        currency: '₹',
        unitPrice: 0,
        discount: 0,
        gst: 18,
        imageDataUrl: null,
        isHighlighted: false,
        sym: '₹',
        isINR: true, isUSD: false, isEUR: false, isGBP: false,
        hasDiscount: false,
        lineTotalFmt: '0.00',
        gstAmtFmt: '0.00',
        itemTotalFmt: '0.00',
        unitPriceFmt: '0.00',
        afterDiscFmt: '0.00',
        qtyDisplay: '01 No',
        wrapperClass: 'qt-li-card',
        previewRowClass: 'qt-item-row',
        summaryRowClass: 'sum-item-row',
        popupCardClass: 'pli-card',
        navDotClass: 'nav-dot',
        groupId: groupId,
        sortOrder: _seq,
        isDirty: true,         // ★ mark as unsaved so it will be sent to SF
        isSelectedForGroup: false
    };
};

// const recalc = (li) => {
//     // const base = (li.quantity || 0) * (li.unitPrice || 0);
//     // const discAmt = base * ((li.discount || 0) / 100);
//     // const afterDisc = base - discAmt;
//     // const gstAmt = afterDisc * ((li.gst || 0) / 100);
//     // const total = afterDisc + gstAmt;
//     const base = (li.quantity || 0) * (li.unitPrice || 0);

//     const discAmt =
//         base * ((li.discount || 0) / 100);

//     const totalAfterDiscount =
//         base - discAmt;

//     const gstAmt =
//         totalAfterDiscount * ((li.gst || 0) / 100);

//     const finalTotal =
//         totalAfterDiscount + gstAmt;
//     return {
//         ...li,
//         sym: li.currency || '₹',
//         isINR: li.currency === '₹',
//         isUSD: li.currency === '$',
//         hasDiscount: (li.discount || 0) > 0,
//         unitPriceFmt: fmt(li.unitPrice),
//         // lineTotalFmt: fmt(afterDisc),
//         // afterDiscFmt: fmt(afterDisc),
//         // gstAmtFmt: fmt(gstAmt),
//         // itemTotalFmt: fmt(total),
//         subtotalFmt: fmt(base),

//         discountAmtFmt: fmt(discAmt),

//         totalPriceFmt: fmt(totalAfterDiscount),

//         gstAmtFmt: fmt(gstAmt),

//         itemTotalFmt: fmt(finalTotal),
//         //itemTotalFmt: fmt(base),
//         qtyDisplay: `${String(Math.ceil(li.quantity || 1)).padStart(2, '0')} ${li.unit || 'No'}`,
//         wrapperClass: li.isHighlighted ? 'qt-li-card qt-li-hl' : 'qt-li-card',
//         previewRowClass: li.isHighlighted ? 'qt-item-row qt-item-hl' : 'qt-item-row',
//         summaryRowClass: li.isHighlighted ? 'sum-item-row sum-item-hl' : 'sum-item-row',
//         popupCardClass: li.isHighlighted ? 'pli-card pli-card-hl' : 'pli-card',
//         description: li.description || ''
//     };
// };
const recalc = (li) => {

    const base =
        (li.quantity || 0) * (li.unitPrice || 0);

    const discAmt =
        base * ((li.discount || 0) / 100);

    const totalAfterDiscount =
        base - discAmt;

    const gstAmt =
        totalAfterDiscount * ((li.gst || 0) / 100);

    const finalTotal =
        totalAfterDiscount + gstAmt;

    return {

        ...li,

        // ===== RAW NUMERIC VALUES =====
        subtotalPrice: base,

        discountAmount: discAmt,

        totalPrice: totalAfterDiscount,

        gstAmount: gstAmt,

        finalTotal: finalTotal,

        // ===== UI FORMATTED VALUES =====
        sym: li.currency || '₹',

        isINR: li.currency === '₹',

        isUSD: li.currency === '$',

        hasDiscount: (li.discount || 0) > 0,

        unitPriceFmt: fmt(li.unitPrice),

        subtotalFmt: fmt(base),

        discountAmtFmt: fmt(discAmt),

        totalPriceFmt: fmt(totalAfterDiscount),

        gstAmtFmt: fmt(gstAmt),

        itemTotalFmt: fmt(finalTotal),

        qtyDisplay:
            `${String(Math.ceil(li.quantity || 1))
                .padStart(2, '0')} ${li.unit || 'No'}`,

        wrapperClass:
            li.isHighlighted
                ? 'qt-li-card qt-li-hl'
                : 'qt-li-card',

        previewRowClass:
            li.isHighlighted
                ? 'qt-item-row qt-item-hl'
                : 'qt-item-row',

        summaryRowClass:
            li.isHighlighted
                ? 'sum-item-row sum-item-hl'
                : 'sum-item-row',

        popupCardClass:
            li.isHighlighted
                ? 'pli-card pli-card-hl'
                : 'pli-card',

        description: li.description || ''
    };
};

// ─── component ─────────────────────────────────────────────────────────────
export default class CustomQuotation extends LightningElement {

    @track termsData = {
        paymentTerms: '',
        deliveryTerms: '',
        prices: '',
        taxes: '',
        gstnPan: '',
        msme: '',
        transit: '',
        commissioning: '',
        inspection: '',
        validity: '',
        scope: '',
        warranty: '',
        forceMajeure: '',
        jurisdiction: ''
    };
    @track emailFrom = '';
    userId = USER_ID;
    @wire(getRecord, { recordId: '$userId', fields: [USER_EMAIL, USER_NAME] })
    currentUser({ data, error }) {
        if (data) {
            this.emailFrom = data.fields.Email.value || '';
        }
    }

    @track originalTermsData = null;
    @track hasTermsChanges = false;
    @track isSavingTerms = false;

    originalData = null;
    @track recordData = {};
    @track showDeleteModal = false;

    @track deleteMessage = '';
    @track quotationCurrency = 'INR';

    deleteCallback = null;

    openDeleteModal(message, callback) {

        this.deleteMessage = message;

        this.deleteCallback = callback;

        this.showDeleteModal = true;
    }
    async confirmDelete() {

        this.showDeleteModal = false;

        if (this.deleteCallback) {

            await this.deleteCallback();
        }
    }
    closeDeleteModal() {

        this.showDeleteModal = false;

        this.deleteCallback = null;
    }

    @api
    get recordId() { return this._recordId; }
    set recordId(val) {
        this._recordId = val;
        if (val) this.loadQuotation();
    }
    _recordId;

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref) {
            const id = ref?.attributes?.recordId || ref?.state?.recordId;
            if (id) this.recordId = id;
        }
    }
    handlePfChange(event) {
        this.pfPercent = parseFloat(event.target.value) || 0;
    }
    @wire(getRecord, {
        recordId: '$_recordId',
        fields: [
            PAYMENT_TERM_FIELD,
            DELIVERY_TERM_FIELD,
            PRICES_FIELD,
            TAXES_FIELD,
            GSTN_PAN_FIELD,
            MSME_FIELD,
            TRANSIT_FIELD,
            COMMISSIONING_FIELD,
            INSPECTION_FIELD,
            VALIDITY_FIELD,
            SCOPE_FIELD,
            WARRANTY_FIELD,
            FORCE_FIELD,
            JURISDICTION_FIELD,
            PF_FIELD,
            TAX_FIELD,
            SHIPPING_FIELD,
            CURRENCY_FIELD
        ]
    })
    wiredQuotation({ data, error }) {
        if (data) {
            this.termsData = {
                paymentTerms: data.fields.Payment_Term__c?.value || '',
                deliveryTerms: data.fields.Delivery_Term__c?.value || '',
                prices: data.fields.Prices1__c?.value || '',
                taxes: data.fields.Taxes__c?.value || '',
                gstnPan: data.fields.GSTN_PAN__c?.value || '',
                msme: data.fields.MSME_ZED_Udyam_Reg_No__c?.value || '',
                transit: data.fields.Transit_Insurance__c?.value || '',
                commissioning: data.fields.Commissioning__c?.value || '',
                inspection: data.fields.Inspection__c?.value || '',
                validity: data.fields.Validity__c?.value || '',
                scope: data.fields.Scope__c?.value || '',
                warranty: data.fields.Warranty__c?.value || '',
                forceMajeure: data.fields.Force_Majeure__c?.value || '',
                jurisdiction: data.fields.Jurisdiction__c?.value || '',
                pfPercent: data.fields.P_F__c?.value || 0,
                gstPercent: data.fields.Tax__c?.value || 0,
            };
            this.pfPercent =
                data.fields.P_F__c?.value || 0;

            this.gstPercent =
                data.fields.Tax__c?.value || 0;
            this.freightCharges =
                data.fields.Shipping_and_Handling__c?.value || 0;
            this.quotationCurrency = data.fields.CurrencyIsoCode?.value || 'INR';

            this.originalTermsData = JSON.stringify(this.termsData);
            this.hasTermsChanges = false;
        } else if (error) {
            console.error('Error:', error);
        }
    }
    @track quotationCreatedBy = '';
    @track gstPercent = 0;

    // @track quotationCreatedByOptions = [
    //     {
    //         label: 'Sandeep Patil | Manager | +91 9175433151',
    //         value: 'Sandeep Patil | Manager | +91 9175433151'
    //     }
    // ];
    @track quotationCreatedByOptions = [];
    @track paymentTermOptions = [];
    @track deliveryTermOptions = [];

    @wire(getObjectInfo, { objectApiName: QUOTATION_OBJECT })
    quotationObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$quotationObjectInfo.data.defaultRecordTypeId',
        fieldApiName: PAYMENT_TERM_FIELD
    })
    wiredPaymentTerms({ data, error }) {
        if (data) {
            this.paymentTermOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

            // ✅ Set first value as default
            if (!this.termsData.paymentTerms && data.values.length > 0) {
                this.termsData = {
                    ...this.termsData,
                    paymentTerms: data.values[0].value
                };
            }

        } else if (error) {
            console.error('Payment Term Picklist Error:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$quotationObjectInfo.data.defaultRecordTypeId',
        fieldApiName: DELIVERY_TERM_FIELD
    })

    wiredDeliveryTerms({ data, error }) {
        if (data) {
            this.deliveryTermOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

            // ✅ Set first value as default
            if (!this.termsData.deliveryTerms && data.values.length > 0) {
                this.termsData = {
                    ...this.termsData,
                    deliveryTerms: data.values[0].value
                };
            }

        } else if (error) {
            console.error('Delivery Term Picklist Error:', error);
        }
    }
    @wire(getPicklistValues, {
        recordTypeId: '$quotationObjectInfo.data.defaultRecordTypeId',
        fieldApiName: QUOTATION_CREATED_BY_FIELD
    })
    wiredQuotationCreatedBy({ data, error }) {

        if (data) {

            this.quotationCreatedByOptions =
                data.values.map(item => ({

                    label: item.label,
                    value: item.value

                }));

            // OPTIONAL DEFAULT VALUE
            if (!this.quotationCreatedBy &&
                data.values.length > 0) {

                this.quotationCreatedBy =
                    data.values[0].value;
            }

        } else if (error) {

            console.error(
                'Quotation Created By Picklist Error:',
                error
            );
        }
    }
    handleQuotationCreatedByChange(event) {
        this.quotationCreatedBy = event.target.value;
    }
    handleGSTChange(event) {
        this.gstPercent = parseFloat(event.target.value) || 0;
    }
    get showPaymentTermsCustom() {
        return this.termsData.paymentTerms === 'Others';
    }

    get showDeliveryTermsCustom() {
        return this.termsData.deliveryTerms === 'Others';
    }

    // ── mode ──────────────────────────────────────────────────────────────
    @track _mode = 'edit';
    get isEditMode() { return this._mode === 'edit'; }
    get isPreviewMode() { return this._mode === 'preview'; }
    get editPillClass() { return this._mode === 'edit' ? 'qt-pill qt-pill-active' : 'qt-pill'; }
    get previewPillClass() { return this._mode === 'preview' ? 'qt-pill qt-pill-active' : 'qt-pill'; }

    switchToEdit() { this._mode = 'edit'; }

    switchToPreview() {
        if (!this._recordId) {
            this._toast('Please save the quotation first before previewing.', 'error');
            return;
        }
        this._mode = 'preview';
        this.showVFPreview = false;
        setTimeout(() => { this._buildVFPageUrl(); }, 100);
    }

    // ── VF Page Preview ───────────────────────────────────────────────────
    @track showVFPreview = false;
    @track vfPageUrl = '';

    // _buildVFPageUrl() {
    //     if (!this._recordId) {
    //         this._toast('Quotation record ID not found. Please save first.', 'error');
    //         this.showVFPreview = false;
    //         return;
    //     }
    //     try {
    //         const origin = window.location.origin;
    //         const match = origin.match(/https:\/\/([a-zA-Z0-9\-]+)\.(?:sandbox\.)?lightning\.force\.com/);
    //         if (!match) throw new Error('Unable to detect Salesforce instance');
    //         const instance = match[1];
    //         const vfDomain = `${instance}--c.sandbox.vf.force.com`;
    //         this.vfPageUrl = `https://${vfDomain}/apex/Quotationpdf?quotationId=${this._recordId}`;
    //         this.showVFPreview = true;
    //     } catch (error) {
    //         this._toast(error.message, 'error');
    //         this.showVFPreview = false;
    //     }
    // }
    _buildVFPageUrl() {
    if (!this._recordId) {
        this._toast('Quotation record ID not found. Please save first.', 'error');
        this.showVFPreview = false;
        return;
    }
    try {
        const origin = window.location.origin;

        // ★ Detect if this is a sandbox based on the actual URL
        const isSandbox = origin.includes('.sandbox.lightning.force.com');

        // ★ Match instance name for BOTH sandbox and production
        const match = origin.match(
            /https:\/\/([a-zA-Z0-9-]+)\.(?:sandbox\.)?lightning\.force\.com/
        );

        if (!match) {
            throw new Error('Unable to detect Salesforce instance');
        }

        const instance = match[1];

        // ★ Build correct VF domain based on environment
        const vfDomain = isSandbox
            ? `${instance}--c.sandbox.vf.force.com`
            : `${instance}--c.vf.force.com`;

        this.vfPageUrl = `https://${vfDomain}/apex/Quotationpdf?quotationId=${this._recordId}`;
        this.showVFPreview = true;

    } catch (error) {
        this._toast(error.message, 'error');
        this.showVFPreview = false;
    }
}

    // ── company ───────────────────────────────────────────────────────────
    @track companyName = 'MicroSet Instrumentation & Controls';
    @track companyTagline = 'Instrumentation & Controls';
    @track companyAddress = '102 Chinmay 1103A, 10 Lakaki Road, Model Colony, Shivajinagar, Pune 411016';
    @track companyPhone = '+91 9112455550';
    @track companyEmail = 'krisha.m@nsiqinfotech.online';
    @track companyWebsite = 'www.MicroSetindia.com';
    @track companyGSTIN = '';
    @track logoDataUrl = null;
    @track watermarkText = 'QUOTATION';

    // ── quotation meta ────────────────────────────────────────────────────
    @track quotationNumber = 'MIC/' + new Date().getFullYear() + '-' + String(new Date().getFullYear() + 1).slice(-2) + '/Q/00001';
    @track quotationDate = new Date().toISOString().split('T')[0];
    @track validUntil = '';
    @track reference = '';
    @track subject = '';
    @track quotationName = '';

    // ── customer ──────────────────────────────────────────────────────────
    @track customerName = '';
    @track contactPerson = '';
    @track mobileNumber = '';
    @track customerEmail = '';
    @track customerAddress = '';
    @track customerGSTIN = '';
    @track placeOfSupply = '';

    // ── line items ────────────────────────────────────────────────────────
    @track lineItems = [];

    // ★ Groups ─────────────────────────────────────────────────────────────
    @track groups = [];
    @track showGroupModal = false;
    @track groupModalName = '';
    @track groupModalNameCustom = '';
    @track editingGroupId = null;
    @track showGroupCheckbox = false;//new added

    groupHeaderOptions = [
        { label: ' pH System Consists of A + B', value: 'pH System Consists of A + B' },
        { label: ' pH System Consists of A + B + C', value: 'pH System Consists of A + B + C' },
        { label: ' ORP System Consists of A + B', value: 'ORP System Consists of A + B' },
        { label: ' ORP System Consists of A + B + C', value: 'ORP System Consists of A + B + C' },
        { label: ' Conductivity System Consists of A + B', value: 'Conductivity System Consists of A + B' },
        { label: ' Conductivity System Consists of A + B + C', value: 'Conductivity System Consists of A + B + C' },
        { label: ' TDS System Consists of A + B', value: 'TDS System Consists of A + B' },
        { label: ' TDS System Consists of A + B + C', value: 'TDS System Consists of A + B + C' },
        { label: ' Dissolved Oxygen System Consists of A + B', value: 'Dissolved Oxygen System Consists of A + B' },
        { label: ' Dissolved Oxygen System Consists of A + B + C', value: 'Dissolved Oxygen System Consists of A + B + C' },
        { label: ' COD BOD TSS System Consists of A + B + C', value: 'COD BOD TSS System Consists of A + B + C' },
        { label: ' COD BOD TSS System Consists of A + B + C + D', value: 'COD BOD TSS System Consists of A + B + C + D' },
        { label: ' COD BOD TSS TOC System Consists of A + B', value: 'COD BOD TSS TOC System Consists of A + B' },
        { label: ' COD BOD TSS TOC System Consists of A + B + C + D', value: 'COD BOD TSS TOC System Consists of A + B + C + D' },
        { label: ' Other', value: 'Other' }
    ];

    // ★ NEW: adds `selected` flag per option for the plain <select>
    get groupHeaderOptionsForUI() {
        return this.groupHeaderOptions.map(opt => ({
            ...opt,
            selected: opt.value === this.groupModalName
        }));
    }

    // ★ NEW: show custom textbox only when "Other" is chosen
    get showGroupNameCustom() {
        return this.groupModalName === 'Other';
    }
    // ── charges / terms ───────────────────────────────────────────────────
    @track pfPercent = 3;
    @track freightCharges = 0;
    @track paymentTerms = '100% along with PO';
    @track delivery = '3 to 4 weeks from payment';
    @track warranty = '12 months from date of sale';
    @track pricesBasis = 'FOB Pune (India)';
    @track termsConditions = '';
    @track additionalNotes = '';

    // ── email modal ───────────────────────────────────────────────────────
    @track showEmailModal = false;
    @track emailTo = '';
    @track emailCC = '';
    @track emailBCC = '';
    @track emailSubject = '';
    @track emailBody = '';

    // ── ui state ──────────────────────────────────────────────────────────
    @track isSaving = false;
    @track isSending = false;
    @track showToast = false;
    @track toastMsg = '';
    @track toastCls = 'qt-toast qt-toast-ok';
    @track toastIco = '✅';

    // ── popup state ───────────────────────────────────────────────────────
    @track showItemsPopup = false;
    @track isEditingItem = false;
    @track currentEditItem = null;
    @track currentEditIndex = -1;
    @track activeGroupId = null;
    @track pendingGroupSelection = [];//new added

    // ── download modal ────────────────────────────────────────────────────
    @track showDownloadOptions = false;
    @track isGeneratingPdf = false;

    @track hsnCode = '';
    get freightDisplay() {
        return (this.freightCharges && this.freightCharges > 0)
            ? `${this.primaryCurrency} ${Number(this.freightCharges).toFixed(2)}`
            : 'EXTRA AT ACTUAL';
    }
    handleHSNChange(event) {
        this.hsnCode = event.target.value;
    }
    handleFreightChange(event) {
        this.freightCharges = parseFloat(event.target.value) || 0;
    }

    // handleDownloadClick() { this.showDownloadOptions = true; }
    // closeDownloadModal() { this.showDownloadOptions = false; }

    get isLastItem() { return this.currentEditIndex === this.lineItems.length - 1; }

    get groupsWithItems() {
        return this.groups.map(g => ({
            ...g,
            items: this.lineItems.filter(li => li.groupId === g.id)
        }));
    }

    get ungroupedLineItems() {
        return this.lineItems.filter(li => !li.groupId);
    }

    get hasGroups() { return this.groups.length > 0; }

    get groupOptions() {
        const opts = [{ label: '— No Group (standalone) —', value: '' }];
        this.groups.forEach(g => opts.push({ label: g.headerName, value: g.id }));
        return opts;
    }

    // ─────────────────────────────────────────────────────────────────────
    // ★ CORE FIX: Build the Salesforce-ready payload for a line item
    // Maps all LWC fields → Quotation_Line_Item__c Salesforce fields
    // ─────────────────────────────────────────────────────────────────────
    // _buildLineItemSFRecord(li, index) {
    //     const record = {
    //         // Only set Id if it's a real Salesforce Id (starts with standard SF Id format)
    //         // New items (sfId = null) will be inserted; existing ones will be updated
    //         Quantity__c: li.quantity || 0,
    //         List_Price__c: li.unitPrice || 0,
    //         Line_Description__c: li.description
    //             ? li.description.replace(/<[^>]*>/g, '')
    //             : '',
    //         Discount__c: li.discount,
    //         // Subtotal_Price__c: base,
    //         // Total_Price__c: totalAfterDiscount,
    //         GST__c: li.gst || 0,
    //         Unit__c: li.unit || 'Nos',
    //         Currency__c: li.currency || '₹',
    //         Is_Highlighted__c: li.isHighlighted || false,
    //         Quote_Line_Group__c: li.groupId || null,
    //         Sort_Order__c: index + 1,
    //         Subtotal_Price__c: li.subtotalPrice || 0,

    //         Total_Price__c: li.totalPrice || 0,

    //         GST_Amount__c: li.gstAmount || 0,

    //         Final_Total__c: li.finalTotal || 0,
    //     };

    // If the item has a real Salesforce Id, include it for update
    // if(li.sfId) {
    //     record.Id = li.sfId;
    // }

    //     return record;
    // }

    // _buildLineItemSFRecord(li, index) {

    //     const record = {

    //         Quantity__c: li.quantity || 0,

    //         List_Price__c: li.unitPrice || 0,

    //         // Line_Description__c: li.description
    //         //     ? li.description.replace(/<[^>]*>/g, '')
    //         //     : '',
    //         Line_Description__c: li.description
    //             ? li.description
    //                 .replace(/<br\s*\/?>/gi, '\n')   // <br/> → \n for DB storage
    //                 .replace(/<[^>]*>/g, '')          // strip other HTML tags
    //                 .trim()
    //             : '',
    //         Discount__c: li.discount || 0,

    //         GST__c: li.gst || 0,

    //         Unit__c: li.unit || 'Nos',

    //         Currency__c: li.currency || '₹',

    //         // ===== CALCULATED VALUES =====
    //         Subtotal_Price__c: li.subtotalPrice || 0,

    //         Total_Price__c: li.totalPrice || 0,

    //         // GST_Amount__c: li.gstAmount || 0,
    //         Total_GST__c: li.gstAmount || 0,

    //         Final_Total__c: li.finalTotal || 0,

    //         Is_Highlighted__c: li.isHighlighted || false,

    //         Quote_Line_Group__c: li.groupId || null,

    //         Sort_Order__c: index + 1
    //     };

    //     if (li.sfId) {
    //         record.Id = li.sfId;
    //     }

    //     return record;
    // }
    // _buildLineItemSFRecord(li, index) {
    //     const record = {
    //         Quantity__c: li.quantity || 0,
    //         List_Price__c: li.unitPrice || 0,

    //         Line_Description__c: li.description
    //             ? li.description
    //                 .replace(/<br\s*\/?>/gi, '\n')
    //                 .replace(/<[^>]*>/g, '')
    //                 .trim()
    //             : '',

    //         Discount__c: li.discount || 0,
    //         GST__c: li.gst || 0,
    //         Unit__c: li.unit || 'Nos',
    //         Currency__c: li.currency || '₹',
    //         Is_Highlighted__c: li.isHighlighted || false,
    //         Quote_Line_Group__c: li.groupId || null,
    //         Sort_Order__c: index + 1,

    //         // ★ ADD THESE
    //         Subtotal_Price__c: li.subtotalPrice || 0,
    //         Total_Price__c: li.totalPrice || 0,
    //         Total_GST__c: li.gstAmount || 0,
    //         Final_Total__c: li.finalTotal || 0,
    //     };

    //     if (li.sfId) {
    //         record.Id = li.sfId;
    //     }

    //     return record;
    // }
    _buildLineItemSFRecord(li, index) {
        const record = {
            Quantity__c: li.quantity || 0,
            List_Price__c: li.unitPrice || 0,
            Model_Number__c: li.modelNumber || '',
            // ★ CRITICAL FIX: Preserve formatting in description
            Line_Description__c: li.description
                ? li.description
                    .replace(/<br\s*\/?>/gi, '\n')  // Convert <br/> to \n
                    .trim()
                : '',

            Discount__c: li.discount || 0,
            GST__c: li.gst || 0,
            Unit__c: li.unit || 'Nos',
            Currency__c: li.currency || '₹',
            Is_Highlighted__c: li.isHighlighted || false,
            Quote_Line_Group__c: li.groupId || null,
            Sort_Order__c: index + 1,

            // ★ Important: Include calculated fields
            Subtotal_Price__c: li.subtotalPrice || 0,
            Total_Price__c: li.totalPrice || 0,
            Total_GST__c: li.gstAmount || 0,
            Final_Total__c: li.finalTotal || 0,
        };

        if (li.sfId) {
            record.Id = li.sfId;
        }

        return record;
    }


    // ─────────────────────────────────────────────────────────────────────
    // ★ CORE FIX: Save ALL line items to Salesforce
    // Calls the Apex method that handles both insert (new) and update (existing)
    // ─────────────────────────────────────────────────────────────────────
    // async _saveLineItemsToSF() {
    //     if (!this._recordId) {
    //         throw new Error('Quotation record Id is required to save line items');
    //     }
    //     if (this.lineItems.length === 0) return;

    //     const records = this.lineItems.map((li, idx) =>
    //         this._buildLineItemSFRecord(li, idx)
    //     );

    //     // Call Apex — pass quotationId so Apex can handle inserts too
    //     const savedIds = await updateQuotationLineItems({
    //         quotationId: this._recordId,
    //         items: records
    //     });

    //     // ★ If Apex returns the saved Ids, update sfId on local items
    //     // so subsequent saves correctly update instead of insert
    //     if (savedIds && savedIds.length === this.lineItems.length) {
    //         this.lineItems = this.lineItems.map((li, idx) => ({
    //             ...li,
    //             sfId: savedIds[idx],
    //             isDirty: false
    //         }));
    //     }
    // }
    async _saveLineItemsToSF() {
        if (!this._recordId) {
            throw new Error('Quotation record Id is required to save line items');
        }
        if (this.lineItems.length === 0) return;

        try {
            const records = this.lineItems.map((li, idx) =>
                this._buildLineItemSFRecord(li, idx)
            );

            console.log('📤 Saving', records.length, 'items to Salesforce...');

            // ★ Pass quotationId separately for new item inserts
            await updateQuotationLineItems({
                quotationId: this._recordId,
                items: records
            });

            console.log('✅ Items saved to Salesforce');

            // ★ Reload fresh from SF to get correct sfIds
            await this._fetchLineItemsFromSF();

            console.log('✅ Reloaded items from Salesforce');

        } catch (error) {
            console.error('❌ Error saving items:', error);
            throw error;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Terms & Conditions
    // ─────────────────────────────────────────────────────────────────────
    // handleTermsChange(event) {
    //     const field = event.target.dataset.field;
    //     const value = event.target.value;
    //     this.termsData = { ...this.termsData, [field]: value };
    //     this._checkTermsChanges();
    // } 
    handleTermsChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;

        this.termsData = {
            ...this.termsData,
            [field]: value
        };

        // Clear custom values if not Others
        if (field === 'paymentTerms' && value !== 'Others') {
            this.termsData.paymentTermsCustom = '';
        }

        if (field === 'deliveryTerms' && value !== 'Others') {
            this.termsData.deliveryTermsCustom = '';
        }

        this._checkTermsChanges();
    }

    _checkTermsChanges() {
        if (!this.originalTermsData) { this.hasTermsChanges = false; return; }
        this.hasTermsChanges = JSON.stringify(this.termsData) !== this.originalTermsData;
    }

    async handleSaveTerms() {
        if (!this._recordId) { this._toast('Quotation record not found', 'error'); return; }
        this.isSavingTerms = true;
        try {
            await saveTermsAndConditions({ quotationId: this._recordId, termsMap: this.termsData });
            this.originalTermsData = JSON.stringify(this.termsData);
            this.hasTermsChanges = false;

            this._toast(' Terms & Conditions saved!', 'success');
        } catch (error) {
            this._toast('Error saving Terms: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSavingTerms = false;
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Group Modal handlers
    // ─────────────────────────────────────────────────────────────────────
    // openAddGroupModal() {
    //     this.groupModalName = '';
    //     this.groupModalNameCustom = '';
    //     this.editingGroupId = null;
    //     this.showGroupModal = true;
    // }

    // openEditGroupModal(e) {
    //     const id = e.currentTarget.dataset.groupId;
    //     const grp = this.groups.find(g => g.id === id);
    //     if (grp) {
    //         this.groupModalName = grp.headerName;
    //         this.editingGroupId = id;
    //         this.showGroupModal = true;
    //     }
    // }

    // closeGroupModal() {
    //     this.showGroupModal = false;
    //     this.groupModalName = '';
    //     this.editingGroupId = null;
    // }
    openAddGroupModal() {
        this.groupModalName = '';
        this.groupModalNameCustom = '';   // ★ NEW
        this.editingGroupId = null;
        this.showGroupModal = true;
    }

    openEditGroupModal(e) {
        const id = e.currentTarget.dataset.groupId;
        const grp = this.groups.find(g => g.id === id);
        if (grp) {
            // ★ NEW: if the saved header matches one of our predefined options, select it;
            // otherwise treat it as a custom "Other" value
            const isPredefined = this.groupHeaderOptions.some(
                opt => opt.value === grp.headerName && opt.value !== 'Other'
            );
            if (isPredefined) {
                this.groupModalName = grp.headerName;
                this.groupModalNameCustom = '';
            } else {
                this.groupModalName = 'Other';
                this.groupModalNameCustom = grp.headerName;
            }
            this.editingGroupId = id;
            this.showGroupModal = true;
        }
    }

    closeGroupModal() {
        this.showGroupModal = false;
        this.groupModalName = '';
        this.groupModalNameCustom = '';   // ★ NEW
        this.editingGroupId = null;
    }

    // handleGroupNameChange(e) { this.groupModalName = e.target.value; }
    // ★ UPDATED: handles dropdown selection
    handleGroupNameChange(e) {
        const val = e.target.value;
        this.groupModalName = val;

        // Reset custom value if user switches away from "Other"
        if (val !== 'Other') {
            this.groupModalNameCustom = '';
        }
    }

    // ★ NEW: handles typing in the custom "Other" textbox
    handleGroupNameCustomChange(e) {
        this.groupModalNameCustom = e.target.value;
    }
    // async saveGroupModal() {
    //     const name = (this.groupModalName || '').trim();
    //     if (!name) { this._toast('Group name is required', 'error'); return; }
    //     try {
    //         const sortOrder = this.editingGroupId
    //             ? this.groups.find(g => g.id === this.editingGroupId)?.sortOrder
    //             : this.groups.length + 1;

    //         const newId = await saveQuoteLineGroup({
    //             quotationId: this._recordId,
    //             groupId: this.editingGroupId || null,
    //             headerName: name,
    //             sortOrder: sortOrder || 1
    //         });

    //         if (this.editingGroupId) {
    //             this.groups = this.groups.map(g =>
    //                 g.id === this.editingGroupId ? { ...g, headerName: name } : g
    //             );
    //         } else {
    //             this.groups = [...this.groups, { id: newId, headerName: name, sortOrder: sortOrder || 1 }];
    //         }
    //         const isEdit = !!this.editingGroupId;

    //         this.closeGroupModal();

    //         if (isEdit) {

    //             this._toast(
    //                 'Group updated successfully!',
    //                 'success'
    //             );

    //         } else {

    //             this._toast(
    //                 'Group created successfully!',
    //                 'success'
    //             );
    //         }
    //     } catch (err) {
    //         this._toast('Error saving group: ' + (err.body?.message || err.message), 'error');
    //     }
    // }
    async saveGroupModal() {
        // ★ NEW: pick custom value if "Other" selected, else the dropdown value
        const name = this.groupModalName === 'Other'
            ? (this.groupModalNameCustom || '').trim()
            : (this.groupModalName || '').trim();

        if (!name) { this._toast('Group name is required', 'error'); return; }

        try {
            const sortOrder = this.editingGroupId
                ? this.groups.find(g => g.id === this.editingGroupId)?.sortOrder
                : this.groups.length + 1;

            const newId = await saveQuoteLineGroup({
                quotationId: this._recordId,
                groupId: this.editingGroupId || null,
                headerName: name,
                sortOrder: sortOrder || 1
            });

            if (this.editingGroupId) {
                this.groups = this.groups.map(g =>
                    g.id === this.editingGroupId ? { ...g, headerName: name } : g
                );
            } else {
                this.groups = [...this.groups, { id: newId, headerName: name, sortOrder: sortOrder || 1 }];
            }
            const isEdit = !!this.editingGroupId;

            this.closeGroupModal();

            if (isEdit) {
                this._toast('Group updated successfully!', 'success');
            } else {
                this._toast('Group created successfully!', 'success');
            }
        } catch (err) {
            this._toast('Error saving group: ' + (err.body?.message || err.message), 'error');
        }
    }
    // async handleDeleteGroup(e) {
    //     const id = e.currentTarget.dataset.groupId;
    //     if (!id) return;
    //     try {
    //         await deleteQuoteLineGroup({ groupId: id });
    //         this.lineItems = this.lineItems.map(li => li.groupId === id ? { ...li, groupId: null } : li);
    //         this.groups = this.groups.filter(g => g.id !== id);
    //         this._toast('Group deleted. Items moved to ungrouped.', 'info');
    //     } catch (err) {
    //         this._toast('Error deleting group: ' + (err.body?.message || err.message), 'error');
    //     }
    // }
    // async handleDeleteGroup(e) {

    //     // const result = await LightningConfirm.open({
    //     //     message: 'Are you sure you want to delete this group?',
    //     //     variant: 'header',
    //     //     label: 'Delete Confirmation'
    //     // });
    //     const result = await LightningConfirm.open

    //     if (!result) {
    //         return;
    //     }

    //     const id = e.currentTarget.dataset.groupId;

    //     if (!id) return;

    //     try {

    //         await deleteQuoteLineGroup({ groupId: id });

    //         this.lineItems = this.lineItems.map(li =>
    //             li.groupId === id
    //                 ? { ...li, groupId: null }
    //                 : li
    //         );

    //         this.groups =
    //             this.groups.filter(g => g.id !== id);

    //         this._toast(
    //             'Group deleted successfully.',
    //             'success'
    //         );

    //     } catch (err) {

    //         this._toast(
    //             'Error deleting group: ' +
    //             (err.body?.message || err.message),
    //             'error'
    //         );
    //     }
    // }
    async handleDeleteGroup(e) {

        const id = e.currentTarget.dataset.groupId;

        if (!id) return;

        this.openDeleteModal(

            'Are you sure you want to delete this group?',

            async () => {

                try {

                    await deleteQuoteLineGroup({
                        groupId: id
                    });

                    this.lineItems = this.lineItems.map(li =>
                        li.groupId === id
                            ? { ...li, groupId: null }
                            : li
                    );

                    this.groups =
                        this.groups.filter(g => g.id !== id);

                    this._toast(
                        'Group deleted successfully.',
                        'success'
                    );

                } catch (err) {

                    this._toast(
                        'Error deleting group: ' +
                        (err.body?.message || err.message),
                        'error'
                    );
                }
            }
        );
    }

    openItemsPopupForGroup(e) {
        this.showGroupCheckbox = true;

        const groupId = e.currentTarget.dataset.groupId;
        console.log('Opening items popup for groupId:::', groupId);

        // current active group
        this.activeGroupId = groupId || null;

        // Auto-check items already inside this group
        this.lineItems = this.lineItems.map(li => {

            return {
                ...li,

                isSelectedForGroup:
                    li.groupId === this.activeGroupId
            };
        });
        this.activeGroupId = groupId || null;
        this.isEditingItem = false;
        this.currentEditItem = null;
        this.showItemsPopup = true;
    }

    handleItemGroupChange(e) {
        const val = e.target.value;
        this.currentEditItem = { ...this.currentEditItem, groupId: val || null };
    }

    // handleItemGroupChange(e) {
    //     const val = e.target.value;

    //     // ✅ 1. Save globally (VERY IMPORTANT)
    //     this.activeGroupId = val || null;

    //     // ✅ 2. Update current item also
    //     this.currentEditItem = {
    //         ...this.currentEditItem,
    //         groupId: val || null
    //     };
    // }

    // ─────────────────────────────────────────────────────────────────────
    // Download helpers
    // ─────────────────────────────────────────────────────────────────────
    // downloadInSystem() {
    //     this.showDownloadOptions = false;
    //     this._toast('Downloading PDF to system...', 'info');
    //     this.downloadInSalesforce();
    // } downloadInSalesforc
    // async downloadInSalesforce() {
    //     this.showDownloadOptions = false;

    //     if (!this._recordId) {
    //         this._toast('No Quotation record found. Please save first.', 'error');
    //         return;
    //     }

    //     this.isGeneratingPdf = true;
    //     this._toast('⏳ Generating PDF...', 'info');

    //     try {
    //         const contentDocId = await generateVFPdf({ quotationId: this._recordId });
    //         const downloadUrl = await getPdfDownloadUrl({ contentDocumentId: contentDocId });

    //         // ✅ DOWNLOAD WITHOUT REDIRECT
    //         const link = document.createElement('a');
    //         link.href = downloadUrl;
    //         link.download = 'Quotation.pdf';
    //         document.body.appendChild(link);
    //         link.click();
    //         document.body.removeChild(link);

    //         this._toast(' PDF downloaded successfully!', 'success');

    //     } catch (error) {
    //         this._toast('Error generating PDF: ' + (error.body?.message || error.message), 'error');
    //     } finally {
    //         this.isGeneratingPdf = false;
    //     }
    // }
    async downloadInSalesforce() {

        if (!this._recordId) {

            this._toast(
                'No Quotation record found.',
                'error'
            );

            return;
        }

        this.isGeneratingPdf = true;

        this._toast(
            'Generating PDF...',
            'info'
        );

        try {

            await generateVFPdf({
                quotationId: this._recordId
            });

            this._toast(
                'PDF saved successfully in Salesforce Files!',
                'success'
            );

            // REFRESH PAGE
            window.location.reload();

        } catch (error) {

            this._toast(
                'Error generating PDF: ' +
                (error.body?.message || error.message),
                'error'
            );

        } finally {

            this.isGeneratingPdf = false;
        }
    }
    // ─────────────────────────────────────────────────────────────────────
    // Popup handlers
    // ─────────────────────────────────────────────────────────────────────
    // openItemsPopup() {
    //     this.activeGroupId = null;
    //     this.isEditingItem = false;
    //     this.currentEditItem = null;
    //     this.showItemsPopup = true;
    // }
    openItemsPopup() {
        this.activeGroupId = null;
        this.isEditingItem = false;
        this.currentEditItem = null;
        this.showGroupCheckbox = false;  // ★ yeh add karo
        this.pendingGroupSelection = []; // ★ yeh add karo
        // checkboxes reset karo
        this.lineItems = this.lineItems.map(li => ({
            ...li,
            isSelectedForGroup: false
        }));
        this.showItemsPopup = true;
    }

    /**async closeItemsPopup() {
        this.lineItems = this.lineItems.map(li => {
            if (li.isSelectedForGroup) {
                return {
                    ...li,
                    // assign selected/current group
                    groupId: this.activeGroupId,
                    // optional reset
                    isSelectedForGroup: false,
                    isDirty: true // mark as dirty so it will be saved to SF on next save
                };
            }
            return {
                ...li,
                isSelectedForGroup: false
            };
        });
        try {

            // SAVE TO DATABASE
            await this._saveLineItemsToSF();

            this._toast(
                'Items added to group successfully!',
                'success'
            );

        } catch (error) {

            this._toast(
                'Error saving items: ' +
                (error.body?.message || error.message),
                'error'
            );

            return;
        }
        this.showItemsPopup = false;
        this.isEditingItem = false;
        this.currentEditItem = null;
        // this.activeGroupId = null;
    }**/
    // async closeItemsPopup() {

    //     this.lineItems = this.lineItems.map(li => {

    //         const isPending =

    //             this.pendingGroupSelection
    //                 .includes(li.id);

    //         // ADD TO GROUP
    //         if (isPending) {

    //             return {

    //                 ...li,

    //                 groupId:
    //                     this.activeGroupId,

    //                 isSelectedForGroup:
    //                     false,

    //                 isDirty: true
    //             };
    //         }

    //         // REMOVE FROM GROUP
    //         if (

    //             li.groupId ===
    //             this.activeGroupId &&

    //             !li.isSelectedForGroup

    //         ) {

    //             return {

    //                 ...li,

    //                 groupId: null,

    //                 isSelectedForGroup:
    //                     false,

    //                 isDirty: true
    //             };
    //         }

    //         return {

    //             ...li,

    //             isSelectedForGroup:
    //                 false
    //         };

    //     });

    //     try {

    //         await this._saveLineItemsToSF();

    //         this.pendingGroupSelection = [];

    //         this._toast(

    //             'Items updated successfully!',

    //             'success'
    //         );

    //     } catch (error) {

    //         this._toast(

    //             'Error saving items: ' +

    //             (
    //                 error.body?.message ||

    //                 error.message
    //             ),

    //             'error'
    //         );

    //         return;
    //     }

    //     this.showItemsPopup = false;

    //     this.isEditingItem = false;

    //     this.currentEditItem = null;
    // }
    async closeItemsPopup() {

        this.lineItems = this.lineItems.map(li => {

            const isPending = this.pendingGroupSelection.includes(li.id);

            if (isPending) {
                return { ...li, groupId: this.activeGroupId, isSelectedForGroup: false, isDirty: true };
            }

            if (li.groupId === this.activeGroupId && !li.isSelectedForGroup) {
                return { ...li, groupId: null, isSelectedForGroup: false, isDirty: true };
            }

            return { ...li, isSelectedForGroup: false };
        });

        try {
            await this._saveLineItemsToSF();

            // ★ MAIN FIX: Cache bypass karke fresh data fetch karo
            await this._fetchGroupsFromSF();
            await this._fetchLineItemsFromSF();

            this.pendingGroupSelection = [];
            this._toast('Items updated successfully!', 'success');

        } catch (error) {
            this._toast('Error saving items: ' + (error.body?.message || error.message), 'error');
            return;
        }

        this.showItemsPopup = false;
        this.isEditingItem = false;
        this.currentEditItem = null;
    }
    async _fetchGroupsFromSF() {
        try {
            // ★ getRefreshTimestamp() jaisa trick — fresh call force karo
            const result = await getQuoteLineGroups({ quotationId: this._recordId });
            this.groups = (result || []).map(g => ({
                id: g.Id,
                headerName: g.Header__c,
                sortOrder: g.Sort_Order__c
            }));
            console.log('✅ Groups reloaded:', this.groups.length);
        } catch (error) {
            console.error('Error loading groups:', error);
            this.groups = [];
        }
    }
    async closeItemsPopuback() {

        this.lineItems = this.lineItems.map(li => {

            const isPending =

                this.pendingGroupSelection
                    .includes(li.id);

            // ADD TO GROUP
            if (isPending) {

                return {

                    ...li,

                    groupId:
                        this.activeGroupId,

                    isSelectedForGroup:
                        false,

                    isDirty: true
                };
            }

            // REMOVE FROM GROUP
            if (

                li.groupId ===
                this.activeGroupId &&

                !li.isSelectedForGroup

            ) {

                return {

                    ...li,

                    groupId: null,

                    isSelectedForGroup:
                        false,

                    isDirty: true
                };
            }

            return {

                ...li,

                isSelectedForGroup:
                    false
            };

        });

        try {

            await this._saveLineItemsToSF();

            this.pendingGroupSelection = [];

            // this._toast(

            //     'Items updated successfully!',

            //     'success'
            // );

        } catch (error) {

            this._toast(

                'Error saving items: ' +

                (
                    error.body?.message ||

                    error.message
                ),

                'error'
            );

            return;
        }

        this.showItemsPopup = false;

        this.isEditingItem = false;

        this.currentEditItem = null;
    }

    goBackWithoutSave() {
        this.showGroupCheckbox = false;
        // clear temp selections

        this.pendingGroupSelection = [];

        this.lineItems = this.lineItems.map(li => ({

            ...li,

            isSelectedForGroup: false

        }));

        this.showItemsPopup = false;

        this.isEditingItem = false;

        this.currentEditItem = null;

    }

    handlePopupClose() {

        // if edit mode open
        if (this.isEditingItem) {

            this.isEditingItem = false;

            this.currentEditItem = null;

            // keep product list as is
            return;
        }

        // normal popup close
        this.showItemsPopup = false;

        this.currentEditItem = null;

        this.isEditingItem = false;

    }
    // async addItemFromPopup() {
    //     if (this.lineItems.length === 0 && this._recordId) {
    //         await this._fetchLineItemsFromSF();
    //     }
    //     const item = recalc(newItem(this.activeGroupId));
    //     this.lineItems = [...this.lineItems, item];
    //     this._openEditorForIndex(this.lineItems.length - 1);
    // }
    setActiveGroup(groupId) {
        this.groups = this.groups.map(g => ({
            ...g,
            isActive: g.id === groupId
        }));
    }

    /**openEditForItem(e) {
        const id = e.currentTarget.dataset.id;
        const idx = this.lineItems.findIndex(li => li.id === id);
        const groupIdForItem = this.lineItems[idx]?.groupId;
        if (idx !== -1) {
           // this.showGroupCheckbox = false;

            this.showItemsPopup = true;
            this._openEditorForIndex(idx);
        }
        this.setActiveGroup(groupIdForItem);
    }**/
    openEditForItem(e) {

        const id =
            e.currentTarget.dataset.id;

        const idx =
            this.lineItems.findIndex(
                li => li.id === id
            );

        if (idx !== -1) {
            this.showGroupCheckbox = false;
            const item =
                this.lineItems[idx];

            // IMPORTANT FIX
            this.activeGroupId =
                item.groupId || null;

            this.lineItems =
                this.lineItems.map(li => ({

                    ...li,

                    isSelectedForGroup:

                        li.groupId ===
                        this.activeGroupId

                }));

            this.showGroupCheckbox =
                false;

            this.showItemsPopup =
                true;

            this._openEditorForIndex(
                idx
            );
        }
    }

    _openEditorForIndex(idx) {
        this.currentEditIndex = idx;
        this.currentEditItem = { ...this.lineItems[idx] };
        this.isEditingItem = true;
        this._refreshNavDots();
    }

    _refreshNavDots() {
        this.lineItems = this.lineItems.map((li, idx) => ({
            ...li,
            navDotClass: idx === this.currentEditIndex ? 'nav-dot nav-dot-active' : 'nav-dot'
        }));
    }

    _storeOriginalData() {
        this.originalData = JSON.stringify(this._buildPayload());
    }

    // currentItemChange(e) {
    //     console.log('Field change:', e.currentTarget.dataset.fld, 'New value:', e.target.value);
    //     console.log('Current edit item before change:', JSON.stringify(this.currentEditItem));
    //     const fld = e.currentTarget.dataset.fld;
    //     let val = e.target.value;
    //     const updated = { ...this.currentEditItem };
    //     console.log('updated before:', updated);
    //     if (['quantity', 'unitPrice', 'discount', 'gst'].includes(fld)) {
    //         updated[fld] = parseFloat(val) || 0;
    //         console.log('if updated:', updated);
    //     } else {
    //         updated[fld] = val;
    //         console.log('else updated:', updated);
    //     }
    //     // Mark item as dirty (has unsaved changes)
    //     updated.isDirty = true;
    //     this.currentEditItem = recalc(updated);
    // }
    currentItemChange(e) {
        const fld = e.currentTarget.dataset.fld;
        let val = e.target.value;
        const updated = { ...this.currentEditItem };

        // ★ IMPORTANT: Handle different field types
        if (['quantity', 'unitPrice', 'discount', 'gst'].includes(fld)) {
            updated[fld] = parseFloat(val) || 0;
        } else if (fld === 'description') {
            // ★ CRITICAL: Rich text editor returns HTML with <br/> and styling
            // DO NOT strip or modify it — keep exactly as-is
            updated[fld] = val || '';
        } else {
            updated[fld] = val;
        }

        // Mark item as dirty
        updated.isDirty = true;
        this.currentEditItem = recalc(updated);
    }

    get currentEditItemForSave() {
        const item = { ...this.currentEditItem };

        // ★ IMPORTANT: Salesforce fields have character limits
        // Trim if necessary (example: Line_Description__c typically 3000 chars)
        if (item.description && item.description.length > 3000) {
            console.warn('⚠️ Description exceeds 3000 chars, will be truncated for DB');
            item.description = item.description.substring(0, 3000);
        }

        return item;
    }

    toggleCurrentHighlight(e) {
        this.currentEditItem = recalc({
            ...this.currentEditItem,
            isHighlighted: e.target.checked,
            isDirty: true
        });
    }

    _saveCurrentItemToList() {
        const updated = [...this.lineItems];
        updated[this.currentEditIndex] = recalc({ ...this.currentEditItem, isDirty: true });
        this.lineItems = updated;
    }

    goBackToItemsList() {
        this.isEditingItem = false;
        this.currentEditItem = null;
        this._refreshNavDots();
    }

    // ★ FIX: saveAndBack now also persists to Salesforce
    /**async saveAndBack() {
        console.log('save and back callinggg');
        this._saveCurrentItemToList();
        this.isEditingItem = false;
        this.currentEditItem = null;

        try {
            console.log('💾 Saving item to Salesforce...');
            await this._saveLineItemsToSF();
            this._toast('✅ Item saved to Salesforce!', 'success');
        } catch (error) {
            console.error('❌ Save Error:', error);
            this._toast('Error saving item: ' + (error.body?.message || error.message), 'error');
        }
    }**/
    async saveAndBack() {

        this._saveCurrentItemToList();

        try {

            console.log(
                'Saving item...'
            );

            await this._saveLineItemsToSF();

            // IMPORTANT
            await this._fetchLineItemsFromSF();

            // refresh preview data
            this.originalData =
                JSON.stringify(
                    this._buildPayload()
                );

            this._toast(
                'Item saved!',
                'success'
            );

        } catch (error) {

            console.error(error);

            this._toast(
                'Error saving item',
                'error'
            );

            return;
        }

        this.isEditingItem = false;

        this.currentEditItem = null;

        this.showItemsPopup = false;
    }

    saveAndNext() {
        this._saveCurrentItemToList();
        const nextIdx = this.currentEditIndex + 1;
        if (nextIdx < this.lineItems.length) {
            this._openEditorForIndex(nextIdx);
        }
    }

    // ★ FIX: saveAndDone now correctly saves ALL items to Salesforce
    async saveAndDone() {
        this._saveCurrentItemToList();

        try {
            console.log('💾 Saving all items to Salesforce...');
            await this._saveLineItemsToSF();
            this.showGroupCheckbox = true;
            this._toast('✅ All items saved to Salesforce!', 'success');
        } catch (error) {
            console.error('❌ Save Error:', error);
            this._toast('Error saving items: ' + (error.body?.message || error.message), 'error');
        }
        //this.showItemsPopup = false;
        this.isEditingItem = false;
        this.currentEditItem = null;
    }

    triggerCurrentProductImageUpload() {
        const inp = this.template.querySelector('input[data-key="currentItem"]');
        if (inp) inp.click();
    }

    handleCurrentProductImageUpload(e) {
        const file = e.target.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (ev) => {
            this.currentEditItem = recalc({ ...this.currentEditItem, imageDataUrl: ev.target.result });
        };
        reader.readAsDataURL(file);
    }

    removeCurrentProductImage() {
        this.currentEditItem = recalc({ ...this.currentEditItem, imageDataUrl: null });
    }

    // removeItem(e) {
    //     const id = e.currentTarget.dataset.id;
    //     this.lineItems = this.lineItems.filter(li => li.id !== id);
    //     this._renumber();
    // }
    // async removeItem(event) {
    //     const result = await LightningConfirm.open({
    //         message: 'Are you sure you want to delete this item?',
    //         variant: 'header',
    //         label: 'Delete Confirmation'
    //     });

    //     if (!result) {
    //         return;
    //     }

    //     const id = event.currentTarget.dataset.id;

    //     const item =
    //         this.lineItems.find(li => li.id === id);

    //     try {

    //         // ===== DELETE FROM SALESFORCE =====
    //         if (item?.sfId) {

    //             await deleteQuotationLineItem({
    //                 lineItemId: item.sfId
    //             });
    //         }

    //         // ===== REMOVE FROM UI =====
    //         this.lineItems =
    //             this.lineItems.filter(li => li.id !== id);

    //         this._toast(
    //             'Item deleted successfully.',
    //             'success'
    //         );

    //     } catch (error) {

    //         this._toast(
    //             'Unable to delete item.',
    //             'error'
    //         );
    //     }
    // }
    async removeItem(event) {

        const id =
            event.currentTarget.dataset.id;

        if (!id) {
            return;
        }

        const item =
            this.lineItems.find(
                li => li.id === id
            );

        this.openDeleteModal(

            'Are you sure you want to delete this item?',

            async () => {

                try {

                    // ===== DELETE FROM SALESFORCE =====
                    if (item?.sfId) {

                        await deleteQuotationLineItem({

                            lineItemId: item.sfId

                        });
                    }

                    // ===== REMOVE FROM LOCAL UI =====
                    this.lineItems =
                        this.lineItems.filter(

                            li => li.id !== id
                        );

                    this._toast(

                        'Item deleted successfully.',

                        'success'
                    );

                } catch (error) {

                    console.error(
                        'Delete Error:',
                        error
                    );

                    this._toast(

                        'Error deleting item.',

                        'error'
                    );
                }
            }
        );
    }
    // ── getters ───────────────────────────────────────────────────────────
    get hasItems() { return this.lineItems.length > 0; }
    get primaryCurrency() {
        // If line items exist, use first item's currency symbol
        if (this.lineItems.length > 0) {
            return this.lineItems[0].currency || '₹';
        }
        // Fallback: derive from Salesforce CurrencyIsoCode
        const isoToSym = {
            'INR': '₹',
            'USD': '$'
        };
        return isoToSym[this.quotationCurrency] || '₹';
    }
    get quotationDateFormatted() { return fmtDate(this.quotationDate); }
    get validUntilFormatted() { return fmtDate(this.validUntil); }
    get hasTermsRows() { return this.paymentTerms || this.delivery || this.pricesBasis || this.validUntil; }

    // ── totals ────────────────────────────────────────────────────────────
    // get _subtotal() {
    //     return this.lineItems.reduce((s, li) => s + (li.quantity || 0) * (li.unitPrice || 0), 0);
    // }
    get _subtotal() {

        return this.lineItems.reduce(
            (sum, li) =>
                sum + (li.totalPrice || 0),
            0
        );
    }
    get _totalDisc() {
        return this.lineItems.reduce((s, li) => {
            const base = (li.quantity || 0) * (li.unitPrice || 0);
            return s + base * ((li.discount || 0) / 100);
        }, 0);
    }
    // get _totalGST() {
    //     return this.lineItems.reduce((s, li) => {
    //         // const base = (li.quantity || 0) * (li.unitPrice || 0);
    //         // const ad = base - base * ((li.discount || 0) / 100);
    //         // return s + ad * ((li.gst || 0) / 100);
    //         return s +
    //             ((li.totalPrice || 0)
    //                 * ((li.gst || 0) / 100));
    //     }, 0);
    // }


    // If you want to calculate GST in LWC (for real-time updates)

    // get _totalGST() {
    //     const freight = parseFloat(this.freightCharges) || 0;
    //     const pfAmount = this._subtotal * (this.pfPercent / 100);

    //     // GST on all three components
    //     const gstOnSubtotal = this._subtotal * 0.18;
    //     const gstOnPF = pfAmount * 0.18;
    //     const gstOnFreight = freight * 0.18;

    //     return gstOnSubtotal + gstOnPF + gstOnFreight;
    // }

    // get _totalGST() {
    //     // Har line item ka GST already recalc() mein uske apne gst% se calculate ho chuka hai (li.gstAmount)
    //     const lineItemsGST = this.lineItems.reduce(
    //         (sum, li) => sum + (li.gstAmount || 0),
    //         0
    //     );

    //     // PF aur Freight pe GST — first item ka GST% (ya quotation-level gstPercent) use karo
    //     const gstRate = this.lineItems.length > 0
    //         ? (this.lineItems[0].gst || 0) / 100
    //         : (this.gstPercent || 0) / 100;

    //     const freight = parseFloat(this.freightCharges) || 0;
    //     const pfAmount = this._subtotal * (this.pfPercent / 100);
    //     console.log('quotationCurrency:', this.quotationCurrency);
    //     // USD quotations: no GST on Freight or P&F, only on line items
    //     const isUSD = this.quotationCurrency === 'USD';
    //     console.log('Calculating GST: lineItemsGST=', lineItemsGST, 'pfAmount=', pfAmount, 'freight=', freight, 'gstRate=', gstRate, 'isUSD=', isUSD);

    //     const gstOnPF = isUSD ? 0 : pfAmount * gstRate;
    //     console.log('GST on PF:::', gstOnPF);
    //     const gstOnFreight = isUSD ? 0 : freight * gstRate;
    //     console.log('GST on Freight:::', gstOnFreight);
    //     return lineItemsGST + gstOnPF + gstOnFreight;

    // }
    get _totalGST() {
        // Har line item ka GST already recalc() mein uske apne gst% se calculate ho chuka hai (li.gstAmount)
        const lineItemsGST = this.lineItems.reduce(
            (sum, li) => sum + (li.gstAmount || 0),
            0
        );

        const freight = parseFloat(this.freightCharges) || 0;
        const pfAmount = this._subtotal * (this.pfPercent / 100);

        // USD quotations: no GST on Freight or P&F, only on line items
        const isUSD = this.quotationCurrency === 'USD';

        // ★ Custom Label GST_Amount se rate lo (e.g. "18" → 0.18)
        const gstRate = Number(GST_AMOUNT) / 100;

        const gstOnPF = isUSD ? 0 : pfAmount * gstRate;
        const gstOnFreight = isUSD ? 0 : freight * gstRate;

        return lineItemsGST + gstOnPF + gstOnFreight;
    }

    get totalGSTFmt() {
        return fmt(this._totalGST);
    }
    // get _totalPriceAmount() {

    //     return this.lineItems.reduce((sum, li) => {

    //         return sum + (li.totalPrice || 0);

    //     }, 0);
    // }
    // get _pfAmt() { return (this._subtotal - this._totalDisc) * ((this.pfPercent || 0) / 100); }
    get _pfAmt() {

        return this._subtotal *
            ((this.pfPercent || 0) / 100);
    }
    // get _grandTotal() {
    //     const freight = this.freightCharges || 0;

    //     // return (this._subtotal - this._totalDisc)
    //     //     + this._totalGST
    //     //     + this._pfAmt
    //     //     + freight;
    //     return this._totalPriceAmount
    //         + this._totalGST
    //         + this._pfAmt
    //         + freight;
    // }
    get _grandTotal() {

        const subtotal =
            this._subtotal || 0;

        const pf =
            this._pfAmt || 0;

        const freight =
            this.freightCharges || 0;

        const gst =
            this._totalGST || 0;

        return (
            subtotal +
            pf +
            freight +
            gst
        );
    }

    get subtotalFmt() { return fmt(this._subtotal); }
    get totalDiscFmt() { return fmt(this._totalDisc); }
    get totalGSTFmt() { return fmt(this._totalGST); }
    get pfAmtFmt() { return fmt(this._pfAmt); }
    get grandTotalFmt() { return fmt(this._grandTotal); }

    // ── field handlers ────────────────────────────────────────────────────
    f_quotationNumber(e) { this.quotationNumber = e.target.value; }
    f_quotationName(e) { this.quotationName = e.target.value; }
    f_quotationDate(e) { this.quotationDate = e.target.value; }
    f_validUntil(e) { this.validUntil = e.target.value; }
    f_reference(e) { this.reference = e.target.value; }
    f_subject(e) { this.subject = e.target.value; }
    f_customerName(e) { this.customerName = e.target.value; }
    f_contactPerson(e) { this.contactPerson = e.target.value; }
    f_mobileNumber(e) { this.mobileNumber = e.target.value; }
    f_customerEmail(e) { this.customerEmail = e.target.value; }
    f_customerAddress(e) { this.customerAddress = e.target.value; }
    f_emailTo(e) { this.emailTo = e.target.value; }
    f_emailCC(e) { this.emailCC = e.target.value; }
    f_emailBCC(e) { this.emailBCC = e.target.value; }
    f_emailSubject(e) { this.emailSubject = e.target.value; }
    f_emailBody(e) { this.emailBody = e.target.value; }

    // ── email modal ───────────────────────────────────────────────────────
    // openEmailModal() {
    //     this.emailTo = this.customerEmail || '';
    //     this.emailSubject = `Quotation ${this.quotationNumber} from ${this.companyName}`;
    //     this.emailBody =
    //         `Dear ${this.contactPerson || "Sir/Ma'am"},\n\n` +
    //         `Please find attached our Quotation No. ${this.quotationNumber} dated ${this.quotationDateFormatted}.\n\n` +
    //         `Grand Total: ₹ ${this.grandTotalFmt}\n\n` +
    //         `Kindly review and confirm at the earliest.\n\n` +
    //         `Warm regards,\n${this.companyName}\n${this.companyPhone}\n${this.companyEmail}`;
    //     this.showEmailModal = true;
    // }
    // async openEmailModal() {
    //     // ★ DB se aaye emails validate karo
    //     this.emailTo = this._cleanEmails(this.emailTo);
    //     this.emailCC = this._cleanEmails(this.emailCC);
    //     this.emailBCC = this._cleanEmails(this.emailBCC);

    //     this.showEmailModal = true;

    //     try {
    //         const result = await getEmailTemplateContent({
    //             templateName: 'Quotation Email Template',
    //             quotationId: this._recordId
    //         });
    //         this.emailSubject = result.subject;
    //         this.emailBody = result.htmlBody;
    //     } catch (error) {
    //         console.error(error);
    //         this.emailSubject = `Offer No ${this.quotationNumber} from MicroSet`;
    //         this._toast('Email template load failed, using default', 'info');
    //     }
    // }
    async openEmailModal() {
        // ★ Quotation record se fresh To/CC/BCC fetch karo, taaki modal mein
        // hamesha actual saved values hi dikhein — kisi aur ka manually
        // typed/stray address modal mein na reh jaaye.
        try {
            const result = await getQuotations({ recordId: this._recordId });
            if (result && result.length > 0) {
                const q = result[0];
                this.emailTo = q.Email__c || '';
                this.emailCC = q.Email_CC__c || '';
                this.emailBCC = q.Email_BCC__c || '';
            }
        } catch (error) {
            console.error('Error refreshing quotation emails:', error);
        }

        // ★ DB se aaye emails validate/clean karo (invalid format hata do)
        this.emailTo = this._cleanEmails(this.emailTo);
        this.emailCC = this._cleanEmails(this.emailCC);
        this.emailBCC = this._cleanEmails(this.emailBCC);

        this.showEmailModal = true;

        try {
            const result = await getEmailTemplateContent({
                templateName: 'Quotation Email Template',
                quotationId: this._recordId
            });
            this.emailSubject = result.subject;
            this.emailBody = result.htmlBody;
        } catch (error) {
            console.error(error);
            this.emailSubject = `Offer No ${this.quotationNumber} from MicroSet`;
            this._toast('Email template load failed, using default', 'info');
        }
    }
    // ★ Email string clean karo — invalid remove karo
    _cleanEmails(emailStr) {
        if (!emailStr) return '';
        const emailRegex = /^[a-zA-Z0-9._|%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        return emailStr
            .split(',')
            .map(e => e.trim())
            .filter(e => e && emailRegex.test(e))
            .join(', ');
    }
    closeEmailModal() { this.showEmailModal = false; }

    _buildPayload() {
        return {
            quotationNumber: this.quotationNumber,
            quotationName: this.quotationName,
            quotationDate: this.quotationDate,
            companyName: this.companyName,
            companyAddress: this.companyAddress,
            companyPhone: this.companyPhone,
            companyEmail: this.companyEmail,
            companyGSTIN: this.companyGSTIN,
            customerName: this.customerName,
            contactPerson: this.contactPerson,
            mobileNumber: this.mobileNumber,
            customerEmail: this.customerEmail,
            customerAddress: this.customerAddress,
            grandTotal: this._grandTotal,
            pfPercent: this.pfPercent,
            //freightCharges: this.Shipping_and_Handling__c,
            quotationCreatedBy: this.quotationCreatedBy,
            gstPercent: this.gstPercent,
            lineItemsJson: JSON.stringify(this.lineItems.map(li => ({
                itemNumber: li.itemNumber,
                productName: li.productName,
                hsnCode: li.hsnCode,
                description: li.description,
                quantity: li.quantity,
                unit: li.unit,
                currency: li.currency,
                unitPrice: li.unitPrice,
                discount: li.discount,
                gst: li.gst,
                groupId: li.groupId || null
            })))
        };

    }

    // customQuotation.js — handleSaveAndEmail method
    async handleSaveAndEmail() {
        if (!this.emailTo) {
            this._toast('Please enter at least one recipient email.', 'error');
            return;
        }
        this.isSending = true;
        try {
            // ★ Pehle PDF generate karo automatically
            this._toast('Generating PDF...', 'info');
            await generateVFPdf({ quotationId: this._recordId });

            // Phir email send karo
            const payload = {
                recordId: this._recordId || null,
                toAddresses: this.emailTo.split(',').map(s => s.trim()).filter(Boolean),
                ccAddresses: this.emailCC
                    ? this.emailCC.split(',').map(s => s.trim()).filter(Boolean) : [],
                bccAddresses: this.emailBCC
                    ? this.emailBCC.split(',').map(s => s.trim()).filter(Boolean) : [],
                emailSubject: this.emailSubject,
                emailBody: this.emailBody,
                quotationNumber: this.quotationNumber,
                companyName: this.companyName,
                grandTotal: this._grandTotal,
            };
            console.log('Sending email with payload:', JSON.stringify(payload));

            await sendQuotationEmail({ payloadMap: payload });
            this.showEmailModal = false;
            this._toast('Quotation emailed successfully!', 'success');

        } catch (err) {
            this._toast('Error: ' + (err.body?.message || err.message), 'error');
        } finally {
            this.isSending = false;
        }
    }
    //new added quotation created by value assignment
    get quotationCreatedByOptionsForUI() {

        return this.quotationCreatedByOptions.map(
            item => ({

                ...item,

                selected:
                    item.value ===
                    this.quotationCreatedBy

            })
        );
    }

    get isNoneSelected() {

        return !this.quotationCreatedBy;
    }
    async loadQuotation() {
        try {
            const result = await getQuotations({ recordId: this._recordId });
            if (result && result.length > 0) {
                const q = result[0];
                this.quotationNumber = q.Quote_Number__c;
                this.quotationName = q.Name;
                this.contactPerson = q.Contact_Name__r?.Name || '';
                this.customerName = q.Contact_Name__r?.Account?.Name || '';
                this.customerEmail = q.Email__c || '';
                this.emailTo = q.Email__c || '';
                this.emailCC = q.Email_CC__c || '';    // ★ CC auto-fill
                this.emailBCC = q.Email_BCC__c || '';
                this.mobileNumber = q.ContactPhone__c || '';
                this.quotationDate = q.Quotation_Date__c;
                this.validUntil = q.Expiration_Date__c;
                this.reference = q.Reference__c;
                this.subject = q.Description__c;
                this.quotationCreatedBy = q.Quotation_Created_By__c || '';
                this.freightCharges = q.Shipping_and_Handling__c || 0;

                const addressParts = [
                    q.Bill_To__Street__s, q.Bill_To__City__s,
                    q.Bill_To__StateCode__s, q.Bill_To__PostalCode__s,
                    q.Bill_To__CountryCode__s
                ].filter(Boolean);
                // if (q.Bill_To_Name__c) addressParts.push(q.Bill_To_Name__c);
                this.customerAddress = addressParts.join(', ');



                await this._fetchGroupsFromSF();
                await this._fetchLineItemsFromSF();
            }
            this.originalData = JSON.stringify(this._buildPayload());
        } catch (error) {
            console.error('Error loading quotation:', error);
        }
    }

    async _fetchGroupsFromSF() {
        try {
            const result = await getQuoteLineGroups({ quotationId: this._recordId });
            this.groups = (result || []).map(g => ({
                id: g.Id,
                headerName: g.Header__c,
                sortOrder: g.Sort_Order__c
            }));
        } catch (error) {
            console.error('Error loading groups:', error);
            this.groups = [];
        }
    }

    // async _fetchLineItemsFromSF() {
    //     try {
    //         const result = await getQuotationLineItems({ quotationId: this._recordId });
    //         _seq = 0;
    //         this.lineItems = result.map((item, index) => {
    //             _seq++;
    //             return recalc({
    //                 id: item.Id,
    //                 sfId: item.Id,
    //                 itemNumber: index + 1,
    //                 productName: item.Productss__r?.Product_Name__c || '',
    //                 hsnCode: item.Productss__r?.HSN_Code__c || '',
    //                 modelNumber: item.Model_Number__c || '',
    //                 // ★ CRITICAL: Convert \n back to <br/> for rich text editor
    //                 description: item.Line_Description__c
    //                     ? item.Line_Description__c.replace(/\n/g, '<br/>')
    //                     : '',

    //                 quantity: item.Quantity__c || 0,
    //                 unit: item.Unit__c || 'Nos',
    //                 currency: item.Currency__c || '₹',
    //                 unitPrice: item.List_Price__c || 0,
    //                 discount: item.Discount__c || 0,
    //                 gst: item.GST__c || 18,
    //                 imageDataUrl: null,
    //                 isHighlighted: item.Is_Highlighted__c || false,
    //                 groupId: item.Quote_Line_Group__c || null,
    //                 sortOrder: item.Sort_Order__c || index + 1,
    //                 isDirty: false,
    //             });
    //         });
    //         console.log('✅ Loaded', this.lineItems.length, 'items from Salesforce');
    //     } catch (error) {
    //         console.error('❌ Error loading line items:', error);
    //     }
    // }
    async _fetchLineItemsFromSF() {
        try {
            // ★ Derive symbol from quotation's CurrencyIsoCode
            const isoToSym = { 'INR': '₹', 'USD': '$', 'EUR': '€', 'GBP': '£' };
            const quotationSym = isoToSym[this.quotationCurrency] || '₹';

            const result = await getQuotationLineItems({ quotationId: this._recordId });
            _seq = 0;
            this.lineItems = result.map((item, index) => {
                _seq++;
                return recalc({
                    id: item.Id,
                    sfId: item.Id,
                    itemNumber: index + 1,
                    productName: item.Productss__r?.Product_Name__c || '',
                    hsnCode: item.Productss__r?.HSN_Code__c || '',
                    modelNumber: item.Model_Number__c || '',
                    // ★ CRITICAL: Convert \n back to <br/> for rich text editor
                    description: item.Line_Description__c
                        ? item.Line_Description__c.replace(/\n/g, '<br/>')
                        : '',
                    quantity: item.Quantity__c || 0,
                    unit: item.Unit__c || 'Nos',
                    currency: quotationSym,  // ★ USE QUOTATION CURRENCY SYMBOL
                    unitPrice: item.List_Price__c || 0,
                    discount: item.Discount__c || 0,
                    // gst: item.GST__c || 18,
                    gst: (item.GST__c !== null && item.GST__c !== undefined) ? item.GST__c : 18,
                    imageDataUrl: null,
                    isHighlighted: item.Is_Highlighted__c || false,
                    groupId: item.Quote_Line_Group__c || null,
                    sortOrder: item.Sort_Order__c || index + 1,
                    isDirty: false,
                });
            });
            console.log('✅ Loaded', this.lineItems.length, 'items from Salesforce');
        } catch (error) {
            console.error('❌ Error loading line items:', error);
        }
    }

    async addItem() { await this.addItemFromPopup(); }

    _renumber() {
        _seq = 0;
        this.lineItems = this.lineItems.map(li => { _seq++; return { ...li, itemNumber: _seq }; });
    }

    connectedCallback() {
        setTimeout(() => {
            if (!this.originalData) {
                this.originalData = JSON.stringify(this._buildPayload());
            }
        }, 500);
    }

    _tick() { return new Promise(r => setTimeout(r, 100)); }

    _toast(msg, type) {
        const cfg = {
            success: { cls: 'qt-toast qt-toast-ok', ico: '✅' },
            error: { cls: 'qt-toast qt-toast-err', ico: '❌' },
            info: { cls: 'qt-toast qt-toast-info', ico: 'ℹ️' }
        };
        const c = cfg[type] || cfg.info;
        this.toastMsg = msg;
        this.toastCls = c.cls;
        this.toastIco = c.ico;
        this.showToast = true;
        setTimeout(() => { this.showToast = false; }, 5000);
    }

    handleCancel() {
        if (!this.originalData) return;
        const data = JSON.parse(this.originalData);
        Object.assign(this, data);
        this._toast('Changes discarded', 'info');
    }

    async saveAndDone() {
        this._saveCurrentItemToList();

        try {
            console.log('💾 Saving all items to Salesforce...');
            await this._saveLineItemsToSF();
            this.showGroupCheckbox = true;
            this._toast('✅ All items saved to Salesforce!', 'success');
        } catch (error) {
            console.error('❌ Save Error:', error);
            this._toast('Error saving items: ' + (error.body?.message || error.message), 'error');
        }
        //this.showItemsPopup = false;
        this.isEditingItem = false;
        this.currentEditItem = null;
    }


    // ════════════════════════════════════════════════════════════════
    // CHANGE 6: Update handleSaveDetails method (main save button)
    // ════════════════════════════════════════════════════════════════

    async handleSaveDetails() {

        if (!this.customerName || !this.customerEmail) {
            const missingFields = [];

            if (!this.customerName) {
                missingFields.push('Customer Name');
            }

            if (!this.contactPerson) {
                missingFields.push('Contact Person');
            }

            if (!this.mobileNumber) {
                missingFields.push('Mobile Number');
            }

            if (!this.customerEmail) {
                missingFields.push('Customer Email');
            }

            if (!this.customerAddress) {
                missingFields.push('Customer Address');
            }

            if (missingFields.length > 0) {
                const message =
                    missingFields.length === 1
                        ? `Please enter ${missingFields[0]}.`
                        : `Please enter:\n• ${missingFields.join('\n• ')}`;

                this._toast(message, 'error');
                return;
            }
        }

        if (this.lineItems.length === 0) {
            this._toast('Add at least one item', 'error');
            return;
        }

        this.isSaving = true;
        try {
            console.log('💾 Starting save process...');

            // 1. Save quotation header fields
            const payload = {
                ...this._buildPayload(),
                recordId: this._recordId,
                reference: this.reference,
                freightCharges: this.freightCharges
            };
            console.log('Payload for save:', JSON.stringify(payload));
            console.log('1️⃣ Saving quotation header...');
            await saveFullQuotation({ payloadMap: payload });
            console.log('✅ Quotation header saved');

            // 2. ★ Save ALL line items to Salesforce
            console.log('2️⃣ Saving', this.lineItems.length, 'line items...');
            await this._saveLineItemsToSF();
            console.log('✅ Line items saved');

            // 3. Save Terms & Conditions
            if (this._recordId) {
                console.log('3️⃣ Saving terms & conditions...');
                await saveTermsAndConditions({
                    quotationId: this._recordId,
                    termsMap: this.termsData
                });
                console.log('✅ Terms saved');

                this.originalTermsData = JSON.stringify(this.termsData);
                this.hasTermsChanges = false;
            }

            this._storeOriginalData();
            this._toast(' Quotation saved successfully!', 'success');

        } catch (error) {
            console.error('❌ Save Error:', error);
            this._toast(error.body?.message || 'Error saving data', 'error');
        } finally {
            this.isSaving = false;
        }
    }
    get groupModalTitle() { return this.editingGroupId ? 'Rename Group' : 'New Group'; }
    get groupModalButtonLabel() { return this.editingGroupId ? '💾 Update' : '➕ Create Group'; }

    isStyleLoaded = false;

    renderedCallback() {
        if (this.isStyleLoaded) return;
        this.isStyleLoaded = true;
        loadStyle(this, MY_STYLES)
            .then(() => console.log('Styles loaded successfully'))
            .catch(error => console.error('Error loading styles', error));
    }


    /**toggleSelectedForGroup(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        console.log('Toggling item', id, 'for group', this.activeGroupId, 'Checked:', checked);
        this.lineItems = this.lineItems.map(li => {
            if (li.id === id) {
                return {
                    ...li,
                    isSelectedForGroup: checked,
                    groupId: checked ? this.activeGroupId : null,
                    isDirty: true // mark as dirty so it will be saved to SF on next save
                };
            }
            return li;
        });
        console.log('Updated lineItems after toggle:', this.lineItems);
    }**/

    toggleSelectedForGroup(event) {

        const id = event.target.dataset.id;

        const checked = event.target.checked;

        console.log(
            'Toggling item',
            id,
            'for group',
            this.activeGroupId,
            'Checked:',
            checked
        );

        // TEMP LIST ONLY
        if (checked) {

            if (
                !this.pendingGroupSelection
                    .includes(id)
            ) {

                this.pendingGroupSelection = [

                    ...this.pendingGroupSelection,

                    id
                ];
            }

        } else {

            this.pendingGroupSelection =

                this.pendingGroupSelection
                    .filter(
                        itemId =>
                            itemId !== id
                    );
        }

        console.log(
            'Pending:',
            this.pendingGroupSelection
        );

        // KEEP UI CHECKBOX STATE
        this.lineItems = this.lineItems.map(li => {

            if (li.id === id) {

                return {

                    ...li,

                    isSelectedForGroup:
                        checked,

                    isDirty: true
                };
            }

            return li;
        });

        console.log(
            'Updated lineItems:',
            this.lineItems
        );
    }

}