import { LightningElement, api } from 'lwc';

export default class orderPdfButton extends LightningElement {

    @api recordId;

    renderedCallback() {

        const modal = this.template.host.closest('.slds-modal__container');

        if(modal){

            modal.style.width = '80vw';
            modal.style.maxWidth = '80vw';
            modal.style.height = '90vh';
        }
    }

    get vfUrl() {

        return '/apex/QuotationPDF?id=' + this.recordId + '#toolbar=1&navpanes=0';
    }
}