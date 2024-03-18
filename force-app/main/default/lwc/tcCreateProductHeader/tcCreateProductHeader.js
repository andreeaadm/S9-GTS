import { LightningElement } from "lwc";
import { label } from "c/labelService";

export default class TcCreateProductHeader extends LightningElement {
  //TEMPLATE PROPERTIES
  labels = label;
  inventoryRecordId;

  //GETTERS & SETTERS
  /**
   * @returns the text to display in the page header
   */
  get headerText() {
    return this.labels.TC_CREATE_PRODUCT_HEADER;
  }

  //EVENT HANDLERS
  /**
   * handles the page url params being parsed from the page reference data cmp
   * @param {object} event retrievedstate custom event
   */
  handleRetrievedState(event) {
    this.inventoryRecordId = event.detail.inventoryId;
  }
}