import { LightningElement, api, track, wire } from 'lwc';
//import getCustomPricebookEntries from '@salesforce/apex/CustomProductFetcher.getCustomPricebookEntries';
import createCustomLineItems from '@salesforce/apex/CustomProductFetcher.createCustomLineItems';
import createQuotationLineItems from '@salesforce/apex/CustomProductFetcher.createQuotationLineItems';
import getQuoteLineItemLastCreated from '@salesforce/apex/CustomProductFetcher.getQuoteLineItemLastCreated';
import getCurrentQuotation from '@salesforce/apex/CustomProductFetcher.getCurrentQuotation';
import fetchActiveProduct from '@salesforce/apex/CustomProductFetcher.fetchActiveProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import MY_STYLES from '@salesforce/resourceUrl/modelcss';



const colum = [
    { label: 'Product Code', fieldName: 'ProductCode' },
    { label: 'Product Name', fieldName: 'ProductName' },
    {
        label: 'List Price', fieldName: 'List_Price__c', type: 'currency', cellAttributes: {
            alignment: 'left'
        }
    },
]

const oppoLineItemCol = [
    { label: 'Product Code', fieldName: 'ProductCode' },
    { label: 'Product Name', fieldName: 'ProductName' },
    {
        label: 'Line Description',
        fieldName: 'LineDescription__c',
        editable: true,
        type: 'Rich Text Area',
        wrapText: true,
        initialWidth: 350
    },
    { label: 'Quantity', fieldName: 'Quantity__c', editable: true, type: 'number' },
    { label: 'List Price', fieldName: 'SalesPrice__c', editable: true, type: 'currency' },
    { label: 'Discount', fieldName: 'Discount__c', editable: true, type: 'percent' }

]

const PAGE_SIZE = 10;
export default class AddProductToQuotation extends LightningElement {

    @api recordId;
    @track pageRef;

    isLoading = false;
    @track products = [];
    columns = colum;
    oppoLineCol = oppoLineItemCol;

    currencyOptions = [
        { label: 'INR - Indian Rupee', value: 'INR' },
        { label: 'USD - US Dollar', value: 'USD' }
    ];

    @track defaultCurrency = 'INR';
    @track filteredProducts = [];
    searchKey = '';
    @track visibleProducts = [];
    currentPage = 1;
    totalPages = 1;
    @track selectedRowsMap = new Map();
    @track pageSelectedRowIds = [];
    @track selectedRowIds = [];
    @track isNextVisible = false;
    @track showModal = false;
    @track selectedProducts = [];
    @track showProductSelection = true;
    @track objectName;
    @track enableFooter = false;
    @track currentQuote;
    @track suggestionPriceList = [];
    @track modelClass = 'slds-col slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12';
    @wire(getRecord, {
        recordId: '$recordId',
        layoutTypes: ['Full'],
        modes: ['View']
    })
    wiredRecord({ error, data }) {
        if (data) {
            // ★ Direct record se currency uthao — chahe Opportunity_Custom__c ho ya Quotation__c
            this.defaultCurrency = data.fields?.CurrencyIsoCode?.value || 'INR';
            console.log('### defaultCurrency from wiredRecord --->', this.defaultCurrency);

            // Agar products already load ho chuke hain, unko currency ke according refresh karo
            this.applyDefaultCurrency();
        } else if (error) {
            console.error('Error fetching record currency:', error);
        }
    }

    applyDefaultCurrency() {
        if (!this.products.length) return;

        const currency = this.defaultCurrency;

        const updateRow = (row) => ({
            ...row,
            CurrencyIsoCode: currency,
            SalesPrice__c: currency === 'USD'
                ? (row.List_Price_USD__c || 0)
                : (row.List_Price__c || 0)
        });

        this.products = this.products.map(updateRow);
        this.filteredProducts = this.filteredProducts.map(updateRow);
        this.updatePagination();
    }
    get saveButtonLabel() {
        if (this.recordId?.startsWith('a01')) {
            this.objectName = 'Opportunity_Custom__c'
            return 'Save to Opportunity';
        } else if (this.recordId?.startsWith('a06')) {
            this.objectName = 'Quotation__c'
            return 'Save to Quotation';
        }
    }
    get enableSuggestion() {
        if (this.suggestionPriceList.length > 0) {
            this.modelClass = 'slds-col slds-large-size_9-of-12 slds-medium-size_9-of-12 slds-size_9-of-12';
            return true;
        } else {
            this.modelClass = 'slds-col slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12';
            return false;
        }
        return this.suggestionPriceList.length > 0 ? true : false;
    }

    // connectedCallback() {
    //     console.log('connectedCallback--->', this.recordId);
    //     if (this.pageRef && this.pageRef.state && this.pageRef.state.recordId) {
    //         this.recordId = this.pageRef.state.recordId;
    //     }
    //     console.log('this.recordId--->' + this.recordId);
    //     setTimeout(() => {
    //         const modalContainer = document.querySelector('.modal-container');
    //         if (modalContainer) {
    //             modalContainer.style.width = '100%';
    //             modalContainer.style.maxWidth = '95%';
    //             modalContainer.style.minWidth = '480px';
    //         }
    //         console.log('this.recordId--->' + this.recordId);
    //         getCurrentQuotation({ quotationId: this.recordId })
    //             .then(result => {
    //                 this.currentQuote = result;
    //             })
    //             .catch(error => {
    //                 console.log('error......quote..not' + JSON.stringify(error));
    //             });
    //     }, 100);
    //     this.isLoading = true;
    //     // getCustomPricebookEntries()
    //     //     .then(result => {


    //     //         console.log('## result: ', result);
    //     //         this.products = result.map(item => ({
    //     //             ...item,
    //     //             ProductCode: item.Product__r?.Name,
    //     //             ProductName: item.Product__r?.Product_Name__c,
    //     //             ProductDescription: item.Product__r?.Product_Description__c,
    //     //             ProductFamily: item.Product__r?.Product_Family__c,
    //     //             HSN_SAC: item.Product__r?.Product_Code__c,
    //     //             Quantity__c: 1,
    //     //             SalesPrice__c: item.List_Price__c || 0,
    //     //             Date__c: null,
    //     //             LineDescription__c: ''
    //     //         }));
    //     //         console.log('records id opportunity ---->' + this.recordId);
    //     //         this.filteredProducts = this.products;
    //     //         // console.log('Flattened products: ',JSON.stringify(this.products));
    //     //         this.updatePagination();
    //     //         this.isLoading = false;

    //     //     })
    //     //     .catch(error => {
    //     //         this.isLoading = false;
    //     //         console.error('Error loading products', error);
    //     //     });
    //     fetchActiveProduct()
    //         .then(result => {

    //             if (!result || result.length === 0) {
    //                 console.warn('No Products Found');
    //             }

    //             this.products = result.map(item => ({
    //                 Id: item.Id,
    //                 Product__c: item.Id,
    //                 ProductCode: item.HSN_Code__c,
    //                 ModelNumber: item.Model_Numbers__c,
    //                 ProductName: item.Product_Name__c,
    //                 HSN_Code__c: item.HSN_Code__c,
    //                 Product_Name__c: item.Product_Name__c,
    //                 List_Price__c: item.List_Price__c,
    //                 List_Price_USD__c: item.List_Price_USD__c,
    //                 Discount__c: 0,
    //                 GST__c: item.GST__c || 0,
    //                 // default values
    //                 Quantity__c: 1,
    //                 CurrencyIsoCode: 'INR',
    //                 SalesPrice__c: item.List_Price__c || 0,
    //                 Date__c: null,

    //                 /**LineDescription__c: item.Product_Description__c
    //                     ?.replace(/<[^>]*>/g, '')
    //                     ?.replace(/\s+/g, ' ')
    //                     ?.trim()**/


    //                 LineDescription__c: item.Product_Description__c
    //                 // ?.replace(/<br\s*\/?>/gi, '\n')
    //                 // ?.replace(/<\/p>/gi, '\n')
    //                 // ?.replace(/<li>/gi, '• ')
    //                 // ?.replace(/<\/li>/gi, '\n')
    //                 // ?.replace(/<[^>]*>/g, '')
    //                 // ?.trim()
    //             }));

    //             this.filteredProducts = this.products;
    //             this.updatePagination();
    //             this.isLoading = false;
    //         })
    //         .catch(error => {
    //             this.isLoading = false;
    //             console.error('Error loading products', error);
    //         });
    // }
    connectedCallback() {
        console.log('connectedCallback--->', this.recordId);
        if (this.pageRef && this.pageRef.state && this.pageRef.state.recordId) {
            this.recordId = this.pageRef.state.recordId;
        }
        console.log('this.recordId--->' + this.recordId);

        setTimeout(() => {
            const modalContainer = document.querySelector('.modal-container');
            if (modalContainer) {
                modalContainer.style.width = '100%';
                modalContainer.style.maxWidth = '95%';
                modalContainer.style.minWidth = '480px';
            }
            console.log('this.recordId--->' + this.recordId);
            getCurrentQuotation({ quotationId: this.recordId })
                .then(result => {
                    this.currentQuote = result;
                })
                .catch(error => {
                    console.log('error......quote..not' + JSON.stringify(error));
                });
        }, 100);

        this.isLoading = true;

        fetchActiveProduct()
            .then(result => {
                if (!result || result.length === 0) {
                    console.warn('No Products Found');
                }

                this.products = result.map(item => ({
                    Id: item.Id,
                    Product__c: item.Id,
                    ProductCode: item.HSN_Code__c,
                    ModelNumber: item.Model_Numbers__c,
                    ProductName: item.Product_Name__c,
                    HSN_Code__c: item.HSN_Code__c,
                    Product_Name__c: item.Product_Name__c,
                    List_Price__c: item.List_Price__c,
                    List_Price_USD__c: item.List_Price_USD__c,
                    Discount__c: 0,
                    GST__c: item.GST__c || 0,
                    Quantity__c: 1,
                    CurrencyIsoCode: this.defaultCurrency,           // ★ CHANGED: hardcoded 'INR' hata diya
                    SalesPrice__c: this.defaultCurrency === 'USD'
                        ? (item.List_Price_USD__c || 0)
                        : (item.List_Price__c || 0),                 // ★ CHANGED
                    Date__c: null,
                    LineDescription__c: item.Product_Description__c
                }));

                this.filteredProducts = this.products;
                this.updatePagination();
                this.isLoading = false;

                // ★ NEW: agar wire se currency pehle se aa chuki hai to immediately apply karo
                this.applyDefaultCurrency();
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error loading products', error);
            });
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        console.log('this.searchKey: ', JSON.stringify(this.searchKey));

        this.filteredProducts = this.products.filter(item =>
            (item.ProductName && item.ProductName.toLowerCase().includes(this.searchKey)) ||
            (item.ProductCode && item.ProductCode.toLowerCase().includes(this.searchKey)) ||
            (item.ModelNumber && item.ModelNumber.toLowerCase().includes(this.searchKey)) ||
            (item.ProductDescription && item.ProductDescription.toLowerCase().includes(this.searchKey))
        );
        this.currentPage = 1;
        this.updatePagination();
        console.log('this.filteredProducts: ', JSON.stringify(this.filteredProducts));
    }

    updatePagination() {
        this.totalPages = Math.ceil(this.filteredProducts.length / PAGE_SIZE);
        const start = (this.currentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        // this.visibleProducts = this.filteredProducts.slice(start, end);

        // this.pageSelectedRowIds = this.visibleProducts
        //     .map(row => row.Id)
        //     .filter(id => this.selectedRowsMap.has(id));
        this.visibleProducts = this.filteredProducts
            .slice(start, end)
            .map(row => ({
                ...row,
                isSelected: this.selectedRowsMap.has(row.Id)
            }));

        this.pageSelectedRowIds = this.visibleProducts
            .map(row => row.Id)
            .filter(id => this.selectedRowsMap.has(id));
    }


    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagination();
        }
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagination();
        }
    }

    handleFirst() {
        if (this.currentPage > 1) {
            this.currentPage = 1;
            this.updatePagination();
        }
    }

    handleLast() {
        if (this.currentPage < this.totalPages) {
            this.currentPage = this.totalPages;
            this.updatePagination();
        }
    }

    get disablePrevious() {
        return this.currentPage <= 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    // handleRowSelection(event) {
    //     const newlySelectedRows = event.detail.selectedRows;
    //     console.log('newlySelectedRows 1: -->' + newlySelectedRows);

    //     newlySelectedRows.forEach(row => {
    //         this.selectedRowsMap.set(row.Id, row);
    //     });
    //     console.log('newlySelectedRows 2: -->' + newlySelectedRows);

    //     const currentPageIds = this.visibleProducts.map(row => row.Id);
    //     const selectedIdsOnPage = new Set(newlySelectedRows.map(row => row.Id));
    //     console.log('currentPageIds 1: -->' + currentPageIds);

    //     currentPageIds.forEach(id => {
    //         if (!selectedIdsOnPage.has(id)) {
    //             this.selectedRowsMap.delete(id);
    //         }
    //     });
    //     console.log('currentPageIds 2: -->' + currentPageIds);

    //     this.selectedRowIds = Array.from(this.selectedRowsMap.keys());
    //     console.log('selectedRowIds 1: -->' + this.selectedRowIds);

    //     this.pageSelectedRowIds = this.visibleProducts
    //         .map(row => row.Id)
    //         .filter(id => this.selectedRowsMap.has(id));
    //     console.log('pageSelectedRowIds 1: -->' + this.pageSelectedRowIds);
    //     this.handleSuggestionPrice(this.selectedRowIds);
    //     this.enableFooter = true;
    //     this.isNextVisible = this.selectedRowIds.length > 0;

    // }
    handleRowSelection(event) {

        const rowId = event.target.dataset.id;
        const checked = event.target.checked;

        const rowData = this.visibleProducts.find(
            row => row.Id === rowId
        );

        if (checked) {
            this.selectedRowsMap.set(rowId, rowData);
        } else {
            this.selectedRowsMap.delete(rowId);
        }

        this.selectedRowIds =
            Array.from(this.selectedRowsMap.keys());

        this.pageSelectedRowIds =
            this.selectedRowIds;

        this.visibleProducts =
            this.visibleProducts.map(row => ({
                ...row,
                isSelected:
                    this.selectedRowsMap.has(row.Id)
            }));

        this.handleSuggestionPrice(this.selectedRowIds);

        this.enableFooter = true;

        this.isNextVisible =
            this.selectedRowIds.length > 0;
    }
    handleCurrencyChange(event) {
        const rowId = event.target.dataset.id;
        const newCurrency = event.detail.value;

        const updateRow = (row) => {
            if (row.Id !== rowId) return row;

            const newPrice = newCurrency === 'USD'
                ? (row.List_Price_USD__c || 0)
                : (row.List_Price__c || 0);

            return {
                ...row,
                CurrencyIsoCode: newCurrency,
                SalesPrice__c: newPrice
            };
        };

        this.products = this.products.map(updateRow);
        this.filteredProducts = this.filteredProducts.map(updateRow);
        this.visibleProducts = this.visibleProducts.map(updateRow);
        this.selectedProducts = this.selectedProducts.map(updateRow);

        if (this.selectedRowsMap.has(rowId)) {
            this.selectedRowsMap.set(rowId, updateRow(this.selectedRowsMap.get(rowId)));
        }
    }
    handleFieldChange(event) {

        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.selectedProducts =
            this.selectedProducts.map(row => {

                if (row.Id === rowId) {

                    return {
                        ...row,
                        [field]: value
                    };
                }

                return row;
            });
    }
    handleDescriptionChange(event) {

        const rowId = event.target.dataset.id;
        const value = event.target.value;

        this.selectedProducts =
            this.selectedProducts.map(row => {

                if (row.Id === rowId) {

                    return {
                        ...row,
                        LineDescription__c: value
                    };
                }

                return row;
            });
    }
    handleSuggestionPrice(selectedRecord) {

        if (!Array.isArray(selectedRecord)) {
            console.log('selectedRecord is NOT an array');
            this.suggestionPriceList = [];
            return;
        }
        // Ensure selectedRecord is a string and split into unique, trimmed IDs
        if (!this.currentQuote.Account_Name__c) {
            return;
        }
        getQuoteLineItemLastCreated({ lineList: selectedRecord, accountId: this.currentQuote.Account_Name__c })
            .then(result => {
                console.log('result:', JSON.stringify(result));
                if (result.length > 0) {
                    this.suggestionPriceList = result;
                    this.modelClass = 'slds-col slds-large-size_9-of-12 slds-medium-size_9-of-12 slds-size_9-of-12';
                    // this.filteredList = result; // Uncomment when needed
                } else {
                    this.suggestionPriceList = [];
                }

            })
            .catch(error => {
                console.error('error:', JSON.stringify(error));
            });
    }


    handleNextStep() {
        this.selectedProducts = Array.from(this.selectedRowsMap.values());
        console.log('selectedProducts 1: -->' + JSON.stringify(this.selectedProducts));
        //this.showModal = true;
        this.showProductSelection = false;
        this.isNextVisible = false;
    }

    handleSaveDrafts(event) {
        try {
            const draftValues = event.detail.draftValues;

            // 1️⃣ Pehle edited values merge karo
            draftValues.forEach(updatedRow => {
                const index = this.selectedProducts.findIndex(
                    item => item.Id === updatedRow.Id
                );
                if (index !== -1) {
                    this.selectedProducts[index] = {
                        ...this.selectedProducts[index],
                        ...updatedRow
                    };
                }
            });

            // 2️⃣ Ab poore selectedProducts ko validate karo
            let hasErrors = false;
            let errorMessage = '';

            this.selectedProducts.forEach((row, index) => {
                if (!row.Quantity__c || row.Quantity__c <= 0) {
                    hasErrors = true;
                    errorMessage += `Row ${index + 1}: Quantity must be greater than 0. Please enter a valid quantity. `;
                }

                if (!row.SalesPrice__c || row.SalesPrice__c <= 0) {
                    hasErrors = true;
                    errorMessage += `Row ${index + 1}: Sales Price is required.\n`;
                }
            });

            if (hasErrors) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Validation Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
                return;
            }

            // 3️⃣ Success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Saved',
                    message: 'Changes updated successfully.',
                    variant: 'success'
                })
            );

        } catch (error) {
            console.error('Draft save error:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error'
                })
            );
        }
    }



    // handleSaveItems() {
    //     if (!this.selectedProducts.length) {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'No Products',
    //             message: 'Please select and update at least one product.',
    //             variant: 'warning'
    //         }));
    //         return;
    //     }

    //     console.log('Final Selected product to OppLIneItem---->', this.selectedProducts);
    //     // This is a Custom Opportunity record
    //     if (this.recordId?.startsWith('a01')) {
    //         createCustomLineItems({
    //             opportunityId: this.recordId,
    //             items: this.selectedProducts
    //         })
    //             .then(() => {
    //                 this.dispatchEvent(new ShowToastEvent({
    //                     title: 'Success',
    //                     message: ` Line Items created successfully.`,
    //                     variant: 'success'
    //                 }));
    //                 this.dispatchEvent(new CloseActionScreenEvent());
    //                 this.navigateToObjectHome();
    //                 this.showProductSelection = true;
    //                 this.selectedRowsMap.clear();
    //                 this.selectedProducts = [];
    //                 this.pageSelectedRowIds = [];

    //             })
    //             .catch(error => {
    //                 console.error('Apex Save Error:', error);
    //                 this.dispatchEvent(new ShowToastEvent({
    //                     title: 'Save Failed',
    //                     message: error.body?.message || 'Unknown error',
    //                     variant: 'error'
    //                 }));
    //             });

    //         // This is a Custom Quotation record
    //     } else if (this.recordId?.startsWith('a06')) {

    //         console.log('## in the else condition: ', this.recordId);
    //         createQuotationLineItems({
    //             quotationId: this.recordId,
    //             items: this.selectedProducts
    //         })
    //             .then(() => {
    //                 try {
    //                     this.dispatchEvent(new ShowToastEvent({
    //                         title: 'Success',
    //                         message: ` Line Items created successfully.`,
    //                         variant: 'success'
    //                     }));
    //                     this.dispatchEvent(new CloseActionScreenEvent());

    //                     //Wrap this in a try-catch to prevent unhandled error
    //                     try {
    //                         this.navigateToObjectHome();
    //                     } catch (navErr) {
    //                         console.error('Navigation Error:', navErr);
    //                     }

    //                     this.showProductSelection = true;
    //                     this.selectedRowsMap.clear();
    //                     this.selectedProducts = [];
    //                     this.pageSelectedRowIds = [];
    //                 } catch (e) {
    //                     console.error('Error in success handler:', e);
    //                 }
    //             })
    //             .catch(error => {
    //                 console.error('Apex Save Error.quotation....:', JSON.stringify(error));

    //                 let errorMessage = 'Unknown error';
    //                 if (error?.body?.message) {
    //                     errorMessage = error.body.message;
    //                 } else if (error?.message) {
    //                     errorMessage = error.message;
    //                 }

    //                 this.dispatchEvent(new ShowToastEvent({
    //                     title: 'Save Failed',
    //                     message: errorMessage,
    //                     variant: 'error'
    //                 }));
    //             });


    //     }

    // }
    handleSaveItems() {

        console.log('Button clicked');
        if (!this.selectedProducts.length) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No Products',
                message: 'Please select and update at least one product.',
                variant: 'warning'
            }));
            return;
        }
        this.selectedProducts = this.selectedProducts.map(row => ({
            ...row,
            List_Price__c: row.SalesPrice__c
        }));
        // ✅ SAME VALIDATION AS OPPORTUNITY
        let hasErrors = false;
        let errorMessage = '';

        this.selectedProducts.forEach((row, index) => {
            console.log('Validating row::::', JSON.stringify(row));
            if (!row.Quantity__c || row.Quantity__c <= 0) {
                console.log('quantity value::::', row.Quantity__c);
                hasErrors = true;
                errorMessage += `Row ${index + 1}: Quantity must be greater than 0. Please enter a valid quantity. `;
                console.log('Validation error in row::::', index + 1, 'Quantity__c:', row.Quantity__c);
            }
            if (!row.SalesPrice__c || row.SalesPrice__c <= 0) {

                console.log('sales price value::::', row.SalesPrice__c);
                hasErrors = true;
                errorMessage += `Row ${index + 1}: Sales Price is required. `;
                console.log('Validation error in row::::', index + 1, 'SalesPrice__c:', row.SalesPrice__c);
            }
            if (row.Discount__c > 100) {
                hasErrors = true;
                errorMessage += `Row ${index + 1}: Discount cannot be greater than 100%. `;
            }

            if (row.Discount__c < 0) {
                hasErrors = true;
                errorMessage += `Row ${index + 1}: Discount cannot be negative. `;
            }
        });

        if (hasErrors) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: errorMessage,
                variant: 'error'
            }));
            return;
        }

        // ✅ CLEAN DATA (IMPORTANT)
        const cleanData = JSON.parse(JSON.stringify(this.selectedProducts));

        console.log('Final Selected product---->', JSON.stringify(cleanData));

        // ✅ SAME STRUCTURE AS OPPORTUNITY
        if (this.recordId?.startsWith('a01')) {

            createCustomLineItems({
                opportunityId: this.recordId,
                items: cleanData
            })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Line Items created successfully.',
                        variant: 'success'
                    }));

                    this.dispatchEvent(new CloseActionScreenEvent());
                    console.log('1::');
                    this.navigateToObjectHome();
                    console.log('2::');

                    // RESET
                    this.showProductSelection = true;
                    console.log('3::');
                    this.selectedRowsMap.clear();
                    console.log('4::');
                    this.selectedProducts = [];
                    console.log('5::');
                    this.pageSelectedRowIds = [];
                    console.log('6::');

                })
                .catch(error => {
                    console.error('Apex Save Error:', error);

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Save Failed',
                        message: error.body?.message || 'Unknown error',
                        variant: 'error'
                    }));
                });

        } else if (this.recordId?.startsWith('a06')) {

            console.log('enter here In esle if');

            console.log('this.recordId' + this.recordId);
            console.log('cleanData' + JSON.stringify(cleanData));
            createQuotationLineItems({
                quotationId: this.recordId,
                items: cleanData
            })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Line Items created successfully.',
                        variant: 'success'
                    }));
                    console.log('Quotation Line Items created successfully.');
                    //this.dispatchEvent(new CloseActionScreenEvent());
                    //console.log('7::');
                    // setTimeout(() => {
                    //     this.dispatchEvent(new CloseActionScreenEvent());
                    //     this.navigateToObjectHome();
                    // }, 800);
                    setTimeout(() => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                        window.location.reload();
                    }, 800);
                    console.log('this.recordId--->' + this.recordId);
                    console.log('this.objectName--->' + this.objectName);
                    //this.navigateToObjectHome();
                    //console.log('8::');
                    // RESET
                    this.showProductSelection = true;
                    console.log('9::');
                    this.selectedRowsMap.clear();
                    console.log('10::');
                    this.selectedProducts = [];
                    console.log('11::');
                    this.pageSelectedRowIds = [];
                    console.log('12::');

                })
                .catch(error => {
                    console.error('Apex Save Error:', error);
                    if (error) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Save Failed',
                            message: error.body?.message || 'Unknown error',
                            variant: 'error'
                        }));
                    }
                });
        }
    }


    // handleCellChange(event) {
    //     const draftValues = event.detail.draftValues;
    //     console.log('handleCellChange draftValues 1: -->' + draftValues);

    //     draftValues.forEach(updatedRow => {
    //         const index = this.selectedProducts.findIndex(item => item.Id === updatedRow.Id);
    //         if (index !== -1) {
    //             this.selectedProducts[index] = { ...this.selectedProducts[index], ...updatedRow };
    //         }
    //     });
    //     console.log('handleCellChange draftValues 2: -->' + JSON.stringify(draftValues));
    // }
    handleCellChange(event) {
        const draftValues = event.detail.draftValues;

        console.log('Draft Values:', JSON.stringify(draftValues));

        let updatedProducts = [...this.selectedProducts];

        draftValues.forEach(draft => {
            const index = updatedProducts.findIndex(item => item.Id === draft.Id);
            if (index !== -1) {
                updatedProducts[index] = {
                    ...updatedProducts[index],
                    ...draft
                };
            }
        });

        this.selectedProducts = updatedProducts;


        this.template.querySelector('lightning-datatable').draftValues = [];
    }

    handleBack() {
        this.showProductSelection = true;
        this.isNextVisible =
            this.selectedRowIds.length > 0;

        this.enableFooter = true;
    }


    closeModal() {
        this.showModal = false;
    }

    navigateToObjectHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectName == 'Opportunity' ? 'Opportunity_Custom__c' : 'Quotation__c',
                actionName: 'view',
            },
        });
    }
    isStyleLoaded = false;

    // Use renderedCallback to ensure the component is in the DOM
    renderedCallback() {
        if (this.isStyleLoaded) return;
        this.isStyleLoaded = true;

        // 3. Load the CSS
        loadStyle(this, MY_STYLES)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles', error);
            });
    }
}