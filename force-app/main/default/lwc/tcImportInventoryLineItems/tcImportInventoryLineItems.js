import { LightningElement, api, track } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
import importLineItems from "@salesforce/apex/TC_ImportInventoryLineItemsController.importLineItems";

export default class TcImportInventoryLineItems extends LightningElement {
  @api recordId;
  disableImport = true;
  isWorking = false;
  errors;
  labels = label;
  importLineItems = importLineItems;

  handleFileChange() {
    this.disableImport = false;
  }
  doImport() {
    this.disableImport = true;
    this.isWorking = true;
    this.template.querySelector("c-csv-import").doImport();
  }
  handleImportSuccess(evt) {
    this.closeAction();
  }
  handleImportError(evt) {
    this.isWorking = false;
  }
  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
  showNotification(title, message, variant, mode) {
    if (!this.disableToasts) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: title,
          message: message,
          variant: variant ? variant : "error",
          mode: mode ? mode : "sticky"
        })
      );
    }
  }
}