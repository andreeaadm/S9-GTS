import { LightningElement, api, wire, track } from "lwc";
import { getRecord } from "lightning/uiRecordApi";

export default class TcViewInventoryBack extends LightningElement {
  @track backToLibraryLabel = 'Back to Chemical Library';
  @track isBackToLibrary = false;

  onButtonClick(event) {
  const buttonlabel = event.detail.label;
  if(buttonlabel) {
    //custom event
  const passBackToLibraryEvent = new CustomEvent('backtolibrary', {
    detail:{isBackToLibrary:this.isBackToLibrary} 
    });
    this.dispatchEvent(passBackToLibraryEvent);
  }
  }
  
}