import { LightningElement, api, track, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getLineItemsForInventory from "@salesforce/apex/TC_InventoryLineItems.getLineItemsForInventory";
import { label } from "c/labelService";

export default class TcViewInventoryLineItems extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  @track lineItemData;
  labels = label;
  loadingMoreLineItems;
  allLineItemsShown;
  noLineItems;
  hasLoaded = false;

  //INTERNAL PROPERTIES
  _recordCount = 50;
  _offset = 0;
  _inventoryRecord;

  //LIGHTNING DATA SERVICE
  /**
   * retireves the Inventory__c sObject from the server
   */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: ["Inventory__c.Type__c"]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this._inventoryRecord = data;
      if (!this.lineItemData) {
        this._getLineItems();
      }
    } else if (error) {
      console.error(error);
    }
  }

  //EVENT HANDLERS
  /**
   * handles the user requesting more records
   */
  handleViewMore() {
    this._processViewMore();
  }

  //INTERNAL FUNCTIONS
  /**
   * processes the user's request for more records
   */
  _processViewMore() {
    this._offset = this.lineItemData.rows.length;
    this.loadingMoreLineItems = true;
    this._getLineItems();
  }

  /**
   * retrieves inventory line items for the server for displaying in the datatable
   */
  _getLineItems() {
    getLineItemsForInventory({
      inventoryId: this.recordId,
      recordCount: this._recordCount,
      offset: this._offset,
      type: this._inventoryRecord.fields.Type__c.value
    })
      .then((result) => {
        this._processLineItemsResponse(result);
      })
      .catch((error) => {
        console.error(error);
      });
  }

  /**
   * processes the line item response from the server
   * @param {object} result - object containing line item data structured for c-datatable
   */
  _processLineItemsResponse(result) {
    if (result) {
      if (this.lineItemData && this.lineItemData.rows) {
        this.lineItemData.rows.push(...result.table.rows);
      } else {
        this.lineItemData = result.table;
      }
      this.allLineItemsShown = result.table.rows.length < this._recordCount;
    } else if (!result && this.lineItemData) {
      this.allLineItemsShown = true;
    } else {
      this.noLineItems = true;
    }
    this.showLoader = this.loadingMoreLineItems = false;
    this.hasLoaded = true;
  }
}