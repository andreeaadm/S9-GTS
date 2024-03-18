import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { label } from "c/labelService";
import { subscribe, MessageContext } from "lightning/messageService";
import tcMessageChannel from "@salesforce/messageChannel/TCMessageChannel__c";
import { refreshApex } from "@salesforce/apex";

export default class TcViewInventory extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  labels = label;
  showLoader = true;
  inventoryRecord;
  recordData;

  //LIGHTNING MESSAGING SERVICE
  /*
   * allows all components on the view inventory page to communicate
   */
  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    subscribe(this.messageContext, tcMessageChannel, (message) =>
      this.handleMessage(message)
    );
  }

  handleMessage(message) {
    if (message.messageType === "refreshInventory") {
      refreshApex(this.recordData);
    }
  }

  //LIGHTNING DATA SERVICE
  /**
   * retireves the Inventory__c sObject from the server
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Inventory__c.Inventory_Name__c",
      "Inventory__c.Status__c",
      "Inventory__c.Type__c",
      "Inventory__c.Completed_Date__c",
      "Inventory__c.Submitted_Date__c",
      "Inventory__c.InCheck_Report_Status__c",
      "Inventory__c.InCheck_Report_Error_Message__c",
      "Inventory__c.InCheck_Report_Verification_Id__c",
      "Inventory__c.Facility__r.Name"
    ]
  })
  wiredRecord(response) {
    this.recordData = response;
    if (response.data) {
      this.inventoryRecord = response.data;
      this.showLoader = false;
    } else if (response.error) {
      console.error(response.error);
    }
  }

  //GETTERS & SETTERS
  /**
   * @returns true if the Inventory Status = 'Complete'
   */
  get isCompleted() {
    return (
      this.inventoryRecord &&
      this.inventoryRecord.fields.Status__c.value === "Complete"
    );
  }

  /**
   * @returns true if the Inventory Status = 'Submitted'
   */
  get isSubmitted() {
    return (
      this.inventoryRecord &&
      this.inventoryRecord.fields.Status__c.value === "Submitted"
    );
  }

  /**
   * @returns true if the Inventory Status = 'Submitted' && InCheck Report Status = 'Error'
   */
  get isSubmittedError() {
    return (
      this.inventoryRecord &&
      this.inventoryRecord.fields.Status__c.value === "Submitted" &&
      this.inventoryRecord.fields.InCheck_Report_Status__c.value != null &&
      this.inventoryRecord.fields.InCheck_Report_Status__c.value.toUpperCase() ===
        "ERROR"
    );
  }

  /**
   * @returns array of text to display in the header
   */
  get headerSegments() {
    return this.inventoryRecord
      ? [
          this.inventoryRecord.fields.Facility__r.displayValue,
          "Inventory " + this.inventoryRecord.fields.Inventory_Name__c.value,
          this.inventoryRecord.fields.Type__c.displayValue
        ]
      : null;
  }
}