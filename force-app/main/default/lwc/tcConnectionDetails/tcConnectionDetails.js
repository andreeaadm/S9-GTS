import { LightningElement, api, wire } from "lwc";
import { getRecord, updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ID_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Id";
import STATUS_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Status__c";
import CONFORMANCE_FIELD from "@salesforce/schema/Brand_Supplier_Connection__c.Supplier_Conformance_Target__c";
import TcExperienceCloud from "c/tcExperienceCloud";
import { label } from "c/labelService";

export default class TcConnectionDetails extends LightningElement {
  @api recordId;
  labels = label;
  context;
  editConformanceTarget = false;
  disableBtn = false;
  conformanceRegex = /^\d{0,3}(\.\d{1,2})?$/;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [ID_FIELD, STATUS_FIELD, CONFORMANCE_FIELD]
  })
  wiredRecord;

  constructor() {
    super();
    this.context = new TcExperienceCloud();
  }

  get isSupplier() {
    return this.context.isSupplierUser;
  }

  get isBrand() {
    return this.context.isBrandUser;
  }

  get isStatusRequested() {
    return getFieldValue(this.wiredRecord.data, STATUS_FIELD) === "Requested";
  }

  get isStatusApproved() {
    return getFieldValue(this.wiredRecord.data, STATUS_FIELD) === "Approved";
  }

  get isStatusRejected() {
    return getFieldValue(this.wiredRecord.data, STATUS_FIELD) === "Rejected";
  }

  handleUpdateConformance() {
    // make conformance field editable, display buttons etc
    this.editConformanceTarget = true;
  }

  handleSaveConformance() {
    let input = this.template.querySelector(
      "c-input[data-id='Supplier_Conformance_Target__c']"
    );
    if (input.validate().isValid) {
      this.disableBtn = true;
      let fields = {};
      let recordInput = {};
      fields[ID_FIELD.fieldApiName] = this.recordId;
      fields[CONFORMANCE_FIELD.fieldApiName] = parseFloat(input.value);
      recordInput = { fields };
      updateRecord(recordInput)
        .then(() => {
          this.editConformanceTarget = false;
          this.disableBtn = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.SUCCESS,
              message: this.labels.UPDATE_CONFORMANCE_SUCCESS,
              variant: "success"
            })
          );
        })
        .catch((error) => {
          this.disableBtn = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.labels.ERROR,
              message: error.body.message,
              variant: "error"
            })
          );
        });
    }
  }

  handleCancelConformance() {
    this.editConformanceTarget = false;
  }
}