import { LightningElement, wire, api, track } from "lwc";
import { getRecord, updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { label } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import BULLETIN_FIELD from "@salesforce/schema/User.Bulletin_Notifications__c";
import INVENTORY_FIELD from "@salesforce/schema/User.Inventory_Report_Reminder_Notifications__c";
import CONNECTION_FIELD from "@salesforce/schema/User.Connection_Request_Notifications__c";
import SUPPLIER_FIELD from "@salesforce/schema/User.Supplier_Conformance_Notifications__c";

export default class OtherEmails extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;
  @track userDetailRecord;

  //TEMPLATE PROPERTIES
  labels = label;
  wireBackup;

  get bulletinValue() {
    return getFieldValue(this.userDetailRecord, BULLETIN_FIELD);
  }

  get inventoryValue() {
    return getFieldValue(this.userDetailRecord, INVENTORY_FIELD);
  }

  get connectionValue() {
    return getFieldValue(this.userDetailRecord, CONNECTION_FIELD);
  }

  get supplierValue() {
    return getFieldValue(this.userDetailRecord, SUPPLIER_FIELD);
  }

  //DATA-FETCHING FUNCTIONS

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [BULLETIN_FIELD, INVENTORY_FIELD, CONNECTION_FIELD],
    optionalFields: [SUPPLIER_FIELD]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.userDetailRecord = data;
      this.wireBackup = data;
    } else if (error) {
      this.userDetailRecord = undefined;
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.labels.ERROR,
          message: this.labels.TC_EMAIL_SETTINGS_ERROR_MESSAGE,
          variant: "error"
        })
      );
    }
  }

  //EVENT HANDLERS

  revertChanges() {
    let checkboxes = this.template.querySelectorAll("c-input");
    checkboxes[0].value = getFieldValue(this.wireBackup, BULLETIN_FIELD);
    checkboxes[1].value = getFieldValue(this.wireBackup, INVENTORY_FIELD);
    checkboxes[2].value = getFieldValue(this.wireBackup, CONNECTION_FIELD);
    if (checkboxes.length > 3) {
      checkboxes[3].value = getFieldValue(this.wireBackup, SUPPLIER_FIELD);
    }
    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.CANCEL,
        message: this.labels.TC_NO_CHANGES,
        variant: "success"
      })
    );
  }

  updateUserRecord() {
    const fields = { Id: this.recordId };
    for (let input of this.template.querySelectorAll("c-input")) {
      if (input.fieldId) {
        fields[input.fieldId] = input.value;
      }
    }

    let recordInput = { fields };
    updateRecord(recordInput);

    this.dispatchEvent(
      new ShowToastEvent({
        title: this.labels.SUCCESS,
        message: this.labels.TC_SAVED_SETTINGS,
        variant: "success"
      })
    );
  }
}