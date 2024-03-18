import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/MTC_Project__c.Name";

export default class ProjectDetail extends LightningElement {
  @api recordId;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: NAME_FIELD
  })
  project;

  get name() {
    return getFieldValue(this.project.data, NAME_FIELD);
  }
}