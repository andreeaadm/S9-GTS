import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import {
  getRecord,
  updateRecord,
  getRecordNotifyChange
} from "lightning/uiRecordApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import ID_FIELD from "@salesforce/schema/Case.Id";
import STATUS_FIELD from "@salesforce/schema/Case.Status";
import ISCLOSED_FIELD from "@salesforce/schema/Case.IsClosed";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";
const CLOSED_STATUS = "Closed";
const REOPEN_STATUS = "New";
export default class CloseReopenCase extends LightningElement {
  @api recordId;
  get isUpdateable() {
    return this.caseObject?.data?.updateable;
  }
  get isClosed() {
    return this.caseRecord?.data?.fields[ISCLOSED_FIELD.fieldApiName].value;
  }
  labels = label;

  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  caseObject;

  @wire(getRecord, { recordId: "$recordId", fields: ISCLOSED_FIELD })
  caseRecord;

  handleClose() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = CLOSED_STATUS;
    const recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.CASE_CLOSED,
            variant: "success"
          })
        );
        getRecordNotifyChange([{ recordId: this.recordId }]);
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: "Action failed: " + error.body.message,
            variant: "error"
          })
        );
      });
  }

  handleReopen() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = REOPEN_STATUS;
    const recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.SUCCESS,
            message: this.labels.CASE_REOPENED,
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: this.labels.ERROR,
            message: "Action failed: " + error.body.message,
            variant: "error"
          })
        );
      });
  }
}