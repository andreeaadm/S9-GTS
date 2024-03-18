import { LightningElement, api } from "lwc";
import { label } from "c/labelService";
import toxLogo from "@salesforce/resourceUrl/toxLogo";

export default class ZdhcViewInCheckReport extends LightningElement {
  //PUBLIC PROPERTIES
  @api recordId;

  //TEMPLATE PROPERTIES
  labels = label;
  toxLogo = toxLogo;

  handleViewInCheckReport() {
    this.template
      .querySelector("c-zdhc-get-in-check-report")
      .getInCheckReport(this.recordId);
  }
}