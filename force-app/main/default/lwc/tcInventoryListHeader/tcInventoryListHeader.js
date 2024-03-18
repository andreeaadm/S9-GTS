import { LightningElement } from "lwc";
import { label } from "c/labelService";

export default class TcInventoryListHeader extends LightningElement {
  labels = label;
  facilityName = "";

  get headerText() {
    return this.labels.TC_INVENTORY_LIST_HEADER.concat(" ", this.facilityName);
  }

  handleRetrievedState(event) {
    this.facilityName = decodeURI(event?.detail?.facilityName);
  }
}