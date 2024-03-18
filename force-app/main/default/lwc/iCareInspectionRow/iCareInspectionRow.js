import { LightningElement, api } from "lwc";

import TIMEZONE from "@salesforce/i18n/timeZone";
import COMPLETED_DATE from '@salesforce/label/c.GTS_Completed_Date';
import INSPECTION_DOC from '@salesforce/label/c.GTS_Inspection_Documents';
import INSPECTOR from '@salesforce/label/c.GTS_Inspector';
import IRN from '@salesforce/label/c.GTS_IRN';
import RESULT from '@salesforce/label/c.iCare_Portal_Report_Result';
import SCHEDULED_FOR from '@salesforce/label/c.GTS_Scheduled_For';
import STATUS from '@salesforce/label/c.GTS_Status';

const columns = [
  {
    label: IRN,
    fieldName: "GTS_IRN__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: STATUS,
    fieldName: "GTS_Status__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: INSPECTOR,
    fieldName: "GTS_Inspector__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  },
  {
    label: SCHEDULED_FOR,
    fieldName: "GTS_Scheduled_For__c",
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
  },
  {
    label: COMPLETED_DATE,
    fieldName: "GTS_Completed__c",
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
  },
  {
    label: RESULT,
    fieldName: "GTS_Results__c",
    type: "text",
    hideDefaultActions: "false",
    wrapText: true
  }
];

export default class ICareInspectionRow extends LightningElement {
  columns = columns;
  @api record;
  @api records;

  labels = {
      INSPECTION_DOC
  }

  connectedCallback() {
    this.records = [this.record];
  }
}