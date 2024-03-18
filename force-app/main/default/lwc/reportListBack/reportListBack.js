import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import assetExpiryBanner from "@salesforce/apex/AssetExpiryBannerController.assetExpirystatus";

export default class TcViewInventoryBack extends LightningElement {
  @track backToReportListLabel = 'Back to Reports';
  @track isBackToReport = false;
  @api booleanExpiry; 
  @api recordId;

  onButtonClick(event) {
  const buttonlabel = event.detail.label;
  if(buttonlabel) {
    //custom event
  const passBackToReportListevent = new CustomEvent('backtoreportlist', {
    detail:{isBackToReportList:this.isBackToReport} 
    });
    this.dispatchEvent(passBackToReportListevent);
  }
  }

  @wire(assetExpiryBanner, { recordId: "$recordId"})
  wiredExpiryStatus({ error, data }) {
    if (data) {
      this.booleanExpiry = data;
    }
  }
  
}