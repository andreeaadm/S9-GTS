import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { label } from "c/labelService";

export default class TcViewInventoryBack extends LightningElement {
  @api recordId;

  labels = label;
  facilityId;
  facilityName;
  baseUrl = "/inventory/Inventory__c/Default?";

  get destinationUrl() {
    if (this.facilityId && this.facilityName) {
      return this.baseUrl.concat(
        "facilityId=",
        this.facilityId,
        "&facilityName=",
        encodeURIComponent(this.facilityName)
      );
    }
    return null;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: ["Inventory__c.Facility__c", "Inventory__c.Facility_Name__c"]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.facilityId = data.fields.Facility__c?.value;
      this.facilityName = data.fields.Facility_Name__c?.value;
    }
  }
}