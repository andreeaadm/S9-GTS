import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { label } from "c/labelService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Brand_Working_with_Parent from "@salesforce/schema/Inventory__c.Facility__r.Parent.Brand_Working_With__c";
import Brand_Working_with_Child from "@salesforce/schema/Inventory__c.Facility__r.Brand_Working_With__c";
import { subscribe, MessageContext } from "lightning/messageService";
import tcMessageChannel from "@salesforce/messageChannel/TCMessageChannel__c";
import { refreshApex } from "@salesforce/apex";

export default class TcViewInventoryActions extends NavigationMixin(
  LightningElement
) {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  inventoryRecord;
  labels = label;
  submitIsDisabled = false;
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

  async handleMessage(message) {
    if (message.messageType === "refreshInventory") {
      await refreshApex(this.recordData);
      this.submitIsDisabled = false;
    }
  }

  //LIGHTNING DATA SERVICE
  /**
   * retireves the Inventory__c sObject from the server
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      "Inventory__c.Status__c",
      "Inventory__c.InCheck_Report_Verification_Id__c",
      Brand_Working_with_Parent,
      Brand_Working_with_Child
    ]
  })
  wiredRecord(response) {
    this.recordData = response;
    if (response.data) {
      this.inventoryRecord = response.data;
    } else if (response.error) {
      console.error(response.error);
    }
  }

  //GETTERS & SETTERS
  /**
   * @returns true if the Inventory Status = 'Pending'
   */
  get isPending() {
    return this.inventoryRecord?.fields.Status__c.value === "Pending";
  }

  /**
   * @returns true if the Inventory Status = 'Complete'
   */
  get isComplete() {
    return this.inventoryRecord?.fields.Status__c.value === "Complete";
  }

  get showVOCReport(){
    return this.inventoryRecord?.fields.Facility__r.value.fields.Parent.value.fields.Brand_Working_With__c.value === 'Nike' || this.inventoryRecord?.fields.Facility__r.value.fields.Brand_Working_With__c.value === 'Nike' ;
  }

  get showInCheckReportButton() {
    return (
      this.inventoryRecord?.fields.Status__c.value === "Submitted" &&
      this.inventoryRecord?.fields.InCheck_Report_Verification_Id__c.value !==
        null
    );
  }

  //EVENT HANDLERS
  /**
   * handles the user clicking to add a product to the Inventory
   */
  handleAddProducts() {
    this._navigateToAddProducts();
  }

  /**
   * handles the user clicking to 'complete' the inventory
   */
  handleMarkComplete() {
    this._processMarkComplete();
  }

  /**
   * handles the user clicking to revert the the inventory back to 'pending'
   */
  handleRevertToPending() {
    this._processRevertToPending();
  }

  //INTERNAL FUNCTIONS
  /**
   * processes the record updates for completing the inventory
   */
  _processMarkComplete() {
    const recordInput = {
      fields: {
        Id: this.recordId,
        Status__c: "Complete",
        Completed_Date__c: new Date().toISOString()
      }
    };
    this._processRecordUpdate(
      recordInput,
      this.labels.TC_MARK_COMPLETE_SUCCESS
    );
  }

  /**
   * processes the record updates for reverting back to pending
   */
  _processRevertToPending() {
    const recordInput = {
      fields: {
        Id: this.recordId,
        Status__c: "Pending"
      }
    };
    this._processRecordUpdate(
      recordInput,
      this.labels.TC_REVERT_TO_PENDING_SUCCESS
    );
  }

  /**
   *
   * @param {object} recordInput - object containing Inventory__c data back to the database
   * @param {*} successMessage - message to display on a successful update
   */
  _processRecordUpdate(recordInput, successMessage) {
    updateRecord(recordInput)
      .then(() => {
        this._showToastNotification(
          this.labels.SUCCESS,
          successMessage,
          "success"
        );
      })
      .catch((error) => {
        console.error(error);
        this._showToastNotification(
          this.labels.ERROR,
          this.labels.TC_UPDATING_INVENTORY_ERROR,
          "error"
        );
      });
  }

  /**
   * navigates the user to the Add Products standard page
   */
  _navigateToAddProducts() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Add_Products__c"
      },
      state: {
        recordId: this.recordId
      }
    });
  }

  /**
   * displays a toast notification to the user
   * @param {string} title - title for the notification
   * @param {string} message - core message of the notification
   * @param {string} variant - type of message shown (success / info / warning / error)
   */
  _showToastNotification(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  handleDownloadClick() {
    this.template
      .querySelector("c-tc-download-inventory")
      .handleDownload(this.recordId);
  }

  handleDownloadInventoryForBrand(){
    this.template
      .querySelector("c-tc-brand-download-inventory")
      .handleDownload(this.recordId);
  }

  handleSubmit() {
    this.submitIsDisabled = true;
    this.template
      .querySelector("c-zdhc-post-in-check-report")
      .doSubmitInventoryCallout(this.recordId);
  }

  handleViewInCheckReport() {
    this.template
      .querySelector("c-zdhc-get-in-check-report")
      .getInCheckReport(this.recordId);
  }
}