import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getInspections from "@salesforce/apex/iCare_InspectionTableController.getInspections";

export default class ICareInspectionTable extends LightningElement {
  @api recordId;
  @api records;

  connectedCallback() {
    getInspections({
      recordId: this.recordId
    })
      .then((response) => {
        this.records = JSON.parse(response);
        console.log(JSON.stringify(this.records));
      })
      .catch((error) => {
        this.showNotification(
          "Error",
          "There was an Error retrieving Inspections.",
          "error"
        );
      });
  }

  showNotification(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}