import { LightningElement, api, track } from "lwc";
import DATE_AND_TIME_LABEL from "@salesforce/label/c.iCare_Portal_Date_and_Time";
import HISTORICAL_STATUS from "@salesforce/label/c.GTS_Historical_Status";
// import ENTITY_NAME from '@salesforce/label/c.GTS_Entity_Name';
// import IRN_NUMBER from '@salesforce/label/c.GTS_IRN_Number';
// import SHIPMENT_NUMBER from '@salesforce/label/c.GTS_Shipment_Number';

import TIMEZONE from "@salesforce/i18n/timeZone";

import getJobTimeStampsApex from "@salesforce/apex/GTSJobHistoryController.getJobTimeStampsOnly";
export default class GtsJobHistory_LicenceAndResgistration extends LightningElement {
  @api recordId;
  @track jobTimestamps;

  columns = [
    {
      label: HISTORICAL_STATUS,
      fieldName: "status",
      hideDefaultActions: "true"
    },
    {
      label: DATE_AND_TIME_LABEL,
      fieldName: "timeStampDate",
      type: "date",
      hideDefaultActions: "false",
      typeAttributes: {
        day: "numeric",
        month: "numeric",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        timeZone: TIMEZONE
      }
    }
    // { label: ENTITY_NAME, fieldName: 'entryName', hideDefaultActions:"true"},
    // { label: IRN_NUMBER, fieldName: 'irnNr', hideDefaultActions:"true"},
    // { label: SHIPMENT_NUMBER, fieldName: 'shipmentNr', hideDefaultActions:"true"},
  ];

  connectedCallback() {
    this.getJobTimeStamps();
  }

  getJobTimeStamps() {
    getJobTimeStampsApex({ jobId: this.recordId })
      .then((result) => {
        console.log("result", JSON.stringify(result));
        this.jobTimestamps = JSON.parse(result);
        console.log("val", JSON.stringify(this.jobTimestamps));
      })
      .catch((error) => {
        console.log("Error loading JobTime Stamp *** ", JSON.stringify(error));
      });
  }
}