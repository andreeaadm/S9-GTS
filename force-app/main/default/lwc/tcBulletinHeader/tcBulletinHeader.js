import { LightningElement, api, wire } from "lwc";
import {
  getRecord,
  getFieldValue,
  getFieldDisplayValue
} from "lightning/uiRecordApi";
import SENT_DATE_FIELD from "@salesforce/schema/Bulletin__c.Sent_Date__c";
import SUBJECT_FIELD from "@salesforce/schema/Bulletin__c.Subject__c";
import SENT_FROM_FIELD from "@salesforce/schema/Bulletin__c.From__c";
import CREATED_BY_NAME_FIELD from "@salesforce/schema/Bulletin__c.CreatedBy.Name";
import { label } from "c/labelService";

export default class TcBulletinHeader extends LightningElement {
  @api recordId;
  labels = label;

  get headerSegments() {
    return this.wiredRecord.data
      ? [
          this.labels.SENT.charAt(0).toUpperCase() +
            this.labels.SENT.slice(1) +
            ": " +
            getFieldDisplayValue(this.wiredRecord.data, SENT_DATE_FIELD),
          getFieldValue(this.wiredRecord.data, SUBJECT_FIELD)
        ]
      : undefined;
  }

  get subHeaderSegments() {
    return this.wiredRecord.data
      ? [
          this.labels.FROM.charAt(0).toUpperCase() +
            this.labels.FROM.slice(1) +
            ": " +
            getFieldValue(this.wiredRecord.data, SENT_FROM_FIELD),
          getFieldValue(this.wiredRecord.data, CREATED_BY_NAME_FIELD)
        ]
      : undefined;
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      SENT_DATE_FIELD,
      SUBJECT_FIELD,
      SENT_FROM_FIELD,
      CREATED_BY_NAME_FIELD
    ]
  })
  wiredRecord;
}