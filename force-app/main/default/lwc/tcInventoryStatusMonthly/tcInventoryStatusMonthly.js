import { LightningElement, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getRecordsForInventoryStatus from "@salesforce/apex/TC_InventoryStatus.getRecords";
import { label } from "c/labelService";

export default class TcInventoryStatusMonthly extends LightningElement {
  //TEMPLATE PROPERTIES
  labels = label;
  @track columns = [];
  @track rows = [];
  hasLoaded = false;
  allShown = false;
  isEmpty = true;
  error = false;

  _response;
  // WIRED DATA
  @wire(getRecordsForInventoryStatus, {})
  wiredRecords(response) {
    this._response = response;
    if (response.data) {
      this.columns = response.data?.table?.columns;
      this.rows = response.data?.table?.rows;
      this.error = false;
      this.hasLoaded = true;
      this.allShown =
        response.data?.totalRows === response.data?.table?.rows?.length;
      this.isEmpty = response.data?.table?.rows?.length === 0;
    } else if (response.error) {
      console.error(response.error);
      this.columns = this.rows = [];
      this.error = true;
      this.hasLoaded = false;
    }
  }

  connectedCallback() {
    refreshApex(this._response);
  }
}