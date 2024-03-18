import { LightningElement } from "lwc";
import { label } from "c/labelService";

export default class TcAddProductHeader extends LightningElement {
  //TEMPLATE PROPERTIES
  headerFields = ["Inventory_Name__c", "Type__c"];
  inventoryRecordId;
  inventoryRecord;
  labels = label;

  //GETTERS & SETTERS
  /**
   * @returns array containing the different segments within the header
   */
  get headerSegments() {
    return [
      this.labels.TC_ADD_PRODUCTS_TO_INVENTORY_HEADER +
        " " +
        this.inventoryRecord?.fields?.Inventory_Name__c?.value,
      this.inventoryRecord?.fields?.Type__c?.displayValue
    ];
  }

  //EVENT HANDLERS
  /**
   * handles the page reference cmp retrieving the page state (record Id)
   * @param {object} event retrievedstate custom event
   */
  handleRetrievedState(event) {
    this.inventoryRecordId = event.detail.recordId;
  }
  /**
   * handles the page reference cmp retrieving the record data needed to display the header
   * @param {object} event - retrievedrecord custom event
   */
  handleRetrievedRecord(event) {
    this._processRetrievedRecord(event.detail);
  }

  //INTERNAL FUNCTIONS
  /**
   * sets the cmp properties to display the header in the template
   * @param {object} record - Inventory__c sObject retrieved from the page reference cmp
   */
  _processRetrievedRecord(record) {
    if (record?.fields) {
      this.inventoryRecord = record;
    }
  }
}