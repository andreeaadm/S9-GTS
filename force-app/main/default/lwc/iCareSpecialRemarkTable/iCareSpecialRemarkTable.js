import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSpecialRemarks from "@salesforce/apex/iCare_SpecialRemarkTableController.getSpecialRemarks";

import TIMEZONE from "@salesforce/i18n/timeZone";

import SPECIAL_REMARKS_LABEL from "@salesforce/label/c.iCare_Portal_Special_Remarks";

import SPECIAL_REMARKS_FIELD from "@salesforce/schema/icare_Special_Remark__c.iCare_Special_Remarks__c";
import SPECIAL_REMARKS_TIMESTAMP_FIELD from "@salesforce/schema/icare_Special_Remark__c.iCare_Special_Remarks_Timestamp__c";

const columns = [
  {
    fieldName: SPECIAL_REMARKS_TIMESTAMP_FIELD.fieldApiName,
    type: "date",
    initialWidth: 180,
    sortable: "true",
    hideDefaultActions: "false",
    typeAttributes: {
      day: "numeric",
      month: "numeric",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: TIMEZONE
    }
  },
  {
    fieldName: SPECIAL_REMARKS_FIELD.fieldApiName,
    hideDefaultActions: "false",
    wrapText: true
  }
];

export default class ICareSpecialRemarkTable extends NavigationMixin(
  LightningElement
) {
  tableHeaderLabel = SPECIAL_REMARKS_LABEL;
  specialRemarks;
  columns = columns;

  @api recordId;

  connectedCallback() {
    getSpecialRemarks({
      recordId: this.recordId
    })
      .then((response) => {
        this.specialRemarks = JSON.parse(response);
        console.log(JSON.stringify(this.specialRemarks));
      })
      .catch((error) => {
        this.showNotification(
          "Error",
          "There was an Error retrieving Special Remarks.",
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