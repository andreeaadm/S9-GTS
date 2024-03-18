import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import REQUESTOR_NAME_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Requestor_Contact__r.Name";

export default class TcConnectionDetailsHeader extends LightningElement {
  @api recordId;

  requestorName;

  @wire(getRecord, { recordId: "$recordId", fields: REQUESTOR_NAME_FIELD })
  processResponse(response) {
    if (response && response.data) {
      this.requestorName =
        response.data?.fields?.Requestor_Contact__r?.value?.fields?.Name?.value;
    }
  }

  get headerText() {
    return (
      "Connection request from " +
      (this.requestorName ? this.requestorName : "")
    );
  }
}