import { LightningElement, api } from "lwc";
import deleteFile
  from '@salesforce/apex/PreviewFileThumbnailCardController.deleteFile';

export default class PreviewFileThumbnailCard extends LightningElement {
  @api file;
  @api recordId;
  @api thumbnail;

  get iconName() {
    if (this.file.Extension) {
      if (this.file.Extension === "pdf") {
        return "doctype:pdf";
      }
      if (this.file.Extension === "ppt") {
        return "doctype:ppt";
      }
      if (this.file.Extension === "xls") {
        return "doctype:excel";
      }
      if (this.file.Extension === "csv") {
        return "doctype:csv";
      }
      if (this.file.Extension === "txt") {
        return "doctype:txt";
      }
      if (this.file.Extension === "xml") {
        return "doctype:xml";
      }
      if (this.file.Extension === "doc") {
        return "doctype:word";
      }
      if (this.file.Extension === "zip") {
        return "doctype:zip";
      }
      if (this.file.Extension === "rtf") {
        return "doctype:rtf";
      }
      if (this.file.Extension === "psd") {
        return "doctype:psd";
      }
      if (this.file.Extension === "html") {
        return "doctype:html";
      }
      if (this.file.Extension === "gdoc") {
        return "doctype:gdoc";
      }
    }
    return "doctype:image";
  }

  filePreview() {
    console.log("###Click");
    const showPreview = this.template.querySelector("c-preview-file-modal");
    showPreview.show();
  }
  handleDelete(event) {

    event.stopPropagation();

    console.log(
      'FILE => ',
      JSON.stringify(this.file)
    );

    const documentId =
      this.file.ContentDocumentId ||
      this.file.Id;

    if (!documentId) {

      console.error(
        'ContentDocumentId not found'
      );

      return;
    }

    deleteFile({

      contentDocumentId: documentId,
      recordId: this.recordId

    })
      .then(() => {

        console.log('Deleted Successfully');
        this.dispatchEvent(

          new CustomEvent('refresh', {

            bubbles: true,
            composed: true

          })

        );
      })
      .catch(error => {

        console.error(
          'DELETE ERROR => ',
          JSON.stringify(error)
        );
      });
  }
}