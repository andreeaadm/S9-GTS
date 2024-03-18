import { LightningElement, api, track, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { label } from "c/labelService";

export default class Record extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api recordTypeLabel;
  @api titleFieldApiName;
  @api editableFieldApiNames;
  @api editableFieldLabels;
  @api requiredFieldApiNames;
  @api viewColumns = 2;
  @api viewDensity = "comfy";
  // selectOptionsOverride accepts a map from field API name to a list of select options in the usual { label: "label", value: "value" } format.
  // e.g. {Origin: [{ label: "labelA", value: "valueA" }, { label: "labelB", value: "valueB" }]}
  @api selectOptionsOverride;
  @track isWorking = false;
  @track editMode = false;
  @track getRecordFields = [];
  recordObject;
  labels = label;

  get showHeader() {
    return this.title || this.isUpdateable;
  }

  // is updateable when the object is updateable, and permissions allow
  // at least one of the editable fields to be updatable.
  get isUpdateable() {
    return (
      this.recordObject?.data?.updateable &&
      (this.editableFieldApiNames?.includes(",")
        ? this.editableFieldApiNames.split(",")
        : this.editableFieldApiNames?.length > 0
        ? [this.editableFieldApiNames]
        : undefined
      )?.find((field) => this.recordObject?.data?.fields[field]?.updateable)
    );
  }

  connectedCallback() {
    this.getRecordFields.push(
      this.objectApiName + "." + this.titleFieldApiName
    );
  }

  @wire(getObjectInfo, { objectApiName: "$objectApiName" })
  wiredRecordObject(response) {
    if (response.data) {
      this.recordObject = response;
    }
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: "$getRecordFields"
  })
  record;

  get title() {
    return this.record?.data?.fields[this.titleFieldApiName]?.value;
  }

  toggleEdit() {
    this.editMode = !this.editMode;
  }

  save() {
    this.isWorking = true;
    this.template.querySelector("c-form").save();
  }

  handleSuccess() {
    this.isWorking = false;
    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.SUCCESS,
        message: this.labels.CHANGES_SAVED,
        variant: "success"
      })
    );
    this.toggleEdit();
  }

  handleError(evt) {
    this.isWorking = false;
    if (evt.detail.message != "Validation failed") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: evt.detail.message,
          variant: "error"
        })
      );
    }
  }

  handleCancel() {
    this.toggleEdit();
  }

  reset() {
    this.template.querySelector("c-form").reset();
  }
}