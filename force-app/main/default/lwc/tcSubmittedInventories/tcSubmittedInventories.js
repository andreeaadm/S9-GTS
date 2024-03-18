import { LightningElement, wire } from "lwc";
import { label } from "c/labelService";
import getPercentage from "@salesforce/apex/TC_SubmittedInventoriesController.getPercentageSubmittedInventories";

export default class TcSubmittedInventories extends LightningElement {
  labels = label;
  percentageValue;
  hasLoaded;

  @wire(getPercentage)
  wiredResponse(response) {
    if (response && response.data) {
      this.percentageValue = response.data;
      this.hasLoaded = true;
    }
  }
}