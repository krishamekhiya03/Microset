import { LightningElement, wire, api, track } from 'lwc';
import createCustomLineItems from '@salesforce/apex/CustomProductFetcher.createCustomLineItems';
import createQuotationLineItems from '@salesforce/apex/CustomProductFetcher.createQuotationLineItems';
import fetchActiveProduct from '@salesforce/apex/CustomProductFetcher.fetchActiveProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import MY_STYLES from '@salesforce/resourceUrl/modelcss';
import { RefreshEvent } from 'lightning/refresh';
import OPP_CURRENCY_FIELD from '@salesforce/schema/Opportunity_Custom__c.CurrencyIsoCode';
const colum = [
    { label: 'Product Code', fieldName: 'Name' },
    // { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Product Name', fieldName: 'Product_Name__c' },
    {
        label: 'List Price',
        fieldName: 'List_Price__c',
        type: 'currency',
        cellAttributes: { alignment: 'left' }
    }
];

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
];

const PAGE_SIZE = 10;

export default class AddProductToOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    @track products = [];
    columns = colum;
    oppoLineCol = oppoLineItemCol;
    currencyOptions = [
        { label: 'INR - Indian Rupee', value: 'INR' },
        { label: 'USD - US Dollar', value: 'USD' }
    ];
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

    buttonLabel = '';
    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecord({ error, data }) {
        if (data) {
            this.objectApiName = data.apiName;
            console.log('Object API Name:', this.objectApiName);
            this.opportunityCurrency = getFieldValue(data, OPP_CURRENCY_FIELD) || 'INR';
            console.log('Opportunity Currency:', this.opportunityCurrency);

            if (this.objectApiName === 'Opportunity_Custom__c') {

                this.buttonLabel = 'Save to Opportunity';
            } else if (this.objectApiName === 'Quotation__c') {

                this.buttonLabel = 'Save to Quotation';
            }
            this.applyOpportunityCurrency();
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }
    applyOpportunityCurrency() {
        if (!this.products.length) return;

        const currency = this.opportunityCurrency;

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

    handleEditDescription(event) {

        const rowId = event.currentTarget.dataset.id;

        this.visibleProducts = this.visibleProducts.map(row => {

            return {
                ...row,
                isEditing: row.Id === rowId
            };
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

    connectedCallback() {
        console.log('connectedCallback--->');
        if (this.pageRef && this.pageRef.state && this.pageRef.state.recordId) {
            this.recordId = this.pageRef.state.recordId;
        }
        console.log('this.recordId--->' + this.recordId);
        this.isLoading = true;


        fetchActiveProduct()
            .then(result => {
                if (!result || result.length === 0) {
                    console.warn('No Products Found');
                }
                console.log('result::' + JSON.stringify(result));
                this.products = result.map(item => ({
                    Id: item.Id,
                    Product__c: item.Id,
                    ProductCode: item.HSN_Code__c,
                    ModelNumber: item.Model_Numbers__c,
                    Name: item.Name,
                    ProductName: item.Product_Name__c,
                    HSN_Code__c: item.HSN_Code__c,
                    Product_Name__c: item.Product_Name__c,
                    List_Price__c: item.List_Price__c,
                    List_Price_USD__c: item.List_Price_USD__c,
                    GST__c: item.GST__c,
                    Quantity__c: 1,
                    CurrencyIsoCode: this.opportunityCurrency,   // ★ CHANGED: hardcoded 'INR' ke jagah
                    SalesPrice__c: this.opportunityCurrency === 'USD'
                        ? (item.List_Price_USD__c || 0)
                        : (item.List_Price__c || 0),             // ★ CHANGED
                    Discount__c: 0,
                    LineDescription__c: item.Product_Description__c
                }));

                console.log('this.products ::' + JSON.stringify(this.products));
                this.filteredProducts = this.products;
                this.updatePagination();
                this.isLoading = false;
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
            (item.Product_Name__c && item.Product_Name__c.toLowerCase().includes(this.searchKey)) ||
            (item.HSN_Code__c && item.HSN_Code__c.toLowerCase().includes(this.searchKey)) ||
            (item.ModelNumber && item.ModelNumber.toLowerCase().includes(this.searchKey))
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

    handleRowSelection(event) {
        const newlySelectedRows = event.detail.selectedRows;
        console.log('newlySelectedRows 1: -->' + newlySelectedRows);

        newlySelectedRows.forEach(row => {
            this.selectedRowsMap.set(row.Id, row);
        });
        console.log('newlySelectedRows 2: -->' + newlySelectedRows);

        const currentPageIds = this.visibleProducts.map(row => row.Id);
        const selectedIdsOnPage = new Set(newlySelectedRows.map(row => row.Id));
        console.log('currentPageIds 1: -->' + currentPageIds);

        currentPageIds.forEach(id => {
            if (!selectedIdsOnPage.has(id)) {
                this.selectedRowsMap.delete(id);
            }
        });
        console.log('currentPageIds 2: -->' + currentPageIds);

        this.selectedRowIds = Array.from(this.selectedRowsMap.keys());
        console.log('selectedRowIds 1: -->' + this.selectedRowIds);

        this.pageSelectedRowIds = this.visibleProducts
            .map(row => row.Id)
            .filter(id => this.selectedRowsMap.has(id));
        console.log('pageSelectedRowIds 1: -->' + this.pageSelectedRowIds);

        this.enableFooter = true;
        this.isNextVisible = this.selectedRowIds.length > 0;
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

        this.pageSelectedRowIds = Array.from(this.selectedRowsMap.keys());

        this.selectedRowIds = Array.from(this.selectedRowsMap.keys());

        this.visibleProducts = this.visibleProducts.map(row => ({
            ...row,
            isSelected: this.selectedRowsMap.has(row.Id)
        }));

        this.enableFooter = true;
        this.isNextVisible = this.selectedRowIds.length > 0;
    }

    handleNextStep() {
        this.selectedProducts = Array.from(this.selectedRowsMap.values());
        console.log('selectedProducts 1: -->' + JSON.stringify(this.selectedProducts));
        this.showProductSelection = false;
        this.isNextVisible = false;
    }

    /*handleCellChange(event) {
        const draftValues = event.detail.draftValues;
        console.log('handleCellChange draftValues 1: -->' + draftValues);

        draftValues.forEach(updatedRow => {
            const index = this.selectedProducts.findIndex(item => item.Id === updatedRow.Id);
            if (index !== -1) {
                this.selectedProducts[index] = { ...this.selectedProducts[index], ...updatedRow };
            }
        });
        console.log('handleCellChange draftValues 2: -->' + draftValues);
    }*/
    // handleCellChange(event) {
    //     const draftValues = event.detail.draftValues;

    //     console.log('Draft Values:', JSON.stringify(draftValues));

    //     let updatedProducts = [...this.selectedProducts];

    //     draftValues.forEach(draft => {
    //         const index = updatedProducts.findIndex(item => item.Id === draft.Id);
    //         if (index !== -1) {
    //             updatedProducts[index] = {
    //                 ...updatedProducts[index],
    //                 ...draft
    //             };
    //         }
    //     });

    //     this.selectedProducts = updatedProducts;


    //     this.template.querySelector('lightning-datatable').draftValues = [];
    // }
    handleFieldChange(event) {

        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.selectedProducts = this.selectedProducts.map(row => {

            if (row.Id === rowId) {

                return {
                    ...row,
                    [field]: value
                };
            }

            return row;
        });
        console.log(
            'Final Selected product --->',
            JSON.stringify(this.selectedProducts)
        );
    }


    handleSaveItems() {
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
        // Validate all rows before saving
        let hasErrors = false;
        let errorMessage = '';

        this.selectedProducts.forEach((row, index) => {
            // if (row.LineDescription__c) {
            //     row.LineDescription__c = row.LineDescription__c
            //         // ?.replace(/<br\s*\/?>/gi, '\n')
            //         // ?.replace(/<\/p>/gi, '\n')
            //         // ?.replace(/<li>/gi, '• ')
            //         // ?.replace(/<\/li>/gi, '\n')
            //         // ?.replace(/<[^>]*>/g, '')
            //         ?.replace(/•\s(.*?)(\n|$)/g, '<li>$1</li>')
            //         ?.trim()
            //         // Convert new line to <br/>
            //         ?.replace(/\n/g, '<br/>');
            //     console.log('Formatted Line Description:::>', row.LineDescription__c);

            // }
            if (!row.Quantity__c || row.Quantity__c <= 0) {
                hasErrors = true;
                errorMessage += `Row ${index + 1}: Quantity must be greater than 0. Please enter a valid quantity. `;
            }
            if (!row.SalesPrice__c || row.SalesPrice__c <= 0) {
                hasErrors = true;
                errorMessage += `Row ${index + 1}: List Price is required. `;
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

        console.log('Final Selected product to OppLineItem---->', JSON.stringify(this.selectedProducts));
        const cleanData = JSON.parse(JSON.stringify(this.selectedProducts));
        console.log('Sending Data to Apex:', JSON.stringify(cleanData));

        // Custom Opportunity record
        if (this.objectApiName === 'Opportunity_Custom__c') {
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
                    // this.dispatchEvent(new RefreshEvent());
                    setTimeout(() => {
                        window.location.reload();
                    }, 500);
                    this.showProductSelection = true;
                    this.selectedRowsMap.clear();
                    this.selectedProducts = [];
                    this.pageSelectedRowIds = [];
                    this.updatePagination();
                })
                .catch(error => {
                    console.error('Apex Save Error:', error);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Save Failed',
                        message: error.body?.message || 'Unknown error',
                        variant: 'error'
                    }));
                });

            // Custom Quotation record
        } else if (this.objectApiName === 'Quotation__c') {
            createQuotationLineItems({
                quotationId: this.recordId,
                items: this.selectedProducts
            })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Line Items created successfully.',
                        variant: 'success'
                    }));
                    // this.dispatchEvent(new CloseActionScreenEvent());
                    // this.navigateToObjectHome();
                    this.dispatchEvent(new CloseActionScreenEvent());
                    // this.dispatchEvent(new RefreshEvent());
                    setTimeout(() => {
                        window.location.reload();
                    }, 500);
                    this.showProductSelection = true;
                    this.selectedRowsMap.clear();
                    this.selectedProducts = [];
                    this.pageSelectedRowIds = [];
                    this.updatePagination();
                })
                .catch(error => {
                    console.error('Apex Save Error:', error);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Save Failed',
                        message: error.body?.message || 'Unknown error',
                        variant: 'error'
                    }));
                });
        }
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
                objectApiName: this.objectApiName,
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